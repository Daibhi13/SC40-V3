import Foundation
import SwiftUI

// Shared types for Watch App

public enum SocialLoginResult {
    case success(name: String, email: String?)
    case error(message: String)
}

// Additional types needed by Watch App
public struct UserProfile: Codable, Equatable {
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

    public init(
        name: String,
        email: String? = nil,
        gender: String,
        age: Int,
        height: Double,
        weight: Double?,
        personalBests: [String: Double] = [:],
        level: String,
        baselineTime: Double,
        frequency: Int,
        currentWeek: Int = 1,
        currentDay: Int = 1,
        leaderboardOptIn: Bool = true
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
    }
}

public enum SessionType: Codable {
    case sprint
    case strength
    case recovery
    case assessment
}

public struct AppWatchTrainingSession: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let type: SessionType
    public let week: Int
    public let day: Int
    public let targetDistance: Double
    public let targetTime: Double
    public let restPeriod: Double
    public let sets: Int
    public let reps: Int
    public let intensity: Intensity
    public let notes: String?
    public let isCompleted: Bool
    public let completedDate: Date?
    public let actualTime: Double?
    public let averageSpeed: Double?
    public let locationData: String?

    public enum Intensity: String, Codable {
        case low, moderate, high, max
    }
}

// Training session types for watch workouts
public struct WatchSprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String

    public init(distanceYards: Int, reps: Int, intensity: String) {
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
}

public struct WatchTrainingSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let week: Int
    public let day: Int
    public let type: String
    public let focus: String
    public let sprints: [WatchSprintSet]
    public let accessoryWork: [String]
    public let notes: String?
    public let isCompleted: Bool

    public init(id: UUID = UUID(), week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = isCompleted
    }

    public init(week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = false
    }
}
