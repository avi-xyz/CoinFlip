import Foundation
import Combine

@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var portfolio: Portfolio
    @Published var coins: [Coin]
    @Published var currentPrices: [String: Double] = [:]
    @Published var selectedHolding: Holding?
    @Published var isLoading = false

    private let dataService: DataServiceProtocol

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

    init(portfolio: Portfolio, coins: [Coin], dataService: DataServiceProtocol = SupabaseDataService.shared) {
        self.portfolio = portfolio
        self.coins = coins
        self.dataService = dataService
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
        // Use real-time coin data if available, fallback to holding data
        let coin = coins.first(where: { $0.id == holding.coinId }) ?? Coin(
            id: holding.coinId,
            symbol: holding.coinSymbol,
            name: holding.coinName,
            image: holding.coinImage,
            currentPrice: currentPrices[holding.coinId] ?? holding.averageBuyPrice,
            priceChange24h: 0,
            priceChangePercentage24h: 0,
            marketCap: 0,
            sparklineIn7d: nil
        )

        var updatedPortfolio = portfolio
        guard let transaction = updatedPortfolio.sell(coin: coin, quantity: quantity) else {
            return false
        }

        // Update local state first
        portfolio = updatedPortfolio
        HapticManager.shared.success()

        // Persist to Supabase in background
        Task {
            await persistSellTransaction(transaction: transaction, updatedPortfolio: updatedPortfolio)
        }

        return true
    }

    /// Persist sell transaction to Supabase
    private func persistSellTransaction(transaction: Transaction, updatedPortfolio: Portfolio) async {
        do {
            print("💾 PortfolioViewModel: Persisting sell transaction to Supabase...")

            // 1. Create transaction
            _ = try await dataService.createTransaction(transaction)
            print("   ✅ Transaction created: \(transaction.coinId) x \(transaction.quantity)")

            // 2. Update or delete holding
            if let holding = updatedPortfolio.holdings.first(where: { $0.coinId == transaction.coinId }) {
                if holding.quantity > 0.00000001 {
                    // Still have coins left - update holding
                    print("   🔄 Upserting holding: \(holding.coinId), qty: \(holding.quantity)")
                    _ = try await dataService.upsertHolding(holding)
                    print("   ✅ Holding updated: \(holding.coinId)")
                } else {
                    // Sold all coins - delete holding
                    print("   🗑️ Deleting holding: \(holding.coinId)")
                    try await dataService.deleteHolding(holdingId: holding.id)
                    print("   ✅ Holding deleted: \(holding.coinId)")
                }
            }

            // 3. Update portfolio cash balance
            print("   🔄 Updating portfolio cash balance to $\(updatedPortfolio.cashBalance)")
            _ = try await dataService.updatePortfolio(updatedPortfolio)
            print("   ✅ Portfolio updated: cash balance = $\(updatedPortfolio.cashBalance)")

            print("✅ PortfolioViewModel: Sell transaction persisted successfully")

            // Reload portfolio from database to ensure sync
            if let userId = AuthService.shared.currentUser?.id {
                let reloadedPortfolio = try await dataService.fetchPortfolio(userId: userId)
                await MainActor.run {
                    self.portfolio = reloadedPortfolio
                    print("   🔄 Portfolio reloaded from database")
                }
            }
        } catch {
            print("❌ PortfolioViewModel: Failed to persist sell transaction - \(error.localizedDescription)")
            print("   Error details: \(error)")
            // TODO: Could implement retry logic or show error to user
        }
    }
}
