import Foundation

// MARK: - Core Program Types

enum Phase: String, Codable, CaseIterable, Hashable {
    case S   // Start
    case A   // Acceleration
    case T   // Transition
    case F   // Max Velocity (Fly)
    case O   // Overspeed/Contrast
    case AR  // Active Recovery
    case R   // Rest
}

struct PhaseProgram: Codable, Hashable {
    var phase: Phase
    var reps: Int
    var distance: Int // yards
    var notes: String?
    var lastTime: Double?
    var pb: Double?
}

struct DayProgram: Codable, Equatable, Hashable {
    var dayNumber: Int
    var phases: [PhaseProgram]
    var hybridAI: HybridAISession?
    static func == (lhs: DayProgram, rhs: DayProgram) -> Bool {
        lhs.dayNumber == rhs.dayNumber && lhs.phases == rhs.phases && lhs.hybridAI == rhs.hybridAI
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(dayNumber)
        hasher.combine(phases)
        hasher.combine(hybridAI)
    }
}

typealias WeeklyProgram = [DayProgram]

// MARK: - AI/Hybrid Session Types

enum TrendDirection: String, Codable {
    case improving, stable, declining
}

struct PredictedPB: Codable, Equatable, Hashable {
    var value: Double
    var confidence: Double
    var trend: TrendDirection
}

struct Adjustment: Codable, Equatable, Hashable {
    enum AdjustmentType: String, Codable { case increaseReps, decreaseReps, increaseRest, decreaseRest }
    var type: AdjustmentType
    var phase: Phase
    var value: Int?
}

struct HybridAISession: Codable, Equatable, Hashable {
    var recommendedAdjustments: [Adjustment]?
    var fatigueScore: Double?
    var fatigue: Double?
    var suggestedRest: Int?
    var predictedPBs: [Phase: PredictedPB]?
    var phaseTrends: [Phase: TrendDirection]?
    var focusPhases: [Phase]?
    var readinessScore: Double?
    
    static func == (lhs: HybridAISession, rhs: HybridAISession) -> Bool {
        lhs.recommendedAdjustments == rhs.recommendedAdjustments &&
        lhs.fatigueScore == rhs.fatigueScore &&
        lhs.fatigue == rhs.fatigue &&
        lhs.suggestedRest == rhs.suggestedRest &&
        lhs.predictedPBs == rhs.predictedPBs &&
        lhs.phaseTrends == rhs.phaseTrends &&
        lhs.focusPhases == rhs.focusPhases &&
        lhs.readinessScore == rhs.readinessScore
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(recommendedAdjustments)
        hasher.combine(fatigueScore)
        hasher.combine(fatigue)
        hasher.combine(suggestedRest)
        if let predictedPBs = predictedPBs {
            for (key, value) in predictedPBs {
                hasher.combine(key)
                hasher.combine(value.value)
                hasher.combine(value.confidence)
                hasher.combine(value.trend)
            }
        }
        if let phaseTrends = phaseTrends {
            for (key, value) in phaseTrends {
                hasher.combine(key)
                hasher.combine(value)
            }
        }
        hasher.combine(focusPhases)
        hasher.combine(readinessScore)
    }
}
