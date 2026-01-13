import Foundation
import UserNotifications
import Combine
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isEnabled: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Check current notification authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.isEnabled = settings.authorizationStatus == .authorized
    }

    /// Request notification permission from user
    func requestAuthorization() async throws -> Bool {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])

        await checkAuthorizationStatus()

        return granted
    }

    /// Toggle notifications on/off
    func toggle() async {
        if authorizationStatus == .notDetermined {
            // First time - request permission
            do {
                let granted = try await requestAuthorization()
                if granted {
                    print("✅ Notifications authorized")
                } else {
                    print("❌ Notifications denied")
                }
            } catch {
                print("❌ Error requesting notifications: \(error)")
            }
        } else if authorizationStatus == .denied {
            // Permission denied - need to open settings
            openSettings()
        } else {
            // Already authorized - toggle would require opening settings to disable
            openSettings()
        }
    }

    /// Open iOS Settings app
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Task { @MainActor in
                await UIApplication.shared.open(url)
            }
        }
    }

    /// Schedule a test notification (for testing)
    func scheduleTestNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "CoinFlip"
        content.body = "Test notification - notifications are working! 🎉"
        content.sound = .default

        // Use 1 second delay so it appears immediately after backgrounding
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        try await notificationCenter.add(request)
        print("📬 Test notification scheduled - will appear in 1 second when app is backgrounded")
    }
}
