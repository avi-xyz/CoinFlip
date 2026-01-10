import Foundation

struct Transaction: Codable, Identifiable, Equatable {
    let id: UUID
    let coinId: String
    let coinSymbol: String
    let type: TransactionType
    let quantity: Double
    let pricePerCoin: Double
    let totalValue: Double
    let timestamp: Date

    enum TransactionType: String, Codable {
        case buy, sell
    }

    init(coin: Coin, type: TransactionType, quantity: Double) {
        self.id = UUID()
        self.coinId = coin.id
        self.coinSymbol = coin.symbol.uppercased()
        self.type = type
        self.quantity = quantity
        self.pricePerCoin = coin.currentPrice
        self.totalValue = quantity * coin.currentPrice
        self.timestamp = Date()
    }
}
