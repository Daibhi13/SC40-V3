// ProgramPersistence shim for Watch target
// This file allows the Watch target to access ProgramPersistence from the main app target.
// It simply imports the main app's ProgramPersistence class for use in the Watch target.

import Foundation
// Import the main app module if needed (replace 'SC40_V3' with your main app's module name)
// @testable import SC40_V3

// If the main app's module is not accessible, you may need to:
// 1. Add ProgramPersistence.swift to a shared framework or to the Watch target's Compile Sources.
// 2. Or, copy the class definition here (not recommended for DRY, but works for now).

// MARK: - Local Type Definitions (required for file access)
struct WatchSprintSet: Codable, Sendable {
    let distanceYards: Int
    let reps: Int
    let intensity: String

    init(distanceYards: Int, reps: Int, intensity: String) {
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
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
    let isCompleted: Bool

    init(id: UUID = UUID(), week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = isCompleted
    }

    init(week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = false
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
