import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("📬")
                            .font(.system(size: 60))

                        Text("Notifications")
                            .font(.headline1)
                            .foregroundColor(.textPrimary)

                        Text("Get notified about price changes and portfolio updates")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)

                    // Status Card
                    BaseCard {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text("Status")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)

                                Spacer()

                                Text(statusText)
                                    .font(.bodyMedium)
                                    .foregroundColor(statusColor)
                            }

                            if notificationService.authorizationStatus == .denied {
                                Divider()

                                Text("Notifications are disabled in Settings. Tap 'Open Settings' to enable them.")
                                    .font(.caption)
                                    .foregroundColor(.textMuted)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }

                    // Action Button
                    if notificationService.authorizationStatus == .notDetermined {
                        PrimaryButton(title: "Enable Notifications") {
                            Task {
                                await notificationService.toggle()
                            }
                        }
                    } else if notificationService.authorizationStatus == .denied {
                        PrimaryButton(title: "Open Settings") {
                            Task {
                                await notificationService.toggle()
                            }
                        }
                    } else if notificationService.authorizationStatus == .authorized {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gainGreen)
                                Text("Notifications Enabled")
                                    .font(.bodyMedium)
                                    .foregroundColor(.gainGreen)
                            }

                            VStack(spacing: Spacing.sm) {
                                Button("Test Notification") {
                                    Task {
                                        do {
                                            try await notificationService.scheduleTestNotification()
                                            HapticManager.shared.success()
                                        } catch {
                                            print("❌ Error scheduling notification: \(error)")
                                            HapticManager.shared.error()
                                        }
                                    }
                                }
                                .foregroundColor(.primaryGreen)
                                .font(.bodyMedium)

                                Text("Background the app to see the notification")
                                    .font(.caption)
                                    .foregroundColor(.textMuted)
                            }

                            Button("Change in Settings") {
                                Task {
                                    await notificationService.toggle()
                                }
                            }
                            .foregroundColor(.textSecondary)
                            .font(.bodySmall)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .task {
            await notificationService.checkAuthorizationStatus()
        }
    }

    private var statusText: String {
        switch notificationService.authorizationStatus {
        case .notDetermined:
            return "Not Set"
        case .denied:
            return "Disabled"
        case .authorized:
            return "Enabled"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }

    private var statusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized:
            return .gainGreen
        case .denied:
            return .lossRed
        default:
            return .textMuted
        }
    }
}

#Preview {
    NotificationSettingsView()
}
