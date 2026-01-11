//
//  MockDataServiceTests.swift
//  CoinFlipTests
//
//  Created on Sprint 11, Task 11.4
//  Unit tests for MockDataService
//

import XCTest
@testable import CoinFlip

@MainActor
final class MockDataServiceTests: XCTestCase {

    var sut: MockDataService!

    override func setUp() async throws {
        try await super.setUp()
        sut = MockDataService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - User Operations Tests

    func testFetchUser() async throws {
        // When
        let user = try await sut.fetchUser()

        // Then
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.username, "cryptokid_2009")
    }

    func testCreateUser() async throws {
        // Given
        let newUser = User(username: "newuser", startingBalance: 1000, avatarEmoji: "🚀")

        // When
        let createdUser = try await sut.createUser(newUser)

        // Then
        XCTAssertEqual(createdUser.username, "newuser")
        XCTAssertEqual(createdUser.startingBalance, 1000)

        // Verify it persisted
        let fetchedUser = try await sut.fetchUser()
        XCTAssertEqual(fetchedUser?.username, "newuser")
    }

    func testUpdateUser() async throws {
        // Given
        var user = try await sut.fetchUser()!
        user.username = "updated_username"

        // When
        let updatedUser = try await sut.updateUser(user)

        // Then
        XCTAssertEqual(updatedUser.username, "updated_username")
    }

    // MARK: - Portfolio Operations Tests

    func testFetchPortfolio() async throws {
        // Given
        let user = try await sut.fetchUser()!

        // When
        let portfolio = try await sut.fetchPortfolio(userId: user.id)

        // Then
        XCTAssertEqual(portfolio.userId, user.id)
        XCTAssertGreaterThan(portfolio.holdings.count, 0)
    }

    func testUpdatePortfolio() async throws {
        // Given
        let user = try await sut.fetchUser()!
        var portfolio = try await sut.fetchPortfolio(userId: user.id)
        portfolio.cashBalance = 5000

        // When
        let updatedPortfolio = try await sut.updatePortfolio(portfolio)

        // Then
        XCTAssertEqual(updatedPortfolio.cashBalance, 5000)
    }

    func testCreatePortfolio() async throws {
        // Given
        let user = try await sut.fetchUser()!

        // When
        let newPortfolio = try await sut.createPortfolio(userId: user.id, startingBalance: 2000)

        // Then
        XCTAssertEqual(newPortfolio.startingBalance, 2000)
        XCTAssertEqual(newPortfolio.cashBalance, 2000)
    }

    // MARK: - Holdings Operations Tests

    func testFetchHoldings() async throws {
        // Given
        let user = try await sut.fetchUser()!
        let portfolio = try await sut.fetchPortfolio(userId: user.id)

        // When
        let holdings = try await sut.fetchHoldings(portfolioId: portfolio.id)

        // Then
        XCTAssertGreaterThan(holdings.count, 0)
    }

    func testUpsertHolding() async throws {
        // Given
        let user = try await sut.fetchUser()!
        let portfolio = try await sut.fetchPortfolio(userId: user.id)
        let coin = MockData.coins[0]
        let holding = Holding(portfolioId: portfolio.id, coin: coin, quantity: 100, buyPrice: 0.08)

        // When
        let upsertedHolding = try await sut.upsertHolding(holding)

        // Then
        XCTAssertEqual(upsertedHolding.quantity, 100)
        XCTAssertEqual(upsertedHolding.coinId, coin.id)
    }

    func testDeleteHolding() async throws {
        // Given
        let user = try await sut.fetchUser()!
        let portfolio = try await sut.fetchPortfolio(userId: user.id)
        let holdings = try await sut.fetchHoldings(portfolioId: portfolio.id)
        let holdingToDelete = holdings.first!

        // When
        try await sut.deleteHolding(holdingId: holdingToDelete.id)

        // Then
        let remainingHoldings = try await sut.fetchHoldings(portfolioId: portfolio.id)
        XCTAssertEqual(remainingHoldings.count, holdings.count - 1)
    }

    // MARK: - Transaction Operations Tests

    func testFetchTransactions() async throws {
        // Given
        let user = try await sut.fetchUser()!
        let portfolio = try await sut.fetchPortfolio(userId: user.id)

        // When
        let transactions = try await sut.fetchTransactions(portfolioId: portfolio.id, limit: 10)

        // Then
        XCTAssertGreaterThan(transactions.count, 0)
    }

    func testCreateTransaction() async throws {
        // Given
        let user = try await sut.fetchUser()!
        let portfolio = try await sut.fetchPortfolio(userId: user.id)
        let coin = MockData.coins[0]
        let transaction = Transaction(portfolioId: portfolio.id, coin: coin, type: .buy, quantity: 100)

        // When
        let createdTransaction = try await sut.createTransaction(transaction)

        // Then
        XCTAssertEqual(createdTransaction.type, .buy)
        XCTAssertEqual(createdTransaction.quantity, 100)

        // Verify it persisted
        let transactions = try await sut.fetchTransactions(portfolioId: portfolio.id, limit: 10)
        XCTAssertTrue(transactions.contains(where: { $0.id == createdTransaction.id }))
    }

    // MARK: - Leaderboard Operations Tests

    func testFetchLeaderboard() async throws {
        // When
        let leaderboard = try await sut.fetchLeaderboard(limit: 5)

        // Then
        XCTAssertGreaterThan(leaderboard.count, 0)
        XCTAssertLessThanOrEqual(leaderboard.count, 5)
    }

    func testFetchUserRank() async throws {
        // Given
        let user = try await sut.fetchUser()!

        // When
        let userRank = try await sut.fetchUserRank(userId: user.id)

        // Then
        XCTAssertNotNil(userRank)
        XCTAssertTrue(userRank?.isCurrentUser ?? false)
    }

    // MARK: - Error Handling Tests

    func testFetchPortfolioWithInvalidUserId() async throws {
        // Given
        let invalidUserId = UUID()

        // When/Then
        do {
            _ = try await sut.fetchPortfolio(userId: invalidUserId)
            XCTFail("Should throw portfolioNotFound error")
        } catch DataServiceError.portfolioNotFound {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testFetchUserPerformance() async throws {
        measure {
            Task { @MainActor in
                _ = try? await sut.fetchUser()
            }
        }
    }
}
