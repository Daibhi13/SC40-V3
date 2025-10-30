import Foundation
import WatchConnectivity
import Combine

// MARK: - Watch-side Connectivity Manager
// Simplified version for watch app - focuses on receiving data from iPhone
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var trainingSessionsSynced = false
    @Published var lastSyncDate: Date?
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("❌ WatchConnectivity not supported on this device")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("🔗 WatchConnectivityManager initialized")
    }
    
    // MARK: - Public Methods
    func requestTrainingData() {
        guard let session = session, session.isReachable else {
            print("⚠️ iPhone not reachable")
            return
        }
        
        let message: [String: Any] = [
            "action": "requestTrainingData",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleTrainingDataResponse(reply)
            }
        }) { error in
            print("❌ Failed to request training data: \(error.localizedDescription)")
        }
    }
    
    private func handleTrainingDataResponse(_ response: [String: Any]) {
        if let success = response["success"] as? Bool, success {
            trainingSessionsSynced = true
            lastSyncDate = Date()
            print("✅ Training data received successfully")
        } else {
            print("❌ Failed to receive training data")
        }
    }
    
    // MARK: - Sync Status
    func checkSyncStatus() -> Bool {
        // Check if we have recent sync data
        guard let lastSync = lastSyncDate else { return false }
        
        // Consider data fresh if synced within last 24 hours
        let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return lastSync > dayAgo && trainingSessionsSynced
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = (activationState == .activated)
            
            if let error = error {
                print("❌ WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("✅ WCSession activated with state: \(activationState.rawValue)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.handleApplicationContext(applicationContext)
        }
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        print("📱 Received message from iPhone: \(message)")
        
        if let action = message["action"] as? String {
            switch action {
            case "trainingDataSync":
                trainingSessionsSynced = true
                lastSyncDate = Date()
                print("✅ Training data synced from iPhone")
                
            case "connectivityTest":
                print("🔗 Connectivity test received")
                
            default:
                print("⚠️ Unknown action: \(action)")
            }
        }
    }
    
    private func handleApplicationContext(_ context: [String: Any]) {
        print("📱 Received application context: \(context)")
        
        if let syncStatus = context["trainingDataSynced"] as? Bool {
            trainingSessionsSynced = syncStatus
            if syncStatus {
                lastSyncDate = Date()
            }
        }
    }
}
