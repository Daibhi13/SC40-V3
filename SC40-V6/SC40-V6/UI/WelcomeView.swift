import SwiftUI
import AuthenticationServices

// MARK: - View extension to sanitize layout modifiers
extension View {
    func sanitizeLayout() -> some View {
        self.modifier(SanitizeLayoutModifier())
    }
}

struct SanitizeLayoutModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear(perform: sanitize)
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

// MARK: - Social Login Enums and Results
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

enum SocialLoginResult {
    case success(name: String, email: String?)
    case error(message: String)
}

// MARK: - Social Icon Button Component
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

// MARK: - Feature Card Component
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

// MARK: - Legacy Feature Pill Component (kept for compatibility)
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

// MARK: - Welcome View
struct WelcomeView: View {
    @State private var showEmailSheet = false
    @State private var emailFirstName = ""
    @State private var emailAddress = ""
    @State private var showNameEntrySheet = false
    @State private var tempFirstName = ""
    @State private var selectedLoginMethod = ""
    @State private var pendingLoginMethod = ""
    @State private var socialLoginResult: SocialLoginResult?
    var onContinue: (_ name: String, _ email: String?) -> Void
    @State private var isLoading = false

    func performSocialLogin(method: SocialLoginMethod) {
        isLoading = true
        selectedLoginMethod = method.loginMethodName
        pendingLoginMethod = method.loginMethodName

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
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                let mockResult = SocialLoginResult.success(name: "John Smith", email: "john@example.com")
                handleSocialLoginResult(mockResult)
            } catch {
                let errorResult = SocialLoginResult.error(message: "Facebook login failed. Please try again.")
                await handleSocialLoginResult(errorResult)
            }
        }
    }

    func performAppleLogin() {
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_200_000_000)
                let mockResult = SocialLoginResult.success(name: "Jane Doe", email: "jane@icloud.com")
                handleSocialLoginResult(mockResult)
            } catch {
                let errorResult = SocialLoginResult.error(message: "Apple Sign-In failed. Please try again.")
                await handleSocialLoginResult(errorResult)
            }
        }
    }

    func performInstagramLogin() {
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                let mockResult = SocialLoginResult.success(name: "Mike Johnson", email: "mike@instagram.com")
                handleSocialLoginResult(mockResult)
            } catch {
                let errorResult = SocialLoginResult.error(message: "Instagram login failed. Please try again.")
                await handleSocialLoginResult(errorResult)
            }
        }
    }

    func performGoogleLogin() {
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_800_000_000)
                let mockResult = SocialLoginResult.success(name: "Sarah Wilson", email: "sarah@gmail.com")
                handleSocialLoginResult(mockResult)
            } catch {
                let errorResult = SocialLoginResult.error(message: "Google Sign-In failed. Please try again.")
                await handleSocialLoginResult(errorResult)
            }
        }
    }

    @MainActor
    func handleSocialLoginResult(_ result: SocialLoginResult) {
        isLoading = false

        switch result {
        case .success(let name, let email):
            onContinue(name, email)
            resetSocialLoginState()
        case .error(let message):
            showErrorAlert(message: message)
        }
    }

    func showErrorAlert(message: String) {
        print("Social Login Error: \(message)")
        resetSocialLoginState()
    }

    func resetSocialLoginState() {
        selectedLoginMethod = ""
        pendingLoginMethod = ""
        socialLoginResult = nil
    }

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

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 30)
                    .padding(.bottom, 40)

                Text("SPRINT COACH")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.3), radius: 8)
                    .padding(.bottom, 20)

                Text("40")
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6))
                    .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.4), radius: 30)
                    .padding(.bottom, 30)

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
                            performSocialLogin(method: .facebook)
                        }
                        SocialIconButton(color: .black, icon: "apple.logo") {
                            performSocialLogin(method: .apple)
                        }
                        SocialIconButton(color: Color(red: 0.8, green: 0.3, blue: 0.8), icon: "camera.circle.fill") {
                            performSocialLogin(method: .instagram)
                        }
                        SocialIconButton(color: Color(red: 1.0, green: 0.3, blue: 0.3), icon: "g.circle.fill") {
                            performSocialLogin(method: .google)
                        }
                        SocialIconButton(color: Color(red: 0.3, green: 0.8, blue: 0.3), icon: "envelope.circle.fill") {
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
                    .padding(.horizontal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
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

                    VStack(spacing: 12) {
                        Button(action: {
                            if !tempFirstName.isEmpty {
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
