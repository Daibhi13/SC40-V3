import SwiftUI
import Foundation

// Sample data for preview
extension TrainingSession {
    static let sampleSessions: [TrainingSession] = [
        TrainingSession(
            id: TrainingSession.stableSessionID(week: 1, day: 1),
            week: 1, day: 1,
            type: "Speed Development",
            focus: "Block Starts",
            sprints: [
                SprintSet(distanceYards: 10, reps: 3, intensity: "95%"),
                SprintSet(distanceYards: 20, reps: 2, intensity: "90%")
            ],
            accessoryWork: ["Dynamic Warm-up", "Core Stability"],
            notes: "Focus on explosive starts"
        ),
        TrainingSession(
            id: TrainingSession.stableSessionID(week: 1, day: 2),
            week: 1, day: 2,
            type: "Recovery",
            focus: "Active Recovery",
            sprints: [],
            accessoryWork: ["Light Stretching", "Foam Rolling"],
            notes: "Active recovery day"
        ),
        TrainingSession(
            id: TrainingSession.stableSessionID(week: 1, day: 3),
            week: 1, day: 3,
            type: "Acceleration",
            focus: "First Step Mechanics",
            sprints: [
                SprintSet(distanceYards: 15, reps: 4, intensity: "92%"),
                SprintSet(distanceYards: 25, reps: 3, intensity: "88%")
            ],
            accessoryWork: ["Plyometrics", "Strength Training"],
            notes: "Work on first step mechanics"
        ),
        TrainingSession(
            id: TrainingSession.stableSessionID(week: 2, day: 1),
            week: 2, day: 1,
            type: "Max Velocity",
            focus: "Top Speed",
            sprints: [
                SprintSet(distanceYards: 30, reps: 3, intensity: "95%"),
                SprintSet(distanceYards: 40, reps: 2, intensity: "98%")
            ],
            accessoryWork: ["Sprint Drills", "Cool Down"],
            notes: "Peak speed development"
        ),
        TrainingSession(
            id: TrainingSession.stableSessionID(week: 2, day: 2),
            week: 2, day: 2,
            type: "Rest",
            focus: "Complete Rest",
            sprints: [],
            accessoryWork: [],
            notes: "Complete rest day"
        ),
        TrainingSession(
            id: TrainingSession.stableSessionID(week: 2, day: 3),
            week: 2, day: 3,
            type: "Speed Endurance",
            focus: "Maintaining Speed",
            sprints: [
                SprintSet(distanceYards: 35, reps: 3, intensity: "90%"),
                SprintSet(distanceYards: 40, reps: 2, intensity: "85%")
            ],
            accessoryWork: ["Tempo Runs", "Recovery Jog"],
            notes: "Maintain speed over distance"
        )
    ]
}

// Brand colors are imported from BrandColors.swift

struct HistoryViewPreview: View {
    var body: some View {
        Text("HistoryView Preview Disabled")
            .foregroundColor(.gray)
    }
}

#Preview("History View - Light Mode") {
    HistoryViewPreview()
        .preferredColorScheme(.light)
}

#Preview("History View - Dark Mode") {
    HistoryViewPreview()
        .preferredColorScheme(.dark)
}

#Preview("History View - Empty State") {
    Text("Preview disabled - needs model imports")
}
