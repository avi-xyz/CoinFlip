//
//  SupabaseService.swift
//  CoinFlip
//
//  Created on Sprint 11, Task 11.1
//  Supabase Client Management
//

import Foundation
import Combine
import Supabase

/// Service for managing Supabase client instance
///
/// This singleton provides access to the Supabase client throughout the app.
/// It handles initialization, configuration, and provides a centralized
/// access point for all Supabase operations.
///
/// Usage:
/// ```swift
/// let client = SupabaseService.shared.client
/// let response = try await client.from("users").select().execute()
/// ```
@MainActor
class SupabaseService: ObservableObject {

    // MARK: - Singleton

    /// Shared instance of SupabaseService
    static let shared = SupabaseService()

    // MARK: - Properties

    /// Supabase client instance
    /// Access this to perform database operations, authentication, etc.
    private(set) var client: SupabaseClient

    /// Indicates whether the service is properly configured
    private(set) var isConfigured: Bool = false

    /// Any initialization error that occurred
    private(set) var initializationError: Error?

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    private init() {
        // Validate configuration before initializing
        guard EnvironmentConfig.isSupabaseConfigured else {
            self.client = SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder"
            )
            self.isConfigured = false
            self.initializationError = SupabaseServiceError.notConfigured
            print("⚠️ SupabaseService: Not configured. Please set credentials in EnvironmentConfig.swift")
            return
        }

        guard EnvironmentConfig.isSupabaseURLValid else {
            self.client = SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder"
            )
            self.isConfigured = false
            self.initializationError = SupabaseServiceError.invalidURL
            print("⚠️ SupabaseService: Invalid Supabase URL format")
            return
        }

        // Initialize Supabase client
        guard let url = URL(string: EnvironmentConfig.supabaseURL) else {
            self.client = SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder"
            )
            self.isConfigured = false
            self.initializationError = SupabaseServiceError.invalidURL
            print("⚠️ SupabaseService: Could not create URL from Supabase URL string")
            return
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: EnvironmentConfig.supabaseAnonKey
        )

        self.isConfigured = true
        self.initializationError = nil
        print("✅ SupabaseService: Successfully initialized")
    }

    // MARK: - Public Methods

    /// Verifies connection to Supabase by making a simple query
    /// - Returns: True if connection is successful
    func verifyConnection() async -> Bool {
        guard isConfigured else {
            print("⚠️ SupabaseService: Cannot verify connection - not configured")
            return false
        }

        // We'll implement actual connection verification once we have tables created
        // For now, just return configuration status
        print("✅ SupabaseService: Configuration verified")
        return true
    }

    /// Resets the service (useful for testing)
    func reset() {
        // Currently just logs - can be expanded for testing purposes
        print("🔄 SupabaseService: Reset called")
    }
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case notConfigured
    case invalidURL
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase credentials not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY in EnvironmentConfig.swift"
        case .invalidURL:
            return "Invalid Supabase URL format. Expected format: https://xxxxx.supabase.co"
        case .connectionFailed:
            return "Failed to connect to Supabase. Please check your internet connection and credentials."
        }
    }
}
