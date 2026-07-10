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

    @MainActor
    func testPremiumStoreHandlesSuccessPendingCancelFailureRestoreAndUnavailableStates() async {
        let successfulPurchase = PremiumStore(
            client: StubPremiumClient(price: "$4.99", purchaseEvent: .purchased, restoreResult: true)
        )
        await successfulPurchase.load()
        XCTAssertEqual(successfulPurchase.state, .ready(price: "$4.99"))
        let purchaseSucceeded = await successfulPurchase.purchase()
        XCTAssertTrue(purchaseSucceeded)
        XCTAssertEqual(successfulPurchase.state, .purchased)
        let restoreSucceeded = await successfulPurchase.restore()
        XCTAssertTrue(restoreSucceeded)

        let pendingPurchase = PremiumStore(
            client: StubPremiumClient(price: "$4.99", purchaseEvent: .pending, restoreResult: false)
        )
        await pendingPurchase.load()
        let pendingPurchaseSucceeded = await pendingPurchase.purchase()
        XCTAssertFalse(pendingPurchaseSucceeded)
        XCTAssertEqual(pendingPurchase.state, .pending)

        let cancelledPurchase = PremiumStore(
            client: StubPremiumClient(price: "$4.99", purchaseEvent: .cancelled, restoreResult: false)
        )
        await cancelledPurchase.load()
        let cancelledPurchaseSucceeded = await cancelledPurchase.purchase()
        XCTAssertFalse(cancelledPurchaseSucceeded)
        XCTAssertEqual(cancelledPurchase.state, .cancelled)
        let cancelledRestoreSucceeded = await cancelledPurchase.restore()
        XCTAssertFalse(cancelledRestoreSucceeded)
        XCTAssertEqual(cancelledPurchase.state, .failed("No previous Future Echo Plus purchase was found."))

        let failedPurchase = PremiumStore(
            client: StubPremiumClient(price: "$4.99", purchaseEvent: nil, restoreResult: false, purchaseFails: true)
        )
        await failedPurchase.load()
        let failedPurchaseSucceeded = await failedPurchase.purchase()
        XCTAssertFalse(failedPurchaseSucceeded)
        XCTAssertEqual(failedPurchase.state, .failed("Purchase couldn't be completed. Try again."))

        let unavailablePurchase = PremiumStore(
            client: StubPremiumClient(price: nil, purchaseEvent: nil, restoreResult: false)
        )
        await unavailablePurchase.load()
        XCTAssertEqual(unavailablePurchase.state, .unavailable)
    }
}

private final class StubPremiumClient: PremiumPurchasing {
    private enum StubError: Error {
        case purchaseFailure
    }

    private let price: String?
    private let purchaseEvent: PremiumPurchaseEvent?
    private let restoreResult: Bool
    private let purchaseFails: Bool

    init(
        price: String?,
        purchaseEvent: PremiumPurchaseEvent?,
        restoreResult: Bool,
        purchaseFails: Bool = false
    ) {
        self.price = price
        self.purchaseEvent = purchaseEvent
        self.restoreResult = restoreResult
        self.purchaseFails = purchaseFails
    }

    func load() async throws -> String? {
        price
    }

    func purchase() async throws -> PremiumPurchaseEvent {
        if purchaseFails { throw StubError.purchaseFailure }
        guard let purchaseEvent else { throw StubError.purchaseFailure }
        return purchaseEvent
    }

    func restore() async throws -> Bool {
        restoreResult
    }
}
