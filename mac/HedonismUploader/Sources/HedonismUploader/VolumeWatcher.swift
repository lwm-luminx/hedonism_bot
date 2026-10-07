import AppKit
import UploaderCore

/// Reports camera cards (removable volumes with a DCIM folder) as they are mounted.
@MainActor
final class VolumeWatcher {
    private var observer: NSObjectProtocol?

    func start(onCard: @escaping (URL) -> Void) {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification, object: nil, queue: .main
        ) { notification in
            guard let volume = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else { return }
            MainActor.assumeIsolated {
                if Self.isRemovableCameraCard(volume) { onCard(volume) }
            }
        }
    }

    /// Camera cards that are already mounted (for a launch with a card inserted, or "Upload now").
    static func mountedCards() -> [URL] {
        let keys: [URLResourceKey] = [.volumeIsRemovableKey, .volumeIsEjectableKey]
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return volumes.filter(isRemovableCameraCard)
    }

    static func isRemovableCameraCard(_ volume: URL) -> Bool {
        let values = try? volume.resourceValues(forKeys: [.volumeIsRemovableKey, .volumeIsEjectableKey])
        let removable = values?.volumeIsRemovable == true || values?.volumeIsEjectable == true
        return removable && CardScanner.isCameraCard(volume)
    }

    static func eject(_ volume: URL) throws {
        try NSWorkspace.shared.unmountAndEjectDevice(at: volume)
    }
}
