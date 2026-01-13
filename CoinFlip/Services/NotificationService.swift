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
        // Check authorization first
        let settings = await notificationCenter.notificationSettings()
        print("📬 Current notification authorization: \(settings.authorizationStatus.rawValue)")

        guard settings.authorizationStatus == .authorized else {
            print("❌ Cannot schedule notification - not authorized")
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = "CoinFlip"
        content.body = "Test notification - notifications are working! 🎉"
        content.sound = .default

        // Use 3 second delay to give time to background the app
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        try await notificationCenter.add(request)
        print("✅ Test notification scheduled - ID: \(request.identifier)")
        print("📬 Background the app NOW - notification will appear in 3 seconds")
    }
}

enum NotificationError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized. Please enable them in Settings."
        }
    }
}
