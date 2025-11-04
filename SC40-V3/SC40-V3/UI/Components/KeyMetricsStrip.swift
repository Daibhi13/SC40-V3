import SwiftUI
import Foundation

// Import the models from the main app target
@_exported import struct SC40_V3.SprintSet
@_exported import struct SC40_V3.TrainingSession

public struct KeyMetricsStrip: View {
    public let profile: UserProfile
    
    public init(profile: UserProfile) {
        self.profile = profile
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                MetricItem(
                    value: String(format: "%.2f", profile.baselineTime),
                    label: "40yd Dash",
                    systemImage: "timer"
                )
                
                MetricItem(
                    value: "\(profile.sessions.count)",
                    label: "Sessions",
                    systemImage: "flame.fill"
                )
                
                MetricItem(
                    value: "\(profile.consistencyScore)%",
                    label: "Consistency",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                
                MetricItem(
                    value: "\(profile.streakDays)",
                    label: "Day Streak",
                    systemImage: "flame"
                )
            }
            .padding(.horizontal)
        }
    }
}

private struct MetricItem: View {
    let value: String
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

public struct KeyMetricsStrip_Previews: PreviewProvider {
    public static var previews: some View {
        // Create a mock user profile with all required parameters
        // Create a mock user profile for preview
        let profile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            gender: "Male",
            age: 25,
            height: 70,
            weight: 180,
            personalBests: ["40yd": 4.5],
            level: "Intermediate",
            baselineTime: 4.5,
            frequency: 3,
            currentWeek: 1,
            currentDay: 1,
            leaderboardOptIn: true,
            photo: Data(),
            availableEquipment: [],
            county: "",
            state: "",
            country: "",
            locationPermissionGranted: false,
            favoriteSessionTemplateIDs: [],
            preferredSessionTemplateIDs: [],
            dislikedSessionTemplateIDs: [],
            allowRepeatingFavorites: true,
            goals: ["Improve 40-yard dash time"],
            personalBest40Yard: 4.5,
            joinDate: Date()
        )
        
        // Create some mock sessions
        let session1 = TrainingSession(
            week: 1,
            day: 1,
            type: "Speed",
            focus: "Acceleration",
            sprints: [
                SprintSet(distanceYards: 40, reps: 4, intensity: "80%"),
                SprintSet(distanceYards: 20, reps: 4, intensity: "90%")
            ],
            accessoryWork: ["Hurdle Mobility", "Core Work"]
        )
        
        let session2 = TrainingSession(
            week: 1,
            day: 2,
            type: "Endurance",
            focus: "Lactate Tolerance",
            sprints: [
                SprintSet(distanceYards: 100, reps: 6, intensity: "75%")
            ],
            accessoryWork: ["Plyometrics", "Upper Body"]
        )
        
        // Add sessions to profile
        var profileWithSessions = profile
        profileWithSessions.sessions = [session1, session2]
        
        return KeyMetricsStrip(profile: profileWithSessions)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .background(Color(UIColor.systemBackground))
    }
}
