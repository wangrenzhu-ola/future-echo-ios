import XCTest
@testable import FutureEchoCore

@available(macOS 14.0, *)
final class SwiftDataPersistenceTests: XCTestCase {
    func testSnapshotRoundTripsThroughSwiftData() throws {
        let repository = try SwiftDataSnapshotRepository(inMemory: true)
        let promise = SavingsPromise(
            title: "Emergency Cushion",
            targetAmount: Decimal(2000),
            currentSavedAmount: Decimal(640),
            plannedContribution: Decimal(32),
            themeToken: .coral
        )
        let expected = AppSnapshot(promises: [promise])

        try repository.save(expected)

        XCTAssertEqual(try repository.load(), expected)
        try repository.reset()
        XCTAssertEqual(try repository.load(), AppSnapshot())
    }
}
