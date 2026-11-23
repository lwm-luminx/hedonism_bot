package host.lumiere.chip

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import host.lumiere.chip.core.ArchiveOption
import host.lumiere.chip.core.PendingArchiveChoice
import host.lumiere.chip.core.UploadAccount
import host.lumiere.chip.ui.ChipActions
import host.lumiere.chip.ui.ChipApp
import host.lumiere.chip.ui.ChipState
import host.lumiere.chip.ui.FileRow
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The screens' behaviour, like the iOS ChipUITests: sign-in choices, disabled upload, shoot details. */
@RunWith(AndroidJUnit4::class)
class ScreensTest {
    @get:Rule val compose = createComposeRule()
    private val calls = mutableListOf<String>()
    private val actions = object : ChipActions {
        override fun signInWithFacebook(server: String) { calls += "facebook $server" }
        override fun signInWithDeviceCode(server: String, code: String) { calls += "device $code" }
        override fun chooseArchive(archive: ArchiveOption) { calls += "archive ${archive.subdomain}" }
        override fun setAlbum(value: String) { calls += "album $value" }
        override fun pickFolder() { calls += "pickFolder" }
        override fun upload() { calls += "upload" }
    }
    private val account = UploadAccount(id = "a", name = "Test Alpha", subdomain = "alpha", server = "https://api.lumiere.host")

    @Test fun signedOutShowsFacebookAndDeviceCode() {
        compose.setContent { ChipApp(ChipState(), actions) }
        compose.onNodeWithText("Continue with Facebook").performClick()
        assertEquals(listOf("facebook https://api.lumiere.host"), calls)
        compose.onNodeWithTag("switchSignInMethod").performClick()
        compose.onNodeWithText("Sign in with device code").assertIsNotEnabled()
        compose.onNodeWithTag("deviceCodeField").performTextInput("ABCD-1234")
        compose.onNodeWithText("Sign in with device code").assertIsEnabled().performClick()
        assertEquals("device ABCD-1234", calls.last())
    }

    @Test fun showsArchiveChoices() {
        val choice = PendingArchiveChoice("https://api.lumiere.host", "s", listOf(ArchiveOption("alpha", "Alpha"), ArchiveOption("beta", "Beta")))
        compose.setContent { ChipApp(ChipState(pendingArchiveChoice = choice), actions) }
        compose.onNodeWithText("Choose an archive").assertIsDisplayed()
        compose.onNodeWithTag("archive-beta").performClick()
        assertEquals(listOf("archive beta"), calls)
    }

    @Test fun showsSignInErrors() {
        compose.setContent { ChipApp(ChipState(accountError = "This code is invalid or expired."), actions) }
        compose.onNodeWithTag("signInError").assertIsDisplayed()
    }

    @Test fun uploadIsDisabledUntilAFolderAndAlbum() {
        compose.setContent { ChipApp(ChipState(accounts = listOf(account), selectedId = "a"), actions) }
        compose.onNodeWithText("Test Alpha · alpha").assertIsDisplayed()
        compose.onNodeWithTag("uploadButton").assertIsNotEnabled()
        compose.onNodeWithTag("albumField").performTextInput("Pride")
        assertEquals("album Pride", calls.last())
        compose.onNodeWithTag("pickFolder").performClick()
        assertEquals("pickFolder", calls.last())
    }

    @Test fun uploadIsEnabledWithEverything() {
        val state = ChipState(accounts = listOf(account), selectedId = "a", album = "Pride", hasFolder = true,
            files = listOf(FileRow("DSC00001.ARW", 25_000_000)))
        compose.setContent { ChipApp(state, actions) }
        compose.onNodeWithTag("uploadButton").assertIsEnabled().performClick()
        assertEquals("upload", calls.last())
    }

    @Test fun runningShowsCancel() {
        compose.setContent { ChipApp(ChipState(accounts = listOf(account), selectedId = "a", running = true), actions) }
        compose.onNodeWithTag("cancelUpload").assertIsDisplayed()
    }
}
