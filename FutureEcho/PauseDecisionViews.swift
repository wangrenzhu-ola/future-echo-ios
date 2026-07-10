import SwiftUI

struct PauseAndDecisionView: View {
    let draft: EchoDraft
    @Binding var pauseCompleted: Bool
    let saveLater: () -> Void
    let finish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if pauseCompleted {
                    DecisionChoicesView(draft: draft, saveLater: saveLater, finish: finish)
                } else {
                    PauseChamberView(draft: draft, completed: $pauseCompleted)
                }
            }
            .padding(20)
        }
    }
}

private struct PauseChamberView: View {
    @EnvironmentObject private var store: EchoStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let draft: EchoDraft
    @Binding var completed: Bool

    @State private var remaining = 12
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var durationSeconds: Int {
        max(store.snapshot.preferences.durationSeconds, 1)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Let the first impulse settle.")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            EchoRing(
                progress: Double(durationSeconds - remaining) / Double(durationSeconds),
                accent: draft.promise.themeToken.color,
                isStatic: reduceMotion
            )
            .frame(maxWidth: 260)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: remaining)
            VStack(spacing: 7) {
                Text("\(remaining)")
                    .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                    .accessibilityLabel("\(remaining) seconds remaining")
                    .accessibilityIdentifier("pause.countdown")
                Text(reduceMotion ? "Static countdown for Reduce Motion" : "A visible pause, never an automatic decision")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.62))
            }
            PromiseLensPreview(
                cost: OpportunityCost(amount: draft.amount, promise: draft.promise),
                promise: draft.promise,
                amount: draft.amount
            )
            Button("Skip Pause", action: complete)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .accessibilityIdentifier("pause.skip")
        }
        .onAppear { remaining = durationSeconds }
        .onReceive(timer) { _ in tick() }
        .accessibilityElement(children: .contain)
    }

    private func tick() {
        guard !completed else { return }
        remaining -= 1
        if remaining == 6 {
            UIAccessibility.post(notification: .announcement, argument: "Halfway through the pause")
        }
        if remaining <= 0 { complete() }
    }

    private func complete() {
        completed = true
        UIAccessibility.post(notification: .announcement, argument: "Pause complete. Choose what happens next.")
    }
}

private struct DecisionChoicesView: View {
    @EnvironmentObject private var store: EchoStore
    @EnvironmentObject private var notificationService: NotificationService

    let draft: EchoDraft
    let saveLater: () -> Void
    let finish: () -> Void

    @State private var reflection = ""
    @State private var pendingDecision: PurchaseDecision?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("The pause is yours.")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                Text("Each choice is valid. Future Echo records what you choose without scoring it.")
                    .foregroundColor(.white.opacity(0.65))
            }
            DecisionButton(
                title: "Wait 24 Hours",
                detail: "Move this moment to the Cooling Shelf.",
                symbol: "hourglass",
                action: wait
            )
            DecisionButton(
                title: "Skip Purchase",
                detail: "Record the decision without claiming money was saved.",
                symbol: "arrow.uturn.backward.circle",
                action: { save(.skipped) }
            )
            DecisionButton(
                title: "Keep Purchase",
                detail: "Record a calm choice to continue.",
                symbol: "checkmark.circle",
                action: { save(.kept) }
            )
            EchoTextField(title: "Reflection (optional)", text: $reflection, keyboardType: .default)
            if store.errorMessage != nil {
                HStack(spacing: 16) {
                    Button("Retry") {
                        if let pendingDecision { save(pendingDecision) }
                    }
                    .accessibilityIdentifier("decision.retry")
                    Button("Save Later", action: saveLater)
                        .accessibilityIdentifier("decision.saveLater")
                }
                .font(.headline)
                .foregroundColor(EchoPalette.mist)
            }
        }
    }

    private func wait() {
        if store.createCoolingCard(from: draft) {
            if store.snapshot.preferences.notificationOptIn,
               let card = store.coolingCards.last {
                Task { await notificationService.scheduleRevisit(for: card) }
            }
            finish()
        }
    }

    private func save(_ decision: PurchaseDecision) {
        pendingDecision = decision
        if store.decide(draft: draft, decision: decision, reflection: reflection) {
            finish()
        }
    }
}

struct DecisionButton: View {
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.title2)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.footnote).foregroundColor(.white.opacity(0.62))
                }
                Spacer()
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.075))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("decision.\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}
