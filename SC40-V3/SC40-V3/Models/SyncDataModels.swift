import Foundation

// MARK: - Sync Data Models for iPhone and Apple Watch Communication

// MARK: - Workout Sync State
struct WorkoutSyncState: Codable {
    let currentPhase: String
    let phaseTimeRemaining: Int
    let isRunning: Bool
    let isPaused: Bool
    let currentRep: Int
    let totalReps: Int
    let completedReps: [RepDataSync]
    let sessionId: String
    let timestamp: Date
}

// MARK: - Rep Data Sync
struct RepDataSync: Codable {
    let rep: Int
    let time: Double
    let distance: Double
    let isCompleted: Bool
    let repType: String
    let timestamp: Date
}

// MARK: - UI Configuration Sync
struct UIConfigurationSync: Codable {
    let primaryColor: String
    let secondaryColor: String
    let fontScale: Double
    let hapticIntensity: String
    let animationSpeed: Double
    let displayMode: String
    let timestamp: Date
}

// MARK: - Coaching Preferences Sync
struct CoachingPreferencesSync: Codable {
    let isVoiceCoachingEnabled: Bool
    let voiceRate: Double
    let voiceVolume: Double
    let coachingFrequency: String
    let motivationalLevel: String
    let language: String
    let timestamp: Date
}

// MARK: - Session Data Sync
struct SessionDataSync: Codable {
    let week: Int
    let day: Int
    let sessionName: String
    let sessionFocus: String
    let estimatedDuration: Int
    let sprintSets: [SprintSetSync]
    let drillSets: [DrillSetSync]
    let strideSets: [StrideSetSync]
    let timestamp: Date
}

// MARK: - Sprint Set Sync
struct SprintSetSync: Codable {
    let distance: Int
    let restTime: Int
    let targetTime: Double?
    let intensity: String
}

// MARK: - Drill Set Sync
struct DrillSetSync: Codable {
    let name: String
    let duration: Int
    let restTime: Int
    let description: String
}

// MARK: - Stride Set Sync
struct StrideSetSync: Codable {
    let distance: Int
    let restTime: Int
    let intensity: String
}

// MARK: - Live Metrics Sync
struct LiveMetricsSync: Codable {
    let distance: Double
    let elapsedTime: Double
    let currentSpeed: Double
    let heartRate: Double?
    let calories: Double?
    let timestamp: Date
}

// MARK: - Pro Picker Data Sync
struct ProPickerDataSync: Codable {
    let selectedDistance: Int
    let selectedReps: Int
    let selectedRestMinutes: Int
    let distanceOptions: [Int]
    let repsOptions: [Int]
    let restOptions: [Int]
    let timestamp: Date
}

// MARK: - Watch Workout State Sync
struct WatchWorkoutStateSync: Codable {
    let currentPhase: String
    let isRunning: Bool
    let isPaused: Bool
    let currentRep: Int
    let requestedAction: String?
    let timestamp: Date
}

// MARK: - Notification Names for Sync Events
extension Notification.Name {
    static let watchRequestedSync = Notification.Name("watchRequestedSync")
    static let watchWorkoutStateChanged = Notification.Name("watchWorkoutStateChanged")
    static let workoutStateAdapted = Notification.Name("workoutStateAdapted")
    static let uiConfigurationAdapted = Notification.Name("uiConfigurationAdapted")
    static let coachingPreferencesAdapted = Notification.Name("coachingPreferencesAdapted")
    static let sessionDataAdapted = Notification.Name("sessionDataAdapted")
    static let liveMetricsAdapted = Notification.Name("liveMetricsAdapted")
    static let proPickerDataAdapted = Notification.Name("proPickerDataAdapted")
}
