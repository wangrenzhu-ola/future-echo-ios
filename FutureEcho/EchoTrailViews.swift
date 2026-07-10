import SwiftUI

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

    private var outcome: DecisionOutcome? {
        store.snapshot.outcomes.first { $0.id == outcomeID }
    }

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
