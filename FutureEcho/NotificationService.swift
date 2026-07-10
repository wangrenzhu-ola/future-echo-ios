import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    enum PermissionState: Equatable {
        case idle
        case authorized
        case denied
        case failed

        var message: String? {
            switch self {
            case .idle: return nil
            case .authorized: return "Reminders are on for future cooling cards."
            case .denied: return "Notifications are off. Your Cooling Shelf remains the manual place to revisit."
            case .failed: return "Notification settings couldn't be updated. Use the Cooling Shelf to revisit manually."
            }
        }
    }

    @Published private(set) var permissionState: PermissionState = .idle

    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            permissionState = .authorized
        case .denied:
            permissionState = .denied
        case .notDetermined:
            permissionState = .idle
        @unknown default:
            permissionState = .failed
        }
    }

    func requestPermission() async -> Bool {
        do {
            let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            permissionState = allowed ? .authorized : .denied
            return allowed
        } catch {
            permissionState = .failed
            return false
        }
    }

    func scheduleRevisit(for card: CoolingCard) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            permissionState = .denied
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Your echo is ready"
        content.body = "Revisit \(EchoFormatters.currency(card.amount)) in Future Echo."
        content.sound = .default
        let interval = max(1, card.revisitAt.timeIntervalSinceNow)
        let request = UNNotificationRequest(
            identifier: card.id.uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            permissionState = .failed
        }
    }
}
