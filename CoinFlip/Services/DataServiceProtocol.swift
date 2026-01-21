//
//  DataServiceProtocol.swift
//  CoinFlip
//
//  Created on Sprint 11, Task 11.3
//  Service layer protocol for data operations
//

import Foundation

/// Protocol defining data operations for the app
///
/// This protocol abstracts data access, allowing the app to work with
/// either mock data (MockDataService) or real backend data (SupabaseDataService)
protocol DataServiceProtocol {

    // MARK: - User Operations

    /// Fetches the current user
    /// - Returns: User if found, nil if not authenticated
    func fetchUser() async throws -> User?

    /// Creates a new user
    /// - Parameter user: The user to create
    /// - Returns: The created user with database-generated fields
    func createUser(_ user: User) async throws -> User

    /// Updates an existing user
    /// - Parameter user: The user to update
    /// - Returns: The updated user
    func updateUser(_ user: User) async throws -> User

    // MARK: - Portfolio Operations

    /// Fetches the portfolio for a given user
    /// - Parameter userId: The user's ID
    /// - Returns: The user's portfolio
    func fetchPortfolio(userId: UUID) async throws -> Portfolio

    /// Updates the portfolio (cash balance, etc.)
    /// - Parameter portfolio: The portfolio to update
    /// - Returns: The updated portfolio
    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio

    /// Creates a new portfolio for a user
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - startingBalance: Initial cash balance
    /// - Returns: The created portfolio
    func createPortfolio(userId: UUID, startingBalance: Double) async throws -> Portfolio

    /// Updates portfolio net worth and gain percentage (for leaderboard accuracy)
    /// - Parameters:
    ///   - portfolioId: The portfolio's ID
    ///   - netWorth: Current net worth (cash + holdings value)
    ///   - gainPercentage: Gain/loss percentage since starting balance
    func updatePortfolioNetWorth(portfolioId: UUID, netWorth: Double, gainPercentage: Double) async throws

    // MARK: - Holdings Operations

    /// Fetches all holdings for a portfolio
    /// - Parameter portfolioId: The portfolio's ID
    /// - Returns: Array of holdings
    func fetchHoldings(portfolioId: UUID) async throws -> [Holding]

    /// Creates a new holding or updates existing one
    /// - Parameter holding: The holding to create/update
    /// - Returns: The created/updated holding
    func upsertHolding(_ holding: Holding) async throws -> Holding

    /// Deletes a holding
    /// - Parameter holdingId: The holding's ID
    func deleteHolding(holdingId: UUID) async throws

    /// Deletes all holdings for a portfolio
    /// - Parameter portfolioId: The portfolio's ID
    func deleteAllHoldings(portfolioId: UUID) async throws

    // MARK: - Transaction Operations

    /// Fetches all transactions for a portfolio
    /// - Parameters:
    ///   - portfolioId: The portfolio's ID
    ///   - limit: Maximum number of transactions to return (default: 100)
    /// - Returns: Array of transactions, sorted by timestamp (newest first)
    func fetchTransactions(portfolioId: UUID, limit: Int) async throws -> [Transaction]

    /// Creates a new transaction
    /// - Parameter transaction: The transaction to create
    /// - Returns: The created transaction
    func createTransaction(_ transaction: Transaction) async throws -> Transaction

    /// Deletes all transactions for a portfolio
    /// - Parameter portfolioId: The portfolio's ID
    func deleteAllTransactions(portfolioId: UUID) async throws

    // MARK: - Leaderboard Operations

    /// Fetches leaderboard entries
    /// - Parameter limit: Number of entries to fetch
    /// - Returns: Array of leaderboard entries sorted by net worth
    func fetchLeaderboard(limit: Int) async throws -> [LeaderboardEntry]

    /// Fetches the current user's rank
    /// - Parameter userId: The user's ID
    /// - Returns: The user's leaderboard entry
    func fetchUserRank(userId: UUID) async throws -> LeaderboardEntry?
}

// MARK: - Default Parameter Values

extension DataServiceProtocol {
    func fetchTransactions(portfolioId: UUID, limit: Int = 100) async throws -> [Transaction] {
        try await fetchTransactions(portfolioId: portfolioId, limit: limit)
    }
}

// MARK: - Service Errors

enum DataServiceError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case portfolioNotFound
    case holdingNotFound
    case transactionFailed
    case invalidData
    case networkError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .userNotFound:
            return "User not found"
        case .portfolioNotFound:
            return "Portfolio not found"
        case .holdingNotFound:
            return "Holding not found"
        case .transactionFailed:
            return "Transaction failed"
        case .invalidData:
            return "Invalid data format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
