import SwiftUI

struct PremiumView: View {
    @EnvironmentObject private var store: EchoStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @Environment(\.presentationMode) private var presentationMode

    private var canPurchase: Bool {
        if case .ready = premiumStore.state { return true }
        return false
    }

    private var stateColor: Color {
        if case .failed = premiumStore.state { return EchoPalette.coral }
        if premiumStore.state == .unavailable { return EchoPalette.coral }
        return EchoPalette.mist
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PremiumHero()
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

private struct PremiumHero: View {
    var body: some View {
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
