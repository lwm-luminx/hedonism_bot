import Foundation
import CogsworthIPC

private var runningService: MLService?

final class MLService: NSObject, MLXPCProtocol {
    weak var connection: NSXPCConnection?
    private var started = false
    private var workerHandle: UnsafeMutableRawPointer?

    func start(_ data: Data, withReply reply: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            guard !self.started else { reply(IPCError.busy.localizedDescription); return }
            do {
                let configuration = try JSONDecoder().decode(WorkerConfiguration.self, from: data)
                try configuration.validate()

                let json = String(decoding: data, as: UTF8.self)
                self.started = true
                reply(nil)

                let servicePtr = Unmanaged.passUnretained(self).toOpaque()
                self.workerHandle = json.withCString { cStr in
                    who_dis_start(cStr, { statusPtr, ctx in
                        guard let statusPtr, let ctx else { return }
                        let status = String(cString: statusPtr)
                        let service = Unmanaged<MLService>.fromOpaque(ctx).takeUnretainedValue()
                        DispatchQueue.main.async { service.emit(status) }
                    }, servicePtr)
                }
            } catch { reply("Invalid AI service configuration") }
        }
    }

    func checkRuntime(withReply reply: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            guard !self.started else { reply(IPCError.busy.localizedDescription); return }
            self.started = true
            let code = who_dis_check()
            reply(code == 0 ? nil : "Embedded Rust ML runtime check failed (\(code)).")
        }
    }

    func emit(_ status: String) {
        (connection?.remoteObjectProxy as? MLXPCEvents)?.workerStatus(status)
    }

    func stop(withReply reply: @escaping () -> Void) {
        if let handle = workerHandle {
            who_dis_stop(handle)
            workerHandle = nil
        }
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
