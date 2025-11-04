import Foundation
import Combine

// MARK: - Core Training Types

/// Represents a single sprint set in a training session
public struct SprintSet: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String // e.g. "max", "submax", "moderate", "easy", "test"
    
    public init(id: UUID = UUID(), distanceYards: Int, reps: Int, intensity: String) {
        self.id = id
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
    
    // MARK: - Equatable
    public static func == (lhs: SprintSet, rhs: SprintSet) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Represents a complete training session with multiple sprint sets
public struct TrainingSession: Codable, Identifiable, Sendable, Equatable {
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
    
    // MARK: - Equatable
    public static func == (lhs: TrainingSession, rhs: TrainingSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func stableSessionID(week: Int, day: Int) -> UUID {
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        return UUID(uuidString: baseString) ?? UUID()
    }
}

// MARK: - User Profile

/// Represents a user profile with training data
public struct UserProfile: Codable, Identifiable, Equatable {
    public var id: UUID
    
    // Basic Info
    public var name: String
    public var email: String?
    public var gender: String
    public var age: Int
    public var height: Double // in inches
    public var weight: Double? // in pounds
    public var personalBests: [String: Double]
    public var level: String // e.g. "Beginner", "Intermediate", "Advanced"
    public var baselineTime: Double // 40-yard dash time in seconds
    public var frequency: Int // Training days per week
    public var currentWeek: Int
    public var currentDay: Int
    public var leaderboardOptIn: Bool
    public var photo: Data?
    public var availableEquipment: [String]
    
    // Location
    public var county: String
    public var state: String
    public var country: String
    public var locationPermissionGranted: Bool
    
    // Session Management
    public var sessionIDs: [UUID] = []
    public var completedSessionIDs: [UUID] = []
    public var favoriteSessionTemplateIDs: [Int] = []
    public var preferredSessionTemplateIDs: [Int] = []
    public var dislikedSessionTemplateIDs: [Int] = []
    public var manualSessionOverrides: [UUID: Int] = [:] // sessionID: templateID
    public var allowRepeatingFavorites: Bool
    
    // Additional Properties
    public var goals: [String]
    public var personalBest40Yard: Double?
    public var joinDate: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        gender: String,
        age: Int,
        height: Double,
        weight: Double? = nil,
        personalBests: [String: Double],
        level: String,
        baselineTime: Double,
        frequency: Int,
        currentWeek: Int = 1,
        currentDay: Int = 1,
        leaderboardOptIn: Bool = true,
        photo: Data? = nil,
        availableEquipment: [String] = [],
        county: String = "",
        state: String = "",
        country: String = "",
        locationPermissionGranted: Bool = false,
        favoriteSessionTemplateIDs: [Int] = [],
        preferredSessionTemplateIDs: [Int] = [],
        dislikedSessionTemplateIDs: [Int] = [],
        allowRepeatingFavorites: Bool = true,
        goals: [String] = [],
        personalBest40Yard: Double? = nil,
        joinDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.personalBests = personalBests
        self.level = level
        self.baselineTime = baselineTime
        self.frequency = frequency
        self.currentWeek = currentWeek
        self.currentDay = currentDay
        self.leaderboardOptIn = leaderboardOptIn
        self.photo = photo
        self.availableEquipment = availableEquipment
        self.county = county
        self.state = state
        self.country = country
        self.locationPermissionGranted = locationPermissionGranted
        self.favoriteSessionTemplateIDs = favoriteSessionTemplateIDs
        self.preferredSessionTemplateIDs = preferredSessionTemplateIDs
        self.dislikedSessionTemplateIDs = dislikedSessionTemplateIDs
        self.allowRepeatingFavorites = allowRepeatingFavorites
        self.goals = goals
        self.personalBest40Yard = personalBest40Yard
        self.joinDate = joinDate
    }
    
    // MARK: - Equatable
    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id
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
