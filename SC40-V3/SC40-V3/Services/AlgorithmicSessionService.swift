import Foundation
import Algorithms
import Combine

// MARK: - Algorithmic Session Service
// Backend-only service that powers the SC40 machine's intelligent session generation
// No UI components - pure algorithmic engine

@MainActor
class AlgorithmicSessionService: ObservableObject {
    
    static let shared = AlgorithmicSessionService()
    
    private let algorithmicGenerator = AlgorithmicSessionGenerator.shared
    private let performanceCollector = PerformanceDataCollector.shared
    
    private init() {}
    
    // MARK: - Backend Session Generation
    
    /// Generates optimized training sessions using algorithmic intelligence
    /// This is the core engine that powers the SC40 machine
    func generateOptimizedSessions(
        for userLevel: String,
        frequency: Int,
        currentWeek: Int,
        performanceHistory: [AlgorithmicSessionGenerator.PerformanceData] = []
    ) -> [TrainingSession] {
        
        print("🤖 AlgorithmicSessionService: Generating sessions for \(userLevel), Week \(currentWeek)")
        
        // Use algorithmic intelligence to determine optimal session types
        let sessionTypes = determineOptimalSessionTypes(
            level: userLevel,
            frequency: frequency,
            week: currentWeek,
            performanceData: performanceHistory
        )
        
        var generatedSessions: [TrainingSession] = []
        
        // Generate sessions for the week using algorithmic parameters
        for (dayIndex, sessionType) in sessionTypes.enumerated() {
            let session = generateAlgorithmicSession(
                type: sessionType,
                level: userLevel,
                week: currentWeek,
                day: dayIndex + 1,
                performanceData: performanceHistory
            )
            generatedSessions.append(session)
        }
        
        print("🤖 Generated \(generatedSessions.count) algorithmic sessions")
        return generatedSessions
    }
    
    // MARK: - Algorithmic Intelligence
    
    private func determineOptimalSessionTypes(
        level: String,
        frequency: Int,
        week: Int,
        performanceData: [AlgorithmicSessionGenerator.PerformanceData]
    ) -> [AlgorithmicSessionGenerator.AlgorithmicSessionType] {
        
        // Use Algorithms framework for intelligent session selection
        let availableTypes = AlgorithmicSessionGenerator.AlgorithmicSessionType.allCases
        
        // Apply algorithmic logic based on user progression
        var sessionTypes: [AlgorithmicSessionGenerator.AlgorithmicSessionType] = []
        
        switch frequency {
        case 1...2:
            sessionTypes = [.speed, .recovery]
        case 3...4:
            sessionTypes = [.speed, .endurance, .plyometrics, .recovery]
        case 5...6:
            sessionTypes = [.speed, .flying, .endurance, .tempo, .plyometrics, .activeRecovery]
        case 7:
            sessionTypes = [.speed, .flying, .endurance, .tempo, .plyometrics, .comprehensive, .recovery]
        default:
            sessionTypes = [.speed, .recovery]
        }
        
        // Algorithmic adaptation based on performance data
        if !performanceData.isEmpty {
            sessionTypes = adaptSessionsBasedOnPerformance(sessionTypes, performanceData)
        }
        
        return Array(sessionTypes.prefix(frequency))
    }
    
    private func adaptSessionsBasedOnPerformance(
        _ baseTypes: [AlgorithmicSessionGenerator.AlgorithmicSessionType],
        _ performanceData: [AlgorithmicSessionGenerator.PerformanceData]
    ) -> [AlgorithmicSessionGenerator.AlgorithmicSessionType] {
        
        // Algorithmic performance analysis
        let avgImprovement = performanceData.map(\.improvementRate).reduce(0, +) / Double(performanceData.count)
        let avgFatigue = performanceData.map(\.fatigueLevel).reduce(0, +) / Double(performanceData.count)
        
        var adaptedTypes = baseTypes
        
        // If high fatigue, add more recovery
        if avgFatigue > 0.7 {
            adaptedTypes = adaptedTypes.map { type in
                if type == .plyometrics { return .activeRecovery }
                return type
            }
        }
        
        // If low improvement, add more variety
        if avgImprovement < 0.02 {
            adaptedTypes = adaptedTypes.map { type in
                if type == .speed { return .comprehensive }
                return type
            }
        }
        
        return adaptedTypes
    }
    
    private func generateAlgorithmicSession(
        type: AlgorithmicSessionGenerator.AlgorithmicSessionType,
        level: String,
        week: Int,
        day: Int,
        performanceData: [AlgorithmicSessionGenerator.PerformanceData]
    ) -> TrainingSession {
        
        // Generate session using algorithmic parameters
        let sessionData = algorithmicGenerator.generateSessionData(
            type: type,
            level: level,
            week: week,
            performanceHistory: performanceData
        )
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: week, day: day),
            week: week,
            day: day,
            type: type.rawValue,
            focus: sessionData.focus,
            sprints: sessionData.sprints,
            accessoryWork: sessionData.accessoryWork,
            notes: "🤖 Algorithmically generated session optimized for your performance"
        )
    }
}

// MARK: - AlgorithmicSessionGenerator Extension
extension AlgorithmicSessionGenerator {
    
    struct SessionData {
        let focus: String
        let sprints: [SprintSet]
        let accessoryWork: [String]
    }
    
    func generateSessionData(
        type: AlgorithmicSessionType,
        level: String,
        week: Int,
        performanceHistory: [PerformanceData]
    ) -> SessionData {
        
        // Algorithmic session generation based on type and performance
        switch type {
        case .speed:
            return generateSpeedSession(level: level, week: week)
        case .flying:
            return generateFlyingSession(level: level, week: week)
        case .endurance:
            return generateEnduranceSession(level: level, week: week)
        case .plyometrics:
            return generatePlyometricsSession(level: level, week: week)
        case .comprehensive:
            return generateComprehensiveSession(level: level, week: week)
        default:
            return generateRecoverySession(level: level, week: week)
        }
    }
    
    private func generateSpeedSession(level: String, week: Int) -> SessionData {
        let distances = level == "Elite" ? [20, 30, 40] : [10, 20, 30]
        let sprints = distances.map { distance in
            SprintSet(distanceYards: distance, reps: 3, intensity: "Max")
        }
        
        return SessionData(
            focus: "Maximum Speed Development",
            sprints: sprints,
            accessoryWork: ["Dynamic Warm-up", "Sprint Mechanics", "Cool-down"]
        )
    }
    
    private func generateFlyingSession(level: String, week: Int) -> SessionData {
        let distance = level == "Elite" ? 60 : 40
        let sprints = [SprintSet(distanceYards: distance, reps: 4, intensity: "Max")]
        
        return SessionData(
            focus: "Flying Sprint Technique",
            sprints: sprints,
            accessoryWork: ["Build-up Runs", "Flying Mechanics", "Recovery"]
        )
    }
    
    private func generateEnduranceSession(level: String, week: Int) -> SessionData {
        let distances = level == "Elite" ? [100, 80, 60] : [60, 40, 30]
        let sprints = distances.map { distance in
            SprintSet(distanceYards: distance, reps: 2, intensity: "Sub-Max")
        }
        
        return SessionData(
            focus: "Speed Endurance",
            sprints: sprints,
            accessoryWork: ["Extended Warm-up", "Lactate Tolerance", "Extended Cool-down"]
        )
    }
    
    private func generatePlyometricsSession(level: String, week: Int) -> SessionData {
        let sprints = [SprintSet(distanceYards: 20, reps: 6, intensity: "Explosive")]
        
        return SessionData(
            focus: "Power Development",
            sprints: sprints,
            accessoryWork: ["Plyometric Drills", "Jump Training", "Power Endurance"]
        )
    }
    
    private func generateComprehensiveSession(level: String, week: Int) -> SessionData {
        let sprints = [
            SprintSet(distanceYards: 20, reps: 2, intensity: "Max"),
            SprintSet(distanceYards: 40, reps: 2, intensity: "Max"),
            SprintSet(distanceYards: 60, reps: 1, intensity: "Max")
        ]
        
        return SessionData(
            focus: "Comprehensive Speed Training",
            sprints: sprints,
            accessoryWork: ["Full Warm-up", "Technique Work", "Strength Integration"]
        )
    }
    
    private func generateRecoverySession(level: String, week: Int) -> SessionData {
        let sprints = [SprintSet(distanceYards: 20, reps: 3, intensity: "Easy")]
        
        return SessionData(
            focus: "Active Recovery",
            sprints: sprints,
            accessoryWork: ["Light Movement", "Mobility Work", "Regeneration"]
        )
    }
}
