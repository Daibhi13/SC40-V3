import Foundation
@preconcurrency import WatchConnectivity
import WatchKit
import OSLog
import Combine

// ROBUST SYNC: Import Logger if not available
#if !canImport(OSLog)
struct Logger {
    let subsystem: String
    let category: String
    
    func info(_ message: String) {
        print("ℹ️ [\(category)] \(message)")
    }
    
    func warning(_ message: String) {
        print("⚠️ [\(category)] \(message)")
    }
    
    func error(_ message: String) {
        print("❌ [\(category)] \(message)")
    }
}
#endif

// Global logger accessible from nonisolated contexts - made nonisolated
@MainActor
let watchConnectivityLogger = Logger(subsystem: "com.accelerate.sc40", category: "WatchConnectivity")

// MARK: - SyncableTrainingSession
enum SyncState: Codable {
    case pending
    case syncing
    case synced
    case failed
}

struct SyncableTrainingSession: Codable {
    let session: TrainingSession
    var syncState: SyncState
    var lastSyncAttempt: Date?
    var syncRetryCount: Int
    
    init(from session: TrainingSession) {
        self.session = session
        self.syncState = .pending
        self.lastSyncAttempt = nil
        self.syncRetryCount = 0
    }
    
    func toTrainingSession() -> TrainingSession {
        return session
    }
}

// MARK: - Background Task Manager Stub
class WatchConnectivityBackgroundTaskManager: @unchecked Sendable {
    static let shared = WatchConnectivityBackgroundTaskManager()
    
    func handleDataProcessingComplete() {
        // Stub implementation
    }
    
    func handleSessionStateChange(_ session: WCSession) {
        // Stub implementation
    }
}

// MARK: - Test Mode Support
#if DEBUG
/// Thread-safe test mode flag
@MainActor var isWatchTestMode: Bool {
    get { UserDefaults.standard.bool(forKey: "isWatchTestMode") }
    set { UserDefaults.standard.set(newValue, forKey: "isWatchTestMode") }
}
#else
/// Always false in release builds
@MainActor var isWatchTestMode = false
#endif

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

@MainActor
class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchSessionManager()
    
    var objectWillChange = ObservableObjectPublisher()
    
    // ROBUST SYNC: Published properties for UI compatibility
    @Published var receivedData: [String: Any] = [:]
    @Published var trainingSessions: [TrainingSession] = []
    @Published var currentWorkoutSession: TrainingSession? = nil
    
    // ROBUST SYNC: New sync-aware properties
    @Published var syncStatus: String = "Ready"
    @Published var syncProgress: Double = 0.0
    @Published var needsSync: Bool = false
    @Published var isPhoneConnected = false
    @Published var isPhoneReachable = false
    @Published var connectionError: String?
    @Published var lastSyncTime: Date?
    @Published var sessionVersion: String = "1.0" // Track session version for updates
    
    // ROBUST SYNC: Core sync components
    private var syncableSessions: [SyncableTrainingSession] = []
    private var syncToken: String = ""
    private var deviceId: String = ""
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "WatchConnectivity")
    private var heartbeatTimer: Timer?
    private var sessionRequestTimer: Timer?
    private var pendingWorkoutResults: [[String: Any]] = []
    private var sessionRequestRetryCount = 0
    private let maxRetryAttempts = 3
    private var lastRetryTime: Date?
    
    private override init() {
        super.init()
        
        // ROBUST SYNC: Initialize sync components
        setupRobustSync()
        loadStoredSessions()
        _ = checkOnboardingData()
        
        // PRIORITY 1: Load stored sessions with sync state (instant access)
        loadStoredSessionsWithSync()

        // PRIORITY 2: Generate UX fallback if no sessions (instant backup)
        if self.trainingSessions.isEmpty {
            logger.info("⚡ Generating UX fallback sessions for instant access")
            self.generateUXFallbackSessions()
        } else {
            logger.info("📱 \(self.trainingSessions.count) stored sessions available")
        }

        // PRIORITY 3: Activate connectivity with robust sync
        activateSessionWithRobustSync()

        // PRIORITY 4: Initiate background sync (non-blocking)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.initiateRobustSync()
        }
        
        startHeartbeat()
    }
    
    func activateSession() {
        // Skip activation in test mode
        guard !isWatchTestMode else {
            logger.info("Test mode active - WatchConnectivity disabled")
            return
        }
        
        guard WCSession.isSupported() else {
            logger.error("WatchConnectivity is not supported on this device")
            self.connectionError = "WatchConnectivity not supported"
            return
        }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        logger.info("WatchConnectivity session activation requested")
    }
    
    func loadStoredSessions() {
        self.trainingSessions = ProgramPersistence.loadSessions()
        logger.info("Loaded \(self.trainingSessions.count) stored training sessions")
        
        if !self.trainingSessions.isEmpty {
            let weekCount = Set(self.trainingSessions.map { $0.week }).count
            let completedCount = self.trainingSessions.filter { $0.isCompleted }.count
            logger.info("Program: \(weekCount) weeks, \(completedCount) completed sessions")
        }
    }
    
    // Check if user has completed onboarding on iPhone
    func checkOnboardingData() -> Bool {
        // Check for essential onboarding data
        let hasName = !UserDefaults.standard.string(forKey: "userName").isNilOrEmpty
        let hasPB = UserDefaults.standard.double(forKey: "personalBest") > 0
        let hasLevel = !UserDefaults.standard.string(forKey: "userLevel").isNilOrEmpty
        
        if !hasName || !hasPB || !hasLevel {
            logger.info("Onboarding check - Name: \(hasName), PB: \(hasPB), Level: \(hasLevel)")
            logger.info("No onboarding data found - user needs to complete setup on iPhone")
            DispatchQueue.main.async {
                self.trainingSessions = []
                self.connectionError = "Complete setup on iPhone first"
            }
            return false
        }
        
        logger.info("Creating fallback sessions with user's onboarding data")
        
        // Get user's personal best and level for appropriate sessions
        let userPB = UserDefaults.standard.double(forKey: "personalBest")
        let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Beginner"
        
        let fallbackSessions = createSessionsBasedOnUserData(pb: userPB, level: userLevel)
        
        DispatchQueue.main.async {
            self.trainingSessions = fallbackSessions
            self.connectionError = "Using offline sessions - iPhone app not available"
        }
        
        // Store fallback sessions locally
        ProgramPersistence.shared.saveProgram(fallbackSessions)
        return true
    }
    
    
    func createSessionsBasedOnUserData(pb: Double, level: String) -> [TrainingSession] {
        // Always include Time Trial
        var sessions = [
            TrainingSession(
                week: 0,
                day: 0,
                type: "Time Trial",
                focus: "Performance Test",
                sprints: [SprintSet(distanceYards: 40, reps: 1, intensity: "max")],
                accessoryWork: []
            )
        ]
        
        // Create level-appropriate sessions
        switch level.lowercased() {
        case "beginner":
            sessions.append(contentsOf: [
                TrainingSession(
                    week: 1, day: 1, type: "Speed Development", focus: "Acceleration",
                    sprints: [SprintSet(distanceYards: 20, reps: 3, intensity: "max")],
                    accessoryWork: ["Dynamic Warm-up", "Cool-down Stretching"]
                ),
                TrainingSession(
                    week: 1, day: 2, type: "Speed Endurance", focus: "Basic Conditioning",
                    sprints: [SprintSet(distanceYards: 30, reps: 2, intensity: "submax")],
                    accessoryWork: ["Core Strengthening"]
                )
            ])
        case "intermediate":
            sessions.append(contentsOf: [
                TrainingSession(
                    week: 1, day: 1, type: "Speed Development", focus: "Acceleration",
                    sprints: [SprintSet(distanceYards: 20, reps: 4, intensity: "max")],
                    accessoryWork: ["Plyometrics", "Dynamic Warm-up"]
                ),
                TrainingSession(
                    week: 1, day: 2, type: "Speed Endurance", focus: "Lactate Tolerance",
                    sprints: [SprintSet(distanceYards: 30, reps: 3, intensity: "max")],
                    accessoryWork: ["Recovery Stretching"]
                )
            ])
        case "advanced":
            sessions.append(contentsOf: [
                TrainingSession(
                    week: 1, day: 1, type: "Speed Development", focus: "Max Velocity",
                    sprints: [SprintSet(distanceYards: 20, reps: 5, intensity: "max")],
                    accessoryWork: ["Advanced Plyometrics", "Speed Mechanics"]
                ),
                TrainingSession(
                    week: 1, day: 2, type: "Speed Endurance", focus: "Power Endurance",
                    sprints: [
                        SprintSet(distanceYards: 40, reps: 1, intensity: "max"),
                        SprintSet(distanceYards: 30, reps: 2, intensity: "max"),
                        SprintSet(distanceYards: 20, reps: 1, intensity: "max")
                    ],
                    accessoryWork: ["Recovery Protocol"]
                )
            ])
        default:
            // Default to intermediate
            sessions.append(contentsOf: [
                TrainingSession(
                    week: 1, day: 1, type: "Speed Development", focus: "Acceleration",
                    sprints: [SprintSet(distanceYards: 20, reps: 4, intensity: "max")],
                    accessoryWork: ["Dynamic Warm-up"]
                ),
                TrainingSession(
                    week: 1, day: 2, type: "Speed Endurance", focus: "Lactate Tolerance",
                    sprints: [SprintSet(distanceYards: 30, reps: 3, intensity: "max")],
                    accessoryWork: ["Recovery Stretching"]
                )
            ])
        }
        
        return sessions
    }
    
    func startHeartbeat() {
        // Send heartbeat to iPhone every 30 seconds to maintain connection
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            // Timer runs on main thread, but we need explicit MainActor context for Swift 6
            Task { @MainActor in
                guard let self = self else { return }
                // Heartbeat logic here - using weak self properly
                await self.sendHeartbeat()
                await self.uploadPendingResults()
            }
        }
    }
    
    // MARK: - Enhanced Communication Methods
    
    @MainActor
    func sendHeartbeat() async {
        // Don't send heartbeat if companion app is not installed
        guard WCSession.default.isReachable,
              connectionError?.contains("not installed") != true else { 
            return 
        }
        
        let heartbeatMessage: [String: Any] = [
            "action": "heartbeat",
            "timestamp": Date().timeIntervalSince1970,
            "sessionCount": self.trainingSessions.count,
            "batteryLevel": getBatteryLevel()
        ]
        
        send(message: heartbeatMessage)
    }
    
    func getBatteryLevel() -> Float {
        return WKInterfaceDevice.current().batteryLevel
    }
    
    func send(message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            logger.warning("WCSession not activated, cannot send message")
            return
        }
        
        // Create a sendable copy of the message to avoid data races
        let sendableMessage = message
        
        if session.isReachable {
            session.sendMessage(sendableMessage, replyHandler: replyHandler, errorHandler: { [weak self] error in
                guard let self = self else { return }
                
                self.logger.error("Failed to send message to iPhone: \(error.localizedDescription)")
                
                // Handle specific error codes
                if let wcError = error as? WCError {
                    switch wcError.code {
                    case .sessionNotSupported:
                        DispatchQueue.main.async {
                            self.connectionError = "WatchConnectivity not supported"
                            self.isPhoneConnected = false
                            self.isPhoneReachable = false
                        }
                    case .sessionNotActivated:
                        DispatchQueue.main.async {
                            self.connectionError = "Session not activated"
                        }
                    case .deviceNotPaired:
                        DispatchQueue.main.async {
                            self.connectionError = "iPhone not paired"
                            self.isPhoneConnected = false
                        }
                    case .watchAppNotInstalled:
                        DispatchQueue.main.async {
                            self.connectionError = "Companion app not installed"
                            self.isPhoneConnected = false
                            self.isPhoneReachable = false
                            // Stop retry attempts when companion app is not installed
                            self.sessionRequestTimer?.invalidate()
                            self.sessionRequestRetryCount = self.maxRetryAttempts
                        }
                    case .companionAppNotInstalled:
                        DispatchQueue.main.async {
                            self.connectionError = "iPhone app not installed"
                            self.isPhoneConnected = false
                            self.isPhoneReachable = false
                            // Stop retry attempts when companion app is not installed
                            self.sessionRequestTimer?.invalidate()
                            self.sessionRequestRetryCount = self.maxRetryAttempts
                        }
                    default:
                        DispatchQueue.main.async {
                            self.connectionError = error.localizedDescription
                        }
                    }
                }
            })
        } else {
            logger.warning("iPhone not reachable, message not sent")
            DispatchQueue.main.async {
                self.connectionError = "iPhone not reachable"
            }
        }
    }
    
    // Request training sessions from iPhone with retry logic
    @MainActor
    func requestTrainingSessions() async {
        // SEAMLESS: Don't retry if we already have sessions (avoid unnecessary requests)
        if !trainingSessions.isEmpty && sessionRequestRetryCount > 0 {
            logger.info("Sessions already available, skipping request")
            return
        }
        
        // Check if we've exceeded retry attempts
        guard sessionRequestRetryCount < maxRetryAttempts else {
            logger.warning("Maximum retry attempts reached, using existing sessions or generating fallback")
            if trainingSessions.isEmpty {
                generateFallbackSessions()
            }
            return
        }
        
        // POLISHED: Shorter retry interval for better responsiveness (10 seconds instead of 30)
        if let lastRetry = lastRetryTime, Date().timeIntervalSince(lastRetry) < 10 {
            logger.warning("Retry attempted too soon, skipping")
            return
        }
        
        // Check if session is properly activated and reachable
        guard WCSession.default.activationState == .activated else {
            logger.warning("WCSession not activated, cannot request sessions")
            DispatchQueue.main.async {
                self.connectionError = "Watch connection not ready"
            }
            return
        }
        
        guard WCSession.default.isReachable else {
            logger.warning("iPhone not reachable, cannot request sessions")
            DispatchQueue.main.async {
                self.connectionError = "iPhone not reachable"
            }
            return
        }
        
        logger.info("Requesting training sessions from iPhone... (attempt \(self.sessionRequestRetryCount + 1)/\(self.maxRetryAttempts))")
        
        let requestMessage: [String: Any] = [
            "action": "requestSessions",
            "timestamp": Date().timeIntervalSince1970,
            "currentSessionCount": trainingSessions.count,
            "forceRefresh": true // Force iPhone to regenerate sessions
        ]
        
        sessionRequestRetryCount += 1
        lastRetryTime = Date()
        
        send(message: requestMessage) { [weak self] reply in
            self?.logger.info("Received reply for session request: \(reply.keys.joined(separator: ", "))")
            // Reset retry count on successful response
            self?.sessionRequestRetryCount = 0
        }
        
        // Set up retry timer in case request fails (only if we haven't exceeded max attempts)
        sessionRequestTimer?.invalidate()
        if sessionRequestRetryCount < maxRetryAttempts {
            sessionRequestTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                // Timer already runs on main thread, no need for Task/@MainActor
                Task { @MainActor in
                    guard let self = self else { return }
                    let noSessions = self.trainingSessions.isEmpty
                    let noInstallError = (self.connectionError?.contains("not installed") != true)
                    if noSessions && noInstallError {
                        self.logger.warning("No sessions received, retrying request...")
                        await self.requestTrainingSessions()
                    }
                }
            }
        }
    }
    
    /// Generate fallback sessions if iPhone sync fails completely - CRITICAL for user experience
    func generateFallbackSessions() {
        logger.warning("🚨 Generating fallback sessions - iPhone sync failed completely")
        
        // C25K Method: Get ACTUAL user profile data from iPhone sync
        let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Beginner" // Default to Beginner, not Intermediate
        let frequency = UserDefaults.standard.integer(forKey: "userFrequency")
        let actualFrequency = frequency > 0 ? frequency : 1 // Default to 1 day/week for safety
        
        logger.info("🎯 Creating fallback sessions for: Level=\(userLevel), Frequency=\(actualFrequency) days/week")
        
        var fallbackSessions: [TrainingSession] = []
        
        // Generate 12 weeks of level-specific and frequency-specific sessions
        for week in 1...12 {
            for day in 1...actualFrequency {
                let session = generateLevelSpecificSession(
                    week: week, 
                    day: day, 
                    level: userLevel, 
                    frequency: actualFrequency
                )
                fallbackSessions.append(session)
            }
        }
        
        // CRITICAL: Always update on main thread and clear errors
        DispatchQueue.main.async {
            self.trainingSessions = fallbackSessions
            self.connectionError = nil // Clear ALL errors since we have sessions
            self.isPhoneReachable = true // Force reachable state
            self.logger.info("✅ Generated \(fallbackSessions.count) comprehensive fallback sessions for \(userLevel) level")
            
            // Mark sessions as fallback-sourced for debugging
            UserDefaults.standard.set("Fallback", forKey: "sessionSource")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastFallbackGeneration")
            
            // 🔊 NOTIFICATION: Play sound and haptic for fallback sessions too
            self.notifySessionsReceived(count: fallbackSessions.count)
            
            // SEAMLESS: Store sync timestamp for smart refresh logic
            self.lastSyncTime = Date()
            
            // Force UI update
            self.objectWillChange.send()
        }
    }
    
    /// Generate level-specific and frequency-specific training session
    func generateLevelSpecificSession(week: Int, day: Int, level: String, frequency: Int) -> TrainingSession {
        // Level-specific parameters
        let (distances, reps, sessionTypes) = getLevelSpecificParameters(level: level, week: week)
        
        // Frequency-specific session distribution
        let sessionType = getFrequencySpecificSessionType(day: day, frequency: frequency, week: week, sessionTypes: sessionTypes)
        
        // Progressive distance selection based on week and day
        let distanceIndex = (week - 1 + day - 1) % distances.count
        let distance = distances[distanceIndex]
        
        // Progressive rep count based on week
        let baseReps = reps[min(week - 1, reps.count - 1)]
        let finalReps = max(1, baseReps + (day - 1)) // Slight variation by day
        
        // Level-specific intensity
        let intensity = getLevelSpecificIntensity(level: level, week: week)
        
        return TrainingSession(
            week: week,
            day: day,
            type: sessionType,
            focus: "\(distance) Yard \(level) Development",
            sprints: [SprintSet(distanceYards: distance, reps: finalReps, intensity: intensity)],
            accessoryWork: getLevelSpecificAccessoryWork(level: level),
            notes: "Fallback session - \(level) level, \(frequency) days/week program"
        )
    }
    
    /// Get level-specific training parameters
    func getLevelSpecificParameters(level: String, week: Int) -> ([Int], [Int], [String]) {
        switch level.lowercased() {
        case "beginner":
            let distances = [20, 30, 40] // Shorter distances for beginners
            let reps = [2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7] // Progressive 2-7 reps over 12 weeks
            let sessionTypes = ["Sprint Training", "Acceleration Work", "Speed Development"]
            return (distances, reps, sessionTypes)
            
        case "intermediate":
            let distances = [20, 30, 40, 50] // Medium distances
            let reps = [3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8] // Progressive 3-8 reps
            let sessionTypes = ["Sprint Training", "Acceleration Work", "Speed Development", "Flying Runs"]
            return (distances, reps, sessionTypes)
            
        case "advanced":
            let distances = [30, 40, 50, 60] // Longer distances
            let reps = [4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9] // Progressive 4-9 reps
            let sessionTypes = ["Sprint Training", "Speed Development", "Flying Runs", "Max Velocity"]
            return (distances, reps, sessionTypes)
            
        case "elite":
            let distances = [40, 50, 60, 75] // Elite distances
            let reps = [5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10] // Progressive 5-10 reps
            let sessionTypes = ["Speed Development", "Flying Runs", "Max Velocity", "Competition Prep"]
            return (distances, reps, sessionTypes)
            
        default:
            // Default to beginner for safety
            let distances = [20, 30, 40]
            let reps = [2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7]
            let sessionTypes = ["Sprint Training", "Acceleration Work", "Speed Development"]
            return (distances, reps, sessionTypes)
        }
    }
    
    /// Get frequency-specific session type distribution
    func getFrequencySpecificSessionType(day: Int, frequency: Int, week: Int, sessionTypes: [String]) -> String {
        switch frequency {
        case 1:
            // 1 day/week: Focus on comprehensive training
            return sessionTypes[0] // Always primary session type
            
        case 2:
            // 2 days/week: Alternate between speed and technique
            return day == 1 ? sessionTypes[0] : sessionTypes[1]
            
        case 3:
            // 3 days/week: Speed, technique, development
            let typeIndex = (day - 1) % sessionTypes.count
            return sessionTypes[typeIndex]
            
        default:
            return sessionTypes[0]
        }
    }
    
    /// Get level-specific intensity
    func getLevelSpecificIntensity(level: String, week: Int) -> String {
        switch level.lowercased() {
        case "beginner":
            return week <= 4 ? "80%" : week <= 8 ? "85%" : "90%"
        case "intermediate":
            return week <= 4 ? "85%" : week <= 8 ? "90%" : "95%"
        case "advanced", "elite":
            return week <= 4 ? "90%" : week <= 8 ? "95%" : "Max"
        default:
            return "80%"
        }
    }
    
    /// Get level-specific accessory work
    func getLevelSpecificAccessoryWork(level: String) -> [String] {
        switch level.lowercased() {
        case "beginner":
            return ["Dynamic Warm-up", "Basic Cool-down", "Flexibility Work"]
        case "intermediate":
            return ["Dynamic Warm-up", "Activation Drills", "Cool-down", "Mobility Work"]
        case "advanced":
            return ["Dynamic Warm-up", "Activation Drills", "Technical Drills", "Recovery Work", "Strength Maintenance"]
        case "elite":
            return ["Dynamic Warm-up", "CNS Activation", "Technical Drills", "Recovery Protocols", "Strength Maintenance", "Competition Prep"]
        default:
            return ["Dynamic Warm-up", "Cool-down", "Flexibility Work"]
        }
    }
    
    // Send workout results with offline queuing
    func sendWorkoutResults(_ results: [String: Any]) {
        logger.info("Sending workout results to iPhone")
        
        var enhancedResults = results
        enhancedResults["timestamp"] = Date().timeIntervalSince1970
        enhancedResults["source"] = "appleWatch"
        enhancedResults["batteryLevel"] = getBatteryLevel()
        
        if WCSession.default.isReachable {
            send(message: enhancedResults)
        } else {
            // Queue for later if phone not reachable
            pendingWorkoutResults.append(enhancedResults)
            logger.info("iPhone not reachable, queued workout results for later upload")
        }
    }
    
    @MainActor
    func uploadPendingResults() async {
        guard WCSession.default.isReachable, !self.pendingWorkoutResults.isEmpty else { return }
        
        logger.info("Uploading \(self.pendingWorkoutResults.count) pending workout results")
        
        for result in self.pendingWorkoutResults {
            send(message: result)
        }
        
        self.pendingWorkoutResults.removeAll()
    }
    
    // Set the current workout session for the active workout with validation
    func setCurrentWorkoutSession(_ session: TrainingSession) {
        logger.info("Setting current workout session: W\(session.week)/D\(session.day) - \(session.type)")
        
        DispatchQueue.main.async {
            self.currentWorkoutSession = session
        }
        
        // Notify iPhone about current session
        let sessionInfo: [String: Any] = [
            "action": "currentSession",
            "week": session.week,
            "day": session.day,
            "type": session.type,
            "focus": session.focus,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        send(message: sessionInfo)
    }
    
    // MARK: - WCSessionDelegate Methods

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        // Capture reachable state before async dispatch
        let isReachable = session.isReachable

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch activationState {
            case .activated:
                self.logger.info("✅ WCSession activated successfully")
                self.isPhoneConnected = isReachable
                self.connectionError = nil

                // Reset retry count on successful activation
                self.sessionRequestRetryCount = 0
                self.lastRetryTime = nil

            case .notActivated:
                self.logger.error("❌ WCSession failed to activate")
                self.connectionError = "Watch connectivity failed"

            case .inactive:
                self.logger.warning("⚠️ WCSession is inactive")
                self.connectionError = "Watch connection inactive"

            @unknown default:
                self.logger.error("❓ Unknown WCSession activation state")
                self.connectionError = "Unknown connection state"
            }

            if let error = error {
                self.logger.error("WCSession activation error: \(error.localizedDescription)")
                self.connectionError = error.localizedDescription
            }

            // Handle background task completion based on session state
            Task { @MainActor in
                WatchConnectivityBackgroundTaskManager.shared.handleSessionStateChange(session)
            }
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Extract all needed values before async dispatch
        let action = message["action"] as? String
        
        // Handle ping messages for connectivity testing
        if action == "ping" {
            let reply: [String: Any] = [
                "status": "pong",
                "deviceType": "Watch",
                "sessionCount": 0, // Will be updated async
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)
            
            // Update connection status on main thread
            Task { @MainActor in
                self.isPhoneConnected = true
                self.isPhoneReachable = true
                self.connectionError = nil
                self.logger.info("✅ Ping received from iPhone - Connection established")
                
                // Complete background tasks after data processing
                Task { @MainActor in
                    WatchConnectivityBackgroundTaskManager.shared.handleDataProcessingComplete()
                }
            }
            return
        }
        
        // ROBUST SYNC: Handle new sync actions
        if action == "syncTokenExchange" {
            // Handle sync token exchange synchronously to avoid data races
            handleSyncTokenExchangeSync(message: message, replyHandler: replyHandler)
            return
        }
        
        if action == "requestFullSessions" {
            // Handle full session request synchronously to avoid data races
            handleRequestFullSessionsSync(message: message, replyHandler: replyHandler)
            return
        }
        let sessionsData = message["trainingSessions"] as? Data
        let sessionCount = message["sessionCount"] as? Int
        let timestamp = message["timestamp"] as? TimeInterval
        let userLevel = message["userLevel"] as? String
        let frequency = message["frequency"] as? Int
        let userName = message["userName"] as? String
        let personalBest = message["personalBest"] as? Double
        
        // Handle clearData action immediately (no async needed)
        if action == "clearData" {
            Task { @MainActor in
                self.logger.info("Received clearData command - clearing all watch data")
                self.clearAllWatchData()
            }
            
            // Send reply confirming data cleared
            replyHandler(["status": "cleared", "timestamp": Date().timeIntervalSince1970])
            return
        }
        
        // Handle syncSessions action - iPhone sending SessionLibrary sessions
        if action == "syncSessions" {
            // Extract all needed data immediately to avoid data races
            let sessionsData = message["trainingSessions"] as? Data
            let sessionCount = message["sessionCount"] as? Int
            let messageTimestamp = message["timestamp"] as? TimeInterval
            let totalSessions = message["totalSessions"] as? Int ?? 0
            
            // Extract batch info values immediately to avoid data races
            var phase = "Unknown"
            var description = "Unknown"
            if let batchInfo = message["batchInfo"] as? [String: Any] {
                phase = batchInfo["phase"] as? String ?? "Unknown"
                description = batchInfo["description"] as? String ?? "Unknown"
            }
            
            // Send immediate reply
            replyHandler([
                "status": "received",
                "timestamp": Date().timeIntervalSince1970
            ])
            
            // Process sessions asynchronously
            Task { @MainActor in
                self.logger.info("📱 Received syncSessions from iPhone")
                
                // Log batch information using extracted values
                let batchSessionCount = sessionCount ?? 0
                self.logger.info("📦 Batch received: \(phase) - \(description)")
                self.logger.info("📦 Sessions: \(batchSessionCount)/\(totalSessions)")
                
                if let sessionsData = sessionsData {
                    self.processingSessionsDataSafely(sessionsData, sessionCount: sessionCount, timestamp: messageTimestamp)
                } else {
                    self.logger.error("❌ No sessions data in syncSessions message")
                }
            }
            return
        }
        
        // Handle establishSync action - iPhone confirming active communication
        if action == "establishSync" {
            // Send basic reply immediately, get session count in async task
            replyHandler([
                "status": "syncEstablished",
                "timestamp": Date().timeIntervalSince1970,
                "watchReady": true
            ])
            
            // Update state and log asynchronously
            Task { @MainActor in
                let currentCount = self.trainingSessions.count
                self.logger.info("📱 Sync establishment confirmed with iPhone - Watch has \(currentCount) sessions")
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update connection status
            self.lastSyncTime = Date()
            self.connectionError = nil
            self.isPhoneReachable = true
            
            // Store user metadata
            if let userLevel = userLevel {
                UserDefaults.standard.set(userLevel, forKey: "userLevel")
                self.logger.info("Stored user level: \(userLevel)")
            }
            if let frequency = frequency {
                UserDefaults.standard.set(frequency, forKey: "userFrequency")
                self.logger.info("Stored user frequency: \(frequency)")
            }
            if let userName = userName {
                UserDefaults.standard.set(userName, forKey: "userName")
                self.logger.info("Stored user name: \(userName)")
                // Mark onboarding as complete when we receive user data
                UserDefaults.standard.set(true, forKey: "hasCompletedWatchOnboarding")
                self.logger.info("✅ Marked Watch onboarding as complete")
            }
            if let personalBest = personalBest {
                UserDefaults.standard.set(personalBest, forKey: "personalBest")
                self.logger.info("Stored personal best: \(personalBest)")
            }
            
            // Check if we now have complete onboarding data and can create sessions
            if self.trainingSessions.isEmpty && self.checkOnboardingData() {
                self.logger.info("Onboarding data now complete, creating sessions")
                self.generateFallbackSessions()
            }
            
            // Process sessions data if available
            if let sessionsData = sessionsData {
                self.processingSessionsDataSafely(sessionsData, sessionCount: sessionCount, timestamp: timestamp)
            }
        }
        
        // Handle session distances from iPhone
        if let sessionDistances = message["distances"] as? [Int],
           let sessionName = message["sessionName"] as? String {
            Task { @MainActor in
                watchConnectivityLogger.info("Received session distances for \(sessionName): \(sessionDistances)")
                
                // Store for use during workout
                UserDefaults.standard.set(sessionDistances, forKey: "currentSessionDistances")
                UserDefaults.standard.set(sessionName, forKey: "currentSessionName")
            }
        }
    }
    
    func processingSessionsData(_ sessionsData: Data, from message: [String: Any]) {
        do {
            let sessions = try JSONDecoder().decode([TrainingSession].self, from: sessionsData)
            let sessionCount = message["sessionCount"] as? Int ?? sessions.count
            let _ = message["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
            
            logger.info("Successfully decoded \(sessions.count) training sessions from iPhone")
            
            // Validate data integrity
            guard sessions.count == sessionCount else {
                logger.error("Session count mismatch: expected \(sessionCount), got \(sessions.count)")
                return
            }
            
            DispatchQueue.main.async {
                self.trainingSessions = sessions
                self.syncProgress = 1.0
                
                // Store sessions locally for offline access
                ProgramPersistence.shared.saveProgram(sessions)
                
                // Cancel retry timer since we got sessions
                self.sessionRequestTimer?.invalidate()
                
                self.logger.info("📱 IPHONE SESSIONS RECEIVED: Updated trainingSessions with \(sessions.count) sessions")
                for (index, session) in sessions.prefix(5).enumerated() {
                    self.logger.info("  📱 iPhone Session \(index + 1): W\(session.week)/D\(session.day) - \(session.type) (\(session.focus))")
                }
                
                // Mark sessions as iPhone-sourced for debugging
                UserDefaults.standard.set("iPhone", forKey: "sessionSource")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastIPhoneSync")
                
                // 🔊 NOTIFICATION: Play sound and haptic when sessions are received
                self.notifySessionsReceived(count: sessions.count)
            }
        } catch {
            logger.error("Failed to decode training sessions: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionError = "Failed to sync sessions: \(error.localizedDescription)"
            }
        }
    }
    
    func processingSessionsDataSafely(_ sessionsData: Data, sessionCount: Int?, timestamp: TimeInterval?) {
        do {
            let sessions = try JSONDecoder().decode([TrainingSession].self, from: sessionsData)
            let expectedCount = sessionCount ?? sessions.count
            let _ = timestamp ?? Date().timeIntervalSince1970
            
            logger.info("Successfully decoded \(sessions.count) training sessions from iPhone")
            
            // Validate data integrity
            guard sessions.count == expectedCount else {
                logger.error("Session count mismatch: expected \(expectedCount), got \(sessions.count)")
                return
            }
            
            DispatchQueue.main.async {
                self.trainingSessions = sessions
                self.syncProgress = 1.0
                
                // Store sessions locally for offline access
                ProgramPersistence.shared.saveProgram(sessions)
                
                // Cancel retry timer since we got sessions
                self.sessionRequestTimer?.invalidate()
                
                self.logger.info("Updated trainingSessions with \(sessions.count) sessions")
                for (index, session) in sessions.prefix(5).enumerated() {
                    self.logger.debug("  Session \(index + 1): W\(session.week)/D\(session.day) - \(session.type) (\(session.focus))")
                }
                
                // 🔊 NOTIFICATION: Play sound and haptic when sessions are received
                self.notifySessionsReceived(count: sessions.count)
            }
        } catch {
            logger.error("Failed to decode training sessions: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Methods

    func notifySessionsReceived(count: Int) {
        logger.info("🔊 Notifying user: \(count) sessions received")

        // Play system sound for data received
        WKInterfaceDevice.current().play(.success)

        // Haptic feedback for confirmation
        let hapticType: WKHapticType = count > 10 ? .success : .notification
        WKInterfaceDevice.current().play(hapticType)

        // Additional haptic for large session counts (full program)
        if count > 20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    // MARK: - Persistent iPhone Communication
    
    /// Establish persistent sync for ongoing iPhone → Watch communication
    func establishPersistentSync() {
        logger.info("🔄 Establishing persistent iPhone → Watch sync for ongoing use")
        
        // Send ping to iPhone to establish active communication
        let pingMessage: [String: Any] = [
            "action": "establishSync",
            "timestamp": Date().timeIntervalSince1970,
            "watchReady": true,
            "currentSessionCount": trainingSessions.count
        ]
        
        send(message: pingMessage) { [weak self] reply in
            self?.logger.info("📱 iPhone responded to sync establishment: \(reply.keys.joined(separator: ", "))")
            
            // If iPhone has newer sessions, request them immediately
            if let iPhoneSessionCount = reply["sessionCount"] as? Int,
               let currentCount = self?.trainingSessions.count,
               iPhoneSessionCount > currentCount {
                self?.logger.info("📲 iPhone has \(iPhoneSessionCount) sessions vs watch \(currentCount), requesting update")
                Task { @MainActor in
                    await self?.requestTrainingSessions()
                }
            }
        }
        
        // Schedule regular sync checks for ongoing communication
        scheduleRegularSyncChecks()
    }
    
    /// Schedule regular sync checks to ensure iPhone → Watch communication
    func scheduleRegularSyncChecks() {
        // Check for iPhone updates every 2 minutes during active use
        Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            // Timer already runs on main thread, no need for Task/@MainActor
            Task { @MainActor in
                guard let self = self else { return }
                
                // Only sync if iPhone is reachable and we haven't synced recently
                if self.isPhoneReachable,
                   let lastSync = self.lastSyncTime,
                   Date().timeIntervalSince(lastSync) > 300 { // 5 minutes
                    
                    self.logger.info("🔄 Regular sync check - requesting fresh sessions from iPhone")
                    await self.requestTrainingSessions()
                }
            }
        }
    }
    
    // MARK: - Public Interface Methods
    
    func refreshSessions() {
        logger.info("Manual session refresh requested")
        
        // Reset retry count for manual refresh
        sessionRequestRetryCount = 0
        lastRetryTime = nil
        
        Task { @MainActor in
            await requestTrainingSessions()
        }
        
        DispatchQueue.main.async {
            self.syncProgress = 0.0
        }
    }
    
    func clearLocalSessions() {
        logger.info("Clearing local sessions")
        DispatchQueue.main.async {
            self.trainingSessions.removeAll()
            self.currentWorkoutSession = nil
        }
        ProgramPersistence.shared.clearProgram()
    }
    
    /// Force sync sessions from iPhone - useful for debugging
    func forceSyncFromPhone() {
        logger.info("Force syncing sessions from iPhone")
        sessionRequestRetryCount = 0 // Reset retry count
        lastRetryTime = nil // Reset retry timer
        
        // If still no sessions after 10 seconds, generate fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.trainingSessions.isEmpty {
                self.logger.warning("Force sync timeout - generating fallback sessions")
                self.generateFallbackSessions()
            }
        }
        
        Task { @MainActor in
            await requestTrainingSessions()
        }
    }
    
    /// Get program status for debugging
    func getProgramStatus() -> String {
        let totalSessions = trainingSessions.count
        let completedSessions = trainingSessions.filter { $0.isCompleted }.count
        let weekCount = Set(trainingSessions.map { $0.week }).count
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        
        if totalSessions == 0 {
            return "No program loaded"
        }
        
        return "Program: \(weekCount) weeks, \(totalSessions) sessions, \(completedSessions) completed (Source: \(sessionSource))"
    }
    
    /// Force iPhone session sync if currently using fallback sessions
    func forceIPhoneSessionSync() {
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        
        logger.info("🔄 FORCE SYNC REQUESTED - Current source: \(sessionSource)")
        logger.info("🔄 Current sessions count: \(self.trainingSessions.count)")
        logger.info("🔄 WCSession reachable: \(WCSession.default.isReachable)")
        logger.info("🔄 WCSession activated: \(WCSession.default.activationState == .activated)")
        
        if sessionSource == "Fallback" {
            logger.warning("🔄 Currently using fallback sessions - forcing iPhone sync to get real sessions")
            
            // Clear fallback sessions to force iPhone sync
            DispatchQueue.main.async {
                self.trainingSessions = []
                self.logger.info("🔄 Cleared fallback sessions - requesting iPhone sessions")
            }
            
            // Aggressively request iPhone sessions
            sessionRequestRetryCount = 0
            lastRetryTime = nil
            logger.info("🔄 Sending requestTrainingSessions to iPhone...")
            Task { @MainActor in
                await requestTrainingSessions()
            }
            
            // If no response in 5 seconds, try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                let currentSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
                if self.trainingSessions.isEmpty || currentSource == "Fallback" {
                    self.logger.warning("🔄 Still no iPhone sessions after 5s - retrying sync (source: \(currentSource))")
                    Task { @MainActor in
                        await self.requestTrainingSessions()
                    }
                } else {
                    self.logger.info("✅ iPhone sessions received successfully!")
                }
            }
        } else {
            logger.info("✅ Already using iPhone sessions - no sync needed")
        }
    }
    
    // MARK: - Data Management
    
    func clearAllWatchData() {
        logger.info("Clearing all watch data for clean connectivity test")
        
        // Clear training sessions
        trainingSessions = []
        
        // Clear stored sessions
        ProgramPersistence.shared.clearProgram()
        
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "userLevel")
        UserDefaults.standard.removeObject(forKey: "userFrequency")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "personalBest")
        
        // Reset connection state
        isPhoneReachable = false
        connectionError = "Complete setup on iPhone first"
        lastSyncTime = nil
        syncProgress = 0.0
        
        logger.info("Watch data cleared - should now show 'Setup Required'")
    }
    
    // MARK: - Robust Sync Implementation
    
    func setupRobustSync() {
        // Initialize device identity
        if let existingId = UserDefaults.standard.string(forKey: "deviceId") {
            deviceId = existingId
        } else {
            deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "deviceId")
        }
        
        // Initialize sync token
        syncToken = UserDefaults.standard.string(forKey: "syncToken") ?? generateNewSyncToken()
        
        logger.info("🔧 Robust sync initialized - Device: \(self.deviceId)")
    }
    
    func generateNewSyncToken() -> String {
        let token = "\(self.deviceId)-\(Date().timeIntervalSince1970)-\(Int.random(in: 1000...9999))"
        UserDefaults.standard.set(token, forKey: "syncToken")
        return token
    }
    
    func loadStoredSessionsWithSync() {
        // Load sessions from UserDefaults with sync state awareness
        if let data = UserDefaults.standard.data(forKey: "scheduledSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            
            // Convert to syncable sessions
            syncableSessions = sessions.map { session in
                var syncableSession = SyncableTrainingSession(from: session)
                // Check if session was previously synced
                let wasSynced = UserDefaults.standard.bool(forKey: "session_\(session.id.uuidString)_synced")
                syncableSession.syncState = wasSynced ? .synced : .pending
                return syncableSession
            }
            
            // Update UI sessions
            trainingSessions = syncableSessions.map { $0.toTrainingSession() }
            
            logger.info("📱 Loaded \(self.trainingSessions.count) sessions with sync state")
        }
    }
    
    func generateUXFallbackSessions() {
        // Generate minimal UX fallback sessions (not permanent data)
        let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Beginner"
        let frequency = UserDefaults.standard.integer(forKey: "userFrequency")
        let actualFrequency = frequency > 0 ? frequency : 1
        
        var fallbackSessions: [TrainingSession] = []
        
        // Generate only 2 weeks for instant UX
        for week in 1...2 {
            for day in 1...actualFrequency {
                let session = TrainingSession(
                    week: week,
                    day: day,
                    type: "Sprint Training",
                    focus: "\(userLevel) Development",
                    sprints: [SprintSet(distanceYards: 20, reps: 2, intensity: "80%")],
                    accessoryWork: ["Dynamic Warm-up", "Cool-down"],
                    notes: "UX Fallback - syncing with iPhone..."
                )
                fallbackSessions.append(session)
            }
        }
        
        trainingSessions = fallbackSessions
        syncStatus = "Using offline sessions"
    }

    func activateSessionWithRobustSync() {
        guard !isWatchTestMode else {
            logger.info("Test mode active - WatchConnectivity disabled")
            return
        }
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            logger.info("✅ WCSession activated with robust sync")
        }
    }
    
    func initiateRobustSync() {
        guard WCSession.default.activationState == .activated else {
            logger.warning("WCSession not activated, cannot sync")
            return
        }
        
        syncStatus = "Syncing..."
        syncProgress = 0.1
        
        // Step 1: Exchange sync tokens
        exchangeSyncTokens()
    }
    
    func exchangeSyncTokens() {
        let message: [String: Any] = [
            "action": "syncTokenExchange",
            "deviceId": self.deviceId,
            "syncToken": self.syncToken,
            "deviceType": "Watch",
            "sessionCount": self.trainingSessions.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        syncProgress = 0.3
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message) { [weak self] reply in
                DispatchQueue.main.async {
                    self?.handleSyncTokenReply(reply)
                }
            } errorHandler: { [weak self] error in
                DispatchQueue.main.async {
                    self?.handleSyncError("Token exchange failed: \(error.localizedDescription)")
                }
            }
        } else {
            // Use transferUserInfo for guaranteed delivery
            WCSession.default.transferUserInfo(message)
            logger.info("Device not reachable, using transferUserInfo")
        }
    }
    
    func handleSyncTokenReply(_ reply: [String: Any]) {
        guard let remoteToken = reply["syncToken"] as? String else {
            handleSyncError("Invalid sync token reply")
            return
        }
        
        logger.info("📥 Received remote sync token: \(remoteToken)")
        syncProgress = 0.6
        
        if remoteToken == syncToken {
            // Tokens match - data is synchronized
            markAllSessionsAsSynced()
            completeSyncSuccessfully()
        } else {
            // Tokens differ - need reconciliation
            requestFullReconciliation()
        }
    }
    
    func markAllSessionsAsSynced() {
        for session in trainingSessions {
            UserDefaults.standard.set(true, forKey: "session_\(session.id.uuidString)_synced")
        }
        
        // Update syncable sessions
        for i in 0..<syncableSessions.count {
            syncableSessions[i].syncState = .synced
        }
        
        needsSync = false
        logger.info("✅ All sessions marked as synced")
    }
    
    func requestFullReconciliation() {
        syncProgress = 0.8
        
        // Request full session data from iPhone
        let message: [String: Any] = [
            "action": "requestFullSessions",
            "deviceId": self.deviceId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(message) { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleFullSessionData(reply)
            }
        } errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.handleSyncError("Reconciliation failed: \(error.localizedDescription)")
            }
        }
    }
    
    func handleFullSessionData(_ reply: [String: Any]) {
        guard let sessionsData = reply["sessionsData"] as? Data else {
            handleSyncError("Invalid session data format")
            return
        }
        
        do {
            let receivedSessions = try JSONDecoder().decode([TrainingSession].self, from: sessionsData)
            
            // Replace UX fallback with real sessions
            if trainingSessions.first?.notes?.contains("UX Fallback") == true {
                logger.info("🔄 Replacing UX fallback with \(receivedSessions.count) real sessions")
            }
            
            trainingSessions = receivedSessions
            
            // Convert to syncable and mark as synced
            syncableSessions = receivedSessions.map { session in
                var syncableSession = SyncableTrainingSession(from: session)
                syncableSession.syncState = .synced
                return syncableSession
            }
            
            // Store sessions
            storeSessionsLocally(receivedSessions)
            markAllSessionsAsSynced()
            completeSyncSuccessfully()
            
        } catch {
            handleSyncError("Failed to decode session data: \(error.localizedDescription)")
        }
    }
    
    func storeSessionsLocally(_ sessions: [TrainingSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: "scheduledSessions")
            UserDefaults.standard.set("iPhone", forKey: "sessionSource")
            logger.info("💾 Stored \(sessions.count) sessions locally")
        } catch {
            logger.error("Failed to store sessions: \(error.localizedDescription)")
        }
    }
    
    func completeSyncSuccessfully() {
        syncStatus = "Synced ✅"
        syncProgress = 1.0
        connectionError = nil
        lastSyncTime = Date()
        needsSync = false
        
        // Reset progress after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.syncProgress = 0.0
            self.syncStatus = "Ready"
        }
        
        // Notify UI
        notifySessionsReceived(count: trainingSessions.count)
        
        logger.info("🎉 Robust sync completed successfully")
    }
    
    func handleSyncError(_ message: String) {
        syncStatus = "Sync Failed"
        syncProgress = 0.0
        connectionError = message
        needsSync = true
        
        logger.error("❌ Sync error: \(message)")
        
        // If no sessions available, generate fallback
        if trainingSessions.isEmpty {
            generateUXFallbackSessions()
        }
    }
    
    // MARK: - Robust Sync Message Handlers
    
    nonisolated func handleSyncTokenExchangeSync(message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let remoteToken = message["syncToken"] as? String,
              let remoteDeviceId = message["deviceId"] as? String else {
            replyHandler(["error": "Invalid sync token exchange"])
            return
        }
        
        // Handle sync token exchange and schedule async updates
        Task { @MainActor in
            self.processSyncTokenExchange(remoteToken: remoteToken, remoteDeviceId: remoteDeviceId)
        }
        
        // Send immediate reply
        let reply: [String: Any] = [
            "syncToken": UserDefaults.standard.string(forKey: "syncToken") ?? "",
            "deviceId": UserDefaults.standard.string(forKey: "deviceId") ?? "",
            "deviceType": "Watch",
            "sessionCount": 0, // Will be updated async
            "timestamp": Date().timeIntervalSince1970
        ]
        replyHandler(reply)
    }
    
    nonisolated func handleRequestFullSessionsSync(message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        // Send stored sessions immediately
        if let data = UserDefaults.standard.data(forKey: "scheduledSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            
            do {
                let sessionsData = try JSONEncoder().encode(sessions)
                let reply: [String: Any] = [
                    "sessionsData": sessionsData,
                    "sessionCount": sessions.count,
                    "deviceId": UserDefaults.standard.string(forKey: "deviceId") ?? "",
                    "syncToken": UserDefaults.standard.string(forKey: "syncToken") ?? "",
                    "timestamp": Date().timeIntervalSince1970
                ]
                replyHandler(reply)
            } catch {
                replyHandler(["error": "Failed to encode sessions"])
            }
        } else {
            replyHandler(["error": "No sessions available"])
        }
    }
    
    func processSyncTokenExchange(remoteToken: String, remoteDeviceId: String) {
        logger.info("📥 Processing sync token exchange from iPhone: \(remoteDeviceId)")
        
        // Check if we need reconciliation
        if remoteToken != self.syncToken {
            logger.info("Tokens differ, requesting full reconciliation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestFullReconciliation()
            }
        } else {
            logger.info("Tokens match, marking sessions as synced")
            markAllSessionsAsSynced()
            completeSyncSuccessfully()
        }
    }
    
    func handleSyncTokenExchange(remoteToken: String?, remoteDeviceId: String?, replyHandler: @escaping ([String: Any]) -> Void) {
        guard let remoteToken = remoteToken,
              let remoteDeviceId = remoteDeviceId else {
            replyHandler(["error": "Invalid sync token exchange"])
            return
        }
        
        logger.info("📥 Handling sync token exchange from iPhone: \(remoteDeviceId)")
        
        let reply: [String: Any] = [
            "syncToken": self.syncToken,
            "deviceId": self.deviceId,
            "deviceType": "Watch",
            "sessionCount": self.trainingSessions.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        replyHandler(reply)
        
        // Check if we need reconciliation
        if remoteToken != self.syncToken {
            logger.info("Tokens differ, requesting full reconciliation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestFullReconciliation()
            }
        } else {
            logger.info("Tokens match, marking sessions as synced")
            markAllSessionsAsSynced()
            completeSyncSuccessfully()
        }
    }
    
    func handleRequestFullSessions(sessionIds: [String]?, replyHandler: @escaping ([String: Any]) -> Void) {
        logger.info("📤 iPhone requesting full sessions from Watch")
        
        do {
            let sessionsData = try JSONEncoder().encode(trainingSessions)
            let reply: [String: Any] = [
                "sessionsData": sessionsData,
                "sessionCount": self.trainingSessions.count,
                "deviceId": self.deviceId,
                "syncToken": self.syncToken,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)
            logger.info("✅ Sent \(self.trainingSessions.count) sessions to iPhone")
        } catch {
            logger.error("Failed to encode sessions: \(error.localizedDescription)")
            replyHandler(["error": "Failed to encode sessions"])
        }
    }
    
    // MARK: - Public Robust Sync Interface
    
    func forceRobustSync() {
        logger.info("🔄 Force robust sync requested")
        syncToken = generateNewSyncToken() // Force token change
        initiateRobustSync()
    }
    
    func getRobustSyncSummary() -> String {
        let syncedCount = syncableSessions.filter { $0.syncState == .synced }.count
        let pendingCount = syncableSessions.filter { $0.syncState == .pending }.count
        
        return """
        ROBUST SYNC STATUS:
        📱 Device: Watch
        🆔 Device ID: \(self.deviceId)
        🔑 Sync Token: \(self.syncToken)
        📊 Total Sessions: \(self.trainingSessions.count)
        ✅ Synced: \(syncedCount)
        ⏳ Pending: \(pendingCount)
        🔗 Connected: \(isPhoneConnected)
        📡 Reachable: \(isPhoneReachable)
        📊 Status: \(syncStatus)
        📡 Last Sync: \(lastSyncTime?.formatted() ?? "Never")
        """
    }
    
    // MARK: - Connection Status Helpers
    
    var isFullyConnected: Bool {
        isPhoneConnected && isPhoneReachable && connectionError == nil
    }
    
    var connectionStatusText: String {
        if !isPhoneConnected {
            return "iPhone not paired"
        } else if !isPhoneReachable {
            return "iPhone not reachable"
        } else if let error = connectionError {
            return "Error: \(error)"
        } else {
            return "Connected"
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        // Call this method when you want to manually clean up timers
        heartbeatTimer?.invalidate()
        sessionRequestTimer?.invalidate()
        heartbeatTimer = nil
        sessionRequestTimer = nil
    }
}
