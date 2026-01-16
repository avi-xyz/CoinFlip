import SwiftUI

struct FeaturedCoinCard: View {
    let coin: Coin
    let onBuy: () -> Void
    let onSkip: () -> Void

    var body: some View {
        BaseCard(padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("🔥 TODAY'S COIN").font(.labelSmall).foregroundColor(.primaryPurple)
                    Spacer()
                }

                HStack(spacing: Spacing.md) {
                    AsyncImage(url: coin.image) { phase in
                        if let image = phase.image { image.resizable().scaledToFit() }
                        else { Circle().fill(Color.cardBackgroundElevated) }
                    }
                    .frame(width: 64, height: 64).clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(coin.name).font(.headline2).foregroundColor(.textPrimary)
                        HStack(spacing: Spacing.xs) {
                            Text(coin.formattedPrice).font(.numberSmall).foregroundColor(.textPrimary)
                            Text(coin.formattedChange).font(.labelSmall)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background((coin.isUp ? Color.gainGreen : Color.lossRed).opacity(0.2))
                                .foregroundColor(coin.isUp ? .gainGreen : .lossRed)
                                .cornerRadius(6)
                        }
                    }
                    Spacer()
                }

                if let sparkline = coin.sparklineIn7d?.price {
                    SparklineView(data: sparkline).frame(height: 60)
                }

                Text(coinStory).font(.bodySmall).foregroundColor(.textSecondary).lineLimit(2)

                HStack(spacing: Spacing.md) {
                    PrimaryButton(title: "Buy", icon: "🚀", action: onBuy)
                        .accessibilityIdentifier("buyFeatured_\(coin.symbol)")
                    SecondaryButton(title: "Skip", icon: "👀", action: onSkip)
                        .accessibilityIdentifier("skipFeatured_\(coin.symbol)")
                }
            }
        }
    }

    private var coinStory: String {
        switch coin.id {
        case "pepe": return "The OG meme frog is making waves again. Will you catch the pump? 🐸"
        case "dogecoin": return "The people's crypto, backed by Elon's tweets. Much wow potential. 🐕"
        case "shiba-inu": return "The DOGE killer is looking for its next run. Ready to ride? 🚀"
        case "dogwifcoin": return "A dog with a hat. That's it. That's the investment thesis. 🎩"
        case "bonk": return "Solana's favorite dog coin is barking up. Join the pack? 🦴"
        default: return "Another day, another meme coin opportunity. WAGMI? 🌙"
        }
    }
}

#Preview {
    ScrollView {
        FeaturedCoinCard(coin: MockData.featuredCoin, onBuy: {}, onSkip: {})
            .padding()
    }
    .background(Color.appBackground)
}
