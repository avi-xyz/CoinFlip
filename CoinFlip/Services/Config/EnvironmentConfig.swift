//
//  EnvironmentConfig.swift
//  CoinFlip
//
//  Created on Sprint 11, Task 11.1
//  Supabase Project Configuration
//

import Foundation

/// Environment configuration for Supabase credentials
///
/// IMPORTANT: These values should be stored securely in production.
/// For now, we're hardcoding them for development.
/// In production, consider using:
/// - Xcode build configurations
/// - Info.plist with environment-specific values
/// - Secure keychain storage
enum EnvironmentConfig {

    // MARK: - Supabase Configuration

    /// Supabase project URL
    /// Get this from: Supabase Dashboard → Settings → API → Project URL
    /// Format: https://xxxxx.supabase.co
    static let supabaseURL: String = {
        return "https://qzlnlwwrnmvqdxnqdief.supabase.co"
    }()

    /// Supabase anonymous API key
    /// Get this from: Supabase Dashboard → Settings → API → anon public key
    /// This is safe to expose in client apps (has Row Level Security)
    static let supabaseAnonKey: String = {
        
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6bG5sd3dybm12cWR4bnFkaWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNzMyMjQsImV4cCI6MjA4MzY0OTIyNH0.gO9NTdVqu3I-uHfftLJjLgiWxwpGWFN5bW3xgL86KtY"
    }()

    // MARK: - Feature Flags

    /// Toggle between Mock and Real data services
    ///
    /// - `true`: Use MockDataService (in-memory, offline, fast)
    /// - `false`: Use SupabaseDataService (real backend, requires auth)
    ///
    /// Switch this to test different data sources during development.
    static let useMockData: Bool = {
        #if DEBUG
        return true  // Use mock data in debug builds by default
        #else
        return false // Use real data in release builds
        #endif
    }()

    // MARK: - Validation

    /// Checks if Supabase credentials are configured
    static var isSupabaseConfigured: Bool {
        return !supabaseURL.contains("YOUR_SUPABASE_URL_HERE") &&
               !supabaseAnonKey.contains("YOUR_SUPABASE_ANON_KEY_HERE") &&
               !supabaseURL.isEmpty &&
               !supabaseAnonKey.isEmpty
    }

    /// Validates that the Supabase URL has the correct format
    static var isSupabaseURLValid: Bool {
        guard let url = URL(string: supabaseURL) else { return false }
        return url.scheme == "https" && url.host?.contains("supabase.co") == true
    }
}
