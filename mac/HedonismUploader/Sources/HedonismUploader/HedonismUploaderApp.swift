import AppKit
import SwiftUI
import UploaderCore

@main
struct HedonismUploaderApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var services = DesktopServices()

    init() {
        // A menu bar app: no Dock icon, even when run outside the .app bundle.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model, services: services)
        } label: {
            Image(systemName: model.isUploading ? "arrow.up.circle.fill" : "sdcard")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model, services: services)
        }
    }
}

struct MenuContent: View {
    @ObservedObject var model: AppModel
    @ObservedObject var services: DesktopServices
    @AppStorage("synologyURL") private var synologyURL = ""
    @AppStorage("workerDirectory") private var workerDirectory = ""
    @AppStorage("uvPath") private var uvPath = "/opt/homebrew/bin/uv"
    @AppStorage("workerAtLaunch") private var workerAtLaunch = false
    @AppStorage("redisURL") private var redisURL = "redis://127.0.0.1:6379/0"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cogsworth").font(.headline)
            Text(model.status).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

            if let progress = model.progress, progress.totalFiles > 0 {
                ProgressView(value: Double(progress.uploadedFiles + progress.failedFiles), total: Double(progress.totalFiles)) {
                    Text("\(progress.uploadedFiles) of \(progress.totalFiles) files")
                } currentValueLabel: {
                    Text(progress.currentFile ?? "")
                }
            }

            if !model.isConfigured {
                Text("Add the server URL and service account token in Settings.").font(.callout)
            }

            Text(services.status).font(.caption)
            Button("Open Synology archive") { services.openSynology(synologyURL) }
            Button("Manage older albums") {
                Task {
                    await model.openArchiveManagement()
                }
            }
            Button("Start who_dis") {
                services.start(directory: workerDirectory, uvPath: uvPath, server: model.serverURL, token: model.token, redis: redisURL)
            }
            Button("Stop who_dis") { services.stop() }
            Divider()
            HStack {
                Button("Upload now") { model.uploadMountedCards() }
                    .disabled(!model.isConfigured || model.isUploading)
                Spacer()
                Button("Settings…") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                Button("Quit") { services.stop(); NSApp.terminate(nil) }
            }
        }
        .padding()
        .frame(width: 320)
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var services: DesktopServices
    @AppStorage("synologyURL") private var synologyURL = ""
    @AppStorage("workerDirectory") private var workerDirectory = ""
    @AppStorage("uvPath") private var uvPath = "/opt/homebrew/bin/uv"
    @AppStorage("workerAtLaunch") private var workerAtLaunch = false
    @AppStorage("redisURL") private var redisURL = "redis://127.0.0.1:6379/0"

    var body: some View {
        Form {
            TextField("Server", text: $model.serverURL, prompt: Text("https://api.lumiere.host"))
            SecureField("Service account token", text: $model.token, prompt: Text("hbsa_…"))
            TextField("Album name prefix", text: $model.albumPrefix)
            Text("Photos go into albums named \"\(model.albumPrefix) 2026-10-07\" by the day they were taken.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Upload automatically when a card is inserted", isOn: $model.autoUpload)
            Toggle("Eject the card when everything uploaded", isOn: $model.ejectWhenDone)
            Toggle("Open at login", isOn: Binding(get: { model.launchAtLogin }, set: { model.launchAtLogin = $0 }))
            TextField("Synology share / DSM URL", text: $synologyURL)
            TextField("who_dis directory", text: $workerDirectory)
            TextField("uv executable", text: $uvPath)
            TextField("Redis URL", text: $redisURL)
            Toggle("Start who_dis when the uploader opens", isOn: $workerAtLaunch)
            HStack {
                Button("Test connection") { Task { await model.testConnection() } }
                if let name = model.connectedAs { Text("Connected as \(name)").foregroundStyle(.secondary) }
            }
        }
        .padding()
        .frame(width: 460)
    }
}
