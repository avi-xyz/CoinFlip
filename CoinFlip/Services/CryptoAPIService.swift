//
//  CryptoAPIService.swift
//  CoinFlip
//
//  Created on Sprint 13
//  Real-time cryptocurrency price data from CoinGecko API
//

import Foundation

/// Service for fetching real-time cryptocurrency data from CoinGecko API
///
/// CoinGecko Free API:
/// - No API key required
/// - Rate limit: 50 calls/minute
/// - Data: Top 250+ cryptocurrencies
@MainActor
class CryptoAPIService {

    // MARK: - Properties

    static let shared = CryptoAPIService()

    private let baseURL = "https://api.coingecko.com/api/v3"
    private let session: URLSession

    // Cache
    private var cachedCoins: [Coin] = []
    private var lastFetchTime: Date?
    private let cacheValidDuration: TimeInterval = 60 // 60 seconds

    // Price cache with 5-minute TTL
    private var priceCache: [String: (price: Double, timestamp: Date)] = [:]
    private let priceCacheDuration: TimeInterval = 300 // 5 minutes

    // MARK: - DEBUG: API Call Counter
    /// Set to true to enable API call logging for debugging rate limits
    static var enableAPICallLogging = false

    private var apiCallCount: Int = 0
    private var sessionStartTime: Date = Date()

    private func incrementCallCount(endpoint: String) {
        apiCallCount += 1
        guard Self.enableAPICallLogging else { return }
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        print("📈 [CoinGecko] API call #\(apiCallCount) (session: \(elapsed)s) - \(endpoint)")
    }

    private func logRateLimitHit(endpoint: String) {
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        // Always log rate limit hits, even if logging is disabled
        print("🚨🚨🚨 [CoinGecko] RATE LIMIT HIT 🚨🚨🚨")
        print("   📊 Total API calls this session: \(apiCallCount)")
        print("   ⏱️  Session duration: \(elapsed) seconds")
        print("   📍 Endpoint: \(endpoint)")
        print("   📉 Calls per minute: \(elapsed > 0 ? Double(apiCallCount) / Double(elapsed) * 60 : 0)")

        // Log to Supabase for production monitoring
        Task {
            await APIRateLimitLogger.shared.logRateLimitEvent(
                apiName: "CoinGecko",
                endpoint: endpoint,
                callCount: apiCallCount,
                sessionDuration: elapsed
            )
        }
    }

    /// Log current stats (called by GeckoTerminalService when it hits rate limit)
    func logCurrentStats() {
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        // Always log when called (rate limit hit)
        print("📊 [CoinGecko] Current stats: \(apiCallCount) calls in \(elapsed)s")
    }

    /// Track external calls made to CoinGecko from other services (e.g., image search)
    func trackExternalCall(endpoint: String) {
        incrementCallCount(endpoint: endpoint)
    }

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Fetch trending/top coins with current prices
    ///
    /// - Parameters:
    ///   - limit: Number of coins to fetch (default: 20)
    ///   - forceRefresh: Skip cache and fetch from API
    /// - Returns: Array of coins with current market data
    func fetchTrendingCoins(limit: Int = 20, forceRefresh: Bool = false) async throws -> [Coin] {
        print("🪙 CryptoAPIService: Fetching coins...")

        // Check if offline - return cache if available
        if !NetworkMonitor.shared.isConnected {
            if !cachedCoins.isEmpty {
                print("   📵 Offline - returning cached coins (\(cachedCoins.count) available)")
                return Array(cachedCoins.prefix(limit))
            } else {
                print("   ❌ Offline and no cached data available")
                throw CryptoAPIError.networkError(NSError(domain: "NetworkMonitor", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "No internet connection. Please check your network settings."
                ]))
            }
        }

        // Check cache first
        if !forceRefresh, let lastFetch = lastFetchTime {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch < cacheValidDuration, !cachedCoins.isEmpty {
                print("   ✅ Returning cached coins (age: \(Int(timeSinceLastFetch))s)")
                return Array(cachedCoins.prefix(limit))
            }
        }

        // Build URL
        let endpoint = "\(baseURL)/coins/markets"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "order", value: "market_cap_desc"),
            URLQueryItem(name: "per_page", value: "\(limit)"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "sparkline", value: "true"),
            URLQueryItem(name: "price_change_percentage", value: "24h")
        ]

        guard let url = components.url else {
            throw CryptoAPIError.invalidURL
        }

        print("   🌐 Fetching from: \(url)")
        incrementCallCount(endpoint: "coins/markets")

        // Make request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CryptoAPIError.invalidResponse
        }

        print("   📥 Response: HTTP \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                logRateLimitHit(endpoint: "coins/markets")
                throw CryptoAPIError.rateLimitExceeded
            }
            throw CryptoAPIError.httpError(httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        // Don't use convertFromSnakeCase - we have explicit CodingKeys

        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("   📄 Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
        }

        let coinGeckoCoins: [CoinGeckoResponse]
        do {
            coinGeckoCoins = try decoder.decode([CoinGeckoResponse].self, from: data)
        } catch {
            print("   ❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   ❌ Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   ❌ Type '\(type)' mismatch: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   ❌ Value '\(type)' not found: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   ❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   ❌ Unknown decoding error")
                }
            }
            throw error
        }

        // Convert to our Coin model
        let coins = coinGeckoCoins.map { $0.toCoin() }

        // Update cache
        self.cachedCoins = coins
        self.lastFetchTime = Date()

        print("   ✅ Fetched \(coins.count) coins")
        return coins
    }

    /// Get current price for a specific coin
    ///
    /// - Parameter coinId: CoinGecko coin ID (e.g., "bitcoin", "ethereum")
    /// - Returns: Current price in USD
    func fetchCoinPrice(coinId: String) async throws -> Double {
        // Check if offline - return cached price if available
        if !NetworkMonitor.shared.isConnected {
            if let cachedCoin = cachedCoins.first(where: { $0.id == coinId }) {
                print("   📵 Offline - returning cached price for \(coinId)")
                return cachedCoin.currentPrice
            } else {
                throw CryptoAPIError.networkError(NSError(domain: "NetworkMonitor", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "No internet connection"
                ]))
            }
        }

        // Check if coin is in cache
        if let cachedCoin = cachedCoins.first(where: { $0.id == coinId }),
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidDuration {
            return cachedCoin.currentPrice
        }

        // Fetch from API
        let endpoint = "\(baseURL)/simple/price"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "ids", value: coinId),
            URLQueryItem(name: "vs_currencies", value: "usd")
        ]

        guard let url = components.url else {
            throw CryptoAPIError.invalidURL
        }

        incrementCallCount(endpoint: "simple/price")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CryptoAPIError.invalidResponse
        }

        if httpResponse.statusCode == 429 {
            logRateLimitHit(endpoint: "simple/price")
            throw CryptoAPIError.rateLimitExceeded
        }

        guard httpResponse.statusCode == 200 else {
            throw CryptoAPIError.invalidResponse
        }

        let priceResponse = try JSONDecoder().decode([String: [String: Double]].self, from: data)

        guard let price = priceResponse[coinId]?["usd"] else {
            throw CryptoAPIError.coinNotFound
        }

        return price
    }

    /// Get current prices for multiple coins (with 5-minute cache)
    ///
    /// - Parameter coinIds: Array of CoinGecko coin IDs
    /// - Returns: Dictionary mapping coin ID to current price
    func fetchPrices(for coinIds: [String]) async throws -> [String: Double] {
        guard !coinIds.isEmpty else { return [:] }

        print("💰 CryptoAPIService: Fetching prices for \(coinIds.count) coins...")

        // Check cache first
        var prices: [String: Double] = [:]
        var coinsToFetch: [String] = []
        let now = Date()

        for coinId in coinIds {
            if let cached = priceCache[coinId],
               now.timeIntervalSince(cached.timestamp) < priceCacheDuration {
                // Use cached price
                prices[coinId] = cached.price
                print("   ✅ Using cached price for \(coinId): $\(cached.price)")
            } else {
                // Need to fetch
                coinsToFetch.append(coinId)
            }
        }

        // If all prices are cached, return immediately
        if coinsToFetch.isEmpty {
            print("   ✅ All prices from cache")
            return prices
        }

        print("   🌐 Fetching \(coinsToFetch.count) prices from API...")

        // Check if offline
        if !NetworkMonitor.shared.isConnected {
            print("   📵 Offline - returning cached prices only")
            // Return what we have in cache, even if stale
            for coinId in coinsToFetch {
                if let cached = priceCache[coinId] {
                    prices[coinId] = cached.price
                    print("   ⚠️ Using stale cached price for \(coinId): $\(cached.price)")
                }
            }
            return prices
        }

        // Fetch missing prices from API
        let idsString = coinsToFetch.joined(separator: ",")

        let endpoint = "\(baseURL)/simple/price"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "ids", value: idsString),
            URLQueryItem(name: "vs_currencies", value: "usd")
        ]

        guard let url = components.url else {
            throw CryptoAPIError.invalidURL
        }

        incrementCallCount(endpoint: "simple/price (batch)")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CryptoAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                logRateLimitHit(endpoint: "simple/price (batch)")
                throw CryptoAPIError.rateLimitExceeded
            }
            throw CryptoAPIError.httpError(httpResponse.statusCode)
        }

        let priceResponse = try JSONDecoder().decode([String: [String: Double]].self, from: data)

        // Update cache and prices dictionary
        for (coinId, currencies) in priceResponse {
            if let usdPrice = currencies["usd"] {
                prices[coinId] = usdPrice
                priceCache[coinId] = (price: usdPrice, timestamp: now)
                print("   ✅ Fetched price for \(coinId): $\(usdPrice)")
            }
        }

        print("   ✅ Total prices returned: \(prices.count)")
        return prices
    }

    /// Clear cached data
    func clearCache() {
        cachedCoins = []
        lastFetchTime = nil
        priceCache = [:]
        print("🗑️ CryptoAPIService: Cache cleared")
    }
}

// MARK: - CoinGecko Response Model

/// Response model from CoinGecko /coins/markets endpoint
private struct CoinGeckoResponse: Codable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let priceChange24h: Double?  // Can be null for some coins
    let priceChangePercentage24h: Double?  // Can be null for some coins
    let marketCap: Double
    let sparklineIn7d: CoinGeckoSparkline?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case priceChange24h = "price_change_24h"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case marketCap = "market_cap"
        case sparklineIn7d = "sparkline_in_7d"
    }

    func toCoin() -> Coin {
        Coin(
            id: id,
            symbol: symbol.uppercased(),
            name: name,
            image: URL(string: image),
            currentPrice: currentPrice,
            priceChange24h: priceChange24h ?? 0.0,  // Default to 0 if null
            priceChangePercentage24h: priceChangePercentage24h ?? 0.0,  // Default to 0 if null
            marketCap: marketCap,
            sparklineIn7d: sparklineIn7d?.toSparklineData()
        )
    }
}

private struct CoinGeckoSparkline: Codable {
    let price: [Double]

    func toSparklineData() -> SparklineData {
        SparklineData(price: price)
    }
}

// MARK: - Errors

enum CryptoAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case rateLimitExceeded
    case coinNotFound
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .coinNotFound:
            return "Cryptocurrency not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
