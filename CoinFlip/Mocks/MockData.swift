import Foundation

enum MockData {
    static let coins: [Coin] = [
        Coin(id: "dogecoin", symbol: "doge", name: "Dogecoin",
             image: URL(string: "https://assets.coingecko.com/coins/images/5/large/dogecoin.png"),
             currentPrice: 0.0847, priceChange24h: 0.00521, priceChangePercentage24h: 6.55,
             marketCap: 12_500_000_000, sparklineIn7d: SparklineData(price: generateSparkline(.up))),

        Coin(id: "shiba-inu", symbol: "shib", name: "Shiba Inu",
             image: URL(string: "https://assets.coingecko.com/coins/images/11939/large/shiba.png"),
             currentPrice: 0.00001234, priceChange24h: -0.00000089, priceChangePercentage24h: -6.72,
             marketCap: 7_200_000_000, sparklineIn7d: SparklineData(price: generateSparkline(.down))),

        Coin(id: "pepe", symbol: "pepe", name: "Pepe",
             image: URL(string: "https://assets.coingecko.com/coins/images/29850/large/pepe-token.png"),
             currentPrice: 0.00001842, priceChange24h: 0.00000623, priceChangePercentage24h: 34.12,
             marketCap: 4_100_000_000, sparklineIn7d: SparklineData(price: generateSparkline(.up))),

        Coin(id: "dogwifcoin", symbol: "wif", name: "dogwifhat",
             image: URL(string: "https://assets.coingecko.com/coins/images/33566/large/dogwifhat.png"),
             currentPrice: 1.23, priceChange24h: -0.15, priceChangePercentage24h: -10.87,
             marketCap: 1_230_000_000, sparklineIn7d: SparklineData(price: generateSparkline(.down))),

        Coin(id: "bonk", symbol: "bonk", name: "Bonk",
             image: URL(string: "https://assets.coingecko.com/coins/images/28600/large/bonk.png"),
             currentPrice: 0.00002156, priceChange24h: 0.00000312, priceChangePercentage24h: 16.91,
             marketCap: 890_000_000, sparklineIn7d: SparklineData(price: generateSparkline(.up)))
    ]

    static var featuredCoin: Coin { coins[2] }

    static let user = User(username: "cryptokid_2009", startingBalance: 1000, avatarEmoji: "🚀")

    static var portfolioWithHoldings: Portfolio {
        var portfolio = Portfolio(userId: user.id, startingBalance: 1000)
        _ = portfolio.buy(coin: coins[0], amount: 200)
        _ = portfolio.buy(coin: coins[2], amount: 300)
        _ = portfolio.buy(coin: coins[4], amount: 150)
        return portfolio
    }

    static var emptyPortfolio: Portfolio {
        Portfolio(userId: user.id, startingBalance: 1000)
    }

    // Mock leaderboard data (for MockDataService only)
    static let leaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(rank: 1, username: "whale_master", avatarEmoji: "👑", netWorth: 47832, percentageGain: 4683),
        LeaderboardEntry(rank: 2, username: "doge_queen", avatarEmoji: "🐕", netWorth: 12847, percentageGain: 1185),
        LeaderboardEntry(rank: 3, username: "cryptokid_2009", avatarEmoji: "🚀", netWorth: 4847, percentageGain: 385, isCurrentUser: true),
        LeaderboardEntry(rank: 4, username: "diamond_hands", avatarEmoji: "💎", netWorth: 2100, percentageGain: 110),
        LeaderboardEntry(rank: 5, username: "paper_hands", avatarEmoji: "💀", netWorth: 12, percentageGain: -99)
    ]

    private enum Trend { case up, down }

    private static func generateSparkline(_ trend: Trend) -> [Double] {
        var values: [Double] = []
        var current = Double.random(in: 50...150)
        for _ in 0..<168 {
            let change: Double = trend == .up ? Double.random(in: -2...4) : Double.random(in: -4...2)
            current = max(10, current + change)
            values.append(current)
        }
        return values
    }
}
