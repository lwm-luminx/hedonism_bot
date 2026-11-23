package host.lumiere.chip.data

import android.content.ContentResolver
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import host.lumiere.chip.core.CardNode
import java.io.FileNotFoundException
import java.io.InputStream

/**
 * A folder or file inside a tree picked with the Storage Access Framework, which is how Android
 * reaches SD cards in USB/USB-C card readers and phones' own SD slots.
 */
class DocumentNode(
    private val resolver: ContentResolver,
    private val treeUri: Uri,
    private val documentId: String,
    override val name: String,
    override val isDirectory: Boolean,
    override val size: Long,
    override val modified: Long,
) : CardNode {
    override val id: String get() = documentId

    override fun children(): List<CardNode> {
        if (!isDirectory) return emptyList()
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId)
        val columns = arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME, Document.COLUMN_MIME_TYPE, Document.COLUMN_SIZE, Document.COLUMN_LAST_MODIFIED)
        val nodes = mutableListOf<CardNode>()
        resolver.query(uri, columns, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                nodes += DocumentNode(
                    resolver, treeUri,
                    documentId = cursor.getString(0),
                    name = cursor.getString(1) ?: "",
                    isDirectory = cursor.getString(2) == Document.MIME_TYPE_DIR,
                    size = if (cursor.isNull(3)) 0 else cursor.getLong(3),
                    modified = if (cursor.isNull(4)) 0 else cursor.getLong(4),
                )
            }
        }
        return nodes
    }

    override fun open(): InputStream =
        resolver.openInputStream(DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId))
            ?: throw FileNotFoundException(name)

    companion object {
        fun tree(resolver: ContentResolver, treeUri: Uri): DocumentNode {
            val id = DocumentsContract.getTreeDocumentId(treeUri)
            val name = resolver.query(DocumentsContract.buildDocumentUriUsingTree(treeUri, id), arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)
                ?.use { if (it.moveToFirst()) it.getString(0) else null } ?: "Card"
            return DocumentNode(resolver, treeUri, id, name, isDirectory = true, size = 0, modified = 0)
        }
    }
}
