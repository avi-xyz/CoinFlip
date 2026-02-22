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
    private let cryptoAPI: CryptoAPIService
    private let viralAPI: GeckoTerminalService

    var holdings: [Holding] {
        portfolio.holdings.filter { $0.quantity > 0.00000001 }
    }

    var transactions: [Transaction] {
        portfolio.transactions
    }

    var totalHoldingsValue: Double {
        holdings.reduce(0) { total, holding in
            let price = getPrice(for: holding)
            return total + (holding.quantity * price)
        }
    }

    /// Get price for a holding, trying coinId first, then symbol, then averageBuyPrice
    private func getPrice(for holding: Holding) -> Double {
        // Try 1: Look up by coinId (works for standard coins and stored viral coins)
        if let price = currentPrices[holding.coinId], price > 0 {
            return price
        }

        // Try 2: Look up by symbol (fallback for viral coins stored by symbol)
        if let price = currentPrices[holding.coinSymbol.uppercased()], price > 0 {
            return price
        }

        // Try 3: Use average buy price as last resort (for coins with no current price data)
        return holding.averageBuyPrice
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

    init(portfolio: Portfolio, coins: [Coin], dataService: DataServiceProtocol = SupabaseDataService.shared, cryptoAPI: CryptoAPIService = .shared, viralAPI: GeckoTerminalService = .shared) {
        self.portfolio = portfolio
        self.coins = coins
        self.dataService = dataService
        self.cryptoAPI = cryptoAPI
        self.viralAPI = viralAPI
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

    /// Refresh price for a specific coin (called when opening sell sheet)
    func refreshPrice(for coinId: String) async {
        print("💰 PortfolioViewModel: Refreshing price for \(coinId)...")

        // Find the holding to get its symbol
        guard let holding = holdings.first(where: { $0.coinId == coinId }) else {
            print("   ⚠️ Holding not found for \(coinId)")
            currentPrices[coinId] = 0.0
            return
        }

        // Step 1: Check GeckoTerminal cache (for viral coins)
        if let viralPrice = viralAPI.getCachedPrice(forSymbol: holding.coinSymbol) {
            currentPrices[coinId] = viralPrice
            currentPrices[holding.coinSymbol.uppercased()] = viralPrice
            print("   ✅ Found viral coin price for \(holding.coinSymbol): $\(viralPrice)")
            return
        }

        // Step 2: If viral coin with chainId, try fetching from GeckoTerminal by address
        if let chainId = holding.chainId {
            do {
                print("   🔗 Trying GeckoTerminal direct lookup for \(holding.coinSymbol) on \(chainId)")
                let price = try await viralAPI.fetchTokenPrice(network: chainId, address: coinId)
                currentPrices[coinId] = price
                currentPrices[holding.coinSymbol.uppercased()] = price
                print("   ✅ Found viral coin price via direct lookup: \(holding.coinSymbol) = $\(price)")
                return
            } catch {
                print("   ⚠️ GeckoTerminal lookup failed: \(error.localizedDescription)")
                // Will try CoinGecko next
            }
        }

        // Step 3: Fetch from CoinGecko API (for well-known coins)
        do {
            let prices = try await cryptoAPI.fetchPrices(for: [coinId])
            if let price = prices[coinId] {
                currentPrices[coinId] = price
                print("   ✅ Updated price for \(coinId): $\(price)")
            } else {
                // Price unavailable - set to $0
                currentPrices[coinId] = 0.0
                print("   ⚠️ Price unavailable for \(coinId) - set to $0")
            }
        } catch {
            print("   ❌ Failed to fetch price for \(coinId): \(error.localizedDescription)")
            // Price unavailable - set to $0
            currentPrices[coinId] = 0.0
            print("   ⚠️ Price unavailable for \(coinId) - set to $0")
        }
    }

    /// Fetch prices for any held coins not in currentPrices or priced at $0
    func fetchMissingPricesForHoldings() async {
        let missingHoldings = holdings.filter {
            let price = currentPrices[$0.coinId]
            return price == nil || price == 0.0
        }

        guard !missingHoldings.isEmpty else { return }

        print("   🔍 PortfolioViewModel: Fetching prices for \(missingHoldings.count) held coins...")

        // Step 1: Check GeckoTerminal cache for viral coins (by symbol)
        let viralPrices = viralAPI.getCachedPrices(forSymbols: missingHoldings.map { $0.coinSymbol })

        var foundCount = 0
        for holding in missingHoldings {
            if let price = viralPrices[holding.coinSymbol] {
                // Store by BOTH coinId (contract address) AND symbol for future lookups
                currentPrices[holding.coinId] = price
                currentPrices[holding.coinSymbol.uppercased()] = price
                print("   ✅ Found viral coin price for \(holding.coinSymbol) (ID: \(holding.coinId)): $\(price)")
                foundCount += 1
            }
        }

        // Step 2: Try fetching viral coins by chainId + address from GeckoTerminal
        let stillMissing = missingHoldings.filter { currentPrices[$0.coinId] == nil }

        // Try holdings with chainId first
        let viralHoldingsWithChain = stillMissing.filter { $0.chainId != nil }

        for holding in viralHoldingsWithChain {
            guard let chainId = holding.chainId else { continue }

            do {
                print("   🔗 Fetching viral coin price from GeckoTerminal: \(holding.coinSymbol) on \(chainId)")
                let price = try await viralAPI.fetchTokenPrice(network: chainId, address: holding.coinId)
                currentPrices[holding.coinId] = price
                currentPrices[holding.coinSymbol.uppercased()] = price
                print("   ✅ Found viral coin price via direct lookup: \(holding.coinSymbol) = $\(price)")
            } catch {
                print("   ⚠️ Failed to fetch \(holding.coinSymbol) from GeckoTerminal: \(error.localizedDescription)")

                // Fallback: Check viral cache (from trending/search)
                if let cachedPrice = viralAPI.getCachedPrice(forSymbol: holding.coinSymbol), cachedPrice > 0 {
                    currentPrices[holding.coinId] = cachedPrice
                    currentPrices[holding.coinSymbol.uppercased()] = cachedPrice
                    print("   💾 Found \(holding.coinSymbol) in viral cache: $\(cachedPrice)")
                } else {
                    // Don't try other chains - too many API calls
                    // Will try CoinGecko as final fallback
                    print("   ⏭️  Will try CoinGecko for \(holding.coinSymbol)")
                }
            }
        }

        // Step 2b: For viral coins WITHOUT chainId, skip GeckoTerminal lookup
        // (Don't try multiple chains - too many API calls)
        // These will fall through to CoinGecko or use avgBuyPrice as fallback

        // Step 3: Fetch remaining coins from CoinGecko API
        let stillMissing2 = missingHoldings.filter { currentPrices[$0.coinId] == nil }

        guard !stillMissing2.isEmpty else {
            print("   ✅ All prices found (viral cache + GeckoTerminal)")
            return
        }

        print("   🌐 Fetching \(stillMissing2.count) prices from CoinGecko API...")

        do {
            let missingCoinIds = stillMissing2.map { $0.coinId }
            let fetchedPrices = try await cryptoAPI.fetchPrices(for: missingCoinIds)

            // Mark coins that we tried to fetch but didn't get a price as $0
            for holding in stillMissing2 {
                if let price = fetchedPrices[holding.coinId] {
                    currentPrices[holding.coinId] = price
                    print("   ✅ Updated price for \(holding.coinSymbol): $\(price)")
                } else {
                    // Price unavailable - set to $0
                    currentPrices[holding.coinId] = 0.0
                    print("   ⚠️ Price unavailable for \(holding.coinSymbol) - set to $0")
                }
            }
        } catch {
            print("   ❌ Failed to fetch prices: \(error.localizedDescription)")
            // Set all missing coins to $0 to indicate price unavailable
            for holding in stillMissing2 {
                if currentPrices[holding.coinId] == nil {
                    currentPrices[holding.coinId] = 0.0
                    print("   ⚠️ Price unavailable for \(holding.coinSymbol) - set to $0")
                }
            }
        }
    }

    private func updatePrices() {
        for coin in coins {
            currentPrices[coin.id] = coin.currentPrice
        }
    }

    /// Sell result to communicate success/failure back to UI
    enum SellResult {
        case success
        case invalidQuantity
        case persistenceFailed(String)
    }

    /// Sell a holding - waits for database confirmation before updating local state
    /// Returns a SellResult indicating success or the type of failure
    func sell(holding: Holding, quantity: Double) async -> SellResult {
        print("💰 PortfolioViewModel.sell() - START")
        print("   📊 Before sell:")
        print("      - Cash balance: $\(portfolio.cashBalance)")
        print("      - Holdings count: \(portfolio.holdings.count)")
        print("      - Total holdings value: $\(totalHoldingsValue)")
        print("      - Net worth: $\(portfolio.cashBalance + totalHoldingsValue)")
        print("   🪙 Selling: \(holding.coinSymbol) qty=\(quantity)")

        // Validate quantity
        guard quantity > 0, quantity <= holding.quantity else {
            print("   ❌ Sell failed - invalid quantity")
            return .invalidQuantity
        }

        // Check if this is a complete sell BEFORE modifying portfolio
        let isCompleteSell = (holding.quantity - quantity) < 0.00000001
        let holdingId = holding.id
        print("   🔍 Is complete sell: \(isCompleteSell)")
        print("   🆔 Holding ID: \(holdingId)")

        // Use real-time coin data if available, fallback to holding data
        // CRITICAL: Check for $0 prices and fall back to averageBuyPrice
        let priceById = currentPrices[holding.coinId]
        let priceBySymbol = currentPrices[holding.coinSymbol.uppercased()]
        let sellPrice = (priceById != nil && priceById! > 0) ? priceById! :
                       (priceBySymbol != nil && priceBySymbol! > 0) ? priceBySymbol! :
                       holding.averageBuyPrice

        let coin = coins.first(where: { $0.id == holding.coinId }) ?? Coin(
            id: holding.coinId,
            symbol: holding.coinSymbol,
            name: holding.coinName,
            image: holding.coinImage,
            currentPrice: sellPrice,
            priceChange24h: 0,
            priceChangePercentage24h: 0,
            marketCap: 0,
            sparklineIn7d: nil
        )

        print("   💵 Sell price: $\(coin.currentPrice)")
        print("   💰 Sale proceeds: $\(quantity * coin.currentPrice)")

        var updatedPortfolio = portfolio
        guard let transaction = updatedPortfolio.sell(coin: coin, quantity: quantity) else {
            print("   ❌ Sell failed - validation error")
            return .invalidQuantity
        }

        print("   📊 After sell (pending DB confirmation):")
        print("      - Cash balance: $\(updatedPortfolio.cashBalance)")
        print("      - Holdings count: \(updatedPortfolio.holdings.count)")

        // Persist to database FIRST - wait for confirmation
        do {
            print("💾 PortfolioViewModel: Persisting sell transaction to Supabase...")
            print("   🔍 Transaction type: \(isCompleteSell ? "Complete sell (delete holding)" : "Partial sell (update holding)")")

            // 1. Create transaction
            _ = try await dataService.createTransaction(transaction)
            print("   ✅ Transaction created: \(transaction.coinId) x \(transaction.quantity)")

            // 2. Update or delete holding
            if isCompleteSell {
                // Complete sell - delete the holding from database
                print("   🗑️ Deleting holding: \(transaction.coinId) (ID: \(holdingId))")
                try await dataService.deleteHolding(holdingId: holdingId)
                print("   ✅ Holding deleted: \(transaction.coinId)")
            } else {
                // Partial sell - update the holding quantity
                if let holding = updatedPortfolio.holdings.first(where: { $0.coinId == transaction.coinId }) {
                    print("   🔄 Upserting holding: \(holding.coinId), qty: \(holding.quantity)")
                    _ = try await dataService.upsertHolding(holding)
                    print("   ✅ Holding updated: \(holding.coinId)")
                } else {
                    print("   ⚠️ Warning: Partial sell but holding not found in updated portfolio")
                }
            }

            // 3. Update portfolio cash balance
            print("   🔄 Updating portfolio cash balance to $\(updatedPortfolio.cashBalance)")
            _ = try await dataService.updatePortfolio(updatedPortfolio)
            print("   ✅ Portfolio updated: cash balance = $\(updatedPortfolio.cashBalance)")

            print("✅ PortfolioViewModel: Sell transaction persisted successfully")

            // NOW update local state (after DB confirmation)
            portfolio = updatedPortfolio

            // Recalculate totals with updated portfolio
            print("      - Total holdings value: $\(totalHoldingsValue)")
            print("      - Net worth: $\(portfolio.cashBalance + totalHoldingsValue)")
            print("💰 PortfolioViewModel.sell() - END (success)")

            // Track successful sell
            let profitLoss = (quantity * sellPrice) - (quantity * holding.averageBuyPrice)
            AnalyticsService.shared.trackSellSuccess(
                coinSymbol: holding.coinSymbol,
                quantity: quantity,
                price: sellPrice,
                profitLoss: profitLoss
            )

            HapticManager.shared.success()
            return .success

        } catch {
            print("❌ PortfolioViewModel: Failed to persist sell transaction - \(error.localizedDescription)")
            print("   Error details: \(error)")

            // Track failed sell
            AnalyticsService.shared.trackSellFailed(
                coinSymbol: holding.coinSymbol,
                quantity: quantity,
                error: error.localizedDescription
            )

            // Don't update local state - the transaction failed
            HapticManager.shared.error()
            return .persistenceFailed(error.localizedDescription)
        }
    }
}
