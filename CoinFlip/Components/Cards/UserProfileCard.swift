import SwiftUI

struct UserProfileCard: View {
    let username: String
    let avatarEmoji: String
    let netWorth: Double
    let rank: Int
    let totalGainPercentage: Double
    var onAvatarTap: (() -> Void)?
    var onUsernameTap: (() -> Void)?

    var body: some View {
        BaseCard {
            VStack(spacing: Spacing.md) {
                // Avatar with edit indicator
                Button(action: {
                    onAvatarTap?()
                }) {
                    ZStack(alignment: .bottomTrailing) {
                        Text(avatarEmoji)
                            .font(.system(size: 64))
                            .frame(width: 96, height: 96)
                            .background(Color.cardBackgroundElevated)
                            .clipShape(Circle())

                        // Edit indicator
                        if onAvatarTap != nil {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.primaryGreen)
                                .background(
                                    Circle()
                                        .fill(Color.cardBackground)
                                        .frame(width: 24, height: 24)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(onAvatarTap == nil)

                // Username with edit indicator
                Button(action: {
                    onUsernameTap?()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Text(username)
                            .font(.headline1)
                            .foregroundColor(.textPrimary)
                            .accessibilityIdentifier("profileUsername")
                            .accessibilityValue(username)

                        if onUsernameTap != nil {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(onUsernameTap == nil)

                // Stats Row
                HStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.xxs) {
                        Text("Rank")
                            .font(.labelMedium)
                            .foregroundColor(.textSecondary)
                        Text("#\(rank)")
                            .font(.displayMedium)
                            .foregroundColor(.primaryGreen)
                            .accessibilityIdentifier("profileRank")
                            .accessibilityValue("#\(rank)")
                    }

                    Divider()
                        .frame(height: 40)
                        .background(Color.borderPrimary)

                    VStack(spacing: Spacing.xxs) {
                        Text("Net Worth")
                            .font(.labelMedium)
                            .foregroundColor(.textSecondary)
                        Text(Formatters.currency(netWorth, decimals: 0))
                            .font(.numberMedium)
                            .foregroundColor(.textPrimary)
                            .accessibilityIdentifier("profileNetWorth")
                            .accessibilityValue(Formatters.currency(netWorth, decimals: 0))
                    }

                    Divider()
                        .frame(height: 40)
                        .background(Color.borderPrimary)

                    VStack(spacing: Spacing.xxs) {
                        Text("Total Gain")
                            .font(.labelMedium)
                            .foregroundColor(.textSecondary)
                        Text("\(totalGainPercentage >= 0 ? "+" : "")\(Int(totalGainPercentage))%")
                            .font(.numberMedium)
                            .foregroundColor(totalGainPercentage >= 0 ? .gainGreen : .lossRed)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Spacing.md)
        }
    }
}

#Preview {
    VStack {
        UserProfileCard(
            username: "CryptoKing",
            avatarEmoji: "👑",
            netWorth: 15420,
            rank: 8,
            totalGainPercentage: 542
        )

        UserProfileCard(
            username: "You",
            avatarEmoji: "🚀",
            netWorth: 1250,
            rank: 15,
            totalGainPercentage: 25
        )
    }
    .padding()
    .background(Color.appBackground)
}
