import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var viewModel: LeaderboardViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading {
                        LeaderboardLoadingSkeleton()
                    } else {
                        // Current User Stats
                        if let currentUserEntry = viewModel.currentUserEntry {
                            BaseCard {
                                VStack(spacing: Spacing.md) {
                                    Text("Your Rank")
                                        .font(.bodyMedium)
                                        .foregroundColor(.textSecondary)

                                    Text("#\(currentUserEntry.rank)")
                                        .font(.displayLarge)
                                        .foregroundColor(.primaryGreen)

                                    HStack(spacing: Spacing.xl) {
                                        VStack(spacing: Spacing.xxs) {
                                            Text("Net Worth")
                                                .font(.labelSmall)
                                                .foregroundColor(.textSecondary)
                                            Text(Formatters.currency(currentUserEntry.netWorth, decimals: 2))
                                                .font(.numberMedium)
                                                .foregroundColor(.textPrimary)
                                        }

                                        VStack(spacing: Spacing.xxs) {
                                            Text("Total Gain")
                                                .font(.labelSmall)
                                                .foregroundColor(.textSecondary)
                                            Text("\(currentUserEntry.percentageGain >= 0 ? "+" : "")\(Int(currentUserEntry.percentageGain))%")
                                                .font(.numberMedium)
                                                .foregroundColor(currentUserEntry.percentageGain >= 0 ? .gainGreen : .lossRed)
                                        }
                                    }
                                }
                                .padding(.vertical, Spacing.sm)
                            }
                        }

                        // Leaderboard List
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Top Traders")
                                .font(.headline3)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, Spacing.xs)

                            ForEach(viewModel.leaderboardEntries) { entry in
                                LeaderboardEntryCard(entry: entry)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("Leaderboard")
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                // Leaderboard loads on init, no need to reload here
            }
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(LeaderboardViewModel(currentUserRank: 15, currentUserNetWorth: 1250, currentUserGain: 25))
}
