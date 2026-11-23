package host.lumiere.chip

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.runtime.getValue
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.activity.viewModels
import host.lumiere.chip.core.ArchiveOption
import host.lumiere.chip.data.DocumentNode
import host.lumiere.chip.location.LocationRecordingService
import host.lumiere.chip.ui.ChipActions
import host.lumiere.chip.ui.ChipApp
import host.lumiere.chip.ui.ChipController
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/** Keeps the controller (and any upload in progress) across rotation. */
class ChipViewModel(app: ChipApplication) : ViewModel() {
    val controller = ChipController(viewModelScope, app.accountStore, app.tokenStore, app.phoneStaging, app.locationRecorder)
}

class MainActivity : ComponentActivity(), ChipActions {
    private val app get() = application as ChipApplication
    private val viewModel: ChipViewModel by viewModels { viewModelFactory { initializer { ChipViewModel(app) } } }
    private val controller get() = viewModel.controller
    private var cameraFile: File? = null

    private val pickFolder = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
        if (uri != null) {
            runCatching { contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
            controller.select(DocumentNode.tree(contentResolver, uri))
        }
    }

    private val takePicture = registerForActivityResult(ActivityResultContracts.TakePicture()) { saved ->
        val file = cameraFile
        cameraFile = null
        if (!saved || file == null || file.length() == 0L) file?.delete()
        controller.usePhonePhotos()
    }

    private val pickPhotos = registerForActivityResult(ActivityResultContracts.PickMultipleVisualMedia()) { uris ->
        if (uris.isEmpty()) return@registerForActivityResult
        controller.setImporting(true)
        lifecycleScope.launch {
            val failed = withContext(Dispatchers.IO) {
                uris.count { uri -> runCatching { app.phoneStaging.import(contentResolver, uri) }.isFailure }
            }
            controller.setImporting(false)
            controller.usePhonePhotos(failed)
        }
    }

    private val locationPermission = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
        if (grants[Manifest.permission.ACCESS_FINE_LOCATION] == true || grants[Manifest.permission.ACCESS_COARSE_LOCATION] == true) {
            LocationRecordingService.start(this)
        } else {
            app.locationRecorder.setStatus("Location permission is unavailable. Enable it in Settings to record.")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        handleSignInCallback(intent)
        val cameraAvailable = Intent(MediaStore.ACTION_IMAGE_CAPTURE).resolveActivity(packageManager) != null
        setContent {
            val state by controller.state.collectAsStateWithLifecycle()
            // Uploads run in the foreground, as on iOS: keep the screen on until they finish.
            if (state.running) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            ChipApp(state.copy(cameraAvailable = cameraAvailable), this)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleSignInCallback(intent)
    }

    private fun handleSignInCallback(intent: Intent?) {
        val data = intent?.data ?: return
        if (data.scheme == "lumiere-uploader" && data.host == "signin") {
            controller.completeBrowserSignIn(data.toString())
            setIntent(Intent(intent).setData(null))
        }
    }

    // ChipActions

    override fun signInWithFacebook(server: String) {
        val url = controller.startBrowserSignIn(server) ?: return
        CustomTabsIntent.Builder().setShowTitle(true).build().launchUrl(this, Uri.parse(url))
    }

    override fun signInWithDeviceCode(server: String, code: String) = controller.signInWithDeviceCode(server, code)
    override fun chooseArchive(archive: ArchiveOption) = controller.chooseArchive(archive)
    override fun cancelArchiveChoice() = controller.cancelArchiveChoice()
    override fun clearAccountError() = controller.clearAccountError()
    override fun selectAccount(id: String) = controller.selectAccount(id)
    override fun signOut() = controller.signOut()
    override fun setAlbum(value: String) = controller.setAlbum(value)
    override fun setEvent(value: String) = controller.setEvent(value)
    override fun setVenue(value: String) = controller.setVenue(value)
    override fun pickFolder() = pickFolder.launch(null)

    override fun takePhoto() {
        val file = app.phoneStaging.newCameraFile()
        cameraFile = file
        takePicture.launch(FileProvider.getUriForFile(this, "$packageName.photos", file))
    }

    override fun pickPhotos() = pickPhotos.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
    override fun removePhonePhotos() = controller.removePhonePhotos()
    override fun upload() = controller.upload()
    override fun cancelUpload() = controller.cancelUpload()

    override fun startRecording() {
        val needed = buildList {
            add(Manifest.permission.ACCESS_FINE_LOCATION)
            add(Manifest.permission.ACCESS_COARSE_LOCATION)
            if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.POST_NOTIFICATIONS)
        }
        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (granted) LocationRecordingService.start(this) else locationPermission.launch(needed.toTypedArray())
    }

    override fun stopRecording() = LocationRecordingService.stop(this)

    override fun deleteRecordings() {
        LocationRecordingService.stop(this)
        app.locationRecorder.delete()
    }

    override fun openLink(url: String) {
        CustomTabsIntent.Builder().build().launchUrl(this, Uri.parse(url))
    }
}
