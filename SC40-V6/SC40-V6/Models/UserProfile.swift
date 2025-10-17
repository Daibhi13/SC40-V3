import Foundation
import Combine

// MARK: - User Profile Model

public struct UserProfile: Codable, Equatable {
    var name: String
    var email: String?
    var gender: String
    var age: Int
    var height: Double // in inches
    var weight: Double? // in pounds (optional for some users)
    var personalBests: [String: Double] // e.g., ["40yd": 4.21]
    var level: String // "Beginner", "Intermediate", "Advanced", "Elite"
    var baselineTime: Double // baseline 40-yard dash time
    var frequency: Int // training days per week (1-7)
    var currentWeek: Int = 1
    var currentDay: Int = 1
    var leaderboardOptIn: Bool = true
    var favoriteSessionTemplateIDs: [Int] = []
    var preferredSessionTemplateIDs: [Int] = []
    var dislikedSessionTemplateIDs: [Int] = []
    var allowRepeatingFavorites: Bool = false
    var manualSessionOverrides: [UUID: Int] = [:]
    var sessionIDs: [UUID] = []
    var completedSessionIDs: [UUID] = []
    var photo: Data? // profile photo data
    var experienceLevel: ExperienceLevel {
        switch level {
        case "Beginner": return .beginner
        case "Intermediate": return .intermediate
        case "Advanced": return .advanced
        case "Elite": return .elite
        default: return .beginner
        }
    }

    enum ExperienceLevel {
        case beginner, intermediate, advanced, elite
    }

    // MARK: - Initialization

    init(
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

// UserProfile model is already defined in TrainingSession.swift file
// This file contains additional profile-related models and extensions

extension UserProfile {
    // MARK: - Computed Properties
    var bmi: Double {
        guard let weight = weight else { return 0.0 }
        return (weight / height / height) * 10000
    }
    
    var ageGroup: AgeGroup {
        switch age {
        case 0..<18: return .junior
        case 18..<25: return .youngAdult
        case 25..<35: return .adult
        case 35..<50: return .master
        default: return .senior
        }
    }
    
    var experienceMultiplier: Double {
        switch experienceLevel {
        case .beginner: return 0.8
        case .intermediate: return 1.0
        case .advanced: return 1.2
        case .elite: return 1.4
        }
    }
    
    enum AgeGroup {
        case junior, youngAdult, adult, master, senior
    }
    
    // MARK: - Validation
    func validate() -> [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name is required")
        }
        
        if age < 13 || age > 100 {
            errors.append("Age must be between 13 and 100")
        }
        
        if let weight = weight, weight <= 0 || weight > 300 {
            errors.append("Weight must be between 0 and 300 kg")
        }
        
        if height <= 0 || height > 250 {
            errors.append("Height must be between 0 and 250 cm")
        }
        
        return errors
    }
}

// MARK: - Profile Management
class ProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    
    private let profileKey = "userProfile"
    
    func saveProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: profileKey)
            currentProfile = profile
        } catch {
            self.error = "Failed to save profile: \(error.localizedDescription)"
        }
    }
    
    func loadProfile() {
        isLoading = true
        defer { isLoading = false }
        
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            return
        }
        
        do {
            currentProfile = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            self.error = "Failed to load profile: \(error.localizedDescription)"
        }
    }
    
    func deleteProfile() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        currentProfile = nil
    }
}

// MARK: - Adaptive Session Extension

extension UserProfile {
    mutating func addAdaptiveSession(_ session: AdaptiveSprintSession) {
        let type = session.level.capitalized
        let focus = "Sprint/Drill Focus"
        let notes: String? = nil
        let trainingSession = TrainingSession(
            week: session.week,
            day: session.day,
            type: type,
            focus: focus,
            sprints: session.sprints,
            accessoryWork: session.accessoryWork,
            notes: notes
        )
        self.sessionIDs.append(trainingSession.id)
    }
}
