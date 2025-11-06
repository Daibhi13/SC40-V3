import Foundation
import SwiftUI
import Combine

/// Session rotation and variety management system
@MainActor
class SessionRotationManager: ObservableObject {
    static let shared = SessionRotationManager()
    
    // MARK: - Published Properties
    @Published var weeklySessionHistory: [Date: RestRecoveryManager.SessionType] = [:]
    @Published var currentWeekSessions: [RestRecoveryManager.SessionType] = []
    @Published var availableSessions: [SprintSessionTemplate] = []
    @Published var recommendedNextSession: SprintSessionTemplate?
    
    // MARK: - Private Properties
    private var sessionHistory: [SessionHistoryEntry] = []
    private let maxHistoryDays = 30
    
    private init() {
        loadSessionHistory()
        updateCurrentWeekSessions()
    }
    
    // MARK: - Core Methods
    
    /// Check if user can perform a specific session type today
    func canPerformSessionType(_ sessionType: RestRecoveryManager.SessionType) -> SessionPermission {
        let currentWeek = getCurrentWeekSessions()
        let sessionCount = currentWeek.filter { $0 == sessionType }.count
        
        // Check weekly frequency limits
        if sessionCount >= sessionType.maxWeeklyFrequency {
            return .denied(
                reason: "Already completed \(sessionType.rawValue) \(sessionCount) time(s) this week",
                alternatives: getAlternativeSessionTypes(excluding: sessionType)
            )
        }
        
        // Check if same session type was done yesterday (for high-intensity sessions)
        if isHighIntensitySession(sessionType) && wasSessionTypePerformedYesterday(sessionType) {
            return .cautioned(
                reason: "Same high-intensity session type performed yesterday",
                alternatives: getLowerIntensityAlternatives()
            )
        }
        
        return .approved(reason: "Session type available for training")
    }
    
    /// Get recommended session based on training history and variety
    func getRecommendedSession(for trainingFrequency: RestRecoveryManager.TrainingFrequency, 
                              userLevel: String) -> SprintSessionTemplate? {
        let currentWeek = getCurrentWeekSessions()
        let availableTypes = getAvailableSessionTypes(currentWeek: currentWeek)
        
        // Prioritize session types based on training frequency
        let prioritizedTypes = prioritizeSessionTypes(
            availableTypes: availableTypes,
            trainingFrequency: trainingFrequency,
            currentWeek: currentWeek
        )
        
        // Get sessions from library matching the prioritized type and user level
        guard let targetType = prioritizedTypes.first else { return nil }
        
        let matchingSessions = sessionLibrary.filter { session in
            getSessionTypeFromFocus(session.focus) == targetType &&
            (session.level.lowercased() == userLevel.lowercased() || session.level.lowercased() == "all levels")
        }
        
        // Return a session that hasn't been done recently
        return selectVariedSession(from: matchingSessions)
    }
    
    /// Record completed session for variety tracking
    func recordSessionCompletion(_ session: SprintSessionTemplate) {
        let sessionType = getSessionTypeFromFocus(session.focus)
        let entry = SessionHistoryEntry(
            date: Date(),
            sessionId: session.id,
            sessionType: sessionType,
            distance: session.distance,
            reps: session.reps,
            focus: session.focus
        )
        
        sessionHistory.append(entry)
        
        // Keep only recent history
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxHistoryDays, to: Date()) ?? Date()
        sessionHistory = sessionHistory.filter { $0.date >= cutoffDate }
        
        updateCurrentWeekSessions()
        saveSessionHistory()
    }
    
    /// Get session by type and user level
    func getSessionByType(_ sessionType: RestRecoveryManager.SessionType?, userLevel: String) -> SprintSessionTemplate? {
        guard let sessionType = sessionType else { return nil }
        
        let matchingSessions = sessionLibrary.filter { session in
            getSessionTypeFromFocus(session.focus) == sessionType &&
            (session.level.lowercased() == userLevel.lowercased() || session.level.lowercased() == "all levels")
        }
        
        return selectVariedSession(from: matchingSessions)
    }
    
    // MARK: - Session Type Mapping
    
    /// Map session focus to session type for categorization
    func getSessionTypeFromFocus(_ focus: String) -> RestRecoveryManager.SessionType {
        let focusLower = focus.lowercased()
        
        if focusLower.contains("acceleration") || focusLower.contains("start") || focusLower.contains("explosive") {
            return .acceleration
        } else if focusLower.contains("drive") {
            return .drivePhase
        } else if focusLower.contains("max velocity") || focusLower.contains("peak velocity") || focusLower.contains("top-end") || focusLower.contains("max speed") {
            return .maxVelocity
        } else if focusLower.contains("speed endurance") || focusLower.contains("repeat") || focusLower.contains("endurance") {
            return .speedEndurance
        } else if focusLower.contains("active recovery") {
            return .activeRecovery
        } else if focusLower.contains("benchmark") || focusLower.contains("time trial") {
            return .benchmark
        } else if focusLower.contains("tempo") {
            return .tempo
        } else {
            // Default mapping based on distance
            let distance = extractDistanceFromFocus(focus)
            if distance <= 25 {
                return .acceleration
            } else if distance <= 45 {
                return .drivePhase
            } else {
                return .maxVelocity
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentWeekSessions() -> [RestRecoveryManager.SessionType] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        return sessionHistory
            .filter { $0.date >= startOfWeek }
            .map { $0.sessionType }
    }
    
    private func updateCurrentWeekSessions() {
        currentWeekSessions = getCurrentWeekSessions()
    }
    
    private func getAvailableSessionTypes(currentWeek: [RestRecoveryManager.SessionType]) -> [RestRecoveryManager.SessionType] {
        return RestRecoveryManager.SessionType.allCases.filter { sessionType in
            let currentCount = currentWeek.filter { $0 == sessionType }.count
            return currentCount < sessionType.maxWeeklyFrequency
        }
    }
    
    private func prioritizeSessionTypes(
        availableTypes: [RestRecoveryManager.SessionType],
        trainingFrequency: RestRecoveryManager.TrainingFrequency,
        currentWeek: [RestRecoveryManager.SessionType]
    ) -> [RestRecoveryManager.SessionType] {
        
        // Sort by priority and how long since last performed
        return availableTypes.sorted { type1, type2 in
            let priority1 = getSessionTypePriority(type1, frequency: trainingFrequency)
            let priority2 = getSessionTypePriority(type2, frequency: trainingFrequency)
            
            if priority1 != priority2 {
                return priority1 < priority2 // Lower number = higher priority
            }
            
            // If same priority, prefer the one not done this week
            let count1 = currentWeek.filter { $0 == type1 }.count
            let count2 = currentWeek.filter { $0 == type2 }.count
            
            return count1 < count2
        }
    }
    
    private func getSessionTypePriority(_ sessionType: RestRecoveryManager.SessionType, 
                                      frequency: RestRecoveryManager.TrainingFrequency) -> Int {
        switch frequency {
        case .casual:
            // Focus on fundamentals
            switch sessionType {
            case .acceleration: return 1
            case .drivePhase: return 2
            case .maxVelocity: return 3
            case .activeRecovery: return 4
            case .tempo: return 5
            case .speedEndurance: return 6
            case .benchmark: return 7
            }
        case .regular:
            // Balanced approach
            switch sessionType {
            case .acceleration: return 1
            case .drivePhase: return 1
            case .maxVelocity: return 2
            case .tempo: return 3
            case .speedEndurance: return 4
            case .activeRecovery: return 5
            case .benchmark: return 6
            }
        case .serious:
            // Advanced variety
            switch sessionType {
            case .acceleration: return 1
            case .drivePhase: return 1
            case .maxVelocity: return 1
            case .speedEndurance: return 2
            case .tempo: return 2
            case .benchmark: return 3
            case .activeRecovery: return 4
            }
        }
    }
    
    private func selectVariedSession(from sessions: [SprintSessionTemplate]) -> SprintSessionTemplate? {
        guard !sessions.isEmpty else { return nil }
        
        let recentSessions = getRecentSessionHistory(days: 14) // Last 2 weeks
        let recentSessionIds = Set(recentSessions.map { $0.sessionId })
        
        // Filter out recently performed sessions
        let unperformedSessions = sessions.filter { !recentSessionIds.contains($0.id) }
        
        if !unperformedSessions.isEmpty {
            // Prioritize sessions not done recently
            return selectByVarietyScore(unperformedSessions)
        } else {
            // If all sessions have been done recently, pick the least recent
            return selectLeastRecentSession(sessions, recentHistory: recentSessions)
        }
    }
    
    private func selectByVarietyScore(_ sessions: [SprintSessionTemplate]) -> SprintSessionTemplate? {
        // Score sessions based on variety factors
        let scoredSessions = sessions.map { session in
            (session: session, score: calculateVarietyScore(session))
        }
        
        // Return session with highest variety score
        return scoredSessions.max(by: { $0.score < $1.score })?.session
    }
    
    private func calculateVarietyScore(_ session: SprintSessionTemplate) -> Double {
        var score: Double = 0
        
        // Distance variety (prefer different distances from recent sessions)
        let recentDistances = getRecentDistances(days: 7)
        if !recentDistances.contains(session.distance) {
            score += 3.0
        }
        
        // Rep count variety
        let recentRepCounts = getRecentRepCounts(days: 7)
        if !recentRepCounts.contains(session.reps) {
            score += 2.0
        }
        
        // Focus variety
        let recentFocuses = getRecentFocuses(days: 7)
        if !recentFocuses.contains(session.focus) {
            score += 2.5
        }
        
        // Session type variety
        let recentTypes = getRecentSessionTypes(days: 7)
        let sessionType = getSessionTypeFromFocus(session.focus)
        if !recentTypes.contains(sessionType) {
            score += 4.0
        }
        
        return score
    }
    
    private func getRecentSessionHistory(days: Int) -> [SessionHistoryEntry] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessionHistory.filter { $0.date >= cutoffDate }
    }
    
    private func getRecentDistances(days: Int) -> Set<Int> {
        return Set(getRecentSessionHistory(days: days).map { $0.distance })
    }
    
    private func getRecentRepCounts(days: Int) -> Set<Int> {
        return Set(getRecentSessionHistory(days: days).map { $0.reps })
    }
    
    private func getRecentFocuses(days: Int) -> Set<String> {
        return Set(getRecentSessionHistory(days: days).map { $0.focus })
    }
    
    private func getRecentSessionTypes(days: Int) -> Set<RestRecoveryManager.SessionType> {
        return Set(getRecentSessionHistory(days: days).map { $0.sessionType })
    }
    
    private func selectLeastRecentSession(_ sessions: [SprintSessionTemplate], 
                                        recentHistory: [SessionHistoryEntry]) -> SprintSessionTemplate? {
        // Find the session that was performed longest ago
        let sessionDates = Dictionary(uniqueKeysWithValues: recentHistory.map { ($0.sessionId, $0.date) })
        
        return sessions.min { session1, session2 in
            let date1 = sessionDates[session1.id] ?? Date.distantPast
            let date2 = sessionDates[session2.id] ?? Date.distantPast
            return date1 < date2
        }
    }
    
    private func isHighIntensitySession(_ sessionType: RestRecoveryManager.SessionType) -> Bool {
        return sessionType.intensity >= 0.8
    }
    
    private func wasSessionTypePerformedYesterday(_ sessionType: RestRecoveryManager.SessionType) -> Bool {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday) ?? Date()
        
        return sessionHistory.contains { entry in
            entry.date >= startOfYesterday && entry.date < endOfYesterday && entry.sessionType == sessionType
        }
    }
    
    private func getAlternativeSessionTypes(excluding sessionType: RestRecoveryManager.SessionType) -> [RestRecoveryManager.SessionType] {
        return RestRecoveryManager.SessionType.allCases.filter { $0 != sessionType }
    }
    
    private func getLowerIntensityAlternatives() -> [RestRecoveryManager.SessionType] {
        return RestRecoveryManager.SessionType.allCases.filter { $0.intensity < 0.7 }
    }
    
    private func extractDistanceFromFocus(_ focus: String) -> Int {
        // Extract distance from focus string (e.g., "40 yd Sprint" -> 40)
        let numbers = focus.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.first ?? 40 // Default to 40 if no distance found
    }
    
    // MARK: - Persistence
    
    private func saveSessionHistory() {
        if let encoded = try? JSONEncoder().encode(sessionHistory) {
            UserDefaults.standard.set(encoded, forKey: "sessionHistory")
        }
    }
    
    private func loadSessionHistory() {
        if let data = UserDefaults.standard.data(forKey: "sessionHistory"),
           let decoded = try? JSONDecoder().decode([SessionHistoryEntry].self, from: data) {
            sessionHistory = decoded
        }
    }
}

// MARK: - Supporting Enums and Structs

enum SessionPermission {
    case approved(reason: String)
    case cautioned(reason: String, alternatives: [RestRecoveryManager.SessionType])
    case denied(reason: String, alternatives: [RestRecoveryManager.SessionType])
}

struct SessionHistoryEntry: Codable {
    let date: Date
    let sessionId: Int
    let sessionType: RestRecoveryManager.SessionType
    let distance: Int
    let reps: Int
    let focus: String
}

// MARK: - Extensions

extension RestRecoveryManager.SessionType {
    var maxWeeklyFrequency: Int {
        switch self {
        case .acceleration: return 2      // Can do twice per week
        case .drivePhase: return 2        // Can do twice per week
        case .maxVelocity: return 1       // Once per week max
        case .speedEndurance: return 1    // Once per week max
        case .tempo: return 2             // Can do twice per week
        case .activeRecovery: return 3    // Multiple times per week
        case .benchmark: return 1         // Once per week max
        }
    }
}
