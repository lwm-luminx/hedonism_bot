import SwiftUI
import UniformTypeIdentifiers
import UploaderCore
import AuthenticationServices
import CryptoKit

@MainActor
final class MobileUploadModel: ObservableObject {
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

    init() {
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
        let uploader = CardUploader(client: HedonismClient(serverURL: account.server, token: token), ledger: ledger,
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
                .scrollContentBackground(.hidden)
                .background(ChipBrand.ink)
                .navigationTitle("Chip by Lumière")
                .onChange(of: model.selectedID) { _ in model.accountChanged() }
                .sheet(isPresented: $addingAccount) { NavigationStack { AddAccountView(model: model) } }
                .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
                    switch result {
                    case .success(let url): model.select(url)
                    case .failure(let error): model.status = error.localizedDescription
                    }
                }
                }
            }
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
                    Text("From your camera to your archive.").font(.body).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.top, isFirstPage ? 44 : 12)

                VStack(alignment: .leading, spacing: 16) {
                    Text(usingDeviceCode ? "Sign in with device code" : "Welcome to your archive")
                        .font(.title2.weight(.semibold)).foregroundStyle(ChipBrand.paper)
                    Text(usingDeviceCode
                         ? "Enter the one-time code supplied by your archive administrator. Codes expire after 10 minutes."
                         : "Sign in to choose the account your photos belong to.")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    if usingDeviceCode {
                        TextField("Device code", text: $deviceCode)
                            .textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced)).focused($focusedField, equals: "code")
                            .accessibilityIdentifier("deviceCodeField")
                            .padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        primaryButton("Sign in with device code", disabled: deviceCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                            Task {
                                focusedField = nil
                                if await model.addAccount(server: server, token: "", photographer: "", facebook: false, deviceCode: deviceCode) { dismiss() }
                            }
                        }
                    } else {
                        TextField("Photographer subdomain", text: $photographer)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focusedField, equals: "photographer")
                            .padding(16).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                        Text("Your archive name — for luminx.lumiere.host, enter luminx.")
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

                DisclosureGroup("Connection settings", isExpanded: $advanced) {
                    TextField("Server URL", text: $server).textInputAutocapitalization(.never)
                        .keyboardType(.URL).autocorrectionDisabled().padding(.top, 12)
                }
                .font(.footnote).foregroundStyle(.secondary).disabled(model.signingIn)
                Text("Your sign-in is saved securely on this device. You can add more accounts and choose one before uploading.")
                    .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(28).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .background(ChipBrand.ink).tint(ChipBrand.gold).preferredColorScheme(.dark)
        .navigationTitle(isFirstPage ? "" : "Add account")
        .navigationBarTitleDisplayMode(.inline)
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
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
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
