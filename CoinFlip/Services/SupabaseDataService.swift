//
//  SupabaseDataService.swift
//  CoinFlip
//
//  Created on Sprint 11, Task 11.3
//  Real implementation of DataServiceProtocol using Supabase
//

import Foundation
import Supabase

/// Supabase data service for production
///
/// This service implements DataServiceProtocol using Supabase as the backend.
/// All operations are async and interact with the PostgreSQL database.
@MainActor
class SupabaseDataService: DataServiceProtocol {

    // MARK: - Properties

    private let supabase: SupabaseClient

    // MARK: - Initialization

    init() {
        self.supabase = SupabaseService.shared.client
    }

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // MARK: - User Operations

    func fetchUser() async throws -> User? {
        // Get current auth user
        guard let authUser = try? await supabase.auth.session.user else {
            throw DataServiceError.notAuthenticated
        }

        // Fetch user from database
        let response = try await supabase
            .from("users")
            .select()
            .eq("auth_user_id", value: authUser.id.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let user = try decoder.decode(User.self, from: response.data)
        return user
    }

    func createUser(_ user: User) async throws -> User {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let userData = try encoder.encode(user)

        let response = try await supabase
            .from("users")
            .insert(userData)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let createdUser = try decoder.decode(User.self, from: response.data)
        return createdUser
    }

    func updateUser(_ user: User) async throws -> User {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let userData = try encoder.encode(user)

        let response = try await supabase
            .from("users")
            .update(userData)
            .eq("id", value: user.id.uuidString)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let updatedUser = try decoder.decode(User.self, from: response.data)
        return updatedUser
    }

    // MARK: - Portfolio Operations

    func fetchPortfolio(userId: UUID) async throws -> Portfolio {
        let response = try await supabase
            .from("portfolios")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        var portfolio = try decoder.decode(Portfolio.self, from: response.data)

        // Fetch associated holdings and transactions
        portfolio.holdings = try await fetchHoldings(portfolioId: portfolio.id)
        portfolio.transactions = try await fetchTransactions(portfolioId: portfolio.id, limit: 100)

        return portfolio
    }

    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        // Only encode the portfolio data, not holdings/transactions
        let updateData: [String: Any] = [
            "cash_balance": portfolio.cashBalance,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: updateData)

        let response = try await supabase
            .from("portfolios")
            .update(jsonData)
            .eq("id", value: portfolio.id.uuidString)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        var updatedPortfolio = try decoder.decode(Portfolio.self, from: response.data)
        updatedPortfolio.holdings = portfolio.holdings
        updatedPortfolio.transactions = portfolio.transactions

        return updatedPortfolio
    }

    func createPortfolio(userId: UUID, startingBalance: Double) async throws -> Portfolio {
        let newPortfolio = Portfolio(userId: userId, startingBalance: startingBalance)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let portfolioData = try encoder.encode(newPortfolio)

        let response = try await supabase
            .from("portfolios")
            .insert(portfolioData)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let createdPortfolio = try decoder.decode(Portfolio.self, from: response.data)
        return createdPortfolio
    }

    // MARK: - Holdings Operations

    func fetchHoldings(portfolioId: UUID) async throws -> [Holding] {
        let response = try await supabase
            .from("holdings")
            .select()
            .eq("portfolio_id", value: portfolioId.uuidString)
            .order("first_purchase_date", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let holdings = try decoder.decode([Holding].self, from: response.data)
        return holdings
    }

    func upsertHolding(_ holding: Holding) async throws -> Holding {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let holdingData = try encoder.encode(holding)

        // Check if holding exists
        let existingResponse = try? await supabase
            .from("holdings")
            .select()
            .eq("portfolio_id", value: holding.portfolioId.uuidString)
            .eq("coin_id", value: holding.coinId)
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        if existingResponse != nil {
            // Update existing holding
            let updateResponse = try await supabase
                .from("holdings")
                .update(holdingData)
                .eq("portfolio_id", value: holding.portfolioId.uuidString)
                .eq("coin_id", value: holding.coinId)
                .select()
                .single()
                .execute()

            let upsertedHolding = try decoder.decode(Holding.self, from: updateResponse.data)
            return upsertedHolding
        } else {
            // Insert new holding
            let insertResponse = try await supabase
                .from("holdings")
                .insert(holdingData)
                .select()
                .single()
                .execute()

            let upsertedHolding = try decoder.decode(Holding.self, from: insertResponse.data)
            return upsertedHolding
        }
    }

    func deleteHolding(holdingId: UUID) async throws {
        _ = try await supabase
            .from("holdings")
            .delete()
            .eq("id", value: holdingId.uuidString)
            .execute()
    }

    // MARK: - Transaction Operations

    func fetchTransactions(portfolioId: UUID, limit: Int = 100) async throws -> [Transaction] {
        let response = try await supabase
            .from("transactions")
            .select()
            .eq("portfolio_id", value: portfolioId.uuidString)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let transactions = try decoder.decode([Transaction].self, from: response.data)
        return transactions
    }

    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let transactionData = try encoder.encode(transaction)

        let response = try await supabase
            .from("transactions")
            .insert(transactionData)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let createdTransaction = try decoder.decode(Transaction.self, from: response.data)
        return createdTransaction
    }

    // MARK: - Leaderboard Operations

    func fetchLeaderboard(limit: Int) async throws -> [LeaderboardEntry] {
        // TODO: Implement with PostgreSQL function in Sprint 16
        // For now, return empty array
        print("⚠️ SupabaseDataService: fetchLeaderboard not yet implemented")
        return []
    }

    func fetchUserRank(userId: UUID) async throws -> LeaderboardEntry? {
        // TODO: Implement with PostgreSQL function in Sprint 16
        // For now, return nil
        print("⚠️ SupabaseDataService: fetchUserRank not yet implemented")
        return nil
    }
}
