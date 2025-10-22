import SwiftUI
import Combine
#if os(watchOS)
import WatchConnectivity
#endif

// MARK: - Apple Watch Workout Synchronization Manager
/// Handles synchronization with iPhone MainProgramWorkoutView and auto-adapts Enhanced7StageWorkoutView
class WatchWorkoutSyncManager: NSObject, ObservableObject {
    static let shared = WatchWorkoutSyncManager()
    
    @Published var isPhoneConnected = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    
    // Auto-adaptation properties
    @Published var adaptedWorkoutState: WorkoutSyncState?
    @Published var adaptedUIConfig: UIConfigurationSync?
    @Published var adaptedCoachingPreferences: CoachingPreferencesSync?
    @Published var adaptedSessionData: SessionDataSync?
    @Published var adaptedLiveMetrics: LiveMetricsSync?
    
    // ENHANCED: Pro picker data adaptation
    @Published var adaptedProPickerData: ProPickerDataSync?
    
    #if os(watchOS)
    private var session: WCSession?
    #endif
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
        #if os(watchOS)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        #endif
    }
    
    // MARK: - Request Full Sync from iPhone
    
    func requestFullSyncFromPhone() {
        #if os(watchOS)
        guard let session = session, session.isReachable else {
            print("⚠️ iPhone not reachable for sync request")
            return
        }
        
        let message = ["requestFullSync": true]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("❌ Failed to request sync: \(error.localizedDescription)")
        })
        
        print("📱 Requested full sync from iPhone")
        #endif
    }
    
    // MARK: - Send Watch State to iPhone
    
    func sendWatchStateToPhone(_ watchState: WatchWorkoutStateSync) {
        guard let session = session, session.isReachable else {
            print("⚠️ iPhone not reachable for state sync")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(watchState)
            let message = ["watchWorkoutState": data]
            
            session.sendMessage(message, replyHandler: { response in
                print("✅ Watch state sent to iPhone successfully")
            }, errorHandler: { error in
                print("❌ Failed to send watch state: \(error.localizedDescription)")
            })
            
        } catch {
            print("❌ Failed to encode watch state: \(error)")
        }
    }
    
    // MARK: - Auto-Adaptation Methods
    
    private func adaptWorkoutState(_ state: WorkoutSyncState) {
        DispatchQueue.main.async {
            self.adaptedWorkoutState = state
            
            // Trigger UI adaptation
            NotificationCenter.default.post(
                name: .workoutStateAdapted,
                object: state
            )
            
            print("🔄 Workout state adapted from iPhone")
        }
    }
    
    private func adaptUIConfiguration(_ config: UIConfigurationSync) {
        DispatchQueue.main.async {
            self.adaptedUIConfig = config
            
            // Trigger UI reconfiguration
            NotificationCenter.default.post(
                name: .uiConfigurationAdapted,
                object: config
            )
            
            print("🎨 UI configuration adapted from iPhone")
        }
    }
    
    private func adaptCoachingPreferences(_ preferences: CoachingPreferencesSync) {
        DispatchQueue.main.async {
            self.adaptedCoachingPreferences = preferences
            
            // Trigger coaching system update
            NotificationCenter.default.post(
                name: .coachingPreferencesAdapted,
                object: preferences
            )
            
            print("🗣️ Coaching preferences adapted from iPhone")
        }
    }
    
    private func adaptSessionData(_ sessionData: SessionDataSync) {
        DispatchQueue.main.async {
            self.adaptedSessionData = sessionData
            
            // Trigger session data update
            NotificationCenter.default.post(
                name: .sessionDataAdapted,
                object: sessionData
            )
            
            print("📊 Session data adapted from iPhone")
        }
    }
    
    private func adaptLiveMetrics(_ metrics: LiveMetricsSync) {
        DispatchQueue.main.async {
            self.adaptedLiveMetrics = metrics
            
            // Trigger live metrics update
            NotificationCenter.default.post(
                name: .liveMetricsAdapted,
                object: metrics
            )
        }
    }
    
    // ENHANCED: Pro picker data adaptation
    private func adaptProPickerData(_ pickerData: ProPickerDataSync) {
        DispatchQueue.main.async {
            self.adaptedProPickerData = pickerData
            
            // Trigger Pro picker data update
            NotificationCenter.default.post(
                name: .proPickerDataAdapted,
                object: pickerData
            )
            
            print("🎯 Pro picker data adapted from iPhone: \(pickerData.selectedDistance)yd x\(pickerData.selectedReps) reps")
        }
    }
    
    // MARK: - Utility Methods
    
    func getAdaptedPhase() -> String? {
        return adaptedWorkoutState?.currentPhase
    }
    
    func getAdaptedVoiceCoachingEnabled() -> Bool {
        return adaptedCoachingPreferences?.isVoiceCoachingEnabled ?? true
    }
    
    func getAdaptedHapticIntensity() -> String {
        return adaptedUIConfig?.hapticIntensity ?? "medium"
    }
    
    func isAutoAdaptationActive() -> Bool {
        return adaptedWorkoutState != nil
    }
}

// MARK: - WCSessionDelegate Implementation

extension WatchWorkoutSyncManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneConnected = (activationState == .activated)
            
            if let error = error {
                print("❌ Watch session activation failed: \(error.localizedDescription)")
            } else {
                print("✅ Watch session activated - Ready for auto-adaptation")
                
                // Request initial sync when connection is established
                self.requestFullSyncFromPhone()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneConnected = session.isReachable
            
            if session.isReachable {
                // Phone became reachable, request sync
                self.requestFullSyncFromPhone()
            }
        }
        print("🔄 iPhone reachability changed: \(session.isReachable)")
    }
    
    // MARK: - Handle Messages from iPhone
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleIncomingMessage(message)
        replyHandler(["received": true])
    }
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        
        // Handle workout state sync
        if let workoutStateData = message["workoutState"] as? Data {
            do {
                let workoutState = try JSONDecoder().decode(WorkoutSyncState.self, from: workoutStateData)
                adaptWorkoutState(workoutState)
            } catch {
                print("❌ Failed to decode workout state: \(error)")
            }
        }
        
        // Handle UI configuration sync
        if let uiConfigData = message["uiConfig"] as? Data {
            do {
                let uiConfig = try JSONDecoder().decode(UIConfigurationSync.self, from: uiConfigData)
                adaptUIConfiguration(uiConfig)
            } catch {
                print("❌ Failed to decode UI configuration: \(error)")
            }
        }
        
        // Handle coaching preferences sync
        if let coachingData = message["coachingPreferences"] as? Data {
            do {
                let coachingPreferences = try JSONDecoder().decode(CoachingPreferencesSync.self, from: coachingData)
                adaptCoachingPreferences(coachingPreferences)
            } catch {
                print("❌ Failed to decode coaching preferences: \(error)")
            }
        }
        
        // Handle live metrics sync
        if let metricsData = message["liveMetrics"] as? Data {
            do {
                let liveMetrics = try JSONDecoder().decode(LiveMetricsSync.self, from: metricsData)
                adaptLiveMetrics(liveMetrics)
            } catch {
                print("❌ Failed to decode live metrics: \(error)")
            }
        }
        
        // ENHANCED: Handle Pro picker data sync
        if let proPickerData = message["proPickerData"] as? Data {
            do {
                let pickerData = try JSONDecoder().decode(ProPickerDataSync.self, from: proPickerData)
                adaptProPickerData(pickerData)
            } catch {
                print("❌ Failed to decode Pro picker data: \(error)")
            }
        }
    }
    
    // Handle application context updates (persistent data)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        if let sessionDataData = applicationContext["sessionData"] as? Data {
            do {
                let sessionData = try JSONDecoder().decode(SessionDataSync.self, from: sessionDataData)
                adaptSessionData(sessionData)
            } catch {
                print("❌ Failed to decode session data from application context: \(error)")
            }
        }
    }
}

// MARK: - Auto-Adaptation Notification Names

extension Notification.Name {
    static let workoutStateAdapted = Notification.Name("workoutStateAdapted")
    static let uiConfigurationAdapted = Notification.Name("uiConfigurationAdapted")
    static let coachingPreferencesAdapted = Notification.Name("coachingPreferencesAdapted")
    static let sessionDataAdapted = Notification.Name("sessionDataAdapted")
    static let liveMetricsAdapted = Notification.Name("liveMetricsAdapted")
    
    // ENHANCED: Pro picker data adaptation
    static let proPickerDataAdapted = Notification.Name("proPickerDataAdapted")
}

// MARK: - Auto-Adaptation Helper Extensions

extension WatchWorkoutSyncManager {
    
    /// Creates a watch workout state sync object for sending to iPhone
    func createWatchStateSync(
        currentPhase: String,
        isRunning: Bool,
        isPaused: Bool,
        currentRep: Int,
        requestedAction: String? = nil
    ) -> WatchWorkoutStateSync {
        
        return WatchWorkoutStateSync(
            currentPhase: currentPhase,
            isRunning: isRunning,
            isPaused: isPaused,
            currentRep: currentRep,
            requestedAction: requestedAction,
            timestamp: Date()
        )
    }
    
    /// Checks if the watch should auto-adapt to iPhone changes
    func shouldAutoAdapt() -> Bool {
        return isPhoneConnected && adaptedWorkoutState != nil
    }
    
    /// Gets the time since last successful sync
    func timeSinceLastSync() -> TimeInterval? {
        guard let lastSync = lastSyncTime else { return nil }
        return Date().timeIntervalSince(lastSync)
    }
}
