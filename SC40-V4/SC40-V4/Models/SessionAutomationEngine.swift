import Foundation
import Combine

// MARK: - Session Automation Engine
// Continuously generates new sessions and adds them to the library

@MainActor
class SessionAutomationEngine: @unchecked Sendable {
    
    static let shared = SessionAutomationEngine()
    private var nextSessionID = 401 // Start after expanded pyramid library
    
    private init() {}
    
    // MARK: - Automated Session Generation
    
    /// Generates new sessions based on gaps in the library and user needs
    func generateNewSessions(count: Int = 50) -> [SprintSessionTemplate] {
        var newSessions: [SprintSessionTemplate] = []
        
        // Analyze current library gaps
        let libraryGaps = analyzeLibraryGaps()
        
        // Generate sessions to fill gaps
        for gap in libraryGaps {
            let sessionsForGap = generateSessionsForGap(gap, count: gap.priority)
            newSessions.append(contentsOf: sessionsForGap)
            
            if newSessions.count >= count {
                break
            }
        }
        
        // Fill remaining slots with innovative sessions
        let remainingCount = count - newSessions.count
        if remainingCount > 0 {
            let innovativeSessions = generateInnovativeSessions(count: remainingCount)
            newSessions.append(contentsOf: innovativeSessions)
        }
        
        return newSessions
    }
    
    /// Analyzes the current session library to identify gaps
    private func analyzeLibraryGaps() -> [LibraryGap] {
        var gaps: [LibraryGap] = []
        
        // Check for missing session types by level
        let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        let sessionTypes: [SessionTypeAnalysis] = [
            .tempo, .intervals, .complexTraining, .reactiveTraining,
            .accelerationSpecific, .maxVelocitySpecific, .speedEndurance,
            .neuromuscularPower, .metabolicConditioning
        ]
        
        for level in levels {
            for sessionType in sessionTypes {
                let existingCount = countExistingSessions(level: level, type: sessionType)
                let recommendedCount = getRecommendedSessionCount(level: level, type: sessionType)
                
                if existingCount < recommendedCount {
                    gaps.append(LibraryGap(
                        level: level,
                        sessionType: sessionType,
                        currentCount: existingCount,
                        targetCount: recommendedCount,
                        priority: recommendedCount - existingCount
                    ))
                }
            }
        }
        
        // Sort gaps by priority (highest need first)
        return gaps.sorted { $0.priority > $1.priority }
    }
    
    /// Generates sessions to fill a specific gap in the library
    private func generateSessionsForGap(_ gap: LibraryGap, count: Int) -> [SprintSessionTemplate] {
        var sessions: [SprintSessionTemplate] = []
        
        for i in 0..<count {
            let session = generateSessionForType(
                level: gap.level,
                sessionType: gap.sessionType,
                variation: i
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    /// Generates innovative new session types
    private func generateInnovativeSessions(count: Int) -> [SprintSessionTemplate] {
        var sessions: [SprintSessionTemplate] = []
        
        let innovativeTypes: [InnovativeSessionType] = [
            .contrastTraining, .complexSets, .clusterTraining,
            .velocityBasedTraining, .accommodatingResistance,
            .plyometricSprints, .reactiveSprints, .cognitiveLoad
        ]
        
        let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        
        for i in 0..<count {
            let level = levels[i % levels.count]
            let sessionType = innovativeTypes[i % innovativeTypes.count]
            
            let session = generateInnovativeSession(
                level: level,
                sessionType: sessionType,
                variation: i / levels.count
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    /// Generates a specific session for a given type and level
    private func generateSessionForType(
        level: String,
        sessionType: SessionTypeAnalysis,
        variation: Int
    ) -> SprintSessionTemplate {
        
        let sessionID = getNextSessionID()
        let baseParameters = getBaseParameters(level: level, sessionType: sessionType)
        
        // Apply variation to create unique sessions
        let distance = applyVariation(baseParameters.distance, variation: variation, type: .distance)
        let reps = applyVariation(baseParameters.reps, variation: variation, type: .reps)
        let rest = applyVariation(baseParameters.rest, variation: variation, type: .rest)
        
        let name = generateSessionName(
            level: level,
            sessionType: sessionType,
            distance: distance,
            reps: reps,
            variation: variation
        )
        
        let focus = generateSessionFocus(sessionType: sessionType, level: level)
        
        return SprintSessionTemplate(
            id: sessionID,
            name: name,
            distance: distance,
            reps: reps,
            rest: rest,
            focus: focus,
            level: level,
            sessionType: mapToLibrarySessionType(sessionType)
        )
    }
    
    /// Generates innovative session types
    private func generateInnovativeSession(
        level: String,
        sessionType: InnovativeSessionType,
        variation: Int
    ) -> SprintSessionTemplate {
        
        let sessionID = getNextSessionID()
        let parameters = getInnovativeParameters(level: level, sessionType: sessionType, variation: variation)
        
        return SprintSessionTemplate(
            id: sessionID,
            name: parameters.name,
            distance: parameters.distance,
            reps: parameters.reps,
            rest: parameters.rest,
            focus: parameters.focus,
            level: level,
            sessionType: .sprint
        )
    }
    
    // MARK: - Helper Functions
    
    private func getNextSessionID() -> Int {
        let id = nextSessionID
        nextSessionID += 1
        return id
    }
    
    private func countExistingSessions(level: String, type: SessionTypeAnalysis) -> Int {
        // This would analyze the existing sessionLibrary
        // For now, return estimated counts based on current library
        switch type {
        case .tempo: return level == "Elite" ? 8 : 5
        case .intervals: return level == "Elite" ? 6 : 4
        case .complexTraining: return level == "Elite" ? 4 : 2
        case .reactiveTraining: return level == "Elite" ? 3 : 1
        case .accelerationSpecific: return level == "Elite" ? 10 : 6
        case .maxVelocitySpecific: return level == "Elite" ? 8 : 5
        case .speedEndurance: return level == "Elite" ? 6 : 4
        case .neuromuscularPower: return level == "Elite" ? 4 : 2
        case .metabolicConditioning: return level == "Elite" ? 3 : 1
        }
    }
    
    private func getRecommendedSessionCount(level: String, type: SessionTypeAnalysis) -> Int {
        let multiplier = level == "Elite" ? 2.0 : level == "Advanced" ? 1.5 : 1.0
        
        let baseCount: Int
        switch type {
        case .tempo: baseCount = 8
        case .intervals: baseCount = 6
        case .complexTraining: baseCount = 5
        case .reactiveTraining: baseCount = 4
        case .accelerationSpecific: baseCount = 12
        case .maxVelocitySpecific: baseCount = 10
        case .speedEndurance: baseCount = 8
        case .neuromuscularPower: baseCount = 6
        case .metabolicConditioning: baseCount = 4
        }
        
        return Int(Double(baseCount) * multiplier)
    }
    
    private func getBaseParameters(level: String, sessionType: SessionTypeAnalysis) -> SessionParameters {
        let levelMultiplier = getLevelMultiplier(level: level)
        
        switch sessionType {
        case .tempo:
            return SessionParameters(
                distance: Int(30 * levelMultiplier),
                reps: Int(6 * (2.0 - levelMultiplier * 0.3)),
                rest: Int(90 * levelMultiplier)
            )
        case .intervals:
            return SessionParameters(
                distance: Int(50 * levelMultiplier),
                reps: Int(5 * (2.0 - levelMultiplier * 0.2)),
                rest: Int(120 * levelMultiplier)
            )
        case .accelerationSpecific:
            return SessionParameters(
                distance: Int(20 * levelMultiplier),
                reps: Int(8 * (2.0 - levelMultiplier * 0.25)),
                rest: Int(60 * levelMultiplier)
            )
        case .maxVelocitySpecific:
            return SessionParameters(
                distance: Int(60 * levelMultiplier),
                reps: Int(4 * (2.0 - levelMultiplier * 0.2)),
                rest: Int(180 * levelMultiplier)
            )
        case .speedEndurance:
            return SessionParameters(
                distance: Int(80 * levelMultiplier),
                reps: Int(3 * (2.0 - levelMultiplier * 0.15)),
                rest: Int(240 * levelMultiplier)
            )
        case .complexTraining:
            return SessionParameters(
                distance: Int(40 * levelMultiplier),
                reps: Int(4 * (2.0 - levelMultiplier * 0.2)),
                rest: Int(150 * levelMultiplier)
            )
        case .reactiveTraining:
            return SessionParameters(
                distance: Int(25 * levelMultiplier),
                reps: Int(6 * (2.0 - levelMultiplier * 0.25)),
                rest: Int(90 * levelMultiplier)
            )
        case .neuromuscularPower:
            return SessionParameters(
                distance: Int(15 * levelMultiplier),
                reps: Int(8 * (2.0 - levelMultiplier * 0.3)),
                rest: Int(120 * levelMultiplier)
            )
        case .metabolicConditioning:
            return SessionParameters(
                distance: Int(100 * levelMultiplier),
                reps: Int(2 * (2.0 - levelMultiplier * 0.1)),
                rest: Int(300 * levelMultiplier)
            )
        }
    }
    
    private func getInnovativeParameters(level: String, sessionType: InnovativeSessionType, variation: Int) -> InnovativeSessionParameters {
        let levelMultiplier = getLevelMultiplier(level: level)
        
        switch sessionType {
        case .contrastTraining:
            return InnovativeSessionParameters(
                name: "\(level) Contrast \(variation + 1): Heavy→Light→Sprint",
                distance: Int(30 * levelMultiplier),
                reps: 4,
                rest: Int(180 * levelMultiplier),
                focus: "Contrast Training - Post-Activation Potentiation"
            )
        case .complexSets:
            return InnovativeSessionParameters(
                name: "\(level) Complex Set \(variation + 1): Plyometric→Sprint",
                distance: Int(40 * levelMultiplier),
                reps: 3,
                rest: Int(240 * levelMultiplier),
                focus: "Complex Training - Power Development"
            )
        case .clusterTraining:
            return InnovativeSessionParameters(
                name: "\(level) Cluster \(variation + 1): 3×(2×\(Int(20 * levelMultiplier))yd)",
                distance: Int(20 * levelMultiplier),
                reps: 6,
                rest: Int(45 * levelMultiplier),
                focus: "Cluster Training - Volume with Quality"
            )
        case .velocityBasedTraining:
            return InnovativeSessionParameters(
                name: "\(level) VBT \(variation + 1): >95% Max Velocity",
                distance: Int(50 * levelMultiplier),
                reps: 4,
                rest: Int(300 * levelMultiplier),
                focus: "Velocity-Based Training - Speed Reserve"
            )
        case .accommodatingResistance:
            return InnovativeSessionParameters(
                name: "\(level) Accommodating \(variation + 1): Band-Assisted",
                distance: Int(35 * levelMultiplier),
                reps: 5,
                rest: Int(150 * levelMultiplier),
                focus: "Accommodating Resistance - Overspeed"
            )
        case .plyometricSprints:
            return InnovativeSessionParameters(
                name: "\(level) Plyo-Sprint \(variation + 1): Bounds→Sprint",
                distance: Int(25 * levelMultiplier),
                reps: 6,
                rest: Int(120 * levelMultiplier),
                focus: "Plyometric-Sprint Complex"
            )
        case .reactiveSprints:
            return InnovativeSessionParameters(
                name: "\(level) Reactive \(variation + 1): Audio Cue Start",
                distance: Int(30 * levelMultiplier),
                reps: 8,
                rest: Int(90 * levelMultiplier),
                focus: "Reactive Sprint Training"
            )
        case .cognitiveLoad:
            return InnovativeSessionParameters(
                name: "\(level) Cognitive \(variation + 1): Decision Sprint",
                distance: Int(40 * levelMultiplier),
                reps: 4,
                rest: Int(180 * levelMultiplier),
                focus: "Cognitive Load Training"
            )
        }
    }
    
    private func getLevelMultiplier(level: String) -> Double {
        switch level {
        case "Beginner": return 0.7
        case "Intermediate": return 1.0
        case "Advanced": return 1.3
        case "Elite": return 1.6
        default: return 1.0
        }
    }
    
    private func applyVariation(_ baseValue: Int, variation: Int, type: VariationType) -> Int {
        let variationFactor = 0.1 + (Double(variation) * 0.05)
        let multiplier = type == .rest ? (1.0 + variationFactor) : (1.0 + (variationFactor * 0.5))
        return Int(Double(baseValue) * multiplier)
    }
    
    private func generateSessionName(level: String, sessionType: SessionTypeAnalysis, distance: Int, reps: Int, variation: Int) -> String {
        let typePrefix = sessionType.rawValue.capitalized
        return "\(level) \(typePrefix) \(variation + 1): \(distance) yd ×\(reps)"
    }
    
    private func generateSessionFocus(sessionType: SessionTypeAnalysis, level: String) -> String {
        let levelAdjective = level == "Elite" ? "Elite" : level == "Advanced" ? "Advanced" : "Progressive"
        return "\(levelAdjective) \(sessionType.rawValue.capitalized) Development"
    }
    
    private func mapToLibrarySessionType(_ sessionType: SessionTypeAnalysis) -> LibrarySessionType {
        switch sessionType {
        case .tempo: return .tempo
        case .intervals, .speedEndurance, .metabolicConditioning: return .sprint
        case .accelerationSpecific, .maxVelocitySpecific: return .sprint
        case .complexTraining, .reactiveTraining, .neuromuscularPower: return .sprint
        }
    }
}

// MARK: - Supporting Data Structures

struct LibraryGap {
    let level: String
    let sessionType: SessionTypeAnalysis
    let currentCount: Int
    let targetCount: Int
    let priority: Int
}

struct SessionParameters {
    let distance: Int
    let reps: Int
    let rest: Int
}

struct InnovativeSessionParameters {
    let name: String
    let distance: Int
    let reps: Int
    let rest: Int
    let focus: String
}

enum SessionTypeAnalysis: String {
    case tempo = "tempo"
    case intervals = "intervals"
    case complexTraining = "complex training"
    case reactiveTraining = "reactive training"
    case accelerationSpecific = "acceleration specific"
    case maxVelocitySpecific = "max velocity specific"
    case speedEndurance = "speed endurance"
    case neuromuscularPower = "neuromuscular power"
    case metabolicConditioning = "metabolic conditioning"
}

enum InnovativeSessionType {
    case contrastTraining
    case complexSets
    case clusterTraining
    case velocityBasedTraining
    case accommodatingResistance
    case plyometricSprints
    case reactiveSprints
    case cognitiveLoad
}

enum VariationType {
    case distance
    case reps
    case rest
}
