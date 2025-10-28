import Foundation
import Combine
import os.log

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

// MARK: - Live Watch Connectivity Manager
// Dedicated manager for live testing and real-time connectivity

@MainActor
class LiveWatchConnectivityManager: NSObject, ObservableObject {
    static let shared = LiveWatchConnectivityManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var isReachable = false
    @Published var connectionStatus = "Initializing..."
    @Published var lastMessageSent: String?
    @Published var lastMessageReceived: String?
    @Published var messagesSent = 0
    @Published var messagesReceived = 0
    @Published var testResults: [ConnectivityTestResult] = []
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "LiveWatchConnectivity")
    private var session: WCSession?
    
    private override init() {
        super.init()
        setupLiveConnectivity()
    }
    
    // MARK: - Setup
    
    private func setupLiveConnectivity() {
        guard WCSession.isSupported() else {
            connectionStatus = "WatchConnectivity not supported"
            logger.error("WatchConnectivity not supported on this device")
            return
        }
        
        session = WCSession.default
        
        // Check if delegate is already set
        if session?.delegate == nil {
            session?.delegate = self
            logger.info("Set as WCSession delegate")
        } else {
            logger.warning("WCSession delegate already set by another manager")
        }
        
        // Activate if needed
        if session?.activationState != .activated {
            session?.activate()
            logger.info("Activating WCSession for live testing")
        }
        
        updateConnectionStatus()
    }
    
    private func updateConnectionStatus() {
        guard let session = session else {
            connectionStatus = "Session not available"
            return
        }
        
        isConnected = session.isPaired && session.isWatchAppInstalled
        isReachable = session.isReachable
        
        if !session.isPaired {
            connectionStatus = "Apple Watch not paired"
        } else if !session.isWatchAppInstalled {
            connectionStatus = "SC40 Watch app not installed"
        } else if !session.isReachable {
            connectionStatus = "Apple Watch not reachable"
        } else {
            connectionStatus = "Connected and ready"
        }
        
        logger.info("Connection status updated: \(self.connectionStatus)")
    }
    
    // MARK: - Live Testing Methods
    
    func sendTestPing() async {
        guard let session = session, session.isReachable else {
            addTestResult(name: "Ping Test", success: false, message: "Watch not reachable")
            return
        }
        
        let testMessage: [String: Any] = [
            "type": "ping_test",
            "timestamp": Date().timeIntervalSince1970,
            "message": "Hello from iPhone - Live Test",
            "testId": UUID().uuidString
        ]
        
        do {
            try await withTimeout(seconds: 5) {
                try await withCheckedThrowingContinuation { continuation in
                    session.sendMessage(testMessage) { reply in
                        self.messagesSent += 1
                        self.lastMessageSent = "Ping test sent successfully"
                        self.addTestResult(name: "Ping Test", success: true, message: "Reply: \(reply)")
                        continuation.resume()
                    } errorHandler: { error in
                        self.addTestResult(name: "Ping Test", success: false, message: error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            addTestResult(name: "Ping Test", success: false, message: "Timeout or error: \(error.localizedDescription)")
        }
    }
    
    func sendTestWorkoutData() async {
        guard let session = session, session.isReachable else {
            addTestResult(name: "Workout Data Test", success: false, message: "Watch not reachable")
            return
        }
        
        let workoutData: [String: Any] = [
            "type": "test_workout_data",
            "sessionId": UUID().uuidString,
            "sessionType": "Live Test Sprint",
            "focus": "Connectivity Testing",
            "week": 1,
            "day": 1,
            "sprints": [
                [
                    "distanceYards": 40,
                    "reps": 3,
                    "intensity": "Max"
                ]
            ],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            try await withTimeout(seconds: 10) {
                try await withCheckedThrowingContinuation { continuation in
                    session.sendMessage(workoutData) { reply in
                        self.messagesSent += 1
                        self.lastMessageSent = "Workout data sent successfully"
                        self.addTestResult(name: "Workout Data Test", success: true, message: "Data synced successfully")
                        continuation.resume()
                    } errorHandler: { error in
                        self.addTestResult(name: "Workout Data Test", success: false, message: error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            addTestResult(name: "Workout Data Test", success: false, message: "Failed: \(error.localizedDescription)")
        }
    }
    
    func sendTestUserProfile() async {
        guard let session = session, session.isReachable else {
            addTestResult(name: "Profile Sync Test", success: false, message: "Watch not reachable")
            return
        }
        
        let profileData: [String: Any] = [
            "type": "test_profile_sync",
            "name": "Live Test User",
            "level": "Elite",
            "frequency": 7,
            "baselineTime": 4.24,
            "personalBests": ["40yd": 4.24],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.transferUserInfo(profileData)
        messagesSent += 1
        lastMessageSent = "Profile data transferred"
        addTestResult(name: "Profile Sync Test", success: true, message: "Profile data queued for transfer")
    }
    
    func testWatchReachability() {
        guard let session = session else {
            addTestResult(name: "Reachability Test", success: false, message: "No session available")
            return
        }
        
        let isReachable = session.isReachable
        let isPaired = session.isPaired
        let isInstalled = session.isWatchAppInstalled
        let activationState = session.activationState
        
        let message = """
        Paired: \(isPaired)
        App Installed: \(isInstalled)
        Reachable: \(isReachable)
        Activation: \(activationState.rawValue)
        """
        
        addTestResult(
            name: "Reachability Test",
            success: isPaired && isInstalled && isReachable && activationState == .activated,
            message: message
        )
    }
    
    // MARK: - Helper Methods
    
    private func addTestResult(name: String, success: Bool, message: String) {
        let result = ConnectivityTestResult(
            id: UUID(),
            testName: name,
            success: success,
            message: message,
            timestamp: Date()
        )
        
        testResults.append(result)
        
        // Keep only last 50 results
        if testResults.count > 50 {
            testResults.removeFirst()
        }
        
        logger.info("Test result: \(name) - \(success ? "SUCCESS" : "FAILED") - \(message)")
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw ConnectivityError.timeout
            }
            
            guard let result = try await group.next() else {
                throw ConnectivityError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    func clearTestResults() {
        testResults.removeAll()
        messagesSent = 0
        messagesReceived = 0
        lastMessageSent = nil
        lastMessageReceived = nil
    }
    
    func runFullConnectivityTest() async {
        clearTestResults()
        
        // Test 1: Reachability
        testWatchReachability()
        
        // Test 2: Ping
        await sendTestPing()
        
        // Small delay between tests
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Test 3: Workout Data
        await sendTestWorkoutData()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Test 4: Profile Sync
        await sendTestUserProfile()
        
        addTestResult(name: "Full Test Suite", success: true, message: "Completed all connectivity tests")
    }
}

// MARK: - WCSessionDelegate

extension LiveWatchConnectivityManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateConnectionStatus()
            
            if let error = error {
                self.addTestResult(name: "Session Activation", success: false, message: error.localizedDescription)
            } else {
                self.addTestResult(name: "Session Activation", success: activationState == .activated, message: "State: \(activationState.rawValue)")
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.updateConnectionStatus()
            self.addTestResult(name: "Reachability Change", success: session.isReachable, message: "Reachable: \(session.isReachable)")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            self.messagesReceived += 1
            self.lastMessageReceived = "Received: \(message["type"] as? String ?? "unknown")"
            
            // Send acknowledgment
            replyHandler([
                "status": "received",
                "timestamp": Date().timeIntervalSince1970,
                "echo": message
            ])
            
            self.addTestResult(name: "Message Received", success: true, message: "Type: \(message["type"] as? String ?? "unknown")")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            self.messagesReceived += 1
            self.lastMessageReceived = "Background data: \(userInfo["type"] as? String ?? "unknown")"
            self.addTestResult(name: "Background Data Received", success: true, message: "Type: \(userInfo["type"] as? String ?? "unknown")")
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.updateConnectionStatus()
            self.addTestResult(name: "Session State", success: false, message: "Session became inactive")
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.updateConnectionStatus()
            self.addTestResult(name: "Session State", success: false, message: "Session deactivated")
        }
    }
    #endif
}

// MARK: - Supporting Models

struct ConnectivityTestResult: Identifiable, Codable {
    let id: UUID
    let testName: String
    let success: Bool
    let message: String
    let timestamp: Date
}

enum ConnectivityError: LocalizedError {
    case timeout
    case notReachable
    case sessionNotActivated
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Operation timed out"
        case .notReachable:
            return "Watch not reachable"
        case .sessionNotActivated:
            return "Session not activated"
        }
    }
}

#endif
