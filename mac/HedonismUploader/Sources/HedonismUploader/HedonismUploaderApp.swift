import AppKit
import SwiftUI
import UploaderCore

@main
struct HedonismUploaderApp: App {
    @StateObject private var model: AppModel
    @StateObject private var services: DesktopServices
    @StateObject private var settings: SettingsWindowController

    init() {
        let model = AppModel()
        let services = DesktopServices()
        services.connect(to: model)
        _model = StateObject(wrappedValue: model)
        _services = StateObject(wrappedValue: services)
        let settings = SettingsWindowController(model: model, services: services)
        _settings = StateObject(wrappedValue: settings)
        if !model.isConfigured {
            DispatchQueue.main.async { settings.open() }
        }
        // A menu bar app: no Dock icon, even when run outside the .app bundle.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model, services: services, settings: settings)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: model.isUploading ? "arrow.up.circle.fill" : "sdcard")
                Image(systemName: services.isReady && !services.isStopping ? "circle.fill" : "circle")
                    .font(.system(size: 7))
            }
            .accessibilityLabel("Cogsworth, " + services.status)
            .onAppear { services.connect(to: model) }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { settings.open() }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }

    }
}

private enum MenuBrand {
    static let gold = Color(red: 0.79, green: 0.66, blue: 0.43)
    static let cream = Color(red: 0.96, green: 0.92, blue: 0.83)
    static let muted = Color(red: 0.66, green: 0.63, blue: 0.57)
    static let background = Color(red: 0.07, green: 0.065, blue: 0.055)
    static let surface = Color(red: 0.12, green: 0.11, blue: 0.09)

    static var mark: NSImage? {
        if let url = Bundle.main.url(forResource: "LumiereMark", withExtension: "png"),
           let image = NSImage(contentsOf: url) { return image }
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        return bundle.url(forResource: "LumiereMark", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
    }
}

struct MenuContent: View {
    @ObservedObject var model: AppModel
    @ObservedObject var services: DesktopServices
    let settings: SettingsWindowController
    @AppStorage("synologyURL") private var synologyURL = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                if let mark = MenuBrand.mark {
                    Image(nsImage: mark).resizable().scaledToFit().frame(width: 60, height: 60)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("LUMIÈRE").font(.system(size: 10, weight: .semibold)).tracking(3)
                        .foregroundStyle(MenuBrand.gold)
                    Text("Cogsworth").font(.system(size: 27, weight: .medium, design: .serif))
                    Text("Your archive companion").font(.caption).foregroundStyle(MenuBrand.muted)
                }
            }

            if let photographer = model.connectedAs {
                connectedContent(photographer: photographer)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Connect your photographer account")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                    Text("Sign in through your browser or pair with a device code from your admin page.")
                        .font(.callout).foregroundStyle(MenuBrand.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { settings.open() } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(model.signingIn ? "Continue signing in" : "Sign in to Lumière")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding(12).frame(maxWidth: .infinity)
                        .background(MenuBrand.gold, in: RoundedRectangle(cornerRadius: 9))
                        .foregroundStyle(MenuBrand.background)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("menuSignIn")
                }
            }
        }
        .padding(22)
        .frame(width: 370)
        .foregroundStyle(MenuBrand.cream)
        .background(LinearGradient(colors: [MenuBrand.surface, MenuBrand.background], startPoint: .topLeading, endPoint: .bottomTrailing))
        .tint(MenuBrand.gold)
        .preferredColorScheme(.dark)
    }

    private func connectedContent(photographer: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CONNECTED PHOTOGRAPHER").font(.system(size: 9, weight: .semibold)).tracking(1.5)
                    .foregroundStyle(MenuBrand.muted)
                Label(photographer, systemImage: "person.crop.circle.fill").font(.callout.weight(.medium))
                HStack(spacing: 6) {
                    Image(systemName: services.isReady && !services.isStopping ? "circle.fill" : "circle")
                        .font(.system(size: 7))
                        .foregroundStyle(services.isReady && !services.isStopping ? Color.green : MenuBrand.gold)
                    Text(services.status).font(.caption).foregroundStyle(MenuBrand.muted)
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(MenuBrand.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MenuBrand.gold.opacity(0.18)))

            Text(model.status).font(.callout).foregroundStyle(MenuBrand.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let progress = model.progress, progress.totalFiles > 0 {
                ProgressView(value: Double(progress.uploadedFiles + progress.failedFiles), total: Double(progress.totalFiles)) {
                    Text("\(progress.uploadedFiles) of \(progress.totalFiles) files").font(.caption)
                }
                if let filename = progress.currentFile {
                    Text(filename).font(.caption).foregroundStyle(MenuBrand.muted).lineLimit(1).truncationMode(.middle)
                }
            }

            VStack(spacing: 2) {
                menuAction("Connect archive storage…", icon: "externaldrive.badge.plus") { model.connectArchiveStorage() }
                Text(model.archiveStatus).font(.caption).foregroundStyle(MenuBrand.muted)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
                menuAction("Open Synology archive", icon: "externaldrive", enabled: !synologyURL.isEmpty) { services.openSynology(synologyURL) }
                menuAction("Manage albums", icon: "photo.on.rectangle") { Task { await model.openArchiveManagement() } }
                menuAction(services.isRunning ? "Stop service" : "Start service", icon: services.isRunning ? "stop.circle" : "play.circle", enabled: !services.isStopping) {
                    if services.isRunning { services.stop() }
                    else { services.start(server: model.serverURL, token: model.token) }
                }
            }

            Divider().overlay(MenuBrand.gold.opacity(0.15))
            HStack {
                Button("Upload now") { model.uploadMountedCards() }
                    .buttonStyle(.borderedProminent).disabled(!model.isConfigured || model.isUploading)
                Spacer()
                Button { settings.open() } label: { Image(systemName: "gearshape") }
                    .help("Settings").accessibilityLabel("Settings")
                Button { services.stop(); NSApp.terminate(nil) } label: { Image(systemName: "power") }
                    .help("Quit Cogsworth").accessibilityLabel("Quit Cogsworth")
            }
        }
    }

    private func menuAction(_ title: String, icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 18).foregroundStyle(MenuBrand.gold)
                Text(title).font(.callout)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(MenuBrand.muted)
            }
            .padding(.horizontal, 10).padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.45)
    }
}

struct SettingsView: View {
    @State private var photographer = ""
    @State private var deviceCode = ""
    @State private var signInMethod: String?
    @State private var showSignInSettings = false
    @ObservedObject var model: AppModel
    @ObservedObject var services: DesktopServices
    @AppStorage("synologyURL") private var synologyURL = ""
    @AppStorage("workerAtLaunch") private var workerAtLaunch = true

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            ScrollView {
                if model.connectedAs == nil {
                    signInView
                } else {
                    preferences
                }
            }
            HStack {
                Text("COGSWORTH BY LUMIÈRE").tracking(1.5)
                Spacer()
                Text("Your archive companion")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MenuBrand.muted)
            .padding(.horizontal, 28).padding(.vertical, 16)
            .background(MenuBrand.surface.opacity(0.5))
        }
        .foregroundStyle(MenuBrand.cream)
        .background(MenuBrand.background)
        .tint(MenuBrand.gold)
        .preferredColorScheme(.dark)
        .frame(minWidth: 520, idealWidth: 580, minHeight: 580, idealHeight: 760)
    }

    private var brandHeader: some View {
        HStack(spacing: 18) {
            Group {
                if let mark = MenuBrand.mark {
                    Image(nsImage: mark).resizable().scaledToFit()
                } else {
                    Image(systemName: "clock").resizable().scaledToFit().padding(12)
                        .foregroundStyle(MenuBrand.gold)
                }
            }
            .frame(width: 64, height: 64).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("LUMIÈRE").font(.system(size: 10, weight: .semibold)).tracking(3)
                    .foregroundStyle(MenuBrand.gold)
                Text("Cogsworth").font(.system(size: 32, weight: .medium, design: .serif))
                    .accessibilityAddTraits(.isHeader)
                Text("A little order for every photograph.").font(.callout)
                    .foregroundStyle(MenuBrand.muted)
            }
            Spacer(minLength: 8)
            Text("SETTINGS").font(.system(size: 10, weight: .semibold)).tracking(1.5)
                .foregroundStyle(MenuBrand.gold)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [MenuBrand.surface, MenuBrand.background],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(alignment: .bottom) { Rectangle().fill(MenuBrand.gold.opacity(0.2)).frame(height: 1) }
    }

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard("Account", icon: "person.crop.circle") {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill").font(.title).foregroundStyle(MenuBrand.gold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connected photographer").font(.caption).foregroundStyle(MenuBrand.muted)
                        Text(model.connectedAs ?? "").font(.headline).textSelection(.enabled)
                    }
                    Spacer()
                    Button("Sign out") { model.signOut() }.disabled(model.isUploading || model.signingIn)
                }
                Divider().overlay(MenuBrand.gold.opacity(0.12))
                settingsField("Server endpoint", text: $model.serverURL)
                HStack {
                    Text(model.status).font(.caption).foregroundStyle(MenuBrand.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("Test connection") { Task { await model.testConnection() } }
                }
            }
            settingsCard("Card uploads", icon: "sdcard") {
                Text("From camera card to your Lumière library.").font(.callout).foregroundStyle(MenuBrand.muted)
                Toggle("Upload when a card is inserted", isOn: $model.autoUpload)
                Toggle("Eject after a successful upload", isOn: $model.ejectWhenDone)
                Divider().overlay(MenuBrand.gold.opacity(0.12))
                Toggle("Open Cogsworth at login", isOn: Binding(get: { model.launchAtLogin }, set: { model.launchAtLogin = $0 }))
            }
            settingsCard("Archive storage", icon: "externaldrive") {
                Text("Connect folders on this Mac or a mounted NAS to register them with your photographer account.")
                    .font(.callout).foregroundStyle(MenuBrand.muted).fixedSize(horizontal: false, vertical: true)
                Button { model.connectArchiveStorage() } label: {
                    Label("Connect archive storage…", systemImage: "plus")
                }
                ForEach(model.archivePaths, id: \.self) { path in
                    HStack(spacing: 12) {
                        Image(systemName: "folder").foregroundStyle(MenuBrand.gold)
                        Text(path).font(.caption).lineLimit(2).truncationMode(.middle).help(path)
                        Spacer()
                        Button("Disconnect") { model.disconnectArchiveStorage(path) }
                            .accessibilityLabel("Disconnect " + path)
                    }
                }
                Text(model.archiveStatus).font(.caption).foregroundStyle(MenuBrand.muted)
                Divider().overlay(MenuBrand.gold.opacity(0.12))
                settingsField("Synology share or DSM address", text: $synologyURL, prompt: "smb://host/share or https://host:port")
            }
            settingsCard("Photo service", icon: "sparkles") {
                HStack {
                    Label(services.status, systemImage: services.isReady && !services.isStopping ? "circle.fill" : "circle")
                        .font(.callout)
                    Spacer()
                    Text(services.runtimeDescription).font(.caption).foregroundStyle(MenuBrand.gold)
                }
                Toggle("Run automatically when connected", isOn: $workerAtLaunch)
                Text("Authenticated connection to your archive").font(.caption).foregroundStyle(MenuBrand.muted)

            }
        }
        .padding(28)
        .textFieldStyle(.roundedBorder).toggleStyle(.switch)
    }

    private func settingsField(_ title: String, text: Binding<String>, prompt: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(MenuBrand.muted)
            TextField(title, text: text, prompt: prompt.map { Text($0) })
                .labelsHidden().accessibilityLabel(title)
        }
    }

    private func settingsCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title.uppercased(), systemImage: icon).font(.caption.weight(.semibold)).tracking(1)
                .foregroundStyle(MenuBrand.gold)
            content()
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(MenuBrand.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MenuBrand.gold.opacity(0.14)))
    }

    private var signInView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Make yourself at home.").font(.system(size: 25, weight: .medium, design: .serif))
                    .accessibilityAddTraits(.isHeader)
                Text("Connect your photographer account to set up card uploads, archive storage and your photo service.")
                    .font(.callout).foregroundStyle(MenuBrand.muted).fixedSize(horizontal: false, vertical: true)
            }

            if signInMethod == nil {
                HStack(spacing: 12) {
                    signInOption("Facebook", icon: "person.crop.circle", prominent: true) { signInMethod = "facebook" }
                    signInOption("Device code", icon: "key", prominent: false) { signInMethod = "code" }
                }
            } else {
                Button { signInMethod = nil } label: { Label("Back", systemImage: "chevron.left") }
                    .buttonStyle(.plain).foregroundStyle(MenuBrand.muted).disabled(model.signingIn)
                if signInMethod == "facebook" {
                    TextField("Photographer subdomain", text: $photographer)
                        .textFieldStyle(.roundedBorder)
                    Text("Enter the subdomain for the photographer you administer.").font(.caption).foregroundStyle(MenuBrand.muted)
                    signInChoice("Continue with Facebook", icon: "arrow.up.right", prominent: true) {
                        Task { await model.signIn(photographer: photographer) }
                    }
                    .disabled(photographer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    TextField("Device code", text: $deviceCode).textFieldStyle(.roundedBorder)
                    Text("Generate a one-use code in Admin → Devices, then paste it here.").font(.caption).foregroundStyle(MenuBrand.muted)
                    signInChoice("Connect with device code", icon: "link", prominent: true) {
                        Task { await model.signIn(photographer: "", deviceCode: deviceCode) }
                    }
                    .disabled(deviceCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if model.signingIn { ProgressView("Signing in…").tint(MenuBrand.gold) }
                Text(model.status).font(.caption).foregroundStyle(MenuBrand.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { showSignInSettings.toggle() } label: {
                Label("Sign-in settings", systemImage: "gearshape").font(.caption)
            }
            .buttonStyle(.plain).foregroundStyle(MenuBrand.muted).disabled(model.signingIn)
            if showSignInSettings {
                TextField("Server endpoint", text: $model.serverURL).textFieldStyle(.roundedBorder)
                Text("Default: https://api.lumiere.host").font(.caption).foregroundStyle(MenuBrand.muted)
            }
        }
        .padding(30).frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(MenuBrand.cream)
        .background(LinearGradient(colors: [MenuBrand.surface, MenuBrand.background], startPoint: .topLeading, endPoint: .bottomTrailing))
        .preferredColorScheme(.dark)
    }

    private func signInOption(_ title: String, icon: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 24))
                VStack(spacing: 3) {
                    Text("Sign in with").font(.caption)
                    Text(title).font(.callout.weight(.semibold))
                }
            }
            .padding(16).frame(maxWidth: .infinity, minHeight: 112)
            .foregroundStyle(prominent ? MenuBrand.background : MenuBrand.cream)
            .background(prominent ? MenuBrand.gold : MenuBrand.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MenuBrand.gold.opacity(prominent ? 0 : 0.3)))
        }
        .buttonStyle(.plain).disabled(model.signingIn)
        .accessibilityLabel("Sign in with " + title)
    }

    private func signInChoice(_ title: String, icon: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                Text(title).font(.callout.weight(.medium))
                Spacer()
                Image(systemName: "arrow.right")
            }
            .padding(14).frame(maxWidth: .infinity)
            .foregroundStyle(prominent ? MenuBrand.background : MenuBrand.cream)
            .background(prominent ? MenuBrand.gold : MenuBrand.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MenuBrand.gold.opacity(prominent ? 0 : 0.3)))
        }
        .buttonStyle(.plain).disabled(model.signingIn)
    }
}

/// Owns a normal window so Settings also works from an accessory menu-bar app on macOS 13.
@MainActor
final class SettingsWindowController: NSWindowController, ObservableObject {
    init(model: AppModel, services: DesktopServices) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 760),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Cogsworth Settings"
        window.contentMinSize = NSSize(width: 520, height: 580)
        window.backgroundColor = NSColor(MenuBrand.background)
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(model: model, services: services))
        super.init(window: window)
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func open() {
        NSApp.activate(ignoringOtherApps: true)
        window?.deminiaturize(nil)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
