import XCTest
import CardTestSupport
@testable import UploaderCore

/// Scans and uploads real FAT32/ExFAT volumes, using attached disk images in place of SD cards.
final class DiskImageCardTests: XCTestCase {
    private var cards: [DiskImageCard] = []

    override func tearDownWithError() throws {
        for card in cards { try card.detach(force: true) }
        cards = []
        FakeServer.reset()
    }

    private func insertCard(format: DiskImageCard.Format = .fat32) throws -> DiskImageCard {
        let card = try DiskImageCard(format: format)
        cards.append(card)
        return card
    }

    private func uploader(ledger: UploadLedger? = nil) -> CardUploader {
        let client = HedonismClient(serverURL: URL(string: "https://rick.hedonism.test")!, token: "hbsa_test", session: FakeServer.session())
        let ledger = ledger ?? UploadLedger(url: FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).json"))
        return CardUploader(client: client, ledger: ledger)
    }

    func testAnAttachedImageLooksLikeACardToTheSystem() throws {
        for format in DiskImageCard.Format.allCases {
            let card = try insertCard(format: format)
            let values = try card.resourceValues()
            XCTAssertEqual(values.volumeIsRemovable, true, "\(format)")
            XCTAssertEqual(values.volumeIsEjectable, true, "\(format)")
            XCTAssertEqual(values.volumeIsReadOnly, false, "\(format)")
            XCTAssertEqual(values.volumeName, card.name)
            XCTAssertTrue(try card.root().path.hasPrefix("/Volumes/"), "\(format)")
            XCTAssertTrue(CardScanner.isCameraCard(try card.root()), "\(format)")
        }
    }

    func testScansPhotosOnFAT32AndExFATCardsAndSkipsWhatMacOSWritesThere() throws {
        for format in DiskImageCard.Format.allCases {
            let card = try insertCard(format: format)
            try card.add("DSC00001.ARW")
            try card.addWithSidecar("DSC00001.HIF")
            try card.add("C0001.MP4")
            try Data().write(to: try card.root().appendingPathComponent("DCIM/100MSDCF/.DS_Store"))

            let sidecar = try card.root().appendingPathComponent("DCIM/100MSDCF/._DSC00001.HIF")
            XCTAssertTrue(FileManager.default.fileExists(atPath: sidecar.path), "macOS keeps AppleDouble sidecars on \(format)")

            let names = CardScanner.photos(on: try card.root()).map(\.filename).sorted()
            XCTAssertEqual(names, ["DSC00001.ARW", "DSC00001.HIF"], "\(format)")
        }
    }

    func testCardFilesKeepTheirLedgerKeysAcrossReinsertion() throws {
        let card = try insertCard()
        // FAT timestamps have two-second resolution; the key must survive the rounding and a remount.
        try card.add("DSC00001.ARW", contents: "raw", modified: Date(timeIntervalSince1970: 1_791_331_201))
        try card.add("DSC00002.ARW", contents: "raw two", modified: Date(timeIntervalSince1970: 1_791_331_333))
        let before = CardScanner.photos(on: try card.root())
        let hashesBefore = try before.map { try FileHasher.digests(of: $0.url).sha256 }

        try card.reattach()

        let after = CardScanner.photos(on: try card.root())
        XCTAssertEqual(after.map(\.ledgerKey), before.map(\.ledgerKey))
        XCTAssertEqual(try after.map { try FileHasher.digests(of: $0.url).sha256 }, hashesBefore)
        XCTAssertEqual(after.map(\.filename), ["DSC00001.ARW", "DSC00002.ARW"], "oldest first")
    }

    func testUploadsFromACardWithTheLockSwitchOn() async throws {
        let card = try insertCard()
        try card.add("DSC00001.ARW", contents: "raw bytes")
        try card.add("DSC00001.HIF", contents: "heif bytes")
        try card.reattach(options: .readOnly)
        XCTAssertEqual(try card.resourceValues().volumeIsReadOnly, true)

        let ledgerURL = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).json")
        let result = try await uploader(ledger: UploadLedger(url: ledgerURL)).upload(volume: try card.root()) { _ in }

        XCTAssertEqual(result.uploadedFiles, 2)
        XCTAssertEqual(result.failedFiles, 0)
        XCTAssertEqual(FakeServer.requests.filter { $0.httpMethod == "PUT" }.count, 2)
        XCTAssertEqual(UploadLedger(url: ledgerURL).count, 2, "the ledger lives off the card, so a locked card still records progress")
    }

    func testPullingTheCardMidUploadFailsTheRemainingFilesWithoutStoppingTheRun() async throws {
        let card = try insertCard()
        try card.add("DSC00001.ARW", contents: "first", modified: Date(timeIntervalSince1970: 1_791_331_200))
        try card.add("DSC00002.ARW", contents: "second", modified: Date(timeIntervalSince1970: 1_791_331_300))
        try card.add("DSC00003.ARW", contents: "third", modified: Date(timeIntervalSince1970: 1_791_331_400))

        let pulled = PulledCard(card)
        let result = try await uploader().upload(volume: try card.root()) { progress in
            // Hashing reports "Checking …"; yank the card once the second file's upload starts.
            if progress.currentFile == "DSC00002.ARW" { pulled.pull() }
        }

        XCTAssertTrue(pulled.wasPulled)
        XCTAssertNil(pulled.failure, "pulling the card failed: \(pulled.failure.map(String.init(describing:)) ?? "")")
        XCTAssertFalse(card.isAttached)
        XCTAssertEqual(result.uploadedFiles, 1)
        XCTAssertEqual(result.failedFiles, 2)
        // The PUTs for the missing files still go out, with no bytes to send; storage rejects them (Content-MD5 mismatch).
        let puts = zip(FakeServer.requests, FakeServer.bodies).filter { $0.0.httpMethod == "PUT" }
        XCTAssertEqual(puts.map { $0.0.url!.lastPathComponent }, ["DSC00001.ARW", "DSC00002.ARW", "DSC00003.ARW"])
        XCTAssertEqual(puts.map { String(decoding: $0.1, as: UTF8.self) }, ["first", "", ""])
        let finishes = FakeServer.bodies.compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            .filter { ($0["query"] as? String)?.contains("updatePhotoPromiseFileUpdate") == true }
            .compactMap { ($0["variables"] as? [String: Any])?["status"] as? String }
        XCTAssertEqual(finishes.sorted(), ["FAILED", "FAILED", "SUCCESS"])
    }

    func testReinsertingTheCardAfterAFailureUploadsOnlyWhatIsMissing() async throws {
        let card = try insertCard()
        try card.add("DSC00001.ARW", contents: "first")
        try card.add("DSC00002.ARW", contents: "second", modified: Date(timeIntervalSince1970: 1_791_331_300))
        FakeServer.failUploadsNamed = ["DSC00002.ARW"]
        let ledgerURL = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString).json")

        let first = try await uploader(ledger: UploadLedger(url: ledgerURL)).upload(volume: try card.root()) { _ in }
        XCTAssertEqual(first.uploadedFiles, 1)
        XCTAssertEqual(first.failedFiles, 1)

        try card.reattach()
        let uploaded = try FileHasher.digests(of: try card.root().appendingPathComponent("DCIM/100MSDCF/DSC00001.ARW")).sha256
        FakeServer.reset()
        FakeServer.uploadedHashes = [uploaded.base64EncodedString()]

        let second = try await uploader(ledger: UploadLedger(url: ledgerURL)).upload(volume: try card.root()) { _ in }
        XCTAssertEqual(second.totalFiles, 1)
        XCTAssertEqual(second.uploadedFiles, 1)
        XCTAssertEqual(FakeServer.requests.filter { $0.httpMethod == "PUT" }.map { $0.url!.lastPathComponent }, ["DSC00002.ARW"])
    }
}

/// Yanks a card from inside the uploader's progress callback, once.
private final class PulledCard: @unchecked Sendable {
    private let card: DiskImageCard
    private let lock = NSLock()
    private(set) var wasPulled = false
    private(set) var failure: Error?

    init(_ card: DiskImageCard) { self.card = card }

    func pull() {
        lock.lock(); defer { lock.unlock() }
        guard !wasPulled else { return }
        wasPulled = true
        do { try card.detach(force: true) } catch { failure = error }
    }
}
