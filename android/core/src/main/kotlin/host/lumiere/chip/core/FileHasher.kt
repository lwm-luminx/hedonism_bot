package host.lumiere.chip.core

import java.io.InputStream
import java.security.MessageDigest

/** Hashes a file in chunks so 70 MB RAW files never sit in memory whole. */
object FileHasher {
    class Digests(
        /** SHA-256, the photo's identity on the server (imageHash). */
        val sha256: ByteArray,
        /** MD5, which storage checks the upload against (Content-MD5). */
        val md5: ByteArray,
    ) {
        val sha256Key: String get() = Base64Codec.encode(sha256)
        override fun equals(other: Any?) = other is Digests && other.sha256.contentEquals(sha256) && other.md5.contentEquals(md5)
        override fun hashCode() = sha256.contentHashCode()
    }

    fun digests(input: InputStream, chunkSize: Int = 4 shl 20): Digests = input.use { stream ->
        val sha = MessageDigest.getInstance("SHA-256")
        val md5 = MessageDigest.getInstance("MD5")
        val buffer = ByteArray(chunkSize)
        while (true) {
            val read = stream.read(buffer)
            if (read < 0) break
            sha.update(buffer, 0, read)
            md5.update(buffer, 0, read)
        }
        Digests(sha.digest(), md5.digest())
    }
}

/** java.util.Base64 is available on JVM and on Android API 26+, which is Chip's minimum. */
object Base64Codec {
    fun encode(bytes: ByteArray): String = java.util.Base64.getEncoder().encodeToString(bytes)
    fun decode(value: String): ByteArray? = try { java.util.Base64.getDecoder().decode(value) } catch (_: IllegalArgumentException) { null }
    fun urlEncodeNoPadding(bytes: ByteArray): String = java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
}
