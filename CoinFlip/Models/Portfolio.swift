import Foundation

struct Portfolio: Codable, Equatable {
    var cashBalance: Double
    var holdings: [Holding]
    var transactions: [Transaction]
    let startingBalance: Double

    init(startingBalance: Double) {
        self.cashBalance = startingBalance
        self.startingBalance = startingBalance
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
            holdings.append(Holding(coin: coin, quantity: quantity, buyPrice: coin.currentPrice))
        }

        let transaction = Transaction(coin: coin, type: .buy, quantity: quantity)
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

        let transaction = Transaction(coin: coin, type: .sell, quantity: quantity)
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
