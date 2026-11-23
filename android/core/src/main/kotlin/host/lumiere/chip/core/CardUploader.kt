package host.lumiere.chip.core

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext

/**
 * Uploads missing card contents through the standard photo-promise upload flow, the same way as
 * the iOS CardUploader: hash everything first, ask the server which content it already has, then
 * upload only what's missing, one shot (RAW + JPEG pair) at a time.
 */
class CardUploader(
    private val client: HedonismClient,
    private val ledger: UploadLedger,
    private val context: UploadContext? = null,
) {
    data class Progress(
        val totalFiles: Int,
        val uploadedFiles: Int = 0,
        val failedFiles: Int = 0,
        val currentFile: String? = null,
    )

    /**
     * Uploads the folder's new files, reporting progress after each file. Throws only for problems
     * that stop the whole run (bad token, server down); a single failed file is counted and skipped.
     */
    suspend fun upload(files: List<PhotoFile>, progress: (Progress) -> Unit): Progress {
        // Read and hash every file before creating promises or transmitting any bytes.
        val hashes = HashMap<String, FileHasher.Digests>()
        for (file in files) {
            currentCoroutineContext().ensureActive()
            progress(Progress(files.size, currentFile = "Checking ${file.filename}"))
            hashes[file.id] = withContext(Dispatchers.IO) { FileHasher.digests(file.open()) }
        }
        val seen = client.uploadedHashes(files.mapNotNull { hashes[it.id]?.sha256 }).toMutableSet()
        val missing = files.filter { file -> hashes[file.id]?.let { seen.add(it.sha256Key) } ?: false }
        val shots = CardScanner.shots(missing)
        var state = Progress(missing.size)
        progress(state)

        if (shots.isNotEmpty()) {
            val promiseId = client.createPromise(context)
            for (shot in shots) {
                currentCoroutineContext().ensureActive()
                val pending = client.attach(promiseId, shot.map { it to hashes.getValue(it.id) })
                for ((file, target) in shot.zip(pending)) {
                    currentCoroutineContext().ensureActive()
                    state = state.copy(currentFile = file.filename)
                    progress(state)
                    try {
                        client.upload(file, target)
                        client.finish(target, succeeded = true)
                        withContext(Dispatchers.IO) { ledger.record(file) }
                        state = state.copy(uploadedFiles = state.uploadedFiles + 1)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: HedonismException) {
                        if (e.isFatal) throw e
                        state = failed(state, target)
                    } catch (e: Exception) {
                        currentCoroutineContext().ensureActive()
                        state = failed(state, target)
                    }
                    progress(state)
                }
            }
        }
        state = state.copy(currentFile = null)
        progress(state)
        return state
    }

    private suspend fun failed(state: Progress, target: PendingUpload): Progress {
        withContext(NonCancellable) { runCatching { client.finish(target, succeeded = false) } }
        return state.copy(failedFiles = state.failedFiles + 1)
    }
}
