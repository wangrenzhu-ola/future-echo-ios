import Foundation

public enum PromiseTheme: String, Codable, CaseIterable, Identifiable {
    case coral
    case mist
    case sand
    case dusk

    public var id: String { rawValue }
}

public struct SavingsPromise: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var targetAmount: Decimal
    public var currentSavedAmount: Decimal
    public var plannedContribution: Decimal?
    public var themeToken: PromiseTheme
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Decimal,
        currentSavedAmount: Decimal,
        plannedContribution: Decimal?,
        themeToken: PromiseTheme,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.currentSavedAmount = currentSavedAmount
        self.plannedContribution = plannedContribution
        self.themeToken = themeToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var snapshot: PromiseSnapshot {
        PromiseSnapshot(
            title: title,
            targetAmount: targetAmount,
            plannedContribution: plannedContribution,
            themeToken: themeToken
        )
    }
}

public struct PromiseSnapshot: Codable, Equatable {
    public var title: String
    public var targetAmount: Decimal
    public var plannedContribution: Decimal?
    public var themeToken: PromiseTheme

    public init(
        title: String,
        targetAmount: Decimal,
        plannedContribution: Decimal?,
        themeToken: PromiseTheme
    ) {
        self.title = title
        self.targetAmount = targetAmount
        self.plannedContribution = plannedContribution
        self.themeToken = themeToken
    }
}

public enum CoolingStatus: String, Codable {
    case cooling
    case ready
}

public struct CoolingCard: Identifiable, Codable, Equatable {
    public var id: UUID
    public var amount: Decimal
    public var note: String?
    public var promiseID: UUID
    public var promiseSnapshot: PromiseSnapshot
    public var createdAt: Date
    public var revisitAt: Date
    public var status: CoolingStatus
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        note: String?,
        promiseID: UUID,
        promiseSnapshot: PromiseSnapshot,
        createdAt: Date = Date(),
        revisitAt: Date,
        status: CoolingStatus = .cooling,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.note = note
        self.promiseID = promiseID
        self.promiseSnapshot = promiseSnapshot
        self.createdAt = createdAt
        self.revisitAt = revisitAt
        self.status = status
        self.updatedAt = updatedAt
    }
}

public enum PurchaseDecision: String, Codable, CaseIterable {
    case skipped
    case kept
}

public struct DecisionOutcome: Identifiable, Codable, Equatable {
    public var id: UUID
    public var coolingCardID: UUID?
    public var amount: Decimal
    public var promiseSnapshot: PromiseSnapshot
    public var decision: PurchaseDecision
    public var reflection: String?
    public var decidedAt: Date

    public init(
        id: UUID = UUID(),
        coolingCardID: UUID?,
        amount: Decimal,
        promiseSnapshot: PromiseSnapshot,
        decision: PurchaseDecision,
        reflection: String? = nil,
        decidedAt: Date = Date()
    ) {
        self.id = id
        self.coolingCardID = coolingCardID
        self.amount = amount
        self.promiseSnapshot = promiseSnapshot
        self.decision = decision
        self.reflection = reflection
        self.decidedAt = decidedAt
    }
}

public struct PausePreference: Codable, Equatable {
    public var durationSeconds: Int
    public var reduceMotionBehavior: Bool
    public var notificationOptIn: Bool

    public init(durationSeconds: Int = 12, reduceMotionBehavior: Bool = true, notificationOptIn: Bool = false) {
        self.durationSeconds = durationSeconds
        self.reduceMotionBehavior = reduceMotionBehavior
        self.notificationOptIn = notificationOptIn
    }
}

public struct AppSnapshot: Codable, Equatable {
    public var promises: [SavingsPromise]
    public var coolingCards: [CoolingCard]
    public var outcomes: [DecisionOutcome]
    public var preferences: PausePreference
    public var plusEntitled: Bool

    public init(
        promises: [SavingsPromise] = [],
        coolingCards: [CoolingCard] = [],
        outcomes: [DecisionOutcome] = [],
        preferences: PausePreference = PausePreference(),
        plusEntitled: Bool = false
    ) {
        self.promises = promises
        self.coolingCards = coolingCards
        self.outcomes = outcomes
        self.preferences = preferences
        self.plusEntitled = plusEntitled
    }
}

public struct EchoDraft: Equatable {
    public var amount: Decimal
    public var note: String
    public var promise: SavingsPromise

    public init(amount: Decimal, note: String, promise: SavingsPromise) {
        self.amount = amount
        self.note = note
        self.promise = promise
    }
}

