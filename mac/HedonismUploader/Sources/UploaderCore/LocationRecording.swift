import Foundation

public struct LocationSample: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double

    public init(timestamp: Date, latitude: Double, longitude: Double, accuracy: Double) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
    }
}

public struct LocationRecording: Codable, Equatable, Sendable {
    public var startedAt: Date
    public var stoppedAt: Date?
    public var samples: [LocationSample]

    public init(startedAt: Date = Date(), stoppedAt: Date? = nil, samples: [LocationSample] = []) {
        self.startedAt = startedAt
        self.stoppedAt = stoppedAt
        self.samples = samples
    }

    public var uploadValue: [String: Any] {
        let formatter = ISO8601DateFormatter()
        return ["startedAt": formatter.string(from: startedAt),
                "stoppedAt": formatter.string(from: stoppedAt ?? Date()),
                "samples": samples.map { ["timestamp": formatter.string(from: $0.timestamp),
                                            "latitude": $0.latitude, "longitude": $0.longitude,
                                            "accuracy": $0.accuracy] as [String: Any] }]
    }
}
