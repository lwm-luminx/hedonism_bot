import XCTest
@testable import UploaderCore

final class FileHasherTests: XCTestCase {
    func testComputesSHA256AndMD5InChunks() throws {
        let card = try TemporaryCard()
        let url = try card.add("DSC00001.ARW", contents: "hello")

        let digests = try FileHasher.digests(of: url, chunkSize: 2)

        XCTAssertEqual(digests.sha256.base64EncodedString(), "LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ=")
        XCTAssertEqual(digests.md5.base64EncodedString(), "XUFAKrxLKna5cZ2REBfFkg==")
    }
}
