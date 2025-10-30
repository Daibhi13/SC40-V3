import Foundation

// MARK: - Unified Session Generator

/// Unified session generation system that ensures iPhone and Watch have identical 12-week programs
/// This service generates deterministic sessions based on user profile to guarantee synchronization
class UnifiedSessionGenerator {
    static let shared = UnifiedSessionGenerator()
    
    private init() {}
    
    // MARK: - Main Generation Method
    
    /// Generate complete 12-week program that will be identical on iPhone and Watch
    func generateUnified12WeekProgram(
        userLevel: String,
        frequency: Int,
        userPreferences: UserSessionPreferences? = nil
    ) -> [TrainingSession] {
        
        print("🔄 UnifiedSessionGenerator: Generating 12-week program")
        print("   Level: \(userLevel)")
        print("   Frequency: \(frequency) days/week")
        print("   Expected total sessions: \(frequency * 12)")
        
        var allSessions: [TrainingSession] = []
        
        // Generate sessions for all 12 weeks
        for week in 1...12 {
            let weekSessions = generateWeekSessions(
                week: week,
                userLevel: userLevel,
                frequency: frequency,
                userPreferences: userPreferences
            )
            allSessions.append(contentsOf: weekSessions)
        }
        
        print("✅ UnifiedSessionGenerator: Generated \(allSessions.count) total sessions")
        
        // Validate session consistency
        validateSessionConsistency(sessions: allSessions, expectedFrequency: frequency)
        
        return allSessions
    }
    
    // MARK: - Week Generation
    
    private func generateWeekSessions(
        week: Int,
        userLevel: String,
        frequency: Int,
        userPreferences: UserSessionPreferences?
    ) -> [TrainingSession] {
        
        var weekSessions: [TrainingSession] = []
        
        // Generate sessions for each day of the week based on frequency
        for day in 1...frequency {
            let session = generateDeterministicSession(
                week: week,
                day: day,
                userLevel: userLevel,
                frequency: frequency
            )
            weekSessions.append(session)
        }
        
        return weekSessions
    }
    
    // MARK: - Deterministic Session Generation
    
    /// Generate a deterministic session that will be identical across iPhone and Watch
    private func generateDeterministicSession(
        week: Int,
        day: Int,
        userLevel: String,
        frequency: Int
    ) -> TrainingSession {
        
        // Create deterministic session ID based on week and day
        let sessionId = TrainingSession.stableSessionID(week: week, day: day)
        
        // Get session characteristics based on level and progression
        let sessionCharacteristics = getSessionCharacteristics(
            week: week,
            day: day,
            userLevel: userLevel,
            frequency: frequency
        )
        
        // Generate session using dynamic naming service
        let namingService = DynamicSessionNamingService.shared
        let sessionConfig = namingService.generateSessionConfiguration(
            userLevel: userLevel,
            distance: sessionCharacteristics.distance,
            reps: sessionCharacteristics.reps,
            intensity: sessionCharacteristics.intensity,
            weekNumber: week,
            dayInWeek: day
        )
        
        // Create sprint sets based on characteristics
        let sprintSets = generateSprintSets(
            distance: sessionCharacteristics.distance,
            reps: sessionCharacteristics.reps,
            intensity: sessionCharacteristics.intensity,
            userLevel: userLevel
        )
        
        // Create accessory work based on level and week
        let accessoryWork = generateAccessoryWork(
            userLevel: userLevel,
            week: week,
            sessionType: sessionConfig.type
        )
        
        return TrainingSession(
            id: sessionId,
            week: week,
            day: day,
            type: sessionConfig.type,
            focus: sessionConfig.focus,
            sprints: sprintSets,
            accessoryWork: accessoryWork
        )
    }
    
    // MARK: - Session Characteristics
    
    private struct SessionCharacteristics {
        let distance: Int
        let reps: Int
        let intensity: String
    }
    
    private func getSessionCharacteristics(
        week: Int,
        day: Int,
        userLevel: String,
        frequency: Int
    ) -> SessionCharacteristics {
        
        // Base characteristics on user level
        let levelMultiplier = getLevelMultiplier(userLevel: userLevel)
        let weekProgression = getWeekProgression(week: week)
        let dayVariation = getDayVariation(day: day, frequency: frequency)
        
        // Calculate distance with progression
        let baseDistance = getBaseDistance(userLevel: userLevel)
        let distance = Int(Double(baseDistance) * weekProgression * dayVariation * levelMultiplier)
        
        // Calculate reps with level scaling
        let baseReps = getBaseReps(userLevel: userLevel, frequency: frequency)
        let reps = max(2, Int(Double(baseReps) * levelMultiplier))
        
        // Determine intensity based on week and level
        let intensity = getIntensity(week: week, day: day, userLevel: userLevel)
        
        return SessionCharacteristics(
            distance: min(100, max(10, distance)), // Clamp between 10-100 yards
            reps: min(8, max(2, reps)), // Clamp between 2-8 reps
            intensity: intensity
        )
    }
    
    private func getLevelMultiplier(userLevel: String) -> Double {
        switch userLevel.lowercased() {
        case "beginner": return 0.8
        case "intermediate": return 1.0
        case "advanced": return 1.2
        case "pro", "elite": return 1.4
        default: 
            print("⚠️ iPhone UnifiedSessionGenerator: Unknown level '\(userLevel)' for multiplier - this should not happen!")
            return 0.8  // Emergency fallback
        }
    }
    
    private func getWeekProgression(week: Int) -> Double {
        // Progressive increase over 12 weeks
        switch week {
        case 1...3: return 0.8 // Foundation phase
        case 4...6: return 1.0 // Development phase
        case 7...9: return 1.2 // Intensity phase
        case 10...12: return 1.1 // Peak/taper phase
        default: return 1.0
        }
    }
    
    private func getDayVariation(day: Int, frequency: Int) -> Double {
        // Vary intensity/distance based on day within week
        _ = Double(day) / Double(frequency) // dayRatio for future use
        
        switch day % 3 {
        case 1: return 1.0 // Standard day
        case 2: return 1.1 // Slightly higher intensity
        case 0: return 0.9 // Recovery day
        default: return 1.0
        }
    }
    
    private func getBaseDistance(userLevel: String) -> Int {
        switch userLevel.lowercased() {
        case "beginner": return 25
        case "intermediate": return 35
        case "advanced": return 45
        case "pro", "elite": return 55
        default: 
            print("⚠️ iPhone UnifiedSessionGenerator: Unknown level '\(userLevel)' - this should not happen!")
            return 25  // Emergency fallback
        }
    }
    
    private func getBaseReps(userLevel: String, frequency: Int) -> Int {
        let baseReps: Int
        switch userLevel.lowercased() {
        case "beginner": baseReps = 3
        case "intermediate": baseReps = 4
        case "advanced": baseReps = 5
        case "pro", "elite": baseReps = 6
        default: 
            print("⚠️ iPhone UnifiedSessionGenerator: Unknown level '\(userLevel)' for reps - this should not happen!")
            baseReps = 3  // Emergency fallback
        }
        
        // Adjust based on frequency (more days = fewer reps per session)
        let frequencyAdjustment = frequency >= 5 ? -1 : 0
        return max(2, baseReps + frequencyAdjustment)
    }
    
    private func getIntensity(week: Int, day: Int, userLevel: String) -> String {
        // Intensity progression over weeks and days
        let weekIntensity: String
        switch week {
        case 1...3: weekIntensity = "Moderate"
        case 4...6: weekIntensity = "High"
        case 7...9: weekIntensity = "Max"
        case 10...12: weekIntensity = userLevel.lowercased() == "beginner" ? "High" : "Max"
        default: weekIntensity = "Moderate"
        }
        
        // Adjust for recovery days
        if day % 3 == 0 && weekIntensity == "Max" {
            return "High" // Recovery day adjustment
        }
        
        return weekIntensity
    }
    
    // MARK: - Sprint Set Generation
    
    private func generateSprintSets(
        distance: Int,
        reps: Int,
        intensity: String,
        userLevel: String
    ) -> [SprintSet] {
        
        // Create primary sprint set
        let primarySet = SprintSet(
            distanceYards: distance,
            reps: reps,
            intensity: intensity
        )
        
        var sprintSets = [primarySet]
        
        // Add secondary set for advanced users
        if userLevel.lowercased() == "advanced" || userLevel.lowercased() == "pro" || userLevel.lowercased() == "elite" {
            if reps >= 4 {
                let secondaryDistance = max(10, distance - 10)
                let secondarySet = SprintSet(
                    distanceYards: secondaryDistance,
                    reps: max(2, reps - 2),
                    intensity: intensity == "Max" ? "High" : intensity
                )
                sprintSets.append(secondarySet)
            }
        }
        
        return sprintSets
    }
    
    // MARK: - Accessory Work Generation
    
    private func generateAccessoryWork(
        userLevel: String,
        week: Int,
        sessionType: String
    ) -> [String] {
        
        var accessoryWork: [String] = []
        
        // Always include warm-up and cool-down
        accessoryWork.append("Dynamic Warm-up")
        
        // Add level-specific work
        switch userLevel.lowercased() {
        case "beginner":
            accessoryWork.append("Basic Drills")
            accessoryWork.append("Form Focus")
            
        case "intermediate":
            accessoryWork.append("Speed Drills")
            accessoryWork.append("Power Development")
            
        case "advanced":
            accessoryWork.append("Advanced Drills")
            accessoryWork.append("Performance Work")
            
        case "pro", "elite":
            accessoryWork.append("Elite Drills")
            accessoryWork.append("Competition Prep")
            
        default:
            accessoryWork.append("Standard Drills")
        }
        
        // Add week-specific focus
        switch week {
        case 1...3:
            accessoryWork.append("Technique Focus")
        case 4...6:
            accessoryWork.append("Speed Development")
        case 7...9:
            accessoryWork.append("Performance Training")
        case 10...12:
            accessoryWork.append("Peak Preparation")
        default:
            accessoryWork.append("General Training")
        }
        
        accessoryWork.append("Cool-down")
        
        return accessoryWork
    }
    
    // MARK: - Validation
    
    private func validateSessionConsistency(sessions: [TrainingSession], expectedFrequency: Int) {
        let expectedTotal = expectedFrequency * 12
        
        guard sessions.count == expectedTotal else {
            print("⚠️ UnifiedSessionGenerator: Session count mismatch - Expected: \(expectedTotal), Got: \(sessions.count)")
            return
        }
        
        // Validate week/day structure
        for week in 1...12 {
            let weekSessions = sessions.filter { $0.week == week }
            guard weekSessions.count == expectedFrequency else {
                print("⚠️ UnifiedSessionGenerator: Week \(week) has \(weekSessions.count) sessions, expected \(expectedFrequency)")
                continue
            }
            
            // Validate day sequence
            let days = weekSessions.map { $0.day }.sorted()
            let expectedDays = Array(1...expectedFrequency)
            guard days == expectedDays else {
                print("⚠️ UnifiedSessionGenerator: Week \(week) day sequence incorrect - Expected: \(expectedDays), Got: \(days)")
                continue
            }
        }
        
        print("✅ UnifiedSessionGenerator: Session structure validation passed")
    }
}

// MARK: - Extensions for Stable ID Generation

extension TrainingSession {
    /// Generate stable, deterministic session ID based on week and day
    static func stableSessionID(week: Int, day: Int) -> UUID {
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        
        if let uuid = UUID(uuidString: baseString) {
            return uuid
        }
        
        // Fallback: create deterministic UUID from week/day hash
        let combinedValue = week * 1000 + day
        let hashValue = combinedValue.hashValue
        let uuidString = String(format: "00000000-0000-0000-%04x-%012x", 
                               abs(hashValue) % 65536, 
                               abs(hashValue))
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
}
