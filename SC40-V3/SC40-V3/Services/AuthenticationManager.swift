import Foundation
import SwiftUI
import AuthenticationServices
import Combine

#if canImport(UIKit)
import UIKit
#endif

// Import SDKs conditionally
#if canImport(FacebookLogin)
import FacebookLogin
import FacebookCore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - User Model
    struct AuthUser {
        let id: String
        let name: String
        let email: String?
        let profileImageURL: String?
        let provider: AuthProvider
    }
    
    enum AuthProvider {
        case apple
        case facebook
        case google
        case instagram
        case email
        
        var displayName: String {
            switch self {
            case .apple: return "Apple"
            case .facebook: return "Facebook"
            case .google: return "Google"
            case .instagram: return "Instagram"
            case .email: return "Email"
            }
        }
    }
    
    // MARK: - Apple Sign-In
    func signInWithApple() async throws -> AuthUser {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            // Create strong references to prevent deallocation
            let delegate = AppleSignInDelegate { [weak self] result in
                continuation.resume(with: result)
            }
            let presentationProvider = AppleSignInPresentationContextProvider()
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = presentationProvider
            
            // Keep strong references during the async operation
            withExtendedLifetime((delegate, presentationProvider)) {
                authorizationController.performRequests()
            }
        }
    }
    
    // MARK: - Facebook Login
    func signInWithFacebook() async throws -> AuthUser {
        #if canImport(FacebookLogin)
        return try await withCheckedThrowingContinuation { continuation in
            let loginManager = LoginManager()
            
            loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: AuthError.unknown)
                    return
                }
                
                if result.isCancelled {
                    continuation.resume(throwing: AuthError.cancelled)
                    return
                }
                    
                    // Get user profile data
                    let request = GraphRequest(graphPath: "me", parameters: ["fields": "id,name,email,picture.type(large)"])
                    request.start { _, result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        guard let userData = result as? [String: Any],
                              let id = userData["id"] as? String,
                              let name = userData["name"] as? String else {
                            continuation.resume(throwing: AuthError.authenticationFailed)
                            return
                        }
                        
                        let email = userData["email"] as? String
                        let profileImageURL = (userData["picture"] as? [String: Any])?["data"] as? [String: Any]
                        let imageURL = profileImageURL?["url"] as? String
                        
                        let user = AuthUser(
                            id: "fb_\(id)",
                            name: name,
                            email: email,
                            profileImageURL: imageURL,
                            provider: .facebook
                        )
                        
                        continuation.resume(returning: user)
                    }
            }
        }
        #else
        // Facebook SDK not available - throw proper error
        throw AuthError.socialLoginNotConfigured("Facebook SDK is not available. Please install FacebookLogin via Swift Package Manager.")
        #endif
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async throws -> AuthUser {
        #if canImport(GoogleSignIn)
        // Check if Google Sign-In is properly configured
        guard let clientId = GIDSignIn.sharedInstance.configuration?.clientID,
              !clientId.contains("your-client-id") && !clientId.contains("placeholder-client-id") else {
            throw AuthError.socialLoginNotConfigured("Google Sign-In is not properly configured. Please update GoogleService-Info.plist with your actual client ID from Firebase Console.")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = windowScene.windows.first?.rootViewController else {
                continuation.resume(throwing: AuthError.authenticationFailed)
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result,
                      let user = result.user.profile else {
                    continuation.resume(throwing: AuthError.authenticationFailed)
                    return
                }
                
                let authUser = AuthUser(
                    id: "google_\(result.user.userID ?? UUID().uuidString)",
                    name: user.name,
                    email: user.email,
                    profileImageURL: user.imageURL(withDimension: 200)?.absoluteString,
                    provider: .google
                )
                
                continuation.resume(returning: authUser)
            }
        }
        #else
        // Google Sign-In SDK not available - throw proper error
        throw AuthError.socialLoginNotConfigured("Google Sign-In SDK is not available. Please install GoogleSignIn via Swift Package Manager.")
        #endif
    }
    
    // MARK: - Instagram OAuth
    func signInWithInstagram() async throws -> AuthUser {
        do {
            let instagramUser = try await InstagramAuthService.shared.signIn()
            
            return AuthUser(
                id: "ig_\(instagramUser.id)",
                name: instagramUser.name ?? instagramUser.username,
                email: nil, // Instagram Basic Display API doesn't provide email
                profileImageURL: instagramUser.profilePictureURL,
                provider: .instagram
            )
        } catch {
            // Re-throw the original error instead of using mock data
            print("❌ Instagram authentication failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Email Registration
    func signUpWithEmail(name: String, email: String) async throws -> AuthUser {
        // Validate input
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.invalidName
        }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // In real implementation, this would create account with Firebase/backend
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let user = AuthUser(
                    id: "email_\(UUID().uuidString)",
                    name: name,
                    email: email,
                    profileImageURL: nil,
                    provider: .email
                )
                continuation.resume(returning: user)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    // MARK: - Main Authentication Method
    func authenticate(with provider: AuthProvider, name: String? = nil, email: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user: AuthUser
            
            switch provider {
            case .apple:
                user = try await signInWithApple()
            case .facebook:
                user = try await signInWithFacebook()
            case .google:
                user = try await signInWithGoogle()
            case .instagram:
                user = try await signInWithInstagram()
            case .email:
                guard let name = name, let email = email else {
                    throw AuthError.missingCredentials
                }
                user = try await signUpWithEmail(name: name, email: email)
            }
            
            // Store user and update state
            currentUser = user
            isAuthenticated = true
            
            // Save to local storage
            saveUserToStorage(user)
            
            // Save to Firebase backend (if available)
            #if canImport(FirebaseAuth)
            do {
                let firebaseProvider: FirebaseService.AuthProvider = {
                    switch user.provider {
                    case .apple: return .apple
                    case .facebook: return .facebook
                    case .google: return .google
                    case .instagram: return .instagram
                    case .email: return .email
                    }
                }()
                
                let firebaseUser = FirebaseService.AuthUser(
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    profileImageURL: user.profileImageURL,
                    provider: firebaseProvider
                )
                try await FirebaseService.shared.createUser(with: firebaseUser)
                print("✅ User saved to Firebase backend")
            } catch {
                print("⚠️ Failed to save user to Firebase: \(error)")
                // Continue with local authentication even if Firebase fails
            }
            #endif
            
        } catch {
            errorMessage = error.localizedDescription
            print("Authentication error: \(error)")
        }
        
        isLoading = false
    }
    
    private func saveUserToStorage(_ user: AuthUser) {
        // In real implementation, save to secure storage
        UserDefaults.standard.set(user.id, forKey: "user_id")
        UserDefaults.standard.set(user.name, forKey: "user_name")
        UserDefaults.standard.set(user.email, forKey: "user_email")
        UserDefaults.standard.set(user.provider.displayName, forKey: "user_provider")
    }
}

// MARK: - Auth Errors
// AuthError is now defined in ConnectivityError.swift

// MARK: - Apple Sign-In Delegates
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<AuthenticationManager.AuthUser, Error>) -> Void
    
    init(completion: @escaping (Result<AuthenticationManager.AuthUser, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            let displayName = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let user = AuthenticationManager.AuthUser(
                id: userID,
                name: displayName.isEmpty ? "Apple User" : displayName,
                email: email,
                profileImageURL: nil,
                provider: .apple
            )
            
            completion(.success(user))
        } else {
            completion(.failure(AuthError.authenticationFailed))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completion(.failure(AuthError.cancelled))
            default:
                completion(.failure(AuthError.authenticationFailed))
            }
        } else {
            completion(.failure(error))
        }
    }
}

class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // iOS 26.0+ compatible fallback
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return UIWindow(windowScene: windowScene)
            }
            // Final fallback - create minimal window
            // Use windowScene-based initializer for iOS 26.0+
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.frame = CGRect(x: 0, y: 0, width: 320, height: 568) // Safe default size
                return window
            }
            // Final fallback - create minimal window with first available scene
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
            return window
        }
        return window
        #else
        // For macOS or other platforms
        return NSApplication.shared.windows.first ?? NSWindow()
        #endif
    }
}
