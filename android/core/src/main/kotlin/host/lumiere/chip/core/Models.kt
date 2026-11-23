package host.lumiere.chip.core

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.UUID

/** Public service endpoints shared by the desktop and mobile clients. */
object ServiceEndpoints {
    const val API = "https://api.lumiere.host"
    private val subdomainPattern = Regex("^[a-z0-9]+(?:-[a-z0-9]+)*$")

    fun photographerSite(subdomain: String): String? =
        if (subdomainPattern.matches(subdomain) && subdomain !in setOf("api", "www")) "https://$subdomain.lumiere.host" else null

    fun privacy(server: String) = server.trimEnd('/') + "/privacy"
    fun dataDeletion(server: String) = server.trimEnd('/') + "/data-deletion"
}

/** A signed-in destination. Its credential is kept separately (Android Keystore). */
@Serializable
data class UploadAccount(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val subdomain: String,
    val server: String,
) {
    val host: String get() = server.substringAfter("://").substringBefore('/')
}

/** Explicit album destination and shoot details. */
data class UploadContext(
    val albumName: String,
    val event: String,
    val venue: String,
    val locationRecordings: List<LocationRecording> = emptyList(),
)

@Serializable
data class LocationSample(
    /** Epoch milliseconds. */
    val timestamp: Long,
    val latitude: Double,
    val longitude: Double,
    val accuracy: Double,
)

@Serializable
data class LocationRecording(
    val startedAt: Long = System.currentTimeMillis(),
    val stoppedAt: Long? = null,
    val samples: List<LocationSample> = emptyList(),
) {
    /** Same JSON shape as the iOS app: ISO 8601 times to the second. */
    fun uploadValue(now: Long = System.currentTimeMillis()): JsonObject = buildJsonObject {
        put("startedAt", iso(startedAt))
        put("stoppedAt", iso(stoppedAt ?: now))
        put("samples", buildJsonArray {
            for (sample in samples) add(buildJsonObject {
                put("timestamp", iso(sample.timestamp))
                put("latitude", sample.latitude)
                put("longitude", sample.longitude)
                put("accuracy", sample.accuracy)
            })
        })
    }

    companion object {
        fun iso(millis: Long): String = Instant.ofEpochMilli(millis).truncatedTo(ChronoUnit.SECONDS).toString()
    }
}
