import AppKit
import Foundation
import UploaderCore

/// Owns the local worker process. Configuration is passed as arguments/environment, never a shell command.
@MainActor
final class DesktopServices: ObservableObject {
    @Published var status = "who_dis stopped"
    private var worker: Process?

    init() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "workerAtLaunch") {
            start(directory: defaults.string(forKey: "workerDirectory") ?? "",
                  uvPath: defaults.string(forKey: "uvPath") ?? "/opt/homebrew/bin/uv",
                  server: defaults.string(forKey: "serverURL") ?? ServiceEndpoints.api.absoluteString, token: Keychain.token() ?? "",
                  redis: defaults.string(forKey: "redisURL") ?? "redis://127.0.0.1:6379/0")
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
    }

    func start(directory: String, uvPath: String, server: String, token: String, redis: String) {
        guard worker == nil else { return }
        guard FileManager.default.fileExists(atPath: directory + "/pyproject.toml"),
              FileManager.default.isExecutableFile(atPath: uvPath),
              let url = URL(string: server), url.host != nil else {
            status = "Set the who_dis directory, uv executable and server URL"
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: uvPath)
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.arguments = ["run", "celery", "-A", "hedonism.who_dis.app", "worker", "--loglevel", "INFO", "--pool=threads"]
        var environment = ProcessInfo.processInfo.environment
        environment["GRAPHQL_URL"] = url.appendingPathComponent("graphql").absoluteString
        environment["API_KEY"] = token
        environment["REDIS_URL"] = redis
        process.environment = environment
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.worker = nil
                self?.status = "who_dis exited (\(process.terminationStatus))"
            }
        }
        do {
            try process.run()
            worker = process
            status = "who_dis running"
        } catch { status = error.localizedDescription }
    }

    func stop() { worker?.terminate() }

    func openSynology(_ address: String) {
        guard let url = URL(string: address), ["smb", "https"].contains(url.scheme), url.host != nil else {
            status = "Enter an smb:// share or https:// Synology address"
            return
        }
        NSWorkspace.shared.open(url)
    }
}
