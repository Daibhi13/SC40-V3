import Foundation
import Combine
import os.log

// MARK: - Training Synchronization Manager
// Implements the Core UI/UX Synchronization Logic as specified:
// - 4 Levels × 7 Days = 28 Combinations
// - Real-time cross-device synchronization
// - Compilation_ID → Session_Model binding
// - Seamless anonymous → active user transition

@MainActor
class TrainingSynchronizationManager: ObservableObject {
    static let shared = TrainingSynchronizationManager()
    
    // MARK: - Published State
    @Published var currentCompilationID: String?
    @Published var selectedLevel: TrainingLevel = .beginner
    @Published var selectedDays: Int = 3
    @Published var activeSessions: [TrainingSession] = []
    @Published var sessionProgress: [String: SessionProgress] = [:]
    @Published var isSyncing = false
    @Published var syncError: String?
    
    // MARK: - Synchronization State
    @Published var isPhoneSynced = true  // Phone is always synced (source of truth)
    @Published var isWatchSynced = false
    @Published var lastSyncTimestamp: Date?
    
    internal let logger = Logger(subsystem: "com.accelerate.sc40", category: "TrainingSynchronization")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Training Combinations (4 Levels × 7 Days = 28 Total)
    internal let supportedLevels: [TrainingLevel] = [.beginner, .intermediate, .advanced, .pro]
    internal let supportedDays: [Int] = [1, 2, 3, 4, 5, 6, 7]
    
    private init() {
        setupSynchronization()
    }
    
    // MARK: - Core Synchronization Logic
    
    /// Generates unique Compilation ID for Level × Days combination
    func generateCompilationID(level: TrainingLevel, days: Int) -> String {
        return "SC40_\(level.rawValue.uppercased())_\(days)DAYS_\(UUID().uuidString.prefix(8))"
    }
    
    /// Main synchronization trigger - called when user selects Level × Days
    func synchronizeTrainingProgram(level: TrainingLevel, days: Int) async {
        logger.info("🔄 Starting synchronization for \(level.rawValue) × \(days) days")
        
        isSyncing = true
        syncError = nil
        
        do {
            // 1. Generate new Compilation ID
            let compilationID = generateCompilationID(level: level, days: days)
            
            // 2. Update local state
            await updateLocalState(compilationID: compilationID, level: level, days: days)
            
            // 3. Generate session model for this combination
            let sessions = await generateSessionModel(level: level, days: days)
            
            // 4. Update UI state on phone
            await updatePhoneUI(sessions: sessions)
            
            // 5. Sync to watch within seconds
            await syncToWatch(compilationID: compilationID, sessions: sessions)
            
            // 6. Transition from anonymous to active user view
            await transitionToActiveUserView()
            
            logger.info("✅ Synchronization completed successfully")
            
        } catch {
            logger.error("❌ Synchronization failed: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    // MARK: - Session Model Generation
    
    /// Generates training sessions based on Level × Days combination using UnifiedSessionGenerator
    internal func generateSessionModel(level: TrainingLevel, days: Int) async -> [TrainingSession] {
        logger.info("📊 Generating session model for \(level.rawValue) × \(days) days using UnifiedSessionGenerator")
        
        // Use UnifiedSessionGenerator to ensure iPhone/Watch synchronization
        let unifiedGenerator = UnifiedSessionGenerator.shared
        let sessions = unifiedGenerator.generateUnified12WeekProgram(
            userLevel: level.rawValue,
            frequency: days,
            userPreferences: nil
        )
        
        logger.info("📈 Generated \(sessions.count) sessions (\(12) weeks × \(days) days) via UnifiedSessionGenerator")
        logger.info("🔄 Sessions will match Watch exactly for W1/D1 through W12/D\(days)")
        
        return sessions
    }
    
    /// Creates individual training session based on parameters
    private func createTrainingSession(week: Int, day: Int, level: TrainingLevel, totalDaysPerWeek: Int) -> TrainingSession {
        let sessionType = determineSessionType(day: day, totalDays: totalDaysPerWeek, level: level)
        let intensity = determineIntensity(week: week, level: level)
        let sprints = generateSprintsForSession(type: sessionType, intensity: intensity, level: level)
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: week, day: day),
            week: week,
            day: day,
            type: sessionType,
            focus: determineFocus(type: sessionType, level: level),
            sprints: sprints,
            accessoryWork: generateAccessoryWork(level: level),
            notes: generateSessionNotes(week: week, day: day, level: level)
        )
    }
    
    // MARK: - Session Configuration Logic
    
    private func determineSessionType(day: Int, totalDays: Int, level: TrainingLevel) -> String {
        let sessionTypes: [String]
        
        switch totalDays {
        case 1:
            sessionTypes = ["Full Sprint Workout"]
        case 2:
            sessionTypes = ["Speed & Acceleration", "Max Velocity & Recovery"]
        case 3:
            sessionTypes = ["Acceleration", "Speed Endurance", "Max Velocity"]
        case 4:
            sessionTypes = ["Acceleration", "Speed Development", "Max Velocity", "Recovery & Technique"]
        case 5:
            sessionTypes = ["Acceleration", "Speed Development", "Max Velocity", "Speed Endurance", "Recovery"]
        case 6:
            sessionTypes = ["Acceleration", "Speed Development", "Max Velocity", "Speed Endurance", "Technique", "Recovery"]
        case 7:
            sessionTypes = ["Acceleration", "Speed Development", "Max Velocity", "Speed Endurance", "Technique", "Recovery", "Active Rest"]
        default:
            sessionTypes = ["General Sprint Training"]
        }
        
        return sessionTypes[(day - 1) % sessionTypes.count]
    }
    
    private func determineIntensity(week: Int, level: TrainingLevel) -> String {
        let baseIntensity: String
        
        switch level {
        case .beginner:
            baseIntensity = week <= 4 ? "moderate" : week <= 8 ? "submax" : "max"
        case .intermediate:
            baseIntensity = week <= 2 ? "moderate" : week <= 6 ? "submax" : "max"
        case .advanced:
            baseIntensity = week <= 2 ? "submax" : "max"
        case .pro:
            baseIntensity = "max"
        }
        
        // Taper in final weeks
        return week >= 11 ? "submax" : baseIntensity
    }
    
    private func generateSprintsForSession(type: String, intensity: String, level: TrainingLevel) -> [SprintSet] {
        var sprints: [SprintSet] = []
        
        // Warm-up (consistent across all sessions)
        sprints.append(SprintSet(distanceYards: 400, reps: 1, intensity: "warm-up"))
        
        // Main work based on session type and level
        switch type {
        case "Acceleration":
            sprints.append(SprintSet(distanceYards: 10, reps: level == .beginner ? 4 : 6, intensity: intensity))
            sprints.append(SprintSet(distanceYards: 20, reps: level == .beginner ? 3 : 4, intensity: intensity))
            
        case "Speed Development", "Speed & Acceleration":
            sprints.append(SprintSet(distanceYards: 30, reps: level == .beginner ? 3 : 4, intensity: intensity))
            sprints.append(SprintSet(distanceYards: 40, reps: level == .beginner ? 2 : 3, intensity: intensity))
            
        case "Max Velocity", "Max Velocity & Recovery":
            sprints.append(SprintSet(distanceYards: 40, reps: level == .beginner ? 3 : 4, intensity: intensity))
            sprints.append(SprintSet(distanceYards: 60, reps: level == .beginner ? 2 : 3, intensity: intensity))
            
        case "Speed Endurance":
            sprints.append(SprintSet(distanceYards: 80, reps: level == .beginner ? 2 : 3, intensity: intensity))
            sprints.append(SprintSet(distanceYards: 100, reps: level == .beginner ? 1 : 2, intensity: intensity))
            
        case "Full Sprint Workout":
            sprints.append(SprintSet(distanceYards: 20, reps: 3, intensity: intensity))
            sprints.append(SprintSet(distanceYards: 40, reps: 3, intensity: intensity))
            sprints.append(SprintSet(distanceYards: 60, reps: 2, intensity: intensity))
            
        default: // Recovery, Technique, Active Rest
            sprints.append(SprintSet(distanceYards: 20, reps: 4, intensity: "easy"))
            sprints.append(SprintSet(distanceYards: 30, reps: 2, intensity: "moderate"))
        }
        
        // Cool-down
        sprints.append(SprintSet(distanceYards: 400, reps: 1, intensity: "cool-down"))
        
        return sprints
    }
    
    private func determineFocus(type: String, level: TrainingLevel) -> String {
        switch type {
        case "Acceleration": return "Block starts and first 20 yards"
        case "Speed Development": return "Transition to max velocity"
        case "Max Velocity": return "Top speed mechanics"
        case "Speed Endurance": return "Maintaining speed over distance"
        case "Recovery": return "Active recovery and technique"
        case "Technique": return "Form and mechanics refinement"
        default: return "General sprint development"
        }
    }
    
    private func generateAccessoryWork(level: TrainingLevel) -> [String] {
        let baseWork = ["Dynamic warm-up", "Cool-down stretching"]
        
        switch level {
        case .beginner:
            return baseWork + ["Basic core strengthening"]
        case .intermediate:
            return baseWork + ["Core strengthening", "Plyometric drills"]
        case .advanced:
            return baseWork + ["Advanced core work", "Plyometrics", "Strength training"]
        case .pro:
            return baseWork + ["Elite core training", "Advanced plyometrics", "Strength training", "Recovery protocols"]
        }
    }
    
    private func generateSessionNotes(week: Int, day: Int, level: TrainingLevel) -> String {
        return "Week \(week), Day \(day) - \(level.label) level training. Focus on quality over quantity."
    }
    
    // MARK: - State Management
    
    private func updateLocalState(compilationID: String, level: TrainingLevel, days: Int) async {
        self.currentCompilationID = compilationID
        self.selectedLevel = level
        self.selectedDays = days
        self.lastSyncTimestamp = Date()
        
        logger.info("📱 Updated local state - Compilation ID: \(compilationID)")
    }
    
    private func updatePhoneUI(sessions: [TrainingSession]) async {
        self.activeSessions = sessions
        self.isPhoneSynced = true
        
        // Initialize session progress
        var progress: [String: SessionProgress] = [:]
        for session in sessions {
            progress[session.id.uuidString] = SessionProgress(
                isLocked: session.week > 1 || session.day > 1, // First session unlocked
                isCompleted: false,
                completionPercentage: 0.0
            )
        }
        self.sessionProgress = progress
        
        logger.info("📱 Updated phone UI with \(sessions.count) sessions")
    }
    
    private func syncToWatch(compilationID: String, sessions: [TrainingSession]) async {
        guard let watchManager = WatchConnectivityManager.shared as? WatchConnectivityManager else {
            logger.warning("⌚ Watch connectivity manager not available")
            return
        }
        
        do {
            // Send compilation data to watch
            let syncData: [String: Any] = [
                "type": "training_sync",
                "compilationID": compilationID,
                "level": selectedLevel.rawValue,
                "days": selectedDays,
                "sessionCount": sessions.count,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // Send sessions in batches for reliability
            let batchSize = 10
            for i in stride(from: 0, to: sessions.count, by: batchSize) {
                let endIndex = min(i + batchSize, sessions.count)
                let batch = Array(sessions[i..<endIndex])
                
                await watchManager.syncTrainingSessions(batch)
            }
            
            self.isWatchSynced = true
            logger.info("⌚ Successfully synced to watch - \(sessions.count) sessions")
            
        } catch {
            logger.error("⌚ Watch sync failed: \(error.localizedDescription)")
            self.isWatchSynced = false
        }
    }
    
    private func transitionToActiveUserView() async {
        // Trigger UI transition from anonymous to active user
        NotificationCenter.default.post(
            name: NSNotification.Name("TrainingProgramActivated"),
            object: nil,
            userInfo: [
                "compilationID": currentCompilationID ?? "",
                "level": selectedLevel.rawValue,
                "days": selectedDays
            ]
        )
        
        logger.info("🎯 Transitioned to active user view")
    }
    
    // MARK: - Session Progress Management
    
    func updateSessionProgress(sessionID: String, progress: SessionProgress) async {
        sessionProgress[sessionID] = progress
        
        // Unlock next session if current is completed
        if progress.isCompleted {
            await unlockNextSession(after: sessionID)
        }
        
        // Sync progress to watch
        await syncProgressToWatch(sessionID: sessionID, progress: progress)
    }
    
    private func unlockNextSession(after sessionID: String) async {
        guard let currentSession = activeSessions.first(where: { $0.id.uuidString == sessionID }) else { return }
        
        // Find next session (next day or next week)
        let nextSession = activeSessions.first { session in
            (session.week == currentSession.week && session.day == currentSession.day + 1) ||
            (session.week == currentSession.week + 1 && session.day == 1)
        }
        
        if let nextSession = nextSession {
            sessionProgress[nextSession.id.uuidString]?.isLocked = false
            logger.info("🔓 Unlocked next session: Week \(nextSession.week), Day \(nextSession.day)")
        }
    }
    
    private func syncProgressToWatch(sessionID: String, progress: SessionProgress) async {
        // Implementation for syncing progress updates to watch
        let progressData: [String: Any] = [
            "type": "progress_update",
            "sessionID": sessionID,
            "isCompleted": progress.isCompleted,
            "completionPercentage": progress.completionPercentage,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Send to watch via WatchConnectivityManager
        // Implementation depends on watch connectivity setup
    }
    
    // MARK: - Setup
    
    private func setupSynchronization() {
        logger.info("🚀 Training Synchronization Manager initialized")
        logger.info("📊 Supporting \(self.supportedLevels.count) levels × \(self.supportedDays.count) days = \(self.supportedLevels.count * self.supportedDays.count) combinations")
    }
}

// MARK: - Supporting Types

struct SessionProgress: Codable {
    var isLocked: Bool
    var isCompleted: Bool
    var completionPercentage: Double
    var lastUpdated: Date = Date()
}

// MARK: - TrainingLevel Extension for Elite Support

extension TrainingLevel {
    static var elite: TrainingLevel { .pro } // Map Elite to Pro for compatibility
}
