package host.lumiere.chip.location

import host.lumiere.chip.core.LocationRecording
import host.lumiere.chip.core.LocationSample
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.io.File

/**
 * The shoot's location history, shared by the recording service and the upload screen. Saved after
 * every sample, so an app that Android stops still keeps what it recorded.
 */
class LocationRecorder(private val file: File) {
    data class State(
        val recordings: List<LocationRecording> = emptyList(),
        val recording: Boolean = false,
        val status: String = "Record during your shoot to match photos to venues later.",
    ) {
        val sampleCount: Int get() = recordings.sumOf { it.samples.size }
    }

    private val _state = MutableStateFlow(State(load()))
    val state: StateFlow<State> = _state.asStateFlow()

    private fun load(): List<LocationRecording> {
        val saved = runCatching { Json.decodeFromString(ListSerializer(LocationRecording.serializer()), file.readText()) }.getOrDefault(emptyList())
        // A stopped app cannot guarantee coverage after its last saved sample.
        return saved.map { if (it.stoppedAt == null) it.copy(stoppedAt = it.samples.lastOrNull()?.timestamp ?: it.startedAt) else it }
    }

    private fun save(state: State) {
        _state.value = state
        runCatching {
            file.parentFile?.mkdirs()
            file.writeText(Json.encodeToString(ListSerializer(LocationRecording.serializer()), state.recordings))
        }.onFailure {
            _state.value = state.copy(recording = false, status = "Could not save location history: ${it.message}")
        }
    }

    fun start(now: Long = System.currentTimeMillis()) {
        val current = _state.value
        if (current.recording) return
        save(current.copy(recordings = current.recordings + LocationRecording(startedAt = now), recording = true,
            status = "Recording location. Stop when your shoot ends."))
    }

    fun stop(now: Long = System.currentTimeMillis()) {
        val current = _state.value
        if (!current.recording) return
        val recordings = current.recordings.toMutableList()
        recordings[recordings.lastIndex] = recordings.last().copy(stoppedAt = now)
        save(current.copy(recordings = recordings, recording = false, status = "Recording stopped. History is saved for later uploads."))
    }

    fun delete() {
        save(State(status = "Location history deleted from this phone."))
    }

    fun setStatus(status: String) { _state.value = _state.value.copy(status = status) }

    /** Keeps fixes within 100 m accuracy that arrive after the current recording started. */
    fun add(sample: LocationSample) {
        val current = _state.value
        if (!current.recording || current.recordings.isEmpty()) return
        val last = current.recordings.last()
        if (sample.accuracy < 0 || sample.accuracy > 100 || sample.timestamp < last.startedAt) return
        val recordings = current.recordings.toMutableList()
        recordings[recordings.lastIndex] = last.copy(samples = last.samples + sample)
        save(current.copy(recordings = recordings))
    }
}
