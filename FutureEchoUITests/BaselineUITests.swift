import XCTest

final class BaselineUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPromisePauseWaitRevisitTrailAndDeletionSurviveRelaunch() {
        let app = launch(reset: true)
        XCTAssertTrue(app.buttons["horizon.createPromise"].waitForExistence(timeout: 8))
        createPromise(in: app)

        app.terminate()
        app.launchArguments = ["-forceJSONStore"]
        app.launch()
        XCTAssertTrue(app.buttons["horizon.newEcho"].waitForExistence(timeout: 8))

        app.buttons["horizon.newEcho"].tap()
        replaceText(in: app.textFields["echo.amount"], with: "128")
        replaceText(in: app.textFields["field.checkout-note-(optional)"], with: "Shoes after a long week")
        let promiseLens = element("echo.promiseLens", in: app)
        XCTAssertTrue(promiseLens.waitForExistence(timeout: 4))
        app.buttons["echo.enterPause"].tap()
        XCTAssertTrue(app.staticTexts["pause.countdown"].waitForExistence(timeout: 4))
        app.buttons["pause.skip"].tap()
        XCTAssertTrue(app.buttons["decision.wait-24-hours"].waitForExistence(timeout: 4))
        app.buttons["decision.wait-24-hours"].tap()

        app.terminate()
        app.launchArguments = ["-forceJSONStore"]
        app.launch()
        app.tabBars.buttons["Shelf"].tap()
        XCTAssertTrue(app.buttons["shelf.card"].waitForExistence(timeout: 8))
        app.buttons["shelf.card"].tap()
        replaceText(in: app.textFields["field.purchase-amount"], with: "130")
        replaceText(in: app.textFields["field.checkout-note-(optional)"], with: "Shoes after a calm revisit")
        app.buttons["cooling.save"].tap()
        app.buttons["decision.skip-purchase"].tap()

        app.tabBars.buttons["Trail"].tap()
        XCTAssertTrue(app.buttons["trail.outcome"].waitForExistence(timeout: 6))
        app.buttons["trail.outcome"].tap()
        replaceText(in: app.textFields["field.reflection-(optional)"], with: "Waiting made the choice clearer.")
        app.buttons["outcome.save"].tap()
        XCTAssertTrue(app.staticTexts["Waiting made the choice clearer."].waitForExistence(timeout: 5))
        app.buttons["trail.outcome"].tap()
        app.buttons["outcome.delete"].tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["outcome.delete"].exists)
        app.buttons["outcome.delete"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(element("trail.empty", in: app).waitForExistence(timeout: 5))
    }

    func testPrivacyPremiumAndRecoverablePersistenceFailureAreVisible() {
        let app = launch(reset: true)
        createPromise(in: app)

        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings.privacy"].tap()
        XCTAssertTrue(element("privacy.screen", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Future Echo does not connect to a bank or read account balances."].exists)
        app.buttons["Close"].tap()
        app.buttons["settings.future-echo-plus"].tap()
        XCTAssertTrue(element("premium.screen", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["premium.restore"].exists)
        app.buttons["Close"].tap()

        app.terminate()
        app.launchArguments = ["-forceJSONStore", "-simulatePersistenceFailure"]
        app.launch()
        app.buttons["horizon.newEcho"].tap()
        replaceText(in: app.textFields["echo.amount"], with: "128")
        app.buttons["echo.enterPause"].tap()
        app.buttons["pause.skip"].tap()
        app.buttons["decision.skip-purchase"].tap()
        XCTAssertTrue(app.buttons["decision.retry"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["decision.saveLater"].exists)
        XCTAssertTrue(app.staticTexts["Couldn't save your decision. Try again or choose Save Later."].exists)
    }

    private func launch(reset: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = reset ? ["-forceJSONStore", "-resetStore"] : ["-forceJSONStore"]
        app.launch()
        return app
    }

    private func createPromise(in app: XCUIApplication) {
        app.buttons["horizon.createPromise"].tap()
        replaceText(in: app.textFields["field.promise-name"], with: "Emergency Cushion")
        replaceText(in: app.textFields["field.goal-amount"], with: "2000")
        replaceText(in: app.textFields["field.currently-saved"], with: "640")
        replaceText(in: app.textFields["field.planned-deposit-(optional)"], with: "32")
        app.buttons["promise.save"].tap()
        XCTAssertTrue(app.buttons["horizon.newEcho"].waitForExistence(timeout: 5))
    }

    private func replaceText(in element: XCUIElement, with value: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.tap()
        if let existing = element.value as? String, !existing.isEmpty, existing != element.placeholderValue {
            element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        element.typeText(value)
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
