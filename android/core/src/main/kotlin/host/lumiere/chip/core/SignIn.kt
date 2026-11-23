package host.lumiere.chip.core

import host.lumiere.chip.core.Http.execute
import host.lumiere.chip.core.Http.string
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.OkHttpClient
import java.net.URI
import java.security.MessageDigest
import java.security.SecureRandom

/** An archive (photographer) the signed-in person administers. */
data class ArchiveOption(val subdomain: String, val name: String)

/** What a Facebook sign-in returns: a credential, or the person's archives to pick from. */
sealed class SignInOutcome {
    data class Credential(val token: String) : SignInOutcome()
    data class ChooseArchive(val selection: String, val archives: List<ArchiveOption>) : SignInOutcome()

    companion object {
        /** Reads `{ token }`, or `{ selection, photographers: [{ subdomain, name }] }`. */
        fun parse(json: JsonObject): SignInOutcome {
            json.string("token")?.takeIf { it.isNotEmpty() }?.let { return Credential(it) }
            val selection = json.string("selection")
            val list = json["photographers"] as? JsonArray
            if (selection != null && list != null) {
                val archives = list.mapNotNull { item ->
                    val obj = item as? JsonObject ?: return@mapNotNull null
                    val subdomain = obj.string("subdomain") ?: return@mapNotNull null
                    ArchiveOption(subdomain, obj.string("name") ?: subdomain)
                }
                if (archives.isEmpty()) throw HedonismException.Unexpected("No archives to sign in to")
                return ChooseArchive(selection, archives)
            }
            throw HedonismException.Unexpected(json.string("error") ?: "Could not complete sign-in")
        }
    }
}

/** A sign-in waiting for the person to pick one of their archives. */
data class PendingArchiveChoice(val server: String, val selection: String, val archives: List<ArchiveOption>)

/** The server-side sign-in endpoints (shared with Chip for iOS and Cogsworth). */
class SignInApi(private val http: OkHttpClient = Http.defaultClient) {
    /** Redeems a one-use service-account device code. */
    suspend fun deviceCode(server: String, code: String): String {
        val request = Http.postJson(Http.url(server, "auth/device/exchange"), buildJsonObject { put("code", code.trim()) })
        val (status, body) = http.execute(request)
        if (status != 200) {
            throw HedonismException.Unexpected(
                if (status == 401) "This code is invalid or expired. Ask for a new device code." else "Device sign-in failed. Please try again.",
            )
        }
        return Http.parseObject(body).string("token") ?: throw HedonismException.Unexpected("Could not complete device sign-in")
    }

    /** Redeems the one-time code from a browser (Facebook) sign-in with its PKCE verifier. */
    suspend fun exchangeBrowserCode(server: String, code: String, verifier: String): SignInOutcome {
        val request = Http.postJson(Http.url(server, "auth/native/exchange"), buildJsonObject { put("code", code); put("verifier", verifier) })
        val (status, body) = http.execute(request)
        val json = Http.parseObject(body)
        if (status != 200) throw HedonismException.Unexpected(json.string("error") ?: "Sign-in exchange failed")
        return SignInOutcome.parse(json)
    }

    /** Exchanges the selection from a sign-in for a credential for the chosen archive. */
    suspend fun chooseArchive(server: String, selection: String, subdomain: String): String {
        val request = Http.postJson(Http.url(server, "auth/archives/select"), buildJsonObject { put("selection", selection); put("photographer", subdomain) })
        val (status, body) = http.execute(request)
        val json = Http.parseObject(body)
        val token = json.string("token")
        if (status != 200 || token == null) throw HedonismException.Unexpected(json.string("error") ?: "Could not open that archive. Sign in again.")
        return token
    }
}

/**
 * Browser (Facebook) sign-in with PKCE. The app opens [authorizeUrl] in a Custom Tab; the server
 * redirects to `lumiere-uploader://signin?code=…&state=…`, and the app redeems the code with the verifier.
 */
data class BrowserSignIn(val server: String, val verifier: String, val state: String) {
    val challenge: String get() = challenge(verifier)

    val authorizeUrl: String get() {
        val base = Http.url(server, "auth/native").toHttpUrlOrNull()!!
        return base.newBuilder().addQueryParameter("challenge", challenge).addQueryParameter("state", state).build().toString()
    }

    /** Returns the one-time code from the callback, or throws with the reason sign-in failed. */
    fun code(callback: String): String {
        val uri = runCatching { URI(callback) }.getOrNull() ?: throw HedonismException.Unexpected("Invalid sign-in callback")
        val items = (uri.rawQuery ?: "").split('&').filter { it.isNotEmpty() }.associate { item ->
            val name = item.substringBefore('=')
            val value = item.substringAfter('=', "")
            decode(name) to decode(value)
        }
        if (uri.scheme != CALLBACK_SCHEME || uri.host != "signin" || items["state"] != state) {
            throw HedonismException.Unexpected("Invalid sign-in callback")
        }
        items["error"]?.let { throw HedonismException.Unexpected("Facebook sign-in failed: $it") }
        return items["code"] ?: throw HedonismException.Unexpected("Invalid sign-in callback")
    }

    companion object {
        const val CALLBACK_SCHEME = "lumiere-uploader"
        private val random = SecureRandom()

        fun start(server: String): BrowserSignIn = BrowserSignIn(server, randomToken(48), randomToken(24))

        /** URL-safe random text; the server requires 43-char challenges and 32-128 char states. */
        fun randomToken(bytes: Int): String = ByteArray(bytes).also(random::nextBytes).let(Base64Codec::urlEncodeNoPadding)

        fun challenge(verifier: String): String =
            Base64Codec.urlEncodeNoPadding(MessageDigest.getInstance("SHA-256").digest(verifier.toByteArray()))

        private fun decode(value: String) = java.net.URLDecoder.decode(value, "UTF-8")
    }
}
