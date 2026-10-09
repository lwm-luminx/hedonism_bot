import Foundation

public struct UploadAccount: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let subdomain: String
    public let server: URL

    public init(id: UUID = UUID(), name: String, subdomain: String, server: URL) {
        self.id = id
        self.name = name
        self.subdomain = subdomain
        self.server = server
    }

    /// Credentials are stored separately in Keychain; upload history is isolated per destination.
    public var ledgerURL: URL {
        UploadLedger.defaultURL.deletingLastPathComponent().appendingPathComponent("accounts/\(id.uuidString).json")
    }
}
