import XCTest
@testable import Future_Echo

final class BaselineTests: XCTestCase {
    @MainActor
    func testPersistenceFailureKeepsExistingSnapshotAndShowsRecovery() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("snapshot.json")
        let healthyRepository = JSONSnapshotRepository(fileURL: fileURL)
        let promise = SavingsPromise(
            title: "Emergency Cushion",
            targetAmount: Decimal(2000),
            currentSavedAmount: Decimal(640),
            plannedContribution: Decimal(32),
            themeToken: .coral
        )
        try healthyRepository.save(AppSnapshot(promises: [promise]))

        let failingRepository = JSONSnapshotRepository(fileURL: fileURL, simulateWriteFailure: true)
        let store = EchoStore(repository: failingRepository)
        let result = store.createCoolingCard(
            from: EchoDraft(amount: Decimal(128), note: "Shoes after a long week", promise: promise)
        )

        XCTAssertFalse(result)
        XCTAssertEqual(store.promises, [promise])
        XCTAssertTrue(store.coolingCards.isEmpty)
        XCTAssertEqual(store.errorMessage, "Couldn't save your decision. Try again or choose Save Later.")
    }
}
