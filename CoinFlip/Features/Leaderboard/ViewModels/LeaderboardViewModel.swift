import Foundation
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var currentUserEntry: LeaderboardEntry?
    @Published var isLoading = false

    private let authService = AuthService.shared
    private var currentUserRank: Int = 15
    private var currentUserNetWorth: Double = 1000
    private var currentUserGain: Double = 0

    init(currentUserRank: Int = 15, currentUserNetWorth: Double = 1000, currentUserGain: Double = 0) {
        self.currentUserRank = currentUserRank
        self.currentUserNetWorth = currentUserNetWorth
        self.currentUserGain = currentUserGain
        // Load leaderboard immediately on init
        Task { @MainActor in
            self.loadLeaderboard()
        }
    }

    func loadLeaderboard() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // Load mock leaderboard
            var entries = MockData.leaderboard

            // Get actual user data from AuthService
            let actualUsername = self.authService.currentUser?.username ?? "You"
            let actualAvatar = self.authService.currentUser?.avatarEmoji ?? "🚀"

            // Add current user to leaderboard with CURRENT values (not init values)
            let currentUser = LeaderboardEntry(
                rank: self.currentUserRank,
                username: actualUsername,
                avatarEmoji: actualAvatar,
                netWorth: self.currentUserNetWorth,
                percentageGain: self.currentUserGain,
                isCurrentUser: true
            )

            // If user is in top 10, mark them
            if let index = entries.firstIndex(where: { $0.rank == self.currentUserRank }) {
                entries[index] = LeaderboardEntry(
                    rank: entries[index].rank,
                    username: actualUsername,
                    avatarEmoji: actualAvatar,
                    netWorth: self.currentUserNetWorth,
                    percentageGain: self.currentUserGain,
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
            print("🔄 Leaderboard loaded - User: \(actualUsername) (\(actualAvatar)), Net Worth: $\(Int(self.currentUserNetWorth)), Gain: \(Int(self.currentUserGain))%")
        }
    }

    func refresh() {
        loadLeaderboard()
    }

    func updateUserStats(netWorth: Double, gain: Double) {
        // Store current values for next refresh
        self.currentUserNetWorth = netWorth
        self.currentUserGain = gain

        // Update current user's stats (gain should be in percentage form like 25 for 25%)
        if let index = leaderboardEntries.firstIndex(where: { $0.isCurrentUser }) {
            let actualUsername = authService.currentUser?.username ?? leaderboardEntries[index].username
            let actualAvatar = authService.currentUser?.avatarEmoji ?? leaderboardEntries[index].avatarEmoji

            let updatedEntry = LeaderboardEntry(
                rank: leaderboardEntries[index].rank,
                username: actualUsername,
                avatarEmoji: actualAvatar,
                netWorth: netWorth,
                percentageGain: gain,
                isCurrentUser: true
            )
            leaderboardEntries[index] = updatedEntry
            currentUserEntry = updatedEntry
            print("📊 Leaderboard updated - User: \(actualUsername) (\(actualAvatar)), Net Worth: $\(Int(netWorth)), Gain: \(Int(gain))%")
        }
    }
}
