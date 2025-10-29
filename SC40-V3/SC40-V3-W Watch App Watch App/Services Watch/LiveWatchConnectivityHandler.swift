import Foundation
import Combine
import os.log
import WatchConnectivity
import WatchKit // Added for haptic feedback
import CoreMotion

// Import Watch-specific models and managers
// Note: These should be available in the same target


// MARK: - Live Watch Connectivity Handler
// Handles connectivity testing messages from iPhone

@MainActor
class LiveWatchConnectivityHandler: NSObject, ObservableObject {
    static let shared = LiveWatchConnectivityHandler()
    
    @Published var isConnected = false
    @Published var lastMessageReceived: String?
    @Published var messagesReceived = 0
    
    private let logger = Logger(subsystem: "com.accelerate.sc40.watch", category: "LiveConnectivity")
    private var session: WCSession?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            logger.error("WatchConnectivity not supported on Apple Watch")
            return
        }
        
        session = WCSession.default
        
        // Set delegate if not already set
        if session?.delegate == nil {
            session?.delegate = self
            logger.info("Set as WCSession delegate on Watch")
        }
        
        // Activate session
        if session?.activationState != .activated {
            session?.activate()
            logger.info("Activating WCSession on Watch")
        }
        
        updateConnectionStatus()
    }
    
    private func updateConnectionStatus() {
        guard let session = session else {
            isConnected = false
            return
        }
        
        isConnected = session.activationState == .activated
        logger.info("Watch connection status: \(self.isConnected)")
    }
    
    // MARK: - Message Handling
    
    private func handlePingTest(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling ping test from iPhone")
        
        // Provide haptic and audio feedback for ping
        WKInterfaceDevice.current().play(.notification)
        
        let reply: [String: Any] = [
            "type": "ping_response",
            "status": "success",
            "message": "Pong from Apple Watch!",
            "timestamp": Date().timeIntervalSince1970,
            "watchInfo": [
                "model": "Apple Watch",
                "os": "watchOS",
                "connectivity": "active"
            ]
        ]
        
        replyHandler(reply)
        
        messagesReceived += 1
        lastMessageReceived = "Ping test - replied successfully"
        
        print("📱 Watch: Ping received with haptic feedback")
    }
    
    private func handleWorkoutData(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling workout data from iPhone")
        
        // Provide haptic and audio feedback for workout session received
        WKInterfaceDevice.current().play(.success)
        
        // Extract workout information
        let sessionType = message["sessionType"] as? String ?? "Unknown"
        let focus = message["focus"] as? String ?? "Unknown"
        
        let reply: [String: Any] = [
            "type": "workout_data_response",
            "status": "received",
            "sessionType": sessionType,
            "focus": focus,
            "watchStatus": "ready_for_workout",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        replyHandler(reply)
        
        messagesReceived += 1
        lastMessageReceived = "Workout data - \(sessionType)"
        
        // Here you could trigger the actual workout UI on the watch
        logger.info("Workout data processed: \(sessionType) - \(focus)")
        print("🏃‍♂️ Watch: Workout session received with success haptic - \(sessionType)")
    }
    
    private func handleProfileSync(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling profile sync from iPhone")
        
        // Provide haptic feedback for profile sync
        WKInterfaceDevice.current().play(.click)
        
        let name = message["name"] as? String ?? "Unknown"
        let level = message["level"] as? String ?? "Unknown"
        
        let reply: [String: Any] = [
            "type": "profile_sync_response",
            "status": "synced",
            "name": name,
            "level": level,
            "watchStorage": "updated",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        replyHandler(reply)
        
        messagesReceived += 1
        lastMessageReceived = "Profile sync - \(name) (\(level))"
        
        // Save the profile data to Watch storage
        UserDefaults.standard.set(name, forKey: "SC40_UserName")
        UserDefaults.standard.set(level, forKey: "SC40_UserLevel")
        logger.info("Profile synced: \(name) - \(level)")
        
        // Post notification for immediate UI updates
        NotificationCenter.default.post(name: NSNotification.Name("profileDataUpdated"), object: nil)
        print("👤 Watch: Profile sync received with click haptic - \(name) (\(level)) - UI updated")
    }
    
    private func handleOnboardingComplete(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling onboarding completion from iPhone")
        
        // Provide strong haptic feedback for onboarding completion
        WKInterfaceDevice.current().play(.success)
        
        // Extract user profile data
        let name = message["name"] as? String ?? "User"
        let level = message["level"] as? String ?? "Intermediate"
        let baselineTime = message["baselineTime"] as? Double ?? 5.0
        let frequency = message["frequency"] as? Int ?? 3
        let age = message["age"] as? Int ?? 25
        let height = message["height"] as? Int ?? 70
        let weight = message["weight"] as? Double ?? 170.0
        let currentWeek = message["currentWeek"] as? Int ?? 1
        let currentDay = message["currentDay"] as? Int ?? 1
        
        // Update Watch UserDefaults with synced data
        UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted")
        UserDefaults.standard.set(level, forKey: "SC40_UserLevel")
        UserDefaults.standard.set(baselineTime, forKey: "SC40_TargetTime")
        UserDefaults.standard.set(frequency, forKey: "SC40_UserFrequency")
        UserDefaults.standard.set(name, forKey: "SC40_UserName")
        UserDefaults.standard.set(age, forKey: "SC40_UserAge")
        UserDefaults.standard.set(height, forKey: "SC40_UserHeight")
        UserDefaults.standard.set(weight, forKey: "SC40_UserWeight")
        UserDefaults.standard.set(currentWeek, forKey: "SC40_CurrentWeek")
        UserDefaults.standard.set(currentDay, forKey: "SC40_CurrentDay")
        
        // Also save to the standard keys for compatibility
        UserDefaults.standard.set(level, forKey: "userLevel")
        UserDefaults.standard.set(frequency, forKey: "trainingFrequency")
        UserDefaults.standard.set(baselineTime, forKey: "personalBest40yd")
        
        // Update Watch app state
        Task { @MainActor in
            // Store user data in UserDefaults for Watch app state management
            UserDefaults.standard.set(name, forKey: "user_name")
            UserDefaults.standard.set(level, forKey: "SC40_UserLevel")
            UserDefaults.standard.set(baselineTime, forKey: "SC40_TargetTime")
            UserDefaults.standard.set("iPhone Sync", forKey: "SC40_AuthMethod")
            
            // TODO: Update WatchAppStateManager when available
            // WatchAppStateManager.shared.updateFromOnboarding([
            //     "name": name,
            //     "level": level,
            //     "frequency": frequency
            // ])
            
            // Post notification for immediate UI updates
            NotificationCenter.default.post(name: NSNotification.Name("profileDataUpdated"), object: nil)
            print("📱➡️⌚ Watch: Profile data updated and UI notification sent")
        }
        
        let reply: [String: Any] = [
            "type": "onboarding_sync_response",
            "status": "success",
            "message": "Onboarding data synced to Watch",
            "watchProfile": [
                "name": name,
                "level": level,
                "targetTime": baselineTime,
                "frequency": frequency
            ],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        replyHandler(reply)
        
        messagesReceived += 1
        lastMessageReceived = "Onboarding sync - \(name) (\(level))"
        
        logger.info("✅ Onboarding data synced to Watch: \(name) - \(level) - \(baselineTime)s")
        print("✅ Watch: Onboarding data received and saved with success haptic - Level: \(level), Target: \(baselineTime)s")
    }
    
    // MARK: - Test Methods
    
    func sendTestMessageToPhone() {
        guard let session = session, session.isReachable else {
            logger.warning("iPhone not reachable from Watch")
            return
        }
        
        let message: [String: Any] = [
            "type": "watch_initiated_test",
            "message": "Hello from Apple Watch!",
            "timestamp": Date().timeIntervalSince1970,
            "watchInfo": [
                "battery": "good",
                "connectivity": "active",
                "status": "ready"
            ]
        ]
        
        session.sendMessage(message) { reply in
            Task { @MainActor in
                self.logger.info("Received reply from iPhone: \(reply)")
                self.lastMessageReceived = "Reply from iPhone received"
            }
        } errorHandler: { error in
            Task { @MainActor in
                self.logger.error("Failed to send message to iPhone: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension LiveWatchConnectivityHandler: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateConnectionStatus()
            
            if let error = error {
                self.logger.error("Watch session activation failed: \(error.localizedDescription)")
            } else {
                self.logger.info("Watch session activated: \(activationState.rawValue)")
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            self.logger.info("Received message from iPhone: \(message)")
            
            guard let messageType = message["type"] as? String else {
                replyHandler(["error": "No message type specified"])
                return
            }
            
            switch messageType {
            case "ping_test":
                self.handlePingTest(message, replyHandler: replyHandler)
                
            case "test_workout_data":
                self.handleWorkoutData(message, replyHandler: replyHandler)
                
            case "test_profile_sync":
                self.handleProfileSync(message, replyHandler: replyHandler)
                
            case "onboarding_complete":
                self.handleOnboardingComplete(message, replyHandler: replyHandler)
                
            case "training_sessions":
                self.handleTrainingSessions(message, replyHandler: replyHandler)
                
            case "workout_flow_update":
                self.handleWorkoutFlowUpdate(message, replyHandler: replyHandler)
                
            default:
                self.logger.warning("Unknown message type: \(messageType)")
                replyHandler([
                    "error": "Unknown message type",
                    "type": messageType,
                    "timestamp": Date().timeIntervalSince1970
                ])
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            self.logger.info("Received background data from iPhone: \(userInfo)")
            
            // Provide haptic feedback for background data
            WKInterfaceDevice.current().play(.notification)
            
            self.messagesReceived += 1
            
            if let type = userInfo["type"] as? String {
                self.lastMessageReceived = "Background: \(type)"
                
                // Handle onboarding data sent via background transfer
                if type == "onboarding_complete" {
                    self.handleOnboardingCompleteBackground(userInfo)
                } else if type == "training_sessions" {
                    self.handleTrainingSessionsBackground(userInfo)
                }
            } else {
                self.lastMessageReceived = "Background data received"
            }
            
            print("📱 Watch: Background data received with notification haptic")
        }
    }
    
    private func handleOnboardingCompleteBackground(_ userInfo: [String: Any]) {
        logger.info("Processing onboarding data from background transfer")
        
        // Provide haptic feedback for background onboarding sync
        WKInterfaceDevice.current().play(.success)
        
        // Extract user profile data (same as message handler)
        let name = userInfo["name"] as? String ?? "User"
        let level = userInfo["level"] as? String ?? "Intermediate"
        let baselineTime = userInfo["baselineTime"] as? Double ?? 5.0
        let frequency = userInfo["frequency"] as? Int ?? 3
        let age = userInfo["age"] as? Int ?? 25
        let height = userInfo["height"] as? Int ?? 70
        let weight = userInfo["weight"] as? Double ?? 170.0
        let currentWeek = userInfo["currentWeek"] as? Int ?? 1
        let currentDay = userInfo["currentDay"] as? Int ?? 1
        
        // Update Watch UserDefaults with synced data
        UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted")
        UserDefaults.standard.set(level, forKey: "SC40_UserLevel")
        UserDefaults.standard.set(baselineTime, forKey: "SC40_TargetTime")
        UserDefaults.standard.set(frequency, forKey: "SC40_UserFrequency")
        UserDefaults.standard.set(name, forKey: "SC40_UserName")
        UserDefaults.standard.set(age, forKey: "SC40_UserAge")
        UserDefaults.standard.set(height, forKey: "SC40_UserHeight")
        UserDefaults.standard.set(weight, forKey: "SC40_UserWeight")
        UserDefaults.standard.set(currentWeek, forKey: "SC40_CurrentWeek")
        UserDefaults.standard.set(currentDay, forKey: "SC40_CurrentDay")
        
        // Also save to the standard keys for compatibility
        UserDefaults.standard.set(level, forKey: "userLevel")
        UserDefaults.standard.set(frequency, forKey: "trainingFrequency")
        UserDefaults.standard.set(baselineTime, forKey: "personalBest40yd")
        
        // Update Watch app state
        Task { @MainActor in
            // Store user data in UserDefaults for Watch app state management
            UserDefaults.standard.set(name, forKey: "user_name")
            UserDefaults.standard.set(level, forKey: "SC40_UserLevel")
            UserDefaults.standard.set(baselineTime, forKey: "SC40_TargetTime")
            UserDefaults.standard.set("iPhone Sync", forKey: "SC40_AuthMethod")
            
            // TODO: Update WatchAppStateManager when available
            // WatchAppStateManager.shared.updateFromOnboarding([
            //     "name": name,
            //     "level": level,
            //     "frequency": frequency
            // ])
        }
    }
    
    // MARK: - Training Sessions Handler
    
    private func handleTrainingSessions(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("📚 Handling training sessions from iPhone")
        
        guard let sessionsData = message["sessions"] as? [[String: Any]] else {
            logger.error("❌ No sessions data in training_sessions message")
            replyHandler(["error": "No sessions data", "timestamp": Date().timeIntervalSince1970])
            return
        }
        
        // Store session data locally (simplified for now)
        // TODO: Implement proper TrainingSession conversion when models are available
        do {
            let data = try JSONSerialization.data(withJSONObject: sessionsData)
            UserDefaults.standard.set(data, forKey: "trainingSessions")
            logger.info("✅ Stored \(sessionsData.count) training sessions locally")
        } catch {
            logger.error("❌ Failed to store training sessions: \(error.localizedDescription)")
        }
        
        // Update Watch app state
        Task { @MainActor in
            // Notify that training sessions have been updated
            NotificationCenter.default.post(name: NSNotification.Name("trainingSessionsUpdated"), object: nil)
            logger.info("✅ Updated Watch with \(sessionsData.count) training sessions")
        }
        
        replyHandler([
            "received": true,
            "sessionCount": sessionsData.count,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Workout Flow Handler
    
    private func handleWorkoutFlowUpdate(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("🏃‍♂️ Handling workout flow update from iPhone")
        
        guard let stages = message["stages"] as? [[String: Any]] else {
            logger.error("❌ No stages data in workout_flow_update message")
            replyHandler(["error": "No stages data", "timestamp": Date().timeIntervalSince1970])
            return
        }
        
        // Store workout flow stages
        UserDefaults.standard.set(stages, forKey: "workoutFlowStages")
        
        logger.info("✅ Updated workout flow with \(stages.count) stages")
        
        replyHandler([
            "received": true,
            "stageCount": stages.count,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Helper Methods
    
    // TODO: Implement TrainingSession conversion when models are available
    /*
    private func convertToTrainingSession(from data: [String: Any]) -> TrainingSession? {
        // Implementation commented out due to missing TrainingSession and SprintSet types
        // Will be restored when proper model imports are available
        return nil
    }
    
    private func storeTrainingSessions(_ sessions: [TrainingSession]) {
        // Implementation commented out due to missing TrainingSession type
        // Will be restored when proper model imports are available
    }
    */
    
    private func handleTrainingSessionsBackground(_ userInfo: [String: Any]) {
        logger.info("📚 Handling background training sessions transfer")
        
        guard let sessionsData = userInfo["sessions"] as? [[String: Any]] else {
            logger.error("❌ No sessions data in background training_sessions transfer")
            return
        }
        
        // Store session data locally (simplified for now)
        // TODO: Implement proper TrainingSession conversion when models are available
        do {
            let data = try JSONSerialization.data(withJSONObject: sessionsData)
            UserDefaults.standard.set(data, forKey: "trainingSessions")
            logger.info("✅ Background stored \(sessionsData.count) training sessions locally")
        } catch {
            logger.error("❌ Failed to store background training sessions: \(error.localizedDescription)")
        }
        
        // Update Watch app state
        Task { @MainActor in
            // Notify that training sessions have been updated
            NotificationCenter.default.post(name: NSNotification.Name("trainingSessionsUpdated"), object: nil)
            logger.info("✅ Background updated Watch with \(sessionsData.count) training sessions")
        }
        
        lastMessageReceived = "Training sessions (BG) - \(sessionsData.count) sessions"
        logger.info("✅ Background training sessions sync complete: \(sessionsData.count) sessions")
        print("✅ Watch: Background training sessions received - \(sessionsData.count) sessions")
    }
}
