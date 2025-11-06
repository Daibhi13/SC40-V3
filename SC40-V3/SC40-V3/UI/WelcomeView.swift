// MARK: - View extension to sanitize layout modifiers
import SwiftUI
extension View {
    func sanitizeLayout() -> some View {
        self
            .modifier(SanitizeLayoutModifier())
    }
}

struct SanitizeLayoutModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear(perform: sanitize)
            .onChange(of: Mirror(reflecting: content).children.count) { _, _ in sanitize() }
    }
    private func sanitize() {
        // No-op: placeholder for future logging or debugging
    }
}
// MARK: - Double & CGFloat extension for safe CoreGraphics usage
extension Double {
    var safeForLayout: Double { (self.isNaN || !self.isFinite) ? 0.0 : self }
}
extension CGFloat {
    var safeForLayout: CGFloat { (self.isNaN || !self.isFinite) ? 0.0 : self }
}
// MARK: - Preview showing new welcome design
struct AllViews_Previews_Welcome: PreviewProvider {
    static var previews: some View {
        WelcomeView(onContinue: { _, _ in })
            .preferredColorScheme(.dark)
            .previewDisplayName("New Welcome Design")
    }
}
import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @State private var showEmailSheet = false
    @State private var isNavigating = false
    
    var onContinue: (_ name: String, _ email: String?) -> Void

    // MARK: - Simple Continue Method (No Authentication)
    private func continueToOnboarding(name: String) {
        guard !isNavigating else {
            print("⚠️ Already navigating, ignoring duplicate request")
            return
        }
        
        isNavigating = true
        print("✅ WelcomeView: Continuing to onboarding with name: \(name)")
        
        // Simple direct navigation without authentication
        DispatchQueue.main.async {
            onContinue(name, nil)
            isNavigating = false
        }
    }
    var body: some View {
        ZStack {
            // Premium gradient background matching the design
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),  // Dark blue top
                    Color(red: 0.2, green: 0.1, blue: 0.3),  // Purple middle
                    Color(red: 0.1, green: 0.05, blue: 0.2)  // Dark purple bottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Runner icon
                Image(systemName: "figure.run")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Bright yellow
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 30)
                    .padding(.bottom, 40)
                
                // "SPRINT COACH" text
                Text("SPRINT COACH")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.3), radius: 8)
                    .padding(.bottom, 20)
                
                // Large "40" numbers
                Text("40")
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6)) // Light green
                    .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.4), radius: 30)
                    .padding(.bottom, 30)
                
                // "Elite Sprint Training" subtitle
                Text("Elite Sprint Training")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1)
                    .shadow(color: .black.opacity(0.2), radius: 4)
                    .padding(.bottom, 80)
                
                Spacer()
            }
            
            // Simple "Get Started" button at bottom
            VStack {
                Spacer()
                
                if isNavigating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding(.bottom, 80)
                } else {
                    Button(action: {
                        continueToOnboarding(name: "User")
                    }) {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color.yellow.opacity(0.5), radius: 15, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 80)
                }
            }
        }
        .sanitizeLayout()
    }
}

// MARK: - Canvas Previews

#if DEBUG
#Preview("1. WelcomeView - Exact Match", traits: .fixedLayout(width: 393, height: 852)) {
    WelcomeView(onContinue: { _, _ in })
        .preferredColorScheme(.dark)
}

#Preview("2. Runner Icon & Branding") {
    VStack(spacing: 30) {
        Image(systemName: "figure.run")
            .font(.system(size: 80, weight: .bold))
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 30)
        
        Text("SPRINT COACH")
            .font(.system(size: 22, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .tracking(4)
            .shadow(color: .black.opacity(0.3), radius: 8)
        
        Text("40")
            .font(.system(size: 140, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6))
            .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.4), radius: 30)
        
        Text("Elite Sprint Training")
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .tracking(1)
            .shadow(color: .black.opacity(0.2), radius: 4)
    }
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.1, green: 0.05, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("4. Name Entry Sheet") {
    NameEntryPreview()
}

struct NameEntryPreview: View {
    @State private var firstName = ""
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "f.circle.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                    }

                    Text("Complete Your Facebook Login")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Enter your name to finish setting up your account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("FIRST NAME")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)

                    TextField("Enter your first name", text: $firstName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        // CRASH PROTECTION: Validate input before continuing
                        guard !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            errorMessage = "Please enter your first name"
                            showErrorAlert = true
                            return
                        }
                        
                        // Preview action - just print for demo
                        print("Continue with name: \(firstName)")
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .cornerRadius(28)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 15)
                    }

                    Button(action: {}) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
            .preferredColorScheme(.dark)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}
// CRITICAL PROTECTION: DO NOT ADD #endif HERE
// This comment prevents Xcode auto-correction that adds stray #endif
// Any #endif here will break struct scope and cause compilation errors
#endif
// REQUIRED: This #endif closes the #if DEBUG block above
// CRITICAL: This #endif must remain to close the #if DEBUG block

struct SocialIconButton: View {
    var color: Color
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.9))
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3), value: UUID())
    }
}

// Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8)
    }
}

// Legacy Feature Pill Component (kept for compatibility)
struct FeaturePill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 4)
    }
}

