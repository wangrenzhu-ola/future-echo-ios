import SwiftUI

struct PrivacyView: View {
    @EnvironmentObject private var store: EchoStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(
                    eyebrow: "PRIVACY",
                    title: "Your purchase context stays here",
                    detail: "Future Echo is designed for a private decision moment, not a financial profile."
                )
                VStack(alignment: .leading, spacing: 16) {
                    PrivacyStatement(symbol: "iphone", text: "Promises, cooling cards, outcomes, and preferences are stored only on this device.")
                    PrivacyStatement(symbol: "building.columns", text: "Future Echo does not connect to a bank or read account balances.")
                    PrivacyStatement(symbol: "creditcard", text: "Future Echo does not execute, block, or verify purchases or payments.")
                    PrivacyStatement(symbol: "person.crop.circle.badge.questionmark", text: "Future Echo offers a neutral pause, not financial, investment, credit, or debt advice.")
                    PrivacyStatement(symbol: "network.slash", text: "There is no login, cloud sync, advertising tracker, chat assistant, or AI upload in this version.")
                }
                .settingsCard()
                Button("Delete All Local Data", action: { showDeleteConfirmation = true })
                    .frame(maxWidth: .infinity)
                    .foregroundColor(EchoPalette.coral)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier("privacy.deleteAll")
            }
            .padding(20)
        }
        .background(EchoBackground())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button("Close") { presentationMode.wrappedValue.dismiss() })
        .accessibilityIdentifier("privacy.screen")
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete all local data?"),
                message: Text("This permanently removes your promises, cooling cards, Trail entries, and preferences from this device."),
                primaryButton: .destructive(Text("Delete All"), action: deleteAll),
                secondaryButton: .cancel()
            )
        }
    }

    private func deleteAll() {
        if store.clearAllData() {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

private struct PrivacyStatement: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 24)
                .foregroundColor(EchoPalette.mist)
            Text(text)
                .foregroundColor(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
