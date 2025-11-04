import Foundation
import Combine
import SwiftUI

// UserProfileManager handles session management for UserProfile
public final class UserProfileManager {
    // MARK: - Shared Instance
    public static let shared = UserProfileManager()
    
    // MARK: - Storage
    private var _sessionsStorage: [String: [TrainingSession]] = [:]
    private var _completedSessionsStorage: [String: [TrainingSession]] = [:]
    
    private var storageKey: String {
        return "\(name)_\(age)_\(Int(baselineTime * 100))"
    }
    
    public var sessions: [TrainingSession] {
        get {
            return Self._sessionsStorage[storageKey] ?? []
        }
        set {
            Self._sessionsStorage[storageKey] = newValue
        }
    }
    
    public var completedSessions: [TrainingSession] {
        get {
            return Self._completedSessionsStorage[storageKey] ?? []
        }
        set {
            Self._completedSessionsStorage[storageKey] = newValue
        }
    }
    
    // MARK: - Computed Properties
    
    /// Calculates a consistency score based on completed sessions
    public var consistencyScore: Int {
        let totalSessions = sessions.count
        guard totalSessions > 0 else { return 0 }
        let completedCount = completedSessions.count
        return min(100, (completedCount * 100) / totalSessions)
    }
    
    /// Calculates the current streak of days with at least one completed session
    public var streakDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        var streak = 0
        
        // Sort completed sessions by date (newest first)
        let sortedSessions = completedSessions.sorted { 
            ($0.completionDate ?? .distantPast) > ($1.completionDate ?? .distantPast) 
        }
        
        // Check for consecutive days with completed sessions
        for session in sortedSessions {
            guard let sessionDate = session.completionDate else { continue }
            let sessionDay = calendar.startOfDay(for: sessionDate)
            
            if sessionDay == currentDate {
                // Session is on the current day of the streak
                continue
            } else if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate),
                      calendar.isDate(sessionDay, inSameDayAs: previousDay) {
                // Session is on the previous day, continue the streak
                currentDate = sessionDay
                streak += 1
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Session Management Methods
    
    /// Adds a new training session to the user's profile
    public mutating func addSession(_ session: TrainingSession) {
        var currentSessions = sessions
        currentSessions.append(session)
        sessions = currentSessions
    }
    
    /// Marks a session as completed
    public mutating func completeSession(_ sessionId: UUID, completionDate: Date = Date()) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        var session = sessions[index]
        session.isCompleted = true
        session.completionDate = completionDate
        
        // Remove from active sessions
        sessions.remove(at: index)
        
        // Add to completed sessions
        var completed = completedSessions
        completed.append(session)
        completedSessions = completed
    }
    
    /// Gets all sessions for a specific week
    public func sessionsForWeek(_ week: Int) -> [TrainingSession] {
        return sessions.filter { $0.week == week } + 
               completedSessions.filter { $0.week == week }
    }
}
