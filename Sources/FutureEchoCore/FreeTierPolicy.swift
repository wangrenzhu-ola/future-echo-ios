import Foundation

public enum FreeTierPolicy {
    public static let promiseLimit = 1
    public static let activeCoolingCardLimit = 3
    public static let visibleOutcomeLimit = 10

    public static func canCreatePromise(currentCount: Int, isPlus: Bool) -> Bool {
        isPlus || currentCount < promiseLimit
    }

    public static func canCreateCoolingCard(activeCount: Int, isPlus: Bool) -> Bool {
        isPlus || activeCount < activeCoolingCardLimit
    }

    public static func visibleOutcomes(
        from outcomes: [DecisionOutcome],
        isPlus: Bool
    ) -> [DecisionOutcome] {
        let sorted = outcomes.sorted { $0.decidedAt > $1.decidedAt }
        return isPlus ? sorted : Array(sorted.prefix(visibleOutcomeLimit))
    }
}

