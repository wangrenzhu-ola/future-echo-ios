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

extension View {
    func settingsCard() -> some View {
        foregroundColor(.white)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
    }
}
