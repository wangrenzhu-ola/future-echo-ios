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

struct PromiseLensPreview: View {
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
