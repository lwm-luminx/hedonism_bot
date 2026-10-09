import Foundation
import CogsworthIPC

// Only one service instance/interpreter exists in this XPC process.
private var runningService: MLService?
private let pythonOutput: @convention(c) (UnsafePointer<CChar>?) -> Void = { line in
    guard let line else { return }
    let status = String(cString: line)
    DispatchQueue.main.async { runningService?.emit(status) }
}

final class MLService: NSObject, MLXPCProtocol {
    weak var connection: NSXPCConnection?
    private var started = false

    func start(_ data: Data, withReply reply: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            guard !self.started else { reply(IPCError.busy.localizedDescription); return }
            do {
                let configuration = try JSONDecoder().decode(WorkerConfiguration.self, from: data)
                try configuration.validate()
                let resources = Bundle.main.bundleURL.appendingPathComponent("Contents/Frameworks/Python.framework/Versions/3.13/Resources")
                guard FileManager.default.fileExists(atPath: resources.appendingPathComponent("lib/python3.13/os.py").path) else {
                    reply("The bundled Python runtime is missing"); return
                }
                let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("CogsworthML", isDirectory: true)
                try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
                var cable = URLComponents(url: configuration.server.appendingPathComponent("cable"), resolvingAgainstBaseURL: false)!
                cable.scheme = configuration.server.scheme == "https" ? "wss" : "ws"
                let models = support.appendingPathComponent("Models").path
                let environment = [
                    "API_KEY": configuration.token,
                    "GRAPHQL_URL": configuration.server.appendingPathComponent("graphql").absoluteString,
                    "CABLE_URL": cable.url!.absoluteString,
                    "HF_HOME": models + "/huggingface", "HF_HUB_CACHE": models + "/huggingface/hub",
                    "TORCH_HOME": models + "/torch", "KERAS_HOME": models + "/keras",
                    "DEEPFACE_HOME": models, "XDG_CACHE_HOME": support.appendingPathComponent("Cache").path,
                    "HF_HUB_DISABLE_TELEMETRY": "1",
                    "OPENSSL_CONF": resources.appendingPathComponent("openssl.cnf").path,
                    "SSL_CERT_FILE": resources.appendingPathComponent("lib/python3.13/site-packages/certifi/cacert.pem").path
                ]
                let json = String(decoding: try JSONEncoder().encode(environment), as: UTF8.self)
                self.started = true
                reply(nil)
                DispatchQueue.global(qos: .utility).async {
                    let code = resources.path.withCString { home in
                        json.withCString { CogsworthRunPython(home, $0, pythonOutput, 0) }
                    }
                    DispatchQueue.main.async {
                        (self.connection?.remoteObjectProxy as? MLXPCEvents)?.workerFinished(
                            code == 0 ? nil : "The embedded AI runtime failed (\(code)).")
                    }
                }
            } catch { reply("Invalid AI service configuration") }
        }
    }

    func checkRuntime(withReply reply: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            guard !self.started else { reply(IPCError.busy.localizedDescription); return }
            self.started = true
            let home = Bundle.main.bundleURL.appendingPathComponent("Contents/Frameworks/Python.framework/Versions/3.13/Resources").path
            DispatchQueue.global(qos: .utility).async {
                let code = home.withCString { CogsworthRunPython($0, "{}", pythonOutput, 1) }
                reply(code == 0 ? nil : "Embedded Python check failed (\(code)): \(String(cString: CogsworthPythonCheckError()))")
            }
        }
    }

    func emit(_ status: String) {
        (connection?.remoteObjectProxy as? MLXPCEvents)?.workerStatus(status)
    }
    func stop(withReply reply: @escaping () -> Void) {
        reply()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exit(0) }
    }
}

final class Delegate: NSObject, NSXPCListenerDelegate {
    private var active: NSXPCConnection?
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard runningService == nil else { return false }
        let service = MLService()
        active = connection
        runningService = service
        service.connection = connection
        connection.exportedInterface = NSXPCInterface(with: MLXPCProtocol.self)
        connection.remoteObjectInterface = NSXPCInterface(with: MLXPCEvents.self)
        connection.exportedObject = service
        connection.invalidationHandler = { exit(0) }
        connection.interruptionHandler = { exit(0) }
        connection.resume()
        return true
    }
}
let delegate = Delegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
