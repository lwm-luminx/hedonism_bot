import AppKit
import Combine
import CogsworthIPC

/// Owns one AI/ML XPC session. Python and its dependencies live in the service bundle.
@MainActor
final class DesktopServices: ObservableObject {
    @Published private(set) var status = "Service stopped"
    @Published private(set) var isRunning = false
    @Published private(set) var isStopping = false
    @Published private(set) var isReady = false
    private var worker: MLWorkerTransport?
    private var subscriptions = Set<AnyCancellable>()
    private var model: AppModel?
    private var stoppedManually = false
    private var activeConfiguration: WorkerConfiguration?
    private var desiredConfiguration: WorkerConfiguration?
    private var shuttingDown = false
    private var terminalStatus: String?
    private var generation = UUID()
    private let makeWorker: @MainActor () -> MLWorkerTransport

    var hasBundledRuntime: Bool {
        FileManager.default.fileExists(atPath:
            Bundle.main.bundleURL.appendingPathComponent("Contents/XPCServices/CogsworthML.xpc/Contents/Frameworks/Python.framework/Python").path)
    }
    var runtimeDescription: String { hasBundledRuntime ? "Python 3.13 · isolated AI service" : "AI service runtime unavailable" }

    init(makeWorker: @escaping @MainActor () -> MLWorkerTransport = { MLXPCClient() }) {
        self.makeWorker = makeWorker
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.shuttingDown = true; self?.stop() }
            }.store(in: &subscriptions)
    }

    func connect(to model: AppModel) {
        guard self.model == nil else { return }
        self.model = model
        model.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.reconcile() }
        }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in Task { @MainActor in self?.reconcile() } }
            .store(in: &subscriptions)
        reconcile()
    }

    private func reconcile() {
        guard !shuttingDown, let model, let server = URL(string: model.serverURL) else { return }
        let configuration = WorkerConfiguration(server: server, token: model.token)
        if desiredConfiguration != configuration {
            stoppedManually = false
            desiredConfiguration = configuration
        }
        guard model.connectedAs != nil, model.isConfigured else {
            if worker != nil { terminateWorker() }
            else { status = "Sign in to start the service" }
            return
        }
        if worker != nil {
            if activeConfiguration != configuration { terminateWorker() }
            return
        }
        guard UserDefaults.standard.object(forKey: "workerAtLaunch") as? Bool ?? true,
              !stoppedManually else { return }
        start(server: model.serverURL, token: model.token)
    }

    func start(server: String, token: String) {
        guard worker == nil, !shuttingDown else { return }
        guard !token.isEmpty else { status = "Sign in to start the service"; return }
        guard let url = URL(string: server) else { status = "Enter a valid server URL"; return }
        let configuration = WorkerConfiguration(server: url, token: token)
        do { try configuration.validate() }
        catch { status = "Enter a valid server URL"; return }
        stoppedManually = false
        terminalStatus = nil
        let id = UUID()
        generation = id
        let worker = makeWorker()
        self.worker = worker
        activeConfiguration = configuration
        isRunning = true
        status = "Connecting service…"
        worker.start(configuration, status: { [weak self] value in
            guard let self, self.generation == id, !self.isStopping else { return }
            switch value {
            case "COGSWORTH_READY": self.isReady = true; self.status = "Service connected"
            case "COGSWORTH_RECONNECTING": self.isReady = false; self.status = "Reconnecting service…"
            case "COGSWORTH_AUTH_REQUIRED":
                self.stoppedManually = true
                self.terminalStatus = "Sign in again to reconnect the service"
                self.isReady = false; self.status = self.terminalStatus!
            case "COGSWORTH_ENDPOINT_UNAVAILABLE":
                self.stoppedManually = true
                self.terminalStatus = "Photo service endpoint unavailable. Update the server or check its address."
                self.isReady = false; self.status = self.terminalStatus!
            default: break
            }
        }, finished: { [weak self] error in
            guard let self, self.generation == id else { return }
            let restart = self.isStopping && !self.stoppedManually && !self.shuttingDown
            self.worker = nil; self.activeConfiguration = nil
            self.isRunning = false; self.isStopping = false; self.isReady = false
            self.status = self.terminalStatus ?? error ?? "Service stopped"
            if restart { self.reconcile() }
            else if !self.stoppedManually && !self.shuttingDown {
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    guard let self, self.generation == id else { return }
                    self.reconcile()
                }
            }
        }, reply: { [weak self] error in
            guard let self, self.generation == id, let error else { return }
            self.terminalStatus = error
            self.stoppedManually = true
            self.terminateWorker()
        })
    }

    func stop() { stoppedManually = true; terminateWorker() }
    private func terminateWorker() {
        guard let worker, !isStopping else { return }
        isStopping = true; isReady = false; status = "Stopping service…"
        worker.stop()
    }
    func openSynology(_ address: String) {
        guard let url = URL(string: address), ["smb", "https"].contains(url.scheme), url.host != nil else {
            status = "Enter an smb:// share or https:// Synology address"; return
        }
        NSWorkspace.shared.open(url)
    }
}
