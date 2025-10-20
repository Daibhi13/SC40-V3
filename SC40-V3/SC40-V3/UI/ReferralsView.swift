import SwiftUI

struct ReferralsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var referralCode = "SC40-JOHN-2024"
    @State private var totalReferrals = 3
    @State private var earnedRewards = 15
    @State private var showShareSheet = false
    @State private var showCopyAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching Settings
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Referrals Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 20)
                            
                            VStack(spacing: 8) {
                                Text("Referrals")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Invite friends, get rewards")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Stats Section
                        ReferralStatsSection(
                            totalReferrals: totalReferrals,
                            earnedRewards: earnedRewards,
                            showContent: showContent
                        )
                        
                        // Referral Code Section
                        ReferralCodeSection(
                            referralCode: referralCode,
                            showContent: showContent,
                            onCopy: {
                                UIPasteboard.general.string = referralCode
                                showCopyAlert = true
                                HapticManager.shared.success()
                            }
                        )
                        
                        // How It Works Section
                        HowItWorksSection(showContent: showContent)
                        
                        // Share Options Section
                        ShareOptionsSection(
                            referralCode: referralCode,
                            showContent: showContent,
                            onShare: { showShareSheet = true }
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showContent = true
                }
            }
            .alert("Copied!", isPresented: $showCopyAlert) {
                Button("OK") { }
            } message: {
                Text("Referral code copied to clipboard")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [generateShareMessage()])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func generateShareMessage() -> String {
        return """
        🏃‍♂️ Get faster with Sprint Coach 40! 
        
        I've been using this app to improve my 40-yard dash time and it's incredible! Professional analytics, personalized training, and real results.
        
        Use my referral code: \(referralCode)
        
        Download now and start your speed journey!
        """
    }
}

// MARK: - Referral Stats Section

struct ReferralStatsSection: View {
    let totalReferrals: Int
    let earnedRewards: Int
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                Text("Your Stats")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Stats Cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Referrals",
                    value: "\(totalReferrals)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Rewards Earned",
                    value: "$\(earnedRewards)",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(0.3), value: showContent)
    }
}

// MARK: - Referral Code Section

struct ReferralCodeSection: View {
    let referralCode: String
    let showContent: Bool
    let onCopy: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                Text("Your Referral Code")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Referral Code Card
            VStack(spacing: 16) {
                Text(referralCode)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), lineWidth: 2)
                            )
                    )
                
                Button(action: onCopy) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Copy Code")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
    }
}

// MARK: - How It Works Section

struct HowItWorksSection: View {
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                Text("How It Works")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Steps
            VStack(spacing: 16) {
                HowItWorksStep(
                    number: "1",
                    title: "Share Your Code",
                    description: "Send your unique referral code to friends and teammates"
                )
                
                HowItWorksStep(
                    number: "2",
                    title: "They Download & Sign Up",
                    description: "Your friends download Sprint Coach 40 and use your code"
                )
                
                HowItWorksStep(
                    number: "3",
                    title: "You Both Get Rewards",
                    description: "Earn $5 credit for each successful referral, they get a free week!"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(0.7), value: showContent)
    }
}

// MARK: - Share Options Section

struct ShareOptionsSection: View {
    let referralCode: String
    let showContent: Bool
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                Text("Share With Friends")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Share Buttons
            VStack(spacing: 12) {
                Button(action: onShare) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                        
                        Text("Share Referral Link")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                HStack(spacing: 12) {
                    SocialShareButton(
                        icon: "message.fill",
                        title: "Messages",
                        color: .green,
                        action: { shareViaMessages() }
                    )
                    
                    SocialShareButton(
                        icon: "envelope.fill",
                        title: "Email",
                        color: .blue,
                        action: { shareViaEmail() }
                    )
                    
                    SocialShareButton(
                        icon: "link",
                        title: "Copy Link",
                        color: .purple,
                        action: { copyReferralLink() }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(0.9), value: showContent)
    }
    
    private func shareViaMessages() {
        // Implementation for Messages sharing
        HapticManager.shared.light()
    }
    
    private func shareViaEmail() {
        // Implementation for Email sharing
        HapticManager.shared.light()
    }
    
    private func copyReferralLink() {
        let referralLink = "https://sprintcoach40.com/ref/\(referralCode)"
        UIPasteboard.general.string = referralLink
        HapticManager.shared.success()
    }
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

struct SocialShareButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReferralsView()
}
