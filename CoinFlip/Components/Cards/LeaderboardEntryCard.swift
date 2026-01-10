import SwiftUI

struct LeaderboardEntryCard: View {
    let entry: LeaderboardEntry

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return .textSecondary
        }
    }

    private var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    var body: some View {
        BaseCard {
            HStack(spacing: Spacing.md) {
                // Rank
                VStack(spacing: Spacing.xxs) {
                    if entry.rank <= 3 {
                        Image(systemName: rankIcon)
                            .font(.title3)
                            .foregroundColor(rankColor)
                    }
                    Text("#\(entry.rank)")
                        .font(.headline3)
                        .foregroundColor(entry.rank <= 3 ? rankColor : .textPrimary)
                }
                .frame(width: 50)

                // Avatar
                Text(entry.avatarEmoji)
                    .font(.system(size: 40))
                    .frame(width: 56, height: 56)
                    .background(Color.cardBackgroundElevated)
                    .clipShape(Circle())

                // User Info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(entry.username)
                            .font(.headline3)
                            .foregroundColor(.textPrimary)

                        if entry.isCurrentUser {
                            Text("YOU")
                                .font(.labelSmall)
                                .foregroundColor(.primaryGreen)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.primaryGreen.opacity(0.1))
                                .cornerRadius(Spacing.xxs)
                        }
                    }

                    Text("Net Worth: \(Formatters.currency(entry.netWorth, decimals: 0))")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Gain/Loss
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: entry.percentageGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.labelSmall)

                        Text("\(entry.percentageGain >= 0 ? "+" : "")\(Int(entry.percentageGain))%")
                            .font(.numberMedium)
                    }
                    .foregroundColor(entry.percentageGain >= 0 ? .gainGreen : .lossRed)

                    Text("Total Gain")
                        .font(.labelSmall)
                        .foregroundColor(.textMuted)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cardRadius)
                .stroke(entry.isCurrentUser ? Color.primaryGreen : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VStack {
        LeaderboardEntryCard(entry: LeaderboardEntry(
            rank: 1,
            username: "whale_master",
            avatarEmoji: "👑",
            netWorth: 47832,
            percentageGain: 4683
        ))

        LeaderboardEntryCard(entry: LeaderboardEntry(
            rank: 2,
            username: "doge_queen",
            avatarEmoji: "🐕",
            netWorth: 12847,
            percentageGain: 1185
        ))

        LeaderboardEntryCard(entry: LeaderboardEntry(
            rank: 15,
            username: "you",
            avatarEmoji: "🚀",
            netWorth: 1250,
            percentageGain: 25,
            isCurrentUser: true
        ))
    }
    .padding()
    .background(Color.appBackground)
}
