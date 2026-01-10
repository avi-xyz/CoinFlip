import Foundation
import Combine

struct OnboardingPageData {
    let emoji: String
    let title: String
    let subtitle: String
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var pages: [OnboardingPageData] = [
        OnboardingPageData(
            emoji: "🪙",
            title: "Welcome to CoinFlip",
            subtitle: "Learn crypto trading with virtual money. No risk, all the fun!"
        ),
        OnboardingPageData(
            emoji: "📈",
            title: "Track Top Coins",
            subtitle: "Follow Bitcoin, Ethereum, and hundreds of other cryptocurrencies in real-time."
        ),
        OnboardingPageData(
            emoji: "💰",
            title: "Build Your Portfolio",
            subtitle: "Start with $1,000 virtual cash. Buy and sell coins to grow your wealth."
        ),
        OnboardingPageData(
            emoji: "🏆",
            title: "Compete & Learn",
            subtitle: "Climb the leaderboard and master crypto trading strategies risk-free!"
        )
    ]

    func nextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        }
    }
}
