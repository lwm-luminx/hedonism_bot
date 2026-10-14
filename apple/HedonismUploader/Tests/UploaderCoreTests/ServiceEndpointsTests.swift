import XCTest
@testable import UploaderCore

final class ServiceEndpointsTests: XCTestCase {
    func testPublicEndpoints() {
        XCTAssertEqual(ServiceEndpoints.api.appendingPathComponent("graphql").absoluteString, "https://api.lumiere.host/graphql")
        XCTAssertEqual(ServiceEndpoints.photographerSite(subdomain: "rick")?.absoluteString, "https://rick.lumiere.host")
    }

    func testRejectsReservedAndInvalidSubdomains() {
        for name in ["api", "www", "rick.example", "../rick", "", "-rick"] {
            XCTAssertNil(ServiceEndpoints.photographerSite(subdomain: name))
        }
    }
}
