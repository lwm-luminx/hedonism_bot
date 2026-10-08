import XCTest
@testable import UploaderCore

final class CardUploaderTests: XCTestCase {
    private var card: TemporaryCard!
    private var ledger: UploadLedger!
    private var uploader: CardUploader!

    override func setUpWithError() throws {
        FakeServer.reset()
        card = try TemporaryCard()
        ledger = UploadLedger(url: FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).json"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let client = HedonismClient(serverURL: URL(string: "https://rick.hedonism.test")!, token: "hbsa_test", session: FakeServer.session())
        uploader = CardUploader(client: client, ledger: ledger, albumPrefix: "SD", calendar: calendar)
    }

    func testUploadsEveryFileIntoAnAlbumPerDay() async throws {
        try card.add("DSC00001.ARW")
        try card.add("DSC00001.HIF")

        let result = try await uploader.upload(volume: card.root) { _ in }

        XCTAssertEqual(result.uploadedFiles, 2)
        XCTAssertEqual(FakeServer.requests.filter { $0.httpMethod == "PUT" }.map { $0.url!.path }.sorted(),
                       ["/uploads/DSC00001.ARW", "/uploads/DSC00001.HIF"])
        let albums = FakeServer.bodies.compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            .compactMap { ($0["variables"] as? [String: Any])?["album"] as? String }
        XCTAssertEqual(albums, ["SD 2026-10-07"])
    }

    func testExplicitShootDetailsAndDCIMSelection() async throws {
        try card.add("DSC00001.ARW")
        let client = HedonismClient(serverURL: URL(string: "https://rick.hedonism.test")!, token: "hbsa_test", session: FakeServer.session())
        let uploader = CardUploader(client: client, ledger: ledger, albumPrefix: "SD",
                                    context: UploadContext(albumName: "Opening night", event: "Launch", venue: "The Hall"))
        let result = try await uploader.upload(volume: card.root.appendingPathComponent("DCIM")) { _ in }
        XCTAssertEqual(result.uploadedFiles, 1)
        let bodies = FakeServer.bodies.compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let variables = bodies.compactMap { $0["variables"] as? [String: Any] }.first { $0["album"] != nil }
        XCTAssertEqual(variables?["album"] as? String, "Opening night")
        XCTAssertEqual(variables?["context"] as? [String: String], ["event": "Launch", "venue": "The Hall"])
    }

    func testSendsTheTokenAndTheUploadHeaders() async throws {
        try card.add("DSC00001.ARW", contents: "hello")

        _ = try await uploader.upload(volume: card.root) { _ in }

        XCTAssertEqual(FakeServer.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer hbsa_test")
        let put = FakeServer.requests.first { $0.httpMethod == "PUT" }
        XCTAssertEqual(put?.value(forHTTPHeaderField: "Content-MD5"), "XUFAKrxLKna5cZ2REBfFkg==")
    }

    func testSkipsFilesAlreadyUploaded() async throws {
        try card.add("DSC00001.ARW")
        _ = try await uploader.upload(volume: card.root) { _ in }
        FakeServer.reset()

        let result = try await uploader.upload(volume: card.root) { _ in }

        XCTAssertEqual(result.totalFiles, 0)
        XCTAssertTrue(FakeServer.requests.isEmpty)
    }

    func testCountsAFailedFileAndRetriesItNextTime() async throws {
        try card.add("DSC00001.ARW")
        FakeServer.failUploadsNamed = ["DSC00001.ARW"]

        let result = try await uploader.upload(volume: card.root) { _ in }

        XCTAssertEqual(result.failedFiles, 1)
        XCTAssertFalse(ledger.contains(CardScanner.photos(on: card.root)[0]))
    }

    func testStopsOnARejectedToken() async throws {
        try card.add("DSC00001.ARW")
        FakeServer.status = 401

        do {
            _ = try await uploader.upload(volume: card.root) { _ in }
            XCTFail("expected the run to stop")
        } catch let error as HedonismClientError {
            XCTAssertEqual(error.errorDescription, "The service account token was rejected.")
        }
    }
}
