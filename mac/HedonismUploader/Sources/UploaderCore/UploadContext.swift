import Foundation

/// Explicit album destination and shoot details, shared by both apps.
public struct UploadContext: Equatable, Sendable {
    public let albumName: String
    public let event: String
    public let venue: String

    public init(albumName: String, event: String, venue: String) {
        self.albumName = albumName
        self.event = event
        self.venue = venue
    }
}
