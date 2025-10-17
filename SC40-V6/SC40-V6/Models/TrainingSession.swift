import Foundation
import CoreLocation
import Combine

// Canonical SprintSet and TrainingSession types for SC40-V3
// These types provide algorithm-friendly structure for sprint training

public struct SprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String // e.g. "max", "submax", "moderate", "easy", "test"
}

public struct AdaptiveSprintSession: Codable, Identifiable, Sendable {
    public var id: UUID
    public let week: Int
    public let day: Int
    public let level: String
    public let sprints: [SprintSet]
    public let accessoryWork: [String]

    public init(id: UUID = UUID(), week: Int, day: Int, level: String, sprints: [SprintSet], accessoryWork: [String]) {
        self.id = id
        self.week = week
        self.day = day
        self.level = level
        self.sprints = sprints
        self.accessoryWork = accessoryWork
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

// MARK: - Compatibility Layer
// These types provide backward compatibility with existing app structure

extension TrainingSession {
    // Convert canonical session to app-compatible format
    var asAppSession: AppTrainingSession {
        AppTrainingSession(
            id: self.id,
            name: "\(self.type) - \(self.focus)",
            type: .sprint,
            week: self.week,
            day: self.day,
            targetDistance: Double(self.sprints.first?.distanceYards ?? 40) * 0.9144, // Convert yards to meters
            targetTime: 15.0, // Default target time
            restPeriod: 120.0, // Default rest period
            sets: self.sprints.count,
            reps: self.sprints.first?.reps ?? 1,
            intensity: .high,
            notes: self.notes,
            isCompleted: self.isCompleted,
            completedDate: self.completionDate,
            actualTime: self.personalBest,
            averageSpeed: self.personalBest.map { Double(self.sprints.first?.distanceYards ?? 40) * 0.9144 / $0 },
            locationData: nil
        )
    }
}

// Legacy app-compatible types
struct AppTrainingSession: Identifiable {
    let id: UUID
    let name: String
    let type: SessionType
    let week: Int
    let day: Int
    let targetDistance: Double // in meters
    let targetTime: TimeInterval // in seconds
    let restPeriod: TimeInterval // in seconds
    let sets: Int
    let reps: Int
    let intensity: IntensityLevel
    let notes: String?
    let isCompleted: Bool
    let completedDate: Date?
    let actualTime: TimeInterval?
    let averageSpeed: Double? // m/s
    let locationData: [CLLocation]?

    enum SessionType: String, Codable {
        case sprint, tempo, interval, recovery, assessment
    }

    enum IntensityLevel: String, Codable {
        case low, moderate, high, maximum
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
