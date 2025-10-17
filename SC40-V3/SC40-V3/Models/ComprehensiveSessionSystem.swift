import Foundation

// MARK: - Comprehensive Session System Integration
// Combines all session libraries and automation for complete training system

@MainActor
class ComprehensiveSessionSystem: @unchecked Sendable {
    
    static let shared = ComprehensiveSessionSystem()
    
    // MARK: - Complete Session Library (724+ Sessions)
    
    /// Returns the complete session library including all expansions
    var completeSessionLibrary: [SprintSessionTemplate] {
        var allSessions = sessionLibrary // Base library (1-324)
        
        // Add expanded pyramids (301-400) - already included via + expandedPyramidLibrary
        
        // Add automated sessions if available
        let automatedSessions = SessionAutomationEngine.shared.generateNewSessions(count: 100)
        allSessions.append(contentsOf: automatedSessions)
        
        return allSessions
    }
    
    // MARK: - Session Type Distribution by Frequency
    
    /// Gets the optimal session mix for a given training frequency
    func getOptimalSessionMix(frequency: Int, level: String) -> SessionMixBreakdown {
        let distribution = SessionMixingEngine.getSessionTypeDistribution(frequency: frequency, level: level)
        
        return SessionMixBreakdown(
            frequency: frequency,
            level: level,
            speed: Int(round(distribution.speed * Double(frequency))),
            flying: Int(round(distribution.flying * Double(frequency))),
            endurance: Int(round(distribution.endurance * Double(frequency))),
            pyramidUpward: Int(round(distribution.pyramidUp * Double(frequency))),
            pyramidDownward: Int(round(distribution.pyramidDown * Double(frequency))),
            pyramidUpDown: Int(round(distribution.pyramidUpDown * Double(frequency))),
            activeRecovery: Int(round(distribution.activeRecovery * Double(frequency))),
            recovery: Int(round(distribution.recovery * Double(frequency)))
        )
    }
    
    // MARK: - Session Library Statistics
    
    /// Provides comprehensive statistics about the session library
    func getLibraryStatistics() -> SessionLibraryStats {
        let allSessions = completeSessionLibrary
        
        let beginnerCount = allSessions.filter { $0.level == "Beginner" }.count
        let intermediateCount = allSessions.filter { $0.level == "Intermediate" }.count
        let advancedCount = allSessions.filter { $0.level == "Advanced" }.count
        let eliteCount = allSessions.filter { $0.level == "Elite" }.count
        
        let sprintCount = allSessions.filter { $0.sessionType == .sprint }.count
        let tempoCount = allSessions.filter { $0.sessionType == .tempo }.count
        let activeRecoveryCount = allSessions.filter { $0.sessionType == .activeRecovery }.count
        let benchmarkCount = allSessions.filter { $0.sessionType == .benchmark }.count
        
        let pyramidCount = allSessions.filter { $0.name.contains("Pyramid") }.count
        let flyingCount = allSessions.filter { $0.name.contains("Flying") }.count
        let plyometricCount = allSessions.filter { $0.distance == 0 }.count // Plyometric sessions have 0 distance
        
        return SessionLibraryStats(
            totalSessions: allSessions.count,
            byLevel: LevelBreakdown(
                beginner: beginnerCount,
                intermediate: intermediateCount,
                advanced: advancedCount,
                elite: eliteCount
            ),
            byType: TypeBreakdown(
                sprint: sprintCount,
                tempo: tempoCount,
                activeRecovery: activeRecoveryCount,
                benchmark: benchmarkCount
            ),
            specialCategories: SpecialCategoryBreakdown(
                pyramid: pyramidCount,
                flying: flyingCount,
                plyometric: plyometricCount
            )
        )
    }
    
    // MARK: - Automated Session Generation
    
    /// Continuously expands the session library based on usage patterns
    func expandLibraryAutomatically() -> [SprintSessionTemplate] {
        let newSessions = SessionAutomationEngine.shared.generateNewSessions(count: 50)
        
        // Log the expansion
        print("🤖 Session Automation Engine generated \(newSessions.count) new sessions")
        print("📊 Total library size now: \(completeSessionLibrary.count) sessions")
        
        return newSessions
    }
    
    // MARK: - Session Validation
    
    /// Validates that all session types are properly distributed across levels
    func validateSessionDistribution() -> ValidationResult {
        let stats = getLibraryStatistics()
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check level distribution
        let totalSessions = stats.totalSessions
        let expectedPerLevel = totalSessions / 4
        let tolerance = Int(Double(expectedPerLevel) * 0.3) // 30% tolerance
        
        if abs(stats.byLevel.beginner - expectedPerLevel) > tolerance {
            issues.append("Beginner sessions: \(stats.byLevel.beginner) (expected ~\(expectedPerLevel))")
            recommendations.append("Generate more beginner-friendly sessions")
        }
        
        if abs(stats.byLevel.elite - expectedPerLevel) > tolerance {
            issues.append("Elite sessions: \(stats.byLevel.elite) (expected ~\(expectedPerLevel))")
            recommendations.append("Add more elite-level challenges")
        }
        
        // Check pyramid distribution
        if stats.specialCategories.pyramid < 100 {
            issues.append("Only \(stats.specialCategories.pyramid) pyramid sessions available")
            recommendations.append("Expand pyramid library with more variations")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            recommendations: recommendations,
            totalSessions: totalSessions
        )
    }
    
    // MARK: - Weekly Program Generation with Full Mixing
    
    /// Generates a comprehensive weekly program using all available session types
    func generateComprehensiveWeeklyProgram(
        level: String,
        frequency: Int,
        weekNumber: Int,
        userPreferences: UserSessionPreferences
    ) -> WeeklyProgramTemplate {
        
        // Use the session mixing engine for optimal distribution
        let mixedSessions = SessionMixingEngine.generateMixedWeeklyProgram(
            level: level,
            frequency: frequency,
            weekNumber: weekNumber,
            userPreferences: userPreferences
        )
        
        return WeeklyProgramTemplate(
            level: level,
            weekNumber: weekNumber,
            totalDays: frequency,
            sessions: mixedSessions
        )
    }
}

// MARK: - Supporting Data Structures

struct SessionMixBreakdown {
    let frequency: Int
    let level: String
    let speed: Int
    let flying: Int
    let endurance: Int
    let pyramidUpward: Int
    let pyramidDownward: Int
    let pyramidUpDown: Int
    let activeRecovery: Int
    let recovery: Int
    
    var description: String {
        return """
        \(frequency)-Day \(level) Program Mix:
        • Speed: \(speed) sessions
        • Flying (Max Velocity): \(flying) sessions
        • Endurance: \(endurance) sessions
        • Pyramid Upward: \(pyramidUpward) sessions
        • Pyramid Downward: \(pyramidDownward) sessions
        • Pyramid Up-Down: \(pyramidUpDown) sessions
        • Active Recovery: \(activeRecovery) sessions
        • Recovery: \(recovery) sessions
        """
    }
}

struct SessionLibraryStats {
    let totalSessions: Int
    let byLevel: LevelBreakdown
    let byType: TypeBreakdown
    let specialCategories: SpecialCategoryBreakdown
}

struct LevelBreakdown {
    let beginner: Int
    let intermediate: Int
    let advanced: Int
    let elite: Int
}

struct TypeBreakdown {
    let sprint: Int
    let tempo: Int
    let activeRecovery: Int
    let benchmark: Int
}

struct SpecialCategoryBreakdown {
    let pyramid: Int
    let flying: Int
    let plyometric: Int
}

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
    let recommendations: [String]
    let totalSessions: Int
}

// MARK: - Session Library Extensions

extension ComprehensiveSessionSystem {
    
    /// Gets sessions by specific criteria
    func getSessionsByCriteria(
        level: String? = nil,
        sessionType: LibrarySessionType? = nil,
        distanceRange: ClosedRange<Int>? = nil,
        focusKeyword: String? = nil
    ) -> [SprintSessionTemplate] {
        
        var filteredSessions = completeSessionLibrary
        
        if let level = level {
            filteredSessions = filteredSessions.filter { $0.level == level }
        }
        
        if let sessionType = sessionType {
            filteredSessions = filteredSessions.filter { $0.sessionType == sessionType }
        }
        
        if let distanceRange = distanceRange {
            filteredSessions = filteredSessions.filter { distanceRange.contains($0.distance) }
        }
        
        if let focusKeyword = focusKeyword {
            filteredSessions = filteredSessions.filter { $0.focus.contains(focusKeyword) }
        }
        
        return filteredSessions
    }
    
    /// Gets pyramid sessions by type
    func getPyramidSessions(type: PyramidSessionType, level: String) -> [SprintSessionTemplate] {
        let pyramidSessions = completeSessionLibrary.filter { 
            $0.name.contains("Pyramid") && $0.level == level 
        }
        
        switch type {
        case .upward:
            return pyramidSessions.filter { $0.name.contains("Upward") }
        case .downward:
            return pyramidSessions.filter { $0.name.contains("Downward") }
        case .upDown:
            return pyramidSessions.filter { $0.name.contains("Full") || $0.name.contains("–") }
        case .all:
            return pyramidSessions
        }
    }
}

enum PyramidSessionType {
    case upward
    case downward
    case upDown
    case all
}
