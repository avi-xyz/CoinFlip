import SwiftUI

struct CoinCard: View {
    let coin: Coin
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            BaseCard {
                HStack(spacing: Spacing.md) {
                    AsyncImage(url: coin.image) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            Circle().fill(Color.cardBackgroundElevated)
                                .overlay(Text(coin.symbol.prefix(1).uppercased()).font(.headline3).foregroundColor(.textSecondary))
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(coin.symbol.uppercased()).font(.headline3).foregroundColor(.textPrimary)
                        Text(coin.name).font(.bodySmall).foregroundColor(.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text(coin.formattedPrice).font(.numberSmall).foregroundColor(.textPrimary)
                        Text(coin.formattedChange).font(.labelSmall).foregroundColor(coin.isUp ? .gainGreen : .lossRed)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MockData.coins) { coin in
            CoinCard(coin: coin) { print("Tapped \(coin.name)") }
        }
    }
    .padding()
    .background(Color.appBackground)
}
