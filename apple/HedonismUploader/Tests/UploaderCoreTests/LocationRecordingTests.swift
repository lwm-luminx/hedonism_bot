import XCTest
@testable import UploaderCore

final class LocationRecordingTests: XCTestCase {
    func testSavedRecordingRoundTripsAbsoluteTimestamps() throws {
        let timestamp = Date(timeIntervalSince1970: 1_791_489_600)
        let sample = LocationSample(timestamp: timestamp, latitude: 39.7, longitude: -104.9, accuracy: 12)
        let recording = LocationRecording(startedAt: timestamp, stoppedAt: timestamp.addingTimeInterval(60), samples: [sample])
        let restored = try JSONDecoder().decode(LocationRecording.self, from: JSONEncoder().encode(recording))
        XCTAssertEqual(restored, recording)
        let payload = restored.uploadValue
        let samples = try XCTUnwrap(payload["samples"] as? [[String: Any]])
        XCTAssertEqual(samples.first?["latitude"] as? Double, sample.latitude)
        XCTAssertEqual(samples.first?["timestamp"] as? String, ISO8601DateFormatter().string(from: timestamp))
    }
}
