import Foundation
import Combine
import UIKit

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

    private let cryptoAPI: CryptoAPIService
    private let dataService: DataServiceProtocol
    private let viralAPI: GeckoTerminalService
    private let authService = AuthService.shared
    private let useMockData: Bool
    private var cancellables = Set<AnyCancellable>()

    // Featured coin persistence
    private let lastFeaturedDateKey = "lastFeaturedDate"
    private let lastFeaturedCoinIdKey = "lastFeaturedCoinId"
    private let hasSkippedTodayKey = "hasSkippedToday"

    init(portfolio: Portfolio, cryptoAPI: CryptoAPIService = .shared, dataService: DataServiceProtocol = SupabaseDataService.shared, viralAPI: GeckoTerminalService = .shared, useMockData: Bool = false) {
        self.portfolio = portfolio
        self.netWorth = portfolio.cashBalance
        self.cryptoAPI = cryptoAPI
        self.dataService = dataService
        self.viralAPI = viralAPI
        self.useMockData = useMockData

        // Observe currentUser changes and reload portfolio
        authService.$currentUser
            .sink { [weak self] user in
                guard let self = self, let user = user else { return }
                print("🔄 HomeViewModel: currentUser changed, loading portfolio...")
                Task { @MainActor in
                    await self.loadPortfolio()
                }
            }
            .store(in: &cancellables)
    }

    convenience init() {
        // Use mock data if configured in EnvironmentConfig
        let useMock = EnvironmentConfig.useMockData
        self.init(
            portfolio: Portfolio(userId: UUID(), startingBalance: 1000),
            useMockData: useMock
        )
        Task { @MainActor in
            await loadData()
        }
    }

    /// Load user's portfolio from Supabase
    func loadPortfolio() async {
        guard let user = authService.currentUser else {
            print("⚠️ HomeViewModel: No currentUser, using default portfolio")
            return
        }

        do {
            print("🔄 HomeViewModel: Loading portfolio for user \(user.username)...")
            let fetchedPortfolio = try await dataService.fetchPortfolio(userId: user.id)
            self.portfolio = fetchedPortfolio
            print("✅ HomeViewModel: Loaded portfolio with \(fetchedPortfolio.holdings.count) holdings, cash: $\(fetchedPortfolio.cashBalance)")

            // Calculate metrics to include holdings in net worth
            await calculatePortfolioMetrics()
            print("   💰 Net worth after calculation: $\(netWorth)")
        } catch {
            print("❌ HomeViewModel: Failed to load portfolio - \(error.localizedDescription)")

            // Portfolio doesn't exist - create one
            print("🔄 HomeViewModel: Creating portfolio for user \(user.username)...")
            do {
                let newPortfolio = try await dataService.createPortfolio(userId: user.id, startingBalance: user.startingBalance)
                self.portfolio = newPortfolio
                self.netWorth = newPortfolio.cashBalance
                print("✅ HomeViewModel: Created portfolio with cash: $\(newPortfolio.cashBalance)")
            } catch {
                print("❌ HomeViewModel: Failed to create portfolio - \(error.localizedDescription)")
                // Keep using the current in-memory portfolio as fallback
            }
        }
    }

    /// Load cryptocurrency data (real or mock based on config)
    func loadData() async {
        isLoading = true
        error = nil

        if useMockData {
            // Use mock data for offline development
            loadMockData()
            return
        }

        do {
            // Fetch real data from CoinGecko
            print("🔄 HomeViewModel: Fetching real crypto data...")
            let coins = try await cryptoAPI.fetchTrendingCoins(limit: 20)

            self.trendingCoins = coins
            self.featuredCoin = selectFeaturedCoin(from: coins)
            updatePrices()
            await calculatePortfolioMetrics()

            print("✅ HomeViewModel: Loaded \(coins.count) coins")
        } catch {
            print("❌ HomeViewModel: Failed to load coins - \(error.localizedDescription)")
            self.error = error.localizedDescription

            // Fallback to mock data if API fails
            print("⚠️ HomeViewModel: Falling back to mock data")
            loadMockData()
        }

        isLoading = false
    }

    /// Load mock data (for offline development or API failure fallback)
    private func loadMockData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.trendingCoins = MockData.coins
            self.featuredCoin = self.selectFeaturedCoin(from: MockData.coins)
            self.updatePrices()
            Task {
                await self.calculatePortfolioMetrics()
            }
            self.isLoading = false
        }
    }

    /// Refresh data (force refresh from API and reload portfolio)
    func refresh() async {
        await loadPortfolio()
        await loadData()
    }

    private func updatePrices() {
        for coin in trendingCoins {
            currentPrices[coin.id] = coin.currentPrice

            // CRITICAL: For viral coins, ALSO store by symbol so holdings can find them
            // Viral coins use contract addresses as IDs which CoinGecko doesn't know
            if coin.isViral {
                currentPrices[coin.symbol.uppercased()] = coin.currentPrice
                print("   💾 Viral coin price stored: ID='\(coin.id)' AND symbol='\(coin.symbol)' = $\(coin.currentPrice)")
            }
        }
    }

    func calculatePortfolioMetrics() async {
        await fetchMissingPricesForHoldings()
        await calculateMetrics()
    }

    /// Fetch prices for any held coins not in currentPrices or priced at $0
    private func fetchMissingPricesForHoldings() async {
        // Find coins in holdings that don't have current prices or have $0 prices
        let missingHoldings = portfolio.holdings.filter {
            let price = currentPrices[$0.coinId]
            return price == nil || price == 0.0
        }

        guard !missingHoldings.isEmpty else {
            print("   ✅ All holding prices already available")
            return
        }

        print("   🔍 Fetching prices for \(missingHoldings.count) held coins not in trending lists...")

        // Step 1: Check GeckoTerminal cache for viral coins (by symbol)
        let viralPrices = viralAPI.getCachedPrices(forSymbols: missingHoldings.map { $0.coinSymbol })

        var foundCount = 0
        for holding in missingHoldings {
            if let price = viralPrices[holding.coinSymbol] {
                currentPrices[holding.coinId] = price
                print("   ✅ Found viral coin price for \(holding.coinSymbol): $\(price)")
                foundCount += 1
            }
        }

        // Step 2: Try fetching viral coins by chainId + address from GeckoTerminal
        let stillMissing = missingHoldings.filter { currentPrices[$0.coinId] == nil }
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
                // Will try CoinGecko next
            }
        }

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
                    // Price unavailable - set to $0 to indicate failure
                    currentPrices[holding.coinId] = 0.0
                    print("   ⚠️ Price unavailable for \(holding.coinSymbol) - set to $0")
                }
            }
        } catch {
            print("   ❌ Failed to fetch held coin prices: \(error.localizedDescription)")
            // Set all missing coins to $0 to indicate price unavailable
            for holding in stillMissing2 {
                if currentPrices[holding.coinId] == nil {
                    currentPrices[holding.coinId] = 0.0
                    print("   ⚠️ Price unavailable for \(holding.coinSymbol) - set to $0")
                }
            }
        }
    }

    /// Calculate portfolio metrics using current prices
    private func calculateMetrics() async {
        print("🧮 Calculating portfolio metrics...")
        print("   💵 Cash balance: $\(portfolio.cashBalance)")
        print("   📊 Holdings count: \(portfolio.holdings.count)")

        let holdingsValue = portfolio.holdings.reduce(0) { total, holding in
            // Try coinId first, then symbol, then fallback to averageBuyPrice
            let priceById = currentPrices[holding.coinId]
            let priceBySymbol = currentPrices[holding.coinSymbol.uppercased()]
            let currentPrice = (priceById != nil && priceById! > 0) ? priceById! :
                              (priceBySymbol != nil && priceBySymbol! > 0) ? priceBySymbol! :
                              holding.averageBuyPrice

            let value = holding.quantity * currentPrice

            if currentPrice == holding.averageBuyPrice {
                print("   ⚠️ No current price for \(holding.coinSymbol), using avg buy price: $\(holding.averageBuyPrice)")
            } else {
                print("   📈 \(holding.coinSymbol): qty=\(holding.quantity), price=$\(currentPrice), value=$\(value), avgBuyPrice=$\(holding.averageBuyPrice)")
            }

            return total + value
        }

        print("   💎 Total holdings value: $\(holdingsValue)")
        netWorth = portfolio.cashBalance + holdingsValue
        print("   💰 Net worth: $\(netWorth)")

        dailyChange = portfolio.holdings.reduce(0) { total, holding in
            // Try coinId first, then symbol, then fallback to averageBuyPrice
            let priceById = currentPrices[holding.coinId]
            let priceBySymbol = currentPrices[holding.coinSymbol.uppercased()]
            let currentPrice = (priceById != nil && priceById! > 0) ? priceById! :
                              (priceBySymbol != nil && priceBySymbol! > 0) ? priceBySymbol! :
                              holding.averageBuyPrice

            let currentValue = holding.quantity * currentPrice
            let costBasis = holding.quantity * holding.averageBuyPrice
            return total + (currentValue - costBasis)
        }

        if netWorth > 0 && netWorth != dailyChange {
            dailyChangePercentage = (dailyChange / (netWorth - dailyChange)) * 100
        } else {
            dailyChangePercentage = 0
        }

        print("   📊 Daily change: $\(dailyChange) (\(dailyChangePercentage)%)")
    }

    /// Select featured "coin of the day"
    /// Returns nil if user has already skipped today's coin
    private func selectFeaturedCoin(from coins: [Coin]) -> Coin? {
        guard !coins.isEmpty else { return nil }

        // Check if user skipped today's coin
        if hasSkippedTodaysCoin() {
            print("⏭️ HomeViewModel: User already skipped today's coin, not showing featured coin")
            return nil
        }

        // Check if it's a new day or we don't have a saved coin
        if shouldShowNewFeaturedCoin() {
            // Pick a random coin for today
            let randomCoin = coins.randomElement()!
            saveFeaturedCoinForToday(coinId: randomCoin.id)
            print("🎲 HomeViewModel: Selected new featured coin for today: \(randomCoin.symbol)")
            return randomCoin
        }

        // Return the saved coin of the day
        if let savedCoinId = UserDefaults.standard.string(forKey: lastFeaturedCoinIdKey),
           let savedCoin = coins.first(where: { $0.id == savedCoinId }) {
            print("📌 HomeViewModel: Showing today's featured coin: \(savedCoin.symbol)")
            return savedCoin
        }

        // Fallback to random coin if saved coin not found
        let randomCoin = coins.randomElement()!
        saveFeaturedCoinForToday(coinId: randomCoin.id)
        return randomCoin
    }

    /// Check if it's a new day or we should show a new featured coin
    private func shouldShowNewFeaturedCoin() -> Bool {
        guard let lastDateString = UserDefaults.standard.string(forKey: lastFeaturedDateKey),
              let lastDate = ISO8601DateFormatter().date(from: lastDateString) else {
            // No saved date, show new coin
            return true
        }

        // Check if it's a new day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)

        return today > lastDay
    }

    /// Check if user has skipped today's featured coin
    private func hasSkippedTodaysCoin() -> Bool {
        guard let skipDateString = UserDefaults.standard.string(forKey: hasSkippedTodayKey),
              let skipDate = ISO8601DateFormatter().date(from: skipDateString) else {
            return false
        }

        // Check if the skip was today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let skipDay = calendar.startOfDay(for: skipDate)

        return today == skipDay
    }

    /// Save the featured coin for today
    private func saveFeaturedCoinForToday(coinId: String) {
        let dateString = ISO8601DateFormatter().string(from: Date())
        UserDefaults.standard.set(dateString, forKey: lastFeaturedDateKey)
        UserDefaults.standard.set(coinId, forKey: lastFeaturedCoinIdKey)
        UserDefaults.standard.removeObject(forKey: hasSkippedTodayKey) // Clear skip status
    }

    /// Skip today's featured coin - hides it until tomorrow or portfolio reset
    func skipFeaturedCoin() {
        guard let currentFeatured = featuredCoin else { return }

        print("⏭️ HomeViewModel: Skipping today's featured coin: \(currentFeatured.symbol)")

        // Mark as skipped with today's date
        let dateString = ISO8601DateFormatter().string(from: Date())
        UserDefaults.standard.set(dateString, forKey: hasSkippedTodayKey)

        // Hide the featured coin
        featuredCoin = nil

        HapticManager.shared.impact(.light)
        print("✅ HomeViewModel: Featured coin hidden until tomorrow or portfolio reset")
    }

    /// Reset featured coin state (called when portfolio is reset)
    func resetFeaturedCoinState() {
        UserDefaults.standard.removeObject(forKey: lastFeaturedDateKey)
        UserDefaults.standard.removeObject(forKey: lastFeaturedCoinIdKey)
        UserDefaults.standard.removeObject(forKey: hasSkippedTodayKey)
        print("🔄 HomeViewModel: Featured coin state reset")
    }

    func buy(coin: Coin, amount: Double) -> Bool {
        var updatedPortfolio = portfolio
        guard let transaction = updatedPortfolio.buy(coin: coin, amount: amount) else {
            print("❌ HomeViewModel: Buy failed - insufficient funds or invalid amount")
            return false
        }

        // Update local state first
        portfolio = updatedPortfolio
        currentPrices[coin.id] = coin.currentPrice

        // IMPORTANT: For viral coins, ALSO store price by symbol (holdings use symbol as fallback)
        if coin.isViral {
            currentPrices[coin.symbol.uppercased()] = coin.currentPrice
            print("🔥 HomeViewModel: Caching viral coin price by ID '\(coin.id)' AND symbol '\(coin.symbol)' = $\(coin.currentPrice)")
        }

        Task {
            await calculatePortfolioMetrics()
        }

        // Persist to Supabase in background
        Task {
            await persistBuyTransaction(transaction: transaction, updatedPortfolio: updatedPortfolio)
        }

        HapticManager.shared.success()
        return true
    }

    /// Persist buy transaction to Supabase
    private func persistBuyTransaction(transaction: Transaction, updatedPortfolio: Portfolio) async {
        do {
            print("💾 HomeViewModel: Persisting transaction to Supabase...")

            // 1. Create transaction
            _ = try await dataService.createTransaction(transaction)
            print("   ✅ Transaction created: \(transaction.coinId) x \(transaction.quantity)")

            // 2. Update or create holding
            if let holding = updatedPortfolio.holdings.first(where: { $0.coinId == transaction.coinId }) {
                print("   🔄 Upserting holding: \(holding.coinId), qty: \(holding.quantity), avg price: \(holding.averageBuyPrice)")
                _ = try await dataService.upsertHolding(holding)
                print("   ✅ Holding updated: \(holding.coinId)")
            } else {
                print("   ⚠️ No holding found for \(transaction.coinId)")
            }

            // 3. Update portfolio cash balance
            print("   🔄 Updating portfolio cash balance to $\(updatedPortfolio.cashBalance)")
            _ = try await dataService.updatePortfolio(updatedPortfolio)
            print("   ✅ Portfolio updated: cash balance = $\(updatedPortfolio.cashBalance)")

            print("✅ HomeViewModel: Transaction persisted successfully")
        } catch {
            print("❌ HomeViewModel: Failed to persist transaction - \(error.localizedDescription)")
            print("   Error details: \(error)")
            // TODO: Could implement retry logic or show error to user
        }
    }

    /// Reset portfolio to starting state (delete all holdings and transactions, reset cash)
    func resetPortfolio() async {
        print("🔄 HomeViewModel: Resetting portfolio...")

        do {
            // 1. Delete all holdings from database
            print("   🗑️ Deleting all holdings...")
            try await dataService.deleteAllHoldings(portfolioId: portfolio.id)
            print("   ✅ All holdings deleted")

            // 2. Delete all transactions from database
            print("   🗑️ Deleting all transactions...")
            try await dataService.deleteAllTransactions(portfolioId: portfolio.id)
            print("   ✅ All transactions deleted")

            // 3. Reset portfolio cash balance to starting balance
            var resetPortfolio = portfolio
            resetPortfolio.cashBalance = portfolio.startingBalance
            resetPortfolio.holdings = []
            resetPortfolio.transactions = []
            resetPortfolio.updatedAt = Date()

            print("   💵 Resetting cash to $\(portfolio.startingBalance)")

            // 4. Update portfolio in database
            _ = try await dataService.updatePortfolio(resetPortfolio)
            print("   ✅ Portfolio updated in database")

            // 5. Update local state
            self.portfolio = resetPortfolio
            self.netWorth = resetPortfolio.cashBalance
            self.dailyChange = 0
            self.dailyChangePercentage = 0

            // 6. Reset featured coin state - show new coin after reset
            resetFeaturedCoinState()
            if !trendingCoins.isEmpty {
                self.featuredCoin = selectFeaturedCoin(from: trendingCoins)
            }

            print("✅ HomeViewModel: Portfolio reset complete")
            print("   💵 Cash: $\(portfolio.cashBalance)")
            print("   📊 Holdings: \(portfolio.holdings.count)")
            print("   💰 Net worth: $\(netWorth)")
            print("   🎲 Featured coin reset: \(featuredCoin?.symbol ?? "none")")

            HapticManager.shared.success()
        } catch {
            print("❌ HomeViewModel: Failed to reset portfolio - \(error.localizedDescription)")
            print("   Error details: \(error)")
            HapticManager.shared.error()
            // TODO: Show error to user
        }
    }
}
