import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var featuredCoin: Coin?
    @Published var trendingCoins: [Coin] = []
    @Published var portfolio: Portfolio
    @Published var currentPrices: [String: Double] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var netWorth: Double = 0
    @Published var dailyChange: Double = 0
    @Published var dailyChangePercentage: Double = 0

    init(portfolio: Portfolio) {
        self.portfolio = portfolio
        self.netWorth = portfolio.cashBalance
    }

    convenience init() {
        self.init(portfolio: Portfolio(startingBalance: 1000))
        Task { @MainActor in
            loadMockData()
        }
    }

    func loadMockData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.featuredCoin = MockData.featuredCoin
            self?.trendingCoins = MockData.coins
            self?.updatePrices()
            self?.calculatePortfolioMetrics()
            self?.isLoading = false
        }
    }

    func refresh() { loadMockData() }

    private func updatePrices() {
        for coin in trendingCoins { currentPrices[coin.id] = coin.currentPrice }
    }

    func calculatePortfolioMetrics() {
        netWorth = portfolio.totalValue(prices: currentPrices)

        dailyChange = portfolio.holdings.reduce(0) { total, holding in
            guard let currentPrice = currentPrices[holding.coinId] else { return total }
            let currentValue = holding.quantity * currentPrice
            let costBasis = holding.quantity * holding.averageBuyPrice
            return total + (currentValue - costBasis)
        }

        if netWorth > 0 && netWorth != dailyChange {
            dailyChangePercentage = (dailyChange / (netWorth - dailyChange)) * 100
        } else {
            dailyChangePercentage = 0
        }
    }

    func buy(coin: Coin, amount: Double) -> Bool {
        var updatedPortfolio = portfolio
        guard updatedPortfolio.buy(coin: coin, amount: amount) != nil else { return false }
        portfolio = updatedPortfolio
        currentPrices[coin.id] = coin.currentPrice
        calculatePortfolioMetrics()
        HapticManager.shared.success()
        return true
    }
}
