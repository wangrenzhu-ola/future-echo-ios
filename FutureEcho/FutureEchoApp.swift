import SwiftUI

@main
struct FutureEchoApp: App {
    @StateObject private var store = EchoStore()
    @StateObject private var premiumStore = PremiumStore()
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            FutureEchoRootView()
                .environmentObject(store)
                .environmentObject(premiumStore)
                .environmentObject(notificationService)
                .preferredColorScheme(.dark)
        }
    }
}
