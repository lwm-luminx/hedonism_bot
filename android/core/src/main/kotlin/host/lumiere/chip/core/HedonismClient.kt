package host.lumiere.chip.core

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put
import okhttp3.Call
import okhttp3.Callback
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okio.BufferedSink
import okio.source
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

sealed class HedonismException(message: String) : Exception(message) {
    class Http(val status: Int, val body: String) :
        HedonismException(if (status == 401) "The service account token was rejected." else "Server returned HTTP $status: ${body.take(200)}")
    class GraphQL(val messages: List<String>) : HedonismException(messages.joinToString("; "))
    class Unexpected(val detail: String) : HedonismException(detail)

    /** Errors that will hit every file, so the run should stop instead of skipping files. */
    val isFatal: Boolean get() = this is Http && (status == 401 || status == 403 || status >= 500)
}

/** A file registered with an upload promise: where and how to PUT its bytes. */
data class PendingUpload(
    val id: String,
    val originalFilename: String,
    val uploadUrl: String,
    val uploadHeaders: Map<String, String>,
)

object Http {
    val json = Json { ignoreUnknownKeys = true }
    val jsonType: MediaType = "application/json".toMediaType()

    /** Shared client: generous timeouts for 70 MB RAW uploads over phone networks. */
    val defaultClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(120, TimeUnit.SECONDS)
            .writeTimeout(120, TimeUnit.SECONDS)
            .build()
    }

    fun url(server: String, path: String): String {
        val base = server.toHttpUrlOrNull() ?: throw HedonismException.Unexpected("Enter a valid HTTPS server URL")
        return base.newBuilder().addPathSegments(path).build().toString()
    }

    fun postJson(url: String, body: JsonObject, bearer: String? = null): Request =
        Request.Builder().url(url).post(body.toString().toRequestBody(jsonType))
            .header("Accept", "application/json")
            .apply { if (bearer != null) header("Authorization", "Bearer $bearer") }
            .build()

    /** Runs a call, cancelling it when the coroutine is cancelled. */
    suspend fun OkHttpClient.execute(request: Request): Pair<Int, String> = suspendCancellableCoroutine { continuation ->
        val call = newCall(request)
        continuation.invokeOnCancellation { call.cancel() }
        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (continuation.isActive) continuation.resumeWithException(e)
            }
            override fun onResponse(call: Call, response: Response) {
                val result = try {
                    response.use { it.code to (it.body?.string() ?: "") }
                } catch (e: IOException) {
                    if (continuation.isActive) continuation.resumeWithException(e)
                    return
                }
                continuation.resume(result)
            }
        })
    }

    fun parseObject(body: String): JsonObject =
        runCatching { json.parseToJsonElement(body).jsonObject }.getOrDefault(JsonObject(emptyMap()))

    fun JsonObject.string(key: String): String? = (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.contentOrNull
    fun JsonObject.obj(key: String): JsonObject? = this[key] as? JsonObject
}

/** Talks to hedonism_bot's GraphQL API with a photographer credential. */
class HedonismClient(
    val serverUrl: String,
    private val token: String,
    private val http: OkHttpClient = Http.defaultClient,
) {
    private val graphQLUrl get() = Http.url(serverUrl, "graphql")

    /** Checks the token and returns the photographer's display name. */
    suspend fun photographerName(): String =
        graphQL("query { photographer { name } }").obj("photographer")?.string("name")
            ?: throw HedonismException.Unexpected("photographer")

    suspend fun photographerSubdomain(): String =
        graphQL("query { photographer { subdomain } }").obj("photographer")?.string("subdomain")
            ?: throw HedonismException.Unexpected("photographer subdomain")

    /** Starts a standard upload batch; an explicitly supplied album overrides the server destination. */
    suspend fun createPromise(context: UploadContext?): String {
        val variables = buildJsonObject {
            if (context != null) {
                put("album", context.albumName)
                put("context", buildJsonObject { put("event", context.event); put("venue", context.venue) })
                if (context.locationRecordings.isNotEmpty()) {
                    put("recordings", JsonArray(context.locationRecordings.map { it.uploadValue() }))
                }
            }
        }
        val data = graphQL(
            "mutation(\$album: String, \$context: JSON, \$recordings: JSON) { createPhotoPromise(albumName: \$album, uploadContext: \$context, locationRecordings: \$recordings) { promise { id } } }",
            variables,
        )
        return data.obj("createPhotoPromise")?.obj("promise")?.let { (it["id"] as? JsonPrimitive)?.contentOrNull }
            ?: throw HedonismException.Unexpected("createPhotoPromise")
    }

    /** Registers files with a promise and gets a signed upload URL for each, in the same order. */
    suspend fun attach(promiseId: String, files: List<Pair<PhotoFile, FileHasher.Digests>>): List<PendingUpload> {
        val inputs = buildJsonArray {
            for ((file, digests) in files) add(buildJsonObject {
                put("originalFilename", file.filename)
                put("contentType", file.contentType ?: "application/octet-stream")
                put("fileSizeBytes", file.size)
                put("imageHash", Base64Codec.encode(digests.sha256))
                put("checksum", Base64Codec.encode(digests.md5))
            })
        }
        val data = graphQL(
            """
            mutation(${'$'}id: ID!, ${'$'}files: [PhotoPromiseFileInput!]!) {
              attachPhotoPromiseFiles(id: ${'$'}id, files: ${'$'}files) { files { id originalFilename uploadUrl uploadHeaders } }
            }
            """.trimIndent(),
            buildJsonObject { put("id", promiseId); put("files", inputs) },
        )
        val nodes = (data.obj("attachPhotoPromiseFiles")?.get("files") as? JsonArray)
            ?: throw HedonismException.Unexpected("attachPhotoPromiseFiles")
        val base = serverUrl.toHttpUrlOrNull()
        return nodes.map { element ->
            val node = element as? JsonObject ?: throw HedonismException.Unexpected("upload file")
            val id = (node["id"] as? JsonPrimitive)?.contentOrNull
            val name = node.string("originalFilename")
            val raw = node.string("uploadUrl")
            val url = raw?.let { base?.resolve(it)?.toString() }
            if (id == null || name == null || url == null) throw HedonismException.Unexpected("upload file")
            val headers = (node["uploadHeaders"] as? JsonObject)?.mapNotNull { (key, value) ->
                (value as? JsonPrimitive)?.takeIf { it.isString }?.content?.let { key to it }
            }?.toMap() ?: emptyMap()
            PendingUpload(id, name, url, headers)
        }
    }

    /** Checks completed server uploads by content hash, scoped to the authenticated photographer. */
    suspend fun uploadedHashes(hashes: List<ByteArray>): Set<String> {
        val found = mutableSetOf<String>()
        for (batch in hashes.chunked(BATCH)) {
            currentCoroutineContext().ensureActive()
            val keys = batch.map(Base64Codec::encode)
            val request = Http.postJson(
                Http.url(serverUrl, "auth/uploaded_contents"),
                buildJsonObject { put("hashes", JsonArray(keys.map(::JsonPrimitive))) },
                bearer = token,
            )
            val (status, body) = with(Http) { http.execute(request) }
            check(status, body)
            val values = runCatching { Http.json.parseToJsonElement(body).jsonObject["hashes"]!!.jsonArray }.getOrNull()
                ?: throw HedonismException.Unexpected("uploaded content hashes")
            for (value in values) {
                val key = (value as? JsonPrimitive)?.contentOrNull
                val bytes = key?.let(Base64Codec::decode)
                if (key == null || bytes == null || bytes.size != 32 || key !in keys) {
                    throw HedonismException.Unexpected("invalid uploaded content hash")
                }
                found += key
            }
        }
        return found
    }

    /** PUTs the file to storage, streaming it from its source. */
    suspend fun upload(file: PhotoFile, pending: PendingUpload) {
        val body = object : RequestBody() {
            override fun contentType(): MediaType? = null
            override fun contentLength() = file.size
            override fun writeTo(sink: BufferedSink) { file.open().source().use { sink.writeAll(it) } }
        }
        val request = Request.Builder().url(pending.uploadUrl).put(body)
            .apply { pending.uploadHeaders.forEach { (name, value) -> header(name, value) } }
            .build()
        val (status, responseBody) = withContext(Dispatchers.IO) { with(Http) { http.execute(request) } }
        check(status, responseBody)
    }

    /** Tells the server the upload finished (it then becomes a photo) or failed. */
    suspend fun finish(pending: PendingUpload, succeeded: Boolean) {
        graphQL(
            """
            mutation(${'$'}id: ID!, ${'$'}status: PhotoPromiseFileStatus!) {
              updatePhotoPromiseFileUpdate(id: ${'$'}id, status: ${'$'}status) { file { status } }
            }
            """.trimIndent(),
            buildJsonObject { put("id", pending.id); put("status", if (succeeded) "SUCCESS" else "FAILED") },
        )
    }

    suspend fun graphQL(query: String, variables: JsonObject = JsonObject(emptyMap())): JsonObject {
        val request = Http.postJson(graphQLUrl, buildJsonObject { put("query", query); put("variables", variables) }, bearer = token)
        val (status, body) = with(Http) { http.execute(request) }
        check(status, body)
        val json = runCatching { Http.json.parseToJsonElement(body).jsonObject }.getOrNull()
            ?: throw HedonismException.Unexpected("not JSON")
        val errors = json["errors"] as? JsonArray
        if (errors != null && errors.isNotEmpty()) {
            throw HedonismException.GraphQL(errors.mapNotNull { (it as? JsonObject)?.let { e -> with(Http) { e.string("message") } } })
        }
        return json["data"] as? JsonObject ?: JsonObject(emptyMap())
    }

    private fun check(status: Int, body: String) {
        if (status !in 200..299) throw HedonismException.Http(status, body)
    }

    private fun JsonObject.obj(key: String) = with(Http) { this@obj.obj(key) }
    private fun JsonObject.string(key: String) = with(Http) { this@string.string(key) }

    companion object {
        const val BATCH = 200
    }
}
