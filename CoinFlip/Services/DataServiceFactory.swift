//
//  DataServiceFactory.swift
//  CoinFlip
//
//  Created on Sprint 11, Task 11.3
//  Factory for creating data service instances
//

import Foundation

/// Factory for creating data service instances
///
/// This factory provides a centralized way to get the appropriate data service
/// based on the current environment configuration.
enum DataServiceFactory {

    /// Returns the appropriate data service based on configuration
    ///
    /// - Returns: Either MockDataService or SupabaseDataService based on `EnvironmentConfig.useMockData`
    @MainActor
    static func createDataService() -> DataServiceProtocol {
        if EnvironmentConfig.useMockData {
            print("📱 DataServiceFactory: Using MockDataService (offline mode)")
            return MockDataService()
        } else {
            print("☁️ DataServiceFactory: Using SupabaseDataService (online mode)")
            return SupabaseDataService()
        }
    }

    /// Shared instance for convenience
    ///
    /// Note: This is created once and reused. To switch between services,
    /// change `EnvironmentConfig.useMockData` and restart the app.
    @MainActor
    static let shared: DataServiceProtocol = createDataService()
}
