import Foundation

// MARK: - Shared Types

/// Represents a sprint set in a training session
public struct SprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String // e.g., "max", "submax", "moderate", "easy", "test"
    
    public init(distanceYards: Int, reps: Int, intensity: String) {
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
}

/// Represents a training session
public struct TrainingSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let week: Int
    public let day: Int
    public let type: String
    public let focus: String
    public let sprints: [SprintSet]
    public let accessoryWork: [String]
    public var isCompleted: Bool
    public var completionDate: Date?
    
    public init(week: Int, day: Int, type: String, focus: String, sprints: [SprintSet], accessoryWork: [String]) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.isCompleted = false
        self.completionDate = nil
    }
}

// MARK: - User Profile

/// Represents a user profile with training data
public struct UserProfile: Codable {
    // Basic Info
    public var name: String
    public var email: String?
    public var gender: String
    public var age: Int
    public var height: Double
    public var weight: Double?
    public var personalBests: [String: Double]
    public var level: String
    public var baselineTime: Double
    public var frequency: Int
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
    public var manualSessionOverrides: [UUID: Int] = [:]
    public var allowRepeatingFavorites: Bool
    
    // Additional Properties
    public var id: UUID
    public var goals: [String]
    public var personalBest40Yard: Double?
    public var joinDate: Date
    
    public init(
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
        self.id = UUID()
    }
}
