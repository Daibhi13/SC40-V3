import Foundation
import Combine

// MARK: - Session Mixing Engine for Comprehensive Training

struct SessionMixingEngine {
    
    // MARK: - Session Type Distribution Rules
    
    /// Defines the optimal session type distribution based on training frequency and level
    static func getSessionTypeDistribution(frequency: Int, level: String) -> SessionTypeDistribution {
        switch frequency {
        case 1:
            return SessionTypeDistribution(
                speed: 1.0,
                flying: 0.0,
                endurance: 0.0,
                pyramidUp: 0.0,
                pyramidDown: 0.0,
                pyramidUpDown: 0.0,
                activeRecovery: 0.0,
                recovery: 0.0
            )
            
        case 2:
            return SessionTypeDistribution(
                speed: 0.5,
                flying: 0.0,
                endurance: 0.5,
                pyramidUp: 0.0,
                pyramidDown: 0.0,
                pyramidUpDown: 0.0,
                activeRecovery: 0.0,
                recovery: 0.0
            )
            
        case 3:
            return SessionTypeDistribution(
                speed: 0.4,
                flying: 0.2,
                endurance: 0.2,
                pyramidUp: 0.2,
                pyramidDown: 0.0,
                pyramidUpDown: 0.0,
                activeRecovery: 0.0,
                recovery: 0.0
            )
            
        case 4:
            return SessionTypeDistribution(
                speed: 0.3,
                flying: 0.2,
                endurance: 0.2,
                pyramidUp: 0.15,
                pyramidDown: 0.15,
                pyramidUpDown: 0.0,
                activeRecovery: 0.0,
                recovery: 0.0
            )
            
        case 5:
            return SessionTypeDistribution(
                speed: 0.25,
                flying: 0.2,
                endurance: 0.2,
                pyramidUp: 0.15,
                pyramidDown: 0.1,
                pyramidUpDown: 0.1,
                activeRecovery: 0.0,
                recovery: 0.0
            )
            
        case 6:
            return SessionTypeDistribution(
                speed: 0.2,
                flying: 0.18,
                endurance: 0.17,
                pyramidUp: 0.15,
                pyramidDown: 0.1,
                pyramidUpDown: 0.1,
                activeRecovery: 0.1,
                recovery: 0.0
            )
            
        case 7:
            return SessionTypeDistribution(
                speed: 0.18,
                flying: 0.16,
                endurance: 0.16,
                pyramidUp: 0.14,
                pyramidDown: 0.1,
                pyramidUpDown: 0.1,
                activeRecovery: 0.08,
                recovery: 0.08
            )
            
        default:
            // Default to 3-day distribution
            return getSessionTypeDistribution(frequency: 3, level: level)
        }
    }
    
    /// Generates a mixed weekly program based on session type distribution
    static func generateMixedWeeklyProgram(
        level: String,
        frequency: Int,
        weekNumber: Int,
        userPreferences: UserSessionPreferences
    ) -> [DaySessionTemplate] {
        
        let distribution = getSessionTypeDistribution(frequency: frequency, level: level)
        var sessions: [DaySessionTemplate] = []
        
        // Calculate actual session counts based on distribution
        let sessionCounts = calculateSessionCounts(distribution: distribution, totalDays: frequency)
        
        // Generate sessions for each type
        var sessionPool: [SprintSessionTemplate] = []
        
        // Add Speed sessions
        sessionPool.append(contentsOf: selectSessionsByType(.speed, count: sessionCounts.speed, level: level, weekNumber: weekNumber))
        
        // Add Flying (Max Velocity) sessions
        sessionPool.append(contentsOf: selectFlyingSessions(count: sessionCounts.flying, level: level, weekNumber: weekNumber))
        
        // Add Endurance sessions
        sessionPool.append(contentsOf: selectSessionsByType(.endurance, count: sessionCounts.endurance, level: level, weekNumber: weekNumber))
        
        // Add Pyramid sessions (Upward)
        sessionPool.append(contentsOf: selectPyramidSessions(.upward, count: sessionCounts.pyramidUp, level: level, weekNumber: weekNumber))
        
        // Add Pyramid sessions (Downward)
        sessionPool.append(contentsOf: selectPyramidSessions(.downward, count: sessionCounts.pyramidDown, level: level, weekNumber: weekNumber))
        
        // Add Pyramid sessions (Up & Down)
        sessionPool.append(contentsOf: selectPyramidSessions(.upDown, count: sessionCounts.pyramidUpDown, level: level, weekNumber: weekNumber))
        
        // Shuffle session pool for variety
        sessionPool.shuffle()
        
        // Create day sessions
        for day in 1...frequency {
            if day <= sessionPool.count {
                let template = sessionPool[day - 1]
                sessions.append(DaySessionTemplate(
                    dayNumber: day,
                    sessionTemplate: template,
                    sessionType: template.sessionType,
                    notes: "Mixed program: \(template.focus)"
                ))
            } else if sessionCounts.activeRecovery > 0 && day == frequency - 1 {
                sessions.append(DaySessionTemplate.activeRecoveryDay(dayNumber: day, level: level))
            } else if sessionCounts.recovery > 0 && day == frequency {
                sessions.append(DaySessionTemplate.restDay(dayNumber: day))
            }
        }
        
        return sessions
    }
    
    // MARK: - Session Selection Helpers
    
    private static func selectSessionsByType(
        _ type: SessionSelectionType,
        count: Int,
        level: String,
        weekNumber: Int
    ) -> [SprintSessionTemplate] {
        
        let levelSessions = sessionsForLevel(level)
        var selectedSessions: [SprintSessionTemplate] = []
        
        switch type {
        case .speed:
            // Select acceleration and drive phase sessions (10-40 yards typically)
            let speedSessions = levelSessions.filter { session in
                session.distance <= 40 && 
                (session.focus.contains("Acceleration") || 
                 session.focus.contains("Speed") ||
                 session.focus.contains("Drive"))
            }
            selectedSessions = Array(speedSessions.shuffled().prefix(count))
            
        case .endurance:
            // Select longer distance sessions (50+ yards)
            let enduranceSessions = levelSessions.filter { session in
                session.distance >= 50 && 
                (session.focus.contains("Endurance") || 
                 session.focus.contains("Repeat") ||
                 session.distance >= 70)
            }
            selectedSessions = Array(enduranceSessions.shuffled().prefix(count))
        }
        
        return selectedSessions
    }
    
    private static func selectFlyingSessions(
        count: Int,
        level: String,
        weekNumber: Int
    ) -> [SprintSessionTemplate] {
        
        let levelSessions = sessionsForLevel(level)
        let flyingSessions = levelSessions.filter { session in
            session.name.contains("Flying") || 
            session.focus.contains("Max Velocity") ||
            session.focus.contains("Peak Velocity")
        }
        
        return Array(flyingSessions.shuffled().prefix(count))
    }
    
    private static func selectPyramidSessions(
        _ pyramidType: PyramidType,
        count: Int,
        level: String,
        weekNumber: Int
    ) -> [SprintSessionTemplate] {
        
        let levelSessions = sessionsForLevel(level)
        var pyramidSessions: [SprintSessionTemplate] = []
        
        switch pyramidType {
        case .upward:
            pyramidSessions = levelSessions.filter { session in
                session.name.contains("Pyramid") && 
                !session.name.contains("Full") &&
                !session.name.contains("–") // Excludes down patterns
            }
            
        case .downward:
            pyramidSessions = levelSessions.filter { session in
                session.name.contains("Downward") || 
                session.name.contains("Reverse")
            }
            
        case .upDown:
            pyramidSessions = levelSessions.filter { session in
                session.name.contains("Full") || 
                session.name.contains("–") // Includes up-down patterns
            }
        }
        
        return Array(pyramidSessions.shuffled().prefix(count))
    }
    
    private static func calculateSessionCounts(
        distribution: SessionTypeDistribution,
        totalDays: Int
    ) -> SessionCounts {
        
        return SessionCounts(
            speed: Int(round(distribution.speed * Double(totalDays))),
            flying: Int(round(distribution.flying * Double(totalDays))),
            endurance: Int(round(distribution.endurance * Double(totalDays))),
            pyramidUp: Int(round(distribution.pyramidUp * Double(totalDays))),
            pyramidDown: Int(round(distribution.pyramidDown * Double(totalDays))),
            pyramidUpDown: Int(round(distribution.pyramidUpDown * Double(totalDays))),
            activeRecovery: Int(round(distribution.activeRecovery * Double(totalDays))),
            recovery: Int(round(distribution.recovery * Double(totalDays)))
        )
    }
}

// MARK: - Supporting Data Structures

struct SessionTypeDistribution {
    let speed: Double
    let flying: Double
    let endurance: Double
    let pyramidUp: Double
    let pyramidDown: Double
    let pyramidUpDown: Double
    let activeRecovery: Double
    let recovery: Double
}

struct SessionCounts {
    let speed: Int
    let flying: Int
    let endurance: Int
    let pyramidUp: Int
    let pyramidDown: Int
    let pyramidUpDown: Int
    let activeRecovery: Int
    let recovery: Int
}

enum SessionSelectionType {
    case speed
    case endurance
}

enum PyramidType {
    case upward
    case downward
    case upDown
}

// MARK: - Helper Functions (Reference existing SessionLibrary functions)

private func sessionsForLevel(_ level: String) -> [SprintSessionTemplate] {
    return sessionLibrary.filter { $0.level == level }
}
