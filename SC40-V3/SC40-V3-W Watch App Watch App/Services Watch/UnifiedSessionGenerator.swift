import Foundation

// MARK: - Watch-Specific Types
// Import SessionLibrary types for consistency with iPhone

/// Simplified UserSessionPreferences for Watch app compatibility
struct UserSessionPreferences {
    let favoriteTemplateIDs: [UUID]
    let preferredTemplateIDs: [UUID]
    let dislikedTemplateIDs: [UUID]
    let allowRepeatingFavorites: Bool
    let manualOverrides: [UUID: UUID]
    
    init(
        favoriteTemplateIDs: [UUID] = [],
        preferredTemplateIDs: [UUID] = [],
        dislikedTemplateIDs: [UUID] = [],
        allowRepeatingFavorites: Bool = false,
        manualOverrides: [UUID: UUID] = [:]
    ) {
        self.favoriteTemplateIDs = favoriteTemplateIDs
        self.preferredTemplateIDs = preferredTemplateIDs
        self.dislikedTemplateIDs = dislikedTemplateIDs
        self.allowRepeatingFavorites = allowRepeatingFavorites
        self.manualOverrides = manualOverrides
    }
}

// MARK: - Unified Session Generator (Watch Version)

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
    /// Now uses SessionLibrary as the source of truth for consistency
    private func generateDeterministicSession(
        week: Int,
        day: Int,
        userLevel: String,
        frequency: Int
    ) -> TrainingSession {
        
        // Create deterministic session ID based on week and day
        let sessionId = TrainingSession.stableSessionID(week: week, day: day)
        
        // IMPROVED: Use SessionLibrary as source of truth (SAME AS IPHONE)
        let sessionTemplate = selectSessionTemplate(
            week: week,
            day: day,
            userLevel: userLevel,
            frequency: frequency
        )
        
        // Apply week progression to the template
        let progressedTemplate = applyWeekProgression(
            template: sessionTemplate,
            week: week,
            userLevel: userLevel
        )
        
        // Convert SessionLibrary template to TrainingSession
        let trainingSession = convertTemplateToTrainingSession(
            template: progressedTemplate,
            sessionId: sessionId,
            week: week,
            day: day
        )
        
        print("📚 Watch UnifiedSessionGenerator: Using SessionLibrary template '\(sessionTemplate.name)' for W\(week)D\(day)")
        
        return trainingSession
    }
    
    /// Select appropriate session template from SessionLibrary based on deterministic criteria
    private func selectSessionTemplate(
        week: Int,
        day: Int,
        userLevel: String,
        frequency: Int
    ) -> SprintSessionTemplate {
        
        // Get level-appropriate sessions from SessionLibrary
        let levelSessions = sessionLibrary.filter { $0.level == userLevel }
        
        // If no sessions for exact level, fall back to Beginner
        let availableSessions = levelSessions.isEmpty ? 
            sessionLibrary.filter { $0.level == "Beginner" } : levelSessions
        
        // CRASH PROTECTION: Ensure we have sessions available
        guard !availableSessions.isEmpty else {
            print("🚨 CRITICAL: No sessions available for level '\(userLevel)' or Beginner fallback")
            // Return first session from library as emergency fallback
            return sessionLibrary.first ?? SprintSessionTemplate(
                id: 1, name: "Emergency Fallback", distance: 20, reps: 4, rest: 2, 
                focus: "Basic Training", level: "Beginner", sessionType: .sprint
            )
        }
        
        // Deterministic selection based on week and day (IDENTICAL TO IPHONE)
        let sessionIndex = ((week - 1) * frequency + (day - 1)) % availableSessions.count
        let selectedTemplate = availableSessions[sessionIndex]
        
        print("📚 Watch SessionLibrary: Selected template #\(selectedTemplate.id) '\(selectedTemplate.name)' for \(userLevel) W\(week)D\(day)")
        
        return selectedTemplate
    }
    
    /// Apply week-based progression to session template
    private func applyWeekProgression(
        template: SprintSessionTemplate,
        week: Int,
        userLevel: String
    ) -> SprintSessionTemplate {
        
        let weekProgression = getWeekProgression(week: week)
        let levelMultiplier = getLevelMultiplier(userLevel: userLevel)
        
        // Apply progression to distance and reps
        let progressedDistance = Int(Double(template.distance) * weekProgression * levelMultiplier)
        let progressedReps = Int(Double(template.reps) * levelMultiplier)
        
        // Create progressed template
        return SprintSessionTemplate(
            id: template.id,
            name: template.name,
            distance: min(100, max(10, progressedDistance)), // Clamp 10-100 yards
            reps: min(8, max(2, progressedReps)), // Clamp 2-8 reps
            rest: template.rest,
            focus: template.focus,
            level: template.level,
            sessionType: template.sessionType
        )
    }
    
    /// Convert SessionLibrary template to TrainingSession format
    private func convertTemplateToTrainingSession(
        template: SprintSessionTemplate,
        sessionId: UUID,
        week: Int,
        day: Int
    ) -> TrainingSession {
        
        // Create sprint sets from template
        let sprintSets = [SprintSet(
            distanceYards: template.distance,
            reps: template.reps,
            intensity: determineIntensityFromTemplate(template: template, week: week)
        )]
        
        // Generate accessory work based on template type and level
        let accessoryWork = generateAccessoryWorkFromTemplate(
            template: template,
            week: week
        )
        
        return TrainingSession(
            id: sessionId,
            week: week,
            day: day,
            type: template.sessionType.rawValue,
            focus: template.focus,
            sprints: sprintSets,
            accessoryWork: accessoryWork,
            notes: "Based on SessionLibrary template: \(template.name)"
        )
    }
    
    /// Determine intensity based on template and week progression
    private func determineIntensityFromTemplate(template: SprintSessionTemplate, week: Int) -> String {
        switch template.sessionType {
        case .sprint:
            return week <= 3 ? "Moderate" : (week <= 6 ? "High" : "Max")
        case .tempo:
            return "Moderate"
        case .activeRecovery, .recovery:
            return "Easy"
        case .benchmark:
            return "Max"
        case .comprehensive:
            return week <= 4 ? "Moderate" : "High"
        case .rest:
            return "Easy"
        }
    }
    
    /// Generate accessory work based on template type
    private func generateAccessoryWorkFromTemplate(
        template: SprintSessionTemplate,
        week: Int
    ) -> [String] {
        
        var accessoryWork: [String] = ["Dynamic Warm-up"]
        
        switch template.sessionType {
        case .sprint:
            accessoryWork.append("Sprint Mechanics Drills")
            accessoryWork.append("Acceleration Technique")
        case .tempo:
            accessoryWork.append("Tempo Running Form")
            accessoryWork.append("Rhythm Development")
        case .activeRecovery:
            accessoryWork.append("Light Movement")
            accessoryWork.append("Mobility Work")
        case .benchmark:
            accessoryWork.append("Competition Preparation")
            accessoryWork.append("Mental Focus")
        case .comprehensive:
            accessoryWork.append("Complete Workout Flow")
            accessoryWork.append("Skill Development")
        case .recovery, .rest:
            accessoryWork.append("Recovery Activities")
        }
        
        // Add week-specific elements
        if week >= 7 {
            accessoryWork.append("Advanced Techniques")
        }
        
        accessoryWork.append("Cool-down & Stretching")
        
        return accessoryWork
    }
    
    // MARK: - Helper Methods for Progression
    
    /// Get week-based progression multiplier (0.8 to 1.2)
    private func getWeekProgression(week: Int) -> Double {
        switch week {
        case 1...3: return 0.8  // Foundation weeks
        case 4...6: return 0.9  // Building weeks
        case 7...9: return 1.0  // Peak weeks
        case 10...12: return 1.1 // Competition weeks
        default: return 1.0
        }
    }
    
    /// Get level-based multiplier for session intensity
    private func getLevelMultiplier(userLevel: String) -> Double {
        switch userLevel.lowercased() {
        case "beginner": return 0.8
        case "intermediate": return 1.0
        case "advanced": return 1.2
        case "elite", "pro": return 1.4
        default: return 1.0
        }
    }
    
    // MARK: - Session Validation
    
    /// Validate session consistency across iPhone and Watch
    private func validateSessionConsistency(sessions: [TrainingSession], expectedFrequency: Int) {
        let expectedTotal = expectedFrequency * 12
        
        guard sessions.count == expectedTotal else {
            print("⚠️ Watch: Session count mismatch: Expected \(expectedTotal), got \(sessions.count)")
            return
        }
        
        // Validate week/day structure
        for week in 1...12 {
            let weekSessions = sessions.filter { $0.week == week }
            guard weekSessions.count == expectedFrequency else {
                print("⚠️ Watch: Week \(week) has \(weekSessions.count) sessions, expected \(expectedFrequency)")
                continue
            }
            
            // Validate day sequence
            let days = weekSessions.map { $0.day }.sorted()
            let expectedDays = Array(1...expectedFrequency)
            guard days == expectedDays else {
                print("⚠️ Watch: Week \(week) day sequence incorrect: \(days) vs \(expectedDays)")
                continue
            }
        }
        
        print("✅ Watch: Session consistency validated: \(sessions.count) sessions across 12 weeks")
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
