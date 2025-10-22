import Foundation
import WatchConnectivity
import Combine

// MARK: - Workout Synchronization Manager
/// Manages real-time synchronization between iPhone MainProgramWorkoutView and Apple Watch Enhanced7StageWorkoutView
class WorkoutSyncManager: NSObject, ObservableObject {
    static let shared = WorkoutSyncManager()
    
    @Published var isWatchConnected = false
    @Published var syncStatus: SyncStatus = .idle
    
    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Watch Connectivity Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("❌ WatchConnectivity not supported on this device")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("🔄 WorkoutSyncManager initialized - Watch connectivity activated")
    }
    
    // MARK: - Sync Workout State
    
    func syncWorkoutState(_ state: WorkoutSyncState) {
        guard let session = session, session.isReachable else {
            print("⚠️ Watch not reachable for sync")
            return
        }
        
        syncStatus = .syncing
        
        do {
            let data = try JSONEncoder().encode(state)
            let message = ["workoutState": data]
            
            session.sendMessage(message, replyHandler: { response in
                DispatchQueue.main.async {
                    self.syncStatus = .success
                    print("✅ Workout state synced successfully to Apple Watch")
                }
            }, errorHandler: { error in
                DispatchQueue.main.async {
                    self.syncStatus = .error(error.localizedDescription)
                    print("❌ Failed to sync workout state: \(error.localizedDescription)")
                }
            })
            
        } catch {
            syncStatus = .error("Failed to encode workout state")
            print("❌ Failed to encode workout state: \(error)")
        }
    }
    
    // MARK: - Sync UI Configuration
    
    func syncUIConfiguration(_ config: UIConfigurationSync) {
        guard let session = session, session.isReachable else {
            print("⚠️ Watch not reachable for UI config sync")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(config)
            let message = ["uiConfig": data]
            
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("❌ Failed to sync UI configuration: \(error.localizedDescription)")
            })
            
            print("🎨 UI configuration synced to Apple Watch")
            
        } catch {
            print("❌ Failed to encode UI configuration: \(error)")
        }
    }
    
    // MARK: - Sync Coaching Preferences
    
    func syncCoachingPreferences(_ preferences: CoachingPreferencesSync) {
        guard let session = session, session.isReachable else {
            print("⚠️ Watch not reachable for coaching preferences sync")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(preferences)
            let message = ["coachingPreferences": data]
            
            session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("❌ Failed to sync coaching preferences: \(error.localizedDescription)")
            })
            
            print("🗣️ Coaching preferences synced to Apple Watch")
            
        } catch {
            print("❌ Failed to encode coaching preferences: \(error)")
        }
    }
    
    // MARK: - Sync Session Data
    
    func syncSessionData(_ sessionData: SessionDataSync) {
        guard let session = session else { return }
        
        do {
            let data = try JSONEncoder().encode(sessionData)
            
            // Use application context for persistent data that doesn't need immediate delivery
            try session.updateApplicationContext(["sessionData": data])
            
            print("📊 Session data synced to Apple Watch via application context")
            
        } catch {
            print("❌ Failed to sync session data: \(error)")
        }
    }
    
    // MARK: - Real-time Metrics Sync
    
    func syncLiveMetrics(_ metrics: LiveMetricsSync) {
        guard let session = session, session.isReachable else { return }
        
        // Use high-frequency data transfer for live metrics
        do {
            let data = try JSONEncoder().encode(metrics)
            let message = ["liveMetrics": data]
            
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            
        } catch {
            print("❌ Failed to sync live metrics: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate Implementation

extension WorkoutSyncManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = (activationState == .activated)
            
            if let error = error {
                print("❌ Watch session activation failed: \(error.localizedDescription)")
            } else {
                print("✅ Watch session activated successfully")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
        print("⚠️ Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
        print("⚠️ Watch session deactivated")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
        }
        print("🔄 Watch reachability changed: \(session.isReachable)")
    }
    
    // Handle messages from Apple Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        if let _ = message["requestSync"] {
            // Apple Watch is requesting a full sync
            print("📱 Apple Watch requested full sync")
            replyHandler(["syncRequested": true])
            
            // Trigger full sync from iPhone
            NotificationCenter.default.post(name: .watchRequestedSync, object: nil)
        }
        
        if let watchStateData = message["watchWorkoutState"] as? Data {
            // Handle workout state updates from Apple Watch
            do {
                let watchState = try JSONDecoder().decode(WatchWorkoutStateSync.self, from: watchStateData)
                
                DispatchQueue.main.async {
                    // Update iPhone UI based on watch state
                    NotificationCenter.default.post(
                        name: .watchWorkoutStateChanged,
                        object: watchState
                    )
                }
                
                replyHandler(["received": true])
                
            } catch {
                print("❌ Failed to decode watch workout state: \(error)")
                replyHandler(["error": error.localizedDescription])
            }
        }
    }
}

// MARK: - Sync Data Models

struct WorkoutSyncState: Codable {
    let currentPhase: String
    let phaseTimeRemaining: Int
    let isRunning: Bool
    let isPaused: Bool
    let currentRep: Int
    let totalReps: Int
    let completedReps: [RepDataSync]
    let sessionId: String
    let timestamp: Date
}

struct UIConfigurationSync: Codable {
    let primaryColor: String
    let secondaryColor: String
    let fontScale: Double
    let hapticIntensity: String
    let animationSpeed: Double
    let displayMode: String
    let timestamp: Date
}

struct CoachingPreferencesSync: Codable {
    let isVoiceCoachingEnabled: Bool
    let voiceRate: Double
    let voiceVolume: Double
    let coachingFrequency: String
    let motivationalLevel: String
    let language: String
    let timestamp: Date
}

struct SessionDataSync: Codable {
    let week: Int
    let day: Int
    let sessionName: String
    let sessionFocus: String
    let estimatedDuration: Int
    let sprintSets: [SprintSetSync]
    let drillSets: [DrillSetSync]
    let strideSets: [StrideSetSync]
    let timestamp: Date
}

struct LiveMetricsSync: Codable {
    let distance: Double
    let elapsedTime: TimeInterval
    let currentSpeed: Double
    let heartRate: Int?
    let calories: Int?
    let timestamp: Date
}

struct RepDataSync: Codable {
    let rep: Int
    let time: Double?
    let distance: Int
    let isCompleted: Bool
    let repType: String
    let timestamp: Date
}

struct SprintSetSync: Codable {
    let distance: Int
    let restTime: Int
    let targetTime: Double?
    let intensity: String
}

struct DrillSetSync: Codable {
    let name: String
    let duration: Int
    let restTime: Int
    let description: String
}

struct StrideSetSync: Codable {
    let distance: Int
    let restTime: Int
    let intensity: String
}

struct WatchWorkoutStateSync: Codable {
    let currentPhase: String
    let isRunning: Bool
    let isPaused: Bool
    let currentRep: Int
    let requestedAction: String? // "pause", "resume", "next", "complete"
    let timestamp: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchRequestedSync = Notification.Name("watchRequestedSync")
    static let watchWorkoutStateChanged = Notification.Name("watchWorkoutStateChanged")
    static let phoneWorkoutStateChanged = Notification.Name("phoneWorkoutStateChanged")
    static let uiConfigurationChanged = Notification.Name("uiConfigurationChanged")
    static let coachingPreferencesChanged = Notification.Name("coachingPreferencesChanged")
}
