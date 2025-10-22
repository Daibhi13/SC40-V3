import Foundation
import Combine

// Canonical SprintSet and TrainingSession types for SC40-V3

public struct SprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String // e.g. "max", "submax", "moderate", "easy", "test"
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

// MARK: - SC40 Example Session (Algorithm Friendly)

/// Comprehensive example session showing how to structure a complete workout
/// that includes all phases from warm-up through cool-down within the TrainingSession model.
/// This template demonstrates:
/// - Complete workout flow integration
/// - GPS phase identification (via distance > 0)
/// - Algorithm-friendly structure for scaling and adaptation
/// - Proper rest interval management
/// - Mixed intensity training within a single session
public let sc40SessionExample = TrainingSession(
    week: 1,
    day: 1,
    type: "Sprint",
    focus: "Acceleration & Mechanics",
    sprints: [
        // Warm-up (jog + stretch as pseudo-sprint sets for tracking)
        SprintSet(distanceYards: 440, reps: 1, intensity: "Warm-up Jog"),
        SprintSet(distanceYards: 0, reps: 1, intensity: "Dynamic Stretch"),

        // Sprint Drills
        SprintSet(distanceYards: 20, reps: 3, intensity: "High Knees"),
        SprintSet(distanceYards: 20, reps: 3, intensity: "Butt Kicks"),
        SprintSet(distanceYards: 20, reps: 3, intensity: "A-Skips"),

        // Strides (GPS collaboration check built-in)
        SprintSet(distanceYards: 20, reps: 4, intensity: "Strides"),

        // Main Sprint Block (adjustable algorithmically by week)
        SprintSet(distanceYards: 40, reps: 4, intensity: "All-Out Sprint"),

        // Cool-down
        SprintSet(distanceYards: 400, reps: 1, intensity: "Cool Down Jog")
    ],
    accessoryWork: [
        "Foam Roll Quads/Hamstrings",
        "Core Stability 5 min"
    ],
    notes: "GPS stride check ensures accuracy before main sprints. Sprint reps can scale by week (4→6→8). Rest: 30s drills, 120s strides, 180s sprints."
)
