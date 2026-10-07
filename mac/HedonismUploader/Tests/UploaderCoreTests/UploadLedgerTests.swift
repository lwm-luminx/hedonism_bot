import XCTest
@testable import UploaderCore

final class UploadLedgerTests: XCTestCase {
    func testRemembersUploadsAcrossLaunches() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString)/uploaded.json")
        let file = PhotoFile(url: URL(fileURLWithPath: "/DCIM/DSC00001.ARW"), size: 10, modified: Date(timeIntervalSince1970: 5))

        try UploadLedger(url: url).record(file)

        XCTAssertTrue(UploadLedger(url: url).contains(file))
    }

    func testTreatsAReusedFilenameWithDifferentContentsAsNew() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledger-\(UUID().uuidString)/uploaded.json")
        let ledger = UploadLedger(url: url)
        try ledger.record(PhotoFile(url: URL(fileURLWithPath: "/DCIM/DSC00001.ARW"), size: 10, modified: Date(timeIntervalSince1970: 5)))

        XCTAssertFalse(ledger.contains(PhotoFile(url: URL(fileURLWithPath: "/DCIM/DSC00001.ARW"), size: 11, modified: Date(timeIntervalSince1970: 9))))
    }
}
