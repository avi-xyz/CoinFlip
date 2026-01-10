import SwiftUI

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Text(icon)
                }
                Text(title)
                    .font(.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.buttonHeight)
            .background(Color.cardBackground)
            .foregroundColor(.textPrimary)
            .cornerRadius(Spacing.buttonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.buttonRadius)
                    .stroke(Color.textMuted, lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton(title: "Skip", icon: "👀") { print("Skipped") }
        SecondaryButton(title: "Cancel") { print("Cancelled") }
    }
    .padding()
    .background(Color.appBackground)
}
