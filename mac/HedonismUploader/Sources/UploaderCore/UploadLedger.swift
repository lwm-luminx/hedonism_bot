import Foundation

/// Remembers which card files were already uploaded so re-inserting a card only sends new shots.
public final class UploadLedger: @unchecked Sendable {
    private let url: URL
    private let lock = NSLock()
    private var keys: Set<String>

    public init(url: URL) {
        self.url = url
        if let data = try? Data(contentsOf: url),
           let stored = try? JSONDecoder().decode([String].self, from: data) {
            keys = Set(stored)
        } else {
            keys = []
        }
    }

    public static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("HedonismUploader/uploaded.json")
    }

    public func contains(_ file: PhotoFile) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return keys.contains(file.ledgerKey)
    }

    public func record(_ file: PhotoFile) throws {
        lock.lock(); defer { lock.unlock() }
        keys.insert(file.ledgerKey)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(keys.sorted()).write(to: url, options: .atomic)
    }

    public var count: Int {
        lock.lock(); defer { lock.unlock() }
        return keys.count
    }
}
