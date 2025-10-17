//
//  SprintSetAndTrainingSession.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import CoreLocation

/// Extended training session management with sprint set configurations
struct SprintSetAndTrainingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let createdDate: Date
    let lastModified: Date
    let isActive: Bool
    let sessionType: SessionType
    let difficulty: Difficulty
    let estimatedDuration: TimeInterval
    let sprintSets: [SprintSetConfiguration]
    let warmUpRoutine: WarmUpRoutine?
    let coolDownRoutine: CoolDownRoutine?
    let tags: [String]
    let author: String
    let version: String

    enum SessionType: String, Codable, CaseIterable {
        case speedDevelopment = "Speed Development"
        case acceleration = "Acceleration Training"
        case maximumVelocity = "Maximum Velocity"
        case speedEndurance = "Speed Endurance"
        case specialEndurance = "Special Endurance"
        case technique = "Technique Focus"
        case strength = "Strength & Power"
        case recovery = "Recovery Session"
        case testing = "Performance Testing"
        case competition = "Competition Preparation"
    }

    enum Difficulty: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case elite = "Elite"
    }

    init(id: UUID = UUID(),
         name: String,
         description: String,
         sessionType: SessionType,
         difficulty: Difficulty,
         estimatedDuration: TimeInterval,
         sprintSets: [SprintSetConfiguration],
         warmUpRoutine: WarmUpRoutine? = nil,
         coolDownRoutine: CoolDownRoutine? = nil,
         tags: [String] = [],
         author: String = "SC40 AI",
         version: String = "1.0") {
        self.id = id
        self.name = name
        self.description = description
        self.createdDate = Date()
        self.lastModified = Date()
        self.isActive = true
        self.sessionType = sessionType
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.sprintSets = sprintSets
        self.warmUpRoutine = warmUpRoutine
        self.coolDownRoutine = coolDownRoutine
        self.tags = tags
        self.author = author
        self.version = version
    }
}

/// Configuration for a sprint set within a training session
struct SprintSetConfiguration: Identifiable, Codable {
    let id: UUID
    let name: String
    let distance: Double // meters
    let targetTime: TimeInterval // seconds
    let restBetweenReps: TimeInterval // seconds
    let restBetweenSets: TimeInterval // seconds
    let repetitions: Int
    let sets: Int
    let progressionType: ProgressionType
    let intensity: Intensity
    let focus: SprintFocus
    let instructions: String?

    enum ProgressionType: String, Codable, CaseIterable {
        case constant = "Constant Pace"
        case descending = "Descending (Faster each rep)"
        case ascending = "Ascending (Slower each rep)"
        case pyramid = "Pyramid (Up then Down)"
        case random = "Random Variation"
    }

    enum Intensity: String, Codable, CaseIterable {
        case low = "Low (60-70% effort)"
        case moderate = "Moderate (70-80% effort)"
        case high = "High (80-90% effort)"
        case maximum = "Maximum (90-100% effort)"
        case supramaximal = "Supramaximal (100%+ effort)"
    }

    enum SprintFocus: String, Codable, CaseIterable {
        case acceleration = "Acceleration"
        case maximumVelocity = "Maximum Velocity"
        case speedEndurance = "Speed Endurance"
        case technique = "Technique"
        case power = "Power Development"
        case reaction = "Reaction Time"
    }

    init(id: UUID = UUID(),
         name: String,
         distance: Double,
         targetTime: TimeInterval,
         restBetweenReps: TimeInterval,
         restBetweenSets: TimeInterval,
         repetitions: Int,
         sets: Int,
         progressionType: ProgressionType,
         intensity: Intensity,
         focus: SprintFocus,
         instructions: String? = nil) {
        self.id = id
        self.name = name
        self.distance = distance
        self.targetTime = targetTime
        self.restBetweenReps = restBetweenReps
        self.restBetweenSets = restBetweenSets
        self.repetitions = repetitions
        self.sets = sets
        self.progressionType = progressionType
        self.intensity = intensity
        self.focus = focus
        self.instructions = instructions
    }
}

/// Warm-up routine before training
struct WarmUpRoutine: Codable {
    let duration: TimeInterval // minutes
    let exercises: [WarmUpExercise]
    let instructions: String

    struct WarmUpExercise: Identifiable, Codable {
        let id: UUID
        let name: String
        let duration: TimeInterval // seconds
        let instructions: String
        let reps: Int?
    }
}

/// Cool-down routine after training
struct CoolDownRoutine: Codable {
    let duration: TimeInterval // minutes
    let exercises: [CoolDownExercise]
    let instructions: String

    struct CoolDownExercise: Identifiable, Codable {
        let id: UUID
        let name: String
        let duration: TimeInterval // seconds
        let instructions: String
        let reps: Int?
    }
}

/// Training session execution data
struct SessionExecution: Identifiable, Codable {
    let id: UUID
    let templateId: UUID // Reference to SprintSetAndTrainingSession
    let startTime: Date
    let endTime: Date?
    let completedSets: [CompletedSprintSet]
    let notes: String?
    let rating: Int? // 1-5 stars
    let weather: WeatherConditions?
    let location: LocationData?

    struct CompletedSprintSet: Identifiable, Codable {
        let id: UUID
        let setConfigurationId: UUID
        let actualTimes: [TimeInterval]
        let averageHeartRate: Double?
        let maxHeartRate: Double?
        let perceivedEffort: Int? // RPE 1-10
        let notes: String?
    }

    struct LocationData: Codable {
        let latitude: Double
        let longitude: Double
        let altitude: Double?
        let horizontalAccuracy: Double?
        let verticalAccuracy: Double?

        init(from location: CLLocation) {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.altitude = location.altitude
            self.horizontalAccuracy = location.horizontalAccuracy
            self.verticalAccuracy = location.verticalAccuracy
        }

        var asCLLocation: CLLocation {
            return CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: altitude ?? 0,
                horizontalAccuracy: horizontalAccuracy ?? 0,
                verticalAccuracy: verticalAccuracy ?? 0,
                timestamp: Date()
            )
        }
    }
}

/// AI-powered session recommendations
struct SessionRecommendation: Codable {
    let sessionId: UUID
    let confidence: Double // 0-1
    let reasoning: String
    let expectedOutcomes: [String]
    let difficultyAdjustment: Int // -2 to +2
    let personalizationFactors: [String]
}
