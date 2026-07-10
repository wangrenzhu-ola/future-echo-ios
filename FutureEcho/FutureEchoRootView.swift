import SwiftUI

enum EchoTab: Hashable {
    case horizon
    case shelf
    case trail
    case settings
}

enum EchoSheet: Identifiable {
    case promiseEditor(UUID?)
    case newEcho
    case coolingCard(UUID)
    case outcome(UUID)
    case privacy
    case premium

    var id: String {
        switch self {
        case .promiseEditor: return "promise-editor"
        case .newEcho: return "new-echo"
        case .coolingCard(let id): return "cooling-\(id.uuidString)"
        case .outcome(let id): return "outcome-\(id.uuidString)"
        case .privacy: return "privacy"
        case .premium: return "premium"
        }
    }
}

struct FutureEchoRootView: View {
    @EnvironmentObject private var store: EchoStore
    @State private var selectedTab: EchoTab = .horizon
    @State private var sheet: EchoSheet?

    var body: some View {
        ZStack {
            EchoBackground()
            VStack(spacing: 0) {
                statusNotice
                TabView(selection: $selectedTab) {
                    PromiseHorizonView(sheet: $sheet, selectedTab: $selectedTab)
                        .tabItem { Label("Horizon", systemImage: "sun.horizon") }
                        .tag(EchoTab.horizon)
                    CoolingShelfView(sheet: $sheet)
                        .tabItem { Label("Shelf", systemImage: "hourglass") }
                        .tag(EchoTab.shelf)
                    EchoTrailView(sheet: $sheet)
                        .tabItem { Label("Trail", systemImage: "point.3.connected.trianglepath.dotted") }
                        .tag(EchoTab.trail)
                    SettingsView(sheet: $sheet)
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                        .tag(EchoTab.settings)
                }
                .accentColor(EchoPalette.coral)
            }
        }
        .sheet(item: $sheet) { destination in
            NavigationView {
                sheetContent(destination)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(store)
        }
    }

    @ViewBuilder
    private func sheetContent(_ destination: EchoSheet) -> some View {
        switch destination {
        case .promiseEditor(let id):
            PromiseEditorView(promiseID: id)
        case .newEcho:
            NewEchoFlowView()
        case .coolingCard(let id):
            CoolingCardDetailView(cardID: id)
        case .outcome(let id):
            OutcomeEditorView(outcomeID: id)
        case .privacy:
            PrivacyView()
        case .premium:
            PremiumView()
        }
    }

    @ViewBuilder
    private var statusNotice: some View {
        if let error = store.errorMessage {
            InlineNoticeView(message: error, isError: true)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .onTapGesture { store.errorMessage = nil }
        } else if let notice = store.notice {
            InlineNoticeView(message: notice, isError: false)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .onTapGesture { store.notice = nil }
        }
    }
}
