import SwiftUI
import Combine
import Foundation

@MainActor
class WatchSessionManager: ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var trainingSessions: [TrainingSession] = []
    @Published var isPhoneConnected = false
    @Published var isPhoneReachable = false
    
    init() {
        loadStoredSessions()
        createMockSessions() // For now, create mock sessions
    }
    
    private func loadStoredSessions() {
        // Load sessions from UserDefaults if available
        if let data = UserDefaults.standard.data(forKey: "trainingSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            self.trainingSessions = sessions
        }
    }
    
    private func createMockSessions() {
        // Create mock sessions for testing
        let mockSessions = [
            TrainingSession(
                week: 1, 
                day: 1, 
                type: "Sprint Training", 
                focus: "Acceleration", 
                sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "Max")], 
                accessoryWork: ["Dynamic Warm-up", "Cool-down"]
            ),
            TrainingSession(
                week: 1, 
                day: 2, 
                type: "Speed Endurance", 
                focus: "Lactate Tolerance", 
                sprints: [SprintSet(distanceYards: 60, reps: 4, intensity: "Sub-max")], 
                accessoryWork: ["Stretching", "Recovery"]
            )
        ]
        
        if trainingSessions.isEmpty {
            trainingSessions = mockSessions
            saveSessionsToStorage(mockSessions)
        }
    }
    
    func requestTrainingSessions() {
        print("📱 Requesting sessions from iPhone...")
        // For now, just simulate a delay and use mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createMockSessions()
        }
    }
    
    private func saveSessionsToStorage(_ sessions: [TrainingSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "trainingSessions")
        }
    }
}
