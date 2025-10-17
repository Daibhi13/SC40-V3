import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// SC40 Watch Login View - Professional Style
struct WatchLoginView: View {
    @ObservedObject private var authManager = WatchAuthManager.shared
    @State private var showingAppleIDLogin = false
    @State private var loginScale: CGFloat = 0.8
    @State private var loginOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Premium gradient background
            Canvas { context, size in
                let gradient = Gradient(colors: [
                    Color.brandBackground,
                    Color.brandTertiary.opacity(0.8),
                    Color.brandPrimary.opacity(0.1)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Animated particles
                for _ in 0..<8 {
                    let x = size.width * CGFloat.random(in: 0.1...0.9)
                    let y = size.height * CGFloat.random(in: 0.1...0.9)
                    let radius = CGFloat.random(in: 2...6)
                    
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                               with: .color(Color.brandPrimary.opacity(0.3)))
                }
            }
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
                                        Color.brandPrimary,
                                        Color.brandPrimary.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 8)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.brandBackground)
                    }
                    .scaleEffect(loginScale)
                    
                    VStack(spacing: 4) {
                        Text("SPRINT COACH")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(Color.brandPrimary)
                        
                        Text("40")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundColor(Color.brandSecondary)
                    }
                    .opacity(loginOpacity)
                    
                    Text("Elite Sprint Training")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.brandSecondary.opacity(0.8))
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
                                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
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
                        .foregroundColor(Color.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.brandPrimary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.brandPrimary.opacity(0.4), lineWidth: 1)
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
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.brandPrimary))
                            .scaleEffect(0.8)
                        
                        Text("Signing in...")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Color.brandSecondary.opacity(0.8))
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
                    .foregroundColor(Color.brandSecondary.opacity(0.6))
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
