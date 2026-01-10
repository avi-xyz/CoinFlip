import Foundation

struct Holding: Codable, Identifiable, Equatable {
    let id: UUID
    let coinId: String
    let coinSymbol: String
    let coinName: String
    let coinImage: URL?
    var quantity: Double
    var averageBuyPrice: Double
    let firstPurchaseDate: Date

    init(coin: Coin, quantity: Double, buyPrice: Double) {
        self.id = UUID()
        self.coinId = coin.id
        self.coinSymbol = coin.symbol
        self.coinName = coin.name
        self.coinImage = coin.image
        self.quantity = quantity
        self.averageBuyPrice = buyPrice
        self.firstPurchaseDate = Date()
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
