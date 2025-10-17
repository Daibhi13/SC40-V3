// Watch-specific models to avoid conflicts with main app types
import Foundation

/// Watch-specific SprintSet definition 
struct WatchSprintSet {
    let distanceYards: Int
    let reps: Int
    let intensity: String
}

/// Simplified training session struct for Watch
struct WatchTrainingSession {
    let week: Int
    let day: Int
    let type: String
    let focus: String
    let sprints: [WatchSprintSet]
    let accessoryWork: String
    let notes: String?
}
