import Foundation

/// A disk image attached as a volume, standing in for an SD card in tests.
///
/// macOS treats an attached image the way it treats a card in a reader: the volume is removable
/// and ejectable, it is formatted FAT32 or ExFAT like a real card, it is listed by `FileManager`
/// and announced by `NSWorkspace.didMountNotification`, macOS writes the same AppleDouble (`._`)
/// and index files onto it, and it can be attached read-only like a card with its lock switch on.
/// Each instance owns one image file and at most one attachment at a time.
public final class DiskImageCard {
    /// The SD Association's formats: FAT32 for SDHC (4–32 GB) and ExFAT for SDXC.
    public enum Format: String, CaseIterable, Sendable {
        case fat32 = "MS-DOS FAT32"
        case exFAT = "ExFAT"
    }

    public struct AttachOptions: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        /// The card's write-protect switch.
        public static let readOnly = AttachOptions(rawValue: 1 << 0)
        /// Mounts the volume hidden from Finder (and from `mountedVolumeURLs(... .skipHiddenVolumes)`).
        public static let hidden = AttachOptions(rawValue: 1 << 1)
    }

    public struct Failure: Error, CustomStringConvertible {
        public let description: String
    }

    /// The image file on disk.
    public let image: URL
    /// The volume label, which is also the mount point's last path component.
    public let name: String
    public let format: Format
    /// Where the volume is mounted, or nil while detached.
    public private(set) var volume: URL?

    /// Creates and attaches a card image with an empty `DCIM/100MSDCF` folder.
    public init(format: Format = .fat32, options: AttachOptions = []) throws {
        self.format = format
        // FAT32 labels are at most 11 upper-case characters; a random suffix keeps concurrent tests apart.
        let suffix = String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })
        name = "CARD" + suffix
        image = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).dmg")
        // FAT32 needs at least 33 MB; hdiutil refuses smaller FAT32 images.
        _ = try Self.hdiutil(["create", "-quiet", "-size", "40m", "-fs", format.rawValue, "-volname", name, image.path])
        // Mount once and let go before the real attach: on some macOS releases the first mount of a fresh FAT
        // image gets a throwaway volume UUID, and grants (security-scoped bookmarks) follow the volume by its UUID.
        try attach(options: .hidden)
        try detach()
        let root = try attach(options: options)
        if !options.contains(.readOnly) {
            try FileManager.default.createDirectory(at: root.appendingPathComponent("DCIM/100MSDCF"), withIntermediateDirectories: true)
        }
    }

    deinit {
        try? detach(force: true)
        try? FileManager.default.removeItem(at: image)
    }

    public var isAttached: Bool {
        guard let volume else { return false }
        return FileManager.default.fileExists(atPath: volume.path)
    }

    /// Inserts the card. Returns the mount point.
    @discardableResult
    public func attach(options: AttachOptions = []) throws -> URL {
        if isAttached { throw Failure(description: "\(name) is already attached at \(volume!.path)") }
        var arguments = ["attach", "-plist", "-noverify", "-noautoopen", image.path]
        if options.contains(.readOnly) { arguments.append("-readonly") }
        if options.contains(.hidden) { arguments.append("-nobrowse") }
        let output = try Self.hdiutil(arguments)
        guard let plist = try PropertyListSerialization.propertyList(from: output, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]],
              let mountPoint = entities.compactMap({ $0["mount-point"] as? String }).first else {
            throw Failure(description: "hdiutil attach reported no mount point for \(image.path)")
        }
        let root = URL(fileURLWithPath: mountPoint, isDirectory: true)
        volume = root
        return root
    }

    /// Removes the card. `force` pulls it even while files on it are open, like yanking a card from the reader.
    public func detach(force: Bool = false) throws {
        guard let volume else { return }
        self.volume = nil
        // Already gone (for example ejected through NSWorkspace): nothing to detach.
        guard FileManager.default.fileExists(atPath: volume.path) else { return }
        if force {
            _ = try Self.hdiutil(["detach", "-quiet", "-force", volume.path])
            return
        }
        // Spotlight and fseventsd hold a freshly mounted volume open for a moment; wait them out like Finder does.
        var attempt = 0
        while true {
            do {
                _ = try Self.hdiutil(["detach", "-quiet", volume.path])
                return
            } catch where attempt < 10 {
                attempt += 1
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    /// The volume UUID macOS assigned, which grants (security-scoped bookmarks) use to find the volume again.
    public func identity() throws -> String? {
        try root().resourceValues(forKeys: [.volumeUUIDStringKey]).volumeUUIDString
    }

    /// Detaches and attaches again, for example to flip the write-protect switch.
    @discardableResult
    public func reattach(options: AttachOptions = []) throws -> URL {
        try detach()
        return try attach(options: options)
    }

    /// Writes a camera file under `DCIM/100MSDCF`. The card must be attached writable.
    @discardableResult
    public func add(_ filename: String, contents: String = "bytes",
                    modified: Date = Date(timeIntervalSince1970: 1_791_331_200)) throws -> URL {
        let url = try root().appendingPathComponent("DCIM/100MSDCF/\(filename)")
        try Data(contents.utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path)
        return url
    }

    /// Writes a file the way Finder or a camera's companion app would, with an extended attribute, which
    /// makes macOS keep a `._` AppleDouble sidecar next to it on FAT and ExFAT volumes.
    @discardableResult
    public func addWithSidecar(_ filename: String, contents: String = "bytes") throws -> URL {
        let url = try add(filename, contents: contents)
        let attribute = "com.apple.metadata:kMDItemWhereFroms"
        let value = Data("camera".utf8)
        let status = value.withUnsafeBytes { bytes in
            setxattr(url.path, attribute, bytes.baseAddress, bytes.count, 0, 0)
        }
        guard status == 0 else { throw Failure(description: "setxattr failed with errno \(errno) on \(url.path)") }
        return url
    }

    public func root() throws -> URL {
        guard let volume, isAttached else { throw Failure(description: "\(name) is not attached") }
        return volume
    }

    /// The volume's resource values, read the way the uploader reads them.
    public func resourceValues() throws -> URLResourceValues {
        try root().resourceValues(forKeys: [.volumeIsRemovableKey, .volumeIsEjectableKey, .volumeIsReadOnlyKey,
                                            .volumeLocalizedFormatDescriptionKey, .volumeNameKey])
    }

    @discardableResult
    static func hdiutil(_ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = arguments
        let stdout = Pipe(), stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errors = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(decoding: errors, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw Failure(description: "hdiutil \(arguments.first ?? "") failed (\(process.terminationStatus)): \(message)")
        }
        return output
    }
}
