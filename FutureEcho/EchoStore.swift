import Foundation

@MainActor
final class EchoStore: ObservableObject {
    @Published private(set) var snapshot: AppSnapshot
    @Published var notice: String?
    @Published var errorMessage: String?

    let persistenceKind: String

    private let repository: SnapshotRepository

    init(repository: SnapshotRepository? = nil) {
        let launchArguments = ProcessInfo.processInfo.arguments
        if let repository {
            self.repository = repository
            persistenceKind = "injected"
        } else if #available(iOS 17.0, *),
                  !launchArguments.contains("-forceJSONStore"),
                  !launchArguments.contains("-simulatePersistenceFailure"),
                  let swiftDataRepository = try? SwiftDataSnapshotRepository() {
            self.repository = swiftDataRepository
            persistenceKind = "swiftdata"
        } else {
            let applicationSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
            let fileURL = applicationSupport
                .appendingPathComponent("FutureEcho", isDirectory: true)
                .appendingPathComponent("snapshot.json")
            let simulateWriteFailure = launchArguments.contains("-simulatePersistenceFailure")
            self.repository = JSONSnapshotRepository(
                fileURL: fileURL,
                simulateWriteFailure: simulateWriteFailure
            )
            persistenceKind = simulateWriteFailure ? "json-failure-injection" : "json-fallback"
        }

        if launchArguments.contains("-resetStore") {
            try? self.repository.reset()
        }

        do {
            snapshot = try self.repository.load()
        } catch {
            snapshot = AppSnapshot()
            errorMessage = "Your local echoes could not be loaded. You can keep using the app and try again."
        }
        logReadback(event: "launch")
    }

    var promises: [SavingsPromise] { snapshot.promises }
    var coolingCards: [CoolingCard] { snapshot.coolingCards.sorted { $0.revisitAt < $1.revisitAt } }
    var outcomes: [DecisionOutcome] {
        FreeTierPolicy.visibleOutcomes(from: snapshot.outcomes, isPlus: snapshot.plusEntitled)
    }

    func upsertPromise(_ promise: SavingsPromise) -> Bool {
        var updated = snapshot
        if let index = updated.promises.firstIndex(where: { $0.id == promise.id }) {
            updated.promises[index] = promise
        } else {
            guard FreeTierPolicy.canCreatePromise(
                currentCount: updated.promises.count,
                isPlus: updated.plusEntitled
            ) else {
                errorMessage = "The free plan keeps one promise at a time. Edit this promise or unlock more themes and promises with Future Echo Plus."
                return false
            }
            updated.promises.append(promise)
        }
        return persist(updated, notice: "Your promise is ready.")
    }

    func deletePromise(id: UUID) -> Bool {
        var updated = snapshot
        updated.promises.removeAll { $0.id == id }
        updated.coolingCards.removeAll { $0.promiseID == id }
        return persist(updated, notice: "The promise and its open cooling cards were deleted.")
    }

    func relatedCoolingCardCount(for promiseID: UUID) -> Int {
        snapshot.coolingCards.filter { $0.promiseID == promiseID }.count
    }

    func createCoolingCard(from draft: EchoDraft) -> Bool {
        let activeCount = snapshot.coolingCards.count
        guard FreeTierPolicy.canCreateCoolingCard(
            activeCount: activeCount,
            isPlus: snapshot.plusEntitled
        ) else {
            errorMessage = "The free plan can hold three active cooling cards. Finish or remove one before waiting on another."
            return false
        }

        let card = CoolingCard(
            amount: draft.amount,
            note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            promiseID: draft.promise.id,
            promiseSnapshot: draft.promise.snapshot,
            revisitAt: Date().addingTimeInterval(24 * 60 * 60)
        )
        var updated = snapshot
        updated.coolingCards.append(card)
        return persist(
            updated,
            notice: "We'll hold this echo until \(EchoFormatters.revisitTime(card.revisitAt))."
        )
    }

    func updateCoolingCard(_ card: CoolingCard) -> Bool {
        var updated = snapshot
        guard let index = updated.coolingCards.firstIndex(where: { $0.id == card.id }) else {
            errorMessage = "That cooling card is no longer available."
            return false
        }
        updated.coolingCards[index] = card
        return persist(updated, notice: "Cooling card updated.")
    }

    func deleteCoolingCard(id: UUID) -> Bool {
        var updated = snapshot
        updated.coolingCards.removeAll { $0.id == id }
        return persist(updated, notice: "Cooling card deleted.")
    }

    func decide(
        draft: EchoDraft,
        decision: PurchaseDecision,
        coolingCardID: UUID? = nil,
        reflection: String? = nil
    ) -> Bool {
        var updated = snapshot
        let outcome = DecisionOutcome(
            coolingCardID: coolingCardID,
            amount: draft.amount,
            promiseSnapshot: draft.promise.snapshot,
            decision: decision,
            reflection: reflection?.nilIfEmpty
        )
        updated.outcomes.append(outcome)
        if let coolingCardID {
            updated.coolingCards.removeAll { $0.id == coolingCardID }
        }
        let message = decision == .skipped
            ? "You chose to skip this purchase."
            : "You chose to keep this purchase."
        return persist(updated, notice: message)
    }

    func decide(card: CoolingCard, decision: PurchaseDecision, reflection: String?) -> Bool {
        guard let promise = snapshot.promises.first(where: { $0.id == card.promiseID }) else {
            let snapshotPromise = SavingsPromise(
                id: card.promiseID,
                title: card.promiseSnapshot.title,
                targetAmount: card.promiseSnapshot.targetAmount,
                currentSavedAmount: 0,
                plannedContribution: card.promiseSnapshot.plannedContribution,
                themeToken: card.promiseSnapshot.themeToken,
                createdAt: card.createdAt,
                updatedAt: card.updatedAt
            )
            return decide(
                draft: EchoDraft(amount: card.amount, note: card.note ?? "", promise: snapshotPromise),
                decision: decision,
                coolingCardID: card.id,
                reflection: reflection
            )
        }
        return decide(
            draft: EchoDraft(amount: card.amount, note: card.note ?? "", promise: promise),
            decision: decision,
            coolingCardID: card.id,
            reflection: reflection
        )
    }

    func updateOutcome(_ outcome: DecisionOutcome) -> Bool {
        var updated = snapshot
        guard let index = updated.outcomes.firstIndex(where: { $0.id == outcome.id }) else {
            errorMessage = "That trail entry is no longer available."
            return false
        }
        updated.outcomes[index] = outcome
        return persist(updated, notice: "Reflection updated.")
    }

    func deleteOutcome(id: UUID) -> Bool {
        var updated = snapshot
        updated.outcomes.removeAll { $0.id == id }
        return persist(updated, notice: "Trail entry deleted.")
    }

    func updatePreferences(_ preferences: PausePreference) -> Bool {
        var updated = snapshot
        updated.preferences = preferences
        return persist(updated, notice: nil)
    }

    func setPlusEntitled(_ entitled: Bool) -> Bool {
        var updated = snapshot
        updated.plusEntitled = entitled
        return persist(updated, notice: entitled ? "Future Echo Plus is active." : nil)
    }

    func clearAllData() -> Bool {
        do {
            try repository.reset()
            snapshot = AppSnapshot()
            notice = "All local Future Echo data was deleted."
            errorMessage = nil
            logReadback(event: "reset")
            return true
        } catch {
            errorMessage = "Couldn't delete your local data. Try again."
            return false
        }
    }

    private func persist(_ updated: AppSnapshot, notice: String?) -> Bool {
        do {
            try repository.save(updated)
            snapshot = updated
            self.notice = notice
            errorMessage = nil
            logReadback(event: "save")
            return true
        } catch {
            errorMessage = "Couldn't save your decision. Try again or choose Save Later."
            return false
        }
    }

    private func logReadback(event: String) {
        print(
            "APP_READBACK event=\(event) persistence=\(persistenceKind) " +
            "promises=\(snapshot.promises.count) cards=\(snapshot.coolingCards.count) " +
            "outcomes=\(snapshot.outcomes.count) plus=\(snapshot.plusEntitled)"
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
