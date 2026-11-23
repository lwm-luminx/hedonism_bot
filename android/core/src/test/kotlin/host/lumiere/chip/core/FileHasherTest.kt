package host.lumiere.chip.core

import org.junit.Assert.assertEquals
import org.junit.Test

class FileHasherTest {
    private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it) }

    @Test fun hashesInChunks() {
        val data = ByteArray(10_000) { (it % 251).toByte() }
        val whole = FileHasher.digests(data.inputStream())
        val chunked = FileHasher.digests(data.inputStream(), chunkSize = 7)
        assertEquals(whole, chunked)
    }

    @Test fun knownVectors() {
        val digests = FileHasher.digests("abc".toByteArray().inputStream())
        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", hex(digests.sha256))
        assertEquals("900150983cd24fb0d6963f7d28e17f72", hex(digests.md5))
        assertEquals("ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=", digests.sha256Key)
    }
}
