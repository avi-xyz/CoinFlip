import Foundation
import Combine

@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var portfolio: Portfolio
    @Published var coins: [Coin]
    @Published var currentPrices: [String: Double] = [:]
    @Published var selectedHolding: Holding?
    @Published var isLoading = false

    var holdings: [Holding] {
        portfolio.holdings.filter { $0.quantity > 0.00000001 }
    }

    var transactions: [Transaction] {
        portfolio.transactions
    }

    var totalHoldingsValue: Double {
        holdings.reduce(0) { total, holding in
            let price = currentPrices[holding.coinId] ?? holding.averageBuyPrice
            return total + (holding.quantity * price)
        }
    }

    var totalCostBasis: Double {
        holdings.reduce(0) { total, holding in
            total + (holding.quantity * holding.averageBuyPrice)
        }
    }

    var totalProfitLoss: Double {
        totalHoldingsValue - totalCostBasis
    }

    var totalProfitLossPercentage: Double {
        guard totalCostBasis > 0 else { return 0 }
        return (totalProfitLoss / totalCostBasis) * 100
    }

    var isProfit: Bool {
        totalProfitLoss >= 0
    }

    init(portfolio: Portfolio, coins: [Coin]) {
        self.portfolio = portfolio
        self.coins = coins
        updatePrices()
    }

    func loadData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.coins = MockData.coins
            self?.updatePrices()
            self?.isLoading = false
        }
    }

    func refresh() {
        loadData()
    }

    private func updatePrices() {
        for coin in coins {
            currentPrices[coin.id] = coin.currentPrice
        }
    }

    func sell(holding: Holding, quantity: Double) -> Bool {
        guard let coin = coins.first(where: { $0.id == holding.coinId }) else { return false }

        var updatedPortfolio = portfolio
        guard updatedPortfolio.sell(coin: coin, quantity: quantity) != nil else { return false }

        portfolio = updatedPortfolio
        HapticManager.shared.success()
        return true
    }
}
