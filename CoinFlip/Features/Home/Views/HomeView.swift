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

                    // First Trade Guidance Banner
                    if viewModel.portfolio.cashBalance >= 999.0 {
                        FirstTradeGuidanceBanner()
                    }

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
                    await viewModel.buy(coin: coin, amount: amount)
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

// MARK: - First Trade Guidance Banner

private struct FirstTradeGuidanceBanner: View {
    @State private var isDismissed = false

    var body: some View {
        if !isDismissed {
            BaseCard {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "hand.wave.fill")
                        .foregroundColor(.primaryGreen)
                        .font(.title)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Ready to Start Trading?")
                            .font(.labelMedium)
                            .foregroundColor(.textPrimary)
                            .fontWeight(.semibold)

                        Text("You have $1,000 to practice with! Tap any coin below to make your first purchase. Start small to learn how trading works.")
                            .font(.labelSmall)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isDismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textMuted)
                            .font(.title3)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cardRadius)
                    .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(HomeViewModel(portfolio: MockData.emptyPortfolio))
}
