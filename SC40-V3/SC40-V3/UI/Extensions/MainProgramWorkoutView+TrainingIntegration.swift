import SwiftUI
import Foundation

// MARK: - Training Integration Extension for MainProgramWorkoutView

extension MainProgramWorkoutView {
    
    /// Check training permission before starting workout
    func checkTrainingPermissionBeforeStart() -> Bool {
        let trainingManager = IntegratedTrainingManager.shared
        let decision = trainingManager.canTrainToday()
        
        switch decision {
        case .trainingApproved, .lightTrainingOnly:
            return true
        case .mandatoryRest, .activeRestRecommended:
            showRestDayRecommendation(decision: decision)
            return false
        case .loading:
            return false
        }
    }
    
    /// Show rest day recommendation modal
    private func showRestDayRecommendation(decision: TrainingDecision) {
        // Present RestDayView as a sheet
        // This would be implemented in the main view body
    }
    
    /// Get today's recommended session if none provided
    func getTodaysRecommendedSession() -> MainProgramWorkoutView.SessionData? {
        guard sessionData == nil else { return sessionData }
        
        let trainingManager = IntegratedTrainingManager.shared
        
        if let recommendedSession = trainingManager.getTodaysRecommendedSession() {
            return convertSprintSessionToSessionData(recommendedSession)
        }
        
        return nil
    }
    
    /// Convert SprintSessionTemplate to MainProgramWorkoutView.SessionData format
    private func convertSprintSessionToSessionData(_ session: SprintSessionTemplate) -> MainProgramWorkoutView.SessionData {
        let sprintSets = [MainProgramWorkoutView.SprintSet(
            distance: session.distance,
            restTime: session.rest,
            targetTime: nil
        )]
        
        return MainProgramWorkoutView.SessionData(
            week: 1,
            day: 1,
            sessionName: session.name,
            sessionFocus: session.focus,
            sprintSets: sprintSets,
            drillSets: [],
            strideSets: [],
            sessionType: session.sessionType.rawValue,
            level: mapLevelToInt(session.level),
            estimatedDuration: calculateEstimatedDuration(session),
            variety: 0.8,
            engagement: 0.9
        )
    }
    
    /// Record completed session for tracking
    func recordCompletedSession() {
        guard let session = sessionData else { return }
        
        // Convert back to SprintSessionTemplate for recording
        let sprintSession = SprintSessionTemplate(
            id: generateSessionId(from: session),
            name: session.sessionName,
            distance: session.sprintSets.first?.distance ?? 40,
            reps: session.sprintSets.count,
            rest: session.sprintSets.first?.restTime ?? 120,
            focus: session.sessionFocus,
            level: mapIntToLevel(session.level),
            sessionType: mapStringToLibrarySessionType(session.sessionType)
        )
        
        // Record with integrated training manager
        IntegratedTrainingManager.shared.recordCompletedSession(sprintSession)
    }
    
    /// Check if user should be encouraged to rest instead of training
    func shouldShowRestEncouragement() -> Bool {
        return IntegratedTrainingManager.shared.shouldEncourageRest()
    }
    
    /// Get rest recommendation message
    func getRestRecommendationMessage() -> String? {
        if let restActivity = IntegratedTrainingManager.shared.getTodaysRestRecommendation() {
            switch restActivity.type {
            case .completeRest:
                return "Consider taking a complete rest day for optimal recovery."
            case .activeRest:
                if let activity = restActivity.activity {
                    return "Try \(activity.name.lowercased()) instead for active recovery."
                } else {
                    return "Consider light active recovery instead of intense training."
                }
            }
        }
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func mapLevelToInt(_ level: String) -> Int {
        switch level.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "advanced": return 3
        default: return 1
        }
    }
    
    private func mapIntToLevel(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Beginner"
        }
    }
    
    private func mapStringToLibrarySessionType(_ sessionType: String) -> LibrarySessionType {
        switch sessionType.lowercased() {
        case "sprint": return .sprint
        case "active recovery": return .activeRecovery
        case "recovery": return .recovery
        case "rest": return .rest
        case "benchmark": return .benchmark
        case "tempo": return .tempo
        default: return .sprint
        }
    }
    
    private func generateSessionId(from session: MainProgramWorkoutView.SessionData) -> Int {
        // Generate a consistent ID based on session properties
        return abs(session.sessionName.hashValue) % 10000
    }
    
    private func calculateEstimatedDuration(_ session: SprintSessionTemplate) -> Int {
        // Base calculation: reps * (distance/speed + rest time) + warmup/cooldown
        let sprintTime = Double(session.reps) * (Double(session.distance) / 8.0) // Assume 8 m/s average speed
        let restTime = Double(session.reps - 1) * Double(session.rest)
        let warmupCooldown = 600.0 // 10 minutes total
        
        return Int((sprintTime + restTime + warmupCooldown) / 60) // Convert to minutes
    }
}

// MARK: - Enhanced MainProgramWorkoutView with Training Integration

struct EnhancedMainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var trainingManager = IntegratedTrainingManager.shared
    @State private var showingRestDayView = false
    @State private var showingTrainingPermissionAlert = false
    @State private var trainingPermissionMessage = ""
    
    let sessionData: MainProgramWorkoutView.SessionData?
    let onWorkoutCompleted: ((MainProgramWorkoutView.CompletedWorkoutData) -> Void)?
    
    var body: some View {
        Group {
            if trainingManager.todaysTrainingDecision.canTrain {
                MainProgramWorkoutView(
                    sessionData: getEffectiveSessionData(),
                    onWorkoutCompleted: handleWorkoutCompletion
                )
            } else {
                RestDayView()
            }
        }
        .onAppear {
            checkTrainingPermission()
        }
        .sheet(isPresented: $showingRestDayView) {
            RestDayView()
        }
        .alert("Training Recommendation", isPresented: $showingTrainingPermissionAlert) {
            Button("View Rest Day") {
                showingRestDayView = true
            }
            Button("Train Anyway", role: .destructive) {
                // Allow user to override (with warning)
            }
            Button("Cancel", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(trainingPermissionMessage)
        }
    }
    
    private func checkTrainingPermission() {
        let decision = trainingManager.todaysTrainingDecision
        
        switch decision {
        case .mandatoryRest(let reason, _):
            trainingPermissionMessage = reason + "\n\nWould you like to view rest day activities instead?"
            showingTrainingPermissionAlert = true
            
        case .activeRestRecommended(let reason, _):
            trainingPermissionMessage = reason + "\n\nConsider active recovery instead of intense training."
            showingTrainingPermissionAlert = true
            
        case .lightTrainingOnly(let reason, _, _):
            trainingPermissionMessage = reason + "\n\nOnly light training is recommended today."
            // Could modify session intensity here
            
        default:
            break
        }
    }
    
    private func getEffectiveSessionData() -> MainProgramWorkoutView.SessionData? {
        if let providedSession = sessionData {
            return providedSession
        }
        
        // Get recommended session from training manager
        if let recommendedSession = trainingManager.getTodaysRecommendedSession() {
            return convertSprintSessionToSessionData(recommendedSession)
        }
        
        return nil
    }
    
    private func handleWorkoutCompletion(_ completedWorkout: MainProgramWorkoutView.CompletedWorkoutData) {
        // Record the session with training manager
        recordCompletedSession(completedWorkout.originalSession)
        
        // Call original completion handler
        onWorkoutCompleted?(completedWorkout)
    }
    
    private func recordCompletedSession(_ session: MainProgramWorkoutView.SessionData) {
        let sprintSession = SprintSessionTemplate(
            id: generateSessionId(from: session),
            name: session.sessionName,
            distance: session.sprintSets.first?.distance ?? 40,
            reps: session.sprintSets.count,
            rest: session.sprintSets.first?.restTime ?? 120,
            focus: session.sessionFocus,
            level: mapIntToLevel(session.level),
            sessionType: mapStringToLibrarySessionType(session.sessionType)
        )
        
        trainingManager.recordCompletedSession(sprintSession)
    }
    
    // Helper methods (same as in extension above)
    private func convertSprintSessionToSessionData(_ session: SprintSessionTemplate) -> MainProgramWorkoutView.SessionData {
        let sprintSets = [MainProgramWorkoutView.SprintSet(
            distance: session.distance,
            restTime: session.rest,
            targetTime: nil
        )]
        
        return MainProgramWorkoutView.SessionData(
            week: 1,
            day: 1,
            sessionName: session.name,
            sessionFocus: session.focus,
            sprintSets: sprintSets,
            drillSets: [],
            strideSets: [],
            sessionType: session.sessionType.rawValue,
            level: mapLevelToInt(session.level),
            estimatedDuration: calculateEstimatedDuration(session),
            variety: 0.8,
            engagement: 0.9
        )
    }
    
    private func mapLevelToInt(_ level: String) -> Int {
        switch level.lowercased() {
        case "beginner": return 1
        case "intermediate": return 2
        case "advanced": return 3
        default: return 1
        }
    }
    
    private func mapIntToLevel(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Beginner"
        }
    }
    
    private func mapStringToLibrarySessionType(_ sessionType: String) -> LibrarySessionType {
        switch sessionType.lowercased() {
        case "sprint": return .sprint
        case "active recovery": return .activeRecovery
        case "recovery": return .recovery
        case "rest": return .rest
        case "benchmark": return .benchmark
        case "tempo": return .tempo
        default: return .sprint
        }
    }
    
    private func generateSessionId(from session: MainProgramWorkoutView.SessionData) -> Int {
        return abs(session.sessionName.hashValue) % 10000
    }
    
    private func calculateEstimatedDuration(_ session: SprintSessionTemplate) -> Int {
        let sprintTime = Double(session.reps) * (Double(session.distance) / 8.0)
        let restTime = Double(session.reps - 1) * Double(session.rest)
        let warmupCooldown = 600.0
        
        return Int((sprintTime + restTime + warmupCooldown) / 60)
    }
}
