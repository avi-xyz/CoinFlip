//
//  APIRateLimitLogger.swift
//  CoinFlip
//
//  Logs API rate limit events to Supabase for production monitoring
//

import Foundation
import Supabase

/// Service for logging API rate limit events to Supabase
///
/// This service captures rate limit hits from external APIs (CoinGecko, GeckoTerminal)
/// and logs them to Supabase for monitoring and alerting in production.
///
/// Usage:
/// ```swift
/// await APIRateLimitLogger.shared.logRateLimitEvent(
///     apiName: "GeckoTerminal",
///     endpoint: "ohlcv",
///     callCount: 15,
///     sessionDuration: 120
/// )
/// ```
@MainActor
class APIRateLimitLogger {

    // MARK: - Singleton

    static let shared = APIRateLimitLogger()

    // MARK: - Properties

    /// Enable/disable rate limit logging to Supabase
    /// Set to true when you want to monitor rate limits in production
    static var enableRemoteLogging = true

    private let tableName = "api_rate_limit_events"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Log a rate limit event to Supabase
    ///
    /// - Parameters:
    ///   - apiName: Name of the API (e.g., "CoinGecko", "GeckoTerminal")
    ///   - endpoint: The specific endpoint that was rate limited
    ///   - callCount: Total API calls in the session when rate limit was hit
    ///   - sessionDuration: Duration of the session in seconds
    func logRateLimitEvent(
        apiName: String,
        endpoint: String,
        callCount: Int,
        sessionDuration: Int
    ) async {
        guard Self.enableRemoteLogging else {
            print("📊 [RateLimitLogger] Remote logging disabled, skipping")
            return
        }

        guard SupabaseService.shared.isConfigured else {
            print("⚠️ [RateLimitLogger] Supabase not configured, skipping remote log")
            return
        }

        // Calculate calls per minute
        let callsPerMinute = sessionDuration > 0
            ? Double(callCount) / Double(sessionDuration) * 60
            : 0

        // Build the event payload
        let event = RateLimitEvent(
            apiName: apiName,
            endpoint: endpoint,
            callCount: callCount,
            sessionDurationSeconds: sessionDuration,
            callsPerMinute: callsPerMinute,
            deviceModel: getDeviceModel(),
            appVersion: getAppVersion(),
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await SupabaseService.shared.client
                .from(tableName)
                .insert(event)
                .execute()

            print("✅ [RateLimitLogger] Rate limit event logged to Supabase")
        } catch {
            // Silently fail - we don't want logging failures to affect the app
            print("⚠️ [RateLimitLogger] Failed to log event: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        return "\(version) (\(build))"
    }
}

// MARK: - Rate Limit Event Model

/// Model for rate limit events stored in Supabase
private struct RateLimitEvent: Encodable {
    let apiName: String
    let endpoint: String
    let callCount: Int
    let sessionDurationSeconds: Int
    let callsPerMinute: Double
    let deviceModel: String
    let appVersion: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case apiName = "api_name"
        case endpoint
        case callCount = "call_count"
        case sessionDurationSeconds = "session_duration_seconds"
        case callsPerMinute = "calls_per_minute"
        case deviceModel = "device_model"
        case appVersion = "app_version"
        case timestamp
    }
}
