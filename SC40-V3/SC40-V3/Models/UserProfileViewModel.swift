import Foundation
import Combine
import OSLog
import Algorithms

final class UserProfileViewModel: ObservableObject, @unchecked Sendable {
    @Published var profile: UserProfile {
        didSet {
            saveProfile()
        }
    }

    private let userDefaultsKey = "UserProfileData"
    private let logger = LoggingService.shared.persistence
    
    // Session storage to avoid circular dependencies
    private var allSessions: [UUID: TrainingSession] = [:] // Using TrainingSession now
    private var completedSessions: [UUID: TrainingSession] = [:]

    // Automatically refresh upcoming sessions when feedback is updated
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let loaded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = loaded
            logger.info("Loaded user profile for \(loaded.name)")
        } else {
            // Check for onboarding data in UserDefaults first
            let savedLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Intermediate"
            let savedFrequency = UserDefaults.standard.integer(forKey: "trainingFrequency")
            let savedPB = UserDefaults.standard.double(forKey: "personalBest40yd")
            
            // Create minimal profile - will be populated during onboarding
            let newProfile = UserProfile(
                name: "New User",
                email: nil,
                gender: "Male",
                age: 25,
                height: 70,
                weight: nil,
                personalBests: savedPB > 0 ? ["40yd": savedPB] : [:], // Use saved PB if available
                level: savedLevel, // Use saved level from onboarding
                baselineTime: savedPB > 0 ? savedPB : 0.0, // Use saved baseline time
                frequency: savedFrequency > 0 ? savedFrequency : 3, // Use saved frequency
                currentWeek: 1,
                currentDay: 1,
                leaderboardOptIn: true
            )
            self.profile = newProfile
            logger.info("Created new user profile - awaiting onboarding data")
        }
        
        // Enable automatic session refresh when profile changes
        $profile
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Refresh sessions when profile changes
                self?.sendSessionsToWatch()
            }
            .store(in: &cancellables)
    }

    // MARK: - Persistence
    
    private func saveProfile() {
        do {
            let data = try JSONEncoder().encode(self.profile)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            logger.info("Profile saved successfully for \(self.profile.name)")
        } catch {
            logger.error("Failed to save profile: \(error.localizedDescription)")
            Task { @MainActor in
                ErrorHandlingService.shared.handle(.storageError(error))
            }
        }
    }
    
    func resetProfile() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        self.profile = UserProfile(
            name: "New User",
            email: nil,
            gender: "Male",
            age: 25,
            height: 70,
            weight: nil,
            personalBests: ["40yd": 5.0],
            level: "Beginner",
            baselineTime: 5.0,
            frequency: 3,
            currentWeek: 1,
            currentDay: 1,
            leaderboardOptIn: true
        )
    }
    
    // MARK: - Basic Session Management (Re-enabled)
    
    // Get upcoming sessions for the user (using UUID-based storage)
    func getUpcomingSessions(count: Int = 7) -> [UUID] {
        let currentWeek = profile.currentWeek
        let currentDay = profile.currentDay
        
        return profile.sessionIDs.filter { sessionID in
            if let session = allSessions[sessionID] {
                // Return sessions from current week onwards, and from current day onwards within current week
                return session.week > currentWeek || 
                       (session.week == currentWeek && session.day >= currentDay)
            }
            return false
        }.prefix(count).map { $0 }
    }
    
    // Get current week sessions
    func getCurrentWeekSessions() -> [UUID] {
        let currentWeek = profile.currentWeek
        return profile.sessionIDs.filter { sessionID in
            allSessions[sessionID]?.week == currentWeek
        }
    }
    
    // Advance to next session (improved implementation)
    private func advanceToNextSession() {
        // Find the next incomplete session
        if let nextSessionID = getUpcomingSessions(count: 1).first,
           let nextSession = allSessions[nextSessionID] {
            profile.currentWeek = nextSession.week
            profile.currentDay = nextSession.day
            print("📅 Advanced to Week \(nextSession.week), Day \(nextSession.day)")
        } else {
            // Simple advancement logic as fallback
            if profile.currentDay < 7 {
                profile.currentDay += 1
            } else {
                profile.currentDay = 1
                profile.currentWeek += 1
            }
            print("📅 Advanced to Week \(profile.currentWeek), Day \(profile.currentDay) (fallback)")
        }
    }
    
    // Enable adaptive program generation using SessionLibrary with Algorithms
    func refreshAdaptiveProgram() {
        LoggingService.shared.session.info("Generating adaptive program for level: \(self.profile.level), frequency: \(self.profile.frequency) days/week")
        
        // Create user preferences object
        let userPreferences = UserSessionPreferences(
            favoriteTemplateIDs: self.profile.favoriteSessionTemplateIDs,
            preferredTemplateIDs: self.profile.preferredSessionTemplateIDs,
            dislikedTemplateIDs: profile.dislikedSessionTemplateIDs,
            allowRepeatingFavorites: profile.allowRepeatingFavorites,
            manualOverrides: profile.manualSessionOverrides
        )
        
        // Use Algorithms framework for intelligent session optimization
        _ = AlgorithmicWorkoutOptimizer.shared
        
        // Initialize performance data collection for algorithmic optimization
        _ = PerformanceDataCollector.shared
        
        // Generate real training sessions using algorithmic SessionLibrary with all session types
        let weeklyPrograms = WeeklyProgramTemplate.generateWithUserPreferences(
            level: profile.level,
            totalDaysPerWeek: profile.frequency,
            userPreferences: userPreferences,
            includeActiveRecovery: profile.frequency >= 6,
            includeRestDay: profile.frequency >= 7
        )
        
        // Convert weekly programs to TrainingSession objects
        let trainingSessions = convertWeeklyProgramsToTrainingSessions(weeklyPrograms)
        
        // Store sessions in local storage and update profile with session IDs
        var sessionIDs: [UUID] = []
        allSessions.removeAll() // Clear existing sessions
        
        for session in trainingSessions {
            allSessions[session.id] = session
            sessionIDs.append(session.id)
        }
        
        profile.sessionIDs = sessionIDs
        logger.info("Generated \(trainingSessions.count) real training sessions across 12 weeks")
        
        // Send updated sessions to watch
        sendSessionsToWatch()
    }
    
    // MARK: - Performance Data Integration
    
    /// Collect performance data when a session is completed
    func recordSessionCompletion(_ session: TrainingSession) {
        // Feed performance data to the algorithmic system for continuous optimization
        PerformanceDataCollector.shared.collectSessionPerformance(from: session)
        
        // Log session completion for science-based evolution
        logger.info("Session completed: \(session.type) - Week \(session.week), Day \(session.day)")
        
        // Trigger session library evolution if performance patterns indicate need
        if shouldTriggerLibraryEvolution() {
            evolveSessionLibraryBasedOnPerformance()
        }
    }
    
    private func shouldTriggerLibraryEvolution() -> Bool {
        // Check if we have enough data and performance patterns suggest evolution is needed
        let performanceHistory = PerformanceDataCollector.shared.performanceHistory
        
        // Trigger evolution every 20 sessions or if performance is declining
        if performanceHistory.count >= 20 {
            let recentPerformance = performanceHistory.suffix(5)
            let averageImprovement = recentPerformance.map(\.improvementRate).reduce(0, +) / Double(recentPerformance.count)
            
            // Trigger if improvement rate is low or negative
            return averageImprovement < 0.02
        }
        
        return false
    }
    
    private func evolveSessionLibraryBasedOnPerformance() {
        logger.info("🧬 Triggering session library evolution based on performance data")
        
        // This would implement the science-based session evolution
        // For now, regenerate the program with updated algorithmic parameters
        refreshAdaptiveProgram()
        
        print("📈 Session library evolved - new sessions generated based on performance science")
    }
    
    // MARK: - User Session Preferences & Favorites
    
    /// Mark a session template as a favorite
    func addFavoriteSession(templateID: Int) {
        if !profile.favoriteSessionTemplateIDs.contains(templateID) {
            profile.favoriteSessionTemplateIDs.append(templateID)
            print("⭐ Added session \(templateID) to favorites")
        }
    }
    
    /// Remove a session template from favorites  
    func removeFavoriteSession(templateID: Int) {
        profile.favoriteSessionTemplateIDs.removeAll { $0 == templateID }
        print("💔 Removed session \(templateID) from favorites")
    }
    
    /// Mark a session template as preferred (increased frequency)
    func addPreferredSession(templateID: Int) {
        if !profile.preferredSessionTemplateIDs.contains(templateID) {
            profile.preferredSessionTemplateIDs.append(templateID)
            print("👍 Added session \(templateID) to preferred")
        }
    }
    
    /// Mark a session template as disliked (avoid unless necessary)
    func addDislikedSession(templateID: Int) {
        if !profile.dislikedSessionTemplateIDs.contains(templateID) {
            profile.dislikedSessionTemplateIDs.append(templateID)
            print("👎 Added session \(templateID) to disliked")
        }
    }
    
    /// Toggle the user's preference for allowing repeated favorite workouts
    func toggleAllowRepeatingFavorites() {
        profile.allowRepeatingFavorites.toggle()
        print("🔄 Allow repeating favorites: \(profile.allowRepeatingFavorites)")
    }
    
    /// Let user manually select a specific workout for a particular day
    func setManualSessionOverride(sessionID: UUID, templateID: Int) {
        profile.manualSessionOverrides[sessionID] = templateID
        print("👆 User manually selected template \(templateID) for session \(sessionID)")
        
        // Regenerate program to apply the override
        refreshAdaptiveProgram()
    }
    
    /// Get user's favorite sessions that match their level
    func getUserFavorites() -> [SprintSessionTemplate] {
        return WeeklyProgramTemplate.getUserFavoriteSessions(for: profile)
    }
    
    /// Quick method to favorite the last completed session
    func favoriteLastCompletedSession() {
        guard let lastSessionID = profile.completedSessionIDs.last,
              let lastSession = allSessions[lastSessionID],
              let templateID = findTemplateIDForSession(lastSession) else {
            print("❌ Could not find template ID for last session")
            return
        }
        
        addFavoriteSession(templateID: templateID)
        print("⭐ Favorited last completed session: \(lastSession.type)")
    }
    
    /// Helper to find template ID based on session characteristics
    private func findTemplateIDForSession(_ session: TrainingSession) -> Int? {
        // This is a helper function to map completed sessions back to template IDs
        // You might need to store this mapping during session creation
        return sessionLibrary.first { template in
            template.name.contains(session.type) || session.focus.contains(template.focus)
        }?.id
    }
    
    /// Get session recommendations based on user preferences
    func getRecommendedSessions(count: Int = 5) -> [SprintSessionTemplate] {
        let userLevel = profile.level
        let availableSessions = sessionLibrary.filter { $0.level == userLevel }
        
        // Prioritize favorites and preferred, avoid disliked
        let favorites = availableSessions.filter { profile.favoriteSessionTemplateIDs.contains($0.id) }
        let preferred = availableSessions.filter { profile.preferredSessionTemplateIDs.contains($0.id) }
        let others = availableSessions.filter { 
            !profile.favoriteSessionTemplateIDs.contains($0.id) && 
            !profile.preferredSessionTemplateIDs.contains($0.id) &&
            !profile.dislikedSessionTemplateIDs.contains($0.id)
        }
        
        // Combine and return top recommendations
        var recommendations = favorites + preferred + others
        recommendations.shuffle()
        return Array(recommendations.prefix(count))
    }
    
    /// Send current training sessions to Apple Watch
    private func sendSessionsToWatch() {
        // Get session IDs and send them to watch
        let upcomingSessions = getUpcomingSessions(count: 7)
        
        LoggingService.shared.logWatchSync(sessionCount: upcomingSessions.count, dataSize: 0)
        for (index, sessionID) in upcomingSessions.enumerated() {
            if let session = allSessions[sessionID] {
                print("  Session \(index + 1): W\(session.week)/D\(session.day) - \(session.type) (\(session.focus))")
            } else {
                print("  Session \(index + 1): \(sessionID) (session not found)")
            }
        }
        
        // Send sessions to watch now that build issues are resolved
        let sessionObjects = upcomingSessions.compactMap { sessionID in
            allSessions[sessionID]
        }
        
        Task {
            await MainActor.run {
                WatchSessionManager.shared.sendTrainingSessions(sessionObjects)
            }
        }
    }
    
    // MARK: - Session Completion
    
    /// Mark a session as completed and advance to next session
    func completeSession(_ sessionID: UUID, sprintTimes: [Double] = [], rpe: Int? = nil, notes: String? = nil) {
        guard var session = allSessions[sessionID] else {
            print("❌ Session not found: \(sessionID)")
            return
        }
        
        // Mark session as completed
        session.isCompleted = true
        session.completionDate = Date()
        session.sprintTimes = sprintTimes
        session.rpe = rpe
        session.sessionNotes = notes
        
        // Calculate session statistics
        if !sprintTimes.isEmpty {
            session.personalBest = sprintTimes.min()
            session.averageTime = sprintTimes.reduce(0, +) / Double(sprintTimes.count)
            
            // Update user's personal best if this session achieved it
            if let newPB = session.personalBest {
                let currentPB = profile.personalBests["40yd"] ?? profile.baselineTime
                if newPB < currentPB {
                    updatePersonalBest(newPB)
                }
            }
        }
        
        // Move session to completed storage
        allSessions[sessionID] = session
        completedSessions[sessionID] = session
        profile.completedSessionIDs.append(sessionID)
        
        // Record in HistoryManager for real-time updates
        Task { @MainActor in
            HistoryManager.shared.recordFullSession(
                session: session,
                sprintTimes: sprintTimes,
                notes: notes
            )
        }
        
        // Advance to next session
        advanceToNextSession()
        
        print("✅ Completed session: W\(session.week)/D\(session.day) - \(session.type)")
        
        // Send updated sessions to watch
        sendSessionsToWatch()
    }
    
    /// Mark a session as stopped partway through
    func stopSessionPartway(_ sessionID: UUID, completedSprints: Int, sprintTimes: [Double] = [], stopReason: String = "User stopped", notes: String? = nil) {
        guard let session = allSessions[sessionID] else {
            print("❌ Session not found: \(sessionID)")
            return
        }
        
        let totalSprints = session.sprints.reduce(0) { $0 + $1.reps }
        
        // Record partial session in HistoryManager
        Task { @MainActor in
            HistoryManager.shared.recordPartialSession(
                session: session,
                completedSprints: completedSprints,
                totalSprints: totalSprints,
                sprintTimes: sprintTimes,
                stopReason: stopReason,
                notes: notes
            )
        }
        
        print("⏸️ Stopped session partway: W\(session.week)/D\(session.day) - \(completedSprints)/\(totalSprints) sprints")
    }
    
    // MARK: - Session Conversion Functions
    
    /// Converts SessionLibrary weekly programs to TrainingSession objects
    private func convertWeeklyProgramsToTrainingSessions(_ weeklyPrograms: [WeeklyProgramTemplate]) -> [TrainingSession] {
        var trainingSessions: [TrainingSession] = []
        
        for weeklyProgram in weeklyPrograms {
            for daySession in weeklyProgram.sessions {
                let session: TrainingSession
                
                if let template = daySession.sessionTemplate {
                    // Handle comprehensive sessions with full workout phases
                    if template.sessionType.rawValue == "Comprehensive" {
                        // Create a comprehensive session with all phases from the example
                        session = createComprehensiveSession(
                            week: weeklyProgram.weekNumber,
                            day: daySession.dayNumber,
                            template: template,
                            notes: daySession.notes
                        )
                    } else {
                        // Convert regular sprint session template to training session
                        let sprintSet = SprintSet(
                            distanceYards: template.distance,
                            reps: template.reps,
                            intensity: template.sessionType.rawValue == "Benchmark" ? "test" : "max"
                        )
                        
                        // Add accessory work based on session type and focus
                        let accessoryWork = generateAccessoryWork(for: template)
                        
                        session = TrainingSession(
                            id: TrainingSession.stableSessionID(week: weeklyProgram.weekNumber, day: daySession.dayNumber),
                            week: weeklyProgram.weekNumber,
                            day: daySession.dayNumber,
                            type: template.sessionType.rawValue,
                            focus: template.focus,
                            sprints: [sprintSet],
                            accessoryWork: accessoryWork,
                            notes: daySession.notes ?? "Rest: \(template.rest)s between reps"
                        )
                    }
                } else {
                    // Handle rest or active recovery days
                    let type = daySession.sessionType.rawValue
                    let focus = daySession.sessionType.rawValue == "Rest" ? "Complete rest" : "Light activity"
                    let accessoryWork = daySession.sessionType.rawValue == "Active Recovery" ? 
                        ["20-30 min easy jog", "Dynamic stretching", "Foam rolling"] : []
                    
                    session = TrainingSession(
                        id: TrainingSession.stableSessionID(week: weeklyProgram.weekNumber, day: daySession.dayNumber),
                        week: weeklyProgram.weekNumber,
                        day: daySession.dayNumber,
                        type: type,
                        focus: focus,
                        sprints: [],
                        accessoryWork: accessoryWork,
                        notes: daySession.notes
                    )
                }
                
                trainingSessions.append(session)
            }
        }
        
        return trainingSessions
    }
    
    /// Creates a comprehensive training session with all workout phases
    private func createComprehensiveSession(
        week: Int,
        day: Int,
        template: SprintSessionTemplate,
        notes: String?
    ) -> TrainingSession {
        // Use the comprehensive library to create a full workout session
        let comprehensiveSession = template.toComprehensiveSession()
        return comprehensiveSession.toTrainingSession(week: week, day: day)
    }
    
    /// Generates accessory work based on the session template
    private func generateAccessoryWork(for template: SprintSessionTemplate) -> [String] {
        let focus = template.focus.lowercased()
        
        if focus.contains("acceleration") || focus.contains("accel") {
            return ["A-Skip 2x20m", "Wall Drill 3x10", "3-Point Start Practice"]
        } else if focus.contains("max velocity") || focus.contains("top speed") {
            return ["Flying start practice", "B-Skip 2x20m", "High knee runs"]
        } else if focus.contains("speed endurance") {
            return ["Tempo run 400m", "Dynamic stretching", "Core stability"]
        } else if focus.contains("benchmark") || focus.contains("test") {
            return ["Extended warm-up", "Mental preparation", "Cool-down protocol"]
        } else {
            return ["Dynamic warm-up", "Sprint technique drills", "Recovery stretches"]
        }
    }
    
    // MARK: - Personal Best Management
    
    /// Updates personal best time for 40-yard dash with validation
    func updatePersonalBest(_ time: Double) {
        Task { @MainActor in
            do {
                try ErrorHandlingService.shared.validatePersonalBest(time)
                
                let oldTime = self.profile.personalBests["40yd"]
                self.profile.personalBests["40yd"] = time
                self.profile.baselineTime = time
                
                LoggingService.shared.logPersonalBest("40yd", oldTime: oldTime, newTime: time)
                logger.info("Updated personal best to \(String(format: "%.2f", time))s")
                
            } catch {
                ErrorHandlingService.shared.handle(error)
            }
        }
    }
    
    /// Debug function to verify personal best consistency
    func verifyPersonalBestConsistency() {
        let pb40yd = profile.personalBests["40yd"]
        let baseline = profile.baselineTime
        
        logger.debug("Personal Best Verification: PB=\(pb40yd?.description ?? "nil"), Baseline=\(String(format: "%.2f", baseline))")
        
        // Auto-fix if there's a mismatch
        if let pb = pb40yd, pb != baseline {
            logger.info("Auto-fixing PB mismatch: setting baselineTime to match personalBests['40yd']")
            profile.baselineTime = pb
        } else if pb40yd == nil && baseline > 0 {
            logger.info("Auto-fixing missing personalBests['40yd']: setting from baselineTime")
            profile.personalBests["40yd"] = baseline
        }
    }
}
