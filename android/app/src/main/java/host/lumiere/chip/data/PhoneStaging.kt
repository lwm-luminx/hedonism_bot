package host.lumiere.chip.data

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import androidx.exifinterface.media.ExifInterface
import host.lumiere.chip.core.CardScanner
import host.lumiere.chip.core.FileNode
import host.lumiere.chip.core.PhotoFile
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

/**
 * Photos taken with the phone's camera or chosen from its library are copied here, then uploaded
 * from this folder through the same hash-checked CardUploader run a camera card uses.
 */
class PhoneStaging(filesDir: File) {
    val folder = File(filesDir, "Chip-phone-photos")
    val node get() = FileNode(folder.apply { mkdirs() })
    val count: Int get() = if (folder.exists()) CardScanner.photos(node).size else 0

    fun removeAll() { folder.deleteRecursively() }

    /** Shots are grouped by basename, so two library photos that are both IMG_0001 must not share one. */
    fun destination(suggestedName: String, extension: String): File {
        folder.mkdirs()
        val base = suggestedName.substringBeforeLast('.').ifBlank { "Photo" }
        return File(folder, "$base-${UUID.randomUUID().toString().take(8)}.$extension")
    }

    /** A file for the system camera to write a new JPEG into. */
    fun newCameraFile(now: Date = Date()): File =
        destination("Chip-" + SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(now), "jpg")

    /**
     * Copies a library photo. The original file is kept when the server takes its format (DNG
     * including ProRAW-style RAW, ARW, HEIC, JPEG, PNG); anything else (WebP, GIF, other RAW) is
     * re-encoded as JPEG with its capture metadata.
     */
    fun import(resolver: ContentResolver, uri: Uri): File {
        val name = displayName(resolver, uri) ?: "Photo"
        val extension = extensionFor(resolver.getType(uri), name)
        if (extension != null) {
            val target = destination(name, extension)
            resolver.openInputStream(uri)?.use { input -> target.outputStream().use { input.copyTo(it) } }
                ?: throw IOException("Could not read $name")
            return target
        }
        val bitmap = resolver.openInputStream(uri)?.use(BitmapFactory::decodeStream) ?: throw IOException("Could not decode $name")
        val target = destination(name, "jpg")
        target.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 92, it) }
        runCatching {
            val source = resolver.openInputStream(uri)?.use { ExifInterface(it) } ?: return target
            val exif = ExifInterface(target.absolutePath)
            for (tag in COPIED_TAGS) source.getAttribute(tag)?.let { exif.setAttribute(tag, it) }
            exif.saveAttributes()
        }
        return target
    }

    private fun displayName(resolver: ContentResolver, uri: Uri): String? =
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { if (it.moveToFirst()) it.getString(0) else null }

    companion object {
        /** The server-accepted extension for a picked file, or null when it must be re-encoded. */
        fun extensionFor(mimeType: String?, name: String): String? {
            val fromName = name.substringAfterLast('.', "").lowercase()
            if (PhotoFile.isSupported(name)) return fromName
            return when (mimeType?.lowercase()) {
                "image/jpeg" -> "jpg"
                "image/heic" -> "heic"
                "image/heif" -> "heif"
                "image/png" -> "png"
                "image/x-adobe-dng", "image/dng" -> "dng"
                "image/x-sony-arw", "image/arw" -> "arw"
                else -> null
            }
        }

        private val COPIED_TAGS = listOf(
            ExifInterface.TAG_ORIENTATION, ExifInterface.TAG_DATETIME, ExifInterface.TAG_DATETIME_ORIGINAL, ExifInterface.TAG_DATETIME_DIGITIZED,
            ExifInterface.TAG_OFFSET_TIME_ORIGINAL, ExifInterface.TAG_SUBSEC_TIME_ORIGINAL,
            ExifInterface.TAG_MAKE, ExifInterface.TAG_MODEL, ExifInterface.TAG_LENS_MODEL,
            ExifInterface.TAG_F_NUMBER, ExifInterface.TAG_EXPOSURE_TIME, ExifInterface.TAG_PHOTOGRAPHIC_SENSITIVITY,
            ExifInterface.TAG_FOCAL_LENGTH, ExifInterface.TAG_GPS_LATITUDE, ExifInterface.TAG_GPS_LATITUDE_REF,
            ExifInterface.TAG_GPS_LONGITUDE, ExifInterface.TAG_GPS_LONGITUDE_REF, ExifInterface.TAG_ARTIST,
        )
    }
}
