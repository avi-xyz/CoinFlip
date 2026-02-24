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
            emoji: "🎮",
            title: "Simulation Only",
            subtitle: "CoinDojo is a TRADING SIMULATOR for educational purposes. No real money. No real cryptocurrency. All trades are 100% simulated with play money."
        ),
        OnboardingPageData(
            emoji: "🪙",
            title: "Welcome to CoinDojo",
            subtitle: "Learn crypto trading with $1,000 of virtual play money. Practice risk-free!"
        ),
        OnboardingPageData(
            emoji: "📈",
            title: "Track Real Prices",
            subtitle: "See real-time cryptocurrency prices. Practice buying and selling with simulated trades."
        ),
        OnboardingPageData(
            emoji: "🏆",
            title: "Compete & Learn",
            subtitle: "Build your virtual portfolio, climb the leaderboard, and master trading strategies!"
        ),
        OnboardingPageData(
            emoji: "⚠️",
            title: "Not Financial Advice",
            subtitle: "This is an educational game. No real transactions occur. Do not make real investment decisions based on this app. Always consult a financial advisor."
        )
    ]

    func nextPage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        }
    }
}
