import XCTest

final class MobileUploaderUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testLaunchAndShootDetails() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-test-accounts", "--reset-test-accounts"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Chip by Lumière"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Add account"].exists)
        XCTAssertFalse(app.buttons["Upload new files"].isEnabled)
        for (field, value) in [("Album", "Device test"), ("Event", "Opening night"), ("Venue", "The Hall")] {
            let input = app.textFields[field]
            input.tap()
            input.typeText(value)
            XCTAssertEqual(input.value as? String, value)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testSystemFolderPickerCanBeCancelled() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-test-accounts", "--reset-test-accounts"]
        app.launch()
        let picker = app.buttons["Select card / DCIM folder"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        cancel.tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Upload new files"].isEnabled)
    }

    func testAccountSelectionSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-test-accounts", "--reset-test-accounts"]
        app.launch()
        let picker = app.descendants(matching: .any)["uploadAccountPicker"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()
        app.buttons["Test Beta · beta"].tap()
        XCTAssertTrue(picker.label.contains("Test Beta"))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--ui-test-accounts"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.label.contains("Test Beta"))
        app.buttons["Sign out of selected account"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.label.contains("Test Alpha"))
    }

    func testLiveFacebookSignIn() throws {
        guard ProcessInfo.processInfo.environment["LUMIERE_LIVE_FACEBOOK_TEST"] == "1" else {
            throw XCTSkip("Enable explicitly for a live, human-authorized Facebook sign-in")
        }
        let app = XCUIApplication()
        app.launch()
        if app.buttons["Add account"].exists { app.buttons["Add account"].tap() }
        let photographer = app.textFields["Photographer subdomain"]
        XCTAssertTrue(photographer.waitForExistence(timeout: 10))
        photographer.tap()
        photographer.typeText("luminx")
        app.buttons["Continue with Facebook"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let consent = springboard.buttons["Continue"]
        if consent.waitForExistence(timeout: 3) { consent.tap() }
        let browser = app.webViews.firstMatch
        let continueButton = browser.buttons["Continue with Facebook"]
        if continueButton.waitForExistence(timeout: 15) { continueButton.tap() }
        var confirmedFacebook = false
        for _ in 0..<45 {
            if app.navigationBars["Add account"].exists == false,
               app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.exists { break }
            let facebookContinue = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue as '")).firstMatch
            if !confirmedFacebook && facebookContinue.exists && facebookContinue.isHittable {
                confirmedFacebook = true
                facebookContinue.tap()
            }
            Thread.sleep(forTimeInterval: 1)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCTAssertFalse(app.navigationBars["Add account"].exists, "Facebook sign-in did not return to the uploader")
        XCTAssertTrue(app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.label.contains("luminx"))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["uploadAccountPicker"].firstMatch.label.contains("luminx"))
    }

    func testFirstLaunchShowsBrandedSignInAndDeviceCode() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-test-accounts"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Chip"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Select card / DCIM folder"].exists)
        XCTAssertFalse(app.buttons["Continue with Facebook"].isEnabled)
        app.buttons["switchSignInMethod"].tap()
        let code = app.textFields["deviceCodeField"]
        XCTAssertTrue(code.exists)
        XCTAssertFalse(app.buttons["Sign in with device code"].isEnabled)
        code.tap()
        code.typeText("ABCD-1234-ABCD-1234-ABCD")
        XCTAssertTrue(app.buttons["Sign in with device code"].isEnabled)
        app.buttons["switchSignInMethod"].tap()
        XCTAssertTrue(app.textFields["Photographer subdomain"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

}
