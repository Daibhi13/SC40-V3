import Foundation
import SwiftUI

// MARK: - Core Data Models for iPhone App

// MARK: - Rep Data Models
struct RepData: Codable, Identifiable, Hashable {
    let id: UUID
    let rep: Int
    let time: Double
    let isCompleted: Bool
    let repType: RepType
    let distance: Int
    let timestamp: Date
    
    init(rep: Int, time: Double, isCompleted: Bool, repType: RepType, distance: Int, timestamp: Date) {
        self.id = UUID()
        self.rep = rep
        self.time = time
        self.isCompleted = isCompleted
        self.repType = repType
        self.distance = distance
        self.timestamp = timestamp
    }
    
    enum RepType: String, Codable, CaseIterable {
        case sprint = "sprint"
        case drill = "drill"
        case stride = "stride"
        case tempo = "tempo"
        case recovery = "recovery"
        
        var displayName: String {
            switch self {
            case .sprint: return "Sprint"
            case .drill: return "Drill"
            case .stride: return "Stride"
            case .tempo: return "Tempo"
            case .recovery: return "Recovery"
            }
        }
    }
}

// MARK: - Live Rep Models
struct LiveRep: Codable, Identifiable, Hashable {
    let id: UUID
    let repNumber: Int
    let startTime: Date
    let endTime: Date?
    let distance: Double
    let speed: Double?
    let isActive: Bool
    let repType: RepData.RepType
    
    init(repNumber: Int, startTime: Date, distance: Double, repType: RepData.RepType) {
        self.id = UUID()
        self.repNumber = repNumber
        self.startTime = startTime
        self.endTime = nil
        self.distance = distance
        self.speed = nil
        self.isActive = true
        self.repType = repType
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Session Models
struct CompletedSession: Codable, Identifiable, Hashable {
    let id: UUID
    let sessionName: String
    let date: Date
    let duration: TimeInterval
    let completedReps: [RepData]
    let sessionType: String
    let level: String
    let notes: String?
    
    init(sessionName: String, date: Date, duration: TimeInterval, completedReps: [RepData], sessionType: String, level: String, notes: String? = nil) {
        self.id = UUID()
        self.sessionName = sessionName
        self.date = date
        self.duration = duration
        self.completedReps = completedReps
        self.sessionType = sessionType
        self.level = level
        self.notes = notes
    }
}

// MARK: - Workout Models
enum WorkoutStage: String, Codable, CaseIterable {
    case idle = "idle"
    case warmUp = "warmUp"
    case warmup = "warmup"
    case drills = "drills"
    case strides = "strides"
    case sprints = "sprints"
    case recovery = "recovery"
    case cooldown = "cooldown"
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .warmUp: return "Warming Up"
        case .warmup: return "Warm-up"
        case .drills: return "Drills"
        case .strides: return "Strides"
        case .sprints: return "Sprints"
        case .recovery: return "Recovery"
        case .cooldown: return "Cool-down"
        }
    }
}

struct WorkoutStep: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let duration: TimeInterval?
    let distance: Double?
    let reps: Int?
    let stage: WorkoutStage
    let isCompleted: Bool
    
    init(name: String, description: String, stage: WorkoutStage, duration: TimeInterval? = nil, distance: Double? = nil, reps: Int? = nil, isCompleted: Bool = false) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.duration = duration
        self.distance = distance
        self.reps = reps
        self.stage = stage
        self.isCompleted = isCompleted
    }
}

// MARK: - Sprint Result Models
struct SprintResult: Codable, Identifiable, Hashable {
    let id: UUID
    let distance: Double
    let time: Double
    let speed: Double
    let date: Date
    let gpsAccuracy: Double?
    let splitTimes: [Double]?
    
    init(distance: Double, time: Double, date: Date, gpsAccuracy: Double? = nil, splitTimes: [Double]? = nil) {
        self.id = UUID()
        self.distance = distance
        self.time = time
        self.speed = distance / time
        self.date = date
        self.gpsAccuracy = gpsAccuracy
        self.splitTimes = splitTimes
    }
}

// MARK: - Analytics Models
struct SessionAnalytics: Codable, Identifiable, Hashable {
    let id: UUID
    let sessionId: UUID
    let totalReps: Int
    let completedReps: Int
    let averageTime: Double
    let bestTime: Double
    let totalDistance: Double
    let averageSpeed: Double
    let improvementPercentage: Double?
    
    init(sessionId: UUID, totalReps: Int, completedReps: Int, averageTime: Double, bestTime: Double, totalDistance: Double, averageSpeed: Double, improvementPercentage: Double? = nil) {
        self.id = UUID()
        self.sessionId = sessionId
        self.totalReps = totalReps
        self.completedReps = completedReps
        self.averageTime = averageTime
        self.bestTime = bestTime
        self.totalDistance = totalDistance
        self.averageSpeed = averageSpeed
        self.improvementPercentage = improvementPercentage
    }
}

// MARK: - Filter Models
enum HistoryFilter: String, Codable, CaseIterable {
    case all = "all"
    case sprints = "sprints"
    case drills = "drills"
    case benchmarks = "benchmarks"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    
    var displayName: String {
        switch self {
        case .all: return "All Sessions"
        case .sprints: return "Sprint Sessions"
        case .drills: return "Drill Sessions"
        case .benchmarks: return "Benchmark Tests"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
}

// MARK: - Trend Models
enum RepTrend: String, Codable, CaseIterable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    case insufficient = "insufficient"
    
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        case .insufficient: return "Insufficient Data"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        case .insufficient: return .gray
        }
    }
}

// MARK: - Achievement Models
struct SC40Achievement: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: Bool
    let unlockedDate: Date?
    let category: AchievementCategory
    
    init(title: String, description: String, iconName: String, category: AchievementCategory, isUnlocked: Bool = false, unlockedDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case speed = "speed"
        case consistency = "consistency"
        case volume = "volume"
        case improvement = "improvement"
        case milestone = "milestone"
    }
}

// MARK: - Sync Models
struct WatchWorkoutStateSync: Codable {
    let isActive: Bool
    let currentStage: WorkoutStage
    let currentRep: Int
    let totalReps: Int
    let elapsedTime: TimeInterval
    let timestamp: Date
    
    init(isActive: Bool, currentStage: WorkoutStage, currentRep: Int, totalReps: Int, elapsedTime: TimeInterval) {
        self.isActive = isActive
        self.currentStage = currentStage
        self.currentRep = currentRep
        self.totalReps = totalReps
        self.elapsedTime = elapsedTime
        self.timestamp = Date()
    }
}

// MARK: - Error Models
enum ConnectivityError: Error, LocalizedError {
    case networkUnavailable
    case syncFailed
    case watchNotConnected
    case dataCorrupted
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "Network connection unavailable"
        case .syncFailed: return "Synchronization failed"
        case .watchNotConnected: return "Apple Watch not connected"
        case .dataCorrupted: return "Data corruption detected"
        case .timeout: return "Connection timeout"
        }
    }
}
