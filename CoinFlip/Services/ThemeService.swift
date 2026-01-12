import Foundation
import SwiftUI
import Combine

enum Theme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

@MainActor
class ThemeService: ObservableObject {
    static let shared = ThemeService()

    @Published var currentTheme: Theme {
        didSet {
            saveTheme()
        }
    }

    private let userDefaultsKey = "app_theme"

    private init() {
        // Load saved theme or default to system
        if let savedTheme = UserDefaults.standard.string(forKey: userDefaultsKey),
           let theme = Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: userDefaultsKey)
        print("💡 Theme saved: \(currentTheme.rawValue)")
    }

    func setTheme(_ theme: Theme) {
        currentTheme = theme
        HapticManager.shared.impact(.light)
    }
}
