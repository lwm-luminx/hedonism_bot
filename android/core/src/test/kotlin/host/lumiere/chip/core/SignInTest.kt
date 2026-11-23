package host.lumiere.chip.core

import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class SignInTest {
    private val server = MockWebServer().apply { start() }
    private val base get() = server.url("/").toString()
    @After fun tearDown() = server.shutdown()

    private fun json(text: String) = Json.parseToJsonElement(text).jsonObject

    @Test fun parsesCredentialAndArchiveChoice() {
        assertEquals(SignInOutcome.Credential("t"), SignInOutcome.parse(json("""{"token":"t"}""")))
        val choice = SignInOutcome.parse(json("""{"selection":"s","photographers":[{"subdomain":"a","name":"Alpha"},{"subdomain":"b"}]}"""))
        assertEquals(SignInOutcome.ChooseArchive("s", listOf(ArchiveOption("a", "Alpha"), ArchiveOption("b", "b"))), choice)
        try { SignInOutcome.parse(json("""{"error":"nope"}""")); fail() } catch (e: HedonismException) { assertEquals("nope", e.message) }
        try { SignInOutcome.parse(json("""{"selection":"s","photographers":[]}""")); fail() } catch (_: HedonismException) {}
    }

    @Test fun pkceChallengeIsUnpaddedUrlSafeSha256() {
        assertEquals("sQO6n65s-O_4RAO4X5T13sSMr-eWekQCJHD-ABJAI7k", BrowserSignIn.challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r2nWcGKqoWdqdxk"))
        val start = BrowserSignIn.start("https://api.lumiere.host")
        assertEquals(43, start.challenge.length)
        assertTrue(start.state.length in 32..128)
        assertTrue(start.authorizeUrl.startsWith("https://api.lumiere.host/auth/native?challenge="))
    }

    @Test fun readsBrowserCallback() {
        val signIn = BrowserSignIn("https://api.lumiere.host", "v", "state123")
        assertEquals("abc/=", signIn.code("lumiere-uploader://signin?code=abc%2F%3D&state=state123"))
        try { signIn.code("lumiere-uploader://signin?code=abc&state=other"); fail() } catch (_: HedonismException) {}
        try { signIn.code("lumiere-uploader://signin?error=access_denied&state=state123"); fail() } catch (e: HedonismException) {
            assertEquals("Facebook sign-in failed: access_denied", e.message)
        }
    }

    @Test fun deviceCodeExchange() = runTest {
        server.enqueue(MockResponse().setBody("""{"token":"device-token"}"""))
        assertEquals("device-token", SignInApi().deviceCode(base, " ABCD-1234 "))
        val request = server.takeRequest()
        assertEquals("/auth/device/exchange", request.path)
        assertEquals("""{"code":"ABCD-1234"}""", request.body.readUtf8())

        server.enqueue(MockResponse().setResponseCode(401))
        try { SignInApi().deviceCode(base, "x"); fail() } catch (e: HedonismException) {
            assertEquals("This code is invalid or expired. Ask for a new device code.", e.message)
        }
    }

    @Test fun browserExchangeAndArchiveSelection() = runTest {
        server.enqueue(MockResponse().setBody("""{"selection":"sel","photographers":[{"subdomain":"a","name":"A"}]}"""))
        server.enqueue(MockResponse().setBody("""{"token":"archive-token"}"""))
        val outcome = SignInApi().exchangeBrowserCode(base, "code", "verifier") as SignInOutcome.ChooseArchive
        assertEquals("archive-token", SignInApi().chooseArchive(base, outcome.selection, "a"))
        assertEquals("""{"code":"code","verifier":"verifier"}""", server.takeRequest().body.readUtf8())
        val select = server.takeRequest()
        assertEquals("/auth/archives/select", select.path)
        assertEquals("""{"selection":"sel","photographer":"a"}""", select.body.readUtf8())
    }
}
