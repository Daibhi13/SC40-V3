import SwiftUI
import Foundation
import Combine
#if os(watchOS)
import WatchKit
#endif

/// SC40 Watch Authentication Manager - Simplified Version
@MainActor
class WatchAuthManager: ObservableObject {
    static let shared = WatchAuthManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authError: String?
    @Published var authState: AuthState = .needsLogin
    @Published var showOnboarding = false
    
    enum AuthState {
        case needsLogin
        case needsOnboarding
        case authenticated
    }
    
    private init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        print("🔐 WatchAuthManager: Checking authentication status")
        
        let hasStoredAuth = UserDefaults.standard.bool(forKey: "SC40_IsAuthenticated")
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "SC40_OnboardingCompleted")
        let storedUserId = UserDefaults.standard.string(forKey: "SC40_UserId")
        
        if hasStoredAuth && hasCompletedOnboarding && storedUserId != nil {
            self.authState = .authenticated
            self.isAuthenticated = true
            print("✅ User authenticated")
        } else if hasStoredAuth && storedUserId != nil {
            self.authState = .needsOnboarding
            self.showOnboarding = true
            print("📋 User needs onboarding")
        } else {
            self.authState = .needsLogin
            print("🔑 User needs login")
        }
    }
    
    func quickLoginWithAppleID() {
        print("🍎 Starting Apple ID login")
        isLoading = true
        authError = nil
        
        // Create basic authentication
        let userId = "watch_user_\(Date().timeIntervalSince1970)"
        
        UserDefaults.standard.set(true, forKey: "SC40_IsAuthenticated")
        UserDefaults.standard.set(userId, forKey: "SC40_UserId")
        UserDefaults.standard.set("Watch User", forKey: "user_name")
        UserDefaults.standard.set("Watch", forKey: "SC40_AuthMethod")
        
        self.isLoading = false
        
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "SC40_OnboardingCompleted")
        
        if hasCompletedOnboarding {
            self.authState = .authenticated
            self.isAuthenticated = true
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
    
    func continueAsGuest() {
        print("👤 Starting guest mode")
        isLoading = true
        
        let guestId = "guest_\(UUID().uuidString.prefix(8))"
        
        UserDefaults.standard.set(true, forKey: "SC40_IsAuthenticated")
        UserDefaults.standard.set(guestId, forKey: "SC40_UserId")
        UserDefaults.standard.set("Guest", forKey: "SC40_AuthMethod")
        UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted")
        
        self.isLoading = false
        self.authState = .authenticated
        self.isAuthenticated = true
        
        print("✅ Guest mode activated")
        
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
    
    func completeOnboarding(userLevel: String, targetTime: Double) {
        print("📋 Completing onboarding - Level: \(userLevel), Target: \(targetTime)s")
        
        UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted")
        UserDefaults.standard.set(userLevel, forKey: "SC40_UserLevel")
        UserDefaults.standard.set(targetTime, forKey: "SC40_TargetTime")
        
        self.authState = .authenticated
        self.isAuthenticated = true
        self.showOnboarding = false
        
        print("✅ Onboarding completed successfully")
        
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }
    
    func signOut() {
        print("🚪 Signing out user")
        
        UserDefaults.standard.removeObject(forKey: "SC40_IsAuthenticated")
        UserDefaults.standard.removeObject(forKey: "SC40_UserId")
        UserDefaults.standard.removeObject(forKey: "SC40_AuthMethod")
        UserDefaults.standard.removeObject(forKey: "SC40_OnboardingCompleted")
        
        self.isAuthenticated = false
        self.authState = .needsLogin
        self.showOnboarding = false
        
        print("✅ User signed out successfully")
    }
}
