import SwiftUI

struct PromiseEditorView: View {
    @EnvironmentObject private var store: EchoStore
    @Environment(\.presentationMode) private var presentationMode

    let promiseID: UUID?

    @State private var title = ""
    @State private var targetAmount = ""
    @State private var currentAmount = ""
    @State private var plannedContribution = ""
    @State private var theme: PromiseTheme = .coral
    @State private var validationMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                EditorIntro(isEditing: promiseID != nil)
                VStack(spacing: 16) {
                    EchoTextField(title: "Promise name", text: $title, keyboardType: .default)
                    EchoTextField(title: "Goal amount", text: $targetAmount, keyboardType: .decimalPad)
                    EchoTextField(title: "Currently saved", text: $currentAmount, keyboardType: .decimalPad)
                    EchoTextField(title: "Planned deposit (optional)", text: $plannedContribution, keyboardType: .decimalPad)
                }
                ThemePicker(theme: $theme)
                if let validationMessage {
                    InlineNoticeView(message: validationMessage, isError: true)
                }
                Button("Save Promise", action: save)
                    .buttonStyle(PrimaryEchoButtonStyle(color: theme.color))
                    .accessibilityIdentifier("promise.save")
                if promiseID != nil {
                    Button("Delete Promise", action: { showDeleteConfirmation = true })
                        .frame(maxWidth: .infinity)
                        .foregroundColor(EchoPalette.coral)
                        .padding(.top, 6)
                        .accessibilityIdentifier("promise.delete")
                }
            }
            .padding(20)
        }
        .background(EchoBackground())
        .navigationTitle(promiseID == nil ? "New Promise" : "Edit Promise")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
            trailing: Button("Done") { dismissKeyboard() }
        )
        .onAppear(perform: loadExistingPromise)
        .alert(isPresented: $showDeleteConfirmation) {
            let related = promiseID.map(store.relatedCoolingCardCount(for:)) ?? 0
            return Alert(
                title: Text("Delete this promise?"),
                message: Text(
                    related == 0
                        ? "This removes the promise from your device. Trail entries keep their original snapshot."
                        : "This also removes \(related) open cooling card\(related == 1 ? "" : "s"). Trail entries keep their original snapshot."
                ),
                primaryButton: .destructive(Text("Delete"), action: deletePromise),
                secondaryButton: .cancel()
            )
        }
    }

    private func loadExistingPromise() {
        guard !loaded else { return }
        loaded = true
        guard let promiseID,
              let promise = store.promises.first(where: { $0.id == promiseID }) else { return }
        title = promise.title
        targetAmount = EchoFormatters.input(promise.targetAmount)
        currentAmount = EchoFormatters.input(promise.currentSavedAmount)
        plannedContribution = promise.plannedContribution.map(EchoFormatters.input) ?? ""
        theme = promise.themeToken
    }

    private func save() {
        dismissKeyboard()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Give your promise a name."
            return
        }
        guard let target = MoneyInput.decimal(from: targetAmount), target > 0 else {
            validationMessage = "Enter a goal amount greater than zero."
            return
        }
        guard let current = MoneyInput.decimal(from: currentAmount), current >= 0 else {
            validationMessage = "Enter a current amount of zero or more."
            return
        }
        guard current <= target else {
            validationMessage = "Current savings can't be higher than the goal amount."
            return
        }
        let planned = plannedContribution.isEmpty ? nil : MoneyInput.decimal(from: plannedContribution)
        if !plannedContribution.isEmpty, planned == nil || planned! <= 0 {
            validationMessage = "Planned deposit must be greater than zero."
            return
        }
        let existing = promiseID.flatMap { id in store.promises.first { $0.id == id } }
        let promise = SavingsPromise(
            id: existing?.id ?? UUID(),
            title: trimmedTitle,
            targetAmount: target,
            currentSavedAmount: current,
            plannedContribution: planned,
            themeToken: theme,
            createdAt: existing?.createdAt ?? Date(),
            updatedAt: Date()
        )
        if store.upsertPromise(promise) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func deletePromise() {
        guard let promiseID else { return }
        if store.deletePromise(id: promiseID) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

private struct EditorIntro: View {
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isEditing ? "Keep the scale honest." : "Choose a scale that matters to you.")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
            Text("Future Echo uses this promise only for private, on-device comparisons.")
                .foregroundColor(.white.opacity(0.65))
        }
    }
}

struct EchoTextField: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.62))
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .accessibilityIdentifier("field.\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
        }
    }
}

private struct ThemePicker: View {
    @Binding var theme: PromiseTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Promise theme")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.62))
            HStack(spacing: 12) {
                ForEach(PromiseTheme.allCases) { option in
                    Button(action: { theme = option }) {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(option.color)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: theme == option ? "checkmark" : "circle")
                                        .foregroundColor(EchoPalette.ink)
                                )
                            Text(option.displayName)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.72))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(option.displayName) theme\(theme == option ? ", selected" : "")")
                }
            }
        }
    }
}

func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
