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
        // Load sessions from UserDefaults if available
        if let data = UserDefaults.standard.data(forKey: "trainingSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            self.trainingSessions = sessions
        }
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
        
        let fallbackSessions = [
            TrainingSession(
                week: 1, 
                day: 1, 
                type: "Speed Training", 
                focus: "Maximum Velocity", 
                sprints: [
                    SprintSet(distanceYards: 40, reps: 6, intensity: "Max"),
                    SprintSet(distanceYards: 60, reps: 4, intensity: "Max")
                ], 
                accessoryWork: ["Dynamic Warm-up", "Speed Mechanics", "Cool-down"]
            ),
            TrainingSession(
                week: 1, 
                day: 2, 
                type: "Pyramid Training", 
                focus: "Progressive Distance", 
                sprints: [
                    SprintSet(distanceYards: 20, reps: 2, intensity: "Max"),
                    SprintSet(distanceYards: 40, reps: 2, intensity: "Max"),
                    SprintSet(distanceYards: 60, reps: 2, intensity: "Max"),
                    SprintSet(distanceYards: 40, reps: 2, intensity: "Max"),
                    SprintSet(distanceYards: 20, reps: 2, intensity: "Max")
                ], 
                accessoryWork: ["Dynamic Warm-up", "Pyramid Progression", "Recovery"]
            )
        ]
        
        trainingSessions = fallbackSessions
        saveSessionsToStorage(fallbackSessions)
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
