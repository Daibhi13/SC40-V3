import Foundation

// Basic persistence for training programs
class ProgramPersistence: @unchecked Sendable {
    static let shared = ProgramPersistence()
    private let userDefaultsKey = "TrainingProgramData"
    
    func saveProgram<T: Codable>(_ program: T) {
        if let data = try? JSONEncoder().encode(program) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func loadProgram<T: Codable>(as type: T.Type) -> T? {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let program = try? JSONDecoder().decode(T.self, from: data) {
            return program
        }
        return nil
    }
    
    func clearProgram() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - Watch-specific persistence helpers
extension ProgramPersistence {
    static func loadSessions() -> [TrainingSession] {
        shared.loadProgram(as: [TrainingSession].self) ?? []
    }
    static func loadFeedback() -> [SessionFeedback] {
        shared.loadProgram(as: [SessionFeedback].self) ?? []
    }
    static func saveFeedback(_ feedback: [SessionFeedback]) {
        shared.saveProgram(feedback)
    }
    static func saveSessions(_ sessions: [TrainingSession]) {
        shared.saveProgram(sessions)
    }
}
