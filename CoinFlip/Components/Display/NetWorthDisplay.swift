import SwiftUI

struct NetWorthDisplay: View {
    let amount: Double
    let change: Double
    let changePercentage: Double

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text("Your Stack")
                .font(.labelMedium)
                .foregroundColor(.textSecondary)

            Text(Formatters.currency(amount, decimals: 2))
                .font(.displayLarge)
                .foregroundColor(.textPrimary)
                .contentTransition(.numericText())

            HStack(spacing: Spacing.xxs) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.labelSmall)
                Text("\(Formatters.currency(abs(change))) today")
                    .font(.labelMedium)
                Text("(\(Formatters.percentage(changePercentage)))")
                    .font(.labelSmall)
            }
            .foregroundColor(change >= 0 ? .gainGreen : .lossRed)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        NetWorthDisplay(amount: 4847.32, change: 892, changePercentage: 22.5)
        NetWorthDisplay(amount: 847.12, change: -152.88, changePercentage: -15.3)
    }
    .padding()
    .background(Color.appBackground)
}
