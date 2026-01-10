import SwiftUI

struct BaseCard<Content: View>: View {
    var padding: CGFloat = Spacing.cardPadding
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(Color.cardBackground)
            .cornerRadius(Spacing.cardRadius)
    }
}

#Preview {
    VStack(spacing: 20) {
        BaseCard {
            Text("Default padding")
                .foregroundColor(.textPrimary)
        }
        BaseCard(padding: Spacing.lg) {
            Text("Large padding")
                .foregroundColor(.textPrimary)
        }
    }
    .padding()
    .background(Color.appBackground)
}
