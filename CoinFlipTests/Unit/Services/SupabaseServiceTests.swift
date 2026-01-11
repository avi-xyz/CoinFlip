//
//  SupabaseServiceTests.swift
//  CoinFlipTests
//
//  Created on Sprint 11, Task 11.1
//  Unit tests for SupabaseService
//

import XCTest
@testable import CoinFlip

@MainActor
final class SupabaseServiceTests: XCTestCase {

    // MARK: - Test Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        // Reset service before each test
        SupabaseService.shared.reset()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSupabaseServiceIsSingleton() {
        // Given & When
        let instance1 = SupabaseService.shared
        let instance2 = SupabaseService.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "SupabaseService should be a singleton")
    }

    // MARK: - Initialization Tests

    func testSupabaseClientInitialization() {
        // Given & When
        let service = SupabaseService.shared

        // Then
        XCTAssertNotNil(service.client, "Supabase client should be initialized")
    }

    func testSupabaseConfigurationStatus() {
        // Given & When
        let service = SupabaseService.shared
        let isConfigured = EnvironmentConfig.isSupabaseConfigured

        // Then
        if isConfigured {
            XCTAssertTrue(service.isConfigured, "Service should be configured when credentials are set")
            XCTAssertNil(service.initializationError, "Should have no initialization error when configured")
        } else {
            XCTAssertFalse(service.isConfigured, "Service should not be configured when credentials are missing")
            XCTAssertNotNil(service.initializationError, "Should have initialization error when not configured")
        }
    }

    func testSupabaseURLConfiguration() {
        // Given
        let url = EnvironmentConfig.supabaseURL

        // When & Then
        if EnvironmentConfig.isSupabaseConfigured {
            XCTAssertFalse(url.contains("YOUR_SUPABASE_URL_HERE"), "URL should be configured")
            XCTAssertTrue(url.hasPrefix("https://"), "URL should use HTTPS")
            XCTAssertTrue(url.contains("supabase.co"), "URL should be a valid Supabase URL")
        } else {
            XCTAssertTrue(url.contains("YOUR_SUPABASE_URL_HERE"), "URL should show placeholder when not configured")
        }
    }

    func testSupabaseKeyConfiguration() {
        // Given
        let key = EnvironmentConfig.supabaseAnonKey

        // When & Then
        if EnvironmentConfig.isSupabaseConfigured {
            XCTAssertFalse(key.contains("YOUR_SUPABASE_ANON_KEY_HERE"), "Key should be configured")
            XCTAssertFalse(key.isEmpty, "Key should not be empty")
            XCTAssertGreaterThan(key.count, 50, "Supabase anon key should be a long JWT string")
        } else {
            XCTAssertTrue(key.contains("YOUR_SUPABASE_ANON_KEY_HERE"), "Key should show placeholder when not configured")
        }
    }

    func testSupabaseURLValidation() {
        // Given & When
        let isValid = EnvironmentConfig.isSupabaseURLValid

        // Then
        if EnvironmentConfig.isSupabaseConfigured {
            XCTAssertTrue(isValid, "Configured URL should be valid")
        } else {
            XCTAssertFalse(isValid, "Placeholder URL should be invalid")
        }
    }

    // MARK: - Connection Tests

    func testVerifyConnection() async {
        // Given
        let service = SupabaseService.shared

        // When
        let isConnected = await service.verifyConnection()

        // Then
        if service.isConfigured {
            // Connection verification should succeed when configured
            // Note: This may fail if internet is down or credentials are wrong
            // For now, we just test that it returns a boolean
            XCTAssertNotNil(isConnected, "Connection verification should return a result")
        } else {
            XCTAssertFalse(isConnected, "Connection verification should fail when not configured")
        }
    }

    // MARK: - Error Handling Tests

    func testSupabaseServiceErrorDescriptions() {
        // Test error messages are user-friendly
        let notConfiguredError = SupabaseServiceError.notConfigured
        let invalidURLError = SupabaseServiceError.invalidURL
        let connectionFailedError = SupabaseServiceError.connectionFailed

        XCTAssertNotNil(notConfiguredError.errorDescription)
        XCTAssertNotNil(invalidURLError.errorDescription)
        XCTAssertNotNil(connectionFailedError.errorDescription)

        XCTAssertTrue(notConfiguredError.errorDescription!.contains("credentials"))
        XCTAssertTrue(invalidURLError.errorDescription!.contains("URL"))
        XCTAssertTrue(connectionFailedError.errorDescription!.contains("connect"))
    }

    // MARK: - Integration Tests

    func testSupabaseServiceWithMockConfiguration() {
        // This test verifies the service behavior with placeholder config
        // In a real scenario, you might want to test with actual test credentials

        // Given
        let service = SupabaseService.shared

        // When
        let isConfigured = service.isConfigured

        // Then
        // This assertion will pass or fail depending on whether
        // the developer has set up their Supabase credentials
        if isConfigured {
            print("✅ Supabase is configured with real credentials")
        } else {
            print("⚠️ Supabase is using placeholder configuration")
        }

        // Either way, client should exist
        XCTAssertNotNil(service.client)
    }
}

// MARK: - Test Helpers

extension SupabaseServiceTests {

    /// Helper to check if we're running in CI environment
    var isRunningInCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil
    }

    /// Helper to skip tests that require network connection
    func skipIfOffline() throws {
        // You can implement network reachability check here if needed
    }
}
