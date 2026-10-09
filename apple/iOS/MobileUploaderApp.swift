import SwiftUI
import UniformTypeIdentifiers
import UploaderCore
import AuthenticationServices
import CryptoKit
#if os(iOS)
import CoreLocation
#else
import AppKit
#endif

@MainActor
final class MobileUploadModel: NSObject, ObservableObject {
    #if os(iOS)
    private let locationManager = CLLocationManager()
    @Published var recordings: [LocationRecording] = []
    @Published var recordingLocation = false
    @Published var locationStatus = "Record during your shoot to match photos to venues later."
    private var recordingURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Chip-location-recordings.json")
    }

    private func saveRecordings() {
        do {
            try FileManager.default.createDirectory(at: recordingURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(recordings).write(to: recordingURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            stopRecording()
            locationStatus = "Could not save location history: \(error.localizedDescription)"
        }
    }

    func startRecording() {
        guard !recordingLocation else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            requestedRecording = true
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            recordings.append(LocationRecording())
            recordingLocation = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.showsBackgroundLocationIndicator = true
            locationManager.startUpdatingLocation()
            locationStatus = "Recording location. Stop when your shoot ends."
            saveRecordings()
        default: locationStatus = "Allow location access in Settings to record your shoot."
        }
    }

    func stopRecording() {
        locationManager.stopUpdatingLocation()
        guard recordingLocation else { return }
        recordingLocation = false
        recordings[recordings.count - 1].stoppedAt = Date()
        locationStatus = "Recording stopped. History is saved for later uploads."
        saveRecordings()
    }

    func deleteRecordings() {
        stopRecording()
        recordings.removeAll()
        saveRecordings()
        locationStatus = "Location history deleted from this phone."
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            if requestedRecording { requestedRecording = false; startRecording() }
        } else if manager.authorizationStatus != .notDetermined {
            requestedRecording = false
            stopRecording()
            locationStatus = "Location permission is unavailable. Enable it in Settings to record."
        }
    }
    private var requestedRecording = false

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard recordingLocation, !recordings.isEmpty else { return }
        let start = recordings[recordings.count - 1].startedAt
        for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 100 && location.timestamp >= start {
            recordings[recordings.count - 1].samples.append(LocationSample(timestamp: location.timestamp, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy))
        }
        saveRecordings()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatus = "Location update failed: \(error.localizedDescription)"
    }
    #endif
    @Published var accounts: [UploadAccount] = []
    @Published var selectedID: UUID? { didSet { defaults.set(selectedID?.uuidString, forKey: "selectedAccount") } }
    @Published var signingIn = false
    @Published var accountError: String?
    private let authentication = FacebookSignIn()
    private let defaults: UserDefaults = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return UserDefaults(suiteName: "LumiereUITests")! }
        #endif
        return .standard
    }()

    override init() {
        super.init()
        #if os(iOS)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 20
        locationManager.pausesLocationUpdatesAutomatically = false
        if !ProcessInfo.processInfo.arguments.contains("--ui-testing"),
           let data = try? Data(contentsOf: recordingURL),
           let saved = try? JSONDecoder().decode([LocationRecording].self, from: data) {
            recordings = saved
            // A terminated app cannot guarantee coverage after its last saved sample.
            for index in recordings.indices where recordings[index].stoppedAt == nil {
                recordings[index].stoppedAt = recordings[index].samples.last?.timestamp ?? recordings[index].startedAt
            }
        }
        #endif
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-test-accounts") { defaults.removePersistentDomain(forName: "LumiereUITests") }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-accounts"), defaults.data(forKey: "uploadAccounts") == nil {
            let fixtures = [UploadAccount(name: "Test Alpha", subdomain: "alpha", server: ServiceEndpoints.api),
                            UploadAccount(name: "Test Beta", subdomain: "beta", server: ServiceEndpoints.api)]
            defaults.set(try? JSONEncoder().encode(fixtures), forKey: "uploadAccounts")
        }
        #endif
        if let data = defaults.data(forKey: "uploadAccounts"),
           let saved = try? JSONDecoder().decode([UploadAccount].self, from: data) { accounts = saved }
        selectedID = defaults.string(forKey: "selectedAccount").flatMap(UUID.init(uuidString:))
        if !accounts.contains(where: { $0.id == selectedID }) { selectedID = accounts.first?.id }
        if accounts.isEmpty, !ProcessInfo.processInfo.arguments.contains("--ui-testing"), let legacy = Keychain.token(), !legacy.isEmpty {
            Task {
                if await addAccount(server: UserDefaults.standard.string(forKey: "serverURL") ?? ServiceEndpoints.api.absoluteString,
                                    token: legacy, photographer: "", facebook: false) {
                    _ = Keychain.setToken(nil)
                    if let account = selectedAccount, FileManager.default.fileExists(atPath: UploadLedger.defaultURL.path) {
                        try? FileManager.default.createDirectory(at: account.ledgerURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                        try? FileManager.default.copyItem(at: UploadLedger.defaultURL, to: account.ledgerURL)
                    }
                }
            }
        }
    }

    var selectedAccount: UploadAccount? { accounts.first { $0.id == selectedID } }
    var canUpload: Bool { !files.isEmpty && selectedAccount != nil && !album.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func saveAccounts() {
        defaults.set(try? JSONEncoder().encode(accounts), forKey: "uploadAccounts")
    }

    func addAccount(server: String, token: String, photographer: String, facebook: Bool, deviceCode: String? = nil) async -> Bool {
        accountError = nil
        guard let url = URL(string: server), url.scheme == "https", url.host != nil else {
            accountError = "Enter a valid HTTPS server URL"; return false
        }
        signingIn = true
        defer { signingIn = false }
        do {
            let credential: String
            if let deviceCode {
                credential = try await DeviceCodeSignIn.signIn(server: url, code: deviceCode)
            } else if facebook {
                credential = try await authentication.signIn(server: url, photographer: photographer)
            } else { credential = token }
            let client = HedonismClient(serverURL: url, token: credential)
            let subdomain = try await client.photographerSubdomain()
            let name = try await client.photographerName()
            let existing = accounts.first { $0.server == url && $0.subdomain == subdomain }
            let account = UploadAccount(id: existing?.id ?? UUID(), name: name, subdomain: subdomain, server: url)
            guard Keychain.setToken(credential, accountID: account.id.uuidString) else {
                throw HedonismClientError.unexpectedResponse("Could not save credentials in Keychain")
            }
            accounts.removeAll { $0.id == account.id }
            accounts.append(account)
            selectedID = account.id
            saveAccounts()
            return true
        } catch { accountError = error.localizedDescription; return false }
    }

    func signOut() {
        guard let account = selectedAccount, !running else { return }
        guard Keychain.setToken(nil, accountID: account.id.uuidString) else {
            status = "Could not remove the saved credential. Try signing out again."; return
        }
        accounts.removeAll { $0.id == account.id }
        selectedID = accounts.first?.id
        saveAccounts()
        progress = nil
        status = "Signed out of \(account.name) on this device"
    }

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
    private var ledger: UploadLedger {
        UploadLedger(url: selectedAccount?.ledgerURL ?? UploadLedger.defaultURL)
    }

    func accountChanged() {
        progress = nil
        if !files.isEmpty { status = "\(files.count) supported files; \(files.filter { !ledger.contains($0) }.count) new for this account" }
    }

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
        guard !running, let folder, let account = selectedAccount,
              let token = Keychain.token(accountID: account.id.uuidString), !token.isEmpty, !album.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "Choose a signed-in account, enter an album, then select a card"
            return
        }
        #if os(iOS)
        let locationRecordings = recordings
        #else
        let locationRecordings: [LocationRecording] = []
        #endif
        let uploader = CardUploader(client: HedonismClient(serverURL: account.server, token: token), ledger: ledger,
                                    context: UploadContext(albumName: album, event: event, venue: venue, locationRecordings: locationRecordings))
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

#if os(iOS)
extension MobileUploadModel: @preconcurrency CLLocationManagerDelegate {}
#endif

@main
struct MobileUploaderApp: App {
    @StateObject private var model = MobileUploadModel()
    @State private var picking = false
    @State private var addingAccount = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if model.accounts.isEmpty {
                    AddAccountView(model: model, isFirstPage: true)
                } else {
                Form {
                    Section("Upload account") {
                        if model.accounts.isEmpty {
                            Text("Sign in to choose where your photos go.").foregroundStyle(.secondary)
                        } else {
                            Picker("Account", selection: $model.selectedID) {
                                ForEach(model.accounts) { account in
                                    Text("\(account.name) · \(account.subdomain)").tag(Optional(account.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("uploadAccountPicker")
                            if let account = model.selectedAccount {
                                Text(account.server.host ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                            Button("Sign out of selected account", role: .destructive) { model.signOut() }
                        }
                        Button("Add account") { addingAccount = true }
                    }
                    .disabled(model.running)
                    Section("Shoot details") {
                        TextField("Album", text: $model.album)
                        TextField("Event", text: $model.event)
                        TextField("Venue", text: $model.venue)
                    }
                    .disabled(model.running)
                    #if os(iOS)
                    Section("Shoot location") {
                        DisclosureGroup(model.recordingLocation ? "Recording your shoot location" : "Record shoot location") {
                        Text(model.locationStatus)
                        Button(model.recordingLocation ? "Stop recording location" : "Start recording location") {
                            if model.recordingLocation { model.stopRecording() } else { model.startRecording() }
                        }
                        Text("\(model.recordings.reduce(0) { $0 + $1.samples.count }) saved samples. History accompanies uploads from this phone. Camera time must match phone time.").font(.caption)
                        Button("Delete saved location history", role: .destructive) { model.deleteRecordings() }
                            .disabled(model.running || model.recordings.isEmpty)
                        }
                    }
                    #endif
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
                            Button("Upload new files") { model.upload() }.disabled(!model.canUpload)
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
                #if os(macOS)
                .formStyle(.grouped)
                #endif
                .scrollContentBackground(.hidden)
                .background(ChipBrand.ink)
                .navigationTitle("Chip by Lumière")
                #if os(macOS)
                .onChange(of: model.selectedID) { model.accountChanged() }
                #else
                .onChange(of: model.selectedID) { _ in model.accountChanged() }
                #endif
                .sheet(isPresented: $addingAccount) { NavigationStack { AddAccountView(model: model) } }
                .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
                    switch result {
                    case .success(let url): model.select(url)
                    case .failure(let error): model.status = error.localizedDescription
                    }
                }
                }
            }
            #if os(macOS)
            .frame(minWidth: 560, minHeight: 640)
            #endif
            .tint(ChipBrand.gold)
            .preferredColorScheme(.dark)
        }
    }
}

enum ChipBrand {
    static let ink = Color(red: 15 / 255, green: 15 / 255, blue: 15 / 255)
    static let gold = Color(red: 201 / 255, green: 169 / 255, blue: 110 / 255)
    static let paper = Color(red: 251 / 255, green: 238 / 255, blue: 198 / 255)
}

struct AddAccountView: View {
    @ObservedObject var model: MobileUploadModel
    var isFirstPage = false
    @Environment(\.dismiss) private var dismiss
    @State private var server = ServiceEndpoints.api.absoluteString
    @State private var photographer = ""
    @State private var deviceCode = ""
    @State private var usingDeviceCode = false
    @State private var advanced = false
    @FocusState private var focusedField: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(spacing: 12) {
                    Image("LumiereBrand").resizable().scaledToFit().frame(width: 100, height: 100)
                        .accessibilityHidden(true)
                    Text("Chip").font(.system(size: 48, weight: .medium, design: .serif))
                    Text("BY LUMIÈRE").font(.caption.weight(.semibold)).tracking(4).foregroundStyle(ChipBrand.gold)
                }
                .frame(maxWidth: .infinity).padding(.top, isFirstPage ? 44 : 12)

                VStack(alignment: .leading, spacing: 16) {
                    if usingDeviceCode {
                        TextField("Device code", text: $deviceCode)
                            #if os(iOS)
                            .textInputAutocapitalization(.characters)
                            #endif
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced)).focused($focusedField, equals: "code")
                            .accessibilityIdentifier("deviceCodeField")
                            .padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        Text("One-time code · expires in 10 minutes").font(.caption).foregroundStyle(.secondary)
                        primaryButton("Sign in with device code", disabled: deviceCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                            Task {
                                focusedField = nil
                                if await model.addAccount(server: server, token: "", photographer: "", facebook: false, deviceCode: deviceCode) { dismiss() }
                            }
                        }
                    } else {
                        TextField("Archive name", text: $photographer)
                            .accessibilityLabel("Photographer subdomain")
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: "photographer")
                            .padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        Text("e.g. luminx")
                            .font(.caption).foregroundStyle(.secondary)
                        primaryButton("Continue with Facebook", disabled: photographer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                            Task {
                                focusedField = nil
                                if await model.addAccount(server: server, token: "", photographer: photographer.trimmingCharacters(in: .whitespacesAndNewlines), facebook: true) { dismiss() }
                            }
                        }
                    }
                    if model.signingIn { ProgressView("Signing in…").accessibilityIdentifier("signInProgress") }
                    if let error = model.accountError {
                        Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("signInError")
                    }
                }
                Button(usingDeviceCode ? "Sign in with Facebook" : "or sign in with device code") {
                    usingDeviceCode.toggle()
                    model.accountError = nil
                    focusedField = nil
                }
                .frame(maxWidth: .infinity).disabled(model.signingIn)
                .accessibilityIdentifier("switchSignInMethod")

                DisclosureGroup("Server", isExpanded: $advanced) {
                    TextField("Server URL", text: $server)
                        #if os(iOS)
                        .textInputAutocapitalization(.never).keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled().padding(.top, 12)
                }
                .font(.footnote).foregroundStyle(.secondary).disabled(model.signingIn)
            }
            .padding(28).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .background(ChipBrand.ink).tint(ChipBrand.gold).preferredColorScheme(.dark)
        .navigationTitle(isFirstPage ? "" : "Add account")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !isFirstPage {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(model.signingIn) }
            }
        }
        .onAppear { model.accountError = nil }
    }

    private func primaryButton(_ title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent).tint(ChipBrand.gold).foregroundStyle(ChipBrand.ink)
        .disabled(disabled || model.signingIn)
    }
}

@MainActor
final class FacebookSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(macOS)
        NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
        #endif
    }

    func signIn(server: URL, photographer: String) async throws -> String {
        let verifier = UUID().uuidString + UUID().uuidString
        let state = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        var components = URLComponents(url: server.appendingPathComponent("auth/native"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "photographer", value: photographer), URLQueryItem(name: "challenge", value: challenge), URLQueryItem(name: "state", value: state)]
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
        defer { session = nil }
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard callback.host == "signin", items.first(where: { $0.name == "state" })?.value == state,
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
