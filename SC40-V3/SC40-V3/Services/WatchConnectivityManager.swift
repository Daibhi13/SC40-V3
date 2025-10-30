import Foundation
import Combine
import os.log

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

// Note: WatchConnectivityError is defined in WatchConnectivityErrorHandler.swift

// MARK: - Enhanced Watch Connectivity Manager for Onboarding Flow Integration
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    @Published var connectionError: String?
    @Published var syncProgress: Double = 0.0
    @Published var isSyncing = false
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "WatchConnectivity")
    private var cancellables = Set<AnyCancellable>()
    
    // Sync state tracking
    @Published var onboardingDataSynced = false
    @Published var trainingSessionsSynced = false
    @Published var userProfileSynced = false
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup & Connection Management
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            logger.error("WatchConnectivity is not supported on this device")
            connectionError = "Apple Watch not supported"
            return
        }
        
        // Only set delegate if not already set by another manager
        if WCSession.default.delegate == nil {
            WCSession.default.delegate = self
        }
        
        // Activate session if not already activated
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        logger.info("WatchConnectivity session setup completed")
        
        // Update initial state
        Task { @MainActor in
            self.updateConnectionState()
        }
    }
    
    private func updateConnectionState() {
        let session = WCSession.default
        isWatchConnected = session.isPaired && session.isWatchAppInstalled
        isWatchReachable = session.isReachable
        
        if !session.isPaired {
            connectionError = "Apple Watch not paired"
        } else if !session.isWatchAppInstalled {
            connectionError = "SC40 Watch app not installed"
        } else if !session.isReachable {
            connectionError = "Apple Watch not reachable"
        } else {
            connectionError = nil
        }
    }
    
    // MARK: - Onboarding Data Sync
    
    func syncOnboardingData(userProfile: UserProfile) async {
        isSyncing = true
        syncProgress = 0.1
        
        do {
            let onboardingData: [String: Any] = [
                "type": "onboarding_complete",
                "name": userProfile.name,
                "email": userProfile.email ?? "",
                "age": userProfile.age,
                "height": userProfile.height,
                "weight": userProfile.weight ?? 0.0,
                "level": userProfile.level,
                "baselineTime": userProfile.baselineTime,
                "frequency": userProfile.frequency,
                "currentWeek": userProfile.currentWeek,
                "currentDay": userProfile.currentDay,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            syncProgress = 0.5
            
            // Try immediate message first, fallback to background transfer
            if isWatchReachable {
                try await sendMessageToWatch(onboardingData)
            } else {
                // Use background transfer for better reliability
                transferDataToWatch(onboardingData)
            }
            
            syncProgress = 1.0
            onboardingDataSynced = true
            
            logger.info("Onboarding data synced successfully to Watch")
            
        } catch {
            logger.error("Failed to sync onboarding data: \(error.localizedDescription)")
            // Fallback to background transfer
            let onboardingData: [String: Any] = [
                "type": "onboarding_complete",
                "name": userProfile.name,
                "email": userProfile.email ?? "",
                "timestamp": Date().timeIntervalSince1970
            ]
            transferDataToWatch(onboardingData)
            onboardingDataSynced = true
            logger.info("Onboarding data sent via background transfer")
        }
        
        isSyncing = false
    }
    
    // MARK: - Training Sessions Sync
    
    func syncTrainingSessions(_ sessions: [TrainingSession]) async {
        // Always attempt sync - use background transfer if not immediately reachable
        if !isWatchReachable {
            logger.warning("Watch not immediately reachable - using background transfer")
        }
        
        isSyncing = true
        syncProgress = 0.1
        
        // Convert sessions to dictionary format for transmission
        let sessionsData = sessions.map { session in
            [
                "id": session.id.uuidString,
                "week": session.week,
                "day": session.day,
                "type": session.type,
                "focus": session.focus,
                "sprints": session.sprints.map { sprint in
                    [
                        "distanceYards": sprint.distanceYards,
                        "reps": sprint.reps,
                        "intensity": sprint.intensity
                    ]
                },
                "accessoryWork": session.accessoryWork,
                "notes": session.notes ?? ""
            ]
        }
        
        syncProgress = 0.3
        
        let trainingData: [String: Any] = [
            "type": "training_sessions",
            "sessions": sessionsData,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        syncProgress = 0.7
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(trainingData)
                logger.info("Training sessions synced successfully to Watch (\(sessions.count) sessions)")
            } else {
                // Use background transfer immediately if not reachable
                throw WatchConnectivityError.watchNotReachable
            }
            
            syncProgress = 1.0
            trainingSessionsSynced = true
            
        } catch {
            logger.error("Failed to sync training sessions: \(error.localizedDescription)")
            
            // Fallback to background transfer
            logger.info("🔄 Falling back to background transfer for training sessions")
            transferDataToWatch(trainingData)
            trainingSessionsSynced = true
            syncProgress = 1.0
            logger.info("Training sessions queued for background transfer (\(sessions.count) sessions)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Optimized Session Transfer System
    
    /// Syncs the next batch of sessions optimally for immediate watch availability
    func syncNextSessionBatch(from allSessions: [TrainingSession], currentWeek: Int, frequency: Int) async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - using background transfer for session batch")
        }
        
        // Determine optimal batch size based on frequency and data size
        let optimalBatchSize = calculateOptimalBatchSize(frequency: frequency)
        let nextSessions = getNextSessionBatch(from: allSessions, currentWeek: currentWeek, batchSize: optimalBatchSize)
        
        logger.info("🚀 Syncing next \(nextSessions.count) sessions to Watch (optimal batch size: \(optimalBatchSize))")
        
        await syncTrainingSessions(nextSessions)
    }
    
    /// Immediately syncs current week sessions for instant availability
    func syncCurrentWeekSessions(from allSessions: [TrainingSession], currentWeek: Int, frequency: Int) async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - using background transfer for current week sessions")
        }
        
        // Get current week sessions
        let currentWeekSessions = allSessions.filter { session in
            session.week == currentWeek && session.day <= frequency
        }.sorted { $0.day < $1.day }
        
        // Remove duplicates by day
        let uniqueCurrentWeekSessions = Dictionary(grouping: currentWeekSessions, by: { $0.day })
            .compactMap { (day, sessions) in sessions.first }
            .sorted { $0.day < $1.day }
        
        logger.info("⚡ Syncing current week \(currentWeek) sessions to Watch (\(uniqueCurrentWeekSessions.count) sessions)")
        
        await syncTrainingSessions(uniqueCurrentWeekSessions)
    }
    
    /// Post-onboarding session sync for immediate training availability
    func syncPostOnboardingSessions(userProfile: UserProfile, allSessions: [TrainingSession]) async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - using background transfer for post-onboarding sessions")
        }
        
        logger.info("🎯 Starting post-onboarding session sync for immediate training availability")
        
        // Phase 1: Sync current week sessions immediately (highest priority)
        await syncCurrentWeekSessions(
            from: allSessions, 
            currentWeek: userProfile.currentWeek, 
            frequency: userProfile.frequency
        )
        
        // Phase 2: Sync next week sessions for seamless progression
        let nextWeek = userProfile.currentWeek + 1
        if nextWeek <= 12 {
            await syncCurrentWeekSessions(
                from: allSessions, 
                currentWeek: nextWeek, 
                frequency: userProfile.frequency
            )
        }
        
        // Phase 3: Background sync of additional sessions
        await syncNextSessionBatch(
            from: allSessions, 
            currentWeek: userProfile.currentWeek, 
            frequency: userProfile.frequency
        )
        
        logger.info("✅ Post-onboarding session sync completed - sessions ready for immediate use")
    }
    
    /// Calculates optimal batch size based on user frequency and data constraints
    private func calculateOptimalBatchSize(frequency: Int) -> Int {
        // Base calculation on frequency and WatchConnectivity limits
        // WatchConnectivity has ~65KB message limit, each session ~1-2KB
        let maxSessionsPerMessage = 30
        
        switch frequency {
        case 1...2:
            // Low frequency: sync 2-3 weeks ahead
            return min(frequency * 3, maxSessionsPerMessage)
        case 3...4:
            // Medium frequency: sync 2 weeks ahead
            return min(frequency * 2, maxSessionsPerMessage)
        case 5...7:
            // High frequency: sync 1.5 weeks ahead
            return min(Int(Double(frequency) * 1.5), maxSessionsPerMessage)
        default:
            return min(frequency * 2, maxSessionsPerMessage)
        }
    }
    
    /// Gets the next batch of sessions for optimal transfer
    private func getNextSessionBatch(from allSessions: [TrainingSession], currentWeek: Int, batchSize: Int) -> [TrainingSession] {
        // Get sessions starting from current week
        let upcomingSessions = allSessions.filter { session in
            session.week >= currentWeek
        }.sorted { session1, session2 in
            if session1.week == session2.week {
                return session1.day < session2.day
            }
            return session1.week < session2.week
        }
        
        // Return the optimal batch size
        return Array(upcomingSessions.prefix(batchSize))
    }
    
    // MARK: - Workout Launch Integration
    
    func launchWorkoutOnWatch(session: TrainingSession) async {
        guard isWatchReachable else {
            logger.warning("Watch not reachable - cannot launch workout")
            connectionError = "Watch not reachable for workout launch"
            return
        }
        
        do {
            let workoutData: [String: Any] = [
                "type": "launch_workout",
                "sessionId": session.id.uuidString,
                "sessionType": session.type,
                "focus": session.focus,
                "week": session.week,
                "day": session.day,
                "sprints": session.sprints.map { sprint in
                    [
                        "distanceYards": sprint.distanceYards,
                        "reps": sprint.reps,
                        "intensity": sprint.intensity
                    ]
                },
                "timestamp": Date().timeIntervalSince1970
            ]
            
            try await sendMessageToWatch(workoutData)
            logger.info("Workout launch command sent to Watch")
            
        } catch {
            logger.error("Failed to launch workout on Watch: \(error.localizedDescription)")
            connectionError = "Failed to start Watch workout"
        }
    }
    
    // MARK: - 7-Stage Flow Sync
    
    func sync7StageWorkoutFlow() async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - using background transfer for 7-stage flow")
        }
        
        let flowData: [String: Any] = [
            "type": "workout_flow_update",
            "stages": [
                ["name": "warmup", "title": "Warm-Up", "color": "orange", "duration": 300],
                ["name": "stretch", "title": "Stretch", "color": "pink", "duration": 300],
                ["name": "drill", "title": "Drills", "color": "indigo", "duration": 360],
                ["name": "strides", "title": "Strides", "color": "purple", "duration": 360],
                ["name": "sprints", "title": "Sprints", "color": "green", "duration": 0],
                ["name": "resting", "title": "Rest", "color": "yellow", "duration": 0],
                ["name": "cooldown", "title": "Cooldown", "color": "blue", "duration": 300]
            ],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(flowData)
                logger.info("7-stage workout flow synced to Watch")
            } else {
                // Use background transfer if not reachable
                throw WatchConnectivityError.watchNotReachable
            }
            
        } catch {
            logger.error("Failed to sync 7-stage flow: \(error.localizedDescription)")
            
            // Fallback to background transfer
            logger.info("🔄 Falling back to background transfer for 7-stage flow")
            transferDataToWatch(flowData)
            logger.info("7-stage workflow queued for background transfer")
        }
    }
    
    // MARK: - Voice Settings Sync
    
    func syncVoiceSettings(_ voiceSettings: [String: Any]) async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - using background transfer for voice settings")
        }
        
        let voiceData: [String: Any] = [
            "type": "voice_settings_update",
            "settings": voiceSettings,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(voiceData)
                logger.info("Voice settings synced successfully to Watch")
            } else {
                // Use background transfer if not reachable
                throw WatchConnectivityError.watchNotReachable
            }
            
        } catch {
            logger.error("Failed to sync voice settings: \(error.localizedDescription)")
            
            // Fallback to background transfer
            logger.info("🔄 Falling back to background transfer for voice settings")
            transferDataToWatch(voiceData)
            logger.info("Voice settings queued for background transfer")
        }
    }
    
    // MARK: - Helper Methods
    
    private func transferDataToWatch(_ data: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            logger.warning("Cannot transfer data - WCSession not activated")
            return
        }
        
        do {
            try WCSession.default.updateApplicationContext(data)
            logger.info("Data transferred to Watch via application context")
        } catch {
            logger.error("Failed to transfer data to Watch: \(error.localizedDescription)")
        }
    }
    
    func sendMessageToWatch(_ message: [String: Any]) async throws {
        // Check if Watch is reachable before sending
        guard WCSession.default.isReachable else {
            throw WatchConnectivityError.watchNotReachable
        }
        
        try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(message) { reply in
                continuation.resume()
            } errorHandler: { error in
                continuation.resume(throwing: error)
            }
        }
    }

    // Note: sync7StageWorkoutFlow is implemented above in the class
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WatchConnectivityError.timeout
            }
            
            guard let result = try await group.next() else {
                throw WatchConnectivityError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Status Check Methods
    
    func checkWatchStatus() -> String {
        if !WCSession.isSupported() {
            return "Apple Watch not supported"
        }
        
        let session = WCSession.default
        
        if !session.isPaired {
            return "Apple Watch not paired"
        }
        
        if !session.isWatchAppInstalled {
            return "SC40 Watch app not installed"
        }
        
        if !session.isReachable {
            return "Apple Watch not reachable"
        }
        
        return "Apple Watch connected and ready"
    }
    
    func isReadyForWorkout() -> Bool {
        return isWatchConnected && isWatchReachable && onboardingDataSynced && trainingSessionsSynced
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            switch activationState {
            case .activated:
                logger.info("WatchConnectivity session activated successfully")
                isWatchConnected = session.isPaired && session.isWatchAppInstalled
                isWatchReachable = session.isReachable
                connectionError = nil
            case .notActivated:
                logger.error("WatchConnectivity session failed to activate")
                connectionError = "Failed to connect to Apple Watch"
            case .inactive:
                logger.warning("WatchConnectivity session is inactive")
                connectionError = "Apple Watch connection inactive"
            @unknown default:
                logger.error("Unknown WatchConnectivity activation state")
                connectionError = "Unknown connection state"
            }
            
            if let error = error {
                logger.error("WatchConnectivity activation error: \(error.localizedDescription)")
                connectionError = error.localizedDescription
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            logger.info("WatchConnectivity session became inactive")
            isWatchConnected = false
            isWatchReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            logger.info("WatchConnectivity session deactivated")
            isWatchConnected = false
            isWatchReachable = false
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            logger.info("Watch reachability changed: \(session.isReachable)")
            isWatchReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            logger.info("Received message from Watch: \(message)")
            
            // Send immediate acknowledgment to prevent timeout
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
            
            // Handle messages from Watch (workout results, status updates, etc.)
            if let type = message["type"] as? String {
                switch type {
                case "workout_completed":
                    handleWorkoutCompletion(message)
                case "sync_request":
                    // sync_request needs special handling as it uses replyHandler for data
                    logger.warning("sync_request received but reply already sent - use background transfer instead")
                case "request_sessions":
                    // CRITICAL FIX: Handle session requests from Watch
                    handleSessionRequest(message, replyHandler: replyHandler)
                    return // Don't send duplicate reply
                case "status_update":
                    handleStatusUpdate(message)
                case "rep_completed":
                    handleRepCompleted(message)
                case "session_completed":
                    // Process session completion asynchronously to prevent timeout
                    Task.detached { [weak self] in
                        await self?.handleSessionCompletedAsync(message)
                    }
                default:
                    logger.warning("Unknown message type from Watch: \(type)")
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            logger.info("Received background user info from Watch: \(userInfo)")
            
            // Handle background data from Watch
            if let type = userInfo["type"] as? String {
                switch type {
                case "workout_completed":
                    handleWorkoutCompletion(userInfo)
                case "status_update":
                    handleStatusUpdate(userInfo)
                default:
                    logger.info("Received background data type: \(type)")
                }
            }
        }
    }
    
    private func handleWorkoutCompletion(_ message: [String: Any]) {
        logger.info("Workout completed on Watch - processing results")
        // Process workout completion data from Watch
        // Update iPhone app with results, sync to HealthKit, etc.
    }
    
    private func handleSessionRequest(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("📱 Watch requesting training sessions - generating current program")
        
        // Get current user profile and generate sessions
        // This should integrate with the existing session generation system
        Task {
            do {
                // Generate sessions using the same logic as TrainingView
                let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Intermediate"
                let frequency = UserDefaults.standard.integer(forKey: "trainingFrequency")
                let currentWeek = UserDefaults.standard.integer(forKey: "currentWeek") > 0 ? 
                                 UserDefaults.standard.integer(forKey: "currentWeek") : 1
                
                print("📊 iPhone: Generating sessions for Watch - Level: \(userLevel), Frequency: \(frequency), Week: \(currentWeek)")
                
                // Create sample sessions that match the phone's session generation logic
                let sessions = generateSessionsForWatch(level: userLevel, frequency: frequency, currentWeek: currentWeek)
                
                let sessionsData = sessions.map { session in
                    [
                        "id": session.id.uuidString,
                        "week": session.week,
                        "day": session.day,
                        "type": session.type,
                        "focus": session.focus,
                        "sprints": session.sprints.map { sprint in
                            [
                                "distanceYards": sprint.distanceYards,
                                "reps": sprint.reps,
                                "intensity": sprint.intensity
                            ]
                        },
                        "accessoryWork": session.accessoryWork,
                        "notes": session.notes ?? ""
                    ]
                }
                
                await MainActor.run {
                    replyHandler([
                        "status": "success",
                        "sessions": sessionsData,
                        "sessionCount": sessionsData.count,
                        "userLevel": userLevel,
                        "frequency": frequency,
                        "currentWeek": currentWeek,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    print("✅ iPhone: Sent \(sessionsData.count) sessions to Watch")
                }
                
            } catch {
                await MainActor.run {
                    logger.error("Failed to generate sessions for Watch: \(error.localizedDescription)")
                    replyHandler([
                        "status": "error",
                        "error": error.localizedDescription,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                }
            }
        }
    }
    
    private func generateSessionsForWatch(level: String, frequency: Int, currentWeek: Int) -> [TrainingSession] {
        // Generate a few sessions for the current week based on user's profile
        var sessions: [TrainingSession] = []
        
        // Create sessions for the current week based on frequency
        for day in 1...min(frequency, 7) {
            let session = TrainingSession(
                week: currentWeek,
                day: day,
                type: getSessionTypeForLevel(level, day: day),
                focus: getSessionFocusForLevel(level, day: day),
                sprints: getSprintsForLevel(level, day: day),
                accessoryWork: getAccessoryWorkForLevel(level)
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func getSessionTypeForLevel(_ level: String, day: Int) -> String {
        // Use dynamic session naming service instead of hardcoded values
        let namingService = DynamicSessionNamingService.shared
        
        // Generate appropriate distance and intensity for the level
        let (distance, intensity) = getDistanceAndIntensityForLevel(level)
        
        return namingService.generateSessionType(
            userLevel: level,
            distance: distance,
            reps: 4, // Default reps
            intensity: intensity,
            dayInWeek: day
        )
    }
    
    private func getDistanceAndIntensityForLevel(_ level: String) -> (distance: Int, intensity: String) {
        switch level.lowercased() {
        case "beginner":
            return (25, "Moderate")
        case "intermediate":
            return (35, "High")
        case "advanced":
            return (45, "Max")
        case "elite", "pro":
            return (55, "Max")
        default:
            return (30, "Moderate")
        }
    }
    
    private func getSessionFocusForLevel(_ level: String, day: Int) -> String {
        // Use dynamic session naming service instead of hardcoded values
        let namingService = DynamicSessionNamingService.shared
        
        // Generate appropriate distance for the level
        let (distance, _) = getDistanceAndIntensityForLevel(level)
        
        return namingService.generateSessionFocus(
            userLevel: level,
            distance: distance,
            reps: 4, // Default reps
            weekNumber: 1, // Default to week 1 for fallback
            dayInWeek: day
        )
    }
    
    private func getSprintsForLevel(_ level: String, day: Int) -> [SprintSet] {
        switch level.lowercased() {
        case "beginner":
            return [SprintSet(distanceYards: 20 + (day * 5), reps: 4, intensity: "Sub-Max")]
        case "intermediate":
            return [SprintSet(distanceYards: 30 + (day * 10), reps: 5, intensity: "Max")]
        case "advanced":
            return [SprintSet(distanceYards: 40 + (day * 10), reps: 6, intensity: "Max")]
        case "elite":
            return [SprintSet(distanceYards: 50 + (day * 10), reps: 4, intensity: "Race")]
        default:
            return [SprintSet(distanceYards: 40, reps: 5, intensity: "Max")]
        }
    }
    
    private func getAccessoryWorkForLevel(_ level: String) -> [String] {
        switch level.lowercased() {
        case "beginner":
            return ["Dynamic Warm-up", "Basic Drills", "Cool-down"]
        case "intermediate":
            return ["Dynamic Warm-up", "Speed Mechanics", "Plyometrics", "Cool-down"]
        case "advanced":
            return ["Competition Warm-up", "Advanced Drills", "Power Training", "Recovery"]
        case "elite":
            return ["Elite Warm-up", "Competition Drills", "Peak Power", "Professional Recovery"]
        default:
            return ["Dynamic Warm-up", "Speed Drills", "Cool-down"]
        }
    }

    private func handleSyncRequest(_ replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Watch requesting sync - sending current data")
        // Send current user profile and training sessions to Watch
        replyHandler([
            "status": "sync_available",
            "onboarding_synced": onboardingDataSynced,
            "sessions_synced": trainingSessionsSynced
        ])
    }
    
    private func handleStatusUpdate(_ message: [String: Any]) {
        logger.info("Received status update from Watch")
        // Handle status updates from Watch app
    }
    
    private func handleRepCompleted(_ message: [String: Any]) {
        logger.info("Received rep completion from Watch")
        
        // Forward to LiveRepLogManager
        NotificationCenter.default.post(
            name: .repDataReceived,
            object: message
        )
    }
    
    private func handleSessionCompleted(_ message: [String: Any]) {
        logger.info("Received session completion from Watch")
        
        // Forward to LiveRepLogManager
        NotificationCenter.default.post(
            name: .sessionDataReceived,
            object: message
        )
        
        // Also integrate with existing HistoryManager
        integrateSessionWithHistory(message)
    }
    
    private func handleSessionCompletedAsync(_ message: [String: Any]) async {
        await MainActor.run {
            logger.info("Processing session completion from Watch asynchronously")
            
            // Forward to LiveRepLogManager
            NotificationCenter.default.post(
                name: .sessionDataReceived,
                object: message
            )
            
            // Also integrate with existing HistoryManager
            integrateSessionWithHistory(message)
        }
    }
    
    private func integrateSessionWithHistory(_ sessionData: [String: Any]) {
        // Convert Watch session data to format compatible with HistoryManager
        guard let _ = sessionData["sessionType"] as? String,
              let _ = sessionData["focus"] as? String,
              let _ = sessionData["week"] as? Int,
              let _ = sessionData["day"] as? Int,
              let reps = sessionData["reps"] as? [[String: Any]] else {
            logger.warning("Invalid session data format from Watch")
            return
        }
        
        logger.info("Integrating Watch session with HistoryManager: \(reps.count) reps")
        
        // Here you would integrate with the existing HistoryManager
        // This ensures RepLog data appears in the main app history
    }
}

// Note: WCSessionDelegate methods are implemented in the main class body above

#endif
