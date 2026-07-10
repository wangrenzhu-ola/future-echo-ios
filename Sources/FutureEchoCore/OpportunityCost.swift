import Foundation

public struct OpportunityCost: Equatable {
    public let percentageOfGoal: Decimal
    public let plannedDeposits: Decimal?

    public init(amount: Decimal, promise: SavingsPromise) {
        if promise.targetAmount > 0 {
            percentageOfGoal = amount / promise.targetAmount * 100
        } else {
            percentageOfGoal = 0
        }

        if let contribution = promise.plannedContribution, contribution > 0 {
            plannedDeposits = amount / contribution
        } else {
            plannedDeposits = nil
        }
    }
}

public enum MoneyInput {
    public static func decimal(from text: String, locale: Locale = Locale(identifier: "en_US")) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: locale.currencySymbol ?? "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    public static func isValidPositiveAmount(_ amount: Decimal?) -> Bool {
        guard let amount = amount else { return false }
        return amount > 0
    }
}

public enum EchoFormatters {
    public static func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    public static func percentage(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return (formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0") + "%"
    }

    public static func count(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
}

