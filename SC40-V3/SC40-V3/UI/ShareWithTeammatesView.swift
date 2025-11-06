import SwiftUI
import UIKit

struct ShareWithTeammatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showShareSheet = false
    @State private var showCopyAlert = false
    @State private var shareLink = "https://sprintcoach40.com/freeweek?ref=athlete"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching app design
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
                            // Team Icon
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
                                Text("Share with Teammates")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Give them 1 week free!")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            }
                            
                            Text("Share Sprint Coach 40 with your teammates\nand give them 7 days of free access to all\nfeatures!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                        .padding(.bottom, 40)
                        
                        // Free Access Card
                        VStack(spacing: 20) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("1 Week Free Access")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("From: You")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                        
                                        Text("All Pro Features")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), lineWidth: 2)
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                        // Requirements Section
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text("Requirements")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                RequirementRow(
                                    icon: "person.badge.plus",
                                    text: "Recipient must be new to Sprint Coach 40"
                                )
                                
                                RequirementRow(
                                    icon: "calendar.badge.clock",
                                    text: "Valid for 7 days from activation"
                                )
                                
                                RequirementRow(
                                    icon: "star.fill",
                                    text: "Full access to all features"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Share with Teammate Button
                            Button(action: {
                                HapticManager.shared.medium()
                                showShareSheet = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("Share with Teammate")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            // Copy Link Button
                            Button(action: {
                                UIPasteboard.general.string = shareLink
                                showCopyAlert = true
                                HapticManager.shared.success()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("Copy Link")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
                        // What They'll Get Section
                        VStack(spacing: 20) {
                            Text("What They'll Get")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 16) {
                                ShareFeatureRow(
                                    icon: "bolt.fill",
                                    title: "Full training programs",
                                    color: Color(red: 1.0, green: 0.8, blue: 0.0)
                                )
                                
                                ShareFeatureRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Performance tracking",
                                    color: Color(red: 1.0, green: 0.8, blue: 0.0)
                                )
                                
                                ShareFeatureRow(
                                    icon: "trophy.fill",
                                    title: "Leaderboard access",
                                    color: Color(red: 1.0, green: 0.8, blue: 0.0)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showShareSheet) {
            TeammateShareSheet(items: [generateShareMessage()])
        }
        .alert("Link Copied!", isPresented: $showCopyAlert) {
            Button("OK") { }
        } message: {
            Text("Share link copied to clipboard")
        }
    }
    
    private func generateShareMessage() -> String {
        return """
        🏃‍♂️ Get 1 Week FREE of Sprint Coach 40!
        
        I'm sharing my favorite sprint training app with you. Get 7 days of free access to all Pro features including:
        
        ⚡ Professional training programs
        📊 Advanced performance analytics  
        🏆 Leaderboard competitions
        📱 Apple Watch integration
        
        Download Sprint Coach 40 and use this link for your free week:
        \(shareLink)
        
        Let's get faster together! 🚀
        """
    }
}

// MARK: - Supporting Components

struct RequirementRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct ShareFeatureRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct TeammateShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#if DEBUG
struct ShareWithTeammatesView_Previews: PreviewProvider {
    static var previews: some View {
        ShareWithTeammatesView()
    }
}
#endif
