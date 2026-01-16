//
//  OfflineBanner.swift
//  CoinFlip
//
//  Created on Sprint 17, Task 17.2
//  Offline indicator banner
//

import SwiftUI

/// Banner displayed when app is offline
struct OfflineBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.bodyMedium)
                    .foregroundColor(.white)

                Text("No Internet Connection")
                    .font(.bodyMedium)
                    .foregroundColor(.white)

                Spacer()

                Text("Offline Mode")
                    .font(.labelSmall)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.lossRed)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    VStack {
        OfflineBanner()
            .environmentObject({
                let monitor = NetworkMonitor.shared
                // Simulate offline for preview
                return monitor
            }())

        Spacer()
    }
}
