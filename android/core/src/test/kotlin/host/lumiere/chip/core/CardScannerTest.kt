package host.lumiere.chip.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CardScannerTest {
    @Test fun findsSupportedPhotosUnderDcimOldestFirst() {
        val card = FileNode(Fixtures.card())
        assertTrue(CardScanner.isCameraCard(card))
        val photos = CardScanner.photos(card)
        assertEquals(listOf("DSC00001.ARW", "DSC00001.HIF", "DSC00002.JPG"), photos.map { it.filename })
    }

    @Test fun scansAPickedDcimFolderDirectly() {
        val dcim = FileNode(Fixtures.card().resolve("DCIM"))
        assertFalse(CardScanner.isCameraCard(dcim))
        assertEquals(3, CardScanner.photos(dcim).size)
    }

    @Test fun groupsRawAndJpegIntoShots() {
        val shots = CardScanner.shots(CardScanner.photos(FileNode(Fixtures.card())))
        assertEquals(listOf(listOf("DSC00001.ARW", "DSC00001.HIF"), listOf("DSC00002.JPG")), shots.map { shot -> shot.map { it.filename } })
    }

    @Test fun photoFileMetadataMatchesIOS() {
        val file = CardScanner.photos(FileNode(Fixtures.card())).first()
        assertEquals("image/x-sony-arw", file.contentType)
        assertEquals("dsc00001", file.basename)
        assertEquals("DSC00001.ARW|7|1700000000", file.ledgerKey)
        assertTrue(PhotoFile.isSupported("IMG_0001.HEIC"))
        assertFalse(PhotoFile.isSupported("IMG_0001.GIF"))
    }
}
