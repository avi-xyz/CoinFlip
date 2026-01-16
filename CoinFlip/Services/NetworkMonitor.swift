//
//  NetworkMonitor.swift
//  CoinFlip
//
//  Created on Sprint 17, Task 17.2
//  Network connectivity monitoring service
//

import Foundation
import Network
import Combine

/// Monitors network connectivity status
///
/// This service uses NWPathMonitor to detect network changes and notify the app
/// when connectivity is lost or restored. Views can observe isConnected to show
/// offline indicators and gracefully degrade functionality.
@MainActor
class NetworkMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Published Properties

    /// Current network connection status
    @Published var isConnected: Bool = true

    /// Type of network connection (wifi, cellular, wired, none)
    @Published var connectionType: ConnectionType = .unknown

    /// Whether the app has ever been online in this session
    @Published var hasBeenOnline: Bool = false

    // MARK: - Private Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.coinflip.networkmonitor")

    // MARK: - Types

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case none
        case unknown

        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wired: return "Wired"
            case .none: return "No Connection"
            case .unknown: return "Unknown"
            }
        }

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wired: return "cable.connector"
            case .none: return "wifi.slash"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    // MARK: - Public Methods

    /// Start monitoring network status
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                let wasConnected = self.isConnected
                self.isConnected = path.status == .satisfied

                // Track if we've ever been online
                if self.isConnected {
                    self.hasBeenOnline = true
                }

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wired
                } else if !self.isConnected {
                    self.connectionType = .none
                } else {
                    self.connectionType = .unknown
                }

                // Log status changes
                if wasConnected != self.isConnected {
                    if self.isConnected {
                        print("✅ NetworkMonitor: Connected via \(self.connectionType.description)")
                    } else {
                        print("❌ NetworkMonitor: Disconnected")
                    }
                }
            }
        }

        monitor.start(queue: queue)
        print("📡 NetworkMonitor: Started monitoring")
    }

    /// Stop monitoring network status
    func stopMonitoring() {
        monitor.cancel()
        print("📡 NetworkMonitor: Stopped monitoring")
    }

    /// Check if currently connected
    var isOnline: Bool {
        return isConnected
    }

    /// Check if currently disconnected
    var isOffline: Bool {
        return !isConnected
    }
}
