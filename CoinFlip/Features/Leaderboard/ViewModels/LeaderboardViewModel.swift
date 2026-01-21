import Foundation
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var currentUserEntry: LeaderboardEntry?
    @Published var isLoading = false

    private let authService = AuthService.shared
    private let dataService: DataServiceProtocol
    private var currentUserNetWorth: Double = 1000
    private var currentUserGain: Double = 0
    private var portfolioId: UUID?

    init(dataService: DataServiceProtocol? = nil, currentUserNetWorth: Double = 1000, currentUserGain: Double = 0) {
        self.dataService = dataService ?? DataServiceFactory.shared
        self.currentUserNetWorth = currentUserNetWorth
        self.currentUserGain = currentUserGain
        // Load leaderboard immediately on init
        Task { @MainActor in
            await self.loadLeaderboard()
        }
    }

    func loadLeaderboard() async {
        isLoading = true

        do {
            // Update current user's net worth in database before fetching leaderboard
            // This ensures real-time accuracy for the active user
            if let currentUser = authService.currentUser {
                // Fetch portfolio ID if we don't have it
                if portfolioId == nil {
                    if let portfolio = try? await dataService.fetchPortfolio(userId: currentUser.id) {
                        portfolioId = portfolio.id
                    }
                }

                // Update net worth in database
                if let portfolioId = portfolioId {
                    try? await dataService.updatePortfolioNetWorth(
                        portfolioId: portfolioId,
                        netWorth: currentUserNetWorth,
                        gainPercentage: currentUserGain
                    )
                }
            }

            // Fetch leaderboard from backend
            var entries = try await dataService.fetchLeaderboard(limit: 50)

            // Get current user info
            guard let currentUser = authService.currentUser else {
                print("⚠️ No authenticated user")
                self.leaderboardEntries = entries
                self.isLoading = false
                return
            }

            // Find current user in leaderboard and mark them
            if let index = entries.firstIndex(where: { $0.username == currentUser.username }) {
                entries[index].isCurrentUser = true
                self.currentUserEntry = entries[index]
                print("✅ Found current user in top 50: Rank #\(entries[index].rank)")
            } else {
                // User not in top 50, fetch their rank separately
                if let userEntry = try? await dataService.fetchUserRank(userId: currentUser.id) {
                    self.currentUserEntry = userEntry
                    print("✅ Current user rank: #\(userEntry.rank) (outside top 50)")
                } else {
                    print("⚠️ Could not fetch current user rank")
                }
            }

            self.leaderboardEntries = entries
            print("🏆 Leaderboard loaded: \(entries.count) entries")
        } catch {
            print("❌ Error loading leaderboard: \(error)")
            // Fall back to empty state on error
            self.leaderboardEntries = []
        }

        isLoading = false
    }

    func refresh() {
        Task {
            await loadLeaderboard()
        }
    }

    func updateUserStats(netWorth: Double, gain: Double) {
        // Store current values for next refresh
        self.currentUserNetWorth = netWorth
        self.currentUserGain = gain

        // Refresh leaderboard to get updated rankings
        Task {
            await loadLeaderboard()
        }
    }
}
