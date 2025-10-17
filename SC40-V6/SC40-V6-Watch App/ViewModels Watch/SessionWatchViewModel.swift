import Foundation
import Combine

// MARK: - Shared Types
struct WatchSprintSet: Codable, Sendable {
    let distanceYards: Int
    let reps: Int
    let intensity: String
}

struct WatchTrainingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let week: Int
    let day: Int
    let type: String
    let focus: String
    let sprints: [WatchSprintSet]
    let accessoryWork: [String]
    let notes: String?

    init(week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
    }
}

struct SessionFeedback: Codable, Sendable {
    let sessionId: UUID
    let difficulty: Int
    let enjoyment: Int
    let notes: String
    let timestamp: Date

    init(sessionId: UUID, difficulty: Int, enjoyment: Int, notes: String) {
        self.sessionId = sessionId
        self.difficulty = difficulty
        self.enjoyment = enjoyment
        self.notes = notes
        self.timestamp = Date()
    }
}

class ProgramPersistence: @unchecked Sendable {
    static let shared = ProgramPersistence()
    private let userDefaultsKey = "TrainingProgramData"
    
    func saveProgram<T: Codable>(_ program: T) {
        if let data = try? JSONEncoder().encode(program) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func loadProgram<T: Codable>(as type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }
}

extension ProgramPersistence {
    static func loadSessions() -> [WatchTrainingSession] {
        shared.loadProgram(as: [WatchTrainingSession].self) ?? []
    }
    static func loadFeedback() -> [SessionFeedback] {
        shared.loadProgram(as: [SessionFeedback].self) ?? []
    }
    static func saveFeedback(_ feedback: [SessionFeedback]) {
        shared.saveProgram(feedback)
    }
}

/// Loads and selects sessions for the Watch.
class SessionWatchViewModel: ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    
    @Published var sessions: [WatchTrainingSession] = []
    @Published var feedback: [SessionFeedback] = []
    
    init() {
        // Initialize objectWillChange first
        self.objectWillChange = ObservableObjectPublisher()
        // Then load data
        loadSessions()
        loadFeedback()
    }
    
    func loadSessions() {
        sessions = ProgramPersistence.loadSessions()
    }
    
    func loadFeedback() {
        feedback = ProgramPersistence.loadFeedback()
    }
    
    func addFeedback(_ newFeedback: SessionFeedback) {
        feedback.append(newFeedback)
        ProgramPersistence.saveFeedback(feedback)
        // Optionally trigger refresh on iPhone via App Group or notification
    }
}
