import Foundation

/// Finds camera cards and the photos on them.
public enum CardScanner {
    /// A volume counts as a camera card when it has a DCIM folder at its root.
    public static func isCameraCard(_ volume: URL, fileManager: FileManager = .default) -> Bool {
        var isDirectory: ObjCBool = false
        let dcim = volume.appendingPathComponent("DCIM", isDirectory: true)
        return fileManager.fileExists(atPath: dcim.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    /// Every supported photo under DCIM (or the selected photo folder), oldest first. Hidden files (macOS ._ files) are skipped.
    public static func photos(on volume: URL, fileManager: FileManager = .default) -> [PhotoFile] {
        let dcim = isCameraCard(volume, fileManager: fileManager) ? volume.appendingPathComponent("DCIM", isDirectory: true) : volume
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: dcim, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var files: [PhotoFile] = []
        for case let url as URL in enumerator {
            guard PhotoFile.contentTypes[url.pathExtension.lowercased()] != nil,
                  let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { continue }
            files.append(PhotoFile(
                url: url,
                size: Int64(values.fileSize ?? 0),
                modified: values.contentModificationDate ?? .distantPast
            ))
        }
        return files.sorted { ($0.modified, $0.filename) < ($1.modified, $1.filename) }
    }

    /// Groups files into shots by basename, keeping the scan order of each shot's first file.
    public static func shots(_ files: [PhotoFile]) -> [[PhotoFile]] {
        var order: [String] = []
        var groups: [String: [PhotoFile]] = [:]
        for file in files {
            if groups[file.basename] == nil { order.append(file.basename) }
            groups[file.basename, default: []].append(file)
        }
        return order.compactMap { groups[$0] }
    }
}
