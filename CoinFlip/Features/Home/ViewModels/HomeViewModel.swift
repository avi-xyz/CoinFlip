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
    private let useMockData: Bool

    init(portfolio: Portfolio, cryptoAPI: CryptoAPIService = .shared, useMockData: Bool = false) {
        self.portfolio = portfolio
        self.netWorth = portfolio.cashBalance
        self.cryptoAPI = cryptoAPI
        self.useMockData = useMockData
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

    /// Refresh data (force refresh from API)
    func refresh() async {
        await loadData()
    }

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
