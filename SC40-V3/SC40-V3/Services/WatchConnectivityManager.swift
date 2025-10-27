import Foundation
import Combine
import os.log

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

// MARK: - Watch Connectivity Errors
enum WatchConnectivityError: LocalizedError {
    case watchNotReachable
    case timeout
    case sessionNotActivated
    
    var errorDescription: String? {
        switch self {
        case .watchNotReachable:
            return "Apple Watch is not reachable. Make sure your Watch is nearby and connected."
        case .timeout:
            return "Watch communication timed out. Please try again."
        case .sessionNotActivated:
            return "Watch session is not activated. Please restart the app."
        }
    }
}

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
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        logger.info("WatchConnectivity session activation requested")
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
            do {
                let onboardingData: [String: Any] = [
                    "type": "onboarding_complete",
                    "name": userProfile.name,
                    "email": userProfile.email ?? "",
                    "timestamp": Date().timeIntervalSince1970
                ]
                transferDataToWatch(onboardingData)
                onboardingDataSynced = true
                logger.info("Onboarding data sent via background transfer")
            } catch {
                connectionError = "Failed to sync profile to Watch"
            }
        }
        
        isSyncing = false
    }
    
    // MARK: - Training Sessions Sync
    
    func syncTrainingSessions(_ sessions: [TrainingSession]) async {
        guard isWatchReachable else {
            logger.warning("Watch not reachable - cannot sync training sessions")
            return
        }
        
        isSyncing = true
        syncProgress = 0.1
        
        do {
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
            
            try await sendMessageToWatch(trainingData)
            
            syncProgress = 1.0
            trainingSessionsSynced = true
            
            logger.info("Training sessions synced successfully to Watch (\(sessions.count) sessions)")
            
        } catch {
            logger.error("Failed to sync training sessions: \(error.localizedDescription)")
            connectionError = "Failed to sync workouts to Watch"
        }
        
        isSyncing = false
    }
    
    // MARK: - Workout Launch Integration
    
    func launchWorkoutOnWatch(session: TrainingSession) async {
        guard isWatchReachable else {
            logger.warning("Watch not reachable - cannot launch workout")
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
        guard isWatchReachable else {
            logger.warning("Watch not reachable - cannot sync 7-stage flow")
            return
        }
        
        do {
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
            
            try await sendMessageToWatch(flowData)
            logger.info("7-stage workout flow synced to Watch")
            
        } catch {
            logger.error("Failed to sync 7-stage flow: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    func sendMessageToWatch(_ message: [String: Any]) async throws {
        // Check if Watch is reachable before sending
        guard WCSession.default.isReachable else {
            throw WatchConnectivityError.watchNotReachable
        }
        
        return try await withTimeout(seconds: 10) {
            try await withCheckedThrowingContinuation { continuation in
                WCSession.default.sendMessage(message) { reply in
                    self.logger.info("Watch message sent successfully with reply: \(reply)")
                    continuation.resume()
                } errorHandler: { error in
                    self.logger.error("Watch message failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Background Transfer Helper
    
    private func transferDataToWatch(_ data: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            logger.error("Cannot transfer data - WCSession not activated")
            return
        }
        
        // Use transferUserInfo for reliable background data transfer
        WCSession.default.transferUserInfo(data)
        logger.info("Data queued for background transfer to Watch")
    }
    
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
            
            // Handle messages from Watch (workout results, status updates, etc.)
            if let type = message["type"] as? String {
                switch type {
                case "workout_completed":
                    handleWorkoutCompletion(message)
                case "sync_request":
                    handleSyncRequest(replyHandler)
                case "status_update":
                    handleStatusUpdate(message)
                default:
                    logger.warning("Unknown message type from Watch: \(type)")
                }
            }
            
            // Send acknowledgment
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
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
}

#endif
