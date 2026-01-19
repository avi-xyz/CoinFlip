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

    // Cache
    private var cachedViralCoins: [Coin] = []
    private var lastFetchTime: Date?
    private let cacheValidDuration: TimeInterval = 30 // 30 seconds (matches API update frequency)

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

        // Make request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeckoTerminalError.invalidResponse
        }

        print("   📥 Response: HTTP \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
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
        let allCoins = poolsResponse.data.compactMap { $0.toCoin() }

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

    /// Clear cached data
    func clearCache() {
        cachedViralCoins = []
        lastFetchTime = nil
        print("🗑️ GeckoTerminalService: Cache cleared")
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
            id: attributes.address.lowercased(),
            symbol: symbol,
            name: tokenName,
            image: nil, // GeckoTerminal doesn't provide images in trending endpoint
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
