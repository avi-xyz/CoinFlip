//
//  LoadingView.swift
//  CoinFlip
//
//  Created on Sprint 12
//  Loading screen while checking auth state
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                // App Icon/Logo
                Text("🪙")
                    .font(.system(size: 80))

                // Loading Indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
                    .scaleEffect(1.5)

                Text("Loading...")
                    .font(.system(size: 16))
                    .foregroundColor(.textMuted)
            }
        }
    }
}

#Preview {
    LoadingView()
}
