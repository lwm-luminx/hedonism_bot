package host.lumiere.chip

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import host.lumiere.chip.core.ArchiveOption
import host.lumiere.chip.core.BrowserSignIn
import host.lumiere.chip.core.FileNode
import host.lumiere.chip.data.AccountStore
import host.lumiere.chip.data.MemoryTokenStore
import host.lumiere.chip.data.PhoneStaging
import host.lumiere.chip.location.LocationRecorder
import host.lumiere.chip.ui.ChipController
import host.lumiere.chip.ui.ChipState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.nio.file.Files

/** Drives Chip's controller against a fake hedonism_bot, end to end: sign-in, archive choice, upload. */
@RunWith(AndroidJUnit4::class)
class ChipControllerTest {
    private val server = MockWebServer()
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private lateinit var store: AccountStore
    private val tokens = MemoryTokenStore()
    private lateinit var staging: PhoneStaging
    private lateinit var recorder: LocationRecorder
    private val uploads = mutableListOf<String>()
    private lateinit var base: String

    @Before fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val dir = Files.createTempDirectory("chip-app").toFile()
        store = AccountStore(context.getSharedPreferences("chip-test-${System.nanoTime()}", Context.MODE_PRIVATE), dir)
        staging = PhoneStaging(dir)
        recorder = LocationRecorder(File(dir, "locations.json"))
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val body = request.body.readUtf8()
                return when {
                    request.path == "/auth/device/exchange" ->
                        if ("GOOD" in body) MockResponse().setBody("""{"token":"device-token"}""") else MockResponse().setResponseCode(401)
                    request.path == "/auth/native/exchange" ->
                        MockResponse().setBody("""{"selection":"sel","photographers":[{"subdomain":"alpha","name":"Alpha"},{"subdomain":"beta","name":"Beta"}]}""")
                    request.path == "/auth/archives/select" -> MockResponse().setBody("""{"token":"beta-token"}""")
                    request.path == "/auth/uploaded_contents" -> MockResponse().setBody("""{"hashes":[]}""")
                    request.method == "PUT" -> { synchronized(uploads) { uploads += request.path!! }; MockResponse() }
                    request.path == "/graphql" -> graphQL(request.getHeader("Authorization")!!, body)
                    else -> MockResponse().setResponseCode(404)
                }
            }
        }
        server.start()
        base = server.url("/").toString().trimEnd('/').replace("http://", "https://")
    }

    @After fun tearDown() { scope.cancel(); server.shutdown() }

    private fun graphQL(auth: String, body: String): MockResponse {
        val name = if ("beta" in auth) "beta" else "alpha"
        return MockResponse().setBody(when {
            "subdomain" in body -> """{"data":{"photographer":{"subdomain":"$name"}}}"""
            "photographer { name }" in body -> """{"data":{"photographer":{"name":"${name.replaceFirstChar { it.uppercase() }} Studio"}}}"""
            "createPhotoPromise" in body -> """{"data":{"createPhotoPromise":{"promise":{"id":"P"}}}}"""
            "attachPhotoPromiseFiles" in body -> {
                val names = Regex("\"originalFilename\":\"([^\"]+)\"").findAll(body).map { it.groupValues[1] }
                val files = names.joinToString(",") { """{"id":"F-$it","originalFilename":"$it","uploadUrl":"/put/$it","uploadHeaders":{}}""" }
                """{"data":{"attachPhotoPromiseFiles":{"files":[$files]}}}"""
            }
            else -> """{"data":{"updatePhotoPromiseFileUpdate":{"file":{"status":"SUCCESS"}}}}"""
        })
    }

    /** The fake server speaks plain HTTP; the app only accepts HTTPS server URLs, so rewrite at the client. */
    private fun controller() = ChipController(
        scope, store, tokens, staging, recorder,
        signInApi = host.lumiere.chip.core.SignInApi(plainHttp),
        clientFactory = { srv, token -> host.lumiere.chip.core.HedonismClient(srv, token, plainHttp) },
    )

    private val plainHttp = okhttp3.OkHttpClient.Builder().addInterceptor { chain ->
        val request = chain.request()
        val url = request.url.newBuilder().scheme("http").host(server.hostName).port(server.port).build()
        chain.proceed(request.newBuilder().url(url).build())
    }.build()

    private fun await(controller: ChipController, timeoutMs: Long = 10_000, condition: (ChipState) -> Boolean): ChipState {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            val state = controller.state.value
            if (condition(state)) return state
            Thread.sleep(20)
        }
        throw AssertionError("Timed out; last state ${controller.state.value}")
    }

    @Test fun deviceCodeSignInSavesAnAccount() {
        val controller = controller()
        controller.signInWithDeviceCode(base, "GOOD-CODE")
        val state = await(controller) { it.accounts.isNotEmpty() && !it.signingIn }
        assertEquals("Alpha Studio", state.selectedAccount?.name)
        assertEquals("alpha", state.selectedAccount?.subdomain)
        assertEquals("device-token", tokens.token(state.selectedId!!))
        assertEquals(1, state.signInCount)
        // A new controller (next launch) restores the saved account.
        assertEquals("alpha", controller().state.value.selectedAccount?.subdomain)
    }

    @Test fun badDeviceCodeShowsTheError() {
        val controller = controller()
        controller.signInWithDeviceCode(base, "BAD")
        val state = await(controller) { it.accountError != null }
        assertEquals("This code is invalid or expired. Ask for a new device code.", state.accountError)
        assertTrue(state.accounts.isEmpty())
    }

    @Test fun rejectsNonHttpsServers() {
        val controller = controller()
        assertNull(controller.startBrowserSignIn("http://example.com"))
        assertEquals("Enter a valid HTTPS server URL", controller.state.value.accountError)
    }

    @Test fun facebookSignInWithSeveralArchivesAsksWhichOne() {
        val controller = controller()
        val url = controller.startBrowserSignIn(base)!!
        assertTrue(url.startsWith("$base/auth/native?challenge="))
        val pending: BrowserSignIn = store.browserSignIn!!
        controller.completeBrowserSignIn("lumiere-uploader://signin?code=one-time&state=${pending.state}")
        val choosing = await(controller) { it.pendingArchiveChoice != null && !it.signingIn }
        assertEquals(listOf("alpha", "beta"), choosing.pendingArchiveChoice!!.archives.map(ArchiveOption::subdomain))
        controller.chooseArchive(ArchiveOption("beta", "Beta"))
        val state = await(controller) { it.accounts.isNotEmpty() && !it.signingIn }
        assertEquals("beta", state.selectedAccount?.subdomain)
        assertEquals("beta-token", tokens.token(state.selectedId!!))
        assertNull(store.browserSignIn)
    }

    @Test fun callbackWithTheWrongStateIsRejected() {
        val controller = controller()
        controller.startBrowserSignIn(base)
        controller.completeBrowserSignIn("lumiere-uploader://signin?code=x&state=forged")
        assertEquals("Invalid sign-in callback", await(controller) { it.accountError != null }.accountError)
    }

    @Test fun uploadsPhonePhotosAndClearsThem() {
        val controller = controller()
        controller.signInWithDeviceCode(base, "GOOD")
        await(controller) { it.accounts.isNotEmpty() && !it.signingIn }
        staging.destination("IMG_0001.JPG", "jpg").writeText("one")
        staging.destination("IMG_0002.JPG", "jpg").writeText("two")
        controller.usePhonePhotos()
        assertEquals("2 phone photos ready to upload", await(controller) { it.files.size == 2 }.status)
        controller.upload()
        assertEquals("Choose a signed-in account, enter an album, then select a card", controller.state.value.status)
        controller.setAlbum("Pride 2026")
        controller.upload()
        val done = await(controller) { !it.running && it.status.endsWith("retry.") }
        assertEquals("2 uploaded; 0 failed. Upload again to retry.", done.status)
        assertEquals(2, uploads.size)
        assertEquals(0, staging.count)
        assertTrue(done.files.isEmpty())
    }

    @Test fun cardFolderShowsNewFilesForTheAccount() {
        val controller = controller()
        val card = Files.createTempDirectory("card").toFile()
        File(card, "DCIM/100CANON").mkdirs()
        File(card, "DCIM/100CANON/IMG_0001.CR3").writeText("unsupported")
        File(card, "DCIM/100CANON/IMG_0002.JPG").writeText("jpeg")
        File(card, "DCIM/100CANON/IMG_0002.DNG").writeText("raw")
        controller.select(FileNode(card))
        val state = await(controller) { it.files.isNotEmpty() }
        assertEquals("2 supported files; 2 new", state.status)
        assertEquals(false, state.canUpload)
    }

    @Test fun signOutRemovesTheCredential() {
        val controller = controller()
        controller.signInWithDeviceCode(base, "GOOD")
        val signedIn = await(controller) { it.accounts.isNotEmpty() && !it.signingIn }
        controller.signOut()
        val state = controller.state.value
        assertTrue(state.accounts.isEmpty())
        assertNull(tokens.token(signedIn.selectedId!!))
        assertEquals("Signed out of Alpha Studio on this phone", state.status)
    }

    @Test fun locationRecordingKeepsAccurateSamples() {
        recorder.start(now = 1_000)
        recorder.add(host.lumiere.chip.core.LocationSample(2_000, 1.0, 2.0, 10.0))
        recorder.add(host.lumiere.chip.core.LocationSample(3_000, 1.0, 2.0, 500.0))
        recorder.add(host.lumiere.chip.core.LocationSample(500, 1.0, 2.0, 10.0))
        recorder.stop(now = 4_000)
        val reloaded = LocationRecorder(File(staging.folder.parentFile, "locations.json")).state.value
        assertEquals(1, reloaded.sampleCount)
        assertEquals(4_000L, reloaded.recordings.single().stoppedAt)
    }
}
