//
//  AnalyticsService.swift
//  CoinFlip
//
//  Analytics tracking service for app usage and error monitoring
//  Sends events to Supabase for the monitoring dashboard
//

import Foundation
import UIKit
import Supabase

/// Analytics event types
enum AnalyticsEventType: String {
    case appOpen = "app_open"
    case screenView = "screen_view"
    case trade = "trade"
    case error = "error"
    case rateLimit = "rate_limit"
    case session = "session"
    case user = "user"
}

/// Analytics service for tracking app events
@MainActor
class AnalyticsService {
    static let shared = AnalyticsService()

    private let supabase = SupabaseService.shared.client
    private var sessionId: String
    private var deviceId: String
    private var sessionStartTime: Date
    private var screenViewCount: Int = 0
    private var tradeCount: Int = 0
    private var errorCount: Int = 0

    private init() {
        // Generate or retrieve persistent device ID
        if let storedDeviceId = UserDefaults.standard.string(forKey: "analytics_device_id") {
            self.deviceId = storedDeviceId
        } else {
            let newDeviceId = UUID().uuidString
            UserDefaults.standard.set(newDeviceId, forKey: "analytics_device_id")
            self.deviceId = newDeviceId
        }

        // Generate new session ID
        self.sessionId = UUID().uuidString
        self.sessionStartTime = Date()

        print("📊 AnalyticsService initialized - Session: \(sessionId.prefix(8))...")
    }

    // MARK: - Public Tracking Methods

    /// Track app open event
    func trackAppOpen() {
        track(type: .appOpen, name: "app_launched")
        startSession()
    }

    /// Track app going to background
    func trackAppBackground() {
        endSession()
    }

    /// Track app returning to foreground
    func trackAppForeground() {
        // Start a new session if the previous one ended
        sessionId = UUID().uuidString
        sessionStartTime = Date()
        screenViewCount = 0
        tradeCount = 0
        errorCount = 0
        startSession()
    }

    /// Track screen view
    func trackScreenView(_ screenName: String) {
        screenViewCount += 1
        track(type: .screenView, name: screenName)
    }

    /// Track successful buy
    func trackBuySuccess(coinSymbol: String, amount: Double, price: Double) {
        tradeCount += 1
        track(type: .trade, name: "buy_success", properties: [
            "coin_symbol": coinSymbol,
            "amount": amount,
            "price": price
        ])
    }

    /// Track failed buy
    func trackBuyFailed(coinSymbol: String, amount: Double, error: String) {
        errorCount += 1
        track(type: .trade, name: "buy_failed", properties: [
            "coin_symbol": coinSymbol,
            "amount": amount,
            "error": error
        ])
    }

    /// Track successful sell
    func trackSellSuccess(coinSymbol: String, quantity: Double, price: Double, profitLoss: Double) {
        tradeCount += 1
        track(type: .trade, name: "sell_success", properties: [
            "coin_symbol": coinSymbol,
            "quantity": quantity,
            "price": price,
            "profit_loss": profitLoss
        ])
    }

    /// Track failed sell
    func trackSellFailed(coinSymbol: String, quantity: Double, error: String) {
        errorCount += 1
        track(type: .trade, name: "sell_failed", properties: [
            "coin_symbol": coinSymbol,
            "quantity": quantity,
            "error": error
        ])
    }

    /// Track rate limit event
    func trackRateLimit(apiSource: String, endpoint: String, callsPerMinute: Int) {
        track(type: .rateLimit, name: "rate_limit_hit", properties: [
            "api_source": apiSource,
            "endpoint": endpoint,
            "calls_per_minute": callsPerMinute
        ])
    }

    /// Track error
    func trackError(name: String, message: String, context: [String: Any]? = nil) {
        errorCount += 1
        var props: [String: Any] = [
            "message": message
        ]
        if let context = context {
            props.merge(context) { _, new in new }
        }
        track(type: .error, name: name, properties: props)
    }

    /// Track user signup
    func trackSignup(username: String) {
        track(type: .user, name: "signup", properties: [
            "username": username
        ])
    }

    /// Track portfolio reset
    func trackPortfolioReset() {
        track(type: .user, name: "portfolio_reset")
    }

    // MARK: - Private Methods

    private func track(type: AnalyticsEventType, name: String, properties: [String: Any] = [:]) {
        Task {
            await sendEvent(type: type, name: name, properties: properties)
        }
    }

    private func sendEvent(type: AnalyticsEventType, name: String, properties: [String: Any]) async {
        // Skip if offline
        guard NetworkMonitor.shared.isConnected else {
            print("📊 Analytics: Offline - skipping event \(name)")
            return
        }

        let userId = AuthService.shared.currentUser?.id

        // Build event data
        var eventData: [String: Any] = [
            "event_type": type.rawValue,
            "event_name": name,
            "session_id": sessionId,
            "device_id": deviceId,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "os_version": UIDevice.current.systemVersion,
            "device_model": UIDevice.current.model,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if let userId = userId {
            eventData["user_id"] = userId.uuidString.lowercased()
        }

        if !properties.isEmpty {
            // Convert properties to JSON string for JSONB column
            if let jsonData = try? JSONSerialization.data(withJSONObject: properties),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                eventData["properties"] = jsonString
            }
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: [eventData])

            let session = try? await supabase.auth.session
            let supabaseURL = EnvironmentConfig.supabaseURL
            let url = URL(string: "\(supabaseURL)/rest/v1/analytics_events")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(EnvironmentConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            if let accessToken = session?.accessToken {
                request.setValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode >= 400 {
                print("📊 Analytics: Failed to send \(name) - HTTP \(statusCode)")
            } else {
                print("📊 Analytics: Sent \(type.rawValue)/\(name)")
            }
        } catch {
            print("📊 Analytics: Error sending \(name) - \(error.localizedDescription)")
        }
    }

    private func startSession() {
        Task {
            await sendSessionStart()
        }
    }

    private func sendSessionStart() async {
        guard NetworkMonitor.shared.isConnected else { return }

        let userId = AuthService.shared.currentUser?.id

        var sessionData: [String: Any] = [
            "session_id": sessionId,
            "device_id": deviceId,
            "started_at": ISO8601DateFormatter().string(from: sessionStartTime),
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "os_version": UIDevice.current.systemVersion,
            "device_model": UIDevice.current.model
        ]

        if let userId = userId {
            sessionData["user_id"] = userId.uuidString.lowercased()
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: [sessionData])

            let session = try? await supabase.auth.session
            let supabaseURL = EnvironmentConfig.supabaseURL
            let url = URL(string: "\(supabaseURL)/rest/v1/app_sessions")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(EnvironmentConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            if let accessToken = session?.accessToken {
                request.setValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode < 400 {
                print("📊 Analytics: Session started")
            }
        } catch {
            print("📊 Analytics: Failed to start session - \(error.localizedDescription)")
        }
    }

    private func endSession() {
        Task {
            await sendSessionEnd()
        }
    }

    private func sendSessionEnd() async {
        guard NetworkMonitor.shared.isConnected else { return }

        let duration = Int(Date().timeIntervalSince(sessionStartTime))

        let updateData: [String: Any] = [
            "ended_at": ISO8601DateFormatter().string(from: Date()),
            "duration_seconds": duration,
            "screens_viewed": screenViewCount,
            "trades_made": tradeCount,
            "errors_encountered": errorCount
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)

            let session = try? await supabase.auth.session
            let supabaseURL = EnvironmentConfig.supabaseURL
            let url = URL(string: "\(supabaseURL)/rest/v1/app_sessions?session_id=eq.\(sessionId)")!

            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(EnvironmentConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            if let accessToken = session?.accessToken {
                request.setValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode < 400 {
                print("📊 Analytics: Session ended (duration: \(duration)s, screens: \(screenViewCount), trades: \(tradeCount))")
            }
        } catch {
            print("📊 Analytics: Failed to end session - \(error.localizedDescription)")
        }
    }
}
