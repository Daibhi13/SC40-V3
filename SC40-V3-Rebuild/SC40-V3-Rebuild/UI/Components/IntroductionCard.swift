import SwiftUI

struct IntroductionCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header matching the design - "Welcome, David!"
            Text("Welcome, \(profile.name)!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Personal Best section
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR PERSONAL BEST")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1)
                
                // Large personal best time
                Text("\(String(format: "%.2f", profile.personalBests["40yd"] ?? profile.baselineTime))s")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
                
                Text("40-Yard Dash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Profile badges in 3-column layout
            HStack(spacing: 16) {
                // Level badge
                ProfileBadge(
                    title: "Level",
                    value: profile.level,
                    color: .orange
                )
                
                // Frequency badge
                ProfileBadge(
                    title: "Frequency", 
                    value: "\(profile.frequency)x/wk",
                    color: .cyan
                )
                
                // Personal Best badge
                ProfileBadge(
                    title: "Personal Best",
                    value: String(format: "%.2fs", profile.personalBests["40yd"] ?? profile.baselineTime),
                    color: .yellow
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brandBackground, Color.brandAccent.opacity(0.1)],
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
    }
}

struct ProfileBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#if DEBUG
#Preview("1. Training Profile - Intermediate") {
    IntroductionCard(profile: UserProfile(
        name: "David",
        email: "david@example.com",
        gender: "Male",
        age: 25,
        height: 180,
        weight: 75,
        personalBests: ["40yd": 5.2],
        level: "Intermediate",
        baselineTime: 5.2,
        frequency: 3
    ))
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}

#Preview("2. Training Profile - Beginner") {
    IntroductionCard(profile: UserProfile(
        name: "Sarah",
        email: "sarah@example.com",
        gender: "Female",
        age: 22,
        height: 165,
        weight: 60,
        personalBests: ["40yd": 6.1],
        level: "Beginner",
        baselineTime: 6.1,
        frequency: 2
    ))
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}

#Preview("3. Training Profile - Advanced") {
    IntroductionCard(profile: UserProfile(
        name: "Mike",
        email: "mike@example.com",
        gender: "Male",
        age: 28,
        height: 185,
        weight: 80,
        personalBests: ["40yd": 4.8],
        level: "Advanced",
        baselineTime: 4.8,
        frequency: 5
    ))
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}

#Preview("4. Profile Badge Component") {
    ProfileBadge(title: "Personal Best", value: "4.85s", color: .yellow)
        .padding()
        .background(Color.gray.opacity(0.1))
        .preferredColorScheme(.dark)
}
#endif
