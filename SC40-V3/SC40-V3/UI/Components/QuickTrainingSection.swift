import SwiftUI

struct QuickTrainingSection: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showTimeTrialView = false
    @State private var showPaywall = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Quick Training")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Tap to start")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick training cards
            HStack(spacing: 12) {
                // Time Trial card
                QuickTrainingCard(
                    title: "Time Trial",
                    subtitle: "40 Yard Test",
                    icon: "stopwatch",
                    color: .purple,
                    isPro: true
                ) {
                    if isProUser {
                        showTimeTrialView = true
                    } else {
                        showPaywall = true
                    }
                }
                
                // Quick Sprint card
                QuickTrainingCard(
                    title: "Quick Sprint",
                    subtitle: "5 min session",
                    icon: "bolt.fill",
                    color: .orange,
                    isPro: false
                ) {
                    // TODO: Implement quick sprint
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brandBackground, Color.brandAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandSecondary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showTimeTrialView) {
            NavigationView {
                TimeTrialPhoneView()
                    .environmentObject(userProfileVM)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showTimeTrialView = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywall(showPaywall: $showPaywall, onUnlock: {
                showPaywall = false
            })
        }
    }
}

struct QuickTrainingCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isPro: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon with pro badge if needed
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                    
                    if isPro {
                        VStack {
                            HStack {
                                Spacer()
                                LocalProBadge()
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 32)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Local ProBadge for QuickTrainingSection
struct LocalProBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8, weight: .bold))
            Text("PRO")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(red: 1.0, green: 0.8, blue: 0.0))
        .cornerRadius(8)
    }
}

#if DEBUG
#Preview("1. Quick Training Section") {
    QuickTrainingSection(userProfileVM: UserProfileViewModel())
        .padding()
        .background(Color.gray.opacity(0.1))
        .preferredColorScheme(.dark)
}

#Preview("2. Quick Training Cards") {
    HStack(spacing: 12) {
        QuickTrainingCard(
            title: "Time Trial",
            subtitle: "40 Yard Test",
            icon: "stopwatch",
            color: .purple,
            isPro: true
        ) { }
        
        QuickTrainingCard(
            title: "Quick Sprint",
            subtitle: "5 min session",
            icon: "bolt.fill",
            color: .orange,
            isPro: false
        ) { }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}

#Preview("3. Pro Badge Component") {
    LocalProBadge()
        .padding()
        .background(Color.gray.opacity(0.1))
        .preferredColorScheme(.dark)
}

#Preview("4. Quick Training - Light Mode") {
    QuickTrainingSection(userProfileVM: UserProfileViewModel())
        .padding()
        .background(Color.gray.opacity(0.1))
        .preferredColorScheme(.light)
}
#endif
