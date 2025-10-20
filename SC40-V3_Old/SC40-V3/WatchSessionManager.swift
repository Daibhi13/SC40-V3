import Foundation
import Combine
import os.log
@preconcurrency import WatchConnectivity

// MARK: - Test Mode Support
#if DEBUG
/// Thread-safe test mode flag
@MainActor var isTestMode: Bool {
    get { UserDefaults.standard.bool(forKey: "isTestMode") }
    set { UserDefaults.standard.set(newValue, forKey: "isTestMode") }
}
#else
/// Always false in release builds
@MainActor var isTestMode = false
#endif

@available(iOS 9.0, *)
@MainActor class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    // Required for ObservableObject conformance
    var objectWillChange = ObservableObjectPublisher()

    @Published var receivedData: [String: Any] = [:]
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    @Published var connectionError: String?
    @Published var lastSyncTime: Date?
    
    // ROBUST SYNC: New sync-aware properties
    @Published var syncStatusText: String = "Ready"
    @Published var syncProgress: Double = 0.0
    @Published var needsSync: Bool = false
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "WatchConnectivity")
    private var pendingMessages: [(message: [String: Any], retryCount: Int)] = []
    private let maxRetries = 3
    
    // ROBUST SYNC: Core sync components
    private var syncToken: String = ""
    private var deviceId: String = ""
    
    // SC40 Accelerate Method: Session management
    @Published var sessions: [TrainingSession] = []
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private override init() {
        super.init()
        // Initialize with empty data to prevent nil crashes
        receivedData = [:]
        
        // ROBUST SYNC: Initialize sync components
        setupRobustSync()
        
        // Activate session with error handling
        DispatchQueue.main.async { [weak self] in
            self?.activateSession()
        }
    }
    // MARK: - Robust Sync Setup
    
    private func setupRobustSync() {
        // Initialize device identity
        if let existingId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = existingId
        } else {
            deviceId = UUID().uuidString
            UserDefaults.standard.set(deviceId, forKey: "deviceId")
        }
        // Initialize sync token
        syncToken = UserDefaults.standard.string(forKey: "syncToken") ?? generateNewSyncToken()
        
        logger.info("🔧 iPhone robust sync initialized - Device: \(self.deviceId)")
    }
    
    private func generateNewSyncToken() -> String {
        let token = "\(self.deviceId)-\(Date().timeIntervalSince1970)-\(Int.random(in: 1000...9999))"
        UserDefaults.standard.set(token, forKey: "syncToken")
        return token
    }
    
    private func activateSession() {
        // Skip activation in test mode
        guard !isTestMode else {
            logger.info("Test mode active - WatchConnectivity disabled")
            return
        }
        
        guard WCSession.isSupported() else {
            logger.error("WatchConnectivity is not supported on this device")
            Task { @MainActor in
                self.connectionError = "WatchConnectivity not supported"
            }
            return
        }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        logger.info("WatchConnectivity session activation requested")
    }
    // MARK: - Connection Monitoring
    
    @MainActor private func checkConnectionStatus() {
        let session = WCSession.default
        self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
        self.isWatchReachable = session.isReachable
        
        if !self.isWatchConnected {
            self.connectionError = "Apple Watch not paired or app not installed"
        } else if !self.isWatchReachable {
            self.connectionError = "Apple Watch not reachable"
        } else {
            self.connectionError = nil
        }
    }
    
    @MainActor private func retryPendingMessages() {
        guard WCSession.default.isReachable else { return }
        
        let messagesToRetry = pendingMessages
        pendingMessages.removeAll()
        
        for (message, retryCount) in messagesToRetry {
            if retryCount < maxRetries {
                sendMessageWithRetry(message, retryCount: retryCount + 1)
            } else {
                logger.error("Max retries reached for message: \(message.keys.joined(separator: ", "))")
            }
        }
    }
    
    // MARK: - Public Interface Methods
    
    /// Test connection to Apple Watch
    func testConnection() {
        logger.info("Testing Apple Watch connection...")
        
        // Log detailed connection status
        let session = WCSession.default
        logger.info("WCSession Status:")
        logger.info("- isSupported: \(WCSession.isSupported())")
        logger.info("- isPaired: \(session.isPaired)")
        logger.info("- isWatchAppInstalled: \(session.isWatchAppInstalled)")
        logger.info("- isReachable: \(session.isReachable)")
        logger.info("- activationState: \(session.activationState.rawValue)")
        
        guard session.isPaired else {
            logger.error("Apple Watch is not paired")
            Task { @MainActor in
                self.connectionError = "Apple Watch not paired. Please pair your watch in the Watch app."
            }
            return
        }
        
        guard session.isWatchAppInstalled else {
            logger.error("Watch app is not installed")
            Task { @MainActor in
                self.connectionError = "Sprint Coach app not installed on Apple Watch. Please install from the Watch app."
            }
            return
        }
        
        let testMessage: [String: Any] = [
            "action": "connectionTest",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessageWithRetry(testMessage)
        
        Task { @MainActor in
            self.checkConnectionStatus()
        }
    }
    
    /// Force sync all data to Apple Watch
    func forceSyncToWatch() {
        logger.info("Force syncing all data to Apple Watch...")
        
        // Send onboarding data if available
        if let profileData = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            
            let onboardingMessage: [String: Any] = [
                "action": "onboardingComplete",
                "userName": profile.name,
                "personalBest": profile.baselineTime,
                "userLevel": profile.level,
                "frequency": profile.frequency,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            sendMessageWithRetry(onboardingMessage)
        }
        
        // Send cached training sessions if available
        if let sessionsData = UserDefaults.standard.data(forKey: "cachedTrainingSessions"),
           let sessionCount = UserDefaults.standard.object(forKey: "sessionCount") as? Int {
            
            let sessionsMessage: [String: Any] = [
                "trainingSessions": sessionsData,
                "sessionCount": sessionCount,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            sendMessageWithRetry(sessionsMessage)
        }
        
        Task { @MainActor in
            self.checkConnectionStatus()
        }
    }
    
    // MARK: - SC40 Accelerate Method: Session Management
    
    /// Generate and sync sessions using SC40 Accelerate Method
    func generateAndSyncSessions(level: String, frequency: Int, userProfileVM: UserProfileViewModel? = nil) {
        logger.info("🚀 SC40 Accelerate Method: generateAndSyncSessions called!")
        logger.info("🧠 Generating sessions for level: \(level), frequency: \(frequency)")
        
        syncStatus = .syncing
        
        // Use proper SessionLibrary generation if UserProfileViewModel is available
        let generatedSessions: [TrainingSession]
        if let userProfileVM = userProfileVM {
            logger.info("📚 Using SessionLibrary for proper program generation")
            // Generate using the same logic as iPhone TrainingView
            generatedSessions = generateSessionLibrarySessions(level: level, frequency: frequency, userProfileVM: userProfileVM)
        } else {
            logger.info("⚠️ Fallback to basic sessions (no UserProfileViewModel)")
            // Fallback to basic sessions
            generatedSessions = generateBasicSessions(level: level, frequency: frequency)
        }
        
        self.sessions = generatedSessions
        
        // Save locally
        saveSessionsLocally()
        
        logger.info("✅ Generated \(generatedSessions.count) sessions using SessionLibrary")
        
        // Send to watch using SC40 Accelerate Method
        sendSessionsToWatch(generatedSessions)
    }
    
    /// Generate sessions using SessionLibrary (mirrors iPhone program exactly)
    private func generateSessionLibrarySessions(level: String, frequency: Int, userProfileVM: UserProfileViewModel) -> [TrainingSession] {
        logger.info("📚 Generating sessions using SessionLibrary for level: \(level), frequency: \(frequency)")
        
        // Create user preferences from profile
        let userPreferences = UserSessionPreferences(
            favoriteTemplateIDs: userProfileVM.profile.favoriteSessionTemplateIDs,
            preferredTemplateIDs: userProfileVM.profile.preferredSessionTemplateIDs,
            dislikedTemplateIDs: userProfileVM.profile.dislikedSessionTemplateIDs,
            allowRepeatingFavorites: userProfileVM.profile.allowRepeatingFavorites,
            manualOverrides: userProfileVM.profile.manualSessionOverrides
        )
        
        // Generate weekly programs using the same logic as iPhone
        let weeklyPrograms = WeeklyProgramTemplate.generateWithUserPreferences(
            level: level,
            totalDaysPerWeek: frequency,
            userPreferences: userPreferences
        )
        
        // Convert to TrainingSession objects (same as iPhone)
        let trainingSessions = convertWeeklyProgramsToTrainingSessions(weeklyPrograms, userProfileVM: userProfileVM)
        
        logger.info("📚 SessionLibrary generated \(trainingSessions.count) sessions (\(weeklyPrograms.count) weeks)")
        return trainingSessions
    }
    
    /// Convert WeeklyProgramTemplate to TrainingSession (mirrors iPhone logic)
    private func convertWeeklyProgramsToTrainingSessions(_ weeklyPrograms: [WeeklyProgramTemplate], userProfileVM: UserProfileViewModel) -> [TrainingSession] {
        var trainingSessions: [TrainingSession] = []
        
        for (weekIndex, weeklyProgram) in weeklyPrograms.enumerated() {
            let weekNumber = weekIndex + 1
            
            for daySession in weeklyProgram.sessions {
                let dayNumber = daySession.dayNumber
                
                // Handle different session types
                if let sprintTemplate = daySession.sessionTemplate {
                    // Sprint session - convert SprintSessionTemplate to TrainingSession
                    let sprintSet = SprintSet(
                        distanceYards: sprintTemplate.distance,
                        reps: sprintTemplate.reps,
                        intensity: "Max"
                    )
                    
                    let trainingSession = TrainingSession(
                        id: UUID(),
                        week: weekNumber,
                        day: dayNumber,
                        type: sprintTemplate.name,
                        focus: sprintTemplate.focus,
                        sprints: [sprintSet],
                        accessoryWork: ["Dynamic Warm-up", "Cool-down"],
                        notes: "Generated via SessionLibrary - \(sprintTemplate.level) level"
                    )
                    trainingSessions.append(trainingSession)
                } else if false { // TODO: Fix recoveryTemplate when available
                    // Recovery session
                    let trainingSession = TrainingSession(
                        id: UUID(),
                        week: weekNumber,
                        day: dayNumber,
                        type: "Recovery",
                        focus: "Active Recovery",
                        sprints: [], // Recovery sessions have no sprints
                        accessoryWork: ["Light stretching", "Mobility work"],
                        notes: "Recovery Session"
                    )
                    trainingSessions.append(trainingSession)
                }
            }
        }
        
        return trainingSessions
    }
    
    private func generateBasicSessions(level: String, frequency: Int) -> [TrainingSession] {
        var sessions: [TrainingSession] = []
        
        // Generate 12 weeks of sessions
        for week in 1...12 {
            for day in 1...frequency {
                let session = TrainingSession(
                    id: UUID(),
                    week: week,
                    day: day,
                    type: "Sprint Training",
                    focus: "40 Yard Sprints",
                    sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "Max")],
                    accessoryWork: ["Dynamic Warm-up", "Cool-down"],
                    notes: "Generated via SC40 Accelerate Method"
                )
                sessions.append(session)
            }
        }
        
        return sessions
    }
    
    private func saveSessionsLocally() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self.sessions)
            UserDefaults.standard.set(data, forKey: "cachedTrainingSessions")
            UserDefaults.standard.set(self.sessions.count, forKey: "sessionCount")
            logger.info("💾 Saved \(self.sessions.count) sessions locally")
        } catch {
            logger.error("Failed to save sessions locally: \(error.localizedDescription)")
        }
    }
    
    /// Send sessions to watch using SC40 Accelerate Method with intelligent batching
    func sendSessionsToWatch(_ sessions: [TrainingSession]) {
        logger.info("🚀 SC40 Accelerate Method: Intelligent batching for \(sessions.count) total sessions")
        
        // Get user's current progress to determine optimal batch
        let userWeek = getCurrentUserWeek()
        let userFrequency = getUserFrequency()
        
        // Determine which sessions to send based on user progress
        let sessionsToSend = getOptimalSessionBatch(sessions: sessions, userWeek: userWeek, frequency: userFrequency)
        
        logger.info("📱 Sending batch: \(sessionsToSend.count) sessions for user at Week \(userWeek)")
        
        // Log first session details for debugging
        if let firstSession = sessionsToSend.first {
            logger.info("📱 SENDING iPhone W1/D1: \(firstSession.sprints)")
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let sessionsData = try encoder.encode(sessionsToSend)
            
            // C25K Method: Include user profile data for proper fallback sessions
            let userLevel = getUserLevel()
            
            let message: [String: Any] = [
                "trainingSessions": sessionsData,
                "sessionCount": sessionsToSend.count,
                "totalSessions": sessions.count,
                "batchInfo": getBatchInfo(userWeek: userWeek, frequency: userFrequency),
                "timestamp": Date().timeIntervalSince1970,
                "action": "syncSessions",
                // C25K Method: Send user profile for proper fallback generation
                "userLevel": userLevel,
                "userFrequency": userFrequency,
                "userName": getUserName() ?? "User"
            ]
            
            logger.info("📤 iPhone sending batch: \(sessionsToSend.count)/\(sessions.count) sessions")
            sendMessageWithRetry(message)
            
        } catch {
            logger.error("Failed to encode sessions: \(error.localizedDescription)")
            syncStatus = .failed(error)
        }
    }
    
    /// Get user level from UserDefaults or profile
    private func getUserLevel() -> String {
        // Try UserDefaults first, then check if we can get from profile
        if let level = UserDefaults.standard.string(forKey: "userLevel") {
            return level
        }
        // Default to Beginner for safety
        return "Beginner"
    }
    
    /// Get user name from UserDefaults
    private func getUserName() -> String? {
        return UserDefaults.standard.string(forKey: "userName")
    }
    
    // MARK: - Intelligent Session Batching
    
    /// Get optimal session batch based on user progress and comprehensive frequency support
    private func getOptimalSessionBatch(sessions: [TrainingSession], userWeek: Int, frequency: Int) -> [TrainingSession] {
        let sortedSessions = sessions.sorted { ($0.week, $0.day) < ($1.week, $1.day) }
        
        // PHASE 1: Always send Week 1 first (immediate access for ALL frequencies 1-7)
        if userWeek <= 1 {
            let week1Sessions = sortedSessions.filter { $0.week == 1 }
            logger.info("📦 PHASE 1: Sending Week 1 (\(week1Sessions.count) sessions) for \(frequency) days/week")
            return week1Sessions
        }
        
        // PHASE 2: Send optimal batch for Week 2 based on frequency
        else if userWeek == 2 {
            let batchSize = getPhase2BatchSize(frequency: frequency)
            let weeksBatch = sortedSessions.filter { $0.week <= batchSize }
            logger.info("📦 PHASE 2: Sending Weeks 1-\(batchSize) (\(weeksBatch.count) sessions) for \(frequency) days/week")
            return weeksBatch
        }
        
        // PHASE 3: Send medium batch when user reaches Week 3
        else if userWeek >= 3 && userWeek <= 5 {
            let batchSize = getPhase3BatchSize(frequency: frequency)
            let weeksBatch = sortedSessions.filter { $0.week <= batchSize }
            logger.info("📦 PHASE 3: Sending Weeks 1-\(batchSize) (\(weeksBatch.count) sessions) for \(frequency) days/week")
            return weeksBatch
        }
        
        // PHASE 4: Send all remaining sessions when user reaches advanced weeks
        else {
            logger.info("📦 PHASE 4: Sending all sessions (\(sortedSessions.count) sessions) for \(frequency) days/week")
            return sortedSessions
        }
    }
    
    /// Get Phase 2 batch size based on training frequency
    private func getPhase2BatchSize(frequency: Int) -> Int {
        switch frequency {
        case 1: return 4  // 1 day/week: Send 4 weeks (4 sessions total)
        case 2: return 3  // 2 days/week: Send 3 weeks (6 sessions total)
        case 3: return 2  // 3 days/week: Send 2 weeks (6 sessions total)
        case 4: return 2  // 4 days/week: Send 2 weeks (8 sessions total)
        case 5: return 2  // 5 days/week: Send 2 weeks (10 sessions total)
        case 6: return 2  // 6 days/week: Send 2 weeks (12 sessions total)
        case 7: return 2  // 7 days/week: Send 2 weeks (14 sessions total)
        default: return 2
        }
    }
    
    /// Get Phase 3 batch size based on training frequency
    private func getPhase3BatchSize(frequency: Int) -> Int {
        switch frequency {
        case 1: return 8   // 1 day/week: Send 8 weeks (8 sessions total)
        case 2: return 6   // 2 days/week: Send 6 weeks (12 sessions total)
        case 3: return 5   // 3 days/week: Send 5 weeks (15 sessions total)
        case 4: return 4   // 4 days/week: Send 4 weeks (16 sessions total)
        case 5: return 4   // 5 days/week: Send 4 weeks (20 sessions total)
        case 6: return 3   // 6 days/week: Send 3 weeks (18 sessions total)
        case 7: return 3   // 7 days/week: Send 3 weeks (21 sessions total)
        default: return 5
        }
    }
    
    /// Get current user week from profile or progress
    private func getCurrentUserWeek() -> Int {
        // Try to get from user profile
        if let profileData = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            return profile.currentWeek
        }
        
        // Fallback: calculate from completed sessions
        let completedSessions = sessions.filter { $0.isCompleted }
        if completedSessions.isEmpty {
            return 1 // New user
        }
        
        // Find the highest completed week
        let maxCompletedWeek = completedSessions.map { $0.week }.max() ?? 1
        return maxCompletedWeek + 1 // Next week to train
    }
    
    /// Get user's training frequency
    private func getUserFrequency() -> Int {
        if let profileData = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            return profile.frequency
        }
        return 3 // Default to 3 days/week
    }
    
    /// Get batch information for debugging and Watch display
    private func getBatchInfo(userWeek: Int, frequency: Int) -> [String: Any] {
        var phase = "PHASE 1"
        var description = "Week 1 (Immediate Access)"
        
        if userWeek == 2 {
            phase = "PHASE 2"
            let batchSize = getPhase2BatchSize(frequency: frequency)
            description = "Weeks 1-\(batchSize) (Frequency-Optimized)"
        } else if userWeek >= 3 && userWeek <= 5 {
            phase = "PHASE 3"
            let batchSize = getPhase3BatchSize(frequency: frequency)
            description = "Weeks 1-\(batchSize) (Medium Batch)"
        } else if userWeek >= 6 {
            phase = "PHASE 4"
            description = "Full Program (All Weeks)"
        }
        
        return [
            "phase": phase,
            "description": description,
            "userWeek": userWeek,
            "frequency": frequency,
            "frequencyOptimized": true
        ]
    }
    
    private func sendMessageWithRetry(_ message: [String: Any], retryCount: Int = 0) {
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            logger.warning("WCSession not activated, queueing message")
            pendingMessages.append((message, retryCount))
            return
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] reply in
                self?.logger.info("Message sent successfully with reply: \(reply.keys.joined(separator: ", "))")
            }, errorHandler: { [weak self] error in
                self?.logger.error("Failed to send message: \(error.localizedDescription)")
                
                // Add to retry queue if not at max retries
                if retryCount < self?.maxRetries ?? 0 {
                    self?.pendingMessages.append((message, retryCount))
                }
                
                let errorMessage = error.localizedDescription
                Task { @MainActor [weak self] in
                    self?.connectionError = "Failed to send data to watch: \(errorMessage)"
                }
            })
        } else {
            // Try using application context for non-urgent data
            if let data = message["trainingSessions"] as? Data {
                do {
                    try session.updateApplicationContext(["trainingSessions": data])
                    logger.info("Training sessions sent via application context")
                } catch {
                    logger.error("Failed to update application context: \(error.localizedDescription)")
                    pendingMessages.append((message, retryCount))
                }
            } else {
                pendingMessages.append((message, retryCount))
                logger.warning("Watch not reachable, message queued for retry")
            }
        }
    }
    
    func send(message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        sendMessageWithRetry(message)
    }
    
    // Send training sessions to watch with validation and retry
    func sendTrainingSessions(_ sessions: [Any]) {
        logger.info("Attempting to send \(sessions.count) training sessions to watch")
        
        // Validate sessions before sending
        guard !sessions.isEmpty else {
            logger.warning("No sessions to send to watch")
            Task { @MainActor in
                self.connectionError = "No training sessions available to sync"
            }
            return
        }
        
        // Create message with metadata for validation
        let message: [String: Any] = [
            "trainingSessions": sessions,
            "sessionCount": sessions.count,
            "timestamp": Date().timeIntervalSince1970,
            "version": "1.0"
        ]
        
        sendMessageWithRetry(message)
        
        Task { @MainActor in
            self.lastSyncTime = Date()
        }
    }
    
    // Send current session distances to watch for GPS tracking with enhanced validation
    func sendSessionDistances(_ distances: [Int], sessionName: String) {
        logger.info("Sending session distances to watch: \(distances) for session: \(sessionName)")
        
        // Validate input data
        guard !distances.isEmpty, !sessionName.isEmpty else {
            logger.warning("Invalid session data - distances: \(distances.count), name: \(sessionName)")
            return
        }
        
        let sessionData: [String: Any] = [
            "type": "sessionDistances",
            "distances": distances,
            "sessionName": sessionName,
            "totalReps": distances.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessageWithRetry(sessionData)
    }
    
    // Send workout results back to iPhone with validation
    func sendWorkoutResults(_ results: [String: Any]) {
        logger.info("Sending workout results to iPhone")
        
        var validatedResults = results
        validatedResults["timestamp"] = Date().timeIntervalSince1970
        validatedResults["source"] = "appleWatch"
        
        sendMessageWithRetry(validatedResults)
    }
    
    // MARK: - Enhanced Receiving and Delegate Methods
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        logger.info("Received message from Apple Watch: \(message.keys.joined(separator: ", "))")
        
        // Extract all needed data immediately to avoid capturing the message dict
        let action = message["action"] as? String
        let messageType = message["type"] as? String
        let timestamp = message["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
        let results = message["results"] as? [Double]
        let source = message["source"] as? String
        
        // ROBUST SYNC: Handle sync token exchange
        if action == "syncTokenExchange" {
            // iPhone handles sync token exchange differently - use UserDefaults for nonisolated access
            let storedSyncToken = UserDefaults.standard.string(forKey: "syncToken") ?? ""
            let storedDeviceId = UserDefaults.standard.string(forKey: "deviceId") ?? ""
            
            let reply: [String: Any] = [
                "syncToken": storedSyncToken,
                "deviceId": storedDeviceId,
                "deviceType": "iPhone",
                "sessionCount": 0,
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)
            return
        }
        
        // ROBUST SYNC: Handle full session request
        if action == "requestFullSessions" {
            // iPhone sends stored sessions
            if let data = UserDefaults.standard.data(forKey: "cachedTrainingSessions"),
               let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
                do {
                    let sessionsData = try JSONEncoder().encode(sessions)
                    let storedDeviceId = UserDefaults.standard.string(forKey: "deviceId") ?? ""
                    let storedSyncToken = UserDefaults.standard.string(forKey: "syncToken") ?? ""
                    
                    let reply: [String: Any] = [
                        "sessionsData": sessionsData,
                        "sessionCount": sessions.count,
                        "deviceId": storedDeviceId,
                        "syncToken": storedSyncToken,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    replyHandler(reply)
                } catch {
                    replyHandler(["error": "Failed to encode sessions"])
                }
            } else {
                replyHandler(["error": "No sessions available"])
            }
            return
        }
        
        // Special-case handling: reply immediately to avoid sending replyHandler across actors
        if action == "requestSessions" {
            // Send immediate reply and handle session sending in async task
            replyHandler([
                "status": "processing",
                "message": "Processing session request",
                "timestamp": Date().timeIntervalSince1970
            ])
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.logger.info("📱 Watch requested training sessions - checking current SessionLibrary sessions")
                self.logger.info("📱 iPhone has \(self.sessions.count) sessions available")
                
                // Check if we have sessions and send them
                if !self.sessions.isEmpty {
                    // Log first session details for comparison
                    if let firstSession = self.sessions.first {
                        self.logger.info("📱 iPhone W1/D1 session: \(firstSession.sprints)")
                    }
                    
                    // Send existing sessions via sendSessionsToWatch
                    self.sendSessionsToWatch(self.sessions)
                    self.logger.info("✅ Sent \(self.sessions.count) existing SessionLibrary sessions to Watch")
                } else {
                    self.logger.warning("⚠️ No sessions available - generating fresh SessionLibrary sessions for Watch")
                    
                    // Try to get user profile data from UserDefaults
                    if let profileData = UserDefaults.standard.data(forKey: "userProfile"),
                       let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
                        let level = profile.level
                        let frequency = profile.frequency
                        
                        // Create a temporary UserProfileViewModel for session generation
                        let tempUserProfileVM = UserProfileViewModel()
                        tempUserProfileVM.profile = profile
                        
                        self.generateAndSyncSessions(level: level, frequency: frequency, userProfileVM: tempUserProfileVM)
                        self.logger.info("✅ Generated fresh SessionLibrary sessions - sent via sendSessionsToWatch")
                    } else {
                        self.logger.warning("⚠️ No user profile available for session generation")
                    }
                }
                
                NotificationCenter.default.post(name: .watchRequestedSessions, object: nil)
                self.lastSyncTime = Date()
                self.connectionError = nil
            }
            return
        }
        
        // Use Task to properly handle the async operation  
        Task { @MainActor in
            // Create a new dictionary with the extracted values to avoid data races
            var safeMessage: [String: Any] = [:]
            if let action = action { safeMessage["action"] = action }
            if let messageType = messageType { safeMessage["type"] = messageType }
            safeMessage["timestamp"] = timestamp
            if let results = results { safeMessage["results"] = results }
            if let source = source { safeMessage["source"] = source }
            
            self.receivedData = safeMessage
            self.lastSyncTime = Date()
            self.connectionError = nil // Clear any connection errors
            
            // Handle requests from watch
            if let action = action {
                switch action {
                case "heartbeat":
                    self.logger.debug("Received heartbeat from watch")
                default:
                    self.logger.info("Received unknown action from watch: \(action)")
                }
            }
            
            // Save all received workouts to history with validation
            self.saveWorkoutToHistory(safeMessage)
            
            // Try to convert message to session data and notify main app
            if let messageType = messageType, messageType == "trainingSession" {
                NotificationCenter.default.post(name: .didReceiveTrainingSession, object: safeMessage)
                self.logger.info("Successfully processed training session from watch")
            }
            
            // Handle StarterPro results from Watch
            if let type = messageType, type == "starterProResults",
               let results = results {
                let sessionData = [
                    "date": Date(timeIntervalSince1970: timestamp),
                    "results": results
                ] as [String: Any]
                NotificationCenter.default.post(name: .didReceiveStarterProResults, object: sessionData)
                self.logger.info("Successfully processed StarterPro results from watch")
            }
        }
    }
    
    // Handle application context updates (for non-urgent data)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Guard against nil or empty context
        guard !applicationContext.isEmpty else {
            logger.warning("Received empty application context from watch")
            return
        }
        
        // Extract needed data immediately to avoid data races
        let contextKeys = applicationContext.keys.joined(separator: ", ")
        logger.info("Received application context from watch: \(contextKeys)")
        
        // Safely extract timestamp
        let safeTimestamp: Double? = {
            if let number = applicationContext["timestamp"] as? NSNumber {
                return number.doubleValue
            } else if let doubleVal = applicationContext["timestamp"] as? Double {
                return doubleVal
            } else {
                return nil
            }
        }()
        
        // Safely extract and copy sessions data
        var safeSessions: Any? = nil
        if let sessions = applicationContext["trainingSessions"] {
            if let data = sessions as? Data {
                safeSessions = data
            } else if let arr = sessions as? [[String: Any]] {
                // Create a safe copy to avoid data races
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: arr, options: [])
                    let copiedArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]
                    safeSessions = copiedArray
                } catch {
                    logger.error("Failed to safely copy sessions array: \(error.localizedDescription)")
                }
            } else {
                logger.warning("Received trainingSessions in unexpected format: \(type(of: sessions))")
            }
        }
        
        // Update on main actor with proper error handling
        Task { @MainActor [weak self, safeSessions, safeTimestamp] in
            guard let self = self else { 
                return 
            }
            
            if let safeSessions = safeSessions {
                self.receivedData["trainingSessions"] = safeSessions
                logger.info("Successfully updated receivedData with training sessions")
            }
            if let safeTimestamp = safeTimestamp {
                self.receivedData["timestamp"] = safeTimestamp
                self.lastSyncTime = Date(timeIntervalSince1970: safeTimestamp)
            }
        }
    }
    
    private func saveWorkoutToHistory(_ workout: [String: Any]) {
        guard !workout.isEmpty else { 
            logger.warning("Attempted to save empty workout to history")
            return 
        }
        
        // Perform all operations on main queue to prevent data races
        Task { @MainActor in
            // Convert watch workout data to TrainingSession format
            if let trainingSession = convertWatchWorkoutToTrainingSession(workout) {
                // Save to HistoryManager so it appears in phone's HistoryView
                // TODO: Add to history when HistoryManager is available
            // HistoryManager.shared.addCompletedSession(trainingSession)
                logger.info("Saved watch workout to HistoryManager: \(trainingSession.type)")
                
                // Post notification for UI updates
                NotificationCenter.default.post(
                    name: NSNotification.Name("WatchWorkoutReceived"),
                    object: trainingSession
                )
                
                // Post notification for personal best updates
                if let personalBest = trainingSession.personalBest {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PersonalBestFromWatch"),
                        object: personalBest
                    )
                }
            } else {
                logger.warning("Failed to convert watch workout to TrainingSession format")
            }
            
            // Also keep legacy storage for backwards compatibility (with size limits)
            var history = UserDefaults.standard.array(forKey: "workoutHistory") as? [[String: Any]] ?? []
            
            // Create a safe copy of the workout data
            if let workoutData = try? JSONSerialization.data(withJSONObject: workout, options: []),
               let safeCopy = try? JSONSerialization.jsonObject(with: workoutData, options: []) as? [String: Any] {
                history.append(safeCopy)
                
                // Keep only last 50 workouts to prevent storage bloat and memory issues
                if history.count > 50 {
                    history = Array(history.suffix(50))
                }
                
                UserDefaults.standard.set(history, forKey: "workoutHistory")
                logger.info("Saved workout to legacy history (total: \(history.count))")
            } else {
                logger.error("Failed to create safe copy of workout data")
            }
        }
    }
    
    private func convertWatchWorkoutToTrainingSession(_ workout: [String: Any]) -> TrainingSession? {
        // Extract workout data
        guard let results = workout["results"] as? [Double],
              !results.isEmpty else {
            logger.warning("No valid results found in watch workout data")
            return nil
        }
        
        let timestamp = workout["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
        let source = workout["source"] as? String ?? "Apple Watch"
        let sessionType = workout["type"] as? String ?? "Sprint"
        
        // Determine if this is a Time Trial session
        let isTimeTrial = sessionType.contains("Time Trial") || 
                         sessionType.contains("time trial") ||
                         sessionType.contains("40 yd Time Trial") ||
                         results.count == 1 // Single rep often indicates time trial
        
        // Create TrainingSession from watch data
        var session = TrainingSession(
            id: UUID(),
            week: 0, // Watch sessions use week 0 as requested
            day: 0,  // Watch sessions use day 0 as requested
            type: isTimeTrial ? "Time Trial" : sessionType,
            focus: isTimeTrial ? "Performance Test" : "Watch Training",
            sprints: [SprintSet(distanceYards: 40, reps: results.count, intensity: isTimeTrial ? "Max Effort" : "Max")],
            accessoryWork: [],
            notes: "Completed on \(source)"
        )
        
        // Add session timing data
        // TODO: Add session timing when TrainingSession supports it
        // session.sessionStartTime = Date(timeIntervalSince1970: timestamp - 300) // Estimate 5min session
        // session.sessionEndTime = Date(timeIntervalSince1970: timestamp)
        // session.sessionDuration = TimeInterval(300) // 5 minutes estimated
        
        // Add sprint times and calculate stats
        session.sprintTimes = results
        session.personalBest = results.min()
        // TODO: Add totalDistance when TrainingSession supports it
        // session.totalDistance = Double(40 * results.count)
        
        // Mark as completed and from watch
        session.isCompleted = true
        session.completionDate = Date(timeIntervalSince1970: timestamp)
        session.sessionNotes = "Completed on \(source) at \(DateFormatter.localizedString(from: Date(timeIntervalSince1970: timestamp), dateStyle: .short, timeStyle: .short))"
        
        return session
    }
    
    // Enhanced delegate methods with proper error handling
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Capture session state before async dispatch
        let isPaired = session.isPaired
        let isWatchAppInstalled = session.isWatchAppInstalled  
        let isReachable = session.isReachable
        
        Task { @MainActor in
            switch activationState {
            case .activated:
                self.logger.info("WatchConnectivity session activated successfully")
                self.isWatchConnected = isPaired && isWatchAppInstalled
                self.isWatchReachable = isReachable
                self.connectionError = nil
            case .notActivated:
                self.logger.error("WatchConnectivity session failed to activate")
                self.connectionError = "Failed to connect to Apple Watch"
            case .inactive:
                self.logger.warning("WatchConnectivity session is inactive")
                self.connectionError = "Apple Watch connection inactive"
            @unknown default:
                self.logger.error("Unknown WatchConnectivity activation state")
                self.connectionError = "Unknown connection state"
            }
            
            if let error = error {
                self.logger.error("WatchConnectivity activation error: \(error.localizedDescription)")
                self.connectionError = error.localizedDescription
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        logger.info("Watch reachability changed: \(isReachable)")
        
        Task { @MainActor in
            self.isWatchReachable = isReachable
            if isReachable {
                self.connectionError = nil
                // Try to send any pending messages
                self.retryPendingMessages()
            }
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("Watch session became inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        logger.info("Watch session deactivated")
        Task { @MainActor in
            WCSession.default.activate()
        }
    }
    #endif
    
    // MARK: - Session Reply Helper

    nonisolated private static func makeSessionsReply() -> [String: Any] {
        var reply: [String: Any] = [
            "status": "success",
            "timestamp": Date().timeIntervalSince1970
        ]
        if let sessionsData = UserDefaults.standard.data(forKey: "cachedTrainingSessions") {
            reply["trainingSessions"] = sessionsData
            reply["sessionCount"] = UserDefaults.standard.integer(forKey: "sessionCount")
        } else {
            reply["status"] = "no_sessions"
        }
        return reply
    }
    
    // MARK: - Enhanced Connectivity Functions
    
    func forceSyncNow() {
        logger.info("🔄 Force Sync Now requested")
        
        // Step 1: Reactivate session
        forceSessionReactivation()
        
        // Step 2: Send ping message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendPingToWatch()
        }
        
        // Step 3: Initiate robust sync if connected
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if WCSession.default.isReachable {
                self.initiateRobustSync()
            }
        }
    }
    
    private func forceSessionReactivation() {
        logger.info("🔄 Force reactivating WCSession...")
        
        // Deactivate current session
        if WCSession.default.activationState == .activated {
            WCSession.default.delegate = nil
        }
        
        // Reactivate with fresh delegate
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        // Force connectivity check after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkConnectivityStatus()
        }
    }
    
    private func checkConnectivityStatus() {
        let session = WCSession.default
        
        logger.info("📊 WCSession Status Check:")
        logger.info("  - Activation State: \(session.activationState.rawValue)")
        logger.info("  - Is Paired: \(session.isPaired)")
        logger.info("  - Is Watch App Installed: \(session.isWatchAppInstalled)")
        logger.info("  - Is Reachable: \(session.isReachable)")
        
        // Update UI state
        Task { @MainActor in
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
            self.isWatchReachable = session.isReachable
            
            if session.isPaired && session.isWatchAppInstalled {
                self.connectionError = nil
                self.syncStatusText = session.isReachable ? "Connected" : "Paired (Not Reachable)"
            } else {
                self.connectionError = "Apple Watch not connected"
                self.syncStatusText = "Disconnected"
            }
        }
    }
    
    private func sendPingToWatch() {
        guard WCSession.default.isReachable else {
            logger.warning("Cannot ping watch - not reachable")
            return
        }
        
        let pingMessage: [String: Any] = [
            "action": "ping",
            "timestamp": Date().timeIntervalSince1970,
            "deviceType": "iPhone"
        ]
        
        WCSession.default.sendMessage(pingMessage) { reply in
            self.logger.info("✅ Ping successful - Watch responded: \(reply)")
            Task { @MainActor in
                self.connectionError = nil
                self.syncStatusText = "Connected"
            }
        } errorHandler: { error in
            self.logger.error("❌ Ping failed: \(error.localizedDescription)")
            Task { @MainActor in
                self.connectionError = "Communication failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func initiateRobustSync() {
        logger.info("🔄 Initiating robust sync with Watch")
        
        let storedSyncToken = UserDefaults.standard.string(forKey: "syncToken") ?? ""
        let storedDeviceId = UserDefaults.standard.string(forKey: "deviceId") ?? ""
        
        let syncMessage: [String: Any] = [
            "action": "syncTokenExchange",
            "syncToken": storedSyncToken,
            "deviceId": storedDeviceId,
            "deviceType": "iPhone",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(syncMessage) { reply in
            self.logger.info("✅ Robust sync initiated successfully")
        } errorHandler: { error in
            self.logger.error("❌ Robust sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Timer removed - cleanup handled by WCSession deactivation
    }
}

// Notification for results and new sessions
extension Notification.Name {
    static let didReceiveStarterProResults = Notification.Name("didReceiveStarterProResults")
    static let didReceiveTrainingSession = Notification.Name("didReceiveTrainingSession")
    static let watchRequestedSessions = Notification.Name("watchRequestedSessions")
}

