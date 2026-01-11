import Foundation

struct Holding: Codable, Identifiable, Equatable {
    let id: UUID
    let portfolioId: UUID
    let coinId: String
    let coinSymbol: String
    let coinName: String
    let coinImage: URL?
    var quantity: Double
    var averageBuyPrice: Double
    let firstPurchaseDate: Date
    var createdAt: Date
    var updatedAt: Date?

    // CodingKeys for snake_case database columns
    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId = "portfolio_id"
        case coinId = "coin_id"
        case coinSymbol = "coin_symbol"
        case coinName = "coin_name"
        case coinImage = "coin_image"
        case quantity
        case averageBuyPrice = "average_buy_price"
        case firstPurchaseDate = "first_purchase_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        portfolioId: UUID,
        coin: Coin,
        quantity: Double,
        buyPrice: Double
    ) {
        self.id = id
        self.portfolioId = portfolioId
        self.coinId = coin.id
        self.coinSymbol = coin.symbol
        self.coinName = coin.name
        self.coinImage = coin.image
        self.quantity = quantity
        self.averageBuyPrice = buyPrice
        self.firstPurchaseDate = Date()
        self.createdAt = Date()
        self.updatedAt = nil
    }

    func currentValue(price: Double) -> Double { quantity * price }

    func profitLoss(currentPrice: Double) -> Double {
        (quantity * currentPrice) - (quantity * averageBuyPrice)
    }

    func profitLossPercentage(currentPrice: Double) -> Double {
        guard averageBuyPrice > 0 else { return 0 }
        return ((currentPrice - averageBuyPrice) / averageBuyPrice) * 100
    }
}
