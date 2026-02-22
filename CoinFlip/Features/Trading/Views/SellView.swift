import SwiftUI

struct SellView: View {
    let holding: Holding
    let coin: Coin
    let currentPrice: Double
    let onSell: (Double) async -> PortfolioViewModel.SellResult

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double
    @State private var showConfirmation = false
    @State private var sellSuccess = false
    @State private var showConfetti = false
    @State private var isSelling = false
    @State private var errorMessage: String? = nil

    init(holding: Holding, coin: Coin, currentPrice: Double, onSell: @escaping (Double) async -> PortfolioViewModel.SellResult) {
        self.holding = holding
        self.coin = coin
        self.currentPrice = currentPrice
        self.onSell = onSell
        _quantity = State(initialValue: min(holding.quantity / 2, holding.quantity))
    }

    private var saleValue: Double {
        quantity * currentPrice
    }

    private var costBasis: Double {
        quantity * holding.averageBuyPrice
    }

    private var profitLoss: Double {
        saleValue - costBasis
    }

    private var isProfit: Bool {
        profitLoss >= 0
    }

    private var isPriceUnavailable: Bool {
        currentPrice == 0.0
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
                .accessibilityIdentifier("sellSheet")

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Price Unavailable Warning
                    if isPriceUnavailable {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.headline3)

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Price Unavailable")
                                    .font(.labelMedium)
                                    .foregroundColor(.textPrimary)

                                Text("Latest price could not be fetched. Cannot sell at this time.")
                                    .font(.labelSmall)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(Spacing.md)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.sm)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, Spacing.md)
                    }

                    // Coin Header
                    VStack(spacing: Spacing.md) {
                        AsyncImage(url: coin.image) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.cardBackground)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                        Text("Sell \(coin.name)")
                            .font(.headline1)
                            .foregroundColor(.textPrimary)

                        Text(coin.symbol.uppercased())
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.md)

                    // Holdings Info
                    BaseCard {
                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Text("You Own")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("\(Formatters.quantity(holding.quantity)) \(coin.symbol.uppercased())")
                                    .font(.numberMedium)
                                    .foregroundColor(.textPrimary)
                            }

                            HStack {
                                Text("Current Value")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text(Formatters.currency(holding.quantity * currentPrice))
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }

                    // Quantity Selector
                    BaseCard {
                        VStack(spacing: Spacing.lg) {
                            Text("\(Formatters.quantity(quantity)) \(coin.symbol.uppercased())")
                                .font(.displayMedium)
                                .foregroundColor(.textPrimary)
                                .contentTransition(.numericText())

                            Slider(value: $quantity, in: 0...holding.quantity, step: holding.quantity / 100)
                                .tint(.primaryPurple)

                            HStack {
                                Text("0").font(.labelSmall).foregroundColor(.textSecondary)
                                Spacer()
                                Button {
                                    withAnimation { quantity = holding.quantity }
                                    HapticManager.shared.impact(.light)
                                } label: {
                                    Text("ALL")
                                        .font(.labelSmall)
                                        .foregroundColor(.primaryPurple)
                                }
                            }

                            HStack(spacing: Spacing.sm) {
                                Button {
                                    withAnimation { quantity = holding.quantity * 0.25 }
                                    HapticManager.shared.impact(.light)
                                } label: {
                                    Text("25%")
                                        .font(.labelMedium)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.cardBackgroundElevated)
                                        .foregroundColor(.textPrimary)
                                        .cornerRadius(Spacing.xs)
                                }
                                .accessibilityIdentifier("sellPercent_25")

                                Button {
                                    withAnimation { quantity = holding.quantity * 0.5 }
                                    HapticManager.shared.impact(.light)
                                } label: {
                                    Text("50%")
                                        .font(.labelMedium)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.cardBackgroundElevated)
                                        .foregroundColor(.textPrimary)
                                        .cornerRadius(Spacing.xs)
                                }
                                .accessibilityIdentifier("sellPercent_50")

                                Button {
                                    withAnimation { quantity = holding.quantity * 0.75 }
                                    HapticManager.shared.impact(.light)
                                } label: {
                                    Text("75%")
                                        .font(.labelMedium)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.cardBackgroundElevated)
                                        .foregroundColor(.textPrimary)
                                        .cornerRadius(Spacing.xs)
                                }
                                .accessibilityIdentifier("sellPercent_75")

                                Button {
                                    withAnimation { quantity = holding.quantity }
                                    HapticManager.shared.impact(.light)
                                } label: {
                                    Text("MAX")
                                        .font(.labelMedium)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(abs(quantity - holding.quantity) < 0.01 ? Color.primaryPurple.opacity(0.2) : Color.cardBackgroundElevated)
                                        .foregroundColor(abs(quantity - holding.quantity) < 0.01 ? .primaryPurple : .textPrimary)
                                        .cornerRadius(Spacing.xs)
                                }
                                .accessibilityIdentifier("sellPercent_100")
                            }

                            if isPriceUnavailable {
                                Text("Price Unavailable")
                                    .font(.bodySmall)
                                    .foregroundColor(.orange)
                            } else {
                                Text("You'll receive: \(Formatters.currency(saleValue))")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    // Sale Summary
                    BaseCard {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text("Sale Summary")
                                    .font(.headline3)
                                    .foregroundColor(.textPrimary)

                                InfoTooltip(text: "This shows the breakdown of your sale including what you'll receive, what you originally paid (cost basis), and your profit or loss.")

                                Spacer()
                            }

                            Divider()
                                .background(Color.borderPrimary)

                            HStack {
                                HStack(spacing: Spacing.xxs) {
                                    Text("Sale value")
                                        .font(.bodyMedium)
                                        .foregroundColor(.textSecondary)

                                    InfoTooltip(text: "The total cash you'll receive from selling these coins at the current market price. This amount will be added to your cash balance.")
                                }
                                Spacer()
                                if isPriceUnavailable {
                                    Text("Price Unavailable")
                                        .font(.bodyMedium)
                                        .foregroundColor(.orange)
                                } else {
                                    Text(Formatters.currency(saleValue))
                                        .font(.bodyMedium)
                                        .foregroundColor(.textPrimary)
                                }
                            }

                            HStack {
                                HStack(spacing: Spacing.xxs) {
                                    Text("Cost basis")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)

                                    InfoTooltip(text: "Cost basis is the original amount you paid for these coins. It's calculated from your average purchase price. The difference between sale value and cost basis is your profit or loss.")
                                }
                                Spacer()
                                Text(Formatters.currency(costBasis))
                                    .font(.bodySmall)
                                    .foregroundColor(.textMuted)
                            }

                            Divider()
                                .background(Color.borderPrimary)

                            HStack {
                                Text(isProfit ? "Profit" : "Loss")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                if isPriceUnavailable {
                                    Text("—")
                                        .font(.numberMedium)
                                        .foregroundColor(.textMuted)
                                } else {
                                    Text("\(isProfit ? "+" : "")\(Formatters.currency(profitLoss))")
                                        .font(.numberMedium)
                                        .foregroundColor(isProfit ? .gainGreen : .lossRed)
                                }
                            }
                        }
                    }

                    // Sell Button
                    PrimaryButton(title: isSelling ? "Processing..." : "Confirm Sale") {
                        Task {
                            await executeSale()
                        }
                    }
                    .disabled(quantity <= 0 || isPriceUnavailable || isSelling)
                    .opacity(quantity <= 0 || isPriceUnavailable || isSelling ? 0.5 : 1.0)
                    .accessibilityIdentifier("confirmSellButton")

                    if quantity <= 0 {
                        Text("Select quantity to sell")
                            .font(.labelSmall)
                            .foregroundColor(.lossRed)
                    } else if isPriceUnavailable {
                        Text("Cannot sell - price unavailable")
                            .font(.labelSmall)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }

            // Confetti Overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            // Success/Failure Overlay
            if showConfirmation {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture { }

                VStack(spacing: Spacing.lg) {
                    Text(sellSuccess ? "💰" : "❌")
                        .font(.system(size: 64))

                    Text(sellSuccess ? "Sale Successful!" : "Sale Failed")
                        .font(.headline1)
                        .foregroundColor(.textPrimary)

                    if sellSuccess {
                        Text("You sold \(Formatters.quantity(quantity)) \(coin.symbol.uppercased()) for \(Formatters.currency(saleValue))")
                            .font(.bodyLarge)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(errorMessage ?? "Something went wrong. Please try again.")
                            .font(.bodyLarge)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.md)
                    }

                    PrimaryButton(title: "Done") {
                        dismiss()
                    }
                    .padding(.top, Spacing.md)
                }
                .padding(Spacing.xl)
                .background(Color.cardBackground)
                .cornerRadius(Spacing.md)
                .padding(.horizontal, Spacing.xl)
            }

            // Close Button
            VStack {
                HStack {
                    Button {
                        HapticManager.shared.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textPrimary)
                            .font(.headline3)
                            .padding()
                            .background(Color.cardBackground.opacity(0.8))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }

    private func executeSale() async {
        HapticManager.shared.impact(.medium)
        isSelling = true
        errorMessage = nil

        let result = await onSell(quantity)

        switch result {
        case .success:
            sellSuccess = true
            showConfetti = true
            HapticManager.shared.success()

        case .invalidQuantity:
            sellSuccess = false
            errorMessage = "Invalid quantity. Please adjust and try again."
            HapticManager.shared.error()

        case .persistenceFailed(let details):
            sellSuccess = false
            print("❌ Sale persistence failed: \(details)")
            errorMessage = "Failed to save your sale. Please check your connection and try again."
            HapticManager.shared.error()
        }

        isSelling = false

        withAnimation {
            showConfirmation = true
        }
    }
}

#Preview {
    SellView(
        holding: Holding(
            portfolioId: UUID(),
            coin: MockData.coins[0],
            quantity: 1250.5,
            buyPrice: 0.08
        ),
        coin: MockData.coins[0],
        currentPrice: 0.0847,
        onSell: { _ in .success }
    )
}
