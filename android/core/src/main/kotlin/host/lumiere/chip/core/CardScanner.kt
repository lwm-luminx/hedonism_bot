package host.lumiere.chip.core

/** Finds the photos on a camera card (or any picked folder). */
object CardScanner {
    /** A folder counts as a camera card when it has a DCIM folder at its root. */
    fun dcim(root: CardNode): CardNode? = root.children().firstOrNull { it.isDirectory && it.name == "DCIM" }

    fun isCameraCard(root: CardNode) = dcim(root) != null

    /** Every supported photo under DCIM (or the selected folder), oldest first. Hidden files (._ sidecars) are skipped. */
    fun photos(root: CardNode): List<PhotoFile> {
        val start = dcim(root) ?: root
        val files = mutableListOf<PhotoFile>()
        fun walk(node: CardNode) {
            for (child in node.children()) {
                if (child.name.startsWith(".")) continue
                if (child.isDirectory) walk(child)
                else if (PhotoFile.isSupported(child.name)) files += PhotoFile(child)
            }
        }
        walk(start)
        return files.sortedWith(compareBy<PhotoFile> { it.modified }.thenBy { it.filename })
    }

    /** Groups files into shots by basename, keeping the scan order of each shot's first file. */
    fun shots(files: List<PhotoFile>): List<List<PhotoFile>> =
        files.groupBy { it.basename }.values.toList()
}
