import Foundation
import CogsworthIPC
import UploaderCore

@MainActor
final class UploaderClient: NSObject, UploaderXPCEvents {
    private var connection: NSXPCConnection?
    private var requestID = UUID()
    private var completion: CheckedContinuation<CardUploader.Progress, Error>?
    private var progressHandler: ((CardUploader.Progress) -> Void)?

    func upload(bookmark: Data, server: URL, token: String,
                progress: @escaping (CardUploader.Progress) -> Void) async throws -> CardUploader.Progress {
        guard completion == nil else { throw IPCError.busy }
        let request = UploadRequest(bookmark: bookmark, server: server, token: token)
        try request.validate()
        let data = try JSONEncoder().encode(request)
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                let id = UUID()
                requestID = id
                completion = continuation
                progressHandler = progress
                if connection == nil {
                    let connection = NSXPCConnection(serviceName: CogsworthService.uploader)
                    connection.remoteObjectInterface = NSXPCInterface(with: UploaderXPCProtocol.self)
                    connection.exportedInterface = NSXPCInterface(with: UploaderXPCEvents.self)
                    connection.exportedObject = self
                    connection.invalidationHandler = { [weak self, weak connection] in
                        Task { @MainActor in
                            guard let self, self.connection === connection else { return }
                            self.connection = nil
                            self.finish(.failure(IPCError.disconnected))
                        }
                    }
                    connection.interruptionHandler = { [weak self, weak connection] in
                        Task { @MainActor in
                            guard let self, self.connection === connection else { return }
                            self.cancel()
                        }
                    }
                    self.connection = connection
                    connection.resume()
                }
                let proxy = connection?.remoteObjectProxyWithErrorHandler { [weak self] _ in
                    Task { @MainActor in
                            guard self?.requestID == id else { return }; self?.cancel()
                        }
                } as? UploaderXPCProtocol
                guard let proxy else { finish(.failure(IPCError.disconnected)); return }
                proxy.upload(data) { [weak self] result, error in
                    Task { @MainActor in
                        guard let self, self.requestID == id else { return }
                        if let result {
                            self.finish(Result { try JSONDecoder().decode(CardUploader.Progress.self, from: result) })
                        } else { self.finish(.failure(IPCError.remote(error ?? "Upload failed"))) }
                    }
                }
            }
        } onCancel: {
            Task { @MainActor in self.cancel() }
        }
    }

    nonisolated func uploadProgress(_ data: Data) {
        guard let progress = try? JSONDecoder().decode(CardUploader.Progress.self, from: data) else { return }
        Task { @MainActor in self.progressHandler?(progress) }
    }

    func cancel() {
        (connection?.remoteObjectProxy as? UploaderXPCProtocol)?.cancel()
        connection?.invalidate()
        connection = nil
        finish(.failure(IPCError.disconnected))
    }

    private func finish(_ result: Result<CardUploader.Progress, Error>) {
        let continuation = completion
        completion = nil
        progressHandler = nil
        continuation?.resume(with: result)
    }
}

@MainActor
protocol MLWorkerTransport: AnyObject {
    func start(_ configuration: WorkerConfiguration, status: @escaping (String) -> Void,
               finished: @escaping (String?) -> Void, reply: @escaping (String?) -> Void)
    func stop()
}

@MainActor
final class MLXPCClient: NSObject, MLWorkerTransport, MLXPCEvents {
    private var connection: NSXPCConnection?
    private var statusHandler: ((String) -> Void)?
    private var finishHandler: ((String?) -> Void)?
    private var terminalError: String?
    private var stopped = false

    func start(_ configuration: WorkerConfiguration, status: @escaping (String) -> Void,
               finished: @escaping (String?) -> Void, reply: @escaping (String?) -> Void) {
        guard connection == nil else { reply(IPCError.busy.localizedDescription); return }
        do {
            try configuration.validate()
            let data = try JSONEncoder().encode(configuration)
            statusHandler = status
            finishHandler = finished
            let connection = NSXPCConnection(serviceName: CogsworthService.machineLearning)
            connection.remoteObjectInterface = NSXPCInterface(with: MLXPCProtocol.self)
            connection.exportedInterface = NSXPCInterface(with: MLXPCEvents.self)
            connection.exportedObject = self
            connection.invalidationHandler = { [weak self] in
                Task { @MainActor in self?.didDisconnect() }
            }
            connection.interruptionHandler = { [weak self] in
                Task { @MainActor in self?.connection?.invalidate() }
            }
            self.connection = connection
            connection.resume()
            let proxy = connection.remoteObjectProxyWithErrorHandler { [weak self] _ in
                Task { @MainActor in self?.connection?.invalidate() }
            } as? MLXPCProtocol
            guard let proxy else { connection.invalidate(); return }
            proxy.start(data) { error in Task { @MainActor in reply(error) } }
        } catch { reply(error.localizedDescription) }
    }

    nonisolated func workerStatus(_ status: String) {
        Task { @MainActor in self.statusHandler?(status) }
    }
    nonisolated func workerFinished(_ error: String?) {
        Task { @MainActor in
            self.terminalError = error
            self.stopped = error == nil
            self.connection?.invalidate()
        }
    }
    func stop() {
        stopped = true
        // Invalidation makes the service terminate even if Python is blocked in native inference.
        connection?.invalidate()
    }
    private func didDisconnect() {
        connection = nil
        let callback = finishHandler
        finishHandler = nil
        statusHandler = nil
        callback?(terminalError ?? (stopped ? nil : IPCError.disconnected.localizedDescription))
    }
}
