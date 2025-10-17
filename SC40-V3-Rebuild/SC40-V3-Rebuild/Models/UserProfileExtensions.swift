import Foundation

// Extension to UserProfile that adds training session relationships
// This is separated to avoid circular dependency issues during compilation

public extension UserProfile {
    // Training session arrays added as extensions to break circular dependency
    private nonisolated(unsafe) static var sessionsStorage: [String: [TrainingSession]] = [:]
    private nonisolated(unsafe) static var completedSessionsStorage: [String: [TrainingSession]] = [:]
    
    private var storageKey: String {
        return "\(name)_\(age)_\(Int(baselineTime * 100))"
    }
    
    var sessions: [TrainingSession] {
        get {
            return Self.sessionsStorage[storageKey] ?? []
        }
        set {
            Self.sessionsStorage[storageKey] = newValue
        }
    }
    
    var completedSessions: [TrainingSession] {
        get {
            return Self.completedSessionsStorage[storageKey] ?? []
        }
        set {
            Self.completedSessionsStorage[storageKey] = newValue
        }
    }
}
