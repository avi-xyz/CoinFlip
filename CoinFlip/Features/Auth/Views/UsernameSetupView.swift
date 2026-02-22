//
//  UsernameSetupView.swift
//  CoinFlip
//
//  Created on Sprint 12
//  Username selection for new anonymous users
//

import SwiftUI

struct UsernameSetupView: View {
    @StateObject private var authService = AuthService.shared
    @State private var username: String = ""
    @State private var selectedEmoji: String = "🚀"
    @State private var isCreating = false
    @State private var error: String?

    private let emojiOptions = ["🚀", "💎", "🔥", "⚡️", "🎯", "🦊", "🐸", "🐕", "🦄", "👑", "💰", "🌟"]

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()
                .onAppear {
                    // Auto-create test user in UI testing mode
                    if ProcessInfo.processInfo.environment["AUTO_CREATE_TEST_USER"] == "1" {
                        // Use unique username with timestamp to avoid conflicts
                        let timestamp = Int(Date().timeIntervalSince1970)
                        username = "TestUser\(timestamp)"
                        selectedEmoji = "🚀"
                        print("🧪 [UI-Testing] Auto-creating user with username: \(username)")
                        // Small delay to let UI settle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            createProfile()
                        }
                    }
                }

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Title
                VStack(spacing: Spacing.md) {
                    Text("Welcome to CoinDojo!")
                        .font(.headline1)
                        .foregroundColor(.textPrimary)

                    Text("Choose your username and avatar")
                        .font(.bodyLarge)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Avatar Selection
                VStack(spacing: Spacing.md) {
                    Text("Pick Your Avatar")
                        .font(.headline3)
                        .foregroundColor(.textPrimary)

                    // Emoji Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.md) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                HapticManager.shared.impact(.light)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 40))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selectedEmoji == emoji ?
                                        Color.primaryGreen.opacity(0.2) :
                                        Color.cardBackground
                                    )
                                    .cornerRadius(Spacing.cardRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Spacing.cardRadius)
                                            .stroke(
                                                selectedEmoji == emoji ? Color.primaryGreen : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .accessibilityIdentifier("avatarEmoji_\(emoji)")
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Username Input
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Choose Username")
                        .font(.headline3)
                        .foregroundColor(.textPrimary)

                    TextField("Enter username", text: $username)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.bodyLarge)
                        .foregroundColor(.textPrimary)
                        .padding(Spacing.md)
                        .background(Color.cardBackground)
                        .cornerRadius(Spacing.cardRadius)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cardRadius)
                                .stroke(Color.textMuted.opacity(0.2), lineWidth: 1)
                        )
                        .accessibilityIdentifier("usernameTextField")

                    Text("3-20 characters, letters and numbers only")
                        .font(.labelSmall)
                        .foregroundColor(.textMuted)
                }
                .padding(.horizontal, Spacing.lg)

                // Error Message
                if let error = error {
                    Text(error)
                        .font(.labelSmall)
                        .foregroundColor(.lossRed)
                        .padding(.horizontal, Spacing.lg)
                }

                Spacer()

                // Continue Button
                PrimaryButton(
                    title: isCreating ? "Creating..." : "Start Trading",
                    isDisabled: !isValidUsername || isCreating
                ) {
                    createProfile()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
                .accessibilityIdentifier("startTradingButton")
            }
        }
    }

    // MARK: - Validation

    private var isValidUsername: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 3 &&
               trimmed.count <= 20 &&
               trimmed.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    // MARK: - Actions

    private func createProfile() {
        guard isValidUsername else {
            error = "Please enter a valid username"
            return
        }

        isCreating = true
        error = nil

        Task {
            do {
                try await authService.createUserProfile(
                    username: username.trimmingCharacters(in: .whitespaces),
                    avatarEmoji: selectedEmoji
                )

                HapticManager.shared.success()

            } catch {
                self.error = error.localizedDescription
                HapticManager.shared.error()
            }

            isCreating = false
        }
    }
}

#Preview {
    UsernameSetupView()
}
