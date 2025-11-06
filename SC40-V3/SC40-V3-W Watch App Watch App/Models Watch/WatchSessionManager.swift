import SwiftUI
import Combine
import Foundation
import WatchConnectivity
import WatchKit

@MainActor
class WatchSessionManager: ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var trainingSessions: [TrainingSession] = []
    @Published var isPhoneConnected = false
    @Published var isPhoneReachable = false
    
    private var connectivityHandler: LiveWatchConnectivityHandler
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.connectivityHandler = LiveWatchConnectivityHandler.shared
        loadStoredSessions()
        setupConnectivityObservers()
        
        // Ensure we always have at least one session available immediately
        if trainingSessions.isEmpty {
            // Create immediate fallback session first
            createFallbackSessions()
            // Then try to sync with iPhone in background
            requestTrainingSessionsFromPhone()
        }
    }
    
    private func loadStoredSessions() {
        // ENHANCED SESSION LOADING: Handle both TrainingSession objects and raw JSON data
        
        // First try to load TrainingSession objects (from WatchSessionManager)
        if let data = UserDefaults.standard.data(forKey: "trainingSessions") {
            do {
                let sessions = try JSONDecoder.safeDecoder.decode([TrainingSession].self, from: data)
                self.trainingSessions = sessions
                print("✅ Watch: Loaded \(sessions.count) TrainingSession objects from storage")
                return
            } catch {
                print("⚠️ Watch: Failed to decode TrainingSession objects: \(error.localizedDescription)")
                // Continue to fallback method
            }
        }
        
        // Fallback: Load raw JSON data from LiveWatchConnectivityHandler
        if let data = UserDefaults.standard.data(forKey: "trainingSessions"),
           let sessionsArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            
            var parsedSessions: [TrainingSession] = []
            
            for sessionData in sessionsArray {
                if let session = parseTrainingSession(from: sessionData) {
                    parsedSessions.append(session)
                }
            }
            
            if !parsedSessions.isEmpty {
                self.trainingSessions = parsedSessions
                // Re-save as proper TrainingSession objects for future loads
                saveSessionsToStorage(parsedSessions)
                print("✅ Watch: Parsed \(parsedSessions.count) sessions from JSON data and converted to TrainingSession objects")
                return
            }
        }
        
        print("⚠️ Watch: No stored sessions found - will request from iPhone or use fallback")
    }
    
    private func setupConnectivityObservers() {
        // Observe connectivity status changes
        connectivityHandler.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isPhoneConnected = isConnected
                if isConnected {
                    self?.requestTrainingSessionsFromPhone()
                }
            }
            .store(in: &cancellables)
        
        // CRITICAL FIX: Listen for training sessions updates from LiveWatchConnectivityHandler
        NotificationCenter.default.publisher(for: NSNotification.Name("trainingSessionsUpdated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("🔄 Watch: Training sessions updated notification received - refreshing session data")
                self?.loadStoredSessions()
                self?.objectWillChange.send() // Force UI update
            }
            .store(in: &cancellables)
        
        // REAL-TIME PROFILE UPDATES: Listen for profile changes that affect sessions
        NotificationCenter.default.publisher(for: NSNotification.Name("profileDataUpdated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("🔄 Watch: Profile updated - requesting fresh sessions from iPhone")
                self?.requestTrainingSessionsFromPhone()
            }
            .store(in: &cancellables)
    }
    
    func requestTrainingSessionsFromPhone() {
        print("📱 Requesting training sessions from iPhone...")
        
        guard WCSession.default.isReachable else {
            print("⚠️ iPhone not reachable, using stored sessions")
            createFallbackSessions()
            return
        }
        
        let message: [String: Any] = [
            "type": "request_sessions",
            "timestamp": Date().timeIntervalSince1970,
            "watchInfo": [
                "model": WKInterfaceDevice.current().model,
                "systemVersion": WKInterfaceDevice.current().systemVersion
            ]
        ]
        
        WCSession.default.sendMessage(message) { [weak self] reply in
            Task { @MainActor in
                self?.handleSessionsResponse(reply)
            }
        } errorHandler: { [weak self] error in
            Task { @MainActor in
                print("❌ Failed to request sessions: \(error.localizedDescription)")
                self?.createFallbackSessions()
            }
        }
    }
    
    private func handleSessionsResponse(_ response: [String: Any]) {
        print("✅ Received sessions response from iPhone")
        
        guard let sessionsData = response["sessions"] as? [[String: Any]] else {
            print("⚠️ No sessions data in response, using fallback")
            createFallbackSessions()
            return
        }
        
        // Parse sessions from iPhone response with error handling
        var receivedSessions: [TrainingSession] = []
        var parseErrors = 0
        
        for (index, sessionData) in sessionsData.enumerated() {
            if let session = parseTrainingSession(from: sessionData) {
                receivedSessions.append(session)
            } else {
                parseErrors += 1
                print("❌ Watch: Failed to parse session \(index + 1)")
            }
        }
        
        if !receivedSessions.isEmpty {
            // Ensure main thread update
            DispatchQueue.main.async {
                self.trainingSessions = receivedSessions
                self.saveSessionsToStorage(receivedSessions)
                print("✅ SYNC SUCCESS: Loaded \(receivedSessions.count) sessions from iPhone (\(parseErrors) parse errors)")
                
                // Log session details for first 2 weeks
                let firstTwoWeeks = receivedSessions.filter { $0.week <= 2 }.sorted { ($0.week, $0.day) < ($1.week, $1.day) }
                print("📋 First 2 weeks available: \(firstTwoWeeks.count) sessions")
                for session in firstTwoWeeks.prefix(4) {
                    print("   • W\(session.week)D\(session.day): \(session.safeType)")
                }
            }
        } else {
            print("⚠️ SYNC FAILED: No valid sessions parsed (\(parseErrors) errors), using pyramid fallback")
            createFallbackSessions()
        }
    }
    
    private func parseTrainingSession(from data: [String: Any]) -> TrainingSession? {
        // Safe parsing with fallback values
        guard let week = data["week"] as? Int,
              let day = data["day"] as? Int else {
            print("❌ Watch: Missing required week/day data in session")
            return nil
        }
        
        // Safe string parsing with fallbacks
        let type = (data["type"] as? String)?.safeValue ?? "Speed Training"
        let focus = (data["focus"] as? String)?.safeValue ?? "Performance Development"
        let notes = data["notes"] as? String
        
        // Parse sprints with safe conversion
        var sprints: [SprintSet] = []
        if let sprintsData = data["sprints"] as? [[String: Any]] {
            for sprintData in sprintsData {
                // Handle both Int and Double for distance
                let distance: Int
                if let intDistance = sprintData["distanceYards"] as? Int {
                    distance = intDistance
                } else if let doubleDistance = sprintData["distanceYards"] as? Double {
                    distance = Int(doubleDistance)
                } else {
                    print("⚠️ Watch: Invalid distance in sprint data, skipping")
                    continue
                }
                
                let reps = sprintData["reps"] as? Int ?? 1
                let intensity = (sprintData["intensity"] as? String)?.safeValue ?? "Moderate"
                
                sprints.append(SprintSet(distanceYards: distance, reps: reps, intensity: intensity))
            }
        }
        
        // Ensure we have at least one sprint
        if sprints.isEmpty {
            sprints = [SprintSet(distanceYards: 40, reps: 1, intensity: "Moderate")]
            print("⚠️ Watch: No sprints found, added default 40yd sprint")
        }
        
        // Parse accessory work
        let accessoryWork = data["accessoryWork"] as? [String] ?? ["Dynamic Warm-up", "Cool-down"]
        
        return TrainingSession(
            week: week,
            day: day,
            type: type,
            focus: focus,
            sprints: sprints,
            accessoryWork: accessoryWork,
            notes: notes
        )
    }
    
    private func createFallbackSessions() {
        // Only create fallback sessions if we have no stored sessions
        guard trainingSessions.isEmpty else { 
            print("📋 Sessions already exist (\(trainingSessions.count)), skipping fallback creation")
            return 
        }
        
        print("⚠️ Creating immediate W1/D1 pyramid fallback session - iPhone sync unavailable")
        
        // Create immediate W1/D1 pyramid session (10, 20, 30, 40, 30, 20, 10)
        let pyramidSession = createPyramidFallbackSession()
        
        trainingSessions = [pyramidSession]
        saveSessionsToStorage([pyramidSession])
        
        print("✅ Created immediate W1/D1 pyramid fallback session - ready to use!")
        print("🏃‍♂️ Pyramid structure: 10, 20, 30, 40, 30, 20, 10 yards")
        print("📊 Session details: \(pyramidSession.type) - \(pyramidSession.focus)")
        print("🏃‍♂️ Sprint sets: \(pyramidSession.sprints.count) sets")
    }
    
    private func createPyramidFallbackSession() -> TrainingSession {
        // Create pyramid sprint sets: 10, 20, 30, 40, 30, 20, 10 yards
        let pyramidSprints = [
            SprintSet(distanceYards: 10, reps: 1, intensity: "Build"),
            SprintSet(distanceYards: 20, reps: 1, intensity: "Moderate"),
            SprintSet(distanceYards: 30, reps: 1, intensity: "Strong"),
            SprintSet(distanceYards: 40, reps: 1, intensity: "Max"),
            SprintSet(distanceYards: 30, reps: 1, intensity: "Strong"),
            SprintSet(distanceYards: 20, reps: 1, intensity: "Moderate"),
            SprintSet(distanceYards: 10, reps: 1, intensity: "Build")
        ]
        
        // Create basic accessory work
        let accessoryWork = [
            "5 min dynamic warm-up",
            "2x10 high knees",
            "2x10 butt kicks",
            "2x10 leg swings",
            "5 min cool-down walk"
        ]
        
        return TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Pyramid Sprint Workout",
            focus: "Speed Development & Conditioning",
            sprints: pyramidSprints,
            accessoryWork: accessoryWork
        )
    }
    
    private func generateLevelAppropriateSessions(level: String, frequency: Int) -> [TrainingSession] {
        // Use Unified Session Generator to ensure iPhone/Watch synchronization
        let unifiedGenerator = UnifiedSessionGenerator.shared
        let allSessions = unifiedGenerator.generateUnified12WeekProgram(
            userLevel: level,
            frequency: frequency,
            userPreferences: nil
        )
        
        print("⌚ Watch: Generated \(allSessions.count) unified sessions")
        print("⌚ Watch: Sessions will match iPhone exactly for W1/D1 through W12/D\(frequency)")
        
        // Return first week sessions for immediate display, but store all sessions
        let firstWeekSessions = allSessions.filter { $0.week == 1 }
        
        // Store all sessions for future use
        trainingSessions = allSessions
        saveSessionsToStorage(allSessions)
        
        return firstWeekSessions
    }
    
    private func createSessionForLevel(level: String, week: Int, day: Int) -> TrainingSession {
        switch level.lowercased() {
        case "beginner":
            return createBeginnerSession(week: week, day: day)
        case "intermediate":
            return createIntermediateSession(week: week, day: day)
        case "advanced":
            return createAdvancedSession(week: week, day: day)
        case "pro", "elite":
            return createProSession(week: week, day: day)
        default:
            return createBeginnerSession(week: week, day: day)
        }
    }
    
    private func createBeginnerSession(week: Int, day: Int) -> TrainingSession {
        let sessionTypes = ["Basic Speed", "Acceleration", "Form Running"]
        let focuses = ["Technique Focus", "Speed Development", "Movement Quality"]
        
        return TrainingSession(
            week: week,
            day: day,
            type: sessionTypes[day % sessionTypes.count],
            focus: focuses[day % focuses.count],
            sprints: [
                SprintSet(distanceYards: 20, reps: 3, intensity: "Moderate"),
                SprintSet(distanceYards: 30, reps: 3, intensity: "Moderate")
            ],
            accessoryWork: ["Dynamic Warm-up", "Basic Drills", "Cool-down"]
        )
    }
    
    private func createIntermediateSession(week: Int, day: Int) -> TrainingSession {
        let sessionTypes = ["Speed Development", "Acceleration Work", "Tempo Running"]
        let focuses = ["Speed Building", "Power Development", "Endurance Speed"]
        
        return TrainingSession(
            week: week,
            day: day,
            type: sessionTypes[day % sessionTypes.count],
            focus: focuses[day % focuses.count],
            sprints: [
                SprintSet(distanceYards: 30, reps: 4, intensity: "High"),
                SprintSet(distanceYards: 40, reps: 3, intensity: "High")
            ],
            accessoryWork: ["Dynamic Warm-up", "Speed Drills", "Recovery"]
        )
    }
    
    private func createAdvancedSession(week: Int, day: Int) -> TrainingSession {
        let sessionTypes = ["High-Intensity Speed", "Power Development", "Speed Endurance"]
        let focuses = ["Maximum Velocity", "Explosive Power", "Speed Maintenance"]
        
        return TrainingSession(
            week: week,
            day: day,
            type: sessionTypes[day % sessionTypes.count],
            focus: focuses[day % focuses.count],
            sprints: [
                SprintSet(distanceYards: 40, reps: 4, intensity: "Max"),
                SprintSet(distanceYards: 50, reps: 3, intensity: "Max")
            ],
            accessoryWork: ["Dynamic Warm-up", "Advanced Drills", "Recovery Work"]
        )
    }
    
    private func createProSession(week: Int, day: Int) -> TrainingSession {
        let sessionTypes = ["Elite Speed Training", "Maximum Power", "Competition Prep"]
        let focuses = ["Peak Velocity", "Elite Performance", "Race Preparation"]
        
        return TrainingSession(
            week: week,
            day: day,
            type: sessionTypes[day % sessionTypes.count],
            focus: focuses[day % focuses.count],
            sprints: [
                SprintSet(distanceYards: 40, reps: 5, intensity: "Max"),
                SprintSet(distanceYards: 60, reps: 4, intensity: "Max"),
                SprintSet(distanceYards: 80, reps: 2, intensity: "Max")
            ],
            accessoryWork: ["Elite Warm-up", "Competition Drills", "Performance Recovery"]
        )
    }
    
    // Legacy method for backward compatibility
    func requestTrainingSessions() {
        requestTrainingSessionsFromPhone()
    }
    
    private func saveSessionsToStorage(_ sessions: [TrainingSession]) {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(sessions)
            UserDefaults.standard.set(data, forKey: "trainingSessions")
            print("✅ Watch: Saved \(sessions.count) sessions to storage")
        } catch {
            print("❌ Watch: Failed to save sessions to storage: \(error.localizedDescription)")
        }
    }
}
