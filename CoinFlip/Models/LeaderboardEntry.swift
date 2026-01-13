//
//  LeaderboardEntry.swift
//  CoinFlip
//
//  Created on Sprint 16
//  Model representing a user's leaderboard position
//

import Foundation

struct LeaderboardEntry: Identifiable, Codable {
    let id: UUID
    let rank: Int
    let username: String
    let avatarEmoji: String
    let netWorth: Double
    let percentageGain: Double
    var isCurrentUser: Bool

    init(rank: Int, username: String, avatarEmoji: String, netWorth: Double, percentageGain: Double, isCurrentUser: Bool = false) {
        self.id = UUID()
        self.rank = rank
        self.username = username
        self.avatarEmoji = avatarEmoji
        self.netWorth = netWorth
        self.percentageGain = percentageGain
        self.isCurrentUser = isCurrentUser
    }
}
