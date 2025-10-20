import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// User Profile View - Professional Style
struct UserProfileView: View {
    @ObservedObject private var authManager = WatchAuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false
    @State private var profileScale: CGFloat = 0.8
    @State private var profileOpacity: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.brandPrimary.opacity(0.8),
                                        Color.brandAccent.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 8)
                        
                        Image(systemName: (authManager.userProfile?.authMethod == "Apple ID") ? "person.crop.circle.fill" : "person.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.brandBackground)
                    }
                    .scaleEffect(profileScale)
                    
                    // User Info
                    VStack(spacing: 4) {
                        Text(authManager.userProfile?.displayName ?? "SC40 Athlete")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color.brandPrimary)
                        
                        HStack(spacing: 4) {
                            Text(authManager.userProfile?.levelEmoji ?? "🟢")
                                .font(.system(size: 12))
                            Text(authManager.userProfile?.level ?? "Intermediate")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.brandSecondary)
                        }
                    }
                    .opacity(profileOpacity)
                }
                
                // Stats Section
                VStack(spacing: 16) {
                    // Target Time
                    VStack(spacing: 8) {
                        Text("40-Yard Target")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.brandSecondary.opacity(0.8))
                        
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", authManager.userProfile?.targetTime ?? 5.0))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.brandPrimary)
                            Text("sec")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color.brandSecondary.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.brandTertiary.opacity(0.1))
                    )
                    
                    // Account Info
                    VStack(spacing: 12) {
                        HStack {
                            Text("Account")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.brandSecondary.opacity(0.8))
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: authManager.userProfile?.authMethod == "Apple ID" ? "applelogo" : "person.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.brandAccent)
                                
                                Text(authManager.userProfile?.authMethod ?? "Unknown")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.brandSecondary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.brandAccent)
                                
                                Text("Joined \(formatJoinDate())")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.brandSecondary)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.brandTertiary.opacity(0.1))
                    )
                }
                .opacity(profileOpacity)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Edit Profile Button (placeholder)
                    Button(action: {
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                        // TODO: Implement profile editing
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Edit Profile")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.brandPrimary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Logout Button
                    Button(action: {
                        showLogoutConfirmation = true
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Sign Out")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.red.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .opacity(profileOpacity)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }
        .background(
            Canvas { context, size in
                let gradient = Gradient(colors: [
                    Color.brandBackground,
                    Color.brandTertiary.opacity(0.6)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                authManager.logout()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            // Animate profile appearance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                profileScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                profileOpacity = 1.0
            }
            
            #if os(watchOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.click)
            }
            #endif
        }
    }
    
    private func formatJoinDate() -> String {
        guard let userProfile = authManager.userProfile else {
            return "Today"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: userProfile.joinDate)
    }
}

#Preview("User Profile") {
    NavigationStack {
        UserProfileView()
    }
    .preferredColorScheme(.dark)
}
