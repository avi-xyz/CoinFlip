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

    var isUp: Bool { priceChangePercentage24h >= 0 }
    var formattedPrice: String { Formatters.cryptoPrice(currentPrice) }
    var formattedChange: String { Formatters.percentage(priceChangePercentage24h) }
    var formattedPriceChange24h: String { Formatters.percentage(priceChangePercentage24h) }
    var formattedMarketCap: String { Formatters.currencyCompact(marketCap) }
    var priceChangeColor: Color { isUp ? .gainGreen : .lossRed }

    static func == (lhs: Coin, rhs: Coin) -> Bool { lhs.id == rhs.id }
}

struct SparklineData: Codable {
    let price: [Double]
}
