import Foundation
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var currentUserEntry: LeaderboardEntry?
    @Published var isLoading = false

    private let currentUserRank: Int
    private let currentUserNetWorth: Double
    private let currentUserGain: Double

    init(currentUserRank: Int = 15, currentUserNetWorth: Double = 1000, currentUserGain: Double = 0) {
        self.currentUserRank = currentUserRank
        self.currentUserNetWorth = currentUserNetWorth
        self.currentUserGain = currentUserGain
    }

    func loadLeaderboard() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // Load mock leaderboard
            var entries = MockData.leaderboard

            // Add current user to leaderboard if not in top 10
            let currentUser = LeaderboardEntry(
                rank: self.currentUserRank,
                username: "You",
                avatarEmoji: "🚀",
                netWorth: self.currentUserNetWorth,
                percentageGain: self.currentUserGain * 100,
                isCurrentUser: true
            )

            // If user is in top 10, mark them
            if let index = entries.firstIndex(where: { $0.rank == self.currentUserRank }) {
                entries[index] = LeaderboardEntry(
                    rank: entries[index].rank,
                    username: entries[index].username,
                    avatarEmoji: entries[index].avatarEmoji,
                    netWorth: entries[index].netWorth,
                    percentageGain: entries[index].percentageGain,
                    isCurrentUser: true
                )
                self.currentUserEntry = entries[index]
            } else {
                // User not in top 10, add them at the end
                entries.append(currentUser)
                self.currentUserEntry = currentUser
            }

            self.leaderboardEntries = entries.sorted { $0.rank < $1.rank }
            self.isLoading = false
        }
    }

    func refresh() {
        loadLeaderboard()
    }

    func updateUserStats(netWorth: Double, gain: Double) {
        // Update current user's stats (gain should be in percentage form like 25 for 25%)
        if let index = leaderboardEntries.firstIndex(where: { $0.isCurrentUser }) {
            let updatedEntry = LeaderboardEntry(
                rank: leaderboardEntries[index].rank,
                username: leaderboardEntries[index].username,
                avatarEmoji: leaderboardEntries[index].avatarEmoji,
                netWorth: netWorth,
                percentageGain: gain,
                isCurrentUser: true
            )
            leaderboardEntries[index] = updatedEntry
            currentUserEntry = updatedEntry
            print("📊 Leaderboard updated - Net Worth: $\(Int(netWorth)), Gain: \(Int(gain))%")
        }
    }
}
