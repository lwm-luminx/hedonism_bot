import Foundation
import UploaderCore
import CogsworthIPC

final class UploaderService: NSObject, UploaderXPCProtocol {
    private let lock = NSLock()
    private var task: Task<Void, Never>?
    private var busy = false
    weak var connection: NSXPCConnection?

    func upload(_ data: Data, withReply reply: @escaping (Data?, String?) -> Void) {
        lock.lock()
        guard !busy else { lock.unlock(); reply(nil, IPCError.busy.localizedDescription); return }
        busy = true
        task = Task {
            let outcome: Result<Data, Error>
            do {
                let request = try JSONDecoder().decode(UploadRequest.self, from: data)
                try request.validate()
                var stale = false
                // Implicit security scope transfers the parent's grant across the XPC boundary.
                let folder = try URL(resolvingBookmarkData: request.bookmark, options: [.withoutUI],
                                     relativeTo: nil, bookmarkDataIsStale: &stale)
                // This is an ephemeral grant from the live parent, not a persisted bookmark.
                // File metadata can make it stale during transfer; successful resolution and
                // actual directory access below determine whether the grant is usable.
                let accessed = folder.startAccessingSecurityScopedResource()
                defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
                try Task.checkCancellation()
                // A denied directory must not be reported as a successfully uploaded empty card.
                _ = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                let uploader = CardUploader(client: HedonismClient(serverURL: request.server, token: request.token),
                                            ledger: UploadLedger(url: UploadLedger.defaultURL))
                let result = try await uploader.upload(volume: folder) { progress in
                    guard let data = try? JSONEncoder().encode(progress) else { return }
                    (self.connection?.remoteObjectProxy as? UploaderXPCEvents)?.uploadProgress(data)
                }
                outcome = .success(try JSONEncoder().encode(result))
            } catch {
                let failure = error as NSError
                NSLog("Upload service failure: %@ (%ld)", failure.domain, failure.code)
                outcome = .failure(error)
            }
            self.lock.withLock { self.busy = false; self.task = nil }
            switch outcome {
            case .success(let data): reply(data, nil)
            case .failure(let error):
                // Never forward response bodies or credentials from a remote server.
                reply(nil, error is CancellationError ? "Upload cancelled" : "Upload failed. Check folder access and the server connection, then retry.")
            }
        }
        lock.unlock()
    }

    func cancel() { lock.withLock { task?.cancel() } }
}

final class Delegate: NSObject, NSXPCListenerDelegate {
    private var active: NSXPCConnection?
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard active == nil else { return false }
        let service = UploaderService()
        service.connection = connection
        connection.exportedInterface = NSXPCInterface(with: UploaderXPCProtocol.self)
        connection.remoteObjectInterface = NSXPCInterface(with: UploaderXPCEvents.self)
        connection.exportedObject = service
        connection.invalidationHandler = { service.cancel(); exit(0) }
        connection.interruptionHandler = { service.cancel() }
        active = connection
        connection.resume()
        return true
    }
}
let delegate = Delegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
