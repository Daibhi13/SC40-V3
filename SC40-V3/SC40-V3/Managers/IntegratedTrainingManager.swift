import Foundation
import SwiftUI
import Combine

/// Unified training management system that integrates rest/recovery and session rotation
@MainActor
class IntegratedTrainingManager: ObservableObject {
    static let shared = IntegratedTrainingManager()
    
    // MARK: - Managers
    @StateObject private var restManager = RestRecoveryManager.shared
    @StateObject private var sessionManager = SessionRotationManager.shared
    
    // MARK: - Published Properties
    @Published var todaysTrainingDecision: TrainingDecision = .loading
    @Published var weeklyPlan: WeeklyTrainingPlan?
    @Published var currentUserLevel: String = "Beginner"
    
    private init() {
        updateTodaysDecision()
        _ = generateWeeklyPlan()
    }
    
    // MARK: - Core Methods
    
    /// Unified training permission check that considers both rest and session variety
    func canTrainToday() -> TrainingDecision {
        // First check rest requirements
        let restPermission = restManager.canTrainToday()
        
        switch restPermission {
        case .denied(let reason, let activity):
            return .mandatoryRest(reason: reason, activity: activity)
            
        case .cautioned(let reason, let activity):
            // Check if we can do light training instead
            let lightSessions = getLightTrainingSessions()
            if !lightSessions.isEmpty {
                return .lightTrainingOnly(
                    reason: reason,
                    allowedSessions: lightSessions,
                    alternativeActivity: activity
                )
            } else {
                return .activeRestRecommended(reason: reason, activity: activity)
            }
            
        case .approved(let reason):
            // Check session variety requirements
            let recommendedSession = sessionManager.getRecommendedSession(
                for: restManager.trainingFrequency,
                userLevel: currentUserLevel
            )
            
            let alternatives = getAlternativeSessions()
            
            return .trainingApproved(
                reason: reason,
                recommendedSession: recommendedSession,
                alternatives: alternatives
            )
        }
    }
    
    /// Generate complete weekly training plan
    func generateWeeklyPlan() -> WeeklyTrainingPlan {
        let plan = WeeklyTrainingPlan(
            trainingFrequency: restManager.trainingFrequency,
            userLevel: currentUserLevel
        )
        
        DispatchQueue.main.async {
            self.weeklyPlan = plan
        }
        
        return plan
    }
    
    /// Record completed training session
    func recordCompletedSession(_ session: SprintSessionTemplate) {
        let sessionType = sessionManager.getSessionTypeFromFocus(session.focus)
        
        // Update both managers
        restManager.recordTrainingSession(sessionType: sessionType)
        sessionManager.recordSessionCompletion(session)
        
        // Update today's decision
        updateTodaysDecision()
        
        // Regenerate weekly plan
        _ = generateWeeklyPlan()
    }
    
    /// Update user's training frequency
    func updateTrainingFrequency(_ frequency: RestRecoveryManager.TrainingFrequency) {
        restManager.trainingFrequency = frequency
        updateTodaysDecision()
        _ = generateWeeklyPlan()
    }
    
    /// Update user's skill level
    func updateUserLevel(_ level: String) {
        currentUserLevel = level
        updateTodaysDecision()
        _ = generateWeeklyPlan()
    }
    
    // MARK: - Private Methods
    
    private func updateTodaysDecision() {
        todaysTrainingDecision = canTrainToday()
    }
    
    private func getLightTrainingSessions() -> [SprintSessionTemplate] {
        let lightSessionTypes: [RestRecoveryManager.SessionType] = [.activeRecovery, .tempo]
        
        return lightSessionTypes.compactMap { sessionType in
            sessionManager.getSessionByType(sessionType, userLevel: currentUserLevel)
        }
    }
    
    private func getAlternativeSessions() -> [SprintSessionTemplate] {
        let availableTypes = RestRecoveryManager.SessionType.allCases
        
        return availableTypes.compactMap { sessionType in
            let permission = sessionManager.canPerformSessionType(sessionType)
            switch permission {
            case .approved, .cautioned:
                return sessionManager.getSessionByType(sessionType, userLevel: currentUserLevel)
            case .denied:
                return nil
            }
        }.prefix(3).map { $0 } // Limit to 3 alternatives
    }
    
    /// Get today's recommended session with fallbacks
    func getTodaysRecommendedSession() -> SprintSessionTemplate? {
        switch todaysTrainingDecision {
        case .trainingApproved(_, let session, let alternatives):
            return session ?? alternatives.first
        case .lightTrainingOnly(_, let sessions, _):
            return sessions.first
        default:
            return nil
        }
    }
    
    /// Check if user should be encouraged to rest
    func shouldEncourageRest() -> Bool {
        switch todaysTrainingDecision {
        case .mandatoryRest, .activeRestRecommended:
            return true
        case .lightTrainingOnly:
            return true
        default:
            return false
        }
    }
    
    /// Get rest recommendation for today
    func getTodaysRestRecommendation() -> RestActivity? {
        switch todaysTrainingDecision {
        case .mandatoryRest(_, let activity),
             .activeRestRecommended(_, let activity),
             .lightTrainingOnly(_, _, let activity):
            return activity
        default:
            return nil
        }
    }
}

// MARK: - Supporting Enums and Structs

enum TrainingDecision {
    case loading
    case mandatoryRest(reason: String, activity: RestActivity)
    case activeRestRecommended(reason: String, activity: RestActivity)
    case lightTrainingOnly(reason: String, allowedSessions: [SprintSessionTemplate], alternativeActivity: RestActivity)
    case trainingApproved(reason: String, recommendedSession: SprintSessionTemplate?, alternatives: [SprintSessionTemplate])
    
    var canTrain: Bool {
        switch self {
        case .trainingApproved, .lightTrainingOnly:
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .loading:
            return "Analyzing..."
        case .mandatoryRest:
            return "Rest Day Required"
        case .activeRestRecommended:
            return "Active Recovery Recommended"
        case .lightTrainingOnly:
            return "Light Training Only"
        case .trainingApproved:
            return "Ready to Train"
        }
    }
    
    var icon: String {
        switch self {
        case .loading:
            return "clock"
        case .mandatoryRest:
            return "bed.double.fill"
        case .activeRestRecommended:
            return "figure.walk"
        case .lightTrainingOnly:
            return "figure.run"
        case .trainingApproved:
            return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .loading:
            return .gray
        case .mandatoryRest:
            return .red
        case .activeRestRecommended:
            return .orange
        case .lightTrainingOnly:
            return .yellow
        case .trainingApproved:
            return .green
        }
    }
}

struct WeeklyTrainingPlan {
    let trainingFrequency: RestRecoveryManager.TrainingFrequency
    let userLevel: String
    let weeklySchedule: [DayOfWeek: DayPlan]
    
    init(trainingFrequency: RestRecoveryManager.TrainingFrequency, userLevel: String) {
        self.trainingFrequency = trainingFrequency
        self.userLevel = userLevel
        self.weeklySchedule = Self.generateSchedule(frequency: trainingFrequency, userLevel: userLevel)
    }
    
    func getDayPlan(for day: DayOfWeek) -> DayPlan? {
        return weeklySchedule[day]
    }
    
    private static func generateSchedule(frequency: RestRecoveryManager.TrainingFrequency, 
                                       userLevel: String) -> [DayOfWeek: DayPlan] {
        var schedule: [DayOfWeek: DayPlan] = [:]
        
        switch frequency {
        case .casual(let days):
            schedule = generateCasualSchedule(days: days, userLevel: userLevel)
        case .regular(let days):
            schedule = generateRegularSchedule(days: days, userLevel: userLevel)
        case .serious(let days):
            schedule = generateSeriousSchedule(days: days, userLevel: userLevel)
        }
        
        return schedule
    }
    
    private static func generateCasualSchedule(days: Int, userLevel: String) -> [DayOfWeek: DayPlan] {
        if days == 2 {
            return [
                .monday: DayPlan(day: .monday, planType: .training(.acceleration), isRestDay: false),
                .tuesday: DayPlan(day: .tuesday, planType: .activeRest, isRestDay: false),
                .wednesday: DayPlan(day: .wednesday, planType: .completeRest, isRestDay: true),
                .thursday: DayPlan(day: .thursday, planType: .training(.maxVelocity), isRestDay: false),
                .friday: DayPlan(day: .friday, planType: .activeRest, isRestDay: false),
                .saturday: DayPlan(day: .saturday, planType: .completeRest, isRestDay: true),
                .sunday: DayPlan(day: .sunday, planType: .completeRest, isRestDay: true)
            ]
        } else { // 3 days
            return [
                .monday: DayPlan(day: .monday, planType: .training(.acceleration), isRestDay: false),
                .tuesday: DayPlan(day: .tuesday, planType: .completeRest, isRestDay: true),
                .wednesday: DayPlan(day: .wednesday, planType: .training(.drivePhase), isRestDay: false),
                .thursday: DayPlan(day: .thursday, planType: .completeRest, isRestDay: true),
                .friday: DayPlan(day: .friday, planType: .training(.maxVelocity), isRestDay: false),
                .saturday: DayPlan(day: .saturday, planType: .activeRest, isRestDay: false),
                .sunday: DayPlan(day: .sunday, planType: .completeRest, isRestDay: true)
            ]
        }
    }
    
    private static func generateRegularSchedule(days: Int, userLevel: String) -> [DayOfWeek: DayPlan] {
        return [
            .monday: DayPlan(day: .monday, planType: .training(.acceleration), isRestDay: false),
            .tuesday: DayPlan(day: .tuesday, planType: .training(.activeRecovery), isRestDay: false),
            .wednesday: DayPlan(day: .wednesday, planType: .training(.drivePhase), isRestDay: false),
            .thursday: DayPlan(day: .thursday, planType: .training(.tempo), isRestDay: false),
            .friday: DayPlan(day: .friday, planType: .training(.maxVelocity), isRestDay: false),
            .saturday: DayPlan(day: .saturday, planType: .activeRest, isRestDay: false),
            .sunday: DayPlan(day: .sunday, planType: .completeRest, isRestDay: true)
        ]
    }
    
    private static func generateSeriousSchedule(days: Int, userLevel: String) -> [DayOfWeek: DayPlan] {
        return [
            .monday: DayPlan(day: .monday, planType: .training(.acceleration), isRestDay: false),
            .tuesday: DayPlan(day: .tuesday, planType: .training(.tempo), isRestDay: false),
            .wednesday: DayPlan(day: .wednesday, planType: .training(.drivePhase), isRestDay: false),
            .thursday: DayPlan(day: .thursday, planType: .training(.activeRecovery), isRestDay: false),
            .friday: DayPlan(day: .friday, planType: .training(.maxVelocity), isRestDay: false),
            .saturday: DayPlan(day: .saturday, planType: .training(.speedEndurance), isRestDay: false),
            .sunday: DayPlan(day: .sunday, planType: .completeRest, isRestDay: true)
        ]
    }
}

struct DayPlan {
    let day: DayOfWeek
    let planType: PlanType
    let isRestDay: Bool
    
    enum PlanType {
        case training(RestRecoveryManager.SessionType)
        case activeRest
        case completeRest
    }
    
    var isTrainingDay: Bool {
        if case .training = planType {
            return !isRestDay
        }
        return false
    }
    
    var sessionType: RestRecoveryManager.SessionType? {
        if case .training(let type) = planType {
            return type
        }
        return nil
    }
}

enum DayOfWeek: Int, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}
