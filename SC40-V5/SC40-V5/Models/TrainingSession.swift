//
//  TrainingSession.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import CoreLocation

/// Represents a complete training session with AI-powered program generation
struct TrainingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let duration: TimeInterval
    let type: SessionType
    let sprintSets: [SprintSet]
    let location: LocationData?
    let weather: WeatherConditions?
    let performance: PerformanceMetrics
    let isCompleted: Bool
    let notes: String?

    enum SessionType: String, Codable, CaseIterable {
        case speedWork = "Speed Work"
        case technique = "Technique"
        case endurance = "Endurance"
        case recovery = "Recovery"
        case competition = "Competition Prep"
    }

    init(id: UUID = UUID(),
         name: String,
         date: Date,
         duration: TimeInterval,
         type: SessionType,
         sprintSets: [SprintSet] = [],
         location: LocationData? = nil,
         weather: WeatherConditions? = nil,
         performance: PerformanceMetrics = PerformanceMetrics(),
         isCompleted: Bool = false,
         notes: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.duration = duration
        self.type = type
        self.sprintSets = sprintSets
        self.location = location
        self.weather = weather
        self.performance = performance
        self.isCompleted = isCompleted
        self.notes = notes
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

/// Individual sprint set within a training session
struct SprintSet: Identifiable, Codable, Hashable {
    let id: UUID
    let distance: Double // in meters
    let targetTime: TimeInterval // target time in seconds
    let restPeriod: TimeInterval // rest between sprints in seconds
    let repetitions: Int
    let actualTimes: [TimeInterval] // recorded times for each rep
    let averageHeartRate: Double?
    let maxHeartRate: Double?

    init(id: UUID = UUID(),
         distance: Double,
         targetTime: TimeInterval,
         restPeriod: TimeInterval = 60.0,
         repetitions: Int = 1,
         actualTimes: [TimeInterval] = [],
         averageHeartRate: Double? = nil,
         maxHeartRate: Double? = nil) {
        self.id = id
        self.distance = distance
        self.targetTime = targetTime
        self.restPeriod = restPeriod
        self.repetitions = repetitions
        self.actualTimes = actualTimes
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SprintSet, rhs: SprintSet) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Weather conditions during the session
struct WeatherConditions: Codable {
    let temperature: Double // Celsius
    let humidity: Double // percentage
    let windSpeed: Double // m/s
    let windDirection: Double // degrees
    let condition: String // e.g., "sunny", "rainy", "cloudy"
}

/// Performance metrics for the session
struct PerformanceMetrics: Codable {
    let averageSpeed: Double // m/s
    let maxSpeed: Double // m/s
    let totalDistance: Double // meters
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let caloriesBurned: Double?
    let vo2Max: Double?

    init(averageSpeed: Double = 0.0,
         maxSpeed: Double = 0.0,
         totalDistance: Double = 0.0,
         averageHeartRate: Double? = nil,
         maxHeartRate: Double? = nil,
         caloriesBurned: Double? = nil,
         vo2Max: Double? = nil) {
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.totalDistance = totalDistance
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.caloriesBurned = caloriesBurned
        self.vo2Max = vo2Max
    }
}
