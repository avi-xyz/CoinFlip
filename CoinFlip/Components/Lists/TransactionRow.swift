import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var typeColor: Color {
        transaction.type == .buy ? .gainGreen : .lossRed
    }

    private var typeIcon: String {
        transaction.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
    }

    private var typeText: String {
        transaction.type == .buy ? "Bought" : "Sold"
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(transaction.timestamp)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }

    var body: some View {
        BaseCard {
            HStack(spacing: Spacing.md) {
                // Type Icon
                Image(systemName: typeIcon)
                    .font(.title3)
                    .foregroundColor(typeColor)
                    .frame(width: 40, height: 40)
                    .background(typeColor.opacity(0.1))
                    .clipShape(Circle())

                // Transaction Info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(typeText) \(transaction.coinSymbol.uppercased())")
                        .font(.headline3)
                        .foregroundColor(.textPrimary)

                    Text("\(Formatters.quantity(transaction.quantity)) @ \(Formatters.cryptoPrice(transaction.pricePerCoin))")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)

                    Text(timeAgo)
                        .font(.labelSmall)
                        .foregroundColor(.textMuted)
                }

                Spacer()

                // Amount
                Text("\(transaction.type == .buy ? "-" : "+")\(Formatters.currency(transaction.totalValue))")
                    .font(.numberMedium)
                    .foregroundColor(typeColor)
            }
        }
    }
}

#Preview {
    VStack {
        TransactionRow(
            transaction: Transaction(
                portfolioId: UUID(),
                coin: MockData.coins[0],
                type: .buy,
                quantity: 1250.5
            )
        )

        TransactionRow(
            transaction: Transaction(
                portfolioId: UUID(),
                coin: MockData.coins[2],
                type: .sell,
                quantity: 500000
            )
        )
    }
    .padding()
    .background(Color.appBackground)
}
