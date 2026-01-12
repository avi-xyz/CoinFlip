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

    private let cryptoAPI: CryptoAPIService
    private let dataService: DataServiceProtocol
    private let authService = AuthService.shared
    private let useMockData: Bool
    private var cancellables = Set<AnyCancellable>()

    init(portfolio: Portfolio, cryptoAPI: CryptoAPIService = .shared, dataService: DataServiceProtocol = SupabaseDataService.shared, useMockData: Bool = false) {
        self.portfolio = portfolio
        self.netWorth = portfolio.cashBalance
        self.cryptoAPI = cryptoAPI
        self.dataService = dataService
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
            calculatePortfolioMetrics()
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
            self.featuredCoin = coins.first
            updatePrices()
            calculatePortfolioMetrics()

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
            self?.featuredCoin = MockData.featuredCoin
            self?.trendingCoins = MockData.coins
            self?.updatePrices()
            self?.calculatePortfolioMetrics()
            self?.isLoading = false
        }
    }

    /// Refresh data (force refresh from API and reload portfolio)
    func refresh() async {
        await loadPortfolio()
        await loadData()
    }

    private func updatePrices() {
        for coin in trendingCoins { currentPrices[coin.id] = coin.currentPrice }
    }

    func calculatePortfolioMetrics() {
        print("🧮 Calculating portfolio metrics...")
        print("   💵 Cash balance: $\(portfolio.cashBalance)")
        print("   📊 Holdings count: \(portfolio.holdings.count)")

        let holdingsValue = portfolio.holdings.reduce(0) { total, holding in
            guard let currentPrice = currentPrices[holding.coinId] else {
                print("   ⚠️ No current price for \(holding.coinId), using avg buy price: $\(holding.averageBuyPrice)")
                return total + (holding.quantity * holding.averageBuyPrice)
            }
            let value = holding.quantity * currentPrice
            print("   📈 \(holding.coinSymbol): qty=\(holding.quantity), price=$\(currentPrice), value=$\(value), avgBuyPrice=$\(holding.averageBuyPrice)")
            return total + value
        }

        print("   💎 Total holdings value: $\(holdingsValue)")
        netWorth = portfolio.cashBalance + holdingsValue
        print("   💰 Net worth: $\(netWorth)")

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

        print("   📊 Daily change: $\(dailyChange) (\(dailyChangePercentage)%)")
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
        calculatePortfolioMetrics()

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
}
