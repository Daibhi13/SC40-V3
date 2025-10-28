import Foundation
import Combine
import os.log

#if canImport(WatchConnectivity) && os(watchOS)
import WatchConnectivity

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
    }
    
    private func handleWorkoutData(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling workout data from iPhone")
        
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
    }
    
    private func handleProfileSync(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling profile sync from iPhone")
        
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
        
        // Here you could save the profile data to Watch storage
        logger.info("Profile synced: \(name) - \(level)")
    }
    
    private func handleOnboardingComplete(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("Handling onboarding completion from iPhone")
        
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
        
        // Update WatchAuthManager if available
        Task { @MainActor in
            if let authManager = try? WatchAuthManager.shared {
                authManager.userProfile = WatchUserProfile(
                    id: name,
                    level: level,
                    targetTime: baselineTime,
                    authMethod: "iPhone Sync",
                    joinDate: Date()
                )
                authManager.authState = .authenticated
                authManager.isAuthenticated = true
                authManager.showOnboarding = false
            }
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
        print("✅ Watch: Onboarding data received and saved - Level: \(level), Target: \(baselineTime)s")
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
            self.messagesReceived += 1
            
            if let type = userInfo["type"] as? String {
                self.lastMessageReceived = "Background: \(type)"
                
                // Handle onboarding data sent via background transfer
                if type == "onboarding_complete" {
                    self.handleOnboardingCompleteBackground(userInfo)
                }
            } else {
                self.lastMessageReceived = "Background data received"
            }
        }
    }
    
    private func handleOnboardingCompleteBackground(_ userInfo: [String: Any]) {
        logger.info("Processing onboarding data from background transfer")
        
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
        
        // Update WatchAuthManager if available
        Task { @MainActor in
            if let authManager = try? WatchAuthManager.shared {
                authManager.userProfile = WatchUserProfile(
                    id: name,
                    level: level,
                    targetTime: baselineTime,
                    authMethod: "iPhone Sync",
                    joinDate: Date()
                )
                authManager.authState = .authenticated
                authManager.isAuthenticated = true
                authManager.showOnboarding = false
            }
        }
        
        lastMessageReceived = "Onboarding sync (BG) - \(name) (\(level))"
        logger.info("✅ Background onboarding sync complete: \(name) - \(level) - \(baselineTime)s")
        print("✅ Watch: Background onboarding data received - Level: \(level), Target: \(baselineTime)s")
    }
}

#endif
