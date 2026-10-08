import SwiftUI
import UniformTypeIdentifiers
import UploaderCore

@MainActor
final class MobileUploadModel: ObservableObject {
    @Published var server = UserDefaults.standard.string(forKey: "serverURL") ?? ""
    @Published var token = Keychain.token() ?? ""
    @Published var album = ""
    @Published var event = ""
    @Published var venue = ""
    @Published var files: [PhotoFile] = []
    @Published var progress: CardUploader.Progress?
    @Published var status = "Select a camera card or its DCIM folder"
    @Published var running = false
    private var folder: URL?
    private var hasAccess = false
    private var task: Task<Void, Never>?
    private let ledger = UploadLedger(url: UploadLedger.defaultURL)

    func select(_ url: URL) {
        releaseFolder()
        hasAccess = url.startAccessingSecurityScopedResource()
        folder = url
        files = CardScanner.photos(on: url)
        status = "\(files.count) supported files; \(files.filter { !ledger.contains($0) }.count) new"
    }

    private func releaseFolder() {
        if hasAccess, let folder { folder.stopAccessingSecurityScopedResource() }
        hasAccess = false
    }

    func cancel() { task?.cancel() }

    func upload() {
        guard !running, let folder, let url = URL(string: server),
              ["https", "http"].contains(url.scheme), url.host != nil,
              !token.isEmpty, !album.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "Enter a server URL, token and album, then select a card"
            return
        }
        Keychain.setToken(token)
        UserDefaults.standard.set(server, forKey: "serverURL")
        let uploader = CardUploader(client: HedonismClient(serverURL: url, token: token), ledger: ledger,
                                    albumPrefix: "", context: UploadContext(albumName: album, event: event, venue: venue))
        running = true
        task = Task {
            defer { running = false; task = nil }
            do {
                let result = try await uploader.upload(volume: folder) { update in
                    Task { @MainActor in self.progress = update }
                }
                status = "\(result.uploadedFiles) uploaded; \(result.failedFiles) failed. Upload again to retry."
            } catch is CancellationError {
                status = "Cancelled. Upload again to continue remaining files."
            } catch { status = error.localizedDescription }
        }
    }
}

@main
struct MobileUploaderApp: App {
    @StateObject private var model = MobileUploadModel()
    @State private var picking = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Form {
                    Section("Connection") {
                        TextField("Server URL", text: $model.server).textInputAutocapitalization(.never).keyboardType(.URL)
                        SecureField("Service account token", text: $model.token)
                    }
                    .disabled(model.running)
                    Section("Shoot details") {
                        TextField("Album", text: $model.album)
                        TextField("Event", text: $model.event)
                        TextField("Venue", text: $model.venue)
                    }
                    .disabled(model.running)
                    Section("Camera card") {
                        Button("Select card / DCIM folder") { picking = true }.disabled(model.running)
                        Text(model.status)
                        if let p = model.progress, p.totalFiles > 0 {
                            ProgressView(value: Double(p.uploadedFiles + p.failedFiles), total: Double(p.totalFiles))
                            Text(p.currentFile ?? "").font(.caption)
                        }
                        if model.running {
                            Button("Cancel", role: .destructive) { model.cancel() }
                        } else {
                            Button("Upload new files") { model.upload() }.disabled(model.files.isEmpty)
                        }
                    }
                    Section("Files on card") {
                        ForEach(model.files, id: \.url) { file in
                            HStack {
                                Text(file.filename)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Lumière Uploader")
                .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
                    switch result {
                    case .success(let url): model.select(url)
                    case .failure(let error): model.status = error.localizedDescription
                    }
                }
            }
        }
    }
}
