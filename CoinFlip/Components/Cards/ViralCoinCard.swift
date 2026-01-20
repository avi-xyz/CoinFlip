//
//  ViralCoinCard.swift
//  CoinFlip
//
//  Professional card design for viral/trending meme coins
//  Emphasizes hourly metrics and visual hierarchy
//

import SwiftUI

struct ViralCoinCard: View {
    let coin: Coin
    let onTap: () -> Void

    private var isExtremelyHot: Bool {
        (coin.priceChangeH1 ?? 0) > 100
    }

    private var isHot: Bool {
        (coin.priceChangeH1 ?? 0) > 50
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            onTap()
        }) {
            VStack(spacing: 0) {
                HStack(spacing: Spacing.md) {
                    // Professional Icon/Avatar
                    CoinAvatar(symbol: coin.symbol, imageURL: coin.image)

                    // Main Content
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Top Row: Symbol + Badges
                        HStack(spacing: Spacing.xs) {
                            Text(coin.symbol)
                                .font(.headline2)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            if coin.chainId != nil {
                                ChainBadge(chain: coin.chainDisplayName)
                            }

                            if let createdAt = coin.poolCreatedAt,
                               Date().timeIntervalSince(createdAt) < 3600 {
                                NewBadge()
                            }
                        }

                        // Metrics Row
                        HStack(spacing: Spacing.sm) {
                            // Launch time
                            if let createdAt = coin.poolCreatedAt {
                                Label(coin.timeSinceLaunch, systemImage: "clock")
                                    .font(.labelSmall)
                                    .foregroundColor(.textSecondary)
                            }

                            // Transaction count
                            if let txns = coin.txnsH1, txns > 0 {
                                Label("\(txns)", systemImage: "arrow.left.arrow.right")
                                    .font(.labelSmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    Spacer(minLength: Spacing.sm)

                    // Right Side: Price & Change
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text(coin.formattedPrice)
                            .font(.numberMedium)
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        if let changeH1 = coin.priceChangeH1 {
                            HourlyChangeBadge(change: changeH1, prominent: true)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)
            }
            .background(cardBackground)
            .cornerRadius(Spacing.md)
            .shadow(color: shadowColor, radius: isExtremelyHot ? 12 : 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.md)
                    .stroke(borderColor, lineWidth: isExtremelyHot ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Visual Styling

    @ViewBuilder
    private var cardBackground: some View {
        if isExtremelyHot {
            // Extreme heat: Animated red gradient
            LinearGradient(
                colors: [
                    Color.red.opacity(0.2),
                    Color.orange.opacity(0.15),
                    Color.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHot {
            // Hot: Orange gradient
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.15),
                    Color.yellow.opacity(0.1),
                    Color.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Normal
            Color.cardBackground
        }
    }

    private var borderColor: Color {
        if isExtremelyHot {
            return Color.red.opacity(0.4)
        } else if isHot {
            return Color.orange.opacity(0.3)
        } else {
            return Color.borderPrimary.opacity(0.3)
        }
    }

    private var shadowColor: Color {
        if isExtremelyHot {
            return Color.red.opacity(0.3)
        } else if isHot {
            return Color.orange.opacity(0.2)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - Supporting Components

private struct CoinAvatar: View {
    let symbol: String
    let imageURL: URL?

    private var firstLetter: String {
        String(symbol.prefix(1))
    }

    private var gradientColors: [Color] {
        // Generate consistent colors based on symbol
        let hash = symbol.hashValue
        let hue = Double(abs(hash) % 360) / 360.0

        return [
            Color(hue: hue, saturation: 0.6, brightness: 0.8),
            Color(hue: hue, saturation: 0.7, brightness: 0.6)
        ]
    }

    var body: some View {
        Group {
            if let imageURL = imageURL {
                // Try to load image
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure, .empty:
                        placeholderAvatar
                    @unknown default:
                        placeholderAvatar
                    }
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Text(firstLetter)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

private struct ChainBadge: View {
    let chain: String

    private var chainIcon: String {
        switch chain.lowercased() {
        case "ethereum": return "⟠"
        case "solana": return "◎"
        case "base": return "🔵"
        case "polygon": return "⬡"
        case "bsc", "binance": return "🟡"
        case "arbitrum": return "🔷"
        case "optimism": return "🔴"
        case "avalanche": return "🔺"
        default: return "⚡"
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(chainIcon)
                .font(.system(size: 10))

            Text(chain)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.cardBackgroundElevated)
        .cornerRadius(4)
    }
}

private struct NewBadge: View {
    @State private var pulse = false

    var body: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red)
            .cornerRadius(4)
            .scaleEffect(pulse ? 1.05 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                pulse = true
            }
    }
}

private struct HourlyChangeBadge: View {
    let change: Double
    let prominent: Bool

    private var color: Color {
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

    private var icon: String {
        if change > 100 {
            return "flame.fill"
        } else if change > 50 {
            return "bolt.fill"
        } else if change > 0 {
            return "arrow.up"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: prominent ? 14 : 11, weight: .bold))

            Text(Formatters.percentage(change))
                .font(.system(size: prominent ? 15 : 12, weight: .bold))

            Text("1H")
                .font(.system(size: prominent ? 10 : 9, weight: .semibold))
                .opacity(0.9)
        }
        .foregroundColor(color)
        .padding(.horizontal, prominent ? 10 : 8)
        .padding(.vertical, prominent ? 6 : 4)
        .background(color.opacity(0.15))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        // Extremely hot coin (>100% change)
        ViralCoinCard(
            coin: Coin(
                id: "test1",
                symbol: "PEPE",
                name: "Pepe",
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
                symbol: "WIF",
                name: "Dogwifhat",
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
                symbol: "BONK",
                name: "Bonk",
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
