package host.lumiere.chip.core

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class LedgerAndModelsTest {
    @Test fun ledgerPersistsAcrossInstances() {
        val file = File(Fixtures.tempDir(), "accounts/a.json")
        val photo = CardScanner.photos(FileNode(Fixtures.card())).first()
        val ledger = UploadLedger(file)
        assertFalse(ledger.contains(photo))
        ledger.record(photo)
        assertTrue(UploadLedger(file).contains(photo))
        assertEquals(1, UploadLedger(file).count)
    }

    @Test fun ledgerIgnoresCorruptFile() {
        val file = File(Fixtures.tempDir(), "ledger.json").apply { writeText("not json") }
        assertEquals(0, UploadLedger(file).count)
    }

    @Test fun photographerSiteValidatesSubdomain() {
        assertEquals("https://rick-mark.lumiere.host", ServiceEndpoints.photographerSite("rick-mark"))
        assertNull(ServiceEndpoints.photographerSite("api"))
        assertNull(ServiceEndpoints.photographerSite("Bad_Name"))
        assertEquals("https://api.lumiere.host/privacy", ServiceEndpoints.privacy("https://api.lumiere.host/"))
    }

    @Test fun locationRecordingUploadValueUsesIso8601() {
        val recording = LocationRecording(
            startedAt = 1_700_000_000_500,
            stoppedAt = null,
            samples = listOf(LocationSample(1_700_000_010_000, 39.74, -104.99, 8.0)),
        )
        val value = recording.uploadValue(now = 1_700_000_100_000)
        assertEquals(JsonPrimitive("2023-11-14T22:13:20Z"), value["startedAt"])
        assertEquals(JsonPrimitive("2023-11-14T22:15:00Z"), value["stoppedAt"])
        val sample = (value["samples"] as JsonArray).single() as JsonObject
        assertEquals(JsonPrimitive(39.74), sample["latitude"])
        assertEquals(JsonPrimitive("2023-11-14T22:13:30Z"), sample["timestamp"])
    }

    @Test fun accountHost() {
        assertEquals("api.lumiere.host", UploadAccount(name = "A", subdomain = "a", server = "https://api.lumiere.host").host)
    }
}
