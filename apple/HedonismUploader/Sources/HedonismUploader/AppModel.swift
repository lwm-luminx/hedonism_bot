import AppKit
import AuthenticationServices
import CryptoKit
import ServiceManagement
import UploaderCore

@MainActor
final class AppModel: ObservableObject {
    @Published var serverURL: String { didSet {
        defaults.set(serverURL, forKey: "serverURL")
        if oldValue != serverURL { connectedAs = nil; loadArchivePaths() }
    } }
    @Published var autoUpload: Bool { didSet { defaults.set(autoUpload, forKey: "autoUpload") } }
    @Published var ejectWhenDone: Bool { didSet { defaults.set(ejectWhenDone, forKey: "ejectWhenDone") } }
    @Published var token: String { didSet { Keychain.setToken(token) } }

    @Published private(set) var status = "Waiting for a camera card"
    @Published private(set) var progress: CardUploader.Progress?
    @Published private(set) var connectedAs: String?
    @Published private(set) var isUploading = false

    @Published private(set) var archivePaths: [String] = []
    @Published private(set) var archiveStatus = "No archive folders connected"
    private var archiveSyncTask: Task<Void, Never>?

    @Published private(set) var signingIn = false
    private let browserSignIn = BrowserSignIn()

    private let defaults = UserDefaults.standard
    private let uploader = UploaderClient()
    private let permissions = FolderPermissions()
    private let watcher = VolumeWatcher()
    private var queue: [URL] = []

    init() {
        serverURL = defaults.string(forKey: "serverURL") ?? ServiceEndpoints.api.absoluteString
        autoUpload = defaults.object(forKey: "autoUpload") as? Bool ?? true
        ejectWhenDone = defaults.bool(forKey: "ejectWhenDone")
        token = Keychain.token() ?? ""

        watcher.start { [weak self] volume in
            guard let self, self.autoUpload else { return }
            self.enqueue(volume)
        }
        if autoUpload { VolumeWatcher.mountedCards().forEach(enqueue) }
        loadArchivePaths()
        if !token.isEmpty { Task { await testConnection() } }
        archiveSyncTask = Task { [weak self] in
            while !Task.isCancelled {
                guard self != nil else { return }
                await self?.syncArchiveStorage()
                do { try await Task.sleep(nanoseconds: 60_000_000_000) }
                catch { return }
            }
        }
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

    func signIn(photographer: String, deviceCode: String? = nil) async {
        guard !signingIn, !isUploading else { return }
        guard let server = URL(string: serverURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              server.scheme == "https" || (server.scheme == "http" && ["localhost", "127.0.0.1"].contains(server.host ?? "")) else {
            status = "Enter a valid HTTPS server URL"
            return
        }
        signingIn = true
        defer { signingIn = false }
        do {
            let credential: String
            if let deviceCode {
                credential = try await DeviceCodeSignIn.signIn(server: server, code: deviceCode)
            } else {
                credential = try await browserSignIn.signIn(server: server, photographer: photographer.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            let name = try await HedonismClient(serverURL: server, token: credential).photographerName()
            guard server.absoluteString == serverURL.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard Keychain.setToken(credential) else {
                status = "Could not save the credential in Keychain. Please try again."
                return
            }
            token = credential
            connectedAs = name
            loadArchivePaths()
            await syncArchiveStorage()
            status = "Connected as \(name)"
        } catch { status = error.localizedDescription }
    }

    func signOut() {
        guard !isUploading, !signingIn else { return }
        guard Keychain.setToken(nil) else {
            status = "Could not remove the credential from Keychain"
            return
        }
        token = ""
        connectedAs = nil
        archivePaths = []
        archiveStatus = "Sign in to connect archive storage"
        status = "Sign in to connect a photographer"
    }

    private var archiveDefaultsKey: String {
        let identity = Data(SHA256.hash(data: Data((serverURL + token).utf8))).base64EncodedString()
        return "archivePaths." + identity
    }

    private func loadArchivePaths() {
        archivePaths = defaults.stringArray(forKey: archiveDefaultsKey) ?? []
    }

    func connectArchiveStorage() {
        guard connectedAs != nil else { archiveStatus = "Sign in first"; return }
        let panel = NSOpenPanel()
        panel.title = "Connect archive storage"
        panel.prompt = "Connect folders"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        do { try panel.urls.forEach { try permissions.remember($0) } }
        catch { archiveStatus = "Could not save folder access. Select the folders again."; return }
        archivePaths = Array(Set(archivePaths + panel.urls.map { $0.standardizedFileURL.path })).sorted()
        defaults.set(archivePaths, forKey: archiveDefaultsKey)
        Task { await syncArchiveStorage() }
    }

    func disconnectArchiveStorage(_ path: String) {
        archivePaths.removeAll { $0 == path }
        defaults.set(archivePaths, forKey: archiveDefaultsKey)
        Task { await syncArchiveStorage() }
    }

    private func syncArchiveStorage() async {
        guard connectedAs != nil, let server = URL(string: serverURL), !token.isEmpty else { return }
        let credential = token
        let paths = archivePaths
        let availablePaths = paths.filter { path in
            guard let url = try? permissions.resolve(URL(fileURLWithPath: path)) else { return false }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            var directory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &directory) && directory.boolValue
        }
        do {
            var request = URLRequest(url: server.appendingPathComponent("auth/archive_storage"))
            request.httpMethod = "PUT"
            request.setValue("Bearer " + credential, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "device_name": Host.current().localizedName ?? "Cogsworth Mac", "paths": availablePaths
            ])
            let (_, response) = try await URLSession.shared.data(for: request)
            guard credential == token, paths == archivePaths else { return }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                archiveStatus = "Could not register archive storage. Will retry automatically."
                return
            }
            archiveStatus = "\(availablePaths.count) archive folders registered" +
                (availablePaths.count < paths.count ? " · Some folders are offline" : "")
        } catch {
            guard credential == token else { return }
            archiveStatus = "Archive server unavailable. Will retry automatically."
        }
    }

    func uploadMountedCards() {
        let panel = NSOpenPanel()
        panel.title = "Choose a camera card or photo folder"
        panel.prompt = "Upload"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        do { try permissions.remember(folder); enqueue(folder) }
        catch { status = "Could not save folder access. Select the folder again." }
    }

    func testConnection() async {
        guard let client else { status = "Sign in to connect a photographer"; return }
        let credential = token
        let server = serverURL
        do {
            let name = try await client.photographerName()
            guard credential == token, server == serverURL else { return }
            connectedAs = name
            await syncArchiveStorage()
            status = "Connected as \(connectedAs ?? "")"
        } catch {
            guard credential == token, server == serverURL else { return }
            connectedAs = nil
            status = error.localizedDescription
        }
    }

    func openArchiveManagement() async {
        guard let client else { status = "Configure the API connection first"; return }
        do {
            let subdomain = try await client.photographerSubdomain()
            guard let site = ServiceEndpoints.photographerSite(subdomain: subdomain) else {
                status = "The server returned an invalid photographer subdomain"
                return
            }
            NSWorkspace.shared.open(site.appendingPathComponent("admin"))
        } catch { status = error.localizedDescription }
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
        guard isConfigured, let server = URL(string: serverURL) else {
            status = "\(name) inserted, but the server URL or token is missing"
            return
        }
        status = "Uploading from \(name)"
        do {
            let folder = try permissions.resolve(volume)
            let accessed = folder.startAccessingSecurityScopedResource()
            defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
            let bookmark = try folder.bookmarkData(options: [],
                                                   includingResourceValuesForKeys: nil, relativeTo: nil)
            let result = try await uploader.upload(bookmark: bookmark, server: server, token: token) { progress in
                self.progress = progress
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

@MainActor
final class BrowserSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
    }

    func signIn(server: URL, photographer: String) async throws -> String {
        let verifier = UUID().uuidString + UUID().uuidString
        let state = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        var components = URLComponents(url: server.appendingPathComponent("auth/native"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "photographer", value: photographer), URLQueryItem(name: "challenge", value: challenge), URLQueryItem(name: "state", value: state)]
        NSApp.activate(ignoringOtherApps: true)
        defer { session = nil }
        let callback: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: components.url!, callbackURLScheme: "lumiere-uploader") { url, error in
                if let url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: error ?? CancellationError()) }
            }
            session.presentationContextProvider = self
            // Reuse the existing browser login when signing into another photographer account.
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            if !session.start() { continuation.resume(throwing: CancellationError()) }
        }
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard callback.scheme == "lumiere-uploader", callback.host == "signin", items.first(where: { $0.name == "state" })?.value == state,
              let code = items.first(where: { $0.name == "code" })?.value else {
            throw HedonismClientError.unexpectedResponse("Invalid sign-in callback")
        }
        var request = URLRequest(url: server.appendingPathComponent("auth/native/exchange"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["code": code, "verifier": verifier])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String else {
            throw HedonismClientError.unexpectedResponse("Sign-in exchange failed")
        }
        return token
    }
}
