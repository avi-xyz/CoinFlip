import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var themeService: ThemeService
    @State private var showAvatarPicker = false
    @State private var showUsernameEditor = false
    @State private var showResetConfirmation = false
    @State private var showLearnSection = false
    @State private var showThemePicker = false
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

                    // Learning
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Learning")
                            .font(.headline3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.xs)

                        SettingsRow(
                            icon: "book.fill",
                            title: "Learn About Crypto",
                            subtitle: "Basics, trading, and strategies",
                            iconColor: .primaryGreen
                        ) {
                            showLearnSection = true
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
                            icon: themeService.currentTheme.icon,
                            title: "Theme",
                            value: themeService.currentTheme.rawValue,
                            iconColor: .primaryGreen
                        ) {
                            showThemePicker = true
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
                            if let url = URL(string: "mailto:avinashgdn@gmail.com?subject=CoinFlip%20Support") {
                                UIApplication.shared.open(url)
                            }
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            iconColor: .textSecondary
                        ) {
                            if let url = URL(string: "https://avi-xyz.github.io/CoinFlip/terms-of-service.html") {
                                UIApplication.shared.open(url)
                            }
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Policy",
                            iconColor: .textSecondary
                        ) {
                            if let url = URL(string: "https://avi-xyz.github.io/CoinFlip/privacy-policy.html") {
                                UIApplication.shared.open(url)
                            }
                            HapticManager.shared.impact(.light)
                        }

                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "App Version",
                            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
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
                            showResetConfirmation = true
                        }
                        .accessibilityIdentifier("resetPortfolioButton")

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
            .sheet(isPresented: $showLearnSection) {
                LearnView()
            }
            .sheet(isPresented: $showThemePicker) {
                ThemeSettingsView()
            }
            .alert("Reset Portfolio?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetPortfolio()
                }
            } message: {
                Text("This will delete all your holdings and transactions. You'll start fresh with $1,000. This cannot be undone.")
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
