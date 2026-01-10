import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let showChevron: Bool
    let iconColor: Color
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        showChevron: Bool = true,
        iconColor: Color = .primaryGreen,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.showChevron = showChevron
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            BaseCard {
                HStack(spacing: Spacing.md) {
                    // Icon
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(iconColor.opacity(0.1))
                        .clipShape(Circle())

                    // Title & Subtitle
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(title)
                            .font(.headline3)
                            .foregroundColor(.textPrimary)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    // Value & Chevron
                    HStack(spacing: Spacing.sm) {
                        if let value = value {
                            Text(value)
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                        }

                        if showChevron {
                            Image(systemName: "chevron.right")
                                .font(.labelMedium)
                                .foregroundColor(.textMuted)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        SettingsRow(
            icon: "person.circle.fill",
            title: "Edit Profile",
            subtitle: "Change your avatar and username",
            iconColor: .primaryGreen
        )

        SettingsRow(
            icon: "bell.fill",
            title: "Notifications",
            value: "On",
            iconColor: .primaryPurple
        )

        SettingsRow(
            icon: "info.circle.fill",
            title: "App Version",
            value: "1.0.0",
            showChevron: false,
            iconColor: .textSecondary
        ) {}

        SettingsRow(
            icon: "arrow.right.circle.fill",
            title: "Sign Out",
            iconColor: .lossRed
        )
    }
    .padding()
    .background(Color.appBackground)
}
