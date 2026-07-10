import XCTest
@testable import FutureEchoCore

final class PersistenceTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var repository: JSONSnapshotRepository!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        repository = JSONSnapshotRepository(
            fileURL: temporaryDirectory.appendingPathComponent("snapshot.json")
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testAllProductObjectsRoundTripAndConfirmedDeletionStaysDeleted() throws {
        let promise = SavingsPromise(
            title: "Emergency Cushion",
            targetAmount: Decimal(2000),
            currentSavedAmount: Decimal(640),
            plannedContribution: Decimal(32),
            themeToken: .coral
        )
        let card = CoolingCard(
            amount: Decimal(128),
            note: "Shoes after a long week",
            promiseID: promise.id,
            promiseSnapshot: promise.snapshot,
            revisitAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let outcome = DecisionOutcome(
            coolingCardID: card.id,
            amount: card.amount,
            promiseSnapshot: card.promiseSnapshot,
            decision: .skipped,
            reflection: "I still chose this calmly."
        )
        let snapshot = AppSnapshot(
            promises: [promise],
            coolingCards: [card],
            outcomes: [outcome],
            preferences: PausePreference(durationSeconds: 12, reduceMotionBehavior: true, notificationOptIn: false)
        )

        try repository.save(snapshot)
        XCTAssertEqual(try repository.load(), snapshot)

        try repository.save(AppSnapshot())
        XCTAssertEqual(try repository.load(), AppSnapshot())
    }

    func testSimulatedFailureDoesNotOverwriteExistingSnapshot() throws {
        let fileURL = temporaryDirectory.appendingPathComponent("failure.json")
        let healthyRepository = JSONSnapshotRepository(fileURL: fileURL)
        let promise = SavingsPromise(
            title: "Travel Promise",
            targetAmount: Decimal(1000),
            currentSavedAmount: Decimal(100),
            plannedContribution: Decimal(50),
            themeToken: .mist
        )
        try healthyRepository.save(AppSnapshot(promises: [promise]))

        let failingRepository = JSONSnapshotRepository(fileURL: fileURL, simulateWriteFailure: true)
        XCTAssertThrowsError(try failingRepository.save(AppSnapshot()))
        XCTAssertEqual(try healthyRepository.load().promises, [promise])
    }
}

