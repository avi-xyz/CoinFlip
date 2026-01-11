import SwiftUI

@main
struct CoinFlipApp: App {

    init() {
        // Initialize Supabase service on app launch
        // This ensures the singleton is created and configured early
        _ = SupabaseService.shared

        // Verify configuration in debug builds
        #if DEBUG
        if !SupabaseService.shared.isConfigured {
            print("⚠️ [DEBUG] Supabase not configured. Update EnvironmentConfig.swift with your credentials.")
        } else {
            print("✅ [DEBUG] Supabase configured successfully")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
