import Foundation
import SwiftUI
import AuthenticationServices
import Combine

class InstagramAuthService: NSObject, ObservableObject {
    static let shared = InstagramAuthService()
    
    // Instagram App Configuration
    private let clientId = "YOUR_INSTAGRAM_CLIENT_ID" // Replace with your Instagram App ID
    private let clientSecret = "YOUR_INSTAGRAM_CLIENT_SECRET" // Replace with your Instagram App Secret
    private let redirectURI = "https://your-app.com/auth/instagram/callback" // Replace with your redirect URI
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authSession: ASWebAuthenticationSession?
    private var completion: ((Result<InstagramUser, Error>) -> Void)?
    
    struct InstagramUser {
        let id: String
        let username: String
        let name: String?
        let profilePictureURL: String?
    }
    
    enum InstagramAuthError: LocalizedError {
        case invalidConfiguration
        case authorizationFailed
        case tokenExchangeFailed
        case userDataFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidConfiguration:
                return "Instagram app not properly configured"
            case .authorizationFailed:
                return "Instagram authorization failed"
            case .tokenExchangeFailed:
                return "Failed to exchange authorization code"
            case .userDataFailed:
                return "Failed to fetch user data from Instagram"
            }
        }
    }
    
    func signIn() async throws -> InstagramUser {
        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { result in
                continuation.resume(with: result)
            }
            
            DispatchQueue.main.async {
                self.startAuthFlow()
            }
        }
    }
    
    private func startAuthFlow() {
        guard !clientId.contains("YOUR_") else {
            completion?(.failure(InstagramAuthError.invalidConfiguration))
            return
        }
        
        isLoading = true
        
        // Instagram Basic Display API OAuth URL
        let scope = "user_profile,user_media"
        let authURL = "https://api.instagram.com/oauth/authorize" +
                     "?client_id=\(clientId)" +
                     "&redirect_uri=\(redirectURI)" +
                     "&scope=\(scope)" +
                     "&response_type=code"
        
        guard let url = URL(string: authURL) else {
            completion?(.failure(InstagramAuthError.invalidConfiguration))
            return
        }
        
        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: URL(string: redirectURI)?.scheme
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleAuthCallback(callbackURL: callbackURL, error: error)
            }
        }
        
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = true
        authSession?.start()
    }
    
    private func handleAuthCallback(callbackURL: URL?, error: Error?) {
        if let error = error {
            completion?(.failure(error))
            return
        }
        
        guard let callbackURL = callbackURL,
              let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            completion?(.failure(InstagramAuthError.authorizationFailed))
            return
        }
        
        Task {
            do {
                let accessToken = try await exchangeCodeForToken(code: code)
                let user = try await fetchUserData(accessToken: accessToken)
                await MainActor.run {
                    self.completion?(.success(user))
                }
            } catch {
                await MainActor.run {
                    self.completion?(.failure(error))
                }
            }
        }
    }
    
    private func exchangeCodeForToken(code: String) async throws -> String {
        let tokenURL = "https://api.instagram.com/oauth/access_token"
        
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI,
            "code": code
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw InstagramAuthError.tokenExchangeFailed
        }
        
        return accessToken
    }
    
    private func fetchUserData(accessToken: String) async throws -> InstagramUser {
        let userURL = "https://graph.instagram.com/me?fields=id,username,account_type&access_token=\(accessToken)"
        
        guard let url = URL(string: userURL) else {
            throw InstagramAuthError.userDataFailed
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let username = json["username"] as? String else {
            throw InstagramAuthError.userDataFailed
        }
        
        return InstagramUser(
            id: id,
            username: username,
            name: username, // Instagram Basic Display API doesn't provide display name
            profilePictureURL: nil // Would need additional API call for profile picture
        )
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension InstagramAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // iOS 26.0+ compatible fallback
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return UIWindow(windowScene: windowScene)
            }
            // Final fallback - create minimal window
            let window = UIWindow()
            window.frame = CGRect(x: 0, y: 0, width: 320, height: 568) // Safe default size
            return window
        }
        return window
        #else
        return NSApplication.shared.windows.first ?? NSWindow()
        #endif
    }
}
