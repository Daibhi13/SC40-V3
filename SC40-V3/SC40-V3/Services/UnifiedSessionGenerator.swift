import Foundation

// MARK: - Unified Session Generator
// Import SessionLibrary for template access

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
        
        // Validate session consistency and filter out invalid sessions
        let validatedSessions = validateAndFilterSessions(sessions: allSessions, expectedFrequency: frequency)
        
        print("✅ UnifiedSessionGenerator: Validated \(validatedSessions.count) sessions (filtered \(allSessions.count - validatedSessions.count) invalid)")
        
        return validatedSessions
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
    func generateDeterministicSession(
        week: Int,
        day: Int,
        userLevel: String,
        frequency: Int
    ) -> TrainingSession {
        
        // Create deterministic session ID based on week and day
        let sessionId = TrainingSession.stableSessionID(week: week, day: day)
        
        // IMPROVED: Use SessionLibrary as source of truth
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
            userLevel: userLevel,
            frequency: frequency
        )
        
        // Convert SessionLibrary template to TrainingSession
        let trainingSession = convertTemplateToTrainingSession(
            template: progressedTemplate,
            sessionId: sessionId,
            week: week,
            day: day
        )
        
        print("📚 UnifiedSessionGenerator: Using SessionLibrary template '\(sessionTemplate.name)' for W\(week)D\(day)")
        
        return trainingSession
    }
    
    /// Select appropriate session template from SessionLibrary based on deterministic criteria
    private func selectSessionTemplate(
        week: Int,
        day: Int,
        userLevel: String,
        frequency: Int
    ) -> SprintSessionTemplate {
        
        // ENHANCED: Get frequency-appropriate sessions for this specific day
        let frequencyFilteredSessions = getFrequencyAppropriateSessionsForDay(
            level: userLevel,
            frequency: frequency,
            week: week,
            day: day
        )
        
        // CRASH PROTECTION: Ensure we have sessions available
        guard !frequencyFilteredSessions.isEmpty else {
            print("🚨 CRITICAL: No frequency-appropriate sessions available for \(userLevel) \(frequency)-day program")
            // Fallback to basic level filtering
            let levelSessions = sessionLibrary.filter { $0.level == userLevel }
            let fallbackSessions = levelSessions.isEmpty ? 
                sessionLibrary.filter { $0.level == "Beginner" } : levelSessions
            
            if !fallbackSessions.isEmpty {
                let sessionIndex = ((week - 1) * frequency + (day - 1)) % fallbackSessions.count
                return fallbackSessions[sessionIndex]
            }
            
            // Emergency fallback
            return sessionLibrary.first ?? SprintSessionTemplate(
                id: 1, name: "Emergency Fallback", distance: 20, reps: 4, rest: 2, 
                focus: "Basic Training", level: "Beginner", sessionType: .sprint
            )
        }
        
        // ENHANCED: Smart selection based on frequency pattern and day position
        let selectedTemplate = selectFromFrequencyFilteredSessions(
            sessions: frequencyFilteredSessions,
            week: week,
            day: day,
            frequency: frequency
        )
        
        print("📚 SessionLibrary: Selected template #\(selectedTemplate.id) '\(selectedTemplate.name)' for \(userLevel) \(frequency)-day W\(week)D\(day) (\(selectedTemplate.sessionType.rawValue))")
        
        return selectedTemplate
    }
    
    /// Get frequency-appropriate sessions for a specific training day
    private func getFrequencyAppropriateSessionsForDay(
        level: String,
        frequency: Int,
        week: Int,
        day: Int
    ) -> [SprintSessionTemplate] {
        
        // Get level-appropriate sessions first
        let levelSessions = sessionLibrary.filter { $0.level == level }
        let baseSessions = levelSessions.isEmpty ? 
            sessionLibrary.filter { $0.level == "Beginner" } : levelSessions
        
        // Apply frequency-specific filtering for each user choice
        switch frequency {
        case 1: // 1-Day Program: Maximum intensity, comprehensive session
            return getOneDayProgramSessions(
                sessions: baseSessions,
                week: week
            )
            
        case 2: // 2-Day Program: High intensity, alternating focus
            return getTwoDayProgramSessions(
                sessions: baseSessions,
                day: day,
                week: week
            )
            
        case 3: // 3-Day Program: Balanced specialization
            return getThreeDayProgramSessions(
                sessions: baseSessions,
                day: day,
                week: week
            )
            
        case 4: // 4-Day Program: Comprehensive with recovery
            return getFourDayProgramSessions(
                sessions: baseSessions,
                day: day,
                week: week
            )
            
        case 5: // 5-Day Program: Specialized with active recovery
            return getFiveDayProgramSessions(
                sessions: baseSessions,
                day: day,
                week: week
            )
            
        case 6: // 6-Day Program: High frequency with recovery integration
            return getSixDayProgramSessions(
                sessions: baseSessions,
                day: day,
                week: week
            )
            
        default:
            return baseSessions
        }
    }
    
    // MARK: - Specific Frequency Program Logic
    
    /// 1-Day Program: Maximum intensity, comprehensive session - Access ALL level-appropriate sessions
    private func getOneDayProgramSessions(
        sessions: [SprintSessionTemplate],
        week: Int
    ) -> [SprintSessionTemplate] {
        
        // Include benchmark sessions every 4th week
        if week % 4 == 0 {
            let benchmarkSessions = sessions.filter { $0.sessionType == .benchmark }
            if !benchmarkSessions.isEmpty {
                return benchmarkSessions
            }
        }
        
        // 1-day = access ALL sessions for maximum variety and intensity
        // Prefer higher intensity sessions but don't exclude others
        let allSprints = sessions.filter { $0.sessionType == .sprint }
        
        // Sort by intensity (distance × reps) but return all for selection variety
        let sortedSessions = allSprints.sorted { session1, session2 in
            let intensity1 = session1.distance * session1.reps
            let intensity2 = session2.distance * session2.reps
            return intensity1 > intensity2
        }
        
        return sortedSessions.isEmpty ? sessions : sortedSessions
    }
    
    /// 2-Day Program: High intensity, alternating focus - Access ALL level-appropriate sessions
    private func getTwoDayProgramSessions(
        sessions: [SprintSessionTemplate],
        day: Int,
        week: Int
    ) -> [SprintSessionTemplate] {
        
        switch day {
        case 1: // Day 1: Acceleration + Drive Phase - Prefer but don't exclude
            let accelerationSessions = sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Acceleration") || 
                 session.focus.contains("Drive") ||
                 session.distance <= 50)
            }
            // If no specific sessions, return all sprints
            return accelerationSessions.isEmpty ? 
                sessions.filter { $0.sessionType == .sprint } : accelerationSessions
            
        case 2: // Day 2: Max Velocity + Speed Endurance
            if week % 4 == 0 { // Benchmark every 4th week
                let benchmarkSessions = sessions.filter { $0.sessionType == .benchmark }
                return benchmarkSessions.isEmpty ? 
                    sessions.filter { $0.sessionType == .sprint } : benchmarkSessions
            } else {
                let velocitySessions = sessions.filter { session in
                    session.sessionType == .sprint && 
                    (session.focus.contains("Max Velocity") || 
                     session.focus.contains("Speed Endurance") ||
                     session.distance >= 50)
                }
                // If no specific sessions, return all sprints
                return velocitySessions.isEmpty ? 
                    sessions.filter { $0.sessionType == .sprint } : velocitySessions
            }
            
        default:
            return sessions.filter { $0.sessionType == .sprint }
        }
    }
    
    /// 3-Day Program: Balanced specialization - Access ALL level-appropriate sessions
    private func getThreeDayProgramSessions(
        sessions: [SprintSessionTemplate],
        day: Int,
        week: Int
    ) -> [SprintSessionTemplate] {
        
        switch day {
        case 1: // Day 1: Acceleration Focus - Prefer but include all
            let accelerationSessions = sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Acceleration") || session.distance <= 40)
            }
            return accelerationSessions.isEmpty ? 
                sessions.filter { $0.sessionType == .sprint } : accelerationSessions
            
        case 2: // Day 2: Max Velocity Focus - Prefer but include all
            let velocitySessions = sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Max Velocity") || 
                 session.focus.contains("Flying") ||
                 (session.distance >= 30 && session.distance <= 70))
            }
            return velocitySessions.isEmpty ? 
                sessions.filter { $0.sessionType == .sprint } : velocitySessions
            
        case 3: // Day 3: Speed Endurance or Benchmark
            if week % 4 == 0 { // Benchmark every 4th week
                let benchmarkSessions = sessions.filter { $0.sessionType == .benchmark }
                return benchmarkSessions.isEmpty ? 
                    sessions.filter { $0.sessionType == .sprint } : benchmarkSessions
            } else {
                let enduranceSessions = sessions.filter { session in
                    session.sessionType == .sprint && 
                    (session.focus.contains("Speed Endurance") || session.distance >= 60)
                }
                return enduranceSessions.isEmpty ? 
                    sessions.filter { $0.sessionType == .sprint } : enduranceSessions
            }
            
        default:
            return sessions.filter { $0.sessionType == .sprint }
        }
    }
    
    /// 4-Day Program: Comprehensive with recovery - Access ALL level-appropriate sessions
    private func getFourDayProgramSessions(
        sessions: [SprintSessionTemplate],
        day: Int,
        week: Int
    ) -> [SprintSessionTemplate] {
        
        switch day {
        case 1: // Day 1: Acceleration - Prefer but include all
            let accelerationSessions = sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Acceleration") || session.distance <= 35)
            }
            return accelerationSessions.isEmpty ? 
                sessions.filter { $0.sessionType == .sprint } : accelerationSessions
            
        case 2: // Day 2: Max Velocity - Prefer but include all
            let velocitySessions = sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Max Velocity") || session.focus.contains("Flying"))
            }
            return velocitySessions.isEmpty ? 
                sessions.filter { $0.sessionType == .sprint } : velocitySessions
            
        case 3: // Day 3: Active Recovery or Tempo - Include recovery types and light sprints
            let recoverySessions = sessions.filter { session in
                session.sessionType == .activeRecovery || 
                session.sessionType == .tempo ||
                (session.sessionType == .sprint && session.distance <= 30)
            }
            return recoverySessions.isEmpty ? 
                sessions.filter { $0.sessionType == .sprint } : recoverySessions
            
        case 4: // Day 4: Speed Endurance or Benchmark
            if week % 4 == 0 { // Benchmark every 4th week
                let benchmarkSessions = sessions.filter { $0.sessionType == .benchmark }
                return benchmarkSessions.isEmpty ? 
                    sessions.filter { $0.sessionType == .sprint } : benchmarkSessions
            } else {
                let enduranceSessions = sessions.filter { session in
                    session.sessionType == .sprint && 
                    (session.focus.contains("Speed Endurance") || session.distance >= 50)
                }
                return enduranceSessions.isEmpty ? 
                    sessions.filter { $0.sessionType == .sprint } : enduranceSessions
            }
            
        default:
            return sessions.filter { $0.sessionType == .sprint }
        }
    }
    
    /// 5-Day Program: Specialized with active recovery
    private func getFiveDayProgramSessions(
        sessions: [SprintSessionTemplate],
        day: Int,
        week: Int
    ) -> [SprintSessionTemplate] {
        
        switch day {
        case 1: // Day 1: Acceleration
            return sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Acceleration") || session.distance <= 30)
            }
            
        case 2: // Day 2: Active Recovery
            return sessions.filter { session in
                session.sessionType == .activeRecovery || 
                session.sessionType == .tempo
            }
            
        case 3: // Day 3: Max Velocity
            return sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Max Velocity") || session.focus.contains("Flying"))
            }
            
        case 4: // Day 4: Light Sprint or Recovery
            return sessions.filter { session in
                session.sessionType == .activeRecovery || 
                (session.sessionType == .sprint && session.distance <= 25)
            }
            
        case 5: // Day 5: Speed Endurance or Benchmark
            if week % 4 == 0 { // Benchmark every 4th week
                return sessions.filter { $0.sessionType == .benchmark }
            } else {
                return sessions.filter { session in
                    session.sessionType == .sprint && 
                    (session.focus.contains("Speed Endurance") || session.distance >= 60)
                }
            }
            
        default:
            return sessions.filter { $0.sessionType == .sprint }
        }
    }
    
    /// 6-Day Program: High frequency with recovery integration
    private func getSixDayProgramSessions(
        sessions: [SprintSessionTemplate],
        day: Int,
        week: Int
    ) -> [SprintSessionTemplate] {
        
        switch day {
        case 1: // Day 1: Acceleration
            return sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Acceleration") || session.distance <= 30)
            }
            
        case 2: // Day 2: Active Recovery
            return sessions.filter { session in
                session.sessionType == .activeRecovery || 
                session.sessionType == .tempo
            }
            
        case 3: // Day 3: Max Velocity
            return sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Max Velocity") || session.focus.contains("Flying"))
            }
            
        case 4: // Day 4: Light Recovery
            return sessions.filter { session in
                session.sessionType == .activeRecovery || 
                (session.sessionType == .sprint && session.distance <= 20)
            }
            
        case 5: // Day 5: Speed Endurance
            return sessions.filter { session in
                session.sessionType == .sprint && 
                (session.focus.contains("Speed Endurance") || session.distance >= 60)
            }
            
        case 6: // Day 6: Comprehensive or Benchmark
            if week % 4 == 0 { // Benchmark every 4th week
                return sessions.filter { $0.sessionType == .benchmark }
            } else {
                return sessions.filter { session in
                    session.sessionType == .comprehensive ||
                    (session.sessionType == .sprint && session.distance >= 40)
                }
            }
            
        default:
            return sessions.filter { $0.sessionType == .sprint }
        }
    }
    
    /// Smart selection from frequency-filtered sessions
    private func selectFromFrequencyFilteredSessions(
        sessions: [SprintSessionTemplate],
        week: Int,
        day: Int,
        frequency: Int
    ) -> SprintSessionTemplate {
        
        // If we have filtered sessions, use smart selection
        guard !sessions.isEmpty else {
            return sessionLibrary.first!
        }
        
        // Use deterministic but varied selection
        let weekOffset = (week - 1) * 7 // Vary by week
        let dayOffset = (day - 1) * 3   // Vary by day
        let frequencyOffset = frequency * 2 // Vary by frequency
        
        let smartIndex = (weekOffset + dayOffset + frequencyOffset) % sessions.count
        return sessions[smartIndex]
    }
    
    /// Apply week-based progression to session template with frequency adjustment
    private func applyWeekProgression(
        template: SprintSessionTemplate,
        week: Int,
        userLevel: String,
        frequency: Int
    ) -> SprintSessionTemplate {
        
        let weekProgression = getWeekProgression(week: week)
        let levelMultiplier = getLevelMultiplier(userLevel: userLevel)
        let frequencyMultiplier = getFrequencyIntensityMultiplier(frequency: frequency, week: week)
        
        // ENHANCED: Apply all multipliers for comprehensive progression
        let combinedMultiplier = weekProgression * levelMultiplier * frequencyMultiplier
        
        // Apply progression to distance and reps
        let progressedDistance = Int(Double(template.distance) * combinedMultiplier)
        let progressedReps = Int(Double(template.reps) * levelMultiplier) // Reps based on level only
        
        // Adjust rest time based on frequency (higher frequency = longer rest for recovery)
        let adjustedRest = template.rest + (frequency > 5 ? 1 : 0)
        
        // Create progressed template
        return SprintSessionTemplate(
            id: template.id,
            name: template.name,
            distance: min(120, max(5, progressedDistance)), // Expanded range for frequency variation
            reps: min(10, max(1, progressedReps)), // Expanded range for frequency variation
            rest: min(8, max(1, adjustedRest)), // Clamp rest time
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
    
    /// Get frequency-based intensity adjustment for each user choice
    private func getFrequencyIntensityMultiplier(frequency: Int, week: Int) -> Double {
        // Specific intensity adjustments for each frequency choice
        
        let baseMultiplier: Double
        switch frequency {
        case 1: // 1-Day: Maximum intensity per session
            baseMultiplier = 1.3
            
        case 2: // 2-Day: High intensity per session
            baseMultiplier = 1.2
            
        case 3: // 3-Day: Balanced intensity
            baseMultiplier = 1.0
            
        case 4: // 4-Day: Moderate intensity with recovery
            baseMultiplier = 0.95
            
        case 5: // 5-Day: Lower intensity per session
            baseMultiplier = 0.9
            
        case 6: // 6-Day: Lowest intensity per session
            baseMultiplier = 0.85
            
        default:
            baseMultiplier = 1.0
        }
        
        // Week-based progression adjustment
        let weekAdjustment: Double
        switch week {
        case 1...3: // Foundation weeks: Reduce intensity
            weekAdjustment = 0.9
        case 4...6: // Building weeks: Standard intensity
            weekAdjustment = 1.0
        case 7...9: // Peak weeks: Increase intensity
            weekAdjustment = 1.1
        case 10...12: // Competition weeks: Peak intensity
            weekAdjustment = 1.15
        default:
            weekAdjustment = 1.0
        }
        
        return baseMultiplier * weekAdjustment
    }
    
    // MARK: - Session Validation
    
    /// Validate session consistency across iPhone and Watch
    private func validateAndFilterSessions(sessions: [TrainingSession], expectedFrequency: Int) -> [TrainingSession] {
        let expectedTotal = expectedFrequency * 12
        
        if sessions.count != expectedTotal {
            print("⚠️ Session count mismatch: expected \(expectedTotal), got \(sessions.count)")
        }
        
        // Filter out invalid sessions using WatchCrashDebugger validation
        let validSessions = sessions.compactMap { session -> TrainingSession? in
            // Basic validation
            guard !session.type.isEmpty,
                  !session.focus.isEmpty,
                  session.week >= 1 && session.week <= 12,
                  session.day >= 1 && session.day <= 7,
                  !session.sprints.isEmpty else {
                print("❌ Invalid session filtered out: W\(session.week)D\(session.day)")
                return nil
            }
            
            // Validate sprints
            let validSprints = session.sprints.allSatisfy { sprint in
                sprint.distanceYards > 0 && sprint.reps > 0
            }
            
            guard validSprints else {
                print("❌ Session with invalid sprints filtered out: W\(session.week)D\(session.day)")
                return nil
            }
            
            return session
        }
        
        // Validate week/day distribution for valid sessions
        for week in 1...12 {
            let weekSessions = validSessions.filter { $0.week == week }
            if weekSessions.count != expectedFrequency {
                print("⚠️ Week \(week) has \(weekSessions.count) valid sessions, expected \(expectedFrequency)")
            }
        }
        
        print("✅ Session validation completed: \(validSessions.count)/\(sessions.count) sessions valid")
        return validSessions
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
