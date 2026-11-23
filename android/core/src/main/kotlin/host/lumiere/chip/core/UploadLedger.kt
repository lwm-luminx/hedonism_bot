package host.lumiere.chip.core

import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.io.File

/** Remembers which card files were already uploaded so re-inserting a card only sends new shots. */
class UploadLedger(private val file: File) {
    private val keys: MutableSet<String> = runCatching {
        Json.decodeFromString(ListSerializer(String.serializer()), file.readText()).toMutableSet()
    }.getOrDefault(mutableSetOf())

    @Synchronized fun contains(photo: PhotoFile) = photo.ledgerKey in keys

    @Synchronized fun record(photo: PhotoFile) {
        keys += photo.ledgerKey
        file.parentFile?.mkdirs()
        val temp = File(file.parentFile, file.name + ".tmp")
        temp.writeText(Json.encodeToString(ListSerializer(String.serializer()), keys.sorted()))
        if (!temp.renameTo(file)) { file.delete(); temp.renameTo(file) }
    }

    @get:Synchronized val count: Int get() = keys.size
}
