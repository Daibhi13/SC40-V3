import Foundation
import SwiftUI
import Combine

/// Comprehensive rest and recovery management system
@MainActor
class RestRecoveryManager: ObservableObject {
    static let shared = RestRecoveryManager()
    
    // MARK: - Published Properties
    @Published var trainingFrequency: TrainingFrequency = .regular(daysPerWeek: 4)
    @Published var lastSprintDate: Date?
    @Published var lastSessionType: SessionType?
    @Published var restDaysRequired: Int = 1
    @Published var activeRestRecommendations: [ActiveRestActivity] = []
    @Published var recoveryScore: Double = 1.0 // 0.0 = exhausted, 1.0 = fully recovered
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum TrainingFrequency: Equatable {
        case casual(daysPerWeek: Int)      // 2-3 days
        case regular(daysPerWeek: Int)     // 4-5 days  
        case serious(daysPerWeek: Int)     // 5-7 days
        
        var mandatoryRestDays: Int {
            switch self {
            case .casual: return 2
            case .regular: return 1
            case .serious: return 1
            }
        }
        
        var activeRestDays: Int {
            switch self {
            case .casual: return 1
            case .regular: return 2
            case .serious: return 3
            }
        }
        
        var daysPerWeek: Int {
            switch self {
            case .casual(let days), .regular(let days), .serious(let days):
                return days
            }
        }
    }
    
    enum SessionType: String, CaseIterable, Codable {
        case acceleration = "Acceleration"
        case drivePhase = "Drive Phase"
        case maxVelocity = "Max Velocity"
        case speedEndurance = "Speed Endurance"
        case activeRecovery = "Active Recovery"
        case benchmark = "Benchmark"
        case tempo = "Tempo"
        
        var intensity: Double {
            switch self {
            case .maxVelocity, .speedEndurance: return 0.9
            case .benchmark: return 1.0
            case .drivePhase, .acceleration: return 0.7
            case .tempo: return 0.5
            case .activeRecovery: return 0.3
            }
        }
    }
    
    private init() {
        loadTrainingHistory()
        setupRecoveryMonitoring()
    }
    
    // MARK: - Core Methods
    
    /// Calculate if user can train today (integrates with session rotation)
    func canTrainToday() -> TrainingPermission {
        guard let lastSprint = lastSprintDate else {
            return .approved(reason: "First workout - ready to go!")
        }
        
        let daysSinceLastSprint = Calendar.current.dateComponents([.day], 
                                                                from: lastSprint, 
                                                                to: Date()).day ?? 0
        
        // Check session type variety (prevent same type consecutive days)
        if let lastType = lastSessionType, daysSinceLastSprint == 0 {
            return .denied(
                reason: "Same session type (\(lastType.rawValue)) performed today",
                suggestedActivity: generateActiveRestPlan()
            )
        }
        
        switch trainingFrequency {
        case .casual:
            if daysSinceLastSprint < 1 {
                return .denied(reason: "Rest required between sprint sessions", 
                             suggestedActivity: generateActiveRestPlan())
            }
        case .regular:
            if daysSinceLastSprint < 1 && recoveryScore < 0.7 {
                return .cautioned(reason: "Consider active rest for better recovery",
                                suggestedActivity: generateActiveRestPlan())
            }
        case .serious:
            if daysSinceLastSprint == 0 && recoveryScore < 0.5 {
                return .denied(reason: "Overtraining risk detected",
                             suggestedActivity: generateRecoveryPlan())
            }
        }
        
        return .approved(reason: "Ready for training!")
    }
    
    /// Update training history with session type
    func recordTrainingSession(sessionType: SessionType) {
        lastSprintDate = Date()
        lastSessionType = sessionType
        
        // Update recovery score based on session intensity
        updateRecoveryScoreAfterSession(sessionType)
        
        // Save to UserDefaults for persistence
        saveTrainingHistory()
    }
    
    /// Generate active rest plan based on user's training frequency
    func generateActiveRestPlan() -> RestActivity {
        let activities = getActiveRestActivities()
        let recommendedActivity = activities.randomElement() ?? activities[0]
        
        return RestActivity(
            type: .activeRest,
            activity: recommendedActivity,
            duration: recommendedActivity.duration,
            description: recommendedActivity.instructions
        )
    }
    
    /// Generate recovery plan for overtraining situations
    func generateRecoveryPlan() -> RestActivity {
        return RestActivity(
            type: .completeRest,
            activity: nil,
            duration: 24 * 60 * 60, // 24 hours
            description: "Complete rest recommended. Focus on sleep, hydration, and gentle stretching."
        )
    }
    
    // MARK: - Private Methods
    
    private func updateRecoveryScoreAfterSession(_ sessionType: SessionType) {
        let intensityImpact: Double
        
        switch sessionType {
        case .maxVelocity, .speedEndurance:
            intensityImpact = 0.3 // High intensity - significant recovery impact
        case .drivePhase, .acceleration:
            intensityImpact = 0.2 // Moderate intensity
        case .tempo:
            intensityImpact = 0.1 // Lower intensity
        case .activeRecovery:
            intensityImpact = -0.1 // Actually helps recovery
        case .benchmark:
            intensityImpact = 0.4 // Very high intensity - max effort
        }
        
        recoveryScore = max(0.0, recoveryScore - intensityImpact)
    }
    
    nonisolated private func setupRecoveryMonitoring() {
        // Monitor recovery score and update recommendations
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateRecoveryScore()
            }
        }
    }
    
    private func updateRecoveryScore() {
        // Natural recovery over time
        let hoursSinceLastWorkout = getHoursSinceLastWorkout()
        let recoveryRate = 0.02 // 2% recovery per hour
        
        recoveryScore = min(1.0, recoveryScore + (recoveryRate * hoursSinceLastWorkout))
    }
    
    private func getHoursSinceLastWorkout() -> Double {
        guard let lastWorkout = lastSprintDate else { return 24.0 }
        return Date().timeIntervalSince(lastWorkout) / 3600
    }
    
    private func getActiveRestActivities() -> [ActiveRestActivity] {
        return [
            ActiveRestActivity(
                name: "Recovery Walk",
                duration: 1200, // 20 minutes
                intensity: .light,
                benefits: [.bloodFlow, .mentalRecovery],
                instructions: "Gentle 20-minute walk at conversational pace",
                videoURL: nil
            ),
            ActiveRestActivity(
                name: "Dynamic Stretching",
                duration: 900, // 15 minutes
                intensity: .veryLight,
                benefits: [.flexibility, .muscleRecovery],
                instructions: "Full-body dynamic stretching routine",
                videoURL: nil
            ),
            ActiveRestActivity(
                name: "Foam Rolling Session",
                duration: 600, // 10 minutes
                intensity: .veryLight,
                benefits: [.muscleRecovery, .injuryPrevention],
                instructions: "Target legs, glutes, and back with foam roller",
                videoURL: nil
            ),
            ActiveRestActivity(
                name: "Easy Bike Ride",
                duration: 1800, // 30 minutes
                intensity: .moderate,
                benefits: [.bloodFlow, .muscleRecovery],
                instructions: "Leisurely bike ride maintaining easy conversation",
                videoURL: nil
            ),
            ActiveRestActivity(
                name: "Yoga Flow",
                duration: 1800, // 30 minutes
                intensity: .light,
                benefits: [.flexibility, .mentalRecovery, .muscleRecovery],
                instructions: "Gentle yoga flow focusing on hip flexors and hamstrings",
                videoURL: nil
            )
        ]
    }
    
    private func saveTrainingHistory() {
        if let lastDate = lastSprintDate {
            UserDefaults.standard.set(lastDate, forKey: "lastSprintDate")
        }
        if let lastType = lastSessionType {
            UserDefaults.standard.set(lastType.rawValue, forKey: "lastSessionType")
        }
        UserDefaults.standard.set(recoveryScore, forKey: "recoveryScore")
    }
    
    private func loadTrainingHistory() {
        lastSprintDate = UserDefaults.standard.object(forKey: "lastSprintDate") as? Date
        if let sessionTypeString = UserDefaults.standard.string(forKey: "lastSessionType") {
            lastSessionType = SessionType(rawValue: sessionTypeString)
        }
        recoveryScore = UserDefaults.standard.double(forKey: "recoveryScore")
        if recoveryScore == 0 { recoveryScore = 1.0 } // Default value
    }
}

// MARK: - Supporting Enums and Structs

enum TrainingPermission {
    case approved(reason: String)
    case cautioned(reason: String, suggestedActivity: RestActivity)
    case denied(reason: String, suggestedActivity: RestActivity)
}

struct RestActivity {
    let type: RestType
    let activity: ActiveRestActivity?
    let duration: TimeInterval
    let description: String
    
    enum RestType {
        case completeRest
        case activeRest
    }
}

struct ActiveRestActivity {
    let name: String
    let duration: TimeInterval
    let intensity: RestIntensity
    let benefits: [RecoveryBenefit]
    let instructions: String
    let videoURL: String?
    
    enum RestIntensity {
        case veryLight    // Heart rate < 50% max
        case light        // Heart rate 50-60% max
        case moderate     // Heart rate 60-70% max
    }
    
    enum RecoveryBenefit {
        case muscleRecovery
        case flexibility
        case bloodFlow
        case mentalRecovery
        case injuryPrevention
    }
}
