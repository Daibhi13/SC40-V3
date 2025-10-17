import SwiftUI
import Combine
#if os(watchOS)
import WatchKit
#endif

// MARK: - WatchAuthManager
class WatchAuthManager: ObservableObject {
    static let shared = WatchAuthManager()
    
    @Published var isLoading = false
    @Published var authError: String?
    @Published var isAuthenticated = false
    
    private init() {}
    
    func quickLoginWithAppleID() {
        isLoading = true
        authError = nil
        
        // Simulate login
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            self.isAuthenticated = true
        }
    }
    
    func continueAsGuest() {
        isLoading = true
        authError = nil
        
        // Simulate guest login
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.isAuthenticated = true
        }
    }
}

/// SC40 Watch Login View - Professional Style
struct WatchLoginView: View {
    @ObservedObject private var authManager = WatchAuthManager.shared
    @State private var showingAppleIDLogin = false
    @State private var loginScale: CGFloat = 0.8
    @State private var loginOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Premium gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.1),
                            Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.8),
                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.1)
                        ]),
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                )
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // SC40 Branding - Professional Style
                VStack(spacing: 12) {
                    // Animated logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.8, blue: 0.0),
                                        Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), radius: 8)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.05, blue: 0.1))
                    }
                    .scaleEffect(loginScale)
                    
                    VStack(spacing: 4) {
                        Text("SPRINT COACH")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("40")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                    }
                    .opacity(loginOpacity)
                    
                    Text("Elite Sprint Training")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.8))
                        .opacity(loginOpacity)
                }
                
                Spacer()
                
                // Login Options - Professional Style
                VStack(spacing: 16) {
                    // Apple ID Login Button
                    Button(action: {
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                        authManager.quickLoginWithAppleID()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Sign in with Apple")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(authManager.isLoading)
                    
                    // Guest Mode Button
                    Button(action: {
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                        authManager.continueAsGuest()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Continue as Guest")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(authManager.isLoading)
                }
                .opacity(loginOpacity)
                .padding(.horizontal, 16)
                
                // Loading indicator
                if authManager.isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.0)))
                            .scaleEffect(0.8)
                        
                        Text("Signing in...")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.8))
                    }
                    .padding(.top, 8)
                }
                
                // Error message
                if let error = authManager.authError {
                    Text(error)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // Footer
                Text("Secure • Private • Fast")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.6))
                    .opacity(loginOpacity)
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            // Animate login screen appearance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                loginScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                loginOpacity = 1.0
            }
            
            // Play welcome haptic
            #if os(watchOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                WKInterfaceDevice.current().play(.notification)
            }
            #endif
        }
    }
}

#Preview("Watch Login") {
    WatchLoginView()
        .preferredColorScheme(.dark)
}
