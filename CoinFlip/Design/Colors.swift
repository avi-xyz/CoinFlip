import SwiftUI
import UIKit

extension Color {
    // MARK: - Adaptive Colors (Light/Dark Mode)

    /// Main app background
    static let appBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "0A0A0A")
            : UIColor(hex: "F2F2F7")
    })

    /// Card/container background
    static let cardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "1A1A1A")
            : UIColor.white
    })

    /// Elevated card background (modals, overlays)
    static let cardBackgroundElevated = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "252525")
            : UIColor(hex: "F8F8F8")
    })

    /// Primary text color
    static let textPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(hex: "1A1A1A")
    })

    /// Secondary text color
    static let textSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "888888")
            : UIColor(hex: "6B6B6B")
    })

    /// Muted text color
    static let textMuted = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "555555")
            : UIColor(hex: "999999")
    })

    /// Border color
    static let borderPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "333333")
            : UIColor(hex: "E0E0E0")
    })

    // MARK: - Brand Colors (Same in both modes)

    static let primaryGreen = Color(hex: "00FF7F")
    static let primaryPurple = Color(hex: "A855F7")
    static let gainGreen = Color(hex: "00FF7F")
    static let lossRed = Color(hex: "FF3B5C")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: Double(a) / 255)
    }
}
