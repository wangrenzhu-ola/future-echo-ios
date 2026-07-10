import XCTest
@testable import FutureEchoCore

final class OpportunityCostTests: XCTestCase {
    func testOpportunityCostUsesDecimalSemantics() {
        let promise = SavingsPromise(
            title: "Emergency Cushion",
            targetAmount: Decimal(2000),
            currentSavedAmount: Decimal(640),
            plannedContribution: Decimal(32),
            themeToken: .coral
        )

        let result = OpportunityCost(amount: Decimal(128), promise: promise)

        XCTAssertEqual(result.percentageOfGoal, Decimal(string: "6.400")!)
        XCTAssertEqual(result.plannedDeposits, Decimal(4))
        XCTAssertEqual(EchoFormatters.percentage(result.percentageOfGoal), "6.4%")
        XCTAssertEqual(EchoFormatters.count(result.plannedDeposits!), "4")
    }

    func testAmountValidationRejectsZeroNegativeAndText() {
        XCTAssertFalse(MoneyInput.isValidPositiveAmount(MoneyInput.decimal(from: "0")))
        XCTAssertFalse(MoneyInput.isValidPositiveAmount(MoneyInput.decimal(from: "-10")))
        XCTAssertFalse(MoneyInput.isValidPositiveAmount(MoneyInput.decimal(from: "shoes")))
        XCTAssertTrue(MoneyInput.isValidPositiveAmount(MoneyInput.decimal(from: "$128.00")))
    }

    func testSnapshotDoesNotChangeWhenPromiseChanges() {
        var promise = SavingsPromise(
            title: "Emergency Cushion",
            targetAmount: Decimal(2000),
            currentSavedAmount: Decimal(640),
            plannedContribution: Decimal(32),
            themeToken: .coral
        )
        let snapshot = promise.snapshot
        promise.title = "Travel"
        promise.targetAmount = Decimal(5000)

        XCTAssertEqual(snapshot.title, "Emergency Cushion")
        XCTAssertEqual(snapshot.targetAmount, Decimal(2000))
    }
}

