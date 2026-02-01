//
//  InfoTooltip.swift
//  CoinFlip
//
//  Created on Sprint 18 - App Store Readiness
//  Reusable tooltip component for displaying help text
//

import SwiftUI

struct InfoTooltip: View {
    let text: String
    @State private var showTooltip = false

    var body: some View {
        Button {
            showTooltip = true
            HapticManager.shared.impact(.light)
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.textSecondary)
                .font(.caption)
        }
        .alert("Info", isPresented: $showTooltip) {
            Button("Got it") { }
        } message: {
            Text(text)
        }
    }
}

#Preview {
    InfoTooltip(text: "This is a helpful explanation about a feature.")
}
