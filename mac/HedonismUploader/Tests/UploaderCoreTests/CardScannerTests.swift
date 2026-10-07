import XCTest
@testable import UploaderCore

final class CardScannerTests: XCTestCase {
    func testRecognisesACameraCard() throws {
        let card = try TemporaryCard()
        XCTAssertTrue(CardScanner.isCameraCard(card.root))
        XCTAssertFalse(CardScanner.isCameraCard(FileManager.default.temporaryDirectory))
    }

    func testFindsSupportedPhotosOnly() throws {
        let card = try TemporaryCard()
        try card.add("DSC00001.ARW")
        try card.add("DSC00001.HIF")
        try card.add("C0001.MP4")
        try card.add("._DSC00001.ARW")

        let names = CardScanner.photos(on: card.root).map(\.filename).sorted()
        XCTAssertEqual(names, ["DSC00001.ARW", "DSC00001.HIF"])
    }

    func testGroupsFilesIntoShotsByBasename() throws {
        let card = try TemporaryCard()
        try card.add("DSC00001.ARW")
        try card.add("DSC00001.HIF")
        try card.add("DSC00002.ARW", modified: Date(timeIntervalSince1970: 1_791_331_300))

        let shots = CardScanner.shots(CardScanner.photos(on: card.root))
        XCTAssertEqual(shots.map { $0.map(\.filename).sorted() }, [["DSC00001.ARW", "DSC00001.HIF"], ["DSC00002.ARW"]])
    }

    func testContentTypes() {
        let file = PhotoFile(url: URL(fileURLWithPath: "/DCIM/DSC00001.ARW"), size: 1, modified: .distantPast)
        XCTAssertEqual(file.contentType, "image/x-sony-arw")
        XCTAssertEqual(file.basename, "dsc00001")
    }
}
