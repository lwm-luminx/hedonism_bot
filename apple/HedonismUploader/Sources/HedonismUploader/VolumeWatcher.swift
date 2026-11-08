import AppKit
import UploaderCore

/// Reports camera cards (removable volumes with a DCIM folder) as they are mounted.
@MainActor
final class VolumeWatcher {
    private let permissions: FolderPermissions
    private var observer: NSObjectProtocol?

    init(permissions: FolderPermissions = FolderPermissions()) {
        self.permissions = permissions
    }

    func start(onCard: @escaping (URL) -> Void) {
        stop()
        let permissions = self.permissions
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification, object: nil, queue: .main
        ) { notification in
            guard let volume = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            MainActor.assumeIsolated {
                if Self.isRemovableCameraCard(volume, permissions: permissions) { onCard(volume) }
            }
        }
    }

    func stop() {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observer = nil
    }

    /// Camera cards that are already mounted (for a launch with a card inserted, or "Upload now").
    static func mountedCards(permissions: FolderPermissions = FolderPermissions()) -> [URL] {
        let keys: [URLResourceKey] = [.volumeIsRemovableKey, .volumeIsEjectableKey]
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return volumes.filter { isRemovableCameraCard($0, permissions: permissions) }
    }

    static func isRemovableCameraCard(_ volume: URL, permissions: FolderPermissions = FolderPermissions()) -> Bool {
        let values = try? volume.resourceValues(forKeys: [.volumeIsRemovableKey, .volumeIsEjectableKey])
        let removable = values?.volumeIsRemovable == true || values?.volumeIsEjectable == true
        guard removable, let granted = try? permissions.resolve(volume) else { return false }
        let accessed = granted.startAccessingSecurityScopedResource()
        defer { if accessed { granted.stopAccessingSecurityScopedResource() } }
        return CardScanner.isCameraCard(granted)
    }

    static func eject(_ volume: URL) throws {
        try NSWorkspace.shared.unmountAndEjectDevice(at: volume)
    }
}
