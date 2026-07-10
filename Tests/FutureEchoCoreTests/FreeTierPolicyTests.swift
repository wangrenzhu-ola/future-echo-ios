import XCTest
@testable import FutureEchoCore

final class FreeTierPolicyTests: XCTestCase {
    func testFreeTierKeepsTheCoreLoopAvailable() {
        for isPlus in [false, true] {
            XCTAssertTrue(FreeTierPolicy.canCreatePromise(currentCount: 0, isPlus: isPlus))
            XCTAssertTrue(FreeTierPolicy.canCreatePromise(currentCount: 100, isPlus: isPlus))
            XCTAssertTrue(FreeTierPolicy.canCreateCoolingCard(activeCount: 3, isPlus: isPlus))
            XCTAssertTrue(FreeTierPolicy.canCreateCoolingCard(activeCount: 100, isPlus: isPlus))
        }
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
        XCTAssertEqual(FreeTierPolicy.visibleOutcomes(from: outcomes, isPlus: true).count, 12)
    }
}
