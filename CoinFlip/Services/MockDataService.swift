//
//  MockDataService.swift
//  CoinFlip
//
//  Created on Sprint 11, Task 11.3
//  Mock implementation of DataServiceProtocol for development
//

import Foundation

/// Mock data service for development and testing
///
/// This service provides in-memory data storage using the existing MockData.
/// Perfect for development, testing, and when working offline.
@MainActor
class MockDataService: DataServiceProtocol {

    // MARK: - Properties

    private var currentUser: User = MockData.user
    private var portfolio: Portfolio = MockData.portfolioWithHoldings
    private var holdings: [Holding] = []
    private var transactions: [Transaction] = []

    // MARK: - Initialization

    init() {
        // Initialize with mock data
        self.holdings = portfolio.holdings
        self.transactions = portfolio.transactions
    }

    // MARK: - User Operations

    func fetchUser() async throws -> User? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return currentUser
    }

    func createUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000)
        currentUser = user
        // Create default portfolio for new user
        portfolio = Portfolio(userId: user.id, startingBalance: user.startingBalance)
        holdings = []
        transactions = []
        return currentUser
    }

    func updateUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        currentUser = user
        return currentUser
    }

    // MARK: - Portfolio Operations

    func fetchPortfolio(userId: UUID) async throws -> Portfolio {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard userId == currentUser.id else {
            throw DataServiceError.portfolioNotFound
        }

        // Return portfolio with current holdings and transactions
        var updatedPortfolio = portfolio
        updatedPortfolio.holdings = holdings
        updatedPortfolio.transactions = transactions
        return updatedPortfolio
    }

    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard portfolio.userId == currentUser.id else {
            throw DataServiceError.portfolioNotFound
        }

        self.portfolio = portfolio
        return portfolio
    }

    func createPortfolio(userId: UUID, startingBalance: Double) async throws -> Portfolio {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard userId == currentUser.id else {
            throw DataServiceError.userNotFound
        }

        let newPortfolio = Portfolio(userId: userId, startingBalance: startingBalance)
        self.portfolio = newPortfolio
        self.holdings = []
        self.transactions = []
        return newPortfolio
    }

    func updatePortfolioNetWorth(portfolioId: UUID, netWorth: Double, gainPercentage: Double) async throws {
        // Mock implementation - no-op since we don't persist net worth in mock mode
        print("MockDataService: Updated portfolio \(portfolioId) net worth: $\(netWorth) (\(gainPercentage)%)")
    }

    // MARK: - Holdings Operations

    func fetchHoldings(portfolioId: UUID) async throws -> [Holding] {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds

        guard portfolioId == portfolio.id else {
            throw DataServiceError.portfolioNotFound
        }

        return holdings
    }

    func upsertHolding(_ holding: Holding) async throws -> Holding {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard holding.portfolioId == portfolio.id else {
            throw DataServiceError.portfolioNotFound
        }

        // Check if holding exists
        if let index = holdings.firstIndex(where: { $0.id == holding.id }) {
            // Update existing
            holdings[index] = holding
        } else if let index = holdings.firstIndex(where: { $0.coinId == holding.coinId }) {
            // Update by coinId (merge holdings of same coin)
            holdings[index] = holding
        } else {
            // Create new
            holdings.append(holding)
        }

        return holding
    }

    func deleteHolding(holdingId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard let index = holdings.firstIndex(where: { $0.id == holdingId }) else {
            throw DataServiceError.holdingNotFound
        }

        holdings.remove(at: index)
    }

    func deleteAllHoldings(portfolioId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard portfolioId == portfolio.id else {
            throw DataServiceError.portfolioNotFound
        }

        holdings.removeAll()
    }

    func updateHoldingChainId(holdingId: UUID, chainId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = holdings.firstIndex(where: { $0.id == holdingId }) else {
            throw DataServiceError.holdingNotFound
        }

        // Note: Since Holding is a struct, we can't directly modify the chainId
        // In mock mode, this is a no-op as we don't persist data
        print("MockDataService: Updated holding \(holdingId) with chainId: \(chainId)")
    }

    // MARK: - Transaction Operations

    func fetchTransactions(portfolioId: UUID, limit: Int = 100) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: 400_000_000)

        guard portfolioId == portfolio.id else {
            throw DataServiceError.portfolioNotFound
        }

        // Return transactions sorted by timestamp (newest first), limited
        return Array(transactions
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit))
    }

    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard transaction.portfolioId == portfolio.id else {
            throw DataServiceError.portfolioNotFound
        }

        transactions.insert(transaction, at: 0)
        return transaction
    }

    func deleteAllTransactions(portfolioId: UUID) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        guard portfolioId == portfolio.id else {
            throw DataServiceError.portfolioNotFound
        }

        transactions.removeAll()
    }

    // MARK: - Leaderboard Operations

    func fetchLeaderboard(limit: Int) async throws -> [LeaderboardEntry] {
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        // Return mock leaderboard data
        return Array(MockData.leaderboard.prefix(limit))
    }

    func fetchUserRank(userId: UUID) async throws -> LeaderboardEntry? {
        try await Task.sleep(nanoseconds: 400_000_000)

        // Find current user in leaderboard
        return MockData.leaderboard.first { $0.isCurrentUser }
    }

    // MARK: - Helper Methods

    /// Resets all data to initial mock state (useful for testing)
    func reset() {
        currentUser = MockData.user
        portfolio = MockData.portfolioWithHoldings
        holdings = portfolio.holdings
        transactions = portfolio.transactions
    }
}
