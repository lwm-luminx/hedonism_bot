package host.lumiere.chip.core

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.File
import java.util.Collections

/** Runs the whole upload against a fake hedonism_bot: preflight, promise, attach, PUT, finish. */
class CardUploaderTest {
    private val server = MockWebServer()
    private val requests = Collections.synchronizedList(mutableListOf<Pair<String, String>>())
    private val uploaded = Collections.synchronizedMap(mutableMapOf<String, ByteArray>())
    private val finished = Collections.synchronizedList(mutableListOf<String>())
    var alreadyOnServer: Set<String> = emptySet()
    var failPut: Set<String> = emptySet()
    var putStatus = 500

    init {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val body = request.body.readByteArray()
                requests += (request.method + " " + request.path) to String(body)
                if (request.method == "PUT") {
                    val name = request.path!!.substringAfterLast('/')
                    if (name in failPut) return MockResponse().setResponseCode(putStatus)
                    uploaded[name] = body
                    assertEquals("expected-md5", request.getHeader("Content-MD5"))
                    return MockResponse()
                }
                if (request.path == "/auth/uploaded_contents") {
                    assertEquals("Bearer secret", request.getHeader("Authorization"))
                    val hashes = Json.parseToJsonElement(String(body)).jsonObject["hashes"]!!.jsonArray.map { it.jsonPrimitive.content }
                    val known = hashes.filter { it in alreadyOnServer }.joinToString(",") { "\"$it\"" }
                    return MockResponse().setBody("""{"hashes":[$known]}""")
                }
                val query = Json.parseToJsonElement(String(body)).jsonObject
                val text = query["query"]!!.jsonPrimitive.content
                val variables = query["variables"] as JsonObject
                return when {
                    "createPhotoPromise" in text -> MockResponse().setBody("""{"data":{"createPhotoPromise":{"promise":{"id":"P1"}}}}""")
                    "attachPhotoPromiseFiles" in text -> {
                        val files = variables["files"]!!.jsonArray.joinToString(",") { file ->
                            val name = file.jsonObject["originalFilename"]!!.jsonPrimitive.content
                            """{"id":"F-$name","originalFilename":"$name","uploadUrl":"/storage/$name","uploadHeaders":{"Content-MD5":"expected-md5"}}"""
                        }
                        MockResponse().setBody("""{"data":{"attachPhotoPromiseFiles":{"files":[$files]}}}""")
                    }
                    "updatePhotoPromiseFileUpdate" in text -> {
                        finished += variables["id"]!!.jsonPrimitive.content + "=" + variables["status"]!!.jsonPrimitive.content
                        MockResponse().setBody("""{"data":{"updatePhotoPromiseFileUpdate":{"file":{"status":"x"}}}}""")
                    }
                    else -> MockResponse().setResponseCode(400)
                }
            }
        }
        server.start()
    }

    @After fun tearDown() = server.shutdown()

    private fun hashOf(text: String) = FileHasher.digests(text.toByteArray().inputStream()).sha256Key

    private fun uploader(ledgerFile: File = File(Fixtures.tempDir(), "ledger.json")) = CardUploader(
        HedonismClient(server.url("/").toString(), "secret"),
        UploadLedger(ledgerFile),
        UploadContext("Pride 2026", "Parade", "Civic Center", listOf(LocationRecording(1_700_000_000_000, 1_700_000_100_000))),
    )

    @Test fun uploadsEveryNewFileAsShots() = runTest {
        val ledgerFile = File(Fixtures.tempDir(), "ledger.json")
        val updates = mutableListOf<CardUploader.Progress>()
        val result = uploader(ledgerFile).upload(CardScanner.photos(FileNode(Fixtures.card()))) { updates += it }

        assertEquals(CardUploader.Progress(3, 3, 0, null), result)
        assertEquals("raw-one", String(uploaded.getValue("DSC00001.ARW")))
        assertEquals(setOf("DSC00001.ARW", "DSC00001.HIF", "DSC00002.JPG"), uploaded.keys)
        assertEquals(listOf("F-DSC00001.ARW=SUCCESS", "F-DSC00001.HIF=SUCCESS", "F-DSC00002.JPG=SUCCESS"), finished)
        assertEquals(3, UploadLedger(ledgerFile).count)
        assertTrue(updates.any { it.currentFile == "Checking DSC00001.ARW" })

        // One attach per shot: the ARW+HIF pair together, then the JPEG.
        val attaches = requests.filter { "attachPhotoPromiseFiles" in it.second }
        assertEquals(2, attaches.size)
        val promise = Json.parseToJsonElement(requests.first { "createPhotoPromise" in it.second }.second).jsonObject["variables"]!!.jsonObject
        assertEquals("Pride 2026", promise["album"]!!.jsonPrimitive.content)
        assertEquals("Civic Center", promise["context"]!!.jsonObject["venue"]!!.jsonPrimitive.content)
        assertEquals(1, promise["recordings"]!!.jsonArray.size)
    }

    @Test fun skipsContentTheServerAndCardAlreadyHave() = runTest {
        val card = Fixtures.card()
        Fixtures.write(card, "DCIM/101MSDCF/COPY0002.JPG", "jpeg-two".toByteArray(), 1_700_000_300)
        alreadyOnServer = setOf(hashOf("raw-one"))
        val result = uploader().upload(CardScanner.photos(FileNode(card))) {}
        assertEquals(2, result.totalFiles)
        assertEquals(setOf("DSC00001.HIF", "DSC00002.JPG"), uploaded.keys)
    }

    @Test fun nothingNewMeansNoPromise() = runTest {
        alreadyOnServer = setOf(hashOf("raw-one"), hashOf("heif-one"), hashOf("jpeg-two"))
        val result = uploader().upload(CardScanner.photos(FileNode(Fixtures.card()))) {}
        assertEquals(CardUploader.Progress(0), result)
        assertTrue(requests.none { "createPhotoPromise" in it.second })
    }

    @Test fun countsAFailedFileAndCarriesOn() = runTest {
        failPut = setOf("DSC00001.HIF"); putStatus = 400
        val result = uploader().upload(CardScanner.photos(FileNode(Fixtures.card()))) {}
        assertEquals(2, result.uploadedFiles)
        assertEquals(1, result.failedFiles)
        assertTrue("F-DSC00001.HIF=FAILED" in finished)
    }

    @Test fun stopsOnServerErrors() = runTest {
        failPut = setOf("DSC00001.ARW"); putStatus = 503
        try {
            uploader().upload(CardScanner.photos(FileNode(Fixtures.card()))) {}
            fail("expected a fatal error")
        } catch (e: HedonismException.Http) {
            assertEquals(503, e.status)
            assertTrue(e.isFatal)
        }
        assertEquals(emptySet<String>(), uploaded.keys)
    }

    @Test fun graphQLErrorsSurface() = runTest {
        val client = HedonismClient(server.url("/").toString(), "secret")
        try { client.graphQL("query { nope }"); fail() } catch (e: HedonismException.Http) { assertEquals(400, e.status) }
    }
}
