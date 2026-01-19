import SwiftUI

struct AmountSlider: View {
    @Binding var amount: Double
    let maxAmount: Double
    let coinSymbol: String
    let coinPrice: Double

    private var coinQuantity: Double {
        guard coinPrice > 0 else { return 0 }
        return amount / coinPrice
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(Formatters.currency(amount, decimals: 0))
                .font(.displayMedium)
                .foregroundColor(.textPrimary)
                .contentTransition(.numericText())

            if maxAmount >= 11 {
                Slider(value: $amount, in: 10...maxAmount, step: 1)
                    .tint(.primaryGreen)
            } else {
                Slider(value: .constant(10), in: 10...11, step: 1)
                    .tint(.primaryGreen)
                    .disabled(true)
            }

            HStack {
                Text("$10").font(.labelSmall).foregroundColor(.textSecondary)
                Spacer()
                Button {
                    withAnimation { amount = maxAmount }
                    HapticManager.shared.impact(.light)
                } label: {
                    Text("ALL IN")
                        .font(.labelSmall)
                        .foregroundColor(.primaryGreen)
                }
                .disabled(maxAmount < 10)
            }

            HStack(spacing: Spacing.sm) {
                ForEach([25.0, 50.0, 100.0], id: \.self) { quickAmount in
                    Button {
                        withAnimation { amount = min(quickAmount, maxAmount) }
                        HapticManager.shared.impact(.light)
                    } label: {
                        Text("$\(Int(quickAmount))")
                            .font(.labelMedium)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(abs(amount - quickAmount) < 1 ? Color.primaryGreen.opacity(0.2) : Color.cardBackgroundElevated)
                            .foregroundColor(abs(amount - quickAmount) < 1 ? .primaryGreen : .textPrimary)
                            .cornerRadius(Spacing.xs)
                    }
                }
                Button {
                    withAnimation { amount = maxAmount }
                    HapticManager.shared.impact(.light)
                } label: {
                    Text("MAX")
                        .font(.labelMedium)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(abs(amount - maxAmount) < 1 ? Color.primaryGreen.opacity(0.2) : Color.cardBackgroundElevated)
                        .foregroundColor(abs(amount - maxAmount) < 1 ? .primaryGreen : .textPrimary)
                        .cornerRadius(Spacing.xs)
                }
                .disabled(maxAmount < 10)
            }

            Text("You'll get: \(Formatters.quantity(coinQuantity)) \(coinSymbol.uppercased())")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    struct Wrapper: View {
        @State var amount: Double = 50
        var body: some View {
            AmountSlider(amount: $amount, maxAmount: 500, coinSymbol: "PEPE", coinPrice: 0.00001842)
                .padding()
                .background(Color.appBackground)
        }
    }
    return Wrapper()
}
