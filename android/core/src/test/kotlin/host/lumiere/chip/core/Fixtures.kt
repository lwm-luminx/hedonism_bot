package host.lumiere.chip.core

import java.io.File
import java.nio.file.Files

object Fixtures {
    fun tempDir(): File = Files.createTempDirectory("chip-test").toFile().apply { deleteOnExit() }

    /** Writes a file with fixed bytes and modification time (epoch seconds). */
    fun write(dir: File, path: String, bytes: ByteArray, modifiedSeconds: Long): File =
        File(dir, path).apply {
            parentFile.mkdirs()
            writeBytes(bytes)
            setLastModified(modifiedSeconds * 1000)
        }

    fun card(): File {
        val root = tempDir()
        write(root, "DCIM/100MSDCF/DSC00001.ARW", "raw-one".toByteArray(), 1_700_000_000)
        write(root, "DCIM/100MSDCF/DSC00001.HIF", "heif-one".toByteArray(), 1_700_000_000)
        write(root, "DCIM/100MSDCF/DSC00002.JPG", "jpeg-two".toByteArray(), 1_700_000_100)
        write(root, "DCIM/100MSDCF/._DSC00002.JPG", "sidecar".toByteArray(), 1_700_000_100)
        write(root, "DCIM/100MSDCF/MOV00003.MP4", "video".toByteArray(), 1_700_000_200)
        write(root, "PRIVATE/M4ROOT/THUMB.JPG", "not-dcim".toByteArray(), 1_600_000_000)
        return root
    }
}
