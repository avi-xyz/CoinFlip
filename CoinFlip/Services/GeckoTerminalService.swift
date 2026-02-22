//
//  GeckoTerminalService.swift
//  CoinFlip
//
//  Service for fetching viral trending meme coins from GeckoTerminal API
//  GeckoTerminal tracks trending pools across 200+ blockchains
//

import Foundation

/// Service for fetching trending cryptocurrency pools from GeckoTerminal API
///
/// GeckoTerminal API (Beta):
/// - Free API, no key required
/// - Rate limit: Not publicly documented
/// - Update frequency: 30 seconds for trending data
/// - Coverage: 200+ networks, 1,500+ DEXes
@MainActor
class GeckoTerminalService {

    // MARK: - Properties

    static let shared = GeckoTerminalService()

    private let baseURL = "https://api.geckoterminal.com/api/v2"
    private let session: URLSession

    // Cache for viral coins
    private var cachedViralCoins: [Coin] = []
    private var lastFetchTime: Date?
    private let cacheValidDuration: TimeInterval = 30 // 30 seconds (matches API update frequency)

    // Cache for OHLCV data
    private var ohlcvCache: [String: (data: [Double], timestamp: Date)] = [:]
    private let ohlcvCacheValidDuration: TimeInterval = 300 // 5 minutes for historical data

    // MARK: - DEBUG: API Call Counter
    /// Set to true to enable API call logging for debugging rate limits
    static var enableAPICallLogging = false

    private var apiCallCount: Int = 0
    private var sessionStartTime: Date = Date()

    private func incrementCallCount(endpoint: String) {
        apiCallCount += 1
        guard Self.enableAPICallLogging else { return }
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        print("📈 [GeckoTerminal] API call #\(apiCallCount) (session: \(elapsed)s) - \(endpoint)")
    }

    private func logRateLimitHit(endpoint: String) {
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        // Always log rate limit hits, even if logging is disabled
        print("🚨🚨🚨 [GeckoTerminal] RATE LIMIT HIT 🚨🚨🚨")
        print("   📊 Total API calls this session: \(apiCallCount)")
        print("   ⏱️  Session duration: \(elapsed) seconds")
        print("   📍 Endpoint: \(endpoint)")
        print("   📉 Calls per minute: \(elapsed > 0 ? Double(apiCallCount) / Double(elapsed) * 60 : 0)")

        // Also log CoinGecko stats for comparison
        CryptoAPIService.shared.logCurrentStats()

        // Log to Supabase for production monitoring
        Task {
            await APIRateLimitLogger.shared.logRateLimitEvent(
                apiName: "GeckoTerminal",
                endpoint: endpoint,
                callCount: apiCallCount,
                sessionDuration: elapsed
            )
        }
    }

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Fetch viral/trending coins from trending pools across all networks
    ///
    /// - Parameters:
    ///   - limit: Number of coins to fetch (default: 20)
    ///   - forceRefresh: Skip cache and fetch from API
    /// - Returns: Array of viral coins filtered by criteria
    func fetchViralCoins(limit: Int = 20, forceRefresh: Bool = false) async throws -> [Coin] {
        print("🔥 GeckoTerminalService: Fetching viral coins...")

        // Check if offline - return cache if available
        if !NetworkMonitor.shared.isConnected {
            if !cachedViralCoins.isEmpty {
                print("   📵 Offline - returning cached viral coins (\(cachedViralCoins.count) available)")
                return Array(cachedViralCoins.prefix(limit))
            } else {
                print("   ❌ Offline and no cached data available")
                throw GeckoTerminalError.networkError(NSError(domain: "NetworkMonitor", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "No internet connection. Please check your network settings."
                ]))
            }
        }

        // Check cache first
        if !forceRefresh, let lastFetch = lastFetchTime {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            if timeSinceLastFetch < cacheValidDuration, !cachedViralCoins.isEmpty {
                print("   ✅ Returning cached viral coins (age: \(Int(timeSinceLastFetch))s)")
                return Array(cachedViralCoins.prefix(limit))
            }
        }

        // Build URL for trending pools (all networks)
        let endpoint = "\(baseURL)/networks/trending_pools"
        guard let url = URL(string: endpoint) else {
            throw GeckoTerminalError.invalidURL
        }

        print("   🌐 Fetching from: \(url)")
        incrementCallCount(endpoint: "trending_pools")

        // Make request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeckoTerminalError.invalidResponse
        }

        print("   📥 Response: HTTP \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                logRateLimitHit(endpoint: "trending_pools")
                throw GeckoTerminalError.rateLimitExceeded
            }
            throw GeckoTerminalError.httpError(httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let poolsResponse: GeckoTerminalPoolsResponse
        do {
            poolsResponse = try decoder.decode(GeckoTerminalPoolsResponse.self, from: data)
        } catch {
            print("   ❌ Decoding error: \(error)")
            throw error
        }

        // Convert to our Coin model and apply viral filtering
        var allCoins = poolsResponse.data.compactMap { $0.toCoin() }

        // Fetch coin images (uses persistent cache - only fetches new coins)
        await enrichCoinsWithImages(&allCoins)

        // Filter for viral coins based on criteria
        let viralCoins = filterViralCoins(from: allCoins)

        // Sort by virality score (highest first)
        let sortedCoins = viralCoins.sorted { calculateViralityScore($0) > calculateViralityScore($1) }

        // Update cache
        self.cachedViralCoins = sortedCoins
        self.lastFetchTime = Date()

        print("   ✅ Fetched \(allCoins.count) pools, filtered to \(sortedCoins.count) viral coins")
        return Array(sortedCoins.prefix(limit))
    }

    // MARK: - Image Enrichment (with persistent caching)

    /// Persistent cache for coin images (symbol -> URL string)
    private var imageCache: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: "coinImageCache") as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "coinImageCache") }
    }

    /// Enrich coins with images - uses persistent cache, only fetches new coins
    private func enrichCoinsWithImages(_ coins: inout [Coin]) async {
        var cache = imageCache
        var fetchCount = 0

        for (index, coin) in coins.enumerated() {
            let symbolKey = coin.symbol.uppercased()

            // Check persistent cache first
            if let cachedURLString = cache[symbolKey],
               let cachedURL = URL(string: cachedURLString) {
                // Use cached image
                coins[index] = coinWithImage(coin, imageURL: cachedURL)
                continue
            }

            // Not in cache - fetch from CoinGecko (rate limited)
            guard let imageURL = await fetchCoinImageFromCoinGecko(symbol: coin.symbol) else {
                continue
            }

            // Update coin and cache
            coins[index] = coinWithImage(coin, imageURL: imageURL)
            cache[symbolKey] = imageURL.absoluteString
            fetchCount += 1

            // Small delay between API calls to respect rate limits
            if fetchCount < coins.count {
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 second delay
            }
        }

        // Save updated cache
        if fetchCount > 0 {
            imageCache = cache
            print("   🖼️  Fetched \(fetchCount) new coin images (cached \(cache.count) total)")
        } else {
            print("   🖼️  All \(coins.count) coin images loaded from cache")
        }
    }

    /// Create a new Coin with the given image URL
    private func coinWithImage(_ coin: Coin, imageURL: URL) -> Coin {
        Coin(
            id: coin.id,
            symbol: coin.symbol,
            name: coin.name,
            image: imageURL,
            currentPrice: coin.currentPrice,
            priceChange24h: coin.priceChange24h,
            priceChangePercentage24h: coin.priceChangePercentage24h,
            marketCap: coin.marketCap,
            sparklineIn7d: coin.sparklineIn7d,
            poolCreatedAt: coin.poolCreatedAt,
            priceChangeH1: coin.priceChangeH1,
            hourlyBuys: coin.hourlyBuys,
            hourlySells: coin.hourlySells,
            txnsH1: coin.txnsH1,
            volumeH1: coin.volumeH1,
            chainId: coin.chainId,
            isViral: coin.isViral
        )
    }

    /// Fetch coin image from CoinGecko search API
    private func fetchCoinImageFromCoinGecko(symbol: String) async -> URL? {
        let searchURL = "https://api.coingecko.com/api/v3/search?query=\(symbol)"

        guard let url = URL(string: searchURL) else { return nil }

        // Track this as a CoinGecko call
        CryptoAPIService.shared.trackExternalCall(endpoint: "search (image)")

        do {
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            let searchResult = try decoder.decode(CoinGeckoSearchResponse.self, from: data)

            // Find exact symbol match (case-insensitive)
            if let match = searchResult.coins.first(where: { $0.symbol.lowercased() == symbol.lowercased() }),
               let imageURLString = match.large,
               let imageURL = URL(string: imageURLString) {
                return imageURL
            }
        } catch {
            // Silently fail - images are best effort
        }

        return nil
    }

    // MARK: - Private Methods

    /// Filter coins based on viral criteria
    ///
    /// Criteria:
    /// - Price change > 50% in last hour OR
    /// - High transaction volume (>100 txns in last hour) OR
    /// - New pool (created < 1 hour ago) OR
    /// - Combination of strong signals
    private func filterViralCoins(from coins: [Coin]) -> [Coin] {
        let oneHourAgo = Date().addingTimeInterval(-3600)

        return coins.filter { coin in
            // Criteria 1: Major price spike in last hour
            let hasPriceSpike = (coin.priceChangeH1 ?? 0) > 50

            // Criteria 2: High transaction volume
            let hasHighVolume = (coin.txnsH1 ?? 0) > 100

            // Criteria 3: New launch (if we have creation date)
            let isNewLaunch = if let createdAt = coin.poolCreatedAt {
                createdAt > oneHourAgo
            } else {
                false
            }

            // Criteria 4: Strong combined signals
            let hasStrongSignals = (coin.priceChangeH1 ?? 0) > 25 && (coin.txnsH1 ?? 0) > 50

            // Pass if any criteria met
            return hasPriceSpike || hasHighVolume || isNewLaunch || hasStrongSignals
        }
    }

    /// Calculate virality score for ranking
    ///
    /// Formula: (priceChangeH1 * 0.4) + (txnsH1 * 0.3) + (volumeH1/10000 * 0.3)
    private func calculateViralityScore(_ coin: Coin) -> Double {
        let priceScore = (coin.priceChangeH1 ?? 0) * 0.4
        let txnScore = Double(coin.txnsH1 ?? 0) * 0.3
        let volumeScore = (coin.volumeH1 ?? 0) / 10000 * 0.3

        return priceScore + txnScore + volumeScore
    }

    /// Get current price for a viral coin from cache by symbol
    /// Returns nil if coin not in cache
    func getCachedPrice(forSymbol symbol: String) -> Double? {
        print("🔍 GeckoTerminalService.getCachedPrice for symbol: '\(symbol)'")
        print("   Cache has \(cachedViralCoins.count) coins: \(cachedViralCoins.map { $0.symbol }.joined(separator: ", "))")

        let matchingCoin = cachedViralCoins.first { $0.symbol.uppercased() == symbol.uppercased() }

        if let coin = matchingCoin {
            print("   ✅ Found match: \(coin.symbol) = $\(coin.currentPrice)")
        } else {
            print("   ❌ No match found for '\(symbol)'")
        }

        return matchingCoin?.currentPrice
    }

    /// Get current prices for multiple viral coins from cache
    /// Returns dictionary of symbol -> price for coins found in cache
    func getCachedPrices(forSymbols symbols: [String]) -> [String: Double] {
        print("🔍 GeckoTerminalService.getCachedPrices for \(symbols.count) symbols")
        var prices: [String: Double] = [:]

        for symbol in symbols {
            if let price = getCachedPrice(forSymbol: symbol) {
                prices[symbol] = price
            }
        }

        print("   Found \(prices.count) prices in viral cache")
        return prices
    }

    /// Fetch current price for a specific token by network and contract address
    ///
    /// - Parameters:
    ///   - network: Network identifier (e.g., "solana", "eth", "base")
    ///   - address: Token contract address
    /// - Returns: Current token price in USD
    func fetchTokenPrice(network: String, address: String) async throws -> Double {
        print("💰 GeckoTerminalService: Fetching price for token \(address) on \(network)...")

        // Check if offline
        if !NetworkMonitor.shared.isConnected {
            print("   ❌ Offline - cannot fetch token price")
            throw GeckoTerminalError.networkError(NSError(domain: "NetworkMonitor", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "No internet connection. Please check your network settings."
            ]))
        }

        // Build URL for token endpoint
        let endpoint = "\(baseURL)/networks/\(network)/tokens/\(address)"
        guard let url = URL(string: endpoint) else {
            throw GeckoTerminalError.invalidURL
        }

        print("   🌐 Fetching from: \(url)")
        incrementCallCount(endpoint: "token_price")

        // Make request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeckoTerminalError.invalidResponse
        }

        print("   📥 Response: HTTP \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                logRateLimitHit(endpoint: "token_price")
                throw GeckoTerminalError.rateLimitExceeded
            }
            if httpResponse.statusCode == 404 {
                throw GeckoTerminalError.poolNotFound
            }
            throw GeckoTerminalError.httpError(httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let tokenResponse: GeckoTerminalTokenResponse
        do {
            tokenResponse = try decoder.decode(GeckoTerminalTokenResponse.self, from: data)
        } catch {
            print("   ❌ Decoding error: \(error)")
            throw error
        }

        // Extract price from attributes
        guard let priceString = tokenResponse.data.attributes.priceUsd,
              let price = Double(priceString) else {
            print("   ❌ Failed to parse price from response")
            throw GeckoTerminalError.invalidResponse
        }

        print("   ✅ Fetched price: $\(price)")
        return price
    }

    /// Remove a specific coin from the cache (for testing)
    func removeCoinFromCache(symbol: String) {
        cachedViralCoins.removeAll { $0.symbol.uppercased() == symbol.uppercased() }
        print("🗑️ GeckoTerminalService: Removed \(symbol) from cache")
    }

    /// Clear cached data
    func clearCache() {
        cachedViralCoins = []
        lastFetchTime = nil
        print("🗑️ GeckoTerminalService: Cache cleared")
    }

    /// Fetch OHLCV (candlestick) data for a specific pool
    ///
    /// - Parameters:
    ///   - network: Network identifier (e.g., "solana", "eth", "base")
    ///   - poolAddress: Pool contract address
    ///   - timeframe: Candle timeframe - "minute", "hour", or "day" (default: "hour")
    ///   - limit: Number of candles to fetch (default: 48)
    /// - Returns: Array of closing prices for sparkline display
    func fetchPoolOHLCV(network: String, poolAddress: String, timeframe: String = "hour", limit: Int = 48) async throws -> [Double] {
        let cacheKey = "\(network)_\(poolAddress)_\(timeframe)"
        print("📊 GeckoTerminalService: Fetching OHLCV for pool \(poolAddress) on \(network)...")

        // Check cache first
        if let cached = ohlcvCache[cacheKey] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < ohlcvCacheValidDuration {
                print("   ✅ Returning cached OHLCV data (age: \(Int(age))s)")
                return cached.data
            }
        }

        // Check if offline
        if !NetworkMonitor.shared.isConnected {
            // Return cached data if available, even if stale
            if let cached = ohlcvCache[cacheKey] {
                print("   📵 Offline - returning stale cached OHLCV data")
                return cached.data
            }
            print("   ❌ Offline - cannot fetch OHLCV data")
            throw GeckoTerminalError.networkError(NSError(domain: "NetworkMonitor", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "No internet connection. Please check your network settings."
            ]))
        }

        // Retry with exponential backoff for rate limits
        var lastError: Error?
        for attempt in 0..<3 {
            if attempt > 0 {
                let delay = pow(2.0, Double(attempt)) // 2s, 4s
                print("   ⏳ Rate limited, waiting \(Int(delay))s before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            do {
                let prices = try await performOHLCVFetch(network: network, poolAddress: poolAddress, timeframe: timeframe, limit: limit)

                // Cache the result
                ohlcvCache[cacheKey] = (data: prices, timestamp: Date())

                return prices
            } catch GeckoTerminalError.rateLimitExceeded {
                lastError = GeckoTerminalError.rateLimitExceeded
                print("   ⚠️ Rate limit hit (attempt \(attempt + 1)/3)")
                continue
            } catch {
                throw error
            }
        }

        // If all retries failed, return cached data if available
        if let cached = ohlcvCache[cacheKey] {
            print("   ⚠️ All retries failed, returning stale cached data")
            return cached.data
        }

        throw lastError ?? GeckoTerminalError.rateLimitExceeded
    }

    /// Internal method to perform the actual OHLCV API call
    private func performOHLCVFetch(network: String, poolAddress: String, timeframe: String, limit: Int) async throws -> [Double] {
        // Build URL for OHLCV endpoint
        let endpoint = "\(baseURL)/networks/\(network)/pools/\(poolAddress)/ohlcv/\(timeframe)?aggregate=1&limit=\(limit)"
        guard let url = URL(string: endpoint) else {
            throw GeckoTerminalError.invalidURL
        }

        print("   🌐 Fetching from: \(url)")
        incrementCallCount(endpoint: "ohlcv")

        // Make request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeckoTerminalError.invalidResponse
        }

        print("   📥 Response: HTTP \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                logRateLimitHit(endpoint: "ohlcv")
                throw GeckoTerminalError.rateLimitExceeded
            }
            if httpResponse.statusCode == 404 {
                throw GeckoTerminalError.poolNotFound
            }
            throw GeckoTerminalError.httpError(httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let ohlcvResponse: GeckoTerminalOHLCVResponse
        do {
            ohlcvResponse = try decoder.decode(GeckoTerminalOHLCVResponse.self, from: data)
        } catch {
            print("   ❌ Decoding error: \(error)")
            throw error
        }

        // Extract closing prices from OHLCV data
        // OHLCV array format: [timestamp, open, high, low, close, volume]
        let closingPrices = ohlcvResponse.data.attributes.ohlcvList.compactMap { candle -> Double? in
            guard candle.count >= 5 else { return nil }
            return candle[4] // Index 4 is close price
        }

        print("   ✅ Fetched \(closingPrices.count) price points")
        return closingPrices
    }
}

// MARK: - GeckoTerminal Response Models

/// Response model from GeckoTerminal /networks/trending_pools endpoint
private struct GeckoTerminalPoolsResponse: Codable {
    let data: [GeckoTerminalPool]
}

/// Pool data from GeckoTerminal
private struct GeckoTerminalPool: Codable {
    let id: String
    let type: String
    let attributes: PoolAttributes

    struct PoolAttributes: Codable {
        let name: String
        let address: String
        let poolCreatedAt: String?
        let baseTokenPriceUsd: String?
        let fdvUsd: String?
        let priceChangePercentage: PriceChangePercentage?
        let transactions: Transactions?
        let volumeUsd: VolumeUsd?
        let reserveInUsd: String?
    }

    struct PriceChangePercentage: Codable {
        let h1: String?
        let h24: String?
    }

    struct Transactions: Codable {
        let h1: TransactionCount?
        let h24: TransactionCount?
    }

    struct TransactionCount: Codable {
        let buys: Int?
        let sells: Int?
    }

    struct VolumeUsd: Codable {
        let h1: String?
        let h24: String?
    }

    /// Convert GeckoTerminal pool to our Coin model
    func toCoin() -> Coin? {
        // Parse pool name to extract token symbol and name
        // Format is typically "TOKEN / QUOTE" or "TokenName / Quote"
        let components = attributes.name.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard components.count >= 1 else { return nil }

        let tokenName = String(components[0])
        let symbol = String(components[0]).uppercased()

        // Parse price
        guard let priceString = attributes.baseTokenPriceUsd,
              let price = Double(priceString) else {
            return nil
        }

        // Parse price changes
        let priceChangeH1 = attributes.priceChangePercentage?.h1.flatMap { Double($0) }
        let priceChange24h = attributes.priceChangePercentage?.h24.flatMap { Double($0) } ?? 0

        // Parse transaction counts
        let txnsH1Buys = attributes.transactions?.h1?.buys ?? 0
        let txnsH1Sells = attributes.transactions?.h1?.sells ?? 0
        let txnsH1Total = txnsH1Buys + txnsH1Sells

        // Parse volumes
        let volumeH1 = attributes.volumeUsd?.h1.flatMap { Double($0) } ?? 0
        let volumeH24 = attributes.volumeUsd?.h24.flatMap { Double($0) } ?? 0

        // Parse market cap / FDV
        let marketCap = attributes.fdvUsd.flatMap { Double($0) } ?? 0

        // Parse creation date
        let poolCreatedAt: Date? = if let dateString = attributes.poolCreatedAt {
            ISO8601DateFormatter().date(from: dateString)
        } else {
            nil
        }

        // Extract chain from pool ID (format: "networkname_address")
        let chainId = id.split(separator: "_").first.map { String($0) }

        return Coin(
            id: attributes.address,
            symbol: symbol,
            name: tokenName,
            image: nil, // Will be enriched later from CoinGecko
            currentPrice: price,
            priceChange24h: price * (priceChange24h / 100), // Convert % to absolute
            priceChangePercentage24h: priceChange24h,
            marketCap: marketCap,
            sparklineIn7d: nil, // Not available in trending endpoint
            poolCreatedAt: poolCreatedAt,
            priceChangeH1: priceChangeH1,
            hourlyBuys: txnsH1Buys,
            hourlySells: txnsH1Sells,
            txnsH1: txnsH1Total,
            volumeH1: volumeH1,
            chainId: chainId,
            isViral: true
        )
    }
}

// MARK: - GeckoTerminal Token Response Models

/// Response from GeckoTerminal /networks/{network}/tokens/{address} endpoint
private struct GeckoTerminalTokenResponse: Codable {
    let data: GeckoTerminalTokenData
}

private struct GeckoTerminalTokenData: Codable {
    let id: String
    let type: String
    let attributes: TokenAttributes

    struct TokenAttributes: Codable {
        let address: String
        let name: String
        let symbol: String
        let priceUsd: String?
    }
}

// MARK: - GeckoTerminal OHLCV Response Models

/// Response from GeckoTerminal /networks/{network}/pools/{address}/ohlcv/{timeframe} endpoint
private struct GeckoTerminalOHLCVResponse: Codable {
    let data: GeckoTerminalOHLCVData
}

private struct GeckoTerminalOHLCVData: Codable {
    let id: String
    let type: String
    let attributes: OHLCVAttributes

    struct OHLCVAttributes: Codable {
        let ohlcvList: [[Double]]
    }
}

// MARK: - CoinGecko Search Models

/// Response from CoinGecko /search API
private struct CoinGeckoSearchResponse: Codable {
    let coins: [CoinGeckoSearchCoin]
}

private struct CoinGeckoSearchCoin: Codable {
    let id: String
    let name: String
    let symbol: String
    let large: String? // Large image URL
}

// MARK: - Errors

enum GeckoTerminalError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case rateLimitExceeded
    case poolNotFound
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
        case .poolNotFound:
            return "Pool not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
