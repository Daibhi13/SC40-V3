import Foundation

// Shared type definitions for Watch app - these mirror the main app types for WatchConnectivity

public struct SprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String // e.g. "max", "submax", "moderate", "easy", "test"

    public init(distanceYards: Int, reps: Int, intensity: String) {
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
}

public struct TrainingSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let week: Int
    public let day: Int
    public let type: String // e.g. "Acceleration", "Max Velocity", etc.
    public let focus: String // e.g. "Block Starts", "Top Speed Mechanics"
    public let sprints: [SprintSet]
    public let accessoryWork: [String]
    public let notes: String?

    // Session results (populated after completion)
    public var isCompleted: Bool = false
    public var completionDate: Date?
    public var sprintTimes: [Double] = [] // Actual sprint times recorded
    public var weatherCondition: String? // e.g. "Clear", "Windy", "Rain"
    public var temperature: Double? // Temperature in Celsius
    public var location: String? // e.g. "Home Track", "Local Field"
    public var personalBest: Double? // Best time from this session
    public var averageTime: Double? // Average time for this session
    public var rpe: Int? // Rate of Perceived Exertion (1-10)
    public var sessionNotes: String? // Post-session notes

    public init(week: Int, day: Int, type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
    }

    // Internal initializer for creating sessions with fixed IDs (for static mock data)
    internal init(id: UUID, week: Int, day: Int, type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = id
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
    }

    public static func stableSessionID(week: Int, day: Int) -> UUID {
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        return UUID(uuidString: baseString) ?? UUID()
    }
}

// Feedback structure for completed sessions
public struct SessionFeedback: Codable, Identifiable {
    public let id: UUID
    public let sessionID: UUID
    public let time: Double?
    public let rpe: Double? // Rate of Perceived Exertion
    public let sleepHours: Double?
    public let soreness: Double?
    public let notes: String?

    public init(sessionID: UUID, time: Double? = nil, rpe: Double? = nil, sleepHours: Double? = nil, soreness: Double? = nil, notes: String? = nil) {
        self.id = UUID()
        self.sessionID = sessionID
        self.time = time
        self.rpe = rpe
        self.sleepHours = sleepHours
        self.soreness = soreness
        self.notes = notes
    }
}
