import Foundation

// Compile alongside Protocols.swift with -module-name CogsworthIPC and run inside
// a disposable copy of Cogsworth.app. Uses a synthetic token and a loopback fixture; no external service.
final class SmokeEvents: NSObject, UploaderXPCEvents, MLXPCEvents {
    func uploadProgress(_ data: Data) {}
    func workerStatus(_ status: String) {}
    func workerFinished(_ error: String?) {}
}

@main
struct XPCSmoke {
    static func main() {
        guard CommandLine.arguments.count == 2,
              let fixture = URL(string: CommandLine.arguments[1]), fixture.host == "127.0.0.1" else {
            fputs("Pass the loopback upload fixture URL\n", stderr); exit(8)
        }
        let servicePrefix = Bundle.main.bundleIdentifier!
        let uploader = NSXPCConnection(serviceName: servicePrefix + ".Uploader")
        uploader.remoteObjectInterface = NSXPCInterface(with: UploaderXPCProtocol.self)
        uploader.exportedInterface = NSXPCInterface(with: UploaderXPCEvents.self)
        uploader.exportedObject = SmokeEvents()
        uploader.resume()
        let ml = NSXPCConnection(serviceName: servicePrefix + ".ML")
        ml.remoteObjectInterface = NSXPCInterface(with: MLXPCProtocol.self)
        ml.exportedInterface = NSXPCInterface(with: MLXPCEvents.self)
        ml.exportedObject = SmokeEvents()
        ml.resume()
        let group = DispatchGroup()
        group.enter()
        let upload = uploader.remoteObjectProxyWithErrorHandler { error in
            fputs("Uploader XPC failed: \(error.localizedDescription)\n", stderr); exit(1)
        } as! UploaderXPCProtocol
        upload.upload(Data("invalid request".utf8)) { result, error in
            guard result == nil, error != nil else { exit(2) }
            print("Uploader XPC rejected malformed request")
            do {
                let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try Data("Cogsworth synthetic upload fixture\n".utf8).write(to: folder.appendingPathComponent("fixture.jpg"))
                let bookmark = try folder.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
                let request = UploadRequest(bookmark: bookmark, server: fixture, token: "smoke-test-only")
                let requestData = try JSONEncoder().encode(request)
                upload.upload(requestData) { data, error in
                    guard error == nil, let data,
                          let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          result["totalFiles"] as? Int == 1,
                          result["uploadedFiles"] as? Int == 1,
                          result["failedFiles"] as? Int == 0 else {
                        fputs("Uploader folder grant failed: \(error ?? "invalid result")\n", stderr); exit(6)
                    }
                    print("Uploader XPC transferred the folder grant and uploaded verified synthetic bytes")
                    upload.upload(requestData) { data, error in
                        defer { try? FileManager.default.removeItem(at: folder) }
                        guard error == nil, let data,
                              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              result["totalFiles"] as? Int == 0 else {
                            fputs("Uploader repeat/deduplication failed\n", stderr); exit(9)
                        }
                        print("Uploader XPC reused its connection and skipped server-confirmed duplicate content")
                        group.leave()
                    }
                }
            } catch { fputs("Folder smoke setup failed: \(error)\n", stderr); exit(7) }
        }
        group.enter()
        let worker = ml.remoteObjectProxyWithErrorHandler { error in
            fputs("ML XPC failed: \(error.localizedDescription)\n", stderr); exit(3)
        } as! MLXPCProtocol
        worker.checkRuntime { error in
            if let error { fputs("\(error)\n", stderr); exit(4) }
            print("ML XPC loaded isolated Python and native ML dependencies")
            worker.checkRuntime { error in
                guard error != nil else {
                    fputs("ML XPC accepted a second interpreter initialization\n", stderr); exit(10)
                }
                worker.stop {
                    print("ML XPC rejected a second initialization and acknowledged shutdown")
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            uploader.invalidate(); ml.invalidate()
            print("XPC smoke test passed"); exit(0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            fputs("XPC smoke test timed out\n", stderr); exit(5)
        }
        dispatchMain()
    }
}
