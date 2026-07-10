import XCTest

final class BaselineUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Future Echo"].waitForExistence(timeout: 5))
    }
}

