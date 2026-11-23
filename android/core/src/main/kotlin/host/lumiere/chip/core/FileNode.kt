package host.lumiere.chip.core

import java.io.File
import java.io.InputStream

/** A [CardNode] backed by java.io.File: the phone-photo staging folder and tests. */
class FileNode(val file: File) : CardNode {
    override val name: String get() = file.name
    override val isDirectory: Boolean get() = file.isDirectory
    override val id: String get() = file.absolutePath
    override val size: Long get() = file.length()
    override val modified: Long get() = file.lastModified()
    override fun children(): List<CardNode> = file.listFiles()?.map(::FileNode) ?: emptyList()
    override fun open(): InputStream = file.inputStream()
}
