import Foundation

public enum FreeTierPolicy {
    public static let visibleOutcomeLimit = 10

    public static func canCreatePromise(currentCount: Int, isPlus: Bool) -> Bool {
        true
    }

    public static func canCreateCoolingCard(activeCount: Int, isPlus: Bool) -> Bool {
        true
    }

    public static func visibleOutcomes(
        from outcomes: [DecisionOutcome],
        isPlus: Bool
    ) -> [DecisionOutcome] {
        let sorted = outcomes.sorted { $0.decidedAt > $1.decidedAt }
        return isPlus ? sorted : Array(sorted.prefix(visibleOutcomeLimit))
    }
}
