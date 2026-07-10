import XCTest
import StoreKit
import StoreKitTest
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
            client: StubPremiumClient(product: product, purchaseEvent: .purchased, restoreResult: true)
        )
        await successfulPurchase.load()
        XCTAssertEqual(successfulPurchase.state, .ready)
        XCTAssertEqual(successfulPurchase.product, product)
        let purchaseSucceeded = await successfulPurchase.purchase()
        XCTAssertTrue(purchaseSucceeded)
        XCTAssertEqual(successfulPurchase.state, .purchased)
        XCTAssertTrue(successfulPurchase.isEntitled)
        let restoreSucceeded = await successfulPurchase.restore()
        XCTAssertTrue(restoreSucceeded)

        let pendingPurchase = PremiumStore(
            client: StubPremiumClient(product: product, purchaseEvent: .pending, restoreResult: false)
        )
        await pendingPurchase.load()
        let pendingPurchaseSucceeded = await pendingPurchase.purchase()
        XCTAssertFalse(pendingPurchaseSucceeded)
        XCTAssertEqual(pendingPurchase.state, .pending)

        let cancelledPurchase = PremiumStore(
            client: StubPremiumClient(product: product, purchaseEvent: .cancelled, restoreResult: false)
        )
        await cancelledPurchase.load()
        let cancelledPurchaseSucceeded = await cancelledPurchase.purchase()
        XCTAssertFalse(cancelledPurchaseSucceeded)
        XCTAssertEqual(cancelledPurchase.state, .cancelled)
        let cancelledRestoreSucceeded = await cancelledPurchase.restore()
        XCTAssertFalse(cancelledRestoreSucceeded)
        XCTAssertEqual(cancelledPurchase.state, .failed("No previous Future Echo Plus purchase was found."))

        let failedPurchase = PremiumStore(
            client: StubPremiumClient(product: product, purchaseEvent: nil, restoreResult: false, purchaseFails: true)
        )
        await failedPurchase.load()
        let failedPurchaseSucceeded = await failedPurchase.purchase()
        XCTAssertFalse(failedPurchaseSucceeded)
        XCTAssertEqual(failedPurchase.state, .failed("Purchase couldn't be completed. Try again."))

        let unavailablePurchase = PremiumStore(
            client: StubPremiumClient(product: nil, purchaseEvent: nil, restoreResult: false)
        )
        await unavailablePurchase.load()
        XCTAssertEqual(unavailablePurchase.state, .unavailable)

        let unverifiedPurchase = PremiumStore(
            client: StubPremiumClient(product: product, purchaseEvent: .unverified, restoreResult: false)
        )
        await unverifiedPurchase.load()
        let unverifiedPurchaseSucceeded = await unverifiedPurchase.purchase()
        XCTAssertFalse(unverifiedPurchaseSucceeded)
        XCTAssertFalse(unverifiedPurchase.isEntitled)
        XCTAssertEqual(unverifiedPurchase.state, .failed("The purchase couldn't be verified. Nothing changed."))
    }

    @MainActor
    func testVerifiedEntitlementPersistsAcrossLaunchAndRevocationClearsIt() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("snapshot.json")

        let purchasedStore = PremiumStore(
            client: StubPremiumClient(product: product, purchaseEvent: nil, restoreResult: false, isEntitled: true)
        )
        await purchasedStore.load()
        XCTAssertTrue(purchasedStore.isEntitled)

        let firstLaunch = EchoStore(repository: JSONSnapshotRepository(fileURL: fileURL))
        XCTAssertTrue(firstLaunch.setPlusEntitled(purchasedStore.isEntitled))
        let relaunchedStore = EchoStore(repository: JSONSnapshotRepository(fileURL: fileURL))
        XCTAssertTrue(relaunchedStore.snapshot.plusEntitled)

        let revokedStore = PremiumStore(
            client: StubPremiumClient(product: product, purchaseEvent: nil, restoreResult: false, isEntitled: false)
        )
        await revokedStore.load()
        XCTAssertFalse(revokedStore.isEntitled)
        XCTAssertTrue(relaunchedStore.setPlusEntitled(revokedStore.isEntitled))
        let storeAfterRevocation = EchoStore(repository: JSONSnapshotRepository(fileURL: fileURL))
        XCTAssertFalse(storeAfterRevocation.snapshot.plusEntitled)
    }

    @available(iOS 17.0, *)
    @MainActor
    func testStoreKitConfigurationReadsVerifiedPurchaseRestoreRevocationAndUnavailableProduct() async throws {
        let session = try makeStoreKitTestSession()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }

        let products = try await Product.products(for: [PremiumStore.productID])
        let product = try XCTUnwrap(products.first)
        let productID = PremiumStore.productID
        XCTAssertEqual(product.id, productID)
        XCTAssertEqual(product.displayName, "Future Echo Plus")
        XCTAssertFalse(product.description.isEmpty)
        XCTAssertFalse(product.displayPrice.isEmpty)
        XCTAssertEqual(product.type, .nonConsumable)
        let unavailableProducts = try await Product.products(for: ["com.wangrenzhu.futureecho.missing"])
        XCTAssertTrue(unavailableProducts.isEmpty)

        let transaction = try await session.buyProduct(identifier: productID)
        let purchasedEntitlement = await hasVerifiedEntitlement(for: productID)
        XCTAssertTrue(purchasedEntitlement)
        try await AppStore.sync()
        let restoredEntitlement = await hasVerifiedEntitlement(for: productID)
        XCTAssertTrue(restoredEntitlement)

        try session.refundTransaction(identifier: UInt(transaction.id))
        let revokedEntitlement = await hasVerifiedEntitlement(for: productID)
        XCTAssertFalse(revokedEntitlement)
        print("STOREKIT_TEST_READBACK state=verified_purchase_restore_revocation product_id=\(product.id) transaction_id=\(transaction.id)")
    }

    @available(iOS 17.0, *)
    @MainActor
    func testStoreKitConfigurationReadsAskToBuyAndInterruptedTransactions() async throws {
        let session = try makeStoreKitTestSession()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }

        session.askToBuyEnabled = true
        let productID = PremiumStore.productID
        let products = try await Product.products(for: [productID])
        let product = try XCTUnwrap(products.first)
        let askToBuyResult = try await product.purchase()
        guard case .pending = askToBuyResult else {
            return XCTFail("Ask to Buy should remain pending until it is approved or declined.")
        }
        let pending = try XCTUnwrap(session.allTransactions().first)
        XCTAssertTrue(pending.pendingAskToBuyConfirmation)
        try session.declineAskToBuyTransaction(identifier: pending.identifier)
        let declinedEntitlement = await hasVerifiedEntitlement(for: productID)
        XCTAssertFalse(declinedEntitlement)

        session.askToBuyEnabled = false
        session.interruptedPurchasesEnabled = true
        _ = try await session.buyProduct(identifier: productID)
        let interrupted = try XCTUnwrap(session.allTransactions().first)
        XCTAssertTrue(interrupted.hasPurchaseIssue)
        print("STOREKIT_TEST_READBACK state=ask_to_buy_declined_and_interrupted product_id=\(productID)")
    }

    @available(iOS 17.0, *)
    private func hasVerifiedEntitlement(for productID: String) async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    private func makeStoreKitTestSession() throws -> SKTestSession {
        try SKTestSession(configurationFileNamed: "FutureEcho")
    }
}

private final class StubPremiumClient: PremiumPurchasing {
    private enum StubError: Error {
        case purchaseFailure
    }

    private let product: PremiumProduct?
    private let purchaseEvent: PremiumPurchaseEvent?
    private let restoreResult: Bool
    private let purchaseFails: Bool
    private let isEntitled: Bool

    init(
        product: PremiumProduct?,
        purchaseEvent: PremiumPurchaseEvent?,
        restoreResult: Bool,
        purchaseFails: Bool = false,
        isEntitled: Bool = false
    ) {
        self.product = product
        self.purchaseEvent = purchaseEvent
        self.restoreResult = restoreResult
        self.purchaseFails = purchaseFails
        self.isEntitled = isEntitled
    }

    func load() async throws -> PremiumLoadResult {
        PremiumLoadResult(product: product, isEntitled: isEntitled)
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

private let product = PremiumProduct(
    displayName: "Future Echo Plus",
    productDescription: "Unlock calm themes and unlimited visible Echo Trail history.",
    displayPrice: "$4.99"
)
