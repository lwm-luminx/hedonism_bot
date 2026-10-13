import Foundation

/// A photo file found on a card. Files that share a basename (DSC00001.ARW + DSC00001.HIF) are one shot.
public struct PhotoFile: Equatable, Hashable, Sendable {
    public let url: URL
    public let size: Int64
    public let modified: Date

    public init(url: URL, size: Int64, modified: Date) {
        self.url = url
        self.size = size
        self.modified = modified
    }

    public var filename: String { url.lastPathComponent }
    public var basename: String { url.deletingPathExtension().lastPathComponent.lowercased() }
    public var contentType: String? { PhotoFile.contentTypes[url.pathExtension.lowercased()] }

    /// Identifies the file across mounts without hashing it. Cards reuse names after a format,
    /// so the size and capture time are part of the key.
    public var ledgerKey: String {
        "\(filename)|\(size)|\(Int(modified.timeIntervalSince1970))"
    }

    /// The formats hedonism_bot accepts (PhotoTake::CONFIGURATIONS on the server).
    public static let contentTypes: [String: String] = [
        "arw": "image/x-sony-arw",
        "hif": "image/heif",
        "heif": "image/heif",
        "heic": "image/heic",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
    ]
}
