//
//  ViralCoinCard.swift
//  CoinFlip
//
//  Card component for displaying viral/trending meme coins
//  Features prominent hourly metrics, chain info, and dramatic styling
//

import SwiftUI

struct ViralCoinCard: View {
    let coin: Coin
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            onTap()
        }) {
            HStack(spacing: Spacing.md) {
                // Coin Image/Placeholder
                CoinImageView(url: coin.image)

                // Coin Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Name and Symbol
                    HStack(spacing: Spacing.xs) {
                        Text(coin.symbol)
                            .font(.headline3)
                            .foregroundColor(.textPrimary)

                        if let createdAt = coin.poolCreatedAt,
                           Date().timeIntervalSince(createdAt) < 3600 {
                            NewBadge()
                        }

                        if coin.chainId != nil {
                            ChainBadge(chain: coin.chainDisplayName)
                        }
                    }

                    Text(coin.name)
                        .font(.labelMedium)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)

                    // Launch Time
                    if let createdAt = coin.poolCreatedAt {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "clock.fill")
                                .font(.labelSmall)
                                .foregroundColor(.textSecondary)

                            Text("Launched \(coin.timeSinceLaunch)")
                                .font(.labelSmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                Spacer()

                // Hourly Metrics
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    // Price
                    Text(coin.formattedPrice)
                        .font(.numberMedium)
                        .foregroundColor(.textPrimary)

                    // Hourly Change (primary metric)
                    if let changeH1 = coin.priceChangeH1 {
                        HourlyChangeBadge(change: changeH1)
                    }

                    // Transaction Count
                    if let txns = coin.txnsH1, txns > 0 {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.labelSmall)

                            Text("\(txns) txns/h")
                                .font(.labelSmall)
                        }
                        .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                // Gradient background for hot coins
                gradientBackground(for: coin.priceChangeH1 ?? 0)
            )
            .cornerRadius(Spacing.md)
            .shadow(color: shadowColor(for: coin.priceChangeH1 ?? 0), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func gradientBackground(for change: Double) -> some View {
        if change > 100 {
            // Super hot - red/orange gradient
            LinearGradient(
                colors: [
                    Color.red.opacity(0.15),
                    Color.orange.opacity(0.1),
                    Color.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if change > 50 {
            // Hot - orange gradient
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.15),
                    Color.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Normal - card background
            Color.cardBackground
        }
    }

    private func shadowColor(for change: Double) -> Color {
        if change > 100 {
            return Color.red.opacity(0.3)
        } else if change > 50 {
            return Color.orange.opacity(0.2)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}

// MARK: - Supporting Components

private struct CoinImageView: View {
    let url: URL?

    var body: some View {
        Group {
            if let imageURL = url {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Circle().fill(Color.cardBackgroundElevated)
                }
            } else {
                // Placeholder for coins without images
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text("🔥")
                            .font(.title3)
                    )
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }
}

private struct NewBadge: View {
    @State private var pulse = false

    var body: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.red)
            .cornerRadius(3)
            .scaleEffect(pulse ? 1.1 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                pulse = true
            }
    }
}

private struct ChainBadge: View {
    let chain: String

    var body: some View {
        Text(chain)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.cardBackgroundElevated)
            .cornerRadius(3)
    }
}

private struct HourlyChangeBadge: View {
    let change: Double

    var color: Color {
        if change > 100 {
            return .red
        } else if change > 50 {
            return .orange
        } else if change > 0 {
            return .gainGreen
        } else {
            return .lossRed
        }
    }

    var icon: String {
        if change > 100 {
            return "flame.fill"
        } else if change > 50 {
            return "arrow.up.right"
        } else if change > 0 {
            return "arrow.up"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.labelMedium)

            Text(Formatters.percentage(change))
                .font(.labelMedium)
                .fontWeight(.bold)

            Text("1h")
                .font(.system(size: 9))
                .opacity(0.8)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(color.opacity(0.15))
        .cornerRadius(Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        // Super hot coin (>100% change)
        ViralCoinCard(
            coin: Coin(
                id: "test1",
                symbol: "VIRAL",
                name: "Viral Coin",
                image: nil,
                currentPrice: 0.0001234,
                priceChange24h: 0,
                priceChangePercentage24h: 250,
                marketCap: 5000000,
                poolCreatedAt: Date().addingTimeInterval(-1800), // 30 mins ago
                priceChangeH1: 150,
                txnsH1: 250,
                chainId: "solana",
                isViral: true
            )
        ) {}

        // Hot coin (>50% change)
        ViralCoinCard(
            coin: Coin(
                id: "test2",
                symbol: "MOON",
                name: "To The Moon",
                image: nil,
                currentPrice: 0.00567,
                priceChange24h: 0,
                priceChangePercentage24h: 80,
                marketCap: 10000000,
                poolCreatedAt: Date().addingTimeInterval(-3000), // 50 mins ago
                priceChangeH1: 75,
                txnsH1: 180,
                chainId: "base",
                isViral: true
            )
        ) {}

        // Normal viral coin
        ViralCoinCard(
            coin: Coin(
                id: "test3",
                symbol: "PUMP",
                name: "Pump It",
                image: nil,
                currentPrice: 0.123,
                priceChange24h: 0,
                priceChangePercentage24h: 35,
                marketCap: 25000000,
                poolCreatedAt: Date().addingTimeInterval(-5400), // 90 mins ago
                priceChangeH1: 35,
                txnsH1: 120,
                chainId: "eth",
                isViral: true
            )
        ) {}
    }
    .padding()
    .background(Color.appBackground)
}
