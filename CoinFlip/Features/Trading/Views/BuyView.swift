import SwiftUI

struct BuyView: View {
    let coin: Coin
    let availableCash: Double
    let onBuy: (Double) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double = 50
    @State private var showConfirmation = false
    @State private var purchaseSuccess = false
    @State private var showConfetti = false

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
                    }

                    // Summary
                    BaseCard {
                        VStack(spacing: Spacing.md) {
                            HStack {
                                Text("Order Summary")
                                    .font(.headline3)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }

                            Divider()
                                .background(Color.borderPrimary)

                            HStack {
                                Text("You're buying")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("\(Formatters.quantity(coinQuantity)) \(coin.symbol.uppercased())")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textPrimary)
                            }

                            HStack {
                                Text("Total cost")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text(Formatters.currency(amount))
                                    .font(.numberMedium)
                                    .foregroundColor(.primaryGreen)
                            }
                        }
                    }

                    // Buy Button
                    PrimaryButton(title: "Confirm Purchase") {
                        executePurchase()
                    }
                    .disabled(amount < 10 || amount > availableCash)
                    .opacity(amount < 10 || amount > availableCash ? 0.5 : 1.0)

                    if amount < 10 {
                        Text("Minimum purchase is $10")
                            .font(.labelSmall)
                            .foregroundColor(.lossRed)
                    } else if amount > availableCash {
                        Text("Insufficient funds")
                            .font(.labelSmall)
                            .foregroundColor(.lossRed)
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
                        Text("Something went wrong. Please try again.")
                            .font(.bodyLarge)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
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
    }

    private func executePurchase() {
        HapticManager.shared.impact(.medium)
        purchaseSuccess = onBuy(amount)

        if purchaseSuccess {
            showConfetti = true
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }

        withAnimation {
            showConfirmation = true
        }
    }
}

#Preview {
    BuyView(
        coin: MockData.featuredCoin,
        availableCash: 1000,
        onBuy: { _ in true }
    )
}
