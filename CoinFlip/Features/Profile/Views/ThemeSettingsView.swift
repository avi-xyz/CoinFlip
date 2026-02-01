import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeService = ThemeService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("🎨")
                            .font(.system(size: 60))

                        Text("Theme")
                            .font(.headline1)
                            .foregroundColor(.textPrimary)

                        Text("Choose your preferred theme")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, Spacing.xl)

                    // Theme Options
                    VStack(spacing: Spacing.md) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            ThemeOption(
                                theme: theme,
                                isSelected: themeService.currentTheme == theme
                            ) {
                                themeService.setTheme(theme)
                            }
                        }
                    }

                    // Info
                    VStack(spacing: Spacing.sm) {
                        Text("Note")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("System theme will automatically match your device's appearance settings.")
                            .font(.caption)
                            .foregroundColor(.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(Spacing.md)

                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .preferredColorScheme(themeService.currentTheme.colorScheme)
    }
}

struct ThemeOption: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BaseCard {
                HStack(spacing: Spacing.md) {
                    // Icon
                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.2))
                        .clipShape(Circle())

                    // Title
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(theme.rawValue)
                            .font(.bodyLarge)
                            .foregroundColor(.textPrimary)

                        Text(themeDescription)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    // Checkmark
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primaryGreen)
                            .font(.title2)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.textMuted)
                            .font(.title2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch theme {
        case .light:
            return .yellow
        case .dark:
            return .purple
        case .system:
            return .blue
        }
    }

    private var themeDescription: String {
        switch theme {
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        case .system:
            return "Match system settings"
        }
    }
}

#Preview {
    ThemeSettingsView()
}
