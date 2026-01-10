import SwiftUI

struct UserProfileCard: View {
    let username: String
    let avatarEmoji: String
    let netWorth: Double
    let rank: Int
    let totalGainPercentage: Double

    var body: some View {
        BaseCard {
            VStack(spacing: Spacing.md) {
                // Avatar
                Text(avatarEmoji)
                    .font(.system(size: 64))
                    .frame(width: 96, height: 96)
                    .background(Color.cardBackgroundElevated)
                    .clipShape(Circle())

                // Username
                Text(username)
                    .font(.headline1)
                    .foregroundColor(.textPrimary)

                // Stats Row
                HStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.xxs) {
                        Text("Rank")
                            .font(.labelMedium)
                            .foregroundColor(.textSecondary)
                        Text("#\(rank)")
                            .font(.displayMedium)
                            .foregroundColor(.primaryGreen)
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
