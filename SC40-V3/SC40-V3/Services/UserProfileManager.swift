import Foundation
import Combine
import OSLog

/// Thread-safe UserProfileManager using actor isolation to prevent race conditions
/// during onboarding completion and profile data synchronization
final class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "UserProfileManager")
    private let userDefaultsKey = "UserProfileData"
    
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isOnboardingComplete = false
    @Published private(set) var isSavingProfile = false
    
    // Synchronization lock to prevent concurrent profile operations
    private var profileSaveLock = false
    
    private init() {
        loadProfile()
        checkOnboardingStatus()
    }
    
    // MARK: - Profile Loading & Initialization
    
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let loaded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            DispatchQueue.main.async {
                self.profile = loaded
            }
            logger.info("Loaded existing user profile for \(loaded.name)")
        } else {
            // Check for onboarding data in UserDefaults
            let savedLevel = UserDefaultsManager.shared.getString(forKey: "userLevel") ?? "Beginner"
            let savedFrequency = UserDefaultsManager.shared.getValue(forKey: "trainingFrequency", defaultValue: 0)
            let savedPB = UserDefaultsManager.shared.getValue(forKey: "personalBest40yd", defaultValue: 0.0)
            
            // Create minimal profile - will be populated during onboarding
            let newProfile = UserProfile(
                name: "New User",
                email: nil,
                gender: "Male",
                age: 25,
                height: 70,
                weight: nil,
                personalBests: savedPB > 0 ? ["40yd": savedPB] : [:],
                level: savedLevel,
                baselineTime: savedPB > 0 ? savedPB : 0.0,
                frequency: savedFrequency > 0 ? savedFrequency : 3,
                currentWeek: 1,
                currentDay: 1,
                leaderboardOptIn: true
            )
            DispatchQueue.main.async {
                self.profile = newProfile
            }
            logger.info("Created new user profile - awaiting onboarding data")
        }
    }
    
    private func checkOnboardingStatus() {
        let completed = UserDefaultsManager.shared.getBool(forKey: "onboardingCompleted")
        DispatchQueue.main.async {
            self.isOnboardingComplete = completed
        }
    }
    
    // MARK: - Thread-Safe Profile Operations
    
    /// Safely save profile data with race condition protection
    func saveProfile(level: String, frequency: Int, personalBest: Double? = nil, additionalData: [String: Any] = [:]) async {
        // Prevent concurrent saves
        guard !profileSaveLock else {
            logger.warning("Profile save already in progress, skipping duplicate save")
            return
        }
        
        profileSaveLock = true
        DispatchQueue.main.async {
            self.isSavingProfile = true
        }
        
        defer {
            profileSaveLock = false
            DispatchQueue.main.async {
                self.isSavingProfile = false
            }
        }
        
        logger.info("🔒 Starting thread-safe profile save: level=\(level), frequency=\(frequency)")
        
        // Update profile data
        let newProfile = UserProfile(
            name: additionalData["name"] as? String ?? profile?.name ?? "User",
            email: additionalData["email"] as? String ?? profile?.email,
            gender: additionalData["gender"] as? String ?? profile?.gender ?? "Male",
            age: additionalData["age"] as? Int ?? profile?.age ?? 25,
            height: additionalData["height"] as? Double ?? profile?.height ?? 70,
            weight: additionalData["weight"] as? Double ?? profile?.weight,
            personalBests: personalBest != nil ? ["40yd": personalBest!] : (profile?.personalBests ?? [:]),
            level: level,
            baselineTime: personalBest ?? profile?.baselineTime ?? 0.0,
            frequency: frequency,
            currentWeek: profile?.currentWeek ?? 1,
            currentDay: profile?.currentDay ?? 1,
            leaderboardOptIn: additionalData["leaderboardOptIn"] as? Bool ?? profile?.leaderboardOptIn ?? true
        )
        
        DispatchQueue.main.async {
            self.profile = newProfile
        }
        
        // Save to UserDefaults with consistent keys
        UserDefaultsManager.shared.setValue(level, forKey: "userLevel")
        UserDefaultsManager.shared.setValue(frequency, forKey: "trainingFrequency")
        if let pb = personalBest {
            UserDefaultsManager.shared.setValue(pb, forKey: "personalBest40yd")
        }
        
        // Save additional data
        for (key, value) in additionalData {
            UserDefaultsManager.shared.setValue(value, forKey: key)
        }
        
        // Save profile object
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize()
            
            logger.info("✅ Profile saved successfully: \(level) level, \(frequency) days/week")
        } catch {
            logger.error("❌ Failed to save profile: \(error.localizedDescription)")
        }
    }
    
    /// Complete onboarding with thread-safe profile save
    func completeOnboarding(
        name: String,
        level: String,
        frequency: Int,
        personalBest: Double,
        gender: String = "Male",
        age: Int = 25,
        height: Double = 70,
        weight: Double? = nil,
        leaderboardOptIn: Bool = true
    ) async {
        logger.info("🚀 Starting onboarding completion: \(level) level, \(frequency) days/week")
        
        let additionalData: [String: Any] = [
            "name": name,
            "gender": gender,
            "age": age,
            "height": height,
            "weight": weight as Any,
            "leaderboardOptIn": leaderboardOptIn,
            "currentWeek": 1,
            "currentDay": 1
        ]
        
        // Save profile data
        await saveProfile(
            level: level,
            frequency: frequency,
            personalBest: personalBest,
            additionalData: additionalData
        )
        
        // Mark onboarding as complete
        UserDefaultsManager.shared.setValue(true, forKey: "onboardingCompleted")
        UserDefaultsManager.shared.setValue(Date(), forKey: "onboardingCompletedAt")
        UserDefaultsManager.shared.synchronize()
        
        isOnboardingComplete = true
        
        logger.info("✅ Onboarding completed successfully")
    }
    
    /// Get current profile safely
    func getProfile() async -> UserProfile? {
        return profile
    }
    
    /// Update profile level safely
    func updateLevel(_ level: String) async {
        guard let currentProfile = profile else { return }
        
        await saveProfile(
            level: level,
            frequency: currentProfile.frequency,
            personalBest: currentProfile.personalBests["40yd"]
        )
    }
    
    /// Update training frequency safely
    func updateFrequency(_ frequency: Int) async {
        guard let currentProfile = profile else { return }
        
        await saveProfile(
            level: currentProfile.level,
            frequency: frequency,
            personalBest: currentProfile.personalBests["40yd"]
        )
    }
    
    /// Update personal best safely
    func updatePersonalBest(_ time: Double) async {
        guard let currentProfile = profile else { return }
        
        await saveProfile(
            level: currentProfile.level,
            frequency: currentProfile.frequency,
            personalBest: time
        )
    }
    
    // MARK: - Validation & Error Handling
    
    /// Validate profile data before saving
    private func validateProfileData(level: String, frequency: Int, personalBest: Double?) -> Bool {
        let validLevels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        
        guard validLevels.contains(level) else {
            logger.error("Invalid level: \(level)")
            return false
        }
        
        guard frequency >= 1 && frequency <= 7 else {
            logger.error("Invalid frequency: \(frequency)")
            return false
        }
        
        if let pb = personalBest {
            guard pb > 0 && pb < 20 else {
                logger.error("Invalid personal best: \(pb)")
                return false
            }
        }
        
        return true
    }
    
    /// Reset profile and onboarding state
    func resetProfile() async {
        logger.info("🧹 Resetting profile and onboarding state")
        
        // Clear UserDefaults
        let keysToRemove = [
            userDefaultsKey,
            "userLevel",
            "trainingFrequency", 
            "personalBest40yd",
            "onboardingCompleted",
            "onboardingCompletedAt",
            "userGender",
            "userAge",
            "currentWeek",
            "currentDay"
        ]
        
        for key in keysToRemove {
            UserDefaultsManager.shared.removeValue(forKey: key)
        }
        UserDefaultsManager.shared.synchronize()
        
        // Reset state
        profile = nil
        isOnboardingComplete = false
        
        // Reload default profile
        loadProfile()
        
        logger.info("✅ Profile reset completed")
    }
}
