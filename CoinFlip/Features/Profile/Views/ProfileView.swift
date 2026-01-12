import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @State private var showAvatarPicker = false
    @State private var previousAvatar: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Profile Card
                    UserProfileCard(
                        username: viewModel.username,
                        avatarEmoji: viewModel.avatarEmoji,
                        netWorth: viewModel.netWorth,
                        rank: viewModel.rank,
                        totalGainPercentage: viewModel.totalGainPercentage
                    )

                    // Account Settings
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Account")
                            .font(.headline3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.xs)

                        SettingsRow(
                            icon: "person.circle.fill",
                            title: "Edit Avatar",
                            subtitle: "Tap to change your avatar",
                            iconColor: .primaryGreen
                        ) {
                            showAvatarPicker = true
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "pencil.circle.fill",
                            title: "Change Username",
                            value: viewModel.username,
                            iconColor: .primaryPurple
                        ) {
                            HapticManager.shared.impact(.light)
                        }
                    }

                    // App Settings
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("App Settings")
                            .font(.headline3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.xs)

                        SettingsRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            value: "On",
                            iconColor: .primaryGreen
                        ) {
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "moon.fill",
                            title: "Dark Mode",
                            value: "Always",
                            iconColor: .primaryPurple
                        ) {
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "hand.raised.fill",
                            title: "Haptic Feedback",
                            value: "On",
                            iconColor: .primaryGreen
                        ) {
                            HapticManager.shared.impact(.light)
                        }
                    }

                    // About
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("About")
                            .font(.headline3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.xs)

                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            iconColor: .primaryPurple
                        ) {
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            iconColor: .textSecondary
                        ) {
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Policy",
                            iconColor: .textSecondary
                        ) {
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "App Version",
                            value: "1.0.0",
                            showChevron: false,
                            iconColor: .textMuted
                        ) {}
                    }

                    // Danger Zone
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Account Actions")
                            .font(.headline3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.xs)

                        SettingsRow(
                            icon: "arrow.counterclockwise.circle.fill",
                            title: "Reset Portfolio",
                            subtitle: "Start over with $1,000",
                            iconColor: .primaryPurple
                        ) {
                            viewModel.resetPortfolio()
                        }

                        SettingsRow(
                            icon: "arrow.right.circle.fill",
                            title: "Sign Out",
                            iconColor: .lossRed
                        ) {
                            Task {
                                await viewModel.signOut()
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPicker(selectedEmoji: $viewModel.avatarEmoji)
            }
            .onChange(of: viewModel.avatarEmoji) { oldValue, newValue in
                // Only save if the avatar actually changed and it's not the initial load
                if !previousAvatar.isEmpty && oldValue != newValue {
                    Task {
                        await viewModel.updateAvatar(newValue)
                    }
                }
                previousAvatar = newValue
            }
            .onAppear {
                previousAvatar = viewModel.avatarEmoji
                // Reload user data when view appears
                viewModel.loadUserData()
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
}
