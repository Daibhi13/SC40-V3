import SwiftUI

struct EmailSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var fullName = ""
    @State private var emailAddress = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var authTimeout: Task<Void, Never>?
    
    var onSuccess: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching WelcomeView
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
                
                VStack(spacing: 32) {
                    // Header with branding
                    VStack(spacing: 16) {
                        // Runner icon
                        Image(systemName: "figure.run")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 20)
                        
                        Text("SPRINT COACH 40")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(3)
                            .shadow(color: .black.opacity(0.3), radius: 6)
                        
                        Text("Create Your Account")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                    
                    // Form fields
                    VStack(spacing: 20) {
                        // Full Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FULL NAME")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(1)
                            
                            TextField("Enter your full name", text: $fullName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    fullName.isEmpty ? Color.white.opacity(0.2) : Color(red: 1.0, green: 0.8, blue: 0.0),
                                                    lineWidth: fullName.isEmpty ? 1 : 2
                                                )
                                        )
                                )
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL ADDRESS")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(1)
                            
                            TextField("Enter your email", text: $emailAddress)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    emailAddress.isEmpty ? Color.white.opacity(0.2) : Color(red: 1.0, green: 0.8, blue: 0.0),
                                                    lineWidth: emailAddress.isEmpty ? 1 : 2
                                                )
                                        )
                                )
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Continue button
                        Button(action: {
                            handleContinue()
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                isFormValid ?
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(
                                color: isFormValid ? Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3) : Color.clear,
                                radius: 15
                            )
                        }
                        .disabled(!isFormValid || authManager.isLoading)
                        
                        // Skip button (if loading is stuck)
                        if authManager.isLoading {
                            Button(action: {
                                HapticManager.shared.light()
                                // Skip authentication and proceed with basic info
                                onSuccess(fullName.isEmpty ? "User" : fullName, emailAddress.isEmpty ? "" : emailAddress)
                                dismiss()
                            }) {
                                Text("Skip for now")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        // Cancel button
                        Button(action: {
                            HapticManager.shared.light()
                            dismiss()
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
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: authManager.errorMessage) { _, newError in
            if let error = newError {
                alertMessage = error
                showingAlert = true
            }
        }
        .onDisappear {
            cleanupAuthResources()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App going to background - cancel any pending auth operations
            cleanupAuthResources()
        }
    }
    
    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        emailAddress.contains("@") &&
        emailAddress.contains(".")
    }
    
    private func handleContinue() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isFormValid else { return }
        
        HapticManager.shared.success()
        
        // Simplified email registration - skip complex authentication for now
        // This prevents email buffering issues and ensures smooth onboarding flow
        print("📧 Email registration: \(trimmedName) (\(trimmedEmail))")
        
        // Save basic user info to UserDefaults for immediate access
        UserDefaults.standard.set(trimmedName, forKey: "user_name")
        UserDefaults.standard.set(trimmedEmail, forKey: "user_email")
        UserDefaults.standard.set("email", forKey: "user_provider")
        
        // Call success handler immediately to prevent UI blocking
        onSuccess(trimmedName, trimmedEmail)
        dismiss()
        
        // Optional: Perform background authentication after UI flow completes
        Task.detached {
            await authManager.authenticate(with: .email, name: trimmedName, email: trimmedEmail)
            print("✅ Background email authentication completed")
        }
    }
    
    // MARK: - Resource Management
    
    private func cleanupAuthResources() {
        print("🧹 Cleaning up authentication resources")
        authTimeout?.cancel()
        authTimeout = nil
    }
}

#Preview {
    EmailSignupView { name, email in
        print("Email signup success: \(name), \(email)")
    }
    .preferredColorScheme(.dark)
}
