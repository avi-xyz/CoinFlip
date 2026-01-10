import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    if let icon = icon {
                        Text(icon)
                    }
                    Text(title)
                        .font(.labelLarge)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.buttonHeight)
            .background(isDisabled ? Color.textMuted : Color.primaryGreen)
            .foregroundColor(.black)
            .cornerRadius(Spacing.buttonRadius)
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Buy Now", icon: "🚀") { print("Tapped") }
        PrimaryButton(title: "Loading", isLoading: true) {}
        PrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .background(Color.appBackground)
}
