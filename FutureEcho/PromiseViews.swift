import SwiftUI

struct PromiseHorizonView: View {
    @EnvironmentObject private var store: EchoStore
    @Binding var sheet: EchoSheet?
    @Binding var selectedTab: EchoTab

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HorizonHeader()
                    if let promise = store.promises.first {
                        PromiseReadyContent(
                            promise: promise,
                            editAction: { sheet = .promiseEditor(promise.id) },
                            newEchoAction: { sheet = .newEcho }
                        )
                    } else {
                        PromiseEmptyContent(createAction: { sheet = .promiseEditor(nil) })
                    }
                    HorizonStatusStrip(
                        cardCount: store.coolingCards.count,
                        outcomeCount: store.outcomes.count,
                        openShelf: { selectedTab = .shelf },
                        openTrail: { selectedTab = .trail }
                    )
                }
                .padding(20)
            }
            .background(EchoBackground())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct HorizonHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("FUTURE ECHO")
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundColor(EchoPalette.mist)
            Text("A quieter moment\nbefore checkout.")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .accessibilityIdentifier("horizon.title")
            Text("Compare the purchase with a promise you chose. You still make the decision.")
                .font(.body)
                .foregroundColor(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PromiseReadyContent: View {
    let promise: SavingsPromise
    let editAction: () -> Void
    let newEchoAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            SplitHorizon(promise: promise)
            Button("Start a New Echo", action: newEchoAction)
                .buttonStyle(PrimaryEchoButtonStyle(color: promise.themeToken.color))
                .accessibilityIdentifier("horizon.newEcho")
            Button("Edit Promise", action: editAction)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
                .accessibilityIdentifier("horizon.editPromise")
        }
    }
}

private struct PromiseEmptyContent: View {
    let createAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            EmptyEchoIllustration(accent: EchoPalette.coral)
            Text("Your promise starts here.")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
            Text("Choose one savings promise to make the next purchase moment easier to see.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.65))
            Button("Create Your Promise", action: createAction)
                .buttonStyle(PrimaryEchoButtonStyle(color: EchoPalette.coral))
                .accessibilityIdentifier("horizon.createPromise")
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct HorizonStatusStrip: View {
    let cardCount: Int
    let outcomeCount: Int
    let openShelf: () -> Void
    let openTrail: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StatusButton(
                title: "Cooling",
                value: "\(cardCount)",
                symbol: "hourglass",
                action: openShelf
            )
            StatusButton(
                title: "Trail",
                value: "\(outcomeCount)",
                symbol: "point.3.connected.trianglepath.dotted",
                action: openTrail
            )
        }
    }
}

private struct StatusButton: View {
    let title: String
    let value: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value).font(.title3.monospacedDigit().weight(.semibold))
                    Text(title).font(.caption)
                }
                Spacer()
            }
            .foregroundColor(.white)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
