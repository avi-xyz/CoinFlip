//
//  ViralCoinsView.swift
//  CoinFlip
//
//  View for displaying viral/trending meme coins from the last hour
//  Shows ultra-fresh, high-volatility coins for educational purposes
//

import SwiftUI

struct ViralCoinsView: View {
    @StateObject private var viewModel = ViralCoinsViewModel()
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var selectedCoin: Coin?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Warning Banner
                    WarningBanner()
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)

                    // Auto-refresh indicator
                    RefreshIndicator(
                        secondsUntilRefresh: viewModel.secondsUntilRefresh,
                        lastRefreshTime: viewModel.lastRefreshTime
                    )
                    .padding(.horizontal, Spacing.md)

                    if viewModel.isLoading && viewModel.viralCoins.isEmpty {
                        LoadingViralCoinsView()
                    } else if let error = viewModel.error, viewModel.viralCoins.isEmpty {
                        ErrorStateView(error: error) {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    } else if viewModel.viralCoins.isEmpty {
                        EmptyViralCoinsView()
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("🔥 Viral Coins (Last Hour)")
                                .font(.headline3)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, Spacing.md)

                            ForEach(viewModel.viralCoins) { coin in
                                ViralCoinCard(coin: coin) {
                                    selectedCoin = coin
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                }
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $selectedCoin) { coin in
                BuyView(
                    coin: coin,
                    availableCash: homeViewModel.portfolio.cashBalance
                ) { amount in
                    homeViewModel.buy(coin: coin, amount: amount)
                }
                .presentationDetents([.large])
            }
            .navigationTitle("Viral Meme Coins")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel.viralCoins.isEmpty {
                Task {
                    await viewModel.loadViralCoins()
                }
            }
        }
        .onDisappear {
            // Don't stop auto-refresh when view disappears to keep data fresh
        }
    }
}

// MARK: - Warning Banner

private struct WarningBanner: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Learn About Viral Coins")
                    .font(.labelMedium)
                    .foregroundColor(.textPrimary)
                    .fontWeight(.semibold)

                Text("Newly launched coins with high volatility. Prices can change 50%+ in minutes! Perfect for learning about extreme market dynamics in a risk-free environment.")
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(Spacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.sm)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Refresh Indicator

private struct RefreshIndicator: View {
    let secondsUntilRefresh: Int
    let lastRefreshTime: Date?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "arrow.clockwise")
                .font(.labelSmall)
                .foregroundColor(.textSecondary)

            if let lastRefresh = lastRefreshTime {
                Text("Updated \(lastRefresh.timeAgo)")
                    .font(.labelSmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text("Next: \(secondsUntilRefresh)s")
                .font(.labelSmall)
                .foregroundColor(.primaryGreen)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.primaryGreen.opacity(0.1))
                .cornerRadius(Spacing.xxs)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.cardBackground)
        .cornerRadius(Spacing.sm)
    }
}

// MARK: - Loading State

private struct LoadingViralCoinsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Finding viral coins...")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Empty State

private struct EmptyViralCoinsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.textSecondary)

            VStack(spacing: Spacing.sm) {
                Text("No Viral Coins Right Now")
                    .font(.headline2)
                    .foregroundColor(.textPrimary)

                Text("The market is calm. Check back soon for hot new launches!")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Error State

private struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.lossRed)

            VStack(spacing: Spacing.sm) {
                Text("Failed to Load")
                    .font(.headline2)
                    .foregroundColor(.textPrimary)

                Text(error)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: "Try Again") {
                onRetry()
            }
            .frame(maxWidth: 200)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Helper Extension

private extension Date {
    var timeAgo: String {
        let interval = Date().timeIntervalSince(self)

        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Preview

#Preview {
    ViralCoinsView()
        .environmentObject(HomeViewModel(portfolio: MockData.emptyPortfolio))
}
