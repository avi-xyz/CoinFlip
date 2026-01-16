import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var selectedCoin: Coin?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    NetWorthDisplay(
                        amount: viewModel.netWorth,
                        change: viewModel.dailyChange,
                        changePercentage: viewModel.dailyChangePercentage
                    )
                    .padding(.top, Spacing.md)

                    if viewModel.isLoading {
                        LoadingSkeletonView()
                    } else {
                        if let featured = viewModel.featuredCoin {
                            FeaturedCoinCard(
                                coin: featured,
                                onBuy: { selectedCoin = featured },
                                onSkip: { viewModel.skipFeaturedCoin() }
                            )
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Trending Meme Coins")
                                .font(.headline3)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, Spacing.xs)
                                .accessibilityIdentifier("trendingCoinsHeader")

                            ForEach(viewModel.trendingCoins) { coin in
                                CoinCard(coin: coin) {
                                    selectedCoin = coin
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $selectedCoin) { coin in
                BuyView(
                    coin: coin,
                    availableCash: viewModel.portfolio.cashBalance
                ) { amount in
                    viewModel.buy(coin: coin, amount: amount)
                }
                .presentationDetents([.large])
            }
            .onAppear {
                // Initial load happens in init()
                // Refresh manually if needed
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(HomeViewModel(portfolio: MockData.emptyPortfolio))
}
