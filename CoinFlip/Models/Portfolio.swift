import Foundation

struct Portfolio: Codable, Equatable, Identifiable {
    let id: UUID
    let userId: UUID
    var cashBalance: Double
    let startingBalance: Double
    var createdAt: Date
    var updatedAt: Date?

    // In-memory only (not stored in portfolios table)
    var holdings: [Holding] = []
    var transactions: [Transaction] = []

    // CodingKeys for snake_case database columns
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cashBalance = "cash_balance"
        case startingBalance = "starting_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // holdings and transactions are not encoded to database
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        startingBalance: Double = 1000
    ) {
        self.id = id
        self.userId = userId
        self.cashBalance = startingBalance
        self.startingBalance = startingBalance
        self.createdAt = Date()
        self.updatedAt = nil
        self.holdings = []
        self.transactions = []
    }

    func totalValue(prices: [String: Double]) -> Double {
        let holdingsValue = holdings.reduce(0) { total, holding in
            let price = prices[holding.coinId] ?? holding.averageBuyPrice
            return total + holding.currentValue(price: price)
        }
        return cashBalance + holdingsValue
    }

    func holdingsValue(prices: [String: Double]) -> Double {
        holdings.reduce(0) { total, holding in
            let price = prices[holding.coinId] ?? holding.averageBuyPrice
            return total + holding.currentValue(price: price)
        }
    }

    mutating func buy(coin: Coin, amount: Double) -> Transaction? {
        guard amount > 0, amount <= cashBalance else { return nil }
        let quantity = amount / coin.currentPrice
        cashBalance -= amount

        if let index = holdings.firstIndex(where: { $0.coinId == coin.id }) {
            let existingQty = holdings[index].quantity
            let existingCost = existingQty * holdings[index].averageBuyPrice
            let newCost = quantity * coin.currentPrice
            holdings[index].quantity += quantity
            holdings[index].averageBuyPrice = (existingCost + newCost) / holdings[index].quantity
        } else {
            holdings.append(Holding(
                portfolioId: self.id,
                coin: coin,
                quantity: quantity,
                buyPrice: coin.currentPrice
            ))
        }

        let transaction = Transaction(
            portfolioId: self.id,
            coin: coin,
            type: .buy,
            quantity: quantity
        )
        transactions.insert(transaction, at: 0)
        return transaction
    }

    mutating func sell(coin: Coin, quantity: Double) -> Transaction? {
        guard let index = holdings.firstIndex(where: { $0.coinId == coin.id }),
              quantity > 0, holdings[index].quantity >= quantity else { return nil }

        let saleValue = quantity * coin.currentPrice
        cashBalance += saleValue
        holdings[index].quantity -= quantity

        if holdings[index].quantity < 0.00000001 {
            holdings.remove(at: index)
        }

        let transaction = Transaction(
            portfolioId: self.id,
            coin: coin,
            type: .sell,
            quantity: quantity
        )
        transactions.insert(transaction, at: 0)
        return transaction
    }

    func holding(for coinId: String) -> Holding? {
        holdings.first { $0.coinId == coinId }
    }

    func hasHolding(for coinId: String) -> Bool {
        holdings.contains { $0.coinId == coinId }
    }
}
