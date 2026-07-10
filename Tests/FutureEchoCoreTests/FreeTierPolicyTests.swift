import XCTest
@testable import FutureEchoCore

final class FreeTierPolicyTests: XCTestCase {
    func testFreeTierKeepsTheCoreLoopAvailable() {
        XCTAssertTrue(FreeTierPolicy.canCreatePromise(currentCount: 0, isPlus: false))
        XCTAssertTrue(FreeTierPolicy.canCreateCoolingCard(activeCount: 2, isPlus: false))
        XCTAssertFalse(FreeTierPolicy.canCreateCoolingCard(activeCount: 3, isPlus: false))
        XCTAssertTrue(FreeTierPolicy.canCreateCoolingCard(activeCount: 3, isPlus: true))
    }

    func testFreeTrailShowsTenMostRecentOutcomes() {
        let promise = SavingsPromise(
            title: "Learning Fund",
            targetAmount: Decimal(1200),
            currentSavedAmount: Decimal(200),
            plannedContribution: Decimal(40),
            themeToken: .dusk
        )
        let outcomes = (0..<12).map { index in
            DecisionOutcome(
                coolingCardID: nil,
                amount: Decimal(index + 1),
                promiseSnapshot: promise.snapshot,
                decision: .kept,
                decidedAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        let visible = FreeTierPolicy.visibleOutcomes(from: outcomes, isPlus: false)
        XCTAssertEqual(visible.count, 10)
        XCTAssertEqual(visible.first?.amount, Decimal(12))
        XCTAssertEqual(visible.last?.amount, Decimal(3))
    }
}
