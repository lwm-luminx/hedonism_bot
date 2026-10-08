import XCTest
@testable import UploaderCore

final class UploadAccountTests: XCTestCase {
    func testSavedMetadataRoundTripsWithoutCredentials() throws {
        let account = UploadAccount(name: "Rick", subdomain: "rick", server: ServiceEndpoints.api)
        let data = try JSONEncoder().encode(account)
        XCTAssertEqual(try JSONDecoder().decode(UploadAccount.self, from: data), account)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("token"))
    }

    func testDifferentAccountsHaveIndependentUploadHistory() {
        let first = UploadAccount(name: "First", subdomain: "first", server: ServiceEndpoints.api)
        let second = UploadAccount(name: "Second", subdomain: "second", server: ServiceEndpoints.api)
        XCTAssertNotEqual(first.ledgerURL, second.ledgerURL)
    }
}
