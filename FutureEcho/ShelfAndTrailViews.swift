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
