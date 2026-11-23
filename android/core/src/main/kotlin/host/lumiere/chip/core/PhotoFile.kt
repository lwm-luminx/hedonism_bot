package host.lumiere.chip.core

import java.io.InputStream

/**
 * A node in a folder tree: a camera card picked through the Storage Access Framework, the app's
 * phone-photo staging folder, or a test directory. Keeps the scanner independent of where files live.
 */
interface CardNode {
    val name: String
    val isDirectory: Boolean
    /** Stable identifier (a document URI or an absolute path). */
    val id: String
    val size: Long
    /** Last-modified time in epoch milliseconds, or 0 when unknown. */
    val modified: Long
    fun children(): List<CardNode>
    fun open(): InputStream
}

/** A photo file found on a card. Files that share a basename (DSC00001.ARW + DSC00001.HIF) are one shot. */
class PhotoFile(val node: CardNode) {
    val id: String get() = node.id
    val filename: String get() = node.name
    val size: Long get() = node.size
    val modified: Long get() = node.modified
    val pathExtension: String get() = filename.substringAfterLast('.', "").lowercase()
    val basename: String get() = filename.substringBeforeLast('.').lowercase()
    val contentType: String? get() = contentTypes[pathExtension]

    /**
     * Identifies the file across mounts without hashing it. Cards reuse names after a format,
     * so the size and capture time are part of the key. Matches the iOS ledger format.
     */
    val ledgerKey: String get() = "$filename|$size|${modified / 1000}"

    fun open(): InputStream = node.open()

    override fun equals(other: Any?) = other is PhotoFile && other.id == id && other.size == size && other.modified == modified
    override fun hashCode() = id.hashCode()
    override fun toString() = "PhotoFile($filename, $size)"

    companion object {
        /** The formats hedonism_bot accepts (PhotoTake::CONFIGURATIONS on the server). */
        val contentTypes: Map<String, String> = mapOf(
            "arw" to "image/x-sony-arw",
            "dng" to "image/x-adobe-dng",
            "hif" to "image/heif",
            "heif" to "image/heif",
            "heic" to "image/heic",
            "jpg" to "image/jpeg",
            "jpeg" to "image/jpeg",
            "png" to "image/png",
        )

        fun isSupported(filename: String) = contentTypes.containsKey(filename.substringAfterLast('.', "").lowercase())
    }
}
