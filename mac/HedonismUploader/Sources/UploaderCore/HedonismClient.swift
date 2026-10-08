import Foundation

public enum HedonismClientError: Error, LocalizedError, Equatable {
    case http(status: Int, body: String)
    case graphQL([String])
    case unexpectedResponse(String)

    public var errorDescription: String? {
        switch self {
        case let .http(status, body):
            return status == 401 ? "The service account token was rejected." : "Server returned HTTP \(status): \(body.prefix(200))"
        case let .graphQL(messages):
            return messages.joined(separator: "; ")
        case let .unexpectedResponse(detail):
            return "Unexpected response from the server: \(detail)"
        }
    }
}

/// A file registered with an upload promise: where and how to PUT its bytes.
public struct PendingUpload: Equatable, Sendable {
    public let id: String
    public let originalFilename: String
    public let uploadURL: URL
    public let uploadHeaders: [String: String]
}

/// Talks to hedonism_bot's GraphQL API as a service account.
public final class HedonismClient: @unchecked Sendable {
    public let serverURL: URL
    private let token: String
    private let session: URLSession

    public init(serverURL: URL, token: String, session: URLSession = .shared) {
        self.serverURL = serverURL
        self.token = token
        self.session = session
    }

    var graphQLURL: URL { serverURL.appendingPathComponent("graphql") }

    /// Checks the token and returns the photographer's subdomain.
    public func photographerName() async throws -> String {
        let data = try await graphQL("query { photographer { name } }")
        guard let name = (data["photographer"] as? [String: Any])?["name"] as? String else {
            throw HedonismClientError.unexpectedResponse("photographer")
        }
        return name
    }

    public func photographerSubdomain() async throws -> String {
        let data = try await graphQL("query { photographer { subdomain } }")
        guard let subdomain = (data["photographer"] as? [String: Any])?["subdomain"] as? String else {
            throw HedonismClientError.unexpectedResponse("photographer subdomain")
        }
        return subdomain
    }

    /// Starts an upload batch whose photos go into the named album (created if missing).
    public func createPromise(albumName: String, context: UploadContext? = nil) async throws -> String {
        var variables: [String: Any] = ["album": albumName]
        if let context { variables["context"] = ["event": context.event, "venue": context.venue] }
        let data = try await graphQL(
            "mutation($album: String, $context: JSON) { createPhotoPromise(albumName: $album, uploadContext: $context) { promise { id } } }",
            variables: variables
        )
        guard let id = ((data["createPhotoPromise"] as? [String: Any])?["promise"] as? [String: Any])?["id"] as? String else {
            throw HedonismClientError.unexpectedResponse("createPhotoPromise")
        }
        return id
    }

    /// Registers files with a promise and gets a signed upload URL for each, in the same order.
    public func attach(promiseID: String, files: [(PhotoFile, FileHasher.Digests)]) async throws -> [PendingUpload] {
        let inputs: [[String: Any]] = files.map { file, digests in
            [
                "originalFilename": file.filename,
                "contentType": file.contentType ?? "application/octet-stream",
                "fileSizeBytes": file.size,
                "imageHash": digests.sha256.base64EncodedString(),
                "checksum": digests.md5.base64EncodedString(),
            ]
        }
        let data = try await graphQL(
            """
            mutation($id: ID!, $files: [PhotoPromiseFileInput!]!) {
              attachPhotoPromiseFiles(id: $id, files: $files) { files { id originalFilename uploadUrl uploadHeaders } }
            }
            """,
            variables: ["id": promiseID, "files": inputs]
        )
        guard let nodes = (data["attachPhotoPromiseFiles"] as? [String: Any])?["files"] as? [[String: Any]] else {
            throw HedonismClientError.unexpectedResponse("attachPhotoPromiseFiles")
        }
        return try nodes.map { node in
            guard let id = node["id"] as? String,
                  let name = node["originalFilename"] as? String,
                  let urlString = node["uploadUrl"] as? String,
                  let url = URL(string: urlString, relativeTo: serverURL)?.absoluteURL else {
                throw HedonismClientError.unexpectedResponse("upload file")
            }
            let headers = (node["uploadHeaders"] as? [String: Any] ?? [:]).compactMapValues { $0 as? String }
            return PendingUpload(id: id, originalFilename: name, uploadURL: url, uploadHeaders: headers)
        }
    }

    /// PUTs the file to storage, streaming it from disk.
    public func upload(_ file: PhotoFile, to pending: PendingUpload) async throws {
        var request = URLRequest(url: pending.uploadURL)
        request.httpMethod = "PUT"
        for (name, value) in pending.uploadHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }
        let (body, response) = try await session.upload(for: request, fromFile: file.url)
        try Self.check(response, body)
    }

    /// Tells the server the upload finished (it then becomes a photo) or failed.
    public func finish(_ pending: PendingUpload, succeeded: Bool) async throws {
        _ = try await graphQL(
            """
            mutation($id: ID!, $status: PhotoPromiseFileStatus!) {
              updatePhotoPromiseFileUpdate(id: $id, status: $status) { file { status } }
            }
            """,
            variables: ["id": pending.id, "status": succeeded ? "SUCCESS" : "FAILED"]
        )
    }

    func graphQLRequest(_ query: String, variables: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: graphQLURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "variables": variables])
        return request
    }

    @discardableResult
    func graphQL(_ query: String, variables: [String: Any] = [:]) async throws -> [String: Any] {
        let (body, response) = try await session.data(for: graphQLRequest(query, variables: variables))
        try Self.check(response, body)
        guard let json = try JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw HedonismClientError.unexpectedResponse("not JSON")
        }
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            throw HedonismClientError.graphQL(errors.compactMap { $0["message"] as? String })
        }
        return json["data"] as? [String: Any] ?? [:]
    }

    static func check(_ response: URLResponse, _ body: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw HedonismClientError.http(status: http.statusCode, body: String(decoding: body, as: UTF8.self))
        }
    }
}
