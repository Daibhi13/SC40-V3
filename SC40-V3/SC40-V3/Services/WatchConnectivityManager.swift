import Foundation
import Combine
import os.log

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

// Note: WatchConnectivityError is defined in WatchConnectivityErrorHandler.swift

// Note: DataPersistenceManager is defined in DataPersistenceManager.swift

// MARK: - Enhanced Watch Connectivity Manager for Onboarding Flow Integration
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    private let logger = Logger(subsystem: "com.sc40.app", category: "WatchConnectivity")
    
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    @Published var onboardingDataSynced = false
    @Published var trainingSessionsSynced = false
    @Published var userProfileSynced = false
    @Published var connectionError: String?
    @Published var syncProgress: Double = 0.0
    @Published var isSyncing = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            logger.warning("WatchConnectivity not supported on this device")
            return
        }
        
        // CRASH PROTECTION: Ensure application context is available
        initializeApplicationContextIfNeeded()
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
        
        logger.info("WatchConnectivity setup initiated with application context protection")
    }
    
    // MARK: - Application Context Protection
    
    private func initializeApplicationContextIfNeeded() {
        // Ensure DataPersistenceManager is available
        let context = DataPersistenceManager.shared.getApplicationContext()
        
        // Send initial application context to prevent nil context errors
        if WCSession.default.activationState == .activated {
            do {
                try WCSession.default.updateApplicationContext(context)
                logger.info("✅ Initial application context sent to Watch")
            } catch {
                logger.warning("⚠️ Could not send initial application context: \(error)")
            }
        } else {
            // Store context to send once session activates
            logger.info("📝 Application context ready for when session activates")
        }
    }
    
    private func sendInitialApplicationContext() {
        logger.info("📤 Sending initial application context after session activation")
        
        let context = DataPersistenceManager.shared.getApplicationContext()
        
        do {
            try WCSession.default.updateApplicationContext(context)
            logger.info("✅ Initial application context sent successfully after activation")
        } catch {
            logger.error("❌ Failed to send initial application context after activation: \(error)")
        }
    }
    
    // MARK: - Onboarding Data Sync
    
    @MainActor
    func syncOnboardingData(userProfile: UserProfile) async {
        logger.info("🔄 Starting onboarding data sync to Watch")
        
        // Prevent concurrent sync operations
        guard !isSyncing else {
            logger.warning("⚠️ Sync already in progress, skipping duplicate request")
            return
        }
        
        isSyncing = true
        syncProgress = 0.1
        
        do {
            // Ensure all string values are properly sanitized
            let sanitizedName = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let sanitizedLevel = userProfile.level.trimmingCharacters(in: .whitespacesAndNewlines)
            let sanitizedEmail = (userProfile.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate all required fields before creating data dictionary
            guard !sanitizedName.isEmpty, !sanitizedLevel.isEmpty else {
                logger.error("Cannot sync onboarding data - missing required fields")
                syncProgress = 0.0
                isSyncing = false
                return
            }
            
            let onboardingData: [String: Any] = [
                "type": "onboarding_complete",
                "name": sanitizedName,
                "email": sanitizedEmail,
                "age": userProfile.age,
                "height": userProfile.height,
                "weight": userProfile.weight ?? 0.0,
                "level": sanitizedLevel,
                "baselineTime": userProfile.baselineTime,
                "frequency": userProfile.frequency,
                "currentWeek": userProfile.currentWeek,
                "currentDay": userProfile.currentDay,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // Debug: Log the data being sent
            print("📤 Sending onboarding data to watch:")
            print("   Name: '\(sanitizedName)'")
            print("   Level: '\(sanitizedLevel)'")
            print("   Frequency: \(userProfile.frequency)")
            print("   BaselineTime: \(userProfile.baselineTime)")
            print("   CurrentWeek: \(userProfile.currentWeek)")
            print("   CurrentDay: \(userProfile.currentDay)")
            
            syncProgress = 0.5
            
            // Try immediate message first, fallback to background transfer
            if isWatchReachable {
                try await sendMessageToWatch(onboardingData)
                logger.info("Onboarding data synced successfully to Watch")
            } else {
                // Use background transfer immediately if not reachable
                throw WatchConnectivityError.watchNotReachable
            }
            
            syncProgress = 1.0
            onboardingDataSynced = true
            
        } catch {
            logger.error("Failed to sync onboarding data: \(error.localizedDescription)")
            
            // Fallback to background transfer
            logger.info("🔄 Falling back to background transfer for onboarding data")
            let fallbackData: [String: Any] = [
                "type": "onboarding_complete",
                "name": userProfile.name,
                "level": userProfile.level,
                "frequency": userProfile.frequency,
                "currentWeek": userProfile.currentWeek,
                "currentDay": userProfile.currentDay,
                "timestamp": Date().timeIntervalSince1970
            ]
            transferDataToWatch(fallbackData)
            onboardingDataSynced = true
            logger.info("Onboarding data queued for background transfer")
        }
        
        isSyncing = false
        
        // ✅ CRITICAL FIX: Update application context after onboarding sync
        await updateProfileContext(userProfile)
    }
    
    /// Update application context with current user profile
    @MainActor
    func updateProfileContext(_ userProfile: UserProfile) async {
        logger.info("📤 Updating application context with user profile")
        
        let context = DataPersistenceManager.shared.getApplicationContext()
        
        guard WCSession.default.activationState == .activated else {
            logger.warning("⚠️ WCSession not activated - context will be sent when ready")
            return
        }
        
        do {
            try WCSession.default.updateApplicationContext(context)
            logger.info("✅ Application context updated with profile: \(userProfile.name), PB: \(userProfile.baselineTime)s")
            print("📤 Sent profile data to Watch via application context")
        } catch {
            logger.error("❌ Failed to update application context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Training Sessions Sync
    
    /// Sync training sessions using incremental transfer to prevent crashes
    @MainActor
    func syncTrainingSessions(_ sessions: [TrainingSession]) async {
        // Prevent concurrent sync operations
        guard !isSyncing else {
            logger.warning("⚠️ Training sync already in progress, skipping duplicate request")
            return
        }
        
        // Always attempt sync - use background transfer if not immediately reachable
        if !isWatchReachable {
            logger.warning("Watch not immediately reachable - using background transfer")
        }
        
        isSyncing = true
        syncProgress = 0.1
        
        // Convert sessions to dictionary format for transmission
        let sessionsData = sessions.compactMap { session -> [String: Any]? in
            return [
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
        
        let trainingData: [String: Any] = [
            "type": "training_sessions",
            "sessions": sessionsData,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        syncProgress = 0.7
        
        do {
            if isWatchReachable {
                // INCREMENTAL TRANSFER: Send sessions in small batches to prevent crashes
                await sendSessionsIncrementally(sessions)
                logger.info("Training sessions synced incrementally to Watch (\(sessions.count) sessions)")
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
            logger.info("Training sessions queued for background transfer (\(sessions.count) sessions)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Helper Methods
    
    private func transferDataToWatch(_ data: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            logger.warning("Cannot transfer data - WCSession not activated")
            return
        }
        
        // Validate data before sending - remove nil values
        let cleanedData = data.compactMapValues { value -> Any? in
            // Remove nil values and ensure all values are valid for WatchConnectivity
            if let stringValue = value as? String, !stringValue.isEmpty {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue
            } else if let boolValue = value as? Bool {
                return boolValue
            } else if let arrayValue = value as? [Any] {
                return arrayValue
            } else if let dictValue = value as? [String: Any] {
                return dictValue
            } else if let dataValue = value as? Data {
                return dataValue
            }
            return nil
        }
        
        logger.info("📦 Transferring data to Watch via background transfer (\(cleanedData.count) keys)")
        
        // Use background transfer for reliability
        WCSession.default.transferUserInfo(cleanedData)
    }
    
    func sendMessageToWatch(_ message: [String: Any]) async throws {
        // Check if Watch is reachable before sending
        guard WCSession.default.isReachable else {
            throw WatchConnectivityError.watchNotReachable
        }
        
        // Add timeout protection to prevent hanging
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    WCSession.default.sendMessage(message) { reply in
                        continuation.resume()
                    } errorHandler: { error in
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                throw WatchConnectivityError.messageTimeout
            }
            
            try await group.next()
            group.cancelAll()
        }
    }
    
    // MARK: - Incremental Data Transfer
    
    /// Send sessions in small batches to prevent WatchConnectivity crashes
    private func sendSessionsIncrementally(_ sessions: [TrainingSession]) async {
        let maxBatchSize = 3  // Small batches to stay under WC limits
        let totalBatches = (sessions.count + maxBatchSize - 1) / maxBatchSize
        
        logger.info("📦 Starting incremental transfer: \(sessions.count) sessions in \(totalBatches) batches")
        
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * maxBatchSize
            let endIndex = min(startIndex + maxBatchSize, sessions.count)
            let batch = Array(sessions[startIndex..<endIndex])
            
            // Convert batch to dictionary format
            let batchData = batch.compactMap { session -> [String: Any]? in
                return [
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
            
            let batchMessage: [String: Any] = [
                "type": "training_sessions_batch",
                "batchIndex": batchIndex,
                "totalBatches": totalBatches,
                "sessions": batchData,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            do {
                try await sendMessageToWatch(batchMessage)
                logger.info("✅ Batch \(batchIndex + 1)/\(totalBatches) sent successfully (\(batch.count) sessions)")
                
                // Small delay between batches to prevent overwhelming the watch
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                logger.error("❌ Batch \(batchIndex + 1) failed: \(error.localizedDescription)")
                // Try background transfer for failed batch
                transferDataToWatch(batchMessage)
            }
        }
        
        // Send completion signal
        let completionMessage: [String: Any] = [
            "type": "training_sessions_complete",
            "totalSessions": sessions.count,
            "totalBatches": totalBatches,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try await sendMessageToWatch(completionMessage)
            logger.info("✅ Incremental transfer completed: \(sessions.count) sessions")
        } catch {
            logger.error("❌ Completion signal failed: \(error.localizedDescription)")
            transferDataToWatch(completionMessage)
        }
    }
    
    // MARK: - Current Week Sessions Sync
    
    func syncCurrentWeekSessions(from allSessions: [TrainingSession], currentWeek: Int, frequency: Int) async {
        let currentWeekSessions = allSessions.filter { $0.week == currentWeek }
        
        if currentWeekSessions.isEmpty {
            logger.warning("No sessions found for current week \(currentWeek)")
            return
        }
        
        let sessionData: [String: Any] = [
            "type": "current_week_sessions",
            "week": currentWeek,
            "frequency": frequency,
            "sessions": currentWeekSessions.compactMap { session -> [String: Any]? in
                return [
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
            },
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(sessionData)
                logger.info("Current week sessions synced successfully to Watch (\(currentWeekSessions.count) sessions)")
            } else {
                throw WatchConnectivityError.watchNotReachable
            }
        } catch {
            logger.error("Failed to sync current week sessions: \(error.localizedDescription)")
            transferDataToWatch(sessionData)
            logger.info("Current week sessions queued for background transfer")
        }
    }
    
    func syncNextSessionBatch(from allSessions: [TrainingSession], currentWeek: Int, frequency: Int) async {
        let batchSize = calculateOptimalBatchSize(frequency: frequency)
        let nextBatch = getNextSessionBatch(from: allSessions, currentWeek: currentWeek, batchSize: batchSize)
        
        if nextBatch.isEmpty {
            logger.info("No additional sessions to sync in next batch")
            return
        }
        
        let batchData: [String: Any] = [
            "type": "next_session_batch",
            "currentWeek": currentWeek,
            "batchSize": batchSize,
            "sessions": nextBatch.compactMap { session -> [String: Any]? in
                return [
                    "id": session.id.uuidString,
                    "week": session.week,
                    "day": session.day,
                    "type": session.type,
                    "focus": session.focus,
                    "sprints": session.sprints.map { sprint in
                        [
                            "distance": sprint.distanceYards,
                            "reps": sprint.reps,
                            "intensity": sprint.intensity
                        ]
                    },
                    "accessoryWork": session.accessoryWork,
                    "notes": session.notes ?? ""
                ]
            },
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(batchData)
                logger.info("Next session batch synced successfully to Watch (\(nextBatch.count) sessions)")
            } else {
                throw WatchConnectivityError.watchNotReachable
            }
        } catch {
            logger.error("Failed to sync next session batch: \(error.localizedDescription)")
            transferDataToWatch(batchData)
            logger.info("Next session batch queued for background transfer")
        }
    }
    
    private func calculateOptimalBatchSize(frequency: Int) -> Int {
        // Calculate optimal batch size based on frequency to prevent WatchConnectivity crashes
        switch frequency {
        case 1...2:
            return 5  // Smaller batches for lower frequency
        case 3...4:
            return 4  // Medium batches
        case 5...7:
            return 3  // Smaller batches for higher frequency
        default:
            return 3  // Default safe size
        }
    }
    
    private func getNextSessionBatch(from allSessions: [TrainingSession], currentWeek: Int, batchSize: Int) -> [TrainingSession] {
        // Get next batch of sessions after current week
        let futureSessions = allSessions.filter { $0.week > currentWeek }
        let sortedSessions = futureSessions.sorted { $0.week < $1.week }
        return Array(sortedSessions.prefix(batchSize))
    }
    
    // MARK: - 7-Stage Workflow Sync
    
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
            "currentStage": "warmup",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(flowData)
                logger.info("7-stage workout flow synced successfully to Watch")
            } else {
                throw WatchConnectivityError.watchNotReachable
            }
        } catch {
            logger.error("Failed to sync 7-stage workout flow: \(error.localizedDescription)")
            transferDataToWatch(flowData)
            logger.info("7-stage workout flow queued for background transfer")
        }
    }
    
    // MARK: - Force Sync Training Data
    
    func forceSyncTrainingData() async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - using background transfer for force sync")
        }
        
        isSyncing = true
        syncProgress = 0.1
        
        // Force sync all training data immediately
        let forceData: [String: Any] = [
            "type": "force_training_sync",
            "action": "full_resync",
            "priority": "high",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            if isWatchReachable {
                try await sendMessageToWatch(forceData)
                logger.info("Force training data sync initiated successfully")
                syncProgress = 1.0
                trainingSessionsSynced = true
            } else {
                throw WatchConnectivityError.watchNotReachable
            }
        } catch {
            logger.error("Failed to force sync training data: \(error.localizedDescription)")
            transferDataToWatch(forceData)
            logger.info("Force training data sync queued for background transfer")
        }
        
        isSyncing = false
    }
    
    // MARK: - Launch Workout on Watch
    
    func launchWorkoutOnWatch(session: TrainingSession) async {
        if !isWatchReachable {
            logger.warning("Watch not reachable - cannot launch workout")
            return
        }
        
        let workoutData: [String: Any] = [
            "type": "launch_workout",
            "session": [
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
            ],
            "autoStart": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try await sendMessageToWatch(workoutData)
            logger.info("Workout launched successfully on Watch: \(session.type)")
        } catch {
            logger.error("Failed to launch workout on Watch: \(error.localizedDescription)")
            // Don't use background transfer for workout launch as it needs to be immediate
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
        return isWatchConnected && isWatchReachable && onboardingDataSynced && trainingSessionsSynced && userProfileSynced
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
                
                // CRASH PROTECTION: Send application context immediately after activation
                sendInitialApplicationContext()
            case .inactive:
                logger.warning("WatchConnectivity session inactive")
                isWatchConnected = false
                isWatchReachable = false
            case .notActivated:
                logger.error("WatchConnectivity session not activated")
                isWatchConnected = false
                isWatchReachable = false
                connectionError = error?.localizedDescription ?? "Session activation failed"
            @unknown default:
                logger.error("Unknown WatchConnectivity activation state")
                isWatchConnected = false
                isWatchReachable = false
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
            
            // Reactivate the session
            session.activate()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            logger.info("Watch reachability changed: \(session.isReachable)")
            isWatchReachable = session.isReachable
            
            if session.isReachable {
                connectionError = nil
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        logger.info("Received message from Watch: \(message.keys.joined(separator: ", "))")
        
        // Handle incoming messages from Watch
        if let messageType = message["type"] as? String {
            switch messageType {
            case "workout_completed":
                handleWorkoutCompletion(message)
            case "session_data":
                handleSessionData(message)
            default:
                logger.info("Unknown message type from Watch: \(messageType)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        logger.info("Received message with reply handler from Watch")
        
        // Handle messages that expect a reply
        if let messageType = message["type"] as? String {
            switch messageType {
            case "request_sessions":
                handleSessionRequest(replyHandler: replyHandler)
            default:
                replyHandler(["status": "unknown_type"])
            }
        } else {
            replyHandler(["status": "no_type"])
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        logger.info("📱 Received application context from Watch")
        
        // CRASH PROTECTION: Handle nil or empty context gracefully
        guard !applicationContext.isEmpty else {
            logger.info("📱 Application context is empty (expected during startup) - initializing default context")
            initializeDefaultApplicationContext()
            return
        }
        
        // Log the received context keys for debugging
        let contextKeys = applicationContext.keys.joined(separator: ", ")
        logger.info("📋 Application context keys: \(contextKeys)")
        
        // Handle different types of application context data
        if let contextType = applicationContext["type"] as? String {
            switch contextType {
            case "user_profile":
                handleApplicationContextUserProfile(applicationContext)
            case "workout_settings":
                handleApplicationContextWorkoutSettings(applicationContext)
            case "app_state":
                handleApplicationContextAppState(applicationContext)
            default:
                logger.info("❓ Unknown application context type: \(contextType)")
            }
        } else {
            // Handle legacy or untyped context data
            handleGenericApplicationContext(applicationContext)
        }
    }
    
    // MARK: - Application Context Handlers
    
    private func initializeDefaultApplicationContext() {
        logger.info("🔄 Initializing default application context")
        
        // CRASH PROTECTION: Get context and ensure we have valid context data
        let defaultContext = DataPersistenceManager.shared.getApplicationContext()
        
        // CRASH PROTECTION: Ensure we have valid context data
        guard !defaultContext.isEmpty else {
            logger.error("❌ DataPersistenceManager returned empty context - using fallback")
            
            let fallbackContext: [String: Any] = [
                "appVersion": "1.0.0",
                "buildNumber": "1",
                "installDate": Date(),
                "lastLaunch": Date(),
                "onboardingCompleted": false,
                "userProfileExists": false,
                "trainingDataSynced": false
            ]
            
            sendContextToWatch(fallbackContext)
            return
        }
        
        // Send default context to watch
        sendContextToWatch(defaultContext)
    }
    
    /// Send application context to watch (public method)
    func sendApplicationContext(_ context: [String: Any]) {
        sendContextToWatch(context)
    }
    
    private func sendContextToWatch(_ context: [String: Any]) {
        Task {
            do {
                if WCSession.default.activationState == .activated {
                    try WCSession.default.updateApplicationContext(context)
                    logger.info("✅ Application context sent to Watch")
                } else {
                    logger.warning("⚠️ WCSession not activated - context will be sent when ready")
                }
            } catch {
                logger.error("❌ Failed to send context to Watch: \(error)")
            }
        }
    }
    
    private func handleApplicationContextUserProfile(_ context: [String: Any]) {
        logger.info("👤 Processing user profile context from Watch")
        
        // Extract and validate user profile data
        if let name = context["name"] as? String,
           let level = context["level"] as? String {
            
            // Update local profile if needed
            Task { @MainActor in
                // Notify profile update
                NotificationCenter.default.post(
                    name: NSNotification.Name("UserProfileUpdatedFromWatch"),
                    object: nil,
                    userInfo: context
                )
            }
            
            logger.info("✅ User profile context processed: \(name) (\(level))")
        } else {
            logger.warning("⚠️ Invalid user profile context data")
        }
    }
    
    private func handleApplicationContextWorkoutSettings(_ context: [String: Any]) {
        logger.info("⚙️ Processing workout settings context from Watch")
        
        // Handle workout settings updates
        Task { @MainActor in
            NotificationCenter.default.post(
                name: NSNotification.Name("WorkoutSettingsUpdatedFromWatch"),
                object: nil,
                userInfo: context
            )
        }
        
        logger.info("✅ Workout settings context processed")
    }
    
    private func handleApplicationContextAppState(_ context: [String: Any]) {
        logger.info("📱 Processing app state context from Watch")
        
        // Handle app state synchronization
        if let currentWorkout = context["currentWorkout"] as? String {
            logger.info("🏃 Watch is in workout: \(currentWorkout)")
        }
        
        Task { @MainActor in
            NotificationCenter.default.post(
                name: NSNotification.Name("AppStateUpdatedFromWatch"),
                object: nil,
                userInfo: context
            )
        }
        
        logger.info("✅ App state context processed")
    }
    
    private func handleGenericApplicationContext(_ context: [String: Any]) {
        logger.info("📦 Processing generic application context from Watch")
        
        // Handle legacy or untyped context data
        Task { @MainActor in
            NotificationCenter.default.post(
                name: NSNotification.Name("GenericContextFromWatch"),
                object: nil,
                userInfo: context
            )
        }
        
        logger.info("✅ Generic application context processed")
    }
    
    // MARK: - Message Handlers
    
    private func handleWorkoutCompletion(_ message: [String: Any]) {
        logger.info("Processing workout completion from Watch")
        
        // Extract workout data and integrate with HistoryManager
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkoutCompletedOnWatch"),
            object: nil,
            userInfo: message
        )
    }
    
    private func handleSessionData(_ message: [String: Any]) {
        logger.info("Processing session data from Watch")
        
        // Handle session performance data
        NotificationCenter.default.post(
            name: NSNotification.Name("SessionDataFromWatch"),
            object: nil,
            userInfo: message
        )
    }
    
    private func handleSessionRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Watch requested training sessions")
        
        // Reply with current sessions
        replyHandler([
            "status": "success",
            "message": "Sessions available via background sync"
        ])
    }
    
    // MARK: - Safe Sync Methods for Crash Prevention
    
    /// Safely sync profile data with comprehensive error handling
    func syncProfileSafely(_ profile: UserProfile) async throws {
        print("⌚ [WATCH] [SYNC]: Starting safe profile sync")
        
        // Validate session state
        guard WCSession.isSupported() else {
            print("⚠️ [WATCH] [SYNC]: Watch not supported, skipping")
            return
        }
        
        guard WCSession.default.activationState == .activated else {
            print("⚠️ [WATCH] [SYNC]: Session not activated, skipping")
            return
        }
        
        guard WCSession.default.isReachable else {
            print("⚠️ [WATCH] [SYNC]: Watch not reachable, will sync later")
            return
        }
        
        do {
            // Convert profile to safe dictionary
            let profileData: [String: Any] = [
                "name": profile.name.isEmpty ? "User" : profile.name,
                "level": profile.level.isEmpty ? "Beginner" : profile.level,
                "frequency": max(1, min(7, profile.frequency)),
                "currentWeek": max(1, profile.currentWeek),
                "currentDay": max(1, profile.currentDay),
                "baselineTime": profile.personalBests["40yd"] ?? 6.25,
                "type": "onboarding_complete",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            // Send with timeout protection
            try await withTimeout(seconds: 30) {
                try await withCheckedThrowingContinuation { continuation in
                    WCSession.default.sendMessage(profileData) { response in
                        print("✅ [WATCH] [SYNC]: Profile sync successful")
                        continuation.resume()
                    } errorHandler: { error in
                        print("❌ [WATCH] [SYNC]: Profile sync failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
        } catch {
            print("⚠️ [WATCH] [SYNC]: Failed to sync profile, continuing anyway: \(error)")
            // Don't throw - watch sync failure shouldn't block onboarding
        }
    }
    
    /// Safely sync training sessions with batching and error handling
    func syncTrainingSessionsSafely(_ sessions: [TrainingSession]) async throws {
        print("⌚ [WATCH] [SESSIONS]: Starting safe session sync (\(sessions.count) sessions)")
        
        // Validate session state
        guard WCSession.isSupported() && WCSession.default.activationState == .activated else {
            print("⚠️ [WATCH] [SESSIONS]: Watch not available, skipping")
            return
        }
        
        guard !sessions.isEmpty else {
            print("⚠️ [WATCH] [SESSIONS]: No sessions to sync")
            return
        }
        
        do {
            // Batch sessions into smaller chunks to prevent memory issues
            let batchSize = 3
            let batches = sessions.chunked(into: batchSize)
            
            for (index, batch) in batches.enumerated() {
                let batchData: [String: Any] = [
                    "type": "training_sessions_batch",
                    "batchIndex": index,
                    "totalBatches": batches.count,
                    "sessions": batch.map { session in
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
                            "accessoryWork": session.accessoryWork
                        ]
                    },
                    "timestamp": Date().timeIntervalSince1970
                ]
                
                // Send batch with timeout
                try await withTimeout(seconds: 15) {
                    try await withCheckedThrowingContinuation { continuation in
                        WCSession.default.sendMessage(batchData) { response in
                            print("✅ [WATCH] [SESSIONS]: Batch \(index + 1)/\(batches.count) sent")
                            continuation.resume()
                        } errorHandler: { error in
                            print("❌ [WATCH] [SESSIONS]: Batch \(index + 1) failed: \(error)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Small delay between batches to prevent overwhelming
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Send completion message
            let completionData: [String: Any] = [
                "type": "training_sessions_complete",
                "totalBatches": batches.count,
                "totalSessions": sessions.count,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            try await withTimeout(seconds: 10) {
                try await withCheckedThrowingContinuation { continuation in
                    WCSession.default.sendMessage(completionData) { response in
                        print("✅ [WATCH] [SESSIONS]: All sessions synced successfully")
                        continuation.resume()
                    } errorHandler: { error in
                        print("❌ [WATCH] [SESSIONS]: Completion message failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
        } catch {
            print("⚠️ [WATCH] [SESSIONS]: Session sync failed, continuing anyway: \(error)")
            // Don't throw - watch sync failure shouldn't block onboarding
        }
    }
    
    // MARK: - Timeout Helper
    
    /// Add timeout protection to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WatchError.timeout
            }
            
            guard let result = try await group.next() else {
                throw WatchError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Application Context Handlers
    
}

// MARK: - Watch Error Types

enum WatchError: LocalizedError {
    case timeout
    case notSupported
    case notActivated
    case notReachable
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Watch sync timed out"
        case .notSupported:
            return "Apple Watch not supported"
        case .notActivated:
            return "Watch session not activated"
        case .notReachable:
            return "Apple Watch not reachable"
        case .syncFailed:
            return "Watch sync failed"
        }
    }
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#endif
