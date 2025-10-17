//
//  UserProfile.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import CoreLocation

/// Comprehensive athlete profile management
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var dateOfBirth: Date
    var height: Double // cm
    var weight: Double // kg
    var gender: Gender
    var fitnessLevel: FitnessLevel
    var preferredUnits: UnitSystem
    var emergencyContact: EmergencyContact?
    var medicalInfo: MedicalInfo?
    var goals: [TrainingGoal]
    var personalBests: [PersonalBest]
    var trainingPreferences: TrainingPreferences
    var notificationsEnabled: Bool
    var privacySettings: PrivacySettings
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var updatedAt: Date

    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        case preferNotToSay = "Prefer not to say"
    }

    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case elite = "Elite"
    }

    enum UnitSystem: String, Codable, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
    }

    enum SubscriptionTier: String, Codable, CaseIterable {
        case free = "Free"
        case premium = "Premium"
        case pro = "Pro"
    }

    init(id: UUID = UUID(),
         name: String,
         email: String,
         dateOfBirth: Date,
         height: Double,
         weight: Double,
         gender: Gender,
         fitnessLevel: FitnessLevel,
         preferredUnits: UnitSystem = .metric,
         emergencyContact: EmergencyContact? = nil,
         medicalInfo: MedicalInfo? = nil,
         goals: [TrainingGoal] = [],
         personalBests: [PersonalBest] = [],
         trainingPreferences: TrainingPreferences = TrainingPreferences(),
         notificationsEnabled: Bool = true,
         privacySettings: PrivacySettings = PrivacySettings(),
         subscriptionTier: SubscriptionTier = .free) {
        self.id = id
        self.name = name
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.height = height
        self.weight = weight
        self.gender = gender
        self.fitnessLevel = fitnessLevel
        self.preferredUnits = preferredUnits
        self.emergencyContact = emergencyContact
        self.medicalInfo = medicalInfo
        self.goals = goals
        self.personalBests = personalBests
        self.trainingPreferences = trainingPreferences
        self.notificationsEnabled = notificationsEnabled
        self.privacySettings = privacySettings
        self.subscriptionTier = subscriptionTier
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }

    var bmi: Double {
        let heightInMeters = height / 100.0
        return weight / (heightInMeters * heightInMeters)
    }

    mutating func updateProfile(name: String? = nil,
                               email: String? = nil,
                               height: Double? = nil,
                               weight: Double? = nil,
                               fitnessLevel: FitnessLevel? = nil) {
        if let name = name { self.name = name }
        if let email = email { self.email = email }
        if let height = height { self.height = height }
        if let weight = weight { self.weight = weight }
        if let fitnessLevel = fitnessLevel { self.fitnessLevel = fitnessLevel }
        self.updatedAt = Date()
    }
}

/// Emergency contact information
struct EmergencyContact: Codable {
    let name: String
    let phoneNumber: String
    let relationship: String
}

/// Medical information for safety
struct MedicalInfo: Codable {
    let allergies: [String]
    let medications: [String]
    let medicalConditions: [String]
    let bloodType: String?
    let physicianName: String?
    let physicianPhone: String?
}

/// User's training goals
struct TrainingGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetDate: Date
    let targetValue: Double
    let unit: String
    let isCompleted: Bool
    let createdAt: Date

    init(id: UUID = UUID(),
         title: String,
         description: String,
         targetDate: Date,
         targetValue: Double,
         unit: String,
         isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.targetValue = targetValue
        self.unit = unit
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}

/// Personal best records
struct PersonalBest: Identifiable, Codable {
    let id: UUID
    let distance: Double // meters
    let time: TimeInterval // seconds
    let date: Date
    let location: String?
    let conditions: String?
}

/// Training preferences and settings
struct TrainingPreferences: Codable {
    let preferredTrainingTimes: [TrainingTime]
    let workoutDuration: TimeInterval // preferred session length in minutes
    let restDayFrequency: Int // rest days per week
    let focusAreas: [TrainingFocus]
    let equipmentAccess: [Equipment]
    let trainingEnvironment: TrainingEnvironment

    init(preferredTrainingTimes: [TrainingTime] = [],
         workoutDuration: TimeInterval = 45.0,
         restDayFrequency: Int = 2,
         focusAreas: [TrainingFocus] = [],
         equipmentAccess: [Equipment] = [],
         trainingEnvironment: TrainingEnvironment = .both) {
        self.preferredTrainingTimes = preferredTrainingTimes
        self.workoutDuration = workoutDuration
        self.restDayFrequency = restDayFrequency
        self.focusAreas = focusAreas
        self.equipmentAccess = equipmentAccess
        self.trainingEnvironment = trainingEnvironment
    }

    enum TrainingTime: String, Codable, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case flexible = "Flexible"
    }

    enum TrainingFocus: String, Codable, CaseIterable {
        case speed = "Speed"
        case endurance = "Endurance"
        case technique = "Technique"
        case strength = "Strength"
        case recovery = "Recovery"
    }

    enum Equipment: String, Codable, CaseIterable {
        case track = "Track Access"
        case gym = "Gym Access"
        case homeEquipment = "Home Equipment"
        case minimal = "Minimal Equipment"
    }

    enum TrainingEnvironment: String, Codable, CaseIterable {
        case indoor = "Indoor"
        case outdoor = "Outdoor"
        case both = "Both"
    }
}

/// Privacy and data sharing settings
struct PrivacySettings: Codable {
    let sharePerformanceData: Bool
    let sharePersonalBests: Bool
    let allowCoaching: Bool
    let publicProfile: Bool
    let dataCollection: Bool

    init(sharePerformanceData: Bool = false,
         sharePersonalBests: Bool = false,
         allowCoaching: Bool = true,
         publicProfile: Bool = false,
         dataCollection: Bool = true) {
        self.sharePerformanceData = sharePerformanceData
        self.sharePersonalBests = sharePersonalBests
        self.allowCoaching = allowCoaching
        self.publicProfile = publicProfile
        self.dataCollection = dataCollection
    }
}
