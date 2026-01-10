import SwiftUI

struct AvatarPicker: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    private let avatars = [
        "😀", "😎", "🤓", "🥳", "🤩", "🤑",
        "👑", "🚀", "💎", "🔥", "⚡️", "🌟",
        "🐶", "🐱", "🦊", "🐻", "🐼", "🦁",
        "🐸", "🐵", "🦄", "🐉", "🦅", "🦉",
        "🌈", "🎯", "🎪", "🎨", "🎭", "🎸",
        "💰", "💵", "💸", "📈", "📊", "🎰"
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 70))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(avatars, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            HapticManager.shared.impact(.light)
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 70, height: 70)
                                .background(selectedEmoji == emoji ? Color.primaryGreen.opacity(0.2) : Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.md)
                                        .stroke(selectedEmoji == emoji ? Color.primaryGreen : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(Spacing.md)
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

#Preview {
    AvatarPicker(selectedEmoji: .constant("🚀"))
}
