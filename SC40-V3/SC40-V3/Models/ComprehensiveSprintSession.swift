import Foundation

// MARK: - Comprehensive Sprint Session
// Extended model for ComprehensiveSprintSession with all required properties
// TODO: Implement full ComprehensiveSprintSession model with complete functionality

struct ComprehensiveSprintSession: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let difficulty: String
    let duration: TimeInterval
    let sessionType: String
    let focus: String
    let distanceYards: Int
    let reps: Int
    let restMinutes: Int
    let level: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        description: String = "",
        difficulty: String = "Intermediate",
        duration: TimeInterval = 0,
        sessionType: String = "Sprint",
        focus: String = "",
        distanceYards: Int = 40,
        reps: Int = 4,
        restMinutes: Int = 3,
        level: String = "Intermediate"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.difficulty = difficulty
        self.duration = duration
        self.sessionType = sessionType
        self.focus = focus
        self.distanceYards = distanceYards
        self.reps = reps
        self.restMinutes = restMinutes
        self.level = level
    }
}
