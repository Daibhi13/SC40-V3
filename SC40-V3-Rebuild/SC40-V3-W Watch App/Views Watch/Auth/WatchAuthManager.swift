import SwiftUI
import Foundation
#if os(watchOS)
import WatchKit
#endif

/// SC40 Watch Authentication Manager - Professional Style
@MainActor
class WatchAuthManager: ObservableObject {
    static let shared = WatchAuthManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authError: String?
    @Published var userProfile: WatchUserProfile?
    @Published var showOnboarding = false
    
    // Professional Style - Quick authentication states
    @Published var authState: AuthState = .checking
    
    enum AuthState: Equatable {
        case checking
        case needsLogin
        case needsOnboarding
        case authenticated
        case error(String)
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.checking, .checking),
                 (.needsLogin, .needsLogin),
                 (.needsOnboarding, .needsOnboarding),
                 (.authenticated, .authenticated):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    private init() {
        checkAuthenticationStatus()
    }
    
    /// Check current authentication status - Professional Style
    func checkAuthenticationStatus() {
        print("🔐 WatchAuthManager: Checking authentication status")
        
        // Check for stored credentials
        let hasStoredAuth = UserDefaults.standard.bool(forKey: "SC40_IsAuthenticated")
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "SC40_OnboardingCompleted")
        let storedUserId = UserDefaults.standard.string(forKey: "SC40_UserId")
        
        print("🔍 Auth Check - Stored: \(hasStoredAuth), Onboarding: \(hasCompletedOnboarding), UserId: \(storedUserId ?? "none")")
        
        Task { @MainActor in
            if hasStoredAuth && hasCompletedOnboarding && storedUserId != nil {
                // User is fully authenticated
                self.authState = .authenticated
                self.isAuthenticated = true
                self.loadUserProfile()
                print("✅ User authenticated - proceeding to app")
            } else if hasStoredAuth && storedUserId != nil {
                // User logged in but needs onboarding
                self.authState = .needsOnboarding
                self.showOnboarding = true
                print("📋 User needs onboarding")
            } else {
                // User needs to log in
                self.authState = .needsLogin
                print("🔑 User needs login")
            }
        }
    }
    
    /// Quick login with Apple ID - Professional Style
    func quickLoginWithAppleID() {
        print("🍎 Starting Apple ID login")
        isLoading = true
        authError = nil
        
        // Simulate Apple ID authentication
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            
            // Generate mock user ID
            let userId = "apple_\(UUID().uuidString.prefix(8))"
            
            // Store authentication
            UserDefaults.standard.set(true, forKey: "SC40_IsAuthenticated")
            UserDefaults.standard.set(userId, forKey: "SC40_UserId")
            UserDefaults.standard.set("Apple ID", forKey: "SC40_AuthMethod")
            
            self.isLoading = false
            
            // Check if onboarding is needed
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "SC40_OnboardingCompleted")
            
            if hasCompletedOnboarding {
                self.authState = .authenticated
                self.isAuthenticated = true
                self.loadUserProfile()
                print("✅ Apple ID login successful - authenticated")
            } else {
                self.authState = .needsOnboarding
                self.showOnboarding = true
                print("📋 Apple ID login successful - needs onboarding")
            }
            
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
    }
    
    /// Guest mode - Professional Style quick start
    func continueAsGuest() {
        print("👤 Starting guest mode")
        isLoading = true
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            
            let guestId = "guest_\(UUID().uuidString.prefix(8))"
            
            // Store guest authentication
            UserDefaults.standard.set(true, forKey: "SC40_IsAuthenticated")
            UserDefaults.standard.set(guestId, forKey: "SC40_UserId")
            UserDefaults.standard.set("Guest", forKey: "SC40_AuthMethod")
            UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted") // Skip onboarding for guests
            
            self.isLoading = false
            self.authState = .authenticated
            self.isAuthenticated = true
            self.createGuestProfile()
            
            print("✅ Guest mode activated")
            
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #endif
        }
    }
    
    /// Complete onboarding process
    func completeOnboarding(userLevel: String, targetTime: Double) {
        print("📋 Completing onboarding - Level: \(userLevel), Target: \(targetTime)s")
        
        // Store onboarding completion
        UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted")
        UserDefaults.standard.set(userLevel, forKey: "SC40_UserLevel")
        UserDefaults.standard.set(targetTime, forKey: "SC40_TargetTime")
        
        // Create user profile
        let userId = UserDefaults.standard.string(forKey: "SC40_UserId") ?? "unknown"
        let authMethod = UserDefaults.standard.string(forKey: "SC40_AuthMethod") ?? "Unknown"
        
        self.userProfile = WatchUserProfile(
            id: userId,
            level: userLevel,
            targetTime: targetTime,
            authMethod: authMethod,
            joinDate: Date()
        )
        
        Task { @MainActor in
            self.authState = .authenticated
            self.isAuthenticated = true
            self.showOnboarding = false
            
            print("✅ Onboarding completed - user authenticated")
            
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
    }
    
    /// Load user profile
    private func loadUserProfile() {
        let userId = UserDefaults.standard.string(forKey: "SC40_UserId") ?? "unknown"
        let level = UserDefaults.standard.string(forKey: "SC40_UserLevel") ?? "Intermediate"
        let targetTime = UserDefaults.standard.double(forKey: "SC40_TargetTime")
        let authMethod = UserDefaults.standard.string(forKey: "SC40_AuthMethod") ?? "Unknown"
        
        self.userProfile = WatchUserProfile(
            id: userId,
            level: level,
            targetTime: targetTime > 0 ? targetTime : 5.0,
            authMethod: authMethod,
            joinDate: Date()
        )
        
        print("👤 User profile loaded: \(level) level, \(targetTime)s target")
    }
    
    /// Create guest profile
    private func createGuestProfile() {
        let userId = UserDefaults.standard.string(forKey: "SC40_UserId") ?? "guest"
        
        self.userProfile = WatchUserProfile(
            id: userId,
            level: "Intermediate",
            targetTime: 5.0,
            authMethod: "Guest",
            joinDate: Date()
        )
        
        print("👤 Guest profile created")
    }
    
    /// Logout user
    func logout() {
        print("🚪 Logging out user")
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "SC40_IsAuthenticated")
        UserDefaults.standard.removeObject(forKey: "SC40_UserId")
        UserDefaults.standard.removeObject(forKey: "SC40_AuthMethod")
        UserDefaults.standard.removeObject(forKey: "SC40_OnboardingCompleted")
        UserDefaults.standard.removeObject(forKey: "SC40_UserLevel")
        UserDefaults.standard.removeObject(forKey: "SC40_TargetTime")
        
        Task { @MainActor in
            self.isAuthenticated = false
            self.userProfile = nil
            self.authState = .needsLogin
            self.showOnboarding = false
            
            print("✅ User logged out")
        }
    }
}

/// Watch User Profile Model - Separate from main UserProfile to avoid conflicts
struct WatchUserProfile {
    let id: String
    let level: String
    let targetTime: Double
    let authMethod: String
    let joinDate: Date
    
    var displayName: String {
        switch authMethod {
        case "Apple ID":
            return "Apple User"
        case "Guest":
            return "Guest Runner"
        default:
            return "SC40 Athlete"
        }
    }
    
    var levelEmoji: String {
        switch level.lowercased() {
        case "beginner":
            return "🟠"
        case "intermediate":
            return "🟢"
        case "advanced":
            return "🔵"
        case "elite":
            return "🟣"
        default:
            return "🟢"
        }
    }
}
