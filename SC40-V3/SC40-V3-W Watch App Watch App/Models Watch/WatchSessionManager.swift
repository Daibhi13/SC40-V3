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
        
        // Only create mock sessions if no stored sessions and no phone connection
        if trainingSessions.isEmpty {
            requestTrainingSessionsFromPhone()
        }
    }
    
    private func loadStoredSessions() {
        // ENHANCED SESSION LOADING: Handle both TrainingSession objects and raw JSON data
        
        // First try to load TrainingSession objects (from WatchSessionManager)
        if let data = UserDefaults.standard.data(forKey: "trainingSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            self.trainingSessions = sessions
            print("✅ Watch: Loaded \(sessions.count) TrainingSession objects from storage")
            return
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
        
        // Parse sessions from iPhone response
        var receivedSessions: [TrainingSession] = []
        
        for sessionData in sessionsData {
            if let session = parseTrainingSession(from: sessionData) {
                receivedSessions.append(session)
            }
        }
        
        if !receivedSessions.isEmpty {
            self.trainingSessions = receivedSessions
            saveSessionsToStorage(receivedSessions)
            print("✅ Loaded \(receivedSessions.count) sessions from iPhone")
        } else {
            createFallbackSessions()
        }
    }
    
    private func parseTrainingSession(from data: [String: Any]) -> TrainingSession? {
        guard let week = data["week"] as? Int,
              let day = data["day"] as? Int,
              let type = data["type"] as? String,
              let focus = data["focus"] as? String else {
            return nil
        }
        
        // Parse sprints
        var sprints: [SprintSet] = []
        if let sprintsData = data["sprints"] as? [[String: Any]] {
            for sprintData in sprintsData {
                if let distance = sprintData["distanceYards"] as? Int,
                   let reps = sprintData["reps"] as? Int,
                   let intensity = sprintData["intensity"] as? String {
                    sprints.append(SprintSet(distanceYards: distance, reps: reps, intensity: intensity))
                }
            }
        }
        
        // Parse accessory work
        let accessoryWork = data["accessoryWork"] as? [String] ?? []
        
        return TrainingSession(
            week: week,
            day: day,
            type: type,
            focus: focus,
            sprints: sprints,
            accessoryWork: accessoryWork
        )
    }
    
    private func createFallbackSessions() {
        // Only create fallback sessions if we have no stored sessions
        guard trainingSessions.isEmpty else { return }
        
        print("⚠️ Creating fallback sessions - iPhone sync unavailable")
        
        // Get user's onboarding data from UserDefaults
        let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Beginner"
        let frequency = UserDefaults.standard.integer(forKey: "trainingFrequency")
        let actualFrequency = frequency > 0 ? frequency : 1 // Default to 1 day if not set
        
        print("📋 Generating fallback sessions for: \(userLevel) level, \(actualFrequency) days/week")
        
        let fallbackSessions = generateLevelAppropriateSessions(
            level: userLevel, 
            frequency: actualFrequency
        )
        
        trainingSessions = fallbackSessions
        saveSessionsToStorage(fallbackSessions)
        
        print("✅ Created \(fallbackSessions.count) fallback sessions based on user profile")
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
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "trainingSessions")
        }
    }
}
