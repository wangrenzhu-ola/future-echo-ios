import SwiftUI

struct CoolingShelfView: View {
    @EnvironmentObject private var store: EchoStore
    @Binding var sheet: EchoSheet?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(
                        eyebrow: "COOLING SHELF",
                        title: "Decisions still in motion",
                        detail: "Open a card whenever you want. Notifications are optional."
                    )
                    if store.coolingCards.isEmpty {
                        CoolingEmptyView(action: emptyAction)
                    } else {
                        ForEach(store.coolingCards) { card in
                            CoolingCardRow(card: card) {
                                sheet = .coolingCard(card.id)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(EchoBackground())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func emptyAction() {
        sheet = store.promises.isEmpty ? .promiseEditor(nil) : .newEcho
    }
}

private struct CoolingEmptyView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            EmptyEchoIllustration(accent: EchoPalette.sand)
            Text("Your next pause will rest here.")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
            Text("Choose Wait 24 Hours after a pause to create a cooling card.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.62))
            Button("Start an Echo", action: action)
                .buttonStyle(PrimaryEchoButtonStyle(color: EchoPalette.sand))
                .accessibilityIdentifier("shelf.emptyAction")
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .accessibilityIdentifier("shelf.empty")
    }
}

private struct CoolingCardRow: View {
    let card: CoolingCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(card.promiseSnapshot.themeToken.color.opacity(0.14))
                    Image(systemName: isReady ? "bell.badge" : "hourglass")
                        .foregroundColor(card.promiseSnapshot.themeToken.color)
                }
                .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(EchoFormatters.currency(card.amount))
                            .font(.title3.monospacedDigit().weight(.semibold))
                        Text(isReady ? "READY" : "COOLING")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    Text(card.note ?? card.promiseSnapshot.title)
                        .lineLimit(1)
                    Text(isReady ? "Ready to revisit" : "Until \(EchoFormatters.revisitTime(card.revisitAt))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.58))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.38))
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(isReady ? 0.1 : 0.065))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(card.promiseSnapshot.themeToken.color.opacity(isReady ? 0.55 : 0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            "\(EchoFormatters.currency(card.amount)), \(card.note ?? card.promiseSnapshot.title), " +
            (isReady ? "ready to revisit" : "cooling until \(EchoFormatters.revisitTime(card.revisitAt))")
        )
        .accessibilityIdentifier("shelf.card")
    }

    private var isReady: Bool { card.revisitAt <= Date() }
}

struct CoolingCardDetailView: View {
    @EnvironmentObject private var store: EchoStore
    @Environment(\.presentationMode) private var presentationMode

    let cardID: UUID

    @State private var amountText = ""
    @State private var note = ""
    @State private var reflection = ""
    @State private var showDeleteConfirmation = false
    @State private var validationMessage: String?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let card {
                    CoolingDetailHeader(card: card)
                    EchoTextField(title: "Purchase amount", text: $amountText, keyboardType: .decimalPad)
                    EchoTextField(title: "Checkout note (optional)", text: $note, keyboardType: .default)
                    if let validationMessage {
                        InlineNoticeView(message: validationMessage, isError: true)
                    }
                    Button("Save Changes", action: saveChanges)
                        .buttonStyle(PrimaryEchoButtonStyle(color: card.promiseSnapshot.themeToken.color))
                        .accessibilityIdentifier("cooling.save")
                    Divider().background(Color.white.opacity(0.2))
                    Text("Finish this echo")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    EchoTextField(title: "Reflection (optional)", text: $reflection, keyboardType: .default)
                    DecisionButton(
                        title: "Skip Purchase",
                        detail: "Record the choice without changing any savings balance.",
                        symbol: "arrow.uturn.backward.circle",
                        action: { finish(.skipped) }
                    )
                    DecisionButton(
                        title: "Keep Purchase",
                        detail: "Record a neutral choice to continue.",
                        symbol: "checkmark.circle",
                        action: { finish(.kept) }
                    )
                    Button("Delete Cooling Card", action: { showDeleteConfirmation = true })
                        .frame(maxWidth: .infinity)
                        .foregroundColor(EchoPalette.coral)
                        .padding(.top, 4)
                        .accessibilityIdentifier("cooling.delete")
                } else {
                    InlineNoticeView(message: "This cooling card is no longer available.", isError: true)
                }
            }
            .padding(20)
        }
        .background(EchoBackground())
        .navigationTitle("Cooling Card")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
            trailing: Button("Done") { dismissKeyboard() }
        )
        .onAppear(perform: loadCard)
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete this cooling card?"),
                message: Text("This removes the open decision from your device. It won't create a Trail entry."),
                primaryButton: .destructive(Text("Delete"), action: deleteCard),
                secondaryButton: .cancel()
            )
        }
    }

    private var card: CoolingCard? {
        store.coolingCards.first { $0.id == cardID }
    }

    private func loadCard() {
        guard !loaded, let card else { return }
        loaded = true
        amountText = EchoFormatters.input(card.amount)
        note = card.note ?? ""
    }

    private func saveChanges() {
        guard var card else { return }
        guard let amount = MoneyInput.decimal(from: amountText), amount > 0 else {
            validationMessage = "Enter a purchase amount greater than zero."
            return
        }
        card.amount = amount
        card.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : note.trimmingCharacters(in: .whitespacesAndNewlines)
        card.updatedAt = Date()
        if store.updateCoolingCard(card) {
            validationMessage = nil
        }
    }

    private func finish(_ decision: PurchaseDecision) {
        guard let card else { return }
        if store.decide(card: card, decision: decision, reflection: reflection) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func deleteCard() {
        if store.deleteCoolingCard(id: cardID) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

private struct CoolingDetailHeader: View {
    let card: CoolingCard

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(card.revisitAt <= Date() ? "READY TO REVISIT" : "COOLING")
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundColor(card.promiseSnapshot.themeToken.color)
            Text(EchoFormatters.currency(card.amount))
                .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundColor(.white)
            Text("Compared with \(card.promiseSnapshot.title) · \(EchoFormatters.revisitTime(card.revisitAt))")
                .foregroundColor(.white.opacity(0.62))
        }
        .accessibilityElement(children: .combine)
    }
}

struct EchoTrailView: View {
    @EnvironmentObject private var store: EchoStore
    @Binding var sheet: EchoSheet?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(
                        eyebrow: "ECHO TRAIL",
                        title: "A record of your choices",
                        detail: "Skipped amounts are decisions, not deposits into a real account."
                    )
                    if store.outcomes.isEmpty {
                        TrailEmptyView()
                    } else {
                        if !store.snapshot.plusEntitled {
                            Text("The free trail keeps your 10 most recent outcomes visible. Future Echo Plus expands history without changing the core pause.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.58))
                        }
                        ForEach(store.outcomes) { outcome in
                            TrailRow(outcome: outcome) { sheet = .outcome(outcome.id) }
                        }
                    }
                }
                .padding(20)
            }
            .background(EchoBackground())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct TrailEmptyView: View {
    var body: some View {
        VStack(spacing: 14) {
            EmptyEchoIllustration(accent: EchoPalette.mist)
            Text("No decisions recorded yet.")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            Text("Finish an echo with Skip Purchase or Keep Purchase. Your Trail stays private on this device.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .accessibilityIdentifier("trail.empty")
    }
}

private struct TrailRow: View {
    let outcome: DecisionOutcome
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: outcome.decision == .skipped ? "arrow.uturn.backward.circle" : "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(outcome.promiseSnapshot.themeToken.color)
                VStack(alignment: .leading, spacing: 5) {
                    Text(outcome.decision == .skipped ? "Skipped" : "Kept")
                        .font(.headline)
                    Text("\(EchoFormatters.currency(outcome.amount)) · \(outcome.promiseSnapshot.title)")
                        .font(.subheadline.monospacedDigit())
                    if let reflection = outcome.reflection, !reflection.isEmpty {
                        Text(reflection)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                    Text(EchoFormatters.revisitTime(outcome.decidedAt))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.42))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.065))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            "\(outcome.decision == .skipped ? "Skipped" : "Kept") \(EchoFormatters.currency(outcome.amount)), \(outcome.promiseSnapshot.title)"
        )
        .accessibilityIdentifier("trail.outcome")
    }
}

struct OutcomeEditorView: View {
    @EnvironmentObject private var store: EchoStore
    @Environment(\.presentationMode) private var presentationMode

    let outcomeID: UUID

    @State private var reflection = ""
    @State private var showDeleteConfirmation = false
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let outcome {
                Text(outcome.decision == .skipped ? "You chose to skip this purchase." : "You chose to keep this purchase.")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                Text("\(EchoFormatters.currency(outcome.amount)) compared with \(outcome.promiseSnapshot.title)")
                    .foregroundColor(.white.opacity(0.65))
                EchoTextField(title: "Reflection (optional)", text: $reflection, keyboardType: .default)
                Button("Save Reflection", action: save)
                    .buttonStyle(PrimaryEchoButtonStyle(color: outcome.promiseSnapshot.themeToken.color))
                    .accessibilityIdentifier("outcome.save")
                Button("Delete Trail Entry", action: { showDeleteConfirmation = true })
                    .frame(maxWidth: .infinity)
                    .foregroundColor(EchoPalette.coral)
                    .accessibilityIdentifier("outcome.delete")
                Spacer()
            }
        }
        .padding(20)
        .background(EchoBackground())
        .navigationTitle("Trail Entry")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Close") { presentationMode.wrappedValue.dismiss() },
            trailing: Button("Done") { dismissKeyboard() }
        )
        .onAppear(perform: load)
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete this trail entry?"),
                message: Text("This removes the local decision record. It does not change any real account."),
                primaryButton: .destructive(Text("Delete"), action: delete),
                secondaryButton: .cancel()
            )
        }
    }

    private var outcome: DecisionOutcome? {
        store.snapshot.outcomes.first { $0.id == outcomeID }
    }

    private func load() {
        guard !loaded, let outcome else { return }
        loaded = true
        reflection = outcome.reflection ?? ""
    }

    private func save() {
        guard var outcome else { return }
        outcome.reflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        if store.updateOutcome(outcome) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func delete() {
        if store.deleteOutcome(id: outcomeID) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow)
                .font(.caption2.weight(.bold))
                .tracking(1.7)
                .foregroundColor(EchoPalette.mist)
            Text(title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(detail)
                .foregroundColor(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
