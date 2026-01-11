import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var authUserId: UUID?  // Links to Supabase auth.users
    var username: String
    var avatarEmoji: String
    var startingBalance: Double
    var createdAt: Date
    var updatedAt: Date?
    var highestNetWorth: Double
    var currentStreak: Int
    var bestStreak: Int

    // CodingKeys for snake_case database columns
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case username
        case avatarEmoji = "avatar_emoji"
        case startingBalance = "starting_balance"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case highestNetWorth = "highest_net_worth"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
    }

    init(
        id: UUID = UUID(),
        authUserId: UUID? = nil,
        username: String,
        startingBalance: Double = 1000,
        avatarEmoji: String? = nil
    ) {
        self.id = id
        self.authUserId = authUserId
        self.username = username
        self.startingBalance = startingBalance
        self.avatarEmoji = avatarEmoji ?? ["🚀", "💎", "🔥", "⚡️", "🎯", "🦊", "🐸", "🐕"].randomElement()!
        self.createdAt = Date()
        self.updatedAt = nil
        self.highestNetWorth = startingBalance
        self.currentStreak = 0
        self.bestStreak = 0
    }
}
