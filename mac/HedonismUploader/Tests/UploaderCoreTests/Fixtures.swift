import Foundation
@testable import UploaderCore

/// A temporary "card" with a DCIM folder.
final class TemporaryCard {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("card-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("DCIM/100MSDCF"), withIntermediateDirectories: true)
    }

    @discardableResult
    func add(_ name: String, contents: String = "bytes", modified: Date = Date(timeIntervalSince1970: 1_791_331_200)) throws -> URL {
        let url = root.appendingPathComponent("DCIM/100MSDCF/\(name)")
        try Data(contents.utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path)
        return url
    }

    deinit { try? FileManager.default.removeItem(at: root) }
}

/// Answers hedonism_bot API calls in-process and records what the uploader sent.
final class FakeServer: URLProtocol {
    static var requests: [URLRequest] = []
    static var bodies: [Data] = []
    static var failUploadsNamed: Set<String> = []
    static var status = 200
    static var uploadedHashes: Set<String> = []

    static func reset() {
        requests = []; bodies = []; failUploadsNamed = []; status = 200; uploadedHashes = []
    }

    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FakeServer.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.read) ?? Data()
        Self.requests.append(request)
        Self.bodies.append(body)

        var status = Self.status
        var json: Any = [String: Any]()
        if request.httpMethod == "PUT" {
            if Self.failUploadsNamed.contains(request.url!.lastPathComponent) { status = 400 }
        } else if request.url?.path == "/auth/uploaded_contents",
                  let payload = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            let hashes = payload["hashes"] as? [String] ?? []
            json = ["hashes": hashes.filter { Self.uploadedHashes.contains($0) }]
        } else if let payload = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let query = payload["query"] as? String {
            json = ["data": Self.answer(query, variables: payload["variables"] as? [String: Any] ?? [:])]
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: json))
        client?.urlProtocolDidFinishLoading(self)
    }

    private static func answer(_ query: String, variables: [String: Any]) -> [String: Any] {
        if query.contains("createPhotoPromise") {
            return ["createPhotoPromise": ["promise": ["id": "promise-\(variables["album"] ?? "")"]]]
        }
        if query.contains("attachPhotoPromiseFiles") {
            let files = (variables["files"] as? [[String: Any]] ?? []).map { file -> [String: Any] in
                let name = file["originalFilename"] as! String
                return ["id": "file-\(name)", "originalFilename": name, "uploadUrl": "/uploads/\(name)",
                        "uploadHeaders": ["Content-MD5": file["checksum"] as! String]]
            }
            return ["attachPhotoPromiseFiles": ["files": files]]
        }
        if query.contains("photographer") {
            return ["photographer": ["name": "Rick"]]
        }
        return ["updatePhotoPromiseFileUpdate": ["file": ["status": variables["status"] ?? ""]]]
    }

    private static func read(_ stream: InputStream) -> Data {
        stream.open(); defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
