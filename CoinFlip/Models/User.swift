import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var username: String
    var avatarEmoji: String
    var startingBalance: Double
    var createdAt: Date
    var highestNetWorth: Double
    var currentStreak: Int
    var bestStreak: Int

    init(id: UUID = UUID(), username: String, startingBalance: Double = 100, avatarEmoji: String? = nil) {
        self.id = id
        self.username = username
        self.startingBalance = startingBalance
        self.avatarEmoji = avatarEmoji ?? ["🚀", "💎", "🔥", "⚡️", "🎯", "🦊", "🐸", "🐕"].randomElement()!
        self.createdAt = Date()
        self.highestNetWorth = startingBalance
        self.currentStreak = 0
        self.bestStreak = 0
    }
}
