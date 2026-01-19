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
    @Published var secondsUntilRefresh: Int = 30

    private let geckoTerminalAPI: GeckoTerminalService
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var countdownTimer: Timer?

    init(geckoTerminalAPI: GeckoTerminalService = .shared) {
        self.geckoTerminalAPI = geckoTerminalAPI
    }

    convenience init() {
        self.init(geckoTerminalAPI: GeckoTerminalService.shared)
        Task { @MainActor in
            await loadViralCoins()
            startAutoRefresh()
        }
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
            self.secondsUntilRefresh = 30

            print("✅ ViralCoinsViewModel: Loaded \(coins.count) viral coins")
        } catch {
            print("❌ ViralCoinsViewModel: Failed to load viral coins - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Manually refresh viral coins
    func refresh() async {
        await loadViralCoins()
        resetCountdown()
    }

    /// Start auto-refresh timer (every 30 seconds)
    func startAutoRefresh() {
        stopAutoRefresh() // Clear any existing timer

        // Refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadViralCoins()
            }
        }

        // Countdown timer (every second)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                if self.secondsUntilRefresh > 0 {
                    self.secondsUntilRefresh -= 1
                } else {
                    self.secondsUntilRefresh = 30
                }
            }
        }

        print("⏰ ViralCoinsViewModel: Auto-refresh started (30s interval)")
    }

    /// Stop auto-refresh timer
    nonisolated func stopAutoRefresh() {
        Task { @MainActor in
            refreshTimer?.invalidate()
            refreshTimer = nil
            countdownTimer?.invalidate()
            countdownTimer = nil
            print("⏸️ ViralCoinsViewModel: Auto-refresh stopped")
        }
    }

    /// Reset countdown to 30 seconds
    private func resetCountdown() {
        secondsUntilRefresh = 30
    }

    // MARK: - Cleanup

    deinit {
        stopAutoRefresh()
    }
}
