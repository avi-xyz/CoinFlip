import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @State private var showTransactionHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Portfolio Summary
                    BaseCard {
                        VStack(spacing: Spacing.md) {
                            HStack(spacing: Spacing.xxs) {
                                Text("Net Worth")
                                    .font(.bodyMedium)
                                    .foregroundColor(.textSecondary)

                                InfoTooltip(text: "Your total net worth is your cash balance plus the current value of all your coin holdings. This is the most important metric to track your overall performance.")
                            }

                            Text(Formatters.currency(viewModel.portfolio.cashBalance + viewModel.totalHoldingsValue, decimals: 2))
                                .font(.displayMedium)
                                .foregroundColor(.textPrimary)
                                .contentTransition(.numericText())
                                .accessibilityIdentifier("portfolioNetWorth")
                                .accessibilityValue(Formatters.currency(viewModel.portfolio.cashBalance + viewModel.totalHoldingsValue, decimals: 2))

                            HStack(spacing: Spacing.xs) {
                                Image(systemName: viewModel.isProfit ? "arrow.up.right" : "arrow.down.right")
                                    .font(.labelMedium)

                                Text(Formatters.currency(abs(viewModel.totalProfitLoss)))
                                    .font(.numberMedium)

                                Text("(\(Formatters.percentage(viewModel.totalProfitLossPercentage)))")
                                    .font(.labelMedium)
                            }
                            .foregroundColor(viewModel.isProfit ? .gainGreen : .lossRed)

                            Divider()
                                .padding(.vertical, Spacing.xs)

                            // Breakdown
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    HStack(spacing: Spacing.xxs) {
                                        Text("Cash")
                                            .font(.labelMedium)
                                            .foregroundColor(.textSecondary)

                                        InfoTooltip(text: "Your available cash balance. This is the amount you can use to buy more coins.")
                                    }
                                    Text(Formatters.currency(viewModel.portfolio.cashBalance))
                                        .font(.bodyMedium)
                                        .foregroundColor(.textPrimary)
                                        .accessibilityIdentifier("portfolioCash")
                                        .accessibilityValue(Formatters.currency(viewModel.portfolio.cashBalance))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                                    HStack(spacing: Spacing.xxs) {
                                        Text("Holdings")
                                            .font(.labelMedium)
                                            .foregroundColor(.textSecondary)

                                        InfoTooltip(text: "The current market value of all the coins you own. This value changes as coin prices fluctuate.")
                                    }
                                    Text(Formatters.currency(viewModel.totalHoldingsValue))
                                        .font(.bodyMedium)
                                        .foregroundColor(.textPrimary)
                                        .accessibilityIdentifier("holdingsValue")
                                        .accessibilityValue(Formatters.currency(viewModel.totalHoldingsValue))
                                }
                            }
                        }
                        .padding(.vertical, Spacing.sm)
                    }

                    // Holdings List
                    if viewModel.holdings.isEmpty {
                        // Empty State
                        VStack(spacing: Spacing.lg) {
                            Spacer()

                            Text("📊")
                                .font(.system(size: 80))

                            Text("No Holdings Yet")
                                .font(.headline1)
                                .foregroundColor(.textPrimary)
                                .accessibilityIdentifier("emptyPortfolioMessage")

                            Text("Buy some coins to start building your portfolio!")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxl)
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Your Holdings")
                                .font(.headline3)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, Spacing.xs)

                            ForEach(viewModel.holdings) { holding in
                                // Try to get real-time coin data, fallback to holding data
                                let coin = viewModel.coins.first(where: { $0.id == holding.coinId }) ?? Coin(
                                    id: holding.coinId,
                                    symbol: holding.coinSymbol,
                                    name: holding.coinName,
                                    image: holding.coinImage,
                                    currentPrice: holding.averageBuyPrice,
                                    priceChange24h: 0,
                                    priceChangePercentage24h: 0,
                                    marketCap: 0,
                                    sparklineIn7d: nil
                                )
                                // Try coinId first, then symbol, then fallback to avgBuyPrice (treat $0 as "not found")
                                let priceById = viewModel.currentPrices[holding.coinId]
                                let priceBySymbol = viewModel.currentPrices[holding.coinSymbol.uppercased()]
                                let currentPrice = (priceById != nil && priceById! > 0) ? priceById! :
                                                  (priceBySymbol != nil && priceBySymbol! > 0) ? priceBySymbol! :
                                                  holding.averageBuyPrice

                                HoldingCard(
                                    holding: holding,
                                    coin: coin,
                                    currentPrice: currentPrice,
                                    onTap: {
                                        viewModel.selectedHolding = holding
                                    }
                                )
                            }
                        }

                        // Transaction History
                        if !viewModel.transactions.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Text("Recent Transactions")
                                        .font(.headline3)
                                        .foregroundColor(.textPrimary)

                                    Spacer()

                                    Button {
                                        showTransactionHistory = true
                                        HapticManager.shared.impact(.light)
                                    } label: {
                                        Text("See All")
                                            .font(.labelMedium)
                                            .foregroundColor(.primaryGreen)
                                    }
                                }
                                .padding(.horizontal, Spacing.xs)
                                .padding(.top, Spacing.md)

                                ForEach(viewModel.transactions.prefix(10)) { transaction in
                                    TransactionRow(transaction: transaction)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("Portfolio")
            .refreshable {
                viewModel.refresh()
            }
            .sheet(item: $viewModel.selectedHolding) { holding in
                // Use real-time data if available, fallback to holding data
                let coin = viewModel.coins.first(where: { $0.id == holding.coinId }) ?? Coin(
                    id: holding.coinId,
                    symbol: holding.coinSymbol,
                    name: holding.coinName,
                    image: holding.coinImage,
                    currentPrice: holding.averageBuyPrice,
                    priceChange24h: 0,
                    priceChangePercentage24h: 0,
                    marketCap: 0,
                    sparklineIn7d: nil
                )
                // Try coinId first, then symbol, then fallback to avgBuyPrice (treat $0 as "not found")
                let priceById = viewModel.currentPrices[holding.coinId]
                let priceBySymbol = viewModel.currentPrices[holding.coinSymbol.uppercased()]
                let currentPrice = (priceById != nil && priceById! > 0) ? priceById! :
                                  (priceBySymbol != nil && priceBySymbol! > 0) ? priceBySymbol! :
                                  holding.averageBuyPrice

                SellView(
                    holding: holding,
                    coin: coin,
                    currentPrice: currentPrice
                ) { quantity in
                    await viewModel.sell(holding: holding, quantity: quantity)
                }
                .presentationDetents([.large])
                .task {
                    // Refresh price when opening sell sheet (5-minute cache)
                    await viewModel.refreshPrice(for: holding.coinId)
                }
            }
            .sheet(isPresented: $showTransactionHistory) {
                TransactionHistoryView(transactions: viewModel.transactions)
            }
            .onAppear {
                viewModel.loadData()
                // Fetch missing prices for held coins
                Task {
                    await viewModel.fetchMissingPricesForHoldings()
                }
            }
        }
    }
}

#Preview {
    PortfolioView()
        .environmentObject(PortfolioViewModel(portfolio: MockData.emptyPortfolio, coins: MockData.coins))
}
