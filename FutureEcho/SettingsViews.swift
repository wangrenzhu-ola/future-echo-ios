import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: EchoStore
    @EnvironmentObject private var notificationService: NotificationService
    @Binding var sheet: EchoSheet?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(
                        eyebrow: "SETTINGS",
                        title: "Shape the pause",
                        detail: "The core decision loop stays available without notifications or Future Echo Plus."
                    )
                    pauseCard
                    notificationCard
                    destinationCard
                }
                .padding(20)
            }
            .background(EchoBackground())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task { await notificationService.refresh() }
        }
    }

    private var pauseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Pause duration", systemImage: "waveform.path")
                .font(.headline)
            Picker("Pause duration", selection: pauseDurationBinding) {
                Text("12 sec").tag(12)
                Text("20 sec").tag(20)
                Text("30 sec").tag(30)
            }
            .pickerStyle(SegmentedPickerStyle())
            Text("Reduce Motion uses the same countdown with a static echo ring.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.62))
        }
        .settingsCard()
        .accessibilityIdentifier("settings.pause")
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: notificationBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optional revisit reminders")
                        .font(.headline)
                    Text("Permission is requested only after you turn this on.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.62))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: EchoPalette.mist))
            if let message = notificationService.permissionState.message {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(notificationService.permissionState == .denied ? EchoPalette.coral : EchoPalette.mist)
            }
        }
        .settingsCard()
        .accessibilityIdentifier("settings.notifications")
    }

    private var destinationCard: some View {
        VStack(spacing: 0) {
            SettingsDestinationRow(
                title: "Privacy",
                detail: "Local-only data and deletion controls",
                symbol: "lock.shield",
                action: { sheet = .privacy }
            )
            Divider().background(Color.white.opacity(0.12))
            SettingsDestinationRow(
                title: "Future Echo Plus",
                detail: store.snapshot.plusEntitled ? "Active on this device" : "More themes and unlimited Trail history",
                symbol: "sparkles",
                action: { sheet = .premium }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
    }

    private var pauseDurationBinding: Binding<Int> {
        Binding(
            get: { store.snapshot.preferences.durationSeconds },
            set: { duration in
                var preferences = store.snapshot.preferences
                preferences.durationSeconds = duration
                _ = store.updatePreferences(preferences)
            }
        )
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { store.snapshot.preferences.notificationOptIn },
            set: { enabled in
                if enabled {
                    Task {
                        let allowed = await notificationService.requestPermission()
                        var preferences = store.snapshot.preferences
                        preferences.notificationOptIn = allowed
                        _ = store.updatePreferences(preferences)
                    }
                } else {
                    var preferences = store.snapshot.preferences
                    preferences.notificationOptIn = false
                    _ = store.updatePreferences(preferences)
                }
            }
        )
    }
}

private struct SettingsDestinationRow: View {
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .frame(width: 28)
                    .foregroundColor(EchoPalette.mist)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.58))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.36))
            }
            .foregroundColor(.white)
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("settings.\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}

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

struct PremiumView: View {
    @EnvironmentObject private var store: EchoStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                premiumHero
                VStack(alignment: .leading, spacing: 12) {
                    PremiumBenefit(symbol: "paintpalette", text: "Four calm echo themes for your Promise Horizon and Pause Chamber")
                    PremiumBenefit(symbol: "point.3.connected.trianglepath.dotted", text: "Unlimited visible Echo Trail history on this device")
                    PremiumBenefit(symbol: "checkmark.shield", text: "The complete promise, pause, wait, and revisit flow remains free")
                }
                .settingsCard()
                Text(premiumStore.state.message)
                    .font(.footnote)
                    .foregroundColor(stateColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("premium.status")
                if store.snapshot.plusEntitled {
                    Label("Future Echo Plus is active", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundColor(EchoPalette.mist)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else {
                    Button("Unlock Future Echo Plus", action: purchase)
                        .buttonStyle(PrimaryEchoButtonStyle(color: EchoPalette.coral))
                        .disabled(!canPurchase)
                        .accessibilityIdentifier("premium.purchase")
                }
                Button("Restore Purchases", action: restore)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .accessibilityIdentifier("premium.restore")
            }
            .padding(20)
        }
        .background(EchoBackground())
        .navigationTitle("Future Echo Plus")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button("Close") { presentationMode.wrappedValue.dismiss() })
        .accessibilityIdentifier("premium.screen")
        .onAppear {
            Task {
                await premiumStore.load()
                if premiumStore.state == .purchased {
                    _ = store.setPlusEntitled(true)
                }
            }
        }
    }

    private var premiumHero: some View {
        VStack(spacing: 16) {
            ZStack {
                EchoRing(progress: 0.72, accent: EchoPalette.coral)
                EchoRing(progress: 0.38, accent: EchoPalette.mist)
                    .scaleEffect(0.67)
            }
            .frame(width: 190, height: 190)
            Text("More room for the choices you already make.")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text("One non-consumable purchase. No countdown, subscription, or core-flow lock.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
    }

    private var canPurchase: Bool {
        if case .ready = premiumStore.state { return true }
        return false
    }

    private var stateColor: Color {
        if case .failed = premiumStore.state { return EchoPalette.coral }
        if premiumStore.state == .unavailable { return EchoPalette.coral }
        return EchoPalette.mist
    }

    private func purchase() {
        Task {
            if await premiumStore.purchase() {
                _ = store.setPlusEntitled(true)
            }
        }
    }

    private func restore() {
        Task {
            if await premiumStore.restore() {
                _ = store.setPlusEntitled(true)
            }
        }
    }
}

private struct PremiumBenefit: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 24)
                .foregroundColor(EchoPalette.coral)
            Text(text)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension View {
    func settingsCard() -> some View {
        foregroundColor(.white)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
    }
}
