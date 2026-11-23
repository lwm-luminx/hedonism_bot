package host.lumiere.chip.ui

import host.lumiere.chip.core.ArchiveOption
import host.lumiere.chip.core.CardUploader
import host.lumiere.chip.core.PendingArchiveChoice
import host.lumiere.chip.core.UploadAccount
import host.lumiere.chip.location.LocationRecorder

data class FileRow(val name: String, val size: Long)

/** Everything the screens show. Screens are stateless so tests and screenshots can render any state. */
data class ChipState(
    val accounts: List<UploadAccount> = emptyList(),
    val selectedId: String? = null,
    val signingIn: Boolean = false,
    val accountError: String? = null,
    val pendingArchiveChoice: PendingArchiveChoice? = null,
    val album: String = "",
    val event: String = "",
    val venue: String = "",
    val files: List<FileRow> = emptyList(),
    val hasFolder: Boolean = false,
    val status: String = "Select a camera card or its DCIM folder",
    val progress: CardUploader.Progress? = null,
    val running: Boolean = false,
    val importing: Boolean = false,
    val phonePhotoCount: Int = 0,
    val location: LocationRecorder.State = LocationRecorder.State(),
    val cameraAvailable: Boolean = true,
    /** Goes up each time a sign-in saves an account, so the Add account page can close. */
    val signInCount: Int = 0,
) {
    val selectedAccount: UploadAccount? get() = accounts.firstOrNull { it.id == selectedId }
    val canUpload: Boolean get() = hasFolder && files.isNotEmpty() && selectedAccount != null && album.isNotBlank() && !running
}

/** What the screens can ask for. */
interface ChipActions {
    fun signInWithFacebook(server: String) {}
    fun signInWithDeviceCode(server: String, code: String) {}
    fun chooseArchive(archive: ArchiveOption) {}
    fun cancelArchiveChoice() {}
    fun clearAccountError() {}
    fun selectAccount(id: String) {}
    fun signOut() {}
    fun setAlbum(value: String) {}
    fun setEvent(value: String) {}
    fun setVenue(value: String) {}
    fun pickFolder() {}
    fun takePhoto() {}
    fun pickPhotos() {}
    fun removePhonePhotos() {}
    fun upload() {}
    fun cancelUpload() {}
    fun startRecording() {}
    fun stopRecording() {}
    fun deleteRecordings() {}
    fun openLink(url: String) {}

    companion object { val None = object : ChipActions {} }
}
