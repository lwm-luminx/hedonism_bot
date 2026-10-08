import AppKit
import ServiceManagement
import UploaderCore

@MainActor
final class AppModel: ObservableObject {
    @Published var serverURL: String { didSet { defaults.set(serverURL, forKey: "serverURL") } }
    @Published var albumPrefix: String { didSet { defaults.set(albumPrefix, forKey: "albumPrefix") } }
    @Published var autoUpload: Bool { didSet { defaults.set(autoUpload, forKey: "autoUpload") } }
    @Published var ejectWhenDone: Bool { didSet { defaults.set(ejectWhenDone, forKey: "ejectWhenDone") } }
    @Published var token: String { didSet { Keychain.setToken(token) } }

    @Published private(set) var status = "Waiting for a camera card"
    @Published private(set) var progress: CardUploader.Progress?
    @Published private(set) var connectedAs: String?
    @Published private(set) var isUploading = false

    private let defaults = UserDefaults.standard
    private let ledger = UploadLedger(url: UploadLedger.defaultURL)
    private let watcher = VolumeWatcher()
    private var queue: [URL] = []

    init() {
        serverURL = defaults.string(forKey: "serverURL") ?? ""
        albumPrefix = defaults.string(forKey: "albumPrefix") ?? "SD"
        autoUpload = defaults.object(forKey: "autoUpload") as? Bool ?? true
        ejectWhenDone = defaults.bool(forKey: "ejectWhenDone")
        token = Keychain.token() ?? ""

        watcher.start { [weak self] volume in
            guard let self, self.autoUpload else { return }
            self.enqueue(volume)
        }
        if autoUpload { VolumeWatcher.mountedCards().forEach(enqueue) }
    }

    var isConfigured: Bool { client != nil }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }

    private var client: HedonismClient? {
        guard let url = URL(string: serverURL.trimmingCharacters(in: .whitespaces)), url.scheme != nil,
              !token.isEmpty else { return nil }
        return HedonismClient(serverURL: url, token: token)
    }

    func uploadMountedCards() {
        let cards = VolumeWatcher.mountedCards()
        if cards.isEmpty { status = "No camera card is inserted" }
        cards.forEach(enqueue)
    }

    func testConnection() async {
        guard let client else { status = "Add the server URL and token in Settings"; return }
        do {
            connectedAs = try await client.photographerName()
            status = "Connected as \(connectedAs ?? "")"
        } catch {
            connectedAs = nil
            status = error.localizedDescription
        }
    }

    private func enqueue(_ volume: URL) {
        guard !queue.contains(volume) else { return }
        queue.append(volume)
        if !isUploading {
            isUploading = true
            Task { await drainQueue() }
        }
    }

    private func drainQueue() async {
        isUploading = true
        defer { isUploading = false }
        while !queue.isEmpty {
            let volume = queue.removeFirst()
            await upload(volume)
        }
    }

    private func upload(_ volume: URL) async {
        let name = volume.lastPathComponent
        guard let client else {
            status = "\(name) inserted, but the server URL or token is missing"
            return
        }
        let uploader = CardUploader(client: client, ledger: ledger, albumPrefix: albumPrefix)
        status = "Uploading from \(name)"
        do {
            let result = try await uploader.upload(volume: volume) { progress in
                Task { @MainActor in self.progress = progress }
            }
            progress = nil
            if result.totalFiles == 0 {
                status = "\(name): nothing new to upload"
            } else if result.failedFiles > 0 {
                status = "\(name): \(result.uploadedFiles) uploaded, \(result.failedFiles) failed (they retry next time)"
            } else {
                status = "\(name): uploaded \(result.uploadedFiles) files"
            }
            if ejectWhenDone && result.failedFiles == 0 {
                try? VolumeWatcher.eject(volume)
            }
        } catch {
            progress = nil
            status = "\(name): \(error.localizedDescription)"
        }
    }
}
