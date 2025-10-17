import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch Session Manager
class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isReachable = false
    @Published var isPaired = false
    @Published var receivedMessage: [String: Any]?
    @Published var lastError: String?
    
    private let session = WCSession.default
    
    static let shared = WatchSessionManager()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Session State
    var isSessionActive: Bool {
        return session.activationState == .activated
    }
    
    // MARK: - Message Sending
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard isSessionActive && session.isReachable else {
            lastError = "Watch is not reachable"
            return
        }
        
        session.sendMessage(message, replyHandler: replyHandler) { error in
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Training Session Sending
    func sendTrainingSessions(_ sessions: [TrainingSession]) {
        let message: [String: Any] = ["type": "trainingSessions", "sessions": sessions.map { $0.id.uuidString }]
        sendMessage(message)
    }
    
    // MARK: - Workout Control Messages
    func sendStartWorkoutMessage(sessionType: String, targetDistance: Double) {
        let message = [
            "action": "startWorkout",
            "sessionType": sessionType,
            "targetDistance": targetDistance,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    func sendPauseWorkoutMessage() {
        let message = [
            "action": "pauseWorkout",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    func sendResumeWorkoutMessage() {
        let message = [
            "action": "resumeWorkout",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    func sendEndWorkoutMessage(totalDistance: Double, totalTime: TimeInterval) {
        let message = [
            "action": "endWorkout",
            "totalDistance": totalDistance,
            "totalTime": totalTime,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    // MARK: - Real-time Data Messages
    func sendHeartRateUpdate(_ heartRate: Double) {
        let message = [
            "action": "heartRateUpdate",
            "heartRate": heartRate,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    func sendLocationUpdate(latitude: Double, longitude: Double, speed: Double) {
        let message = [
            "action": "locationUpdate",
            "latitude": latitude,
            "longitude": longitude,
            "speed": speed,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    func sendWorkoutProgress(currentDistance: Double, elapsedTime: TimeInterval, currentSet: Int, totalSets: Int) {
        let message = [
            "action": "workoutProgress",
            "currentDistance": currentDistance,
            "elapsedTime": elapsedTime,
            "currentSet": currentSet,
            "totalSets": totalSets,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    // MARK: - Audio Cue Control
    func sendAudioCueMessage(cue: String, type: String) {
        let message = [
            "action": "audioCue",
            "cue": cue,
            "type": type,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    // MARK: - Haptic Feedback Control
    func sendHapticFeedbackMessage(type: String) {
        let message = [
            "action": "hapticFeedback",
            "type": type,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        sendMessage(message)
    }
    
    // MARK: - Application Context
    func updateApplicationContext(_ context: [String: Any]) {
        guard isSessionActive else { return }
        
        do {
            try session.updateApplicationContext(context)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    // MARK: - User Info Transfer
    func transferUserInfo(_ userInfo: [String: Any]) {
        guard isSessionActive else { return }
        
        session.transferUserInfo(userInfo)
    }
    
    // MARK: - File Transfer
    func transferFile(_ fileURL: URL, metadata: [String: Any]? = nil) {
        guard isSessionActive else { return }
        
        session.transferFile(fileURL, metadata: metadata)
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.lastError = error.localizedDescription
            }
            
            self.isReachable = session.isReachable
            self.isPaired = session.isPaired
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedMessage = message
            self.handleReceivedMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.receivedMessage = message
            self.handleReceivedMessage(message, replyHandler: replyHandler)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedMessage = applicationContext
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedMessage = userInfo
        }
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
            }
        }
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
            // Reactivate session
            WCSession.default.activate()
        }
    }
    
    // MARK: - Message Handling
    private func handleReceivedMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let action = message["action"] as? String else { return }
        
        switch action {
        case "workoutStart":
            // Watch started a workout
            break
        case "workoutPause":
            // Watch paused workout
            break
        case "workoutResume":
            // Watch resumed workout
            break
        case "workoutEnd":
            // Watch ended workout
            break
        case "heartRate":
            if let heartRate = message["heartRate"] as? Double {
                // Handle heart rate data from watch
                print("Received heart rate from watch: \(heartRate)")
            }
        case "location":
            if let latitude = message["latitude"] as? Double,
               let longitude = message["longitude"] as? Double,
               let speed = message["speed"] as? Double {
                // Handle location data from watch
                print("Received location from watch: \(latitude), \(longitude), speed: \(speed)")
            }
        default:
            break
        }
        
        // Send acknowledgment if reply handler provided
        if let replyHandler = replyHandler {
            replyHandler(["status": "received"])
        }
    }
}

// MARK: - Watch Communication Helper
extension WatchSessionManager {
    func sendWorkoutCommand(_ command: WorkoutCommand) {
        var message: [String: Any] = ["action": command.rawValue]
        
        switch command {
        case .start:
            message["timestamp"] = Date().timeIntervalSince1970
        case .pause:
            message["timestamp"] = Date().timeIntervalSince1970
        case .resume:
            message["timestamp"] = Date().timeIntervalSince1970
        case .end:
            message["timestamp"] = Date().timeIntervalSince1970
        }
        
        sendMessage(message)
    }
    
    enum WorkoutCommand: String {
        case start, pause, resume, end
    }
}
