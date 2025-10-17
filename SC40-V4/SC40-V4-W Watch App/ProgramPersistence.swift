// ProgramPersistence shim for Watch target
// This file allows the Watch target to access ProgramPersistence from the main app target.
// It simply imports the main app's ProgramPersistence class for use in the Watch target.

import Foundation

// Local definitions for Watch App
public struct TrainingSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let week: Int
    public let day: Int
    public let type: String
    public let focus: String
    public let sprints: [SprintSet]
    public let accessoryWork: [String]
    public let notes: String?
    
    public init(week: Int, day: Int, type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String? = nil) {
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

public struct SprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String
}

public struct SessionFeedback: Codable, Sendable {
    public let sessionID: UUID
    public let rating: Int
    public let notes: String?
    public let date: Date
}
// Import the main app module if needed (replace 'SC40_V3' with your main app's module name)
// @testable import SC40_V3

// If the main app's module is not accessible, you may need to:
// 1. Add ProgramPersistence.swift to a shared framework or to the Watch target's Compile Sources.
// 2. Or, copy the class definition here (not recommended for DRY, but works for now).

// For now, copy the class definition for Watch target:

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
}
