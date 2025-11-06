import SwiftUI

struct AdvancedAnalyticsMonetizationView: View {
    let onUpgrade: () -> Void
    @State private var animateFeatures = false
    
    var body: some View {
        ZStack {
            // Premium gradient background matching app theme
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
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Premium badge
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            
                            Text("PREMIUM FEATURE")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                .tracking(1.5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), lineWidth: 1)
                                )
                        )
                        
                        // Main title
                        VStack(spacing: 8) {
                            Text("Advanced Analytics")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock Professional Performance Insights")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Analytics preview icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3),
                                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateFeatures ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateFeatures)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Features Section
                    VStack(spacing: 24) {
                        Text("What You'll Get")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            AnalyticsFeatureRow(
                                icon: "chart.bar.fill",
                                title: "Performance Trends",
                                description: "Track your 40-yard times over weeks and months with detailed trend analysis"
                            )
                            
                            AnalyticsFeatureRow(
                                icon: "speedometer",
                                title: "Speed Metrics",
                                description: "Advanced speed analysis including acceleration phases and top speed zones"
                            )
                            
                            AnalyticsFeatureRow(
                                icon: "target",
                                title: "Goal Tracking",
                                description: "Set performance targets and track your progress with intelligent recommendations"
                            )
                            
                            AnalyticsFeatureRow(
                                icon: "chart.pie.fill",
                                title: "Training Distribution",
                                description: "Analyze your training load and optimize your workout schedule"
                            )
                            
                            AnalyticsFeatureRow(
                                icon: "trophy.fill",
                                title: "Personal Records",
                                description: "Comprehensive PR tracking with seasonal and all-time bests"
                            )
                            
                            AnalyticsFeatureRow(
                                icon: "brain.head.profile",
                                title: "AI Insights",
                                description: "Machine learning powered recommendations for performance improvement"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Upgrade Button
                    Button(action: onUpgrade) {
                        HStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("UPGRADE TO PRO")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .tracking(1)
                                
                                Text("Unlock Advanced Analytics")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(red: 1.0, green: 0.85, blue: 0.0), location: 0.0),
                                    .init(color: Color(red: 1.0, green: 0.75, blue: 0.0), location: 0.5),
                                    .init(color: Color(red: 1.0, green: 0.65, blue: 0.0), location: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.5), radius: 20, x: 0, y: 8)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Value proposition
                    VStack(spacing: 12) {
                        Text("Join Elite Athletes")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Used by professional trainers and elite athletes to optimize sprint performance and achieve breakthrough times.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Advanced Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateFeatures = true
        }
    }
}

// MARK: - Analytics Feature Row Component
struct AnalyticsFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationView {
        AdvancedAnalyticsMonetizationView(onUpgrade: {})
    }
}
