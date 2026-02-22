//
//  LearnView.swift
//  CoinFlip
//
//  Created on Sprint 18 - App Store Readiness
//  Educational content for crypto beginners
//

import SwiftUI

struct LearnView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Introduction
                    IntroCard()

                    // Crypto Basics
                    LearnSection(
                        icon: "🪙",
                        title: "What is Cryptocurrency?",
                        content: "Digital money that exists on blockchain networks. Bitcoin was the first in 2009, now there are thousands! Each coin has its own purpose, price, and community."
                    )

                    LearnSection(
                        icon: "🔗",
                        title: "What is a Blockchain?",
                        content: "A blockchain is like a digital ledger that records all transactions. It's called a 'chain' because new records (blocks) are linked to previous ones. Different coins run on different blockchains—like Ethereum, Solana, or Base."
                    )

                    // Reading Charts
                    LearnSection(
                        icon: "📊",
                        title: "How to Read Price Charts",
                        content: "Green means the price went up, red means it went down. The sparkline shows 7 days of price history. A coin's '24h change' tells you if it's trending up or down today."
                    )

                    LearnSection(
                        icon: "💹",
                        title: "What is Market Cap?",
                        content: "Market cap = price × total supply. It shows how 'big' a cryptocurrency is. Bitcoin has the highest market cap. Smaller market cap coins can be more volatile (risky but potentially rewarding in real trading)."
                    )

                    // Trading Basics
                    LearnSection(
                        icon: "💰",
                        title: "Buying & Selling",
                        content: "Buy low, sell high—that's the goal! Your profit or loss is the difference between what you paid (buy price) and what you receive (sell price). In CoinDojo, practice this risk-free with virtual money."
                    )

                    LearnSection(
                        icon: "📈",
                        title: "Portfolio & Net Worth",
                        content: "Your net worth = cash + value of all holdings. As coin prices change, your net worth goes up or down. Diversifying (owning multiple coins) can reduce risk."
                    )

                    LearnSection(
                        icon: "💸",
                        title: "Understanding Profit/Loss",
                        content: "If you bought a coin for $100 and it's now worth $150, you have a $50 profit (50% gain). If it's worth $75, you have a $25 loss (25% loss). In CoinDojo, these are unrealized until you sell."
                    )

                    // Advanced Concepts
                    LearnSection(
                        icon: "🔥",
                        title: "What are Viral/Meme Coins?",
                        content: "Newly launched coins with high activity and volatility. They can gain or lose 50%+ in minutes! Great for learning about market dynamics, but extremely risky in real trading. Only invest what you can afford to lose."
                    )

                    LearnSection(
                        icon: "🌐",
                        title: "Multi-Chain Trading",
                        content: "Coins can exist on different blockchains. The same token might be on Ethereum (slower, expensive) and Solana (faster, cheaper). Each chain has different fees and speeds. CoinDojo shows you which chain each coin is on."
                    )

                    // Strategy
                    LearnSection(
                        icon: "🎯",
                        title: "Basic Trading Strategies",
                        content: "1. HODL: Buy and hold long-term. 2. Day Trading: Buy/sell frequently. 3. Dollar-Cost Averaging: Invest regularly over time. 4. Diversification: Spread money across different coins. Try all strategies in CoinDojo!"
                    )

                    LearnSection(
                        icon: "🏆",
                        title: "The Leaderboard",
                        content: "Everyone starts with $1,000. Your rank is based on your net worth. Top traders have grown their virtual money through smart buying and selling. Can you reach the top?"
                    )

                    // Important Disclaimer
                    DisclaimerCard()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("Learn Crypto")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct IntroCard: View {
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title)
                        .foregroundColor(.primaryGreen)

                    Text("New to Crypto?")
                        .font(.headline2)
                        .foregroundColor(.textPrimary)
                }

                Text("You're in the right place! This guide explains everything you need to know to start trading in CoinDojo. All the concepts you learn here apply to real crypto trading too.")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)

                Text("Remember: CoinDojo uses virtual money. It's a safe space to learn, make mistakes, and build confidence before considering real trading.")
                    .font(.bodySmall)
                    .foregroundColor(.textMuted)
                    .italic()
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

struct LearnSection: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    Text(icon)
                        .font(.system(size: 40))

                    Text(title)
                        .font(.headline3)
                        .foregroundColor(.textPrimary)
                }

                Text(content)
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct DisclaimerCard: View {
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Important Reminder")
                        .font(.headline3)
                        .foregroundColor(.textPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    BulletPoint(text: "CoinDojo uses VIRTUAL money only")
                    BulletPoint(text: "All trades are simulated—not real")
                    BulletPoint(text: "This is NOT financial advice")
                    BulletPoint(text: "Real crypto trading involves significant risk")
                    BulletPoint(text: "Never invest more than you can afford to lose")
                    BulletPoint(text: "Do your own research before real trading")
                }

                Text("CoinDojo is an educational tool. Consult licensed financial advisors before making real investment decisions.")
                    .font(.bodySmall)
                    .foregroundColor(.textMuted)
                    .italic()
                    .padding(.top, Spacing.xs)
            }
            .padding(.vertical, Spacing.sm)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cardRadius)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("•")
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)

            Text(text)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    LearnView()
}
