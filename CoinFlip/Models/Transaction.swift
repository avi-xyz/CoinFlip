import Foundation

struct Transaction: Codable, Identifiable, Equatable {
    let id: UUID
    let portfolioId: UUID
    let coinId: String
    let coinSymbol: String
    let type: TransactionType
    let quantity: Double
    let pricePerCoin: Double
    let totalValue: Double
    let timestamp: Date
    let createdAt: Date

    enum TransactionType: String, Codable {
        case buy, sell
    }

    // CodingKeys for snake_case database columns
    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId = "portfolio_id"
        case coinId = "coin_id"
        case coinSymbol = "coin_symbol"
        case type
        case quantity
        case pricePerCoin = "price_per_coin"
        case totalValue = "total_value"
        case timestamp
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        portfolioId: UUID,
        coin: Coin,
        type: TransactionType,
        quantity: Double
    ) {
        self.id = id
        self.portfolioId = portfolioId
        self.coinId = coin.id
        self.coinSymbol = coin.symbol.uppercased()
        self.type = type
        self.quantity = quantity
        self.pricePerCoin = coin.currentPrice
        self.totalValue = quantity * coin.currentPrice
        self.timestamp = Date()
        self.createdAt = Date()
    }
}
