import SwiftUI

struct BuyView: View {
    let coin: Coin
    let availableCash: Double
    let onBuy: (Double) async -> HomeViewModel.BuyResult

    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double = 50
    @State private var showConfirmation = false
    @State private var purchaseSuccess = false
    @State private var showConfetti = false
    @State private var isPurchasing = false
    @State private var errorMessage: String? = nil
    @State private var ohlcvData: [Double]? = nil
    @State private var isLoadingChart = false
    @State private var chartError: String? = nil

    private var coinQuantity: Double {
        guard coin.currentPrice > 0 else { return 0 }
        return amount / coin.currentPrice
    }

    private var initialAmount: Double {
        max(10, min(50, availableCash))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
                .accessibilityIdentifier("buySheet")

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Coin Header
                    VStack(spacing: Spacing.md) {
                        AsyncImage(url: coin.image) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.cardBackground)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                        Text(coin.name)
                            .font(.headline1)
                            .foregroundColor(.textPrimary)

                        Text(coin.symbol.uppercased())
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)

                        HStack(spacing: Spacing.xs) {
                            Text(coin.formattedPrice)
                                .font(.numberMedium)
                                .foregroundColor(.textPrimary)

                            Text(coin.formattedPriceChange24h)
                                .font(.labelMedium)
                                .foregroundColor(coin.priceChangeColor)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(coin.priceChangeColor.opacity(0.1))
                                .cornerRadius(Spacing.xxs)
                        }
                    }
                    .padding(.top, Spacing.md)

                    // Price Chart
                    PriceChartCard(
                        coin: coin,
                        ohlcvData: ohlcvData,
                        isLoading: isLoadingChart,
                        error: chartError
                    )

                    // Available Cash
                    BaseCard {
                        HStack {
                            Text("Available Cash")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(Formatters.currency(availableCash))
                                .font(.numberMedium)
                                .foregroundColor(.textPrimary)
                        }
                    }

                    // Amount Slider
                    BaseCard {
                        AmountSlider(
                            amount: $amount,
                            maxAmount: availableCash,
                            coinSymbol: coin.symbol,
                            coinPrice: coin.currentPrice
                        )
                        .accessibilityIdentifier("buyAmountInput")
                    }

                    // Summary
                    BaseCard {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text("Order Summary")
                                    .font(.headline3)
                                    .foregroundColor(.textPrimary)

                                InfoTooltip(text: "This shows the details of your purchase. Review the quantity of coins you'll receive and the total cost before confirming.")

                                Spacer()
                            }

                            Divider()
                                .background(Color.borderPrimary)

                            HStack {
                                HStack(spacing: Spacing.xxs) {
                                    Text("You're buying")
                                        .font(.bodyMedium)
                                        .foregroundColor(.textSecondary)

                                    InfoTooltip(text: "The number of coins you'll receive. This is calculated by dividing your purchase amount by the current coin price.")
                                }
                                Spacer()
                                Text("\(Formatters.quantity(coinQuantity)) \(coin.symbol.uppercased())")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                            }

                            HStack {
                                HStack(spacing: Spacing.xxs) {
                                    Text("Total cost")
                                        .font(.bodyMedium)
                                        .foregroundColor(.textSecondary)

                                    InfoTooltip(text: "The total amount that will be deducted from your cash balance. This is your purchase price or 'cost basis' for calculating future profit/loss.")
                                }
                                Spacer()
                                Text(Formatters.currency(amount))
                                    .font(.numberMedium)
                                    .foregroundColor(.primaryGreen)
                            }
                        }
                    }

                    // Buy Button
                    PrimaryButton(title: isPurchasing ? "Processing..." : "Confirm Purchase") {
                        Task {
                            await executePurchase()
                        }
                    }
                    .disabled(amount < 10 || amount > availableCash || isPurchasing)
                    .opacity(amount < 10 || amount > availableCash || isPurchasing ? 0.5 : 1.0)
                    .accessibilityIdentifier("confirmBuyButton")

                    if amount < 10 {
                        Text("Minimum purchase is $10")
                            .font(.labelSmall)
                            .foregroundColor(.lossRed)
                    } else if amount > availableCash {
                        Text("Insufficient funds")
                            .font(.labelSmall)
                            .foregroundColor(.lossRed)
                    }

                    // Simulation disclaimer
                    Text("Simulated trade with virtual play money")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                        .padding(.top, Spacing.sm)
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
                    Text(purchaseSuccess ? "🎉" : "❌")
                        .font(.system(size: 64))

                    Text(purchaseSuccess ? "Purchase Successful!" : "Purchase Failed")
                        .font(.headline1)
                        .foregroundColor(.textPrimary)

                    if purchaseSuccess {
                        Text("You bought \(Formatters.quantity(coinQuantity)) \(coin.symbol.uppercased())")
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
        .onAppear {
            amount = initialAmount
        }
        .task {
            await loadChartData()
        }
    }

    private func executePurchase() async {
        HapticManager.shared.impact(.medium)
        isPurchasing = true
        errorMessage = nil

        let result = await onBuy(amount)

        switch result {
        case .success:
            purchaseSuccess = true
            showConfetti = true
            HapticManager.shared.success()

        case .insufficientFunds:
            purchaseSuccess = false
            errorMessage = "Insufficient funds. Please reduce the purchase amount."
            HapticManager.shared.error()

        case .invalidAmount:
            purchaseSuccess = false
            errorMessage = "Invalid purchase amount. Please try again."
            HapticManager.shared.error()

        case .persistenceFailed(let details):
            purchaseSuccess = false
            // Show user-friendly message but log details
            print("❌ Purchase persistence failed: \(details)")
            errorMessage = "Failed to save your purchase. Please check your connection and try again."
            HapticManager.shared.error()
        }

        isPurchasing = false

        withAnimation {
            showConfirmation = true
        }
    }

    private func loadChartData() async {
        // For regular coins, sparkline data is already available
        if coin.sparklineIn7d != nil {
            return
        }

        // For viral coins, fetch OHLCV data
        guard coin.isViral, let chainId = coin.chainId else {
            return
        }

        isLoadingChart = true
        chartError = nil

        // Small delay to avoid rate limiting if viral coins were just loaded
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

        do {
            let prices = try await GeckoTerminalService.shared.fetchPoolOHLCV(
                network: chainId,
                poolAddress: coin.id,
                timeframe: "hour",
                limit: 48
            )
            ohlcvData = prices
        } catch {
            print("❌ Failed to fetch OHLCV: \(error)")
            chartError = "Unable to load price history"
        }

        isLoadingChart = false
    }
}

// MARK: - Price Chart Card

private struct PriceChartCard: View {
    let coin: Coin
    let ohlcvData: [Double]?
    let isLoading: Bool
    let error: String?

    private var chartData: [Double]? {
        // Use sparkline data for regular coins
        if let sparkline = coin.sparklineIn7d?.price {
            return sparkline
        }
        // Use OHLCV data for viral coins
        return ohlcvData
    }

    private var timeLabel: String {
        if coin.sparklineIn7d != nil {
            return "7 days"
        } else if coin.isViral {
            return "48 hours"
        }
        return ""
    }

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Price Trend")
                        .font(.headline3)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if !timeLabel.isEmpty {
                        Text(timeLabel)
                            .font(.labelSmall)
                            .foregroundColor(.textMuted)
                    }
                }

                if isLoading {
                    // Loading state
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
                        Spacer()
                    }
                    .frame(height: 100)
                } else if let error = error {
                    // Error state
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.title)
                            .foregroundColor(.textMuted)
                        Text(error)
                            .font(.bodySmall)
                            .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                } else if let data = chartData, data.count > 1 {
                    // Chart
                    SparklineView(data: data, lineWidth: 2.5)
                        .frame(height: 100)

                    // Price range
                    if let minPrice = data.min(), let maxPrice = data.max() {
                        HStack {
                            Text("L: \(Formatters.cryptoPrice(minPrice))")
                                .font(.labelSmall)
                                .foregroundColor(.textMuted)
                            Spacer()
                            Text("H: \(Formatters.cryptoPrice(maxPrice))")
                                .font(.labelSmall)
                                .foregroundColor(.textMuted)
                        }
                    }
                } else {
                    // No data available
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "chart.line.flattrend.xyaxis")
                            .font(.title)
                            .foregroundColor(.textMuted)
                        Text("Price history not available")
                            .font(.bodySmall)
                            .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                }
            }
        }
    }
}

#Preview {
    BuyView(
        coin: MockData.featuredCoin,
        availableCash: 1000,
        onBuy: { _ in .success }
    )
}
