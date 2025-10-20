import SwiftUI
import Foundation

// Mock data provider for demonstrating HistoryView functionality
// This can be used directly by views since they can access TrainingSession
struct MockTrainingData {
    
    static func createMockCompletedSessions() -> [TrainingSession] {
        let calendar = Calendar.current
        let now = Date()
        
        // Create realistic mock sessions with complete data
        let mockSessionsData: [(week: Int, day: Int, type: String, focus: String, times: [Double], weather: String, temp: Double, location: String, notes: String)] = [
            (1, 1, "Acceleration", "Block Starts", [5.32, 5.28, 5.35, 5.29], "Clear", 22.5, "Home Track", "Great start technique, felt explosive"),
            (1, 3, "Max Velocity", "Flying Starts", [4.89, 4.92, 4.86, 4.91], "Partly Cloudy", 25.0, "University Field", "Hit new personal best on run 3!"),
            (1, 5, "Acceleration", "Drive Phase", [5.45, 5.41, 5.38, 5.42], "Windy", 18.5, "Local Park", "Wind affected times but technique solid"),
            (2, 1, "Acceleration", "3-Point Starts", [5.25, 5.22, 5.27, 5.24], "Clear", 24.0, "Home Track", "Improved reaction time"),
            (2, 3, "Max Velocity", "Top Speed Mechanics", [4.95, 4.91, 4.88, 4.93], "Hot", 28.5, "Athletics Center", "Hot day but maintained form"),
            (2, 5, "Test", "40-Yard Benchmark", [4.84], "Clear", 21.0, "Official Track", "New personal record! Feeling strong"),
            (3, 1, "Acceleration", "Block Starts", [5.18, 5.15, 5.21, 5.17], "Overcast", 19.5, "Home Track", "Consistent improvement in starts"),
            (3, 3, "Max Velocity", "Speed Endurance", [4.96, 4.98, 4.94, 4.97], "Light Rain", 16.0, "Indoor Facility", "Good session despite rain")
        ]
        
        var sessions: [TrainingSession] = []
        
        for (index, data) in mockSessionsData.enumerated() {
            let sessionDate = calendar.date(byAdding: .day, value: -(21 - index * 3), to: now) ?? now
            
            let sprints = [SprintSet(distanceYards: 40, reps: data.times.count, intensity: "max")]
            
            var session = TrainingSession(
                id: TrainingSession.stableSessionID(week: data.week, day: data.day),
                week: data.week,
                day: data.day,
                type: data.type,
                focus: data.focus,
                sprints: sprints,
                accessoryWork: generateAccessoryWork(for: data.focus),
                notes: "Session completed"
            )
            
            // Set completion data
            session.isCompleted = true
            session.completionDate = sessionDate
            session.sprintTimes = data.times
            session.weatherCondition = data.weather
            session.temperature = data.temp
            session.location = data.location
            session.personalBest = data.times.min()
            session.averageTime = data.times.reduce(0, +) / Double(data.times.count)
            session.rpe = Int.random(in: 6...8) // Moderate to hard effort
            session.sessionNotes = data.notes
            
            sessions.append(session)
        }
        
        return sessions
    }
    
    private static func generateAccessoryWork(for focus: String) -> [String] {
        let focusLower = focus.lowercased()
        
        if focusLower.contains("block") || focusLower.contains("start") {
            return ["A-Skip 2x20m", "Wall Drill 3x10", "3-Point Start Practice"]
        } else if focusLower.contains("drive") || focusLower.contains("acceleration") {
            return ["A-Skip 2x20m", "Wall Drill 3x10", "Drive Phase Drills"]
        } else if focusLower.contains("max") || focusLower.contains("velocity") || focusLower.contains("speed") {
            return ["Flying start practice", "B-Skip 2x20m", "High knee runs"]
        } else if focusLower.contains("test") || focusLower.contains("benchmark") {
            return ["Extended warm-up", "Mental preparation", "Cool-down protocol"]
        } else {
            return ["Dynamic warm-up", "Sprint technique drills", "Recovery stretches"]
        }
    }
}

// Preview provider for HistoryView
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockProfile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            gender: "Male",
            age: 25,
            height: 72.0,
            weight: 180.0,
            personalBests: [:],
            level: "Intermediate",
            baselineTime: 5.5,
            frequency: 3,
            currentWeek: 1,
            currentDay: 1
        )
        
        HistoryView()
            .preferredColorScheme(.dark)
    }
}
