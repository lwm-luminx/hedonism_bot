package host.lumiere.chip

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.github.takahirom.roborazzi.captureRoboImage
import host.lumiere.chip.core.ArchiveOption
import host.lumiere.chip.core.CardUploader
import host.lumiere.chip.core.LocationRecording
import host.lumiere.chip.core.LocationSample
import host.lumiere.chip.core.PendingArchiveChoice
import host.lumiere.chip.core.UploadAccount
import host.lumiere.chip.location.LocationRecorder
import host.lumiere.chip.ui.ChipActions
import host.lumiere.chip.ui.ChipApp
import host.lumiere.chip.ui.ChipState
import host.lumiere.chip.ui.FileRow
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Google Play listing screenshots. Record with `./gradlew :app:recordRoborazziDebug`; images land in
 * android/store/screenshots. Phone: 1080x1920. Tablets: 7" 1200x1920 and 10" 1600x2560.
 */
@RunWith(AndroidJUnit4::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
abstract class StoreScreenshots(private val device: String) {
    @get:Rule val compose = createComposeRule()

    private val accounts = listOf(
        UploadAccount(id = "a", name = "Love Wins Media", subdomain = "lovewins", server = "https://api.lumiere.host"),
        UploadAccount(id = "b", name = "Hot Mess", subdomain = "hotmess", server = "https://api.lumiere.host"),
    )
    private val card = listOf(
        FileRow("DSC04211.ARW", 24_812_330), FileRow("DSC04211.HIF", 6_120_448),
        FileRow("DSC04212.ARW", 24_790_102), FileRow("DSC04212.HIF", 5_998_210),
        FileRow("DSC04213.ARW", 24_901_557), FileRow("DSC04213.HIF", 6_402_871),
        FileRow("DSC04214.ARW", 24_655_019), FileRow("DSC04214.HIF", 6_011_640),
        FileRow("DSC04215.ARW", 24_730_884), FileRow("DSC04215.HIF", 6_230_105),
    )
    private val shoot = ChipState(
        accounts = accounts, selectedId = "a", album = "Pride Parade 2026", event = "Denver PrideFest", venue = "Civic Center Park",
        hasFolder = true, files = card, status = "10 supported files; 10 new",
        location = LocationRecorder.State(
            recordings = listOf(LocationRecording(0, 1, List(184) { LocationSample(it.toLong(), 0.0, 0.0, 5.0) })),
            recording = true, status = "Recording location. Stop when your shoot ends.",
        ),
    )

    private fun shot(name: String, state: ChipState) {
        compose.setContent { ChipApp(state, ChipActions.None) }
        compose.onRoot().captureRoboImage("../store/screenshots/$device/$name.png")
    }

    @Test fun signIn() = shot("1-sign-in", ChipState())
    @Test fun upload() = shot("2-shoot-ready", shoot)
    @Test fun uploading() = shot("3-uploading", shoot.copy(
        running = true, status = "Uploading to Love Wins Media",
        progress = CardUploader.Progress(totalFiles = 10, uploadedFiles = 6, currentFile = "DSC04214.ARW"),
    ))
    @Test fun done() = shot("4-done", shoot.copy(status = "10 uploaded; 0 failed. Upload again to retry.", files = emptyList(),
        location = shoot.location.copy(recording = false, status = "Recording stopped. History is saved for later uploads.")))
    @Test fun archives() = shot("5-choose-archive", ChipState(pendingArchiveChoice = PendingArchiveChoice(
        "https://api.lumiere.host", "s",
        listOf(ArchiveOption("lovewins", "Love Wins Media"), ArchiveOption("hotmess", "Hot Mess"), ArchiveOption("hackdifferent", "Hack Different")),
    )))
}

@RunWith(AndroidJUnit4::class) @GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w360dp-h640dp-xxhdpi") class PhoneScreenshots : StoreScreenshots("phone")
@RunWith(AndroidJUnit4::class) @GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w600dp-h960dp-xhdpi") class Tablet7Screenshots : StoreScreenshots("tablet-7")
@RunWith(AndroidJUnit4::class) @GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(qualifiers = "w800dp-h1280dp-xhdpi") class Tablet10Screenshots : StoreScreenshots("tablet-10")
