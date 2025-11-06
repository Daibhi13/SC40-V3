#if canImport(UIKit)
import UIKit
#endif
import Foundation
import Combine
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(AppKit) && !canImport(UIKit)
import AppKit
#endif

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum AuthProvider {
        case apple, facebook, instagram, google, email
    }
    
    private init() {}
    
    func authenticate(with provider: AuthProvider) async {
        isLoading = true
        
        // Removed artificial delay for better UX
        // try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let success: Bool
        let user: AuthUser?
        let error: String?
        
        switch provider {
        case .apple:
            success = true
            user = AuthUser(id: UUID(), name: "Apple User", email: "appleuser@example.com")
            error = nil
        case .facebook:
            success = false
            user = nil
            error = "Facebook authentication failed."
        case .instagram:
            success = false
            user = nil
            error = "Instagram authentication failed."
        case .google:
            success = true
            user = AuthUser(id: UUID(), name: "Google User", email: "googleuser@example.com")
            error = nil
        case .email:
            success = true
            user = AuthUser(id: UUID(), name: "Email User", email: "emailuser@example.com")
            error = nil
        }
        
        if success {
            self.currentUser = user
            self.isAuthenticated = true
            self.errorMessage = nil
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
            self.errorMessage = error
        }
        self.isLoading = false
    }
    
    func signInWithApple() async {
        await authenticate(with: .apple)
    }
    
    func signOut() async {
        self.isAuthenticated = false
        self.currentUser = nil
        self.errorMessage = nil
        self.isLoading = false
    }
}

struct AuthUser: Identifiable, Equatable {
    let id: UUID
    let name: String
    let email: String?
}

// Legacy User struct for compatibility
struct User {
    let id: String
    let email: String?
    let displayName: String?
}

class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        // Try to get existing window from any scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        
        // Create new window with available scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return UIWindow(windowScene: windowScene)
        }
        
        // Fallback to any existing window from any scene
        if let anyWindow = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first })
            .first {
            return anyWindow
        }
        
        // Final fallback - create window with first available scene or return empty window
        if let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return UIWindow(windowScene: firstScene)
        }
        
        // Absolute fallback - return any available window or create basic window
        print("⚠️ No window scene available for Apple Sign In - using fallback")
        // Try to get any existing window from the app
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        // Return the first available window
        if let firstWindow = UIApplication.shared.windows.first {
            return firstWindow
        }
        // Last resort - create a basic window (this should not crash)
        return UIWindow(frame: UIScreen.main.bounds)
        #else
        #if canImport(AppKit)
        // For macOS (AppKit)
        return NSApplication.shared.windows.first ?? NSWindow()
        #else
        // Other platforms fallback
        return ASPresentationAnchor()
        #endif
        #endif
    }
}
