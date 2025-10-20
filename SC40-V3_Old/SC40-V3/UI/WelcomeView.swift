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
        HamburgerSideMenu(showMenu: .constant(true), onSelect: { (_: TrainingView.MenuSelection) in })
            .preferredColorScheme(.dark)
            .previewDisplayName("New Welcome Design")
    }
}
import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @State private var showEmailSheet = false
    @State private var emailFirstName = ""
    @State private var emailAddress = ""
    @State private var showFirstNameSheet = false
    @State private var tempFirstName = ""
    @State private var showNameEntrySheet = false
    @State private var selectedLoginMethod = ""
    @State private var pendingLoginMethod = ""
    @State private var socialLoginResult: SocialLoginResult?
    var onContinue: (_ name: String, _ email: String?) -> Void
    @State private var isLoading = false

    enum SocialLoginResult {
        case success(name: String, email: String?)
        case error(message: String)
    }

    enum SocialLoginMethod {
        case facebook, apple, instagram, google

        var loginMethodName: String {
            switch self {
            case .facebook: return "Facebook"
            case .apple: return "Apple"
            case .instagram: return "Instagram"
            case .google: return "Google"
            }
        }
    }

    func performSocialLogin(method: SocialLoginMethod) {
        isLoading = true
        selectedLoginMethod = method.loginMethodName
        pendingLoginMethod = method.loginMethodName

        // Perform actual social login based on method
        switch method {
        case .facebook:
            performFacebookLogin()
        case .apple:
            performAppleLogin()
        case .instagram:
            performInstagramLogin()
        case .google:
            performGoogleLogin()
        }
    }

    func performFacebookLogin() {
        // Facebook SDK Integration
        // In a real implementation, this would use FacebookLoginManager
        Task { @MainActor in
            do {
                // Simulate Facebook SDK call
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

                // Mock successful login result
                let mockResult = SocialLoginResult.success(name: "John Smith", email: "john@example.com")

                handleSocialLoginResult(mockResult)

            } catch {
                let errorResult = SocialLoginResult.error(message: "Facebook login failed. Please try again.")
                handleSocialLoginResult(errorResult)
            }
        }
    }

    func performAppleLogin() {
        // Apple Sign-In Integration
        // In a real implementation, this would use ASAuthorizationController
        Task { @MainActor in
            do {
                // Simulate Apple Sign-In
                try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

                // Mock successful login result
                let mockResult = SocialLoginResult.success(name: "Jane Doe", email: "jane@icloud.com")

                handleSocialLoginResult(mockResult)

            } catch {
                let errorResult = SocialLoginResult.error(message: "Apple Sign-In failed. Please try again.")
                handleSocialLoginResult(errorResult)
            }
        }
    }

    func performInstagramLogin() {
        // Instagram OAuth Integration
        // In a real implementation, this would use Instagram Basic Display API
        Task { @MainActor in
            do {
                // Simulate Instagram OAuth
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

                // Mock successful login result
                let mockResult = SocialLoginResult.success(name: "Mike Johnson", email: "mike@instagram.com")

                handleSocialLoginResult(mockResult)

            } catch {
                let errorResult = SocialLoginResult.error(message: "Instagram login failed. Please try again.")
                handleSocialLoginResult(errorResult)
            }
        }
    }

    func performGoogleLogin() {
        // Google Sign-In Integration
        // In a real implementation, this would use GIDSignIn
        Task { @MainActor in
            do {
                // Simulate Google Sign-In
                try await Task.sleep(nanoseconds: 1_800_000_000) // 1.8 seconds

                // Mock successful login result
                let mockResult = SocialLoginResult.success(name: "Sarah Wilson", email: "sarah@gmail.com")

                handleSocialLoginResult(mockResult)

            } catch {
                let errorResult = SocialLoginResult.error(message: "Google Sign-In failed. Please try again.")
                handleSocialLoginResult(errorResult)
            }
        }
    }

    @MainActor
    func handleSocialLoginResult(_ result: SocialLoginResult) {
        isLoading = false

        switch result {
        case .success(let name, let email):
            // Successfully logged in with social media
            onContinue(name, email)
            resetSocialLoginState()

        case .error(let message):
            // Show error and allow retry
            showErrorAlert(message: message)
        }
    }

    func showErrorAlert(message: String) {
        // In a real implementation, this would show an alert
        print("Social Login Error: \(message)")
        // For now, just reset state - in production, show alert
        resetSocialLoginState()
    }

    func resetSocialLoginState() {
        selectedLoginMethod = ""
        pendingLoginMethod = ""
        socialLoginResult = nil
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
                
                // Lightning bolt icon
                Image(systemName: "bolt.fill")
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
            VStack {
                Spacer()
                if isLoading {
                    ProgressView().padding(.bottom, 80)
                } else {
                    HStack(spacing: 20) {
                        SocialIconButton(color: Color(red: 0.2, green: 0.6, blue: 1.0), icon: "f.circle.fill") {
                            HapticManager.shared.medium()
                            performSocialLogin(method: .facebook)
                        }
                        SocialIconButton(color: .black, icon: "apple.logo") {
                            HapticManager.shared.medium()
                            performSocialLogin(method: .apple)
                        }
                        SocialIconButton(color: Color(red: 0.8, green: 0.3, blue: 0.8), icon: "camera.circle.fill") {
                            HapticManager.shared.medium()
                            performSocialLogin(method: .instagram)
                        }
                        SocialIconButton(color: Color(red: 1.0, green: 0.3, blue: 0.3), icon: "g.circle.fill") {
                            HapticManager.shared.medium()
                            performSocialLogin(method: .google)
                        }
                        SocialIconButton(color: Color(red: 0.3, green: 0.8, blue: 0.3), icon: "envelope.circle.fill") {
                            HapticManager.shared.medium()
                            showEmailSheet = true
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .sheet(isPresented: $showEmailSheet) {
            VStack(spacing: 24) {
                Text("Sign Up with Email")
                    .font(.title2.bold())
                    .padding(.top, 24)
                TextField("First Name", text: $emailFirstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Email Address", text: $emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                Button(action: {
                    HapticManager.shared.success()
                    print("[DEBUG] Email Continue tapped: name=\\(emailFirstName), email=\\(emailAddress)")
                    onContinue(emailFirstName.isEmpty ? "Email User" : emailFirstName, emailAddress)
                    showEmailSheet = false
                    emailFirstName = ""
                    emailAddress = ""
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((!emailFirstName.isEmpty && emailAddress.contains("@")) ? Color.green : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(emailFirstName.isEmpty || !emailAddress.contains("@"))
                Spacer()
            }
        }
        .sheet(isPresented: $showNameEntrySheet) {
            ZStack {
                // Premium gradient background
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
                    // Header with login method icon and text
                    VStack(spacing: 16) {
                        // Login method icon
                        ZStack {
                            Circle()
                                .fill(getLoginMethodColor(pendingLoginMethod).opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: getLoginMethodIcon(pendingLoginMethod))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(getLoginMethodColor(pendingLoginMethod))
                        }

                        Text("Complete Your \(pendingLoginMethod) Login")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Enter your name to finish setting up your account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    // Name input field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FIRST NAME")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        TextField("", text: $tempFirstName)
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
                            .overlay(
                                HStack {
                                    Spacer()
                                    if !tempFirstName.isEmpty {
                                        Button(action: {
                                            tempFirstName = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.6))
                                                .padding(.trailing, 16)
                                        }
                                    }
                                }
                            )
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            if !tempFirstName.isEmpty {
                                HapticManager.shared.success()
                                showNameEntrySheet = false
                                tempFirstName = ""
                                onContinue(tempFirstName, nil)
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    tempFirstName.isEmpty ?
                                    Color.gray.opacity(0.5) :
                                    Color(red: 1.0, green: 0.8, blue: 0.0)
                                )
                                .cornerRadius(28)
                                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 15)
                        }
                        .disabled(tempFirstName.isEmpty)

                        Button(action: {
                            showNameEntrySheet = false
                            tempFirstName = ""
                            selectedLoginMethod = ""
                            pendingLoginMethod = ""
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 60)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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

#Preview("2. Lightning Bolt & Branding") {
    VStack(spacing: 30) {
        Image(systemName: "bolt.fill")
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

                TextField("", text: .constant("John"))
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
                Button(action: {}) {
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
    }
    .preferredColorScheme(.dark)
}
#endif

extension WelcomeView {
    func getLoginMethodColor(_ method: String) -> Color {
        switch method {
        case "Facebook":
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "Apple":
            return .black
        case "Instagram":
            return Color(red: 0.8, green: 0.3, blue: 0.8)
        case "Google":
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        default:
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        }
    }

    func getLoginMethodIcon(_ method: String) -> String {
        switch method {
        case "Facebook":
            return "f.circle.fill"
        case "Apple":
            return "apple.logo"
        case "Instagram":
            return "camera.circle.fill"
        case "Google":
            return "g.circle.fill"
        default:
            return "person.circle.fill"
        }
    }

    func handleSocialLogin(_ name: String) {
        // This function is now replaced by the direct sheet presentation
        // Keep for backward compatibility
    }
}

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

