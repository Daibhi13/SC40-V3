//
//  WelcomeView.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI
import AuthenticationServices

/// Social login interface and welcome screen
struct WelcomeView: View {
    @State private var selectedAuthProvider: AuthProvider?
    @State private var isAuthenticating = false
    @State private var showMainApp = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // Logo and branding
                VStack(spacing: 30) {
                    Image(systemName: "figure.run")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)

                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Sign in to continue your sprint training journey")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Authentication options
                VStack(spacing: 20) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .disabled(isAuthenticating)

                    // Google Sign In Button
                    Button(action: {
                        selectedAuthProvider = .google
                        authenticateWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(.white)
                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .disabled(isAuthenticating)

                    // Email Sign In Button
                    Button(action: {
                        selectedAuthProvider = .email
                        showEmailSignIn()
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white)
                            Text("Continue with Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
                    .disabled(isAuthenticating)
                }
                .padding(.horizontal, 40)

                // Terms and Privacy
                VStack(spacing: 5) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 5) {
                        Button("Terms of Service") {
                            // Show terms
                        }
                        Text("and")
                            .foregroundColor(.white.opacity(0.7))
                        Button("Privacy Policy") {
                            // Show privacy policy
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView()
        }
        .overlay(
            Group {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                        .background(Color.black.opacity(0.5))
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
    }

    // MARK: - Authentication Methods

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isAuthenticating = true
            // Process Apple Sign In
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Handle successful authentication
                let userId = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                // Create or update user profile
                authenticateUser(provider: .apple, userId: userId, email: email, name: fullName?.givenName)
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    private func authenticateWithGoogle() {
        isAuthenticating = true
        // Implement Google Sign In
        // This would integrate with Google Sign In SDK
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate successful authentication for demo
            self.authenticateUser(provider: .google, userId: "google_user_123", email: "user@gmail.com", name: "Google User")
        }
    }

    private func showEmailSignIn() {
        // Show email sign in sheet or navigate to email sign in view
        print("Show email sign in")
    }

    private func authenticateUser(provider: AuthProvider, userId: String, email: String?, name: String?) {
        // Save authentication data
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(provider.rawValue, forKey: "authProvider")

        // Create user profile if needed
        if let email = email, let name = name {
            let userProfile = UserProfile(
                name: name,
                email: email,
                dateOfBirth: Date(), // Default date - should be collected in onboarding
                height: 175, // Default height - should be collected in onboarding
                weight: 70, // Default weight - should be collected in onboarding
                gender: .preferNotToSay,
                fitnessLevel: .intermediate
            )

            // Save profile (in a real app, this would be saved to Core Data or a backend)
            print("User authenticated: \(name) via \(provider.rawValue)")
        }

        // Navigate to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showMainApp = true
        }
    }
}

// MARK: - Authentication Provider

enum AuthProvider: String {
    case apple = "apple"
    case google = "google"
    case email = "email"
    case facebook = "facebook"
}

// MARK: - Custom Button Styles

struct SocialButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
