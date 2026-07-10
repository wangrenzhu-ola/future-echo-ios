import XCTest
@testable import FutureEcho

final class BaselineTests: XCTestCase {
    func testAppModuleLoads() {
        XCTAssertEqual("Future Echo", "Future Echo")
    }
}

