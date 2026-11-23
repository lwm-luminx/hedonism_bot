package host.lumiere.chip.ui

import host.lumiere.chip.core.ArchiveOption
import host.lumiere.chip.core.BrowserSignIn
import host.lumiere.chip.core.CardNode
import host.lumiere.chip.core.CardScanner
import host.lumiere.chip.core.CardUploader
import host.lumiere.chip.core.HedonismClient
import host.lumiere.chip.core.PendingArchiveChoice
import host.lumiere.chip.core.PhotoFile
import host.lumiere.chip.core.SignInApi
import host.lumiere.chip.core.SignInOutcome
import host.lumiere.chip.core.UploadAccount
import host.lumiere.chip.core.UploadContext
import host.lumiere.chip.core.UploadLedger
import host.lumiere.chip.data.AccountStore
import host.lumiere.chip.data.PhoneStaging
import host.lumiere.chip.data.TokenStore
import host.lumiere.chip.location.LocationRecorder
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

/**
 * Chip's upload model, the Android counterpart of MobileUploadModel on iOS. Platform pieces (the
 * browser, pickers, location service) stay in MainActivity; this class holds the logic so tests can
 * drive it against a fake server.
 */
class ChipController(
    private val scope: CoroutineScope,
    private val store: AccountStore,
    private val tokens: TokenStore,
    private val staging: PhoneStaging,
    private val recorder: LocationRecorder,
    private val signInApi: SignInApi = SignInApi(),
    private val io: CoroutineDispatcher = Dispatchers.IO,
    private val clientFactory: (server: String, token: String) -> HedonismClient = { server, token -> HedonismClient(server, token) },
) {
    private val _state = MutableStateFlow(ChipState())
    val state: StateFlow<ChipState> = _state.asStateFlow()

    private var folder: CardNode? = null
    private var photos: List<PhotoFile> = emptyList()
    private var uploadJob: Job? = null

    init {
        val accounts = store.accounts
        val selected = store.selectedId?.takeIf { id -> accounts.any { it.id == id } } ?: accounts.firstOrNull()?.id
        _state.update { it.copy(accounts = accounts, selectedId = selected, phonePhotoCount = staging.count, location = recorder.state.value) }
        scope.launch { recorder.state.collect { location -> _state.update { it.copy(location = location) } } }
    }

    private fun validServer(server: String): String? {
        val url = server.trim().toHttpUrlOrNull()
        return if (url != null && url.isHttps) server.trim().trimEnd('/') else null
    }

    // Sign-in

    /** Starts a Facebook sign-in; returns the URL to open in a Custom Tab. */
    fun startBrowserSignIn(server: String): String? {
        val url = validServer(server) ?: run { _state.update { it.copy(accountError = "Enter a valid HTTPS server URL") }; return null }
        val signIn = BrowserSignIn.start(url)
        store.browserSignIn = signIn
        _state.update { it.copy(accountError = null, pendingArchiveChoice = null) }
        return signIn.authorizeUrl
    }

    /** Handles lumiere-uploader://signin?… from the browser. */
    fun completeBrowserSignIn(callback: String) {
        val signIn = store.browserSignIn ?: return
        store.browserSignIn = null
        signIn(signIn.server) {
            val code = signIn.code(callback)
            signInApi.exchangeBrowserCode(signIn.server, code, signIn.verifier)
        }
    }

    fun signInWithDeviceCode(server: String, code: String) {
        val url = validServer(server) ?: run { _state.update { it.copy(accountError = "Enter a valid HTTPS server URL") }; return }
        signIn(url) { SignInOutcome.Credential(signInApi.deviceCode(url, code)) }
    }

    private fun signIn(server: String, outcome: suspend () -> SignInOutcome) {
        if (_state.value.signingIn) return
        _state.update { it.copy(signingIn = true, accountError = null, pendingArchiveChoice = null) }
        scope.launch {
            try {
                when (val result = outcome()) {
                    is SignInOutcome.Credential -> saveAccount(server, result.token)
                    is SignInOutcome.ChooseArchive -> _state.update {
                        it.copy(pendingArchiveChoice = PendingArchiveChoice(server, result.selection, result.archives))
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update { it.copy(accountError = e.message ?: "Sign-in failed") }
            } finally {
                _state.update { it.copy(signingIn = false) }
            }
        }
    }

    fun chooseArchive(archive: ArchiveOption) {
        val pending = _state.value.pendingArchiveChoice ?: return
        if (_state.value.signingIn) return
        _state.update { it.copy(signingIn = true, accountError = null) }
        scope.launch {
            try {
                val credential = signInApi.chooseArchive(pending.server, pending.selection, archive.subdomain)
                _state.update { it.copy(pendingArchiveChoice = null) }
                saveAccount(pending.server, credential)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update { it.copy(accountError = e.message ?: "Could not open that archive") }
            } finally {
                _state.update { it.copy(signingIn = false) }
            }
        }
    }

    fun cancelArchiveChoice() = _state.update { it.copy(pendingArchiveChoice = null) }
    fun clearAccountError() = _state.update { it.copy(accountError = null) }

    private suspend fun saveAccount(server: String, credential: String) {
        val client = clientFactory(server, credential)
        val subdomain = client.photographerSubdomain()
        val name = client.photographerName()
        val existing = _state.value.accounts.firstOrNull { it.server == server && it.subdomain == subdomain }
        val account = existing?.copy(name = name) ?: UploadAccount(name = name, subdomain = subdomain, server = server)
        if (!tokens.setToken(account.id, credential)) error("Could not save the credential on this phone")
        val accounts = _state.value.accounts.filter { it.id != account.id } + account
        store.accounts = accounts
        store.selectedId = account.id
        _state.update { it.copy(accounts = accounts, selectedId = account.id, signInCount = it.signInCount + 1) }
        refreshStatus()
    }

    fun selectAccount(id: String) {
        if (_state.value.running) return
        store.selectedId = id
        _state.update { it.copy(selectedId = id, progress = null) }
        refreshStatus()
    }

    fun signOut() {
        val account = _state.value.selectedAccount ?: return
        if (_state.value.running) return
        if (!tokens.setToken(account.id, null)) {
            _state.update { it.copy(status = "Could not remove the saved credential. Try signing out again.") }
            return
        }
        val accounts = _state.value.accounts.filter { it.id != account.id }
        store.accounts = accounts
        store.selectedId = accounts.firstOrNull()?.id
        _state.update { it.copy(accounts = accounts, selectedId = accounts.firstOrNull()?.id, progress = null, status = "Signed out of ${account.name} on this phone") }
    }

    // Shoot details

    fun setAlbum(value: String) = _state.update { it.copy(album = value) }
    fun setEvent(value: String) = _state.update { it.copy(event = value) }
    fun setVenue(value: String) = _state.update { it.copy(venue = value) }

    // Photos

    private fun ledger(): UploadLedger? = _state.value.selectedAccount?.let { UploadLedger(store.ledgerFile(it)) }

    private fun newCount(): Int {
        val ledger = ledger() ?: return photos.size
        return photos.count { !ledger.contains(it) }
    }

    private fun refreshStatus() {
        if (folder == null) return
        _state.update { it.copy(status = "${photos.size} supported files; ${newCount()} new for this account") }
    }

    /** Scans a picked card or folder. */
    fun select(node: CardNode, phone: Boolean = false) {
        if (_state.value.running) return
        folder = node
        _state.update { it.copy(status = "Reading ${node.name}…", hasFolder = true, progress = null) }
        scope.launch {
            val found = try {
                withContext(io) { CardScanner.photos(node) }
            } catch (e: Exception) {
                _state.update { it.copy(status = "Could not read that folder: ${e.message}", files = emptyList()) }
                return@launch
            }
            photos = found
            val newFiles = withContext(io) { newCount() }
            _state.update {
                it.copy(
                    files = found.map { file -> FileRow(file.filename, file.size) },
                    phonePhotoCount = staging.count,
                    status = when {
                        phone && found.isEmpty() -> "Take or choose photos to upload"
                        phone -> "${found.size} phone photo${if (found.size == 1) "" else "s"} ready to upload"
                        else -> "${found.size} supported files; $newFiles new"
                    },
                )
            }
        }
    }

    /** Points the upload at photos taken or chosen on this phone. */
    fun usePhonePhotos(failed: Int = 0) {
        select(staging.node, phone = true)
        if (failed > 0) scope.launch {
            _state.update { it.copy(status = it.status + ". $failed photo${if (failed == 1) "" else "s"} could not be added.") }
        }
    }

    fun setImporting(importing: Boolean) = _state.update { it.copy(importing = importing) }

    fun removePhonePhotos() {
        staging.removeAll()
        usePhonePhotos()
    }

    fun upload() {
        val current = _state.value
        val account = current.selectedAccount
        val token = account?.let { tokens.token(it.id) }
        val node = folder
        if (current.running || node == null || account == null || token.isNullOrEmpty() || current.album.isBlank()) {
            _state.update { it.copy(status = "Choose a signed-in account, enter an album, then select a card") }
            return
        }
        val context = UploadContext(current.album.trim(), current.event.trim(), current.venue.trim(), recorder.state.value.recordings)
        val uploader = CardUploader(clientFactory(account.server, token), UploadLedger(store.ledgerFile(account)), context)
        _state.update { it.copy(running = true, progress = null) }
        uploadJob = scope.launch {
            try {
                // Rescan so files added since selection (or removed) are current.
                val files = withContext(io) { CardScanner.photos(node) }
                val result = uploader.upload(files) { progress -> _state.update { it.copy(progress = progress) } }
                _state.update { it.copy(status = "${result.uploadedFiles} uploaded; ${result.failedFiles} failed. Upload again to retry.") }
                // Phone photos are copies; drop them once everything is on the server.
                if (node.id == staging.node.id && result.failedFiles == 0) {
                    staging.removeAll()
                    photos = emptyList()
                    _state.update { it.copy(files = emptyList(), phonePhotoCount = 0) }
                }
            } catch (e: CancellationException) {
                _state.update { it.copy(status = "Cancelled. Upload again to continue remaining files.") }
            } catch (e: Exception) {
                _state.update { it.copy(status = e.message ?: "Upload failed") }
            } finally {
                _state.update { it.copy(running = false) }
                uploadJob = null
            }
        }
    }

    fun cancelUpload() { uploadJob?.cancel() }
}
