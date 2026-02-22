import SwiftUI

struct OnboardingPage: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Text(emoji)
                .font(.system(size: 120))

            VStack(spacing: Spacing.md) {
                Text(title)
                    .font(.displayMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.bodyLarge)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack {
        OnboardingPage(
            emoji: "🪙",
            title: "Welcome to CoinDojo",
            subtitle: "Learn crypto trading with virtual money. No risk, all the fun!"
        )
        .background(Color.appBackground)
    }
}
