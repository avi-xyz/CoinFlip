import Foundation
import SwiftUI

struct Coin: Codable, Identifiable, Equatable {
    let id: String
    let symbol: String
    let name: String
    let image: URL?
    let currentPrice: Double
    let priceChange24h: Double
    let priceChangePercentage24h: Double
    let marketCap: Double
    let sparklineIn7d: SparklineData?

    // Viral coin specific fields (optional - only for GeckoTerminal coins)
    let poolCreatedAt: Date?
    let priceChangeH1: Double? // Hourly price change percentage
    let hourlyBuys: Int? // Number of buys in last hour
    let hourlySells: Int? // Number of sells in last hour
    let txnsH1: Int? // Total transactions in last hour
    let volumeH1: Double? // Volume in last hour (USD)
    let chainId: String? // Blockchain identifier (eth, solana, base, etc.)
    let isViral: Bool // Flag indicating if this is a viral coin

    var isUp: Bool { priceChangePercentage24h >= 0 }
    var formattedPrice: String { Formatters.cryptoPrice(currentPrice) }
    var formattedChange: String { Formatters.percentage(priceChangePercentage24h) }
    var formattedPriceChange24h: String { Formatters.percentage(priceChangePercentage24h) }
    var formattedMarketCap: String { Formatters.currencyCompact(marketCap) }
    var priceChangeColor: Color { isUp ? .gainGreen : .lossRed }

    // Viral coin specific computed properties
    var formattedPriceChangeH1: String {
        guard let change = priceChangeH1 else { return "N/A" }
        return Formatters.percentage(change)
    }

    var timeSinceLaunch: String {
        guard let createdAt = poolCreatedAt else { return "Unknown" }
        let interval = Date().timeIntervalSince(createdAt)

        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }

    var chainDisplayName: String {
        guard let chain = chainId else { return "Unknown" }

        switch chain {
        case "eth": return "Ethereum"
        case "solana": return "Solana"
        case "bsc": return "BSC"
        case "polygon": return "Polygon"
        case "arbitrum": return "Arbitrum"
        case "base": return "Base"
        case "optimism": return "Optimism"
        case "avalanche": return "Avalanche"
        default: return chain.capitalized
        }
    }

    // Default initializer with all viral fields
    init(
        id: String,
        symbol: String,
        name: String,
        image: URL? = nil,
        currentPrice: Double,
        priceChange24h: Double,
        priceChangePercentage24h: Double,
        marketCap: Double,
        sparklineIn7d: SparklineData? = nil,
        poolCreatedAt: Date? = nil,
        priceChangeH1: Double? = nil,
        hourlyBuys: Int? = nil,
        hourlySells: Int? = nil,
        txnsH1: Int? = nil,
        volumeH1: Double? = nil,
        chainId: String? = nil,
        isViral: Bool = false
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = currentPrice
        self.priceChange24h = priceChange24h
        self.priceChangePercentage24h = priceChangePercentage24h
        self.marketCap = marketCap
        self.sparklineIn7d = sparklineIn7d
        self.poolCreatedAt = poolCreatedAt
        self.priceChangeH1 = priceChangeH1
        self.hourlyBuys = hourlyBuys
        self.hourlySells = hourlySells
        self.txnsH1 = txnsH1
        self.volumeH1 = volumeH1
        self.chainId = chainId
        self.isViral = isViral
    }

    static func == (lhs: Coin, rhs: Coin) -> Bool { lhs.id == rhs.id }
}

struct SparklineData: Codable {
    let price: [Double]
}
