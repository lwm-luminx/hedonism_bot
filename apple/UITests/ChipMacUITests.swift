import XCTest
import CoreGraphics
import CryptoKit
import ImageIO
import UniformTypeIdentifiers

/// End-to-end tests for Chip for Mac against a live server's review archive.
///
/// The upload test signs in with the reusable App Review device code and uploads two freshly
/// generated JPEGs. Pass the code to the test runner with
/// `TEST_RUNNER_CHIP_REVIEW_CODE=<code> xcodebuild … test`; without it the live tests are skipped.
/// `TEST_RUNNER_CHIP_REVIEW_SERVER` overrides the default https://api.lumiere.host.
@MainActor
final class ChipMacUITests: XCTestCase {
    private var environment: [String: String] { ProcessInfo.processInfo.environment }
    private var server: URL { URL(string: environment["CHIP_REVIEW_SERVER"] ?? "https://api.lumiere.host")! }

    override func setUpWithError() throws { continueAfterFailure = false }

    // MARK: Sign-in page

    func testSignInPageControls() {
        let app = launch(["--ui-testing", "--reset-test-accounts"])
        XCTAssertTrue(app.staticTexts["Chip"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Select card / DCIM folder"].exists)

        let apple = element(app, "signInWithApple")
        XCTAssertTrue(apple.exists, "Sign in with Apple button is missing")
        XCTAssertFalse(apple.isEnabled, "Sign in with Apple must wait for a subdomain")
        XCTAssertFalse(app.buttons["Continue with Facebook"].isEnabled)

        let subdomain = app.textFields["Photographer subdomain"]
        subdomain.click()
        subdomain.typeText("review")
        XCTAssertTrue(apple.isEnabled, "Sign in with Apple should enable once a subdomain is entered")
        XCTAssertTrue(app.buttons["Continue with Facebook"].isEnabled)

        app.buttons["switchSignInMethod"].click()
        let code = app.textFields["deviceCodeField"]
        XCTAssertTrue(code.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Sign in with device code"].isEnabled)
        code.click()
        code.typeText("ABCD-1234-ABCD-1234")
        XCTAssertTrue(app.buttons["Sign in with device code"].isEnabled)
        attachScreenshot(app, "Sign-in page")
    }

    // MARK: Live upload to the review archive

    func testUploadsToReviewArchiveAndSkipsCompletedFiles() async throws {
        guard let code = environment["CHIP_REVIEW_CODE"], !code.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_CHIP_REVIEW_CODE to the review device code to run the live upload test")
        }
        let stamp = ISO8601DateFormatter().string(from: Date())
        let album = "UI test \(stamp)"
        let photos = try (1...2).map { try Self.uniqueJPEG(index: $0) }
        let encoded = Dictionary(uniqueKeysWithValues: photos.map { ($0.name, $0.data.base64EncodedString()) })

        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-accounts", "--ui-test-folder"]
        app.launchEnvironment["CHIP_UI_TEST_FILES"] = String(decoding: try JSONEncoder().encode(encoded), as: UTF8.self)
        app.launch()

        // Sign in with the review code.
        XCTAssertTrue(app.staticTexts["Chip"].waitForExistence(timeout: 10))
        if server.absoluteString != "https://api.lumiere.host" {
            app.disclosureTriangles.firstMatch.click()
            let field = app.textFields["Server URL"]
            field.click()
            field.typeKey("a", modifierFlags: .command)
            field.typeText(server.absoluteString)
        }
        app.buttons["switchSignInMethod"].click()
        let codeField = app.textFields["deviceCodeField"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 5))
        codeField.click()
        codeField.typeText(code)
        app.buttons["Sign in with device code"].click()

        let picker = element(app, "uploadAccountPicker")
        XCTAssertTrue(picker.waitForExistence(timeout: 30), signInFailure(app))
        XCTAssertTrue(pickerTitle(picker).contains("review"), "Signed in to \(pickerTitle(picker)), not the review archive")

        // Account settings App Review asks for.
        XCTAssertTrue(element(app, "Privacy policy").exists, "Privacy policy link is missing")
        XCTAssertTrue(element(app, "Delete my account and data").exists, "Account deletion link is missing")
        XCTAssertTrue(element(app, "signInWithApple").exists, "Link Apple ID button is missing")

        // The generated folder is preselected.
        let status = element(app, "uploadStatus")
        XCTAssertTrue(wait(for: status, toContain: "2 supported files", timeout: 10), "Fixture folder not selected: \(text(status))")
        for photo in photos { XCTAssertTrue(app.staticTexts[photo.name].exists, "\(photo.name) is not listed") }

        // Shoot details.
        fill(app, "Album", album)
        fill(app, "Event", "Chip for Mac UI test")
        fill(app, "Venue", "Xcode test runner")
        attachScreenshot(app, "Ready to upload")

        let upload = app.buttons["Upload new files"]
        XCTAssertTrue(upload.isEnabled)
        upload.click()
        XCTAssertTrue(wait(for: status, toContain: "2 uploaded; 0 failed", timeout: 180), "Upload did not complete: \(text(status))")
        attachScreenshot(app, "Uploaded")

        // Server side: both photos are in the review archive, in the album with its shoot details.
        let token = try await Self.exchange(code: code, server: server)
        let archive = try await Self.graphQL("query { photographer { subdomain } }", token: token, server: server)
        XCTAssertEqual((archive["photographer"] as? [String: Any])?["subdomain"] as? String, "review")
        let stored = try await Self.uploadedHashes(photos.map(\.sha256), token: token, server: server)
        XCTAssertEqual(stored, Set(photos.map(\.sha256)), "The server does not have both uploaded photos")
        let folder = try await Self.waitForFolder(named: album, photos: photos.count, token: token, server: server)
        let context = folder["uploadContext"] as? [String: Any] ?? [:]
        XCTAssertEqual(context["event"] as? String, "Chip for Mac UI test")
        XCTAssertEqual(context["venue"] as? String, "Xcode test runner")

        // Uploading the same folder again skips the completed files.
        XCTAssertTrue(upload.waitForExistence(timeout: 10) && upload.isEnabled)
        upload.click()
        XCTAssertTrue(wait(for: status, toContain: "0 uploaded; 0 failed", timeout: 60), "Re-upload did not skip completed files: \(text(status))")

        // Signing out removes the account and returns to the sign-in page.
        app.buttons["Sign out of selected account"].click()
        XCTAssertTrue(app.staticTexts["Chip"].waitForExistence(timeout: 10), "Sign-out did not return to the sign-in page")
        XCTAssertFalse(element(app, "uploadAccountPicker").exists)
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Chip"].waitForExistence(timeout: 10), "The signed-out account came back after relaunch")
    }

    // MARK: UI helpers

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func fill(_ app: XCUIApplication, _ field: String, _ value: String) {
        let input = app.textFields[field]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "\(field) field is missing")
        input.click()
        input.typeText(value)
        XCTAssertEqual(input.value as? String, value)
    }

    private func text(_ element: XCUIElement) -> String {
        [element.value as? String, element.label].compactMap { $0 }.first { !$0.isEmpty } ?? ""
    }

    private func pickerTitle(_ picker: XCUIElement) -> String {
        [picker.value as? String, picker.label, picker.title].compactMap { $0 }.joined(separator: " ")
    }

    private func wait(for element: XCUIElement, toContain substring: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate { _, _ in self.text(element).contains(substring) }
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: timeout) == .completed
    }

    private func signInFailure(_ app: XCUIApplication) -> String {
        let error = element(app, "signInError")
        return error.exists ? "Sign-in failed: \(text(error))" : "Sign-in did not finish"
    }

    private func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    // MARK: Fixtures

    struct Photo {
        let name: String
        let data: Data
        var sha256: Data { Data(SHA256.hash(data: data)) }
    }

    /// A small JPEG whose pixels and EXIF comment are unique to this run, so the server has never seen it.
    static func uniqueJPEG(index: Int) throws -> Photo {
        let width = 64, height = 48
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw XCTSkip("Could not create a drawing context")
        }
        for x in stride(from: 0, to: width, by: 8) {
            for y in stride(from: 0, to: height, by: 8) {
                context.setFillColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
                context.fill(CGRect(x: x, y: y, width: 8, height: 8))
            }
        }
        let output = NSMutableData()
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw XCTSkip("Could not encode a JPEG")
        }
        let date = DateFormatter()
        date.dateFormat = "yyyy:MM:dd HH:mm:ss"
        date.locale = Locale(identifier: "en_US_POSIX")
        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.9,
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifUserComment: "Chip for Mac UI test \(UUID().uuidString)",
                kCGImagePropertyExifDateTimeOriginal: date.string(from: Date().addingTimeInterval(Double(index))),
            ],
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw XCTSkip("Could not encode a JPEG") }
        return Photo(name: String(format: "CHIP%04d.JPG", index), data: output as Data)
    }

    // MARK: Server checks

    static func exchange(code: String, server: URL) async throws -> String {
        var request = URLRequest(url: server.appendingPathComponent("auth/device/exchange"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["code": code])
        let json = try await send(request)
        guard let token = json["token"] as? String else { throw failure("Device code exchange returned no token: \(json)") }
        return token
    }

    static func uploadedHashes(_ hashes: [Data], token: String, server: URL) async throws -> Set<Data> {
        var request = URLRequest(url: server.appendingPathComponent("auth/uploaded_contents"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["hashes": hashes.map { $0.base64EncodedString() }])
        let json = try await send(request)
        return Set((json["hashes"] as? [String] ?? []).compactMap { Data(base64Encoded: $0) })
    }

    static func graphQL(_ query: String, variables: [String: Any] = [:], token: String, server: URL) async throws -> [String: Any] {
        var request = URLRequest(url: server.appendingPathComponent("graphql"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "variables": variables])
        let json = try await send(request)
        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty { throw failure("GraphQL errors: \(errors)") }
        return json["data"] as? [String: Any] ?? [:]
    }

    /// Finds the album by name, waiting for the server to turn both uploads into photos.
    static func waitForFolder(named name: String, photos: Int, token: String, server: URL) async throws -> [String: Any] {
        let query = """
        query($after: String) {
          folders(first: 100, after: $after) {
            pageInfo { hasNextPage endCursor }
            nodes { name photoCount uploadContext }
          }
        }
        """
        var last: [String: Any]?
        for _ in 0..<30 {
            var after: String?
            repeat {
                let data = try await graphQL(query, variables: after.map { ["after": $0] } ?? [:], token: token, server: server)
                let folders = data["folders"] as? [String: Any] ?? [:]
                if let match = (folders["nodes"] as? [[String: Any]] ?? []).first(where: { $0["name"] as? String == name }) {
                    last = match
                    if (match["photoCount"] as? Int ?? 0) >= photos { return match }
                }
                let page = folders["pageInfo"] as? [String: Any] ?? [:]
                after = page["hasNextPage"] as? Bool == true ? page["endCursor"] as? String : nil
            } while after != nil
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
        throw failure(last.map { "Album \(name) has \($0["photoCount"] ?? 0) photos, expected \(photos)" }
                      ?? "Album \(name) was not found in the review archive")
    }

    private static func send(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw failure("\(request.url?.path ?? "") returned HTTP \(status): \(String(decoding: data.prefix(500), as: UTF8.self))")
        }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    private static func failure(_ message: String) -> Error {
        NSError(domain: "ChipMacUITests", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
