//
//  ViralCoinsViewModel.swift
//  CoinFlip
//
//  ViewModel for viral/trending meme coins from last hour
//  Fetches from GeckoTerminal API and filters by viral criteria
//

import Foundation
import Combine

@MainActor
class ViralCoinsViewModel: ObservableObject {
    @Published var viralCoins: [Coin] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastRefreshTime: Date?

    private let geckoTerminalAPI: GeckoTerminalService
    private let staleDuration: TimeInterval = 120 // 2 minutes

    init(geckoTerminalAPI: GeckoTerminalService = .shared) {
        self.geckoTerminalAPI = geckoTerminalAPI
    }

    // MARK: - Public Methods

    /// Load viral coins from GeckoTerminal
    func loadViralCoins() async {
        isLoading = true
        error = nil

        do {
            print("🔥 ViralCoinsViewModel: Loading viral coins...")
            let coins = try await geckoTerminalAPI.fetchViralCoins(limit: 20)

            self.viralCoins = coins
            self.lastRefreshTime = Date()

            print("✅ ViralCoinsViewModel: Loaded \(coins.count) viral coins")
        } catch {
            print("❌ ViralCoinsViewModel: Failed to load viral coins - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh viral coins if data is stale (older than 2 minutes)
    /// Called on view appear - avoids unnecessary API calls
    func refreshIfStale() async {
        // Skip if already loading
        guard !isLoading else {
            print("⏳ ViralCoinsViewModel: Already loading, skipping refresh")
            return
        }

        // Check if data is stale
        if let lastRefresh = lastRefreshTime {
            let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
            if timeSinceRefresh < staleDuration {
                print("✅ ViralCoinsViewModel: Data is fresh (\(Int(timeSinceRefresh))s old), skipping refresh")
                return
            }
            print("🔄 ViralCoinsViewModel: Data is stale (\(Int(timeSinceRefresh))s old), refreshing...")
        } else {
            print("🔄 ViralCoinsViewModel: No data yet, loading...")
        }

        await loadViralCoins()
    }

    /// Manual refresh (pull-to-refresh) - always refreshes
    func refresh() async {
        await loadViralCoins()
    }

    /// Check if data is stale
    var isStale: Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        return Date().timeIntervalSince(lastRefresh) >= staleDuration
    }

    /// Time since last refresh (for display)
    var timeSinceRefresh: String? {
        guard let lastRefresh = lastRefreshTime else { return nil }
        let interval = Date().timeIntervalSince(lastRefresh)

        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}
