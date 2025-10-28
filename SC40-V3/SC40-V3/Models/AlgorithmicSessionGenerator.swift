import Foundation
import Algorithms
import Combine

// MARK: - Algorithmic Session Generator
// Uses Algorithms framework to create science-based, evolving session library

@MainActor
class AlgorithmicSessionGenerator: ObservableObject {
    
    @Published var isGenerating = false
    
    static let shared = AlgorithmicSessionGenerator()
    
    // MARK: - Session Type Algorithms
    
    /// All available session types for algorithmic generation
    enum AlgorithmicSessionType: String, CaseIterable {
        case speed = "Speed"
        case flying = "Flying Runs" 
        case endurance = "Endurance"
        case pyramidUp = "Pyramid Up"
        case pyramidDown = "Pyramid Down"
        case pyramidUpDown = "Pyramid Up-Down"
        case tempo = "Tempo"
        case plyometrics = "Plyometrics"
        case activeRecovery = "Active Recovery"
        case recovery = "Recovery"
        case benchmark = "Benchmark"
        case comprehensive = "Comprehensive"
        
        var librarySessionType: LibrarySessionType {
            switch self {
            case .speed, .flying, .endurance, .pyramidUp, .pyramidDown, .pyramidUpDown, .plyometrics:
                return .sprint
            case .tempo:
                return .tempo
            case .activeRecovery:
                return .activeRecovery
            case .recovery:
                return .recovery
            case .benchmark:
                return .benchmark
            case .comprehensive:
                return .comprehensive
            }
        }
    }
    
    // MARK: - Science-Based Session Parameters
    
    struct SessionParameters {
        let level: String
        let sessionType: AlgorithmicSessionType
        let weekNumber: Int
        let frequency: Int
        let userPerformanceData: PerformanceData?
    }
    
    struct PerformanceData {
        let averageTime: Double
        let improvementRate: Double
        let fatigueLevel: Double
        let consistencyScore: Double
        let strengthLevel: Double
    }
    
    struct GeneratedSession {
        let id: Int
        let name: String
        let distance: Int
        let reps: Int
        let rest: Int
        let focus: String
        let level: String
        let sessionType: LibrarySessionType
        let algorithmicType: AlgorithmicSessionType
        let scienceScore: Double
        let adaptationFactors: [String]
    }
    
    // MARK: - Algorithmic Session Generation
    
    /// Generates sessions using Algorithms framework for optimal distribution
    func generateAlgorithmicWeeklyProgram(
        level: String,
        frequency: Int,
        weekNumber: Int,
        userPreferences: UserSessionPreferences,
        performanceData: PerformanceData?
    ) -> [DaySessionTemplate] {
        
        // Use Algorithms framework for optimal session type distribution
        let sessionTypeDistribution = calculateOptimalDistribution(
            frequency: frequency,
            level: level,
            weekNumber: weekNumber,
            performanceData: performanceData
        )
        
        // Generate session pool using algorithmic selection
        let sessionPool = generateSessionPool(
            distribution: sessionTypeDistribution,
            parameters: SessionParameters(
                level: level,
                sessionType: .speed, // Will be overridden per session
                weekNumber: weekNumber,
                frequency: frequency,
                userPerformanceData: performanceData
            )
        )
        
        // Use Algorithms.randomSample for optimal variety
        let selectedSessions = sessionPool.randomSample(count: frequency)
        
        // Convert to DaySessionTemplate with algorithmic optimization
        return selectedSessions.enumerated().map { index, session in
            let dayNumber = index + 1
            
            // Apply manual overrides if they exist
            if let overrideTemplateID = userPreferences.manualOverrides.first(where: { 
                $0.key.uuidString.contains("W\(weekNumber)D\(dayNumber)") 
            })?.value,
               let overrideTemplate = sessionLibrary.first(where: { $0.id == overrideTemplateID }) {
                return DaySessionTemplate(
                    dayNumber: dayNumber,
                    sessionTemplate: overrideTemplate,
                    sessionType: overrideTemplate.sessionType,
                    notes: "👆 User selected: \(overrideTemplate.name)"
                )
            }
            
            // Convert generated session to SprintSessionTemplate
            let sprintTemplate = SprintSessionTemplate(
                id: session.id,
                name: session.name,
                distance: session.distance,
                reps: session.reps,
                rest: session.rest,
                focus: session.focus,
                level: session.level,
                sessionType: session.sessionType
            )
            
            return DaySessionTemplate(
                dayNumber: dayNumber,
                sessionTemplate: sprintTemplate,
                sessionType: session.sessionType,
                notes: "🧠 Algorithmic: \(session.algorithmicType.rawValue) (Score: \(String(format: "%.1f", session.scienceScore)))"
            )
        }
    }
    
    // MARK: - Optimal Distribution Algorithm
    
    private func calculateOptimalDistribution(
        frequency: Int,
        level: String,
        weekNumber: Int,
        performanceData: PerformanceData?
    ) -> [AlgorithmicSessionType: Double] {
        
        // Base distribution using SessionMixingEngine principles
        var distribution: [AlgorithmicSessionType: Double] = [:]
        
        // Apply frequency-based distribution
        switch frequency {
        case 1:
            distribution = [.speed: 1.0]
            
        case 2:
            distribution = [.speed: 0.6, .endurance: 0.4]
            
        case 3:
            distribution = [.speed: 0.4, .flying: 0.3, .endurance: 0.3]
            
        case 4:
            distribution = [
                .speed: 0.3, .flying: 0.25, .endurance: 0.25, 
                .pyramidUp: 0.2
            ]
            
        case 5:
            distribution = [
                .speed: 0.25, .flying: 0.2, .endurance: 0.2,
                .pyramidUp: 0.15, .tempo: 0.1, .activeRecovery: 0.1
            ]
            
        case 6:
            distribution = [
                .speed: 0.2, .flying: 0.18, .endurance: 0.17,
                .pyramidUp: 0.15, .pyramidDown: 0.1, .tempo: 0.1,
                .activeRecovery: 0.1
            ]
            
        case 7:
            distribution = [
                .speed: 0.18, .flying: 0.16, .endurance: 0.16,
                .pyramidUp: 0.14, .pyramidDown: 0.1, .pyramidUpDown: 0.08,
                .activeRecovery: 0.08, .recovery: 0.1
            ]
            
        default:
            distribution = [.speed: 0.4, .flying: 0.3, .endurance: 0.3]
        }
        
        // Apply level-based adjustments using Algorithms framework
        distribution = applyLevelAdjustments(distribution, level: level)
        
        // Apply week progression using algorithmic scaling
        distribution = applyWeekProgression(distribution, weekNumber: weekNumber)
        
        // Apply performance-based optimization
        if let performanceData = performanceData {
            distribution = applyPerformanceOptimization(distribution, performanceData: performanceData)
        }
        
        // Add benchmark sessions for assessment weeks
        if [1, 4, 8, 12].contains(weekNumber) {
            distribution[.benchmark] = 0.1
            // Normalize other distributions
            let totalNonBenchmark = distribution.values.reduce(0, +) - 0.1
            for (key, value) in distribution {
                if key != .benchmark {
                    distribution[key] = value * 0.9 / totalNonBenchmark
                }
            }
        }
        
        return distribution
    }
    
    // MARK: - Level-Based Algorithmic Adjustments
    
    private func applyLevelAdjustments(
        _ distribution: [AlgorithmicSessionType: Double],
        level: String
    ) -> [AlgorithmicSessionType: Double] {
        
        var adjusted = distribution
        
        switch level.lowercased() {
        case "beginner":
            // Increase speed and reduce complex sessions
            adjusted[.speed] = (adjusted[.speed] ?? 0) * 1.2
            adjusted[.flying] = (adjusted[.flying] ?? 0) * 0.8
            adjusted[.pyramidUpDown] = (adjusted[.pyramidUpDown] ?? 0) * 0.5
            
        case "intermediate":
            // Balanced approach with slight flying emphasis
            adjusted[.flying] = (adjusted[.flying] ?? 0) * 1.1
            adjusted[.tempo] = (adjusted[.tempo] ?? 0) * 1.1
            
        case "advanced":
            // Increase complex sessions and endurance
            adjusted[.endurance] = (adjusted[.endurance] ?? 0) * 1.2
            adjusted[.pyramidUpDown] = (adjusted[.pyramidUpDown] ?? 0) * 1.3
            adjusted[.plyometrics] = (adjusted[.plyometrics] ?? 0.05) * 1.5
            
        case "elite":
            // Maximum variety and complexity
            adjusted[.flying] = (adjusted[.flying] ?? 0) * 1.3
            adjusted[.endurance] = (adjusted[.endurance] ?? 0) * 1.2
            adjusted[.plyometrics] = (adjusted[.plyometrics] ?? 0.1) * 2.0
            adjusted[.comprehensive] = (adjusted[.comprehensive] ?? 0.02) * 3.0
            
        default:
            break
        }
        
        // Normalize to ensure total = 1.0
        let total = adjusted.values.reduce(0, +)
        for (key, value) in adjusted {
            adjusted[key] = value / total
        }
        
        return adjusted
    }
    
    // MARK: - Week Progression Algorithm
    
    private func applyWeekProgression(
        _ distribution: [AlgorithmicSessionType: Double],
        weekNumber: Int
    ) -> [AlgorithmicSessionType: Double] {
        
        var adjusted = distribution
        let progressionFactor = Double(weekNumber) / 12.0
        
        // Early weeks (1-3): Focus on fundamentals
        if weekNumber <= 3 {
            adjusted[.speed] = (adjusted[.speed] ?? 0) * 1.3
            adjusted[.flying] = (adjusted[.flying] ?? 0) * 0.7
            
        // Mid weeks (4-8): Build complexity
        } else if weekNumber <= 8 {
            adjusted[.endurance] = (adjusted[.endurance] ?? 0) * (1.0 + progressionFactor * 0.5)
            adjusted[.pyramidUp] = (adjusted[.pyramidUp] ?? 0) * (1.0 + progressionFactor * 0.3)
            
        // Late weeks (9-12): Peak performance
        } else {
            adjusted[.flying] = (adjusted[.flying] ?? 0) * 1.4
            adjusted[.plyometrics] = (adjusted[.plyometrics] ?? 0.05) * 2.0
            adjusted[.comprehensive] = (adjusted[.comprehensive] ?? 0.02) * 1.5
        }
        
        // Normalize
        let total = adjusted.values.reduce(0, +)
        for (key, value) in adjusted {
            adjusted[key] = value / total
        }
        
        return adjusted
    }
    
    // MARK: - Performance-Based Optimization
    
    private func applyPerformanceOptimization(
        _ distribution: [AlgorithmicSessionType: Double],
        performanceData: PerformanceData
    ) -> [AlgorithmicSessionType: Double] {
        
        var adjusted = distribution
        
        // High fatigue: Increase recovery
        if performanceData.fatigueLevel > 0.7 {
            adjusted[.activeRecovery] = (adjusted[.activeRecovery] ?? 0) * 1.5
            adjusted[.recovery] = (adjusted[.recovery] ?? 0) * 1.3
            adjusted[.endurance] = (adjusted[.endurance] ?? 0) * 0.7
        }
        
        // Low improvement rate: Increase variety
        if performanceData.improvementRate < 0.02 {
            adjusted[.plyometrics] = (adjusted[.plyometrics] ?? 0.05) * 1.8
            adjusted[.pyramidUpDown] = (adjusted[.pyramidUpDown] ?? 0.05) * 1.5
            adjusted[.comprehensive] = (adjusted[.comprehensive] ?? 0.02) * 2.0
        }
        
        // Low consistency: Focus on fundamentals
        if performanceData.consistencyScore < 0.6 {
            adjusted[.speed] = (adjusted[.speed] ?? 0) * 1.2
            adjusted[.tempo] = (adjusted[.tempo] ?? 0) * 1.1
            adjusted[.pyramidUpDown] = (adjusted[.pyramidUpDown] ?? 0) * 0.6
        }
        
        // High strength: Increase power sessions
        if performanceData.strengthLevel > 0.8 {
            adjusted[.plyometrics] = (adjusted[.plyometrics] ?? 0.05) * 1.6
            adjusted[.flying] = (adjusted[.flying] ?? 0) * 1.2
        }
        
        // Normalize
        let total = adjusted.values.reduce(0, +)
        for (key, value) in adjusted {
            adjusted[key] = value / total
        }
        
        return adjusted
    }
    
    // MARK: - Session Pool Generation
    
    private func generateSessionPool(
        distribution: [AlgorithmicSessionType: Double],
        parameters: SessionParameters
    ) -> [GeneratedSession] {
        
        var sessionPool: [GeneratedSession] = []
        var sessionId = 10000 // Start high to avoid conflicts
        
        for (sessionType, weight) in distribution {
            let sessionCount = max(1, Int(round(weight * Double(parameters.frequency * 3)))) // Generate 3x for variety
            
            for _ in 0..<sessionCount {
                let session = generateAlgorithmicSession(
                    type: sessionType,
                    parameters: parameters,
                    sessionId: sessionId
                )
                sessionPool.append(session)
                sessionId += 1
            }
        }
        
        // Use Algorithms framework to sort by science score
        return sessionPool.sorted { $0.scienceScore > $1.scienceScore }
    }
    
    // MARK: - Individual Session Generation
    
    private func generateAlgorithmicSession(
        type: AlgorithmicSessionType,
        parameters: SessionParameters,
        sessionId: Int
    ) -> GeneratedSession {
        
        let levelMultiplier = getLevelMultiplier(parameters.level)
        let weekProgression = Double(parameters.weekNumber) / 12.0
        
        var distance: Int
        var reps: Int
        var rest: Int
        var focus: String
        var adaptationFactors: [String] = []
        
        switch type {
        case .speed:
            distance = Int(Double([20, 30, 40].randomElement()!) * levelMultiplier)
            reps = max(3, Int(Double([4, 5, 6].randomElement()!) * (1.0 + weekProgression * 0.3)))
            rest = 90 + Int(Double(distance) * 1.5)
            focus = ["Acceleration", "Drive Phase", "Max Speed"].randomElement()!
            adaptationFactors = ["Neural Power", "Explosive Strength", "Speed Reserve"]
            
        case .flying:
            distance = Int(Double([10, 15, 20, 25, 30].randomElement()!) * levelMultiplier)
            reps = max(3, Int(Double([4, 5, 6].randomElement()!) * (1.0 + weekProgression * 0.2)))
            rest = 120 + Int(Double(distance) * 2.0)
            focus = "Max Velocity"
            adaptationFactors = ["Peak Velocity", "Neuromuscular Coordination", "Stride Frequency"]
            
        case .endurance:
            distance = Int(Double([50, 60, 70, 80].randomElement()!) * levelMultiplier)
            reps = max(2, Int(Double([3, 4, 5].randomElement()!) * (1.0 + weekProgression * 0.4)))
            rest = 180 + Int(Double(distance) * 2.5)
            focus = "Speed Endurance"
            adaptationFactors = ["Lactate Tolerance", "Speed Reserve", "Metabolic Power"]
            
        case .pyramidUp:
            let baseDistance = Int(Double([10, 15, 20].randomElement()!) * levelMultiplier)
            distance = baseDistance + 20 // Peak distance
            reps = 3
            rest = 120 + Int(Double(distance) * 1.8)
            focus = "Progressive Speed"
            adaptationFactors = ["Progressive Overload", "Adaptation Stimulus", "Volume Tolerance"]
            
        case .pyramidDown:
            let baseDistance = Int(Double([40, 50, 60].randomElement()!) * levelMultiplier)
            distance = baseDistance
            reps = 3
            rest = 150 + Int(Double(distance) * 1.5)
            focus = "Speed Maintenance"
            adaptationFactors = ["Fatigue Resistance", "Speed Maintenance", "Recovery Capacity"]
            
        case .pyramidUpDown:
            distance = Int(Double([30, 40, 50].randomElement()!) * levelMultiplier)
            reps = 5
            rest = 120 + Int(Double(distance) * 2.0)
            focus = "Complete Speed Development"
            adaptationFactors = ["Complete Adaptation", "Volume + Intensity", "Comprehensive Stimulus"]
            
        case .tempo:
            distance = Int(Double([30, 40, 50].randomElement()!) * levelMultiplier)
            reps = max(4, Int(Double([5, 6, 7].randomElement()!) * (1.0 + weekProgression * 0.2)))
            rest = 60 + Int(Double(distance) * 1.0)
            focus = "Tempo Development"
            adaptationFactors = ["Aerobic Power", "Rhythm", "Efficiency"]
            
        case .plyometrics:
            distance = Int(Double([15, 20, 25].randomElement()!) * levelMultiplier)
            reps = max(6, Int(Double([8, 10, 12].randomElement()!) * (1.0 + weekProgression * 0.1)))
            rest = 90 + Int(Double(distance) * 1.2)
            focus = "Explosive Power"
            adaptationFactors = ["Reactive Strength", "Elastic Energy", "Power Development"]
            
        case .activeRecovery:
            distance = Int(Double([20, 30, 40].randomElement()!) * 0.8) // Reduced intensity
            reps = max(4, Int(Double([5, 6].randomElement()!) * 0.9))
            rest = 90
            focus = "Active Recovery"
            adaptationFactors = ["Blood Flow", "Movement Quality", "Recovery Enhancement"]
            
        case .recovery:
            distance = 0 // No sprints
            reps = 0
            rest = 0
            focus = "Complete Recovery"
            adaptationFactors = ["Regeneration", "Adaptation", "Supercompensation"]
            
        case .benchmark:
            distance = 40 // Standard 40-yard test
            reps = 1
            rest = 600 // 10 minutes full recovery
            focus = "Performance Assessment"
            adaptationFactors = ["Performance Tracking", "Progress Measurement", "Goal Assessment"]
            
        case .comprehensive:
            distance = Int(Double([40, 50, 60].randomElement()!) * levelMultiplier)
            reps = max(4, Int(Double([5, 6, 7].randomElement()!) * (1.0 + weekProgression * 0.3)))
            rest = 150 + Int(Double(distance) * 2.0)
            focus = "Complete Development"
            adaptationFactors = ["Holistic Training", "Multi-System", "Complete Athlete"]
        }
        
        // Calculate science score based on multiple factors
        let scienceScore = calculateScienceScore(
            type: type,
            distance: distance,
            reps: reps,
            rest: rest,
            level: parameters.level,
            weekNumber: parameters.weekNumber,
            performanceData: parameters.userPerformanceData
        )
        
        let sessionName = generateSessionName(
            type: type,
            distance: distance,
            reps: reps,
            level: parameters.level
        )
        
        return GeneratedSession(
            id: sessionId,
            name: sessionName,
            distance: distance,
            reps: reps,
            rest: rest,
            focus: focus,
            level: parameters.level,
            sessionType: type.librarySessionType,
            algorithmicType: type,
            scienceScore: scienceScore,
            adaptationFactors: adaptationFactors
        )
    }
    
    // MARK: - Helper Functions
    
    private func getLevelMultiplier(_ level: String) -> Double {
        switch level.lowercased() {
        case "beginner": return 0.8
        case "intermediate": return 1.0
        case "advanced": return 1.2
        case "elite": return 1.4
        default: return 1.0
        }
    }
    
    private func calculateScienceScore(
        type: AlgorithmicSessionType,
        distance: Int,
        reps: Int,
        rest: Int,
        level: String,
        weekNumber: Int,
        performanceData: PerformanceData?
    ) -> Double {
        
        var score: Double = 50.0 // Base score
        
        // Distance appropriateness (0-20 points)
        let levelMultiplier = getLevelMultiplier(level)
        let optimalDistance = type == .speed ? 30 : type == .flying ? 20 : type == .endurance ? 60 : 40
        let distanceScore = max(0, 20 - abs(Double(distance) - Double(optimalDistance) * levelMultiplier))
        score += distanceScore
        
        // Rep appropriateness (0-15 points)
        let optimalReps = type == .endurance ? 3 : type == .speed ? 5 : 4
        let repScore = max(0, 15 - abs(Double(reps - optimalReps)) * 3)
        score += repScore
        
        // Rest appropriateness (0-10 points)
        let optimalRest = Double(distance) * 2.0 + 60
        let restScore = max(0, 10 - abs(Double(rest) - optimalRest) / 30.0)
        score += restScore
        
        // Week progression bonus (0-5 points)
        let progressionBonus = Double(weekNumber) / 12.0 * 5.0
        score += progressionBonus
        
        // Performance data optimization (0-10 points)
        if let performanceData = performanceData {
            if performanceData.fatigueLevel > 0.7 && [.activeRecovery, .recovery].contains(type) {
                score += 8.0
            }
            if performanceData.improvementRate < 0.02 && [.plyometrics, .comprehensive].contains(type) {
                score += 6.0
            }
            if performanceData.consistencyScore < 0.6 && [.speed, .tempo].contains(type) {
                score += 7.0
            }
        }
        
        return min(100.0, score)
    }
    
    private func generateSessionName(
        type: AlgorithmicSessionType,
        distance: Int,
        reps: Int,
        level: String
    ) -> String {
        
        let levelPrefix = level == "Elite" ? "Elite " : ""
        
        switch type {
        case .speed:
            return "\(levelPrefix)\(distance) yd Speed ×\(reps)"
        case .flying:
            return "\(levelPrefix)Flying \(distance) yd ×\(reps)"
        case .endurance:
            return "\(levelPrefix)\(distance) yd Endurance ×\(reps)"
        case .pyramidUp:
            return "\(levelPrefix)Pyramid Up to \(distance) yd"
        case .pyramidDown:
            return "\(levelPrefix)Pyramid Down from \(distance) yd"
        case .pyramidUpDown:
            return "\(levelPrefix)Full Pyramid \(distance) yd"
        case .tempo:
            return "\(levelPrefix)\(distance) yd Tempo ×\(reps)"
        case .plyometrics:
            return "\(levelPrefix)Plyo + \(distance) yd ×\(reps)"
        case .activeRecovery:
            return "\(levelPrefix)Active Recovery \(distance) yd"
        case .recovery:
            return "\(levelPrefix)Recovery Session"
        case .benchmark:
            return "\(levelPrefix)\(distance) yd Time Trial"
        case .comprehensive:
            return "\(levelPrefix)Complete \(distance) yd ×\(reps)"
        }
    }
}

// MARK: - Extensions for Algorithms Framework Integration

extension Array {
    func randomSample(count: Int) -> [Element] {
        guard count <= self.count else { return Array(self.shuffled()) }
        return Array(self.shuffled().prefix(count))
    }
}

// MARK: - Performance Data Collection

extension AlgorithmicSessionGenerator {
    
    /// Collects performance data from completed sessions for algorithmic optimization
    func collectPerformanceData(from sessions: [TrainingSession]) -> PerformanceData? {
        guard !sessions.isEmpty else { return nil }
        
        let completedSessions = sessions.filter { session in
            // Check if session has timing data
            return session.sprints.allSatisfy { $0.reps > 0 }
        }
        
        guard !completedSessions.isEmpty else { return nil }
        
        // Calculate average time (simplified - would use actual timing data)
        let averageTime = 5.0 // Placeholder - would calculate from actual session times
        
        // Calculate improvement rate (week-over-week progress)
        let improvementRate = 0.05 // Placeholder - would calculate from historical data
        
        // Calculate fatigue level (based on recent session performance)
        let fatigueLevel = 0.3 // Placeholder - would analyze performance degradation
        
        // Calculate consistency score (variance in performance)
        let consistencyScore = 0.8 // Placeholder - would calculate performance variance
        
        // Calculate strength level (based on power metrics)
        let strengthLevel = 0.7 // Placeholder - would analyze explosive metrics
        
        return PerformanceData(
            averageTime: averageTime,
            improvementRate: improvementRate,
            fatigueLevel: fatigueLevel,
            consistencyScore: consistencyScore,
            strengthLevel: strengthLevel
        )
    }
}
