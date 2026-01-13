import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @StateObject private var themeService = ThemeService.shared
    @State private var showAvatarPicker = false
    @State private var showUsernameEditor = false
    @State private var showNotificationSettings = false
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
                        totalGainPercentage: viewModel.totalGainPercentage,
                        onAvatarTap: {
                            showAvatarPicker = true
                            HapticManager.shared.impact(.light)
                        },
                        onUsernameTap: {
                            showUsernameEditor = true
                            HapticManager.shared.impact(.light)
                        }
                    )

                    // App Settings
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("App Settings")
                            .font(.headline3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.xs)

                        SettingsRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            iconColor: .primaryGreen
                        ) {
                            showNotificationSettings = true
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleTheme()
                    }) {
                        Image(systemName: themeService.currentTheme == .dark ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(.primaryGreen)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPicker(selectedEmoji: $viewModel.avatarEmoji)
                    .onDisappear {
                        // Save avatar when sheet closes, only if it changed
                        if previousAvatar != viewModel.avatarEmoji {
                            Task {
                                await viewModel.updateAvatar(viewModel.avatarEmoji)
                            }
                            previousAvatar = viewModel.avatarEmoji
                        }
                    }
            }
            .sheet(isPresented: $showUsernameEditor) {
                EditUsernameView(viewModel: viewModel)
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .onAppear {
                previousAvatar = viewModel.avatarEmoji
                // Reload user data when view appears
                viewModel.loadUserData()
            }
        }
    }

    private func toggleTheme() {
        // Toggle between dark and system
        let newTheme: Theme = themeService.currentTheme == .dark ? .system : .dark
        themeService.setTheme(newTheme)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
}
