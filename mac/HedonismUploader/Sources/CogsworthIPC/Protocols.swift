import Foundation

public enum CogsworthService {
    public static let uploader = "host.lumiere.Cogsworth.Uploader"
    public static let machineLearning = "host.lumiere.Cogsworth.ML"
}

@objc public protocol UploaderXPCProtocol {
    func upload(_ request: Data, withReply reply: @escaping (Data?, String?) -> Void)
    func cancel()
}

@objc public protocol UploaderXPCEvents {
    func uploadProgress(_ data: Data)
}

@objc public protocol MLXPCProtocol {
    func checkRuntime(withReply reply: @escaping (String?) -> Void)
    func start(_ configuration: Data, withReply reply: @escaping (String?) -> Void)
    func stop(withReply reply: @escaping () -> Void)
}

@objc public protocol MLXPCEvents {
    func workerStatus(_ status: String)
    func workerFinished(_ error: String?)
}

public struct UploadRequest: Codable, Sendable {
    public let bookmark: Data
    public let server: URL
    public let token: String
    public init(bookmark: Data, server: URL, token: String) {
        self.bookmark = bookmark; self.server = server; self.token = token
    }
    public func validate() throws {
        try WorkerConfiguration(server: server, token: token).validate()
        guard !bookmark.isEmpty else { throw IPCError.invalidConfiguration }
    }
}

public struct WorkerConfiguration: Codable, Equatable, Sendable {
    public let server: URL
    public let token: String
    public init(server: URL, token: String) { self.server = server; self.token = token }
    public func validate() throws {
        guard !token.isEmpty, server.user == nil, server.password == nil,
              let host = server.host,
              server.scheme == "https" || (server.scheme == "http" && ["localhost", "127.0.0.1", "::1"].contains(host))
        else { throw IPCError.invalidConfiguration }
    }
}

public enum IPCError: LocalizedError {
    case invalidConfiguration, disconnected, busy, remote(String)
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Invalid worker configuration"
        case .disconnected: return "The background service disconnected. Retry the operation."
        case .busy: return "The background service is already busy"
        case .remote(let message): return message
        }
    }
}
