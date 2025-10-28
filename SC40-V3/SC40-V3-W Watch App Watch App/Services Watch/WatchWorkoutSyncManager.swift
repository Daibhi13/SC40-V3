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
    
    // MARK: - Enhanced Background Sync Properties
    private var backgroundSyncQueue: [SyncOperation] = []
    private var syncRetryTimer: Timer?
    private let maxRetryAttempts = 3
    private let retryIntervals: [TimeInterval] = [5, 15, 60] // 5s, 15s, 1min
    
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
    
    // MARK: - Rep Data Sync
    
    func sendRepDataToPhone(_ repData: [String: Any]) {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else {
            print("📊 RepLog: iPhone not reachable, queuing rep data")
            // Could queue for later sending
            return
        }
        
        WCSession.default.sendMessage(repData) { reply in
            print("📊 RepLog: Rep data sent successfully - Reply: \(reply)")
        } errorHandler: { error in
            print("❌ RepLog: Failed to send rep data - \(error.localizedDescription)")
        }
        #endif
    }
    
    func sendSessionDataToPhone(_ sessionData: SessionData) {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else {
            print("📊 RepLog: iPhone not reachable, saving session locally")
            return
        }
        
        let sessionMessage: [String: Any] = [
            "type": "session_completed",
            "sessionId": sessionData.id.uuidString,
            "sessionType": sessionData.type,
            "focus": sessionData.focus,
            "week": sessionData.week,
            "day": sessionData.day,
            "startTime": sessionData.startTime.timeIntervalSince1970,
            "endTime": sessionData.endTime?.timeIntervalSince1970 ?? 0,
            "totalTime": sessionData.totalTime,
            "averageTime": sessionData.averageTime,
            "bestTime": sessionData.bestTime,
            "repCount": sessionData.reps.count,
            "reps": sessionData.reps.map { rep in
                [
                    "repNumber": rep.repNumber,
                    "distance": rep.distance,
                    "time": rep.splitTime,
                    "timestamp": rep.gpsTime.timeIntervalSince1970
                ]
            }
        ]
        
        WCSession.default.sendMessage(sessionMessage) { reply in
            print("📊 RepLog: Session data sent successfully")
        } errorHandler: { error in
            print("❌ RepLog: Failed to send session data - \(error.localizedDescription)")
            print("🔄 RepLog: Attempting background transfer as fallback...")
            
            // Use background transfer as fallback for timeout errors
            WCSession.default.transferUserInfo(sessionMessage)
            print("📤 RepLog: Session data queued for background transfer")
        }
        #endif
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

// MARK: - Enhanced Sync Data Models

struct SyncOperation {
    let id: UUID
    let type: SyncOperationType
    let data: Data
    let workoutId: UUID?
    let priority: SyncPriority
    var attempts: Int
    let createdAt: Date
    var lastError: String?
    let completion: (Bool) -> Void
}

enum SyncOperationType: String, CaseIterable {
    case workoutData = "workoutData"
    case workoutState = "workoutState"
    case heartRateData = "heartRateData"
    case gpsData = "gpsData"
}

enum SyncPriority: Int, CaseIterable {
    case low = 1
    case normal = 2
    case high = 3
}

struct SyncQueueStatus {
    let totalItems: Int
    let highPriorityItems: Int
    let normalPriorityItems: Int
    let lowPriorityItems: Int
    let isProcessing: Bool
    let lastSyncTime: Date?
    
    var isEmpty: Bool {
        return totalItems == 0
    }
    
    var statusDescription: String {
        if isEmpty {
            return "Sync queue empty"
        } else if isProcessing {
            return "Syncing \(totalItems) items"
        } else {
            return "\(totalItems) items queued"
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
    
    // MARK: - Enhanced Background Sync System
    
    /// Enhanced sync with retry logic and background queue
    func enhancedSendWorkoutData(_ data: Data, workoutId: UUID, priority: SyncPriority = .normal, completion: @escaping (Bool) -> Void) {
        let operation = SyncOperation(
            id: UUID(),
            type: .workoutData,
            data: data,
            workoutId: workoutId,
            priority: priority,
            attempts: 0,
            createdAt: Date(),
            completion: completion
        )
        
        performSyncOperation(operation)
    }
    
    /// Enhanced state sync with retry logic
    func enhancedSendWatchState(_ state: WatchWorkoutStateSync, priority: SyncPriority = .high, completion: @escaping (Bool) -> Void) {
        guard let data = try? JSONEncoder().encode(state) else {
            completion(false)
            return
        }
        
        let operation = SyncOperation(
            id: UUID(),
            type: .workoutState,
            data: data,
            workoutId: nil,
            priority: priority,
            attempts: 0,
            createdAt: Date(),
            completion: completion
        )
        
        performSyncOperation(operation)
    }
    
    private func performSyncOperation(_ operation: SyncOperation) {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else {
            print("📱 Phone not reachable - adding to background sync queue")
            addToBackgroundQueue(operation)
            operation.completion(false)
            return
        }
        
        print("🔄 Performing sync operation: \(operation.type.rawValue) (attempt \(operation.attempts + 1))")
        
        let message: [String: Any]
        
        switch operation.type {
        case .workoutData:
            message = [
                "type": "workoutData",
                "data": operation.data,
                "workoutId": operation.workoutId?.uuidString ?? "",
                "priority": operation.priority.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .workoutState:
            message = [
                "type": "workoutState",
                "data": operation.data,
                "priority": operation.priority.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .heartRateData:
            message = [
                "type": "heartRateData",
                "data": operation.data,
                "priority": operation.priority.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        case .gpsData:
            message = [
                "type": "gpsData",
                "data": operation.data,
                "priority": operation.priority.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]
        }
        
        WCSession.default.sendMessage(message, replyHandler: { [weak self] response in
            print("✅ Sync operation successful: \(operation.type.rawValue)")
            self?.lastSyncTime = Date()
            operation.completion(true)
            
            // Remove from background queue if it was there
            self?.removeFromBackgroundQueue(operation.id)
            
        }, errorHandler: { [weak self] error in
            print("❌ Sync operation failed: \(operation.type.rawValue) - \(error.localizedDescription)")
            self?.handleSyncFailure(operation, error: error)
        })
        #else
        operation.completion(false)
        #endif
    }
    
    private func handleSyncFailure(_ operation: SyncOperation, error: Error) {
        var updatedOperation = operation
        updatedOperation.attempts += 1
        updatedOperation.lastError = error.localizedDescription
        
        if updatedOperation.attempts < maxRetryAttempts {
            // Schedule retry
            let retryDelay = retryIntervals[min(updatedOperation.attempts - 1, retryIntervals.count - 1)]
            
            print("⏰ Scheduling retry for \(operation.type.rawValue) in \(retryDelay)s (attempt \(updatedOperation.attempts + 1)/\(maxRetryAttempts))")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                self?.performSyncOperation(updatedOperation)
            }
        } else {
            // Max retries reached - add to background queue
            print("❌ Max retries reached for \(operation.type.rawValue) - adding to background queue")
            addToBackgroundQueue(updatedOperation)
            operation.completion(false)
        }
    }
    
    private func addToBackgroundQueue(_ operation: SyncOperation) {
        backgroundSyncQueue.append(operation)
        
        // Sort by priority and creation time
        backgroundSyncQueue.sort { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            return lhs.createdAt < rhs.createdAt
        }
        
        // Limit queue size
        if backgroundSyncQueue.count > 100 {
            backgroundSyncQueue = Array(backgroundSyncQueue.prefix(100))
        }
        
        // Start background sync timer if not already running
        startBackgroundSyncTimer()
        
        print("📦 Added to background sync queue (size: \(backgroundSyncQueue.count))")
    }
    
    private func removeFromBackgroundQueue(_ operationId: UUID) {
        backgroundSyncQueue.removeAll { $0.id == operationId }
    }
    
    private func startBackgroundSyncTimer() {
        guard syncRetryTimer == nil else { return }
        
        print("⏰ Starting background sync timer")
        
        syncRetryTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.processBackgroundSyncQueue()
        }
    }
    
    private func stopBackgroundSyncTimer() {
        syncRetryTimer?.invalidate()
        syncRetryTimer = nil
        print("⏰ Stopped background sync timer")
    }
    
    private func processBackgroundSyncQueue() {
        guard !backgroundSyncQueue.isEmpty else {
            stopBackgroundSyncTimer()
            return
        }
        
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else {
            print("📱 Phone still not reachable - background sync waiting")
            return
        }
        #endif
        
        print("🔄 Processing background sync queue (\(backgroundSyncQueue.count) items)")
        
        // Process high priority items first
        let highPriorityOps = backgroundSyncQueue.filter { $0.priority == .high }
        let normalPriorityOps = backgroundSyncQueue.filter { $0.priority == .normal }
        let lowPriorityOps = backgroundSyncQueue.filter { $0.priority == .low }
        
        let opsToProcess = highPriorityOps + normalPriorityOps + lowPriorityOps
        
        // Process up to 5 operations at a time
        let batchSize = min(5, opsToProcess.count)
        let batch = Array(opsToProcess.prefix(batchSize))
        
        for operation in batch {
            // Reset attempts for background retry
            var retryOperation = operation
            retryOperation.attempts = 0
            
            // Remove from queue before retry
            removeFromBackgroundQueue(operation.id)
            
            // Retry the operation
            performSyncOperation(retryOperation)
        }
    }
    
    /// Get current sync queue status
    func getSyncQueueStatus() -> SyncQueueStatus {
        let highPriority = backgroundSyncQueue.filter { $0.priority == .high }.count
        let normalPriority = backgroundSyncQueue.filter { $0.priority == .normal }.count
        let lowPriority = backgroundSyncQueue.filter { $0.priority == .low }.count
        
        return SyncQueueStatus(
            totalItems: backgroundSyncQueue.count,
            highPriorityItems: highPriority,
            normalPriorityItems: normalPriority,
            lowPriorityItems: lowPriority,
            isProcessing: syncRetryTimer != nil,
            lastSyncTime: lastSyncTime
        )
    }
    
    /// Force process sync queue (manual trigger)
    func forceSyncQueue() {
        print("🔄 Force processing sync queue")
        processBackgroundSyncQueue()
    }
    
    /// Clear sync queue (emergency reset)
    func clearSyncQueue() {
        print("🗑️ Clearing sync queue (\(backgroundSyncQueue.count) items)")
        backgroundSyncQueue.removeAll()
        stopBackgroundSyncTimer()
    }
    
    /// Enhanced heart rate sync with batching
    func syncHeartRateData(_ readings: [HeartRateReading], completion: @escaping (Bool) -> Void) {
        guard let data = try? JSONEncoder().encode(readings) else {
            completion(false)
            return
        }
        
        let operation = SyncOperation(
            id: UUID(),
            type: .heartRateData,
            data: data,
            workoutId: nil,
            priority: .normal,
            attempts: 0,
            createdAt: Date(),
            completion: completion
        )
        
        performSyncOperation(operation)
    }
    
    /// Enhanced GPS data sync with compression
    func syncGPSData(_ locations: [LocationReading], completion: @escaping (Bool) -> Void) {
        // Compress GPS data by removing redundant points
        let compressedLocations = compressGPSData(locations)
        
        guard let data = try? JSONEncoder().encode(compressedLocations) else {
            completion(false)
            return
        }
        
        let operation = SyncOperation(
            id: UUID(),
            type: .gpsData,
            data: data,
            workoutId: nil,
            priority: .low, // GPS data is less critical
            attempts: 0,
            createdAt: Date(),
            completion: completion
        )
        
        performSyncOperation(operation)
    }
    
    private func compressGPSData(_ locations: [LocationReading]) -> [LocationReading] {
        guard locations.count > 10 else { return locations }
        
        // Keep every nth point, but always keep first and last
        let compressionRatio = max(1, locations.count / 50) // Target ~50 points max
        var compressed: [LocationReading] = []
        
        for (index, location) in locations.enumerated() {
            if index == 0 || index == locations.count - 1 || index % compressionRatio == 0 {
                compressed.append(location)
            }
        }
        
        print("📍 Compressed GPS data: \(locations.count) → \(compressed.count) points")
        return compressed
    }
}
