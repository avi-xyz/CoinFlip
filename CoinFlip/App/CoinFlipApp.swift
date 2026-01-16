import SwiftUI
import Supabase

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

        // Handle UI Testing reset state
        if ProcessInfo.processInfo.environment["RESET_STATE"] == "1" {
            print("🧪 [UI-Testing] RESET_STATE flag detected - signing out and clearing state")
            Task {
                do {
                    // Sign out from Supabase
                    try await SupabaseService.shared.client.auth.signOut()
                    print("✅ [UI-Testing] Successfully signed out")

                    // Clear UserDefaults
                    if let bundleID = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
                        UserDefaults.standard.synchronize()
                        print("✅ [UI-Testing] UserDefaults cleared")
                    }
                } catch {
                    print("⚠️ [UI-Testing] Error during reset: \(error.localizedDescription)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
