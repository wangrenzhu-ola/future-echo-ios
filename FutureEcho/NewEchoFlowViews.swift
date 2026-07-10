import SwiftUI

struct NewEchoFlowView: View {
    @EnvironmentObject private var store: EchoStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var amountText = ""
    @State private var note = ""
    @State private var selectedPromiseID: UUID?
    @State private var draft: EchoDraft?
    @State private var pauseCompleted = false
    @State private var validationMessage: String?

    var body: some View {
        ZStack {
            EchoBackground()
            if let draft {
                PauseAndDecisionView(
                    draft: draft,
                    pauseCompleted: $pauseCompleted,
                    saveLater: saveLater,
                    finish: finish
                )
            } else {
                NewEchoEntryView(
                    amountText: $amountText,
                    note: $note,
                    selectedPromiseID: $selectedPromiseID,
                    validationMessage: validationMessage,
                    enterPause: enterPause
                )
            }
        }
        .navigationTitle(draft == nil ? "New Echo" : "Pause Chamber")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
            trailing: Button("Done") { dismissKeyboard() }
        )
        .onAppear {
            if selectedPromiseID == nil {
                selectedPromiseID = store.promises.first?.id
            }
        }
    }

    private func enterPause() {
        dismissKeyboard()
        guard let promiseID = selectedPromiseID,
              let promise = store.promises.first(where: { $0.id == promiseID }) else {
            validationMessage = "Create a promise first so the purchase has a scale."
            return
        }
        guard let amount = MoneyInput.decimal(from: amountText), amount > 0 else {
            validationMessage = "Enter a purchase amount greater than zero."
            return
        }
        validationMessage = nil
        draft = EchoDraft(amount: amount, note: note, promise: promise)
        pauseCompleted = false
    }

    private func saveLater() {
        pauseCompleted = false
        draft = nil
        validationMessage = "Your amount and note are still here. Try the pause again when you're ready."
    }

    private func finish() {
        presentationMode.wrappedValue.dismiss()
    }
}

private struct NewEchoEntryView: View {
    @EnvironmentObject private var store: EchoStore

    @Binding var amountText: String
    @Binding var note: String
    @Binding var selectedPromiseID: UUID?
    let validationMessage: String?
    let enterPause: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name the moment, not the purchase.")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    Text("Everything stays on this device. No bank connection, score, or advice.")
                        .foregroundColor(.white.opacity(0.65))
                }
                if store.promises.isEmpty {
                    NoPromiseView()
                } else {
                    AmountEntry(amountText: $amountText)
                    PromiseSelector(selectedPromiseID: $selectedPromiseID)
                    EchoTextField(title: "Checkout note (optional)", text: $note, keyboardType: .default)
                    if let preview {
                        PromiseLensPreview(cost: preview.cost, promise: preview.promise, amount: preview.amount)
                    }
                    if let validationMessage {
                        InlineNoticeView(message: validationMessage, isError: true)
                    }
                    Button("Enter Pause", action: enterPause)
                        .buttonStyle(PrimaryEchoButtonStyle(color: selectedPromise?.themeToken.color ?? EchoPalette.coral))
                        .accessibilityIdentifier("echo.enterPause")
                }
            }
            .padding(20)
        }
    }

    private var selectedPromise: SavingsPromise? {
        store.promises.first { $0.id == selectedPromiseID }
    }

    private var preview: (cost: OpportunityCost, promise: SavingsPromise, amount: Decimal)? {
        guard let promise = selectedPromise,
              let amount = MoneyInput.decimal(from: amountText),
              amount > 0 else { return nil }
        return (OpportunityCost(amount: amount, promise: promise), promise, amount)
    }
}

private struct NoPromiseView: View {
    var body: some View {
        VStack(spacing: 14) {
            EmptyEchoIllustration(accent: EchoPalette.coral)
            Text("Create a Promise First")
                .font(.title3.weight(.semibold))
            Text("Close this sheet and create your first promise from the Horizon.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
    }
}

private struct AmountEntry: View {
    @Binding var amountText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("PURCHASE AMOUNT")
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundColor(EchoPalette.mist)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$")
                    .font(.system(.largeTitle, design: .rounded).weight(.light))
                    .foregroundColor(.white.opacity(0.48))
                TextField("128", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 52, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                    .accessibilityLabel("Purchase amount")
                    .accessibilityIdentifier("echo.amount")
            }
            Rectangle()
                .fill(EchoPalette.mist.opacity(0.42))
                .frame(height: 1)
        }
    }
}

private struct PromiseSelector: View {
    @EnvironmentObject private var store: EchoStore
    @Binding var selectedPromiseID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Compare with")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.62))
            Picker("Compare with", selection: $selectedPromiseID) {
                ForEach(store.promises) { promise in
                    Text(promise.title).tag(Optional(promise.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .accessibilityIdentifier("echo.promisePicker")
        }
    }
}

private struct PromiseLensPreview: View {
    let cost: OpportunityCost
    let promise: SavingsPromise
    let amount: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROMISE LENS")
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundColor(promise.themeToken.color)
            Text("\(EchoFormatters.currency(amount)) is \(EchoFormatters.percentage(cost.percentageOfGoal)) of \(promise.title).")
                .font(.headline)
                .foregroundColor(.white)
            if let deposits = cost.plannedDeposits, let planned = promise.plannedContribution {
                Text("That equals \(EchoFormatters.count(deposits)) planned \(EchoFormatters.currency(planned)) deposits.")
                    .foregroundColor(.white.opacity(0.66))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(promise.themeToken.color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(promise.themeToken.color.opacity(0.35), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("echo.promiseLens")
    }
}

private struct PauseAndDecisionView: View {
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
        .onAppear {
            remaining = durationSeconds
        }
        .onReceive(timer) { _ in tick() }
        .accessibilityElement(children: .contain)
    }

    private func tick() {
        guard !completed else { return }
        remaining -= 1
        if remaining == 6 {
            UIAccessibility.post(notification: .announcement, argument: "Halfway through the pause")
        }
        if remaining <= 0 {
            complete()
        }
    }

    private var durationSeconds: Int {
        max(store.snapshot.preferences.durationSeconds, 1)
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
        .accessibilityIdentifier("decision.sheet")
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
