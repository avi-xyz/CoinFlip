import SwiftUI

extension Color {
    static let appBackground = Color(hex: "0A0A0A")
    static let cardBackground = Color(hex: "1A1A1A")
    static let cardBackgroundElevated = Color(hex: "252525")
    static let primaryGreen = Color(hex: "00FF7F")
    static let primaryPurple = Color(hex: "A855F7")
    static let gainGreen = Color(hex: "00FF7F")
    static let lossRed = Color(hex: "FF3B5C")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "888888")
    static let textMuted = Color(hex: "555555")
    static let borderPrimary = Color(hex: "333333")

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
