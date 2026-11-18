import XCTest
@testable import UploaderCore

final class SignInOutcomeTests: XCTestCase {
    func testReadsACredential() throws {
        guard case .credential(let token) = try SignInOutcome(json: ["token": "hbsa_abc", "subdomain": "luminx"]) else {
            return XCTFail("Expected a credential")
        }
        XCTAssertEqual(token, "hbsa_abc")
    }

    func testReadsArchivesToChooseFrom() throws {
        let json: [String: Any] = ["selection": "signed", "photographers": [
            ["subdomain": "lovewins", "name": "Love Wins"], ["subdomain": "luminx", "name": "Luminx"],
        ]]
        guard case .chooseArchive(let selection, let archives) = try SignInOutcome(json: json) else {
            return XCTFail("Expected archives to choose from")
        }
        XCTAssertEqual(selection, "signed")
        XCTAssertEqual(archives, [ArchiveOption(subdomain: "lovewins", name: "Love Wins"), ArchiveOption(subdomain: "luminx", name: "Luminx")])
    }

    func testReportsTheServersError() {
        XCTAssertThrowsError(try SignInOutcome(json: ["error": "No archive"])) { error in
            XCTAssertEqual(error as? HedonismClientError, .unexpectedResponse("No archive"))
        }
    }

    func testRejectsAnEmptyArchiveList() {
        XCTAssertThrowsError(try SignInOutcome(json: ["selection": "signed", "photographers": [[String: Any]]()]))
    }
}
