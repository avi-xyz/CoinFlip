import SwiftUI

struct HoldingCard: View {
    let holding: Holding
    let coin: Coin
    let currentPrice: Double
    let onTap: () -> Void

    private var currentValue: Double {
        holding.quantity * currentPrice
    }

    private var costBasis: Double {
        holding.quantity * holding.averageBuyPrice
    }

    private var profitLoss: Double {
        currentValue - costBasis
    }

    private var profitLossPercentage: Double {
        guard costBasis > 0 else { return 0 }
        return (profitLoss / costBasis) * 100
    }

    private var isProfit: Bool {
        profitLoss >= 0
    }

    var body: some View {
        Button(action: onTap) {
            BaseCard {
                HStack(spacing: Spacing.md) {
                    // Coin Image
                    AsyncImage(url: coin.image) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(Color.cardBackgroundElevated)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    // Coin Info & Holdings
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(coin.symbol.uppercased())
                            .font(.headline3)
                            .foregroundColor(.textPrimary)

                        Text("\(Formatters.quantity(holding.quantity)) \(coin.symbol.uppercased())")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)

                        Text("Avg: \(Formatters.cryptoPrice(holding.averageBuyPrice))")
                            .font(.labelSmall)
                            .foregroundColor(.textMuted)
                    }

                    Spacer()

                    // Value & P/L
                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text(Formatters.currency(currentValue))
                            .font(.numberMedium)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: isProfit ? "arrow.up.right" : "arrow.down.right")
                                .font(.labelSmall)

                            Text(Formatters.currency(abs(profitLoss)))
                                .font(.labelMedium)
                        }
                        .foregroundColor(isProfit ? .gainGreen : .lossRed)

                        Text(Formatters.percentage(profitLossPercentage))
                            .font(.labelSmall)
                            .foregroundColor(isProfit ? .gainGreen : .lossRed)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        HoldingCard(
            holding: Holding(
                coin: MockData.coins[0],
                quantity: 1250.5,
                buyPrice: 0.08
            ),
            coin: MockData.coins[0],
            currentPrice: 0.0847,
            onTap: {}
        )

        HoldingCard(
            holding: Holding(
                coin: MockData.coins[2],
                quantity: 5000000,
                buyPrice: 0.00002
            ),
            coin: MockData.coins[2],
            currentPrice: 0.000018,
            onTap: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}
