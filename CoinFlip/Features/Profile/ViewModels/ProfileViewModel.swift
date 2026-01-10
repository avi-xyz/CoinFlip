import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = "You"
    @Published var avatarEmoji: String = "🚀"
    @Published var netWorth: Double = 1000
    @Published var rank: Int = 15
    @Published var totalGainPercentage: Double = 0

    var onResetPortfolio: (() -> Void)?

    func updateStats(netWorth: Double, rank: Int, gainPercentage: Double) {
        self.netWorth = netWorth
        self.rank = rank
        self.totalGainPercentage = gainPercentage
    }

    func resetPortfolio() {
        HapticManager.shared.success()
        onResetPortfolio?()
    }
}
