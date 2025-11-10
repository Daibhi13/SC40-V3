import SwiftUI
import Foundation

// MARK: - Session Rotation Integration Extension for TrainingView

extension TrainingView {
    
    /// Get today's recommended training session with variety enforcement
    func getTodaysRecommendedSession() -> TrainingSession? {
        let trainingManager = IntegratedTrainingManager.shared
        
        // Check if user can train today
        let decision = trainingManager.canTrainToday()
        
        switch decision {
        case .trainingApproved(_, let recommendedSession, _):
            if let session = recommendedSession {
                return convertSprintSessionToTrainingSession(session)
            }
            
        case .lightTrainingOnly(_, let allowedSessions, _):
            if let lightSession = allowedSessions.first {
                return convertSprintSessionToTrainingSession(lightSession)
            }
            
        default:
            return nil
        }
        
        return nil
    }
    
    /// Get varied session recommendations based on recent training history
    func getVariedSessionRecommendations(for userLevel: String) -> [TrainingSession] {
        let sessionManager = SessionRotationManager.shared
        
        var recommendations: [TrainingSession] = []
        
        // Get sessions for each available session type
        for sessionType in RestRecoveryManager.SessionType.allCases {
            let permission = sessionManager.canPerformSessionType(sessionType)
            
            switch permission {
            case .approved, .cautioned:
                if let session = sessionManager.getSessionByType(sessionType, userLevel: userLevel) {
                    let trainingSession = convertSprintSessionToTrainingSession(session)
                    recommendations.append(trainingSession)
                }
            case .denied:
                continue
            }
        }
        
        // Limit to top 6 recommendations and sort by variety
        return Array(recommendations.prefix(6))
    }
    
    /// Update dynamic sessions with variety-enforced recommendations
    func updateDynamicSessionsWithVariety() {
        let userLevel = getUserLevel()
        _ = getVariedSessionRecommendations(for: userLevel)
        
        // Note: This would need to be implemented in the actual TrainingView
        // as dynamicSessions is private to that view
    }
    
    /// Check if user should see rest day recommendation
    func shouldShowRestDayPrompt() -> Bool {
        let trainingManager = IntegratedTrainingManager.shared
        return trainingManager.shouldEncourageRest()
    }
    
    /// Get rest day message for user
    func getRestDayMessage() -> String? {
        let trainingManager = IntegratedTrainingManager.shared
        
        if let restActivity = trainingManager.getTodaysRestRecommendation() {
            switch restActivity.type {
            case .completeRest:
                return "Your body needs complete rest today for optimal recovery."
            case .activeRest:
                if let activity = restActivity.activity {
                    return "Consider \(activity.name.lowercased()) for active recovery instead of intense training."
                }
            }
        }
        
        return nil
    }
    
    /// Record completed session for variety tracking
    func recordCompletedTrainingSession(_ session: TrainingSession) {
        // Convert TrainingSession back to SprintSessionTemplate
        let sprintSession = convertTrainingSessionToSprintSession(session)
        
        // Record with integrated training manager
        IntegratedTrainingManager.shared.recordCompletedSession(sprintSession)
        
        // Update dynamic sessions to reflect new variety requirements
        updateDynamicSessionsWithVariety()
    }
    
    /// Get session variety stats for display
    func getSessionVarietyStats() -> SessionVarietyStats {
        let sessionManager = SessionRotationManager.shared
        let currentWeek = sessionManager.currentWeekSessions
        
        let sessionTypeCounts = Dictionary(grouping: currentWeek) { $0 }
            .mapValues { $0.count }
        
        let totalSessions = currentWeek.count
        let uniqueSessionTypes = Set(currentWeek).count
        let varietyScore = totalSessions > 0 ? Double(uniqueSessionTypes) / Double(RestRecoveryManager.SessionType.allCases.count) : 0.0
        
        return SessionVarietyStats(
            totalSessionsThisWeek: totalSessions,
            uniqueSessionTypes: uniqueSessionTypes,
            varietyScore: varietyScore,
            sessionTypeCounts: sessionTypeCounts,
            recommendedNextType: getRecommendedNextSessionType()
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func convertSprintSessionToTrainingSession(_ sprintSession: SprintSessionTemplate) -> TrainingSession {
        let sprintSet = SprintSet(
            distanceYards: sprintSession.distance,
            reps: sprintSession.reps,
            intensity: getIntensityFromSessionType(sprintSession)
        )
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: 1, day: 1),
            week: 1,
            day: 1,
            type: sprintSession.name,
            focus: sprintSession.focus,
            sprints: [sprintSet],
            accessoryWork: getAccessoryWorkForSession(sprintSession),
            notes: "Rest: \(sprintSession.rest / 60) minutes between reps"
        )
    }
    
    private func convertTrainingSessionToSprintSession(_ trainingSession: TrainingSession) -> SprintSessionTemplate {
        let firstSprint = trainingSession.sprints.first
        
        return SprintSessionTemplate(
            id: Int(trainingSession.id.hashValue) % 10000,
            name: trainingSession.type,
            distance: firstSprint?.distanceYards ?? 40,
            reps: firstSprint?.reps ?? 4,
            rest: 120, // Default rest time
            focus: trainingSession.focus,
            level: getUserLevel(),
            sessionType: .sprint
        )
    }
    
    private func getIntensityFromSessionType(_ session: SprintSessionTemplate) -> String {
        let sessionType = SessionRotationManager.shared.getSessionTypeFromFocus(session.focus)
        
        switch sessionType {
        case .acceleration: return "moderate"
        case .drivePhase: return "high"
        case .maxVelocity: return "max"
        case .speedEndurance: return "high"
        case .activeRecovery: return "light"
        case .benchmark: return "all-out"
        case .tempo: return "moderate"
        }
    }
    
    private func getAccessoryWorkForSession(_ session: SprintSessionTemplate) -> [String] {
        let sessionType = SessionRotationManager.shared.getSessionTypeFromFocus(session.focus)
        
        switch sessionType {
        case .acceleration:
            return ["Block starts", "Acceleration drills", "A-skips"]
        case .drivePhase:
            return ["Drive phase drills", "Wicket runs", "Sled pulls"]
        case .maxVelocity:
            return ["Flying sprints", "Overspeed training", "Relaxation drills"]
        case .speedEndurance:
            return ["Tempo runs", "Lactate threshold work", "Recovery runs"]
        case .activeRecovery:
            return ["Dynamic stretching", "Light jogging", "Mobility work"]
        case .benchmark:
            return ["Thorough warm-up", "Activation exercises", "Cool-down"]
        case .tempo:
            return ["Rhythm runs", "Breathing exercises", "Form drills"]
        }
    }
    
    private func getUserLevel() -> String {
        // Get user level from profile or default to Beginner
        return userProfileVM.profile.level
    }
    
    private func getRecommendedNextSessionType() -> RestRecoveryManager.SessionType? {
        let sessionManager = SessionRotationManager.shared
        let restManager = RestRecoveryManager.shared
        
        return sessionManager.getRecommendedSession(
            for: restManager.trainingFrequency,
            userLevel: getUserLevel()
        ).map { session in
            sessionManager.getSessionTypeFromFocus(session.focus)
        }
    }
}

// MARK: - Enhanced TrainingView with Session Rotation

struct EnhancedTrainingView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @StateObject private var trainingManager = IntegratedTrainingManager.shared
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showMenu = false
    @State private var selectedMenu: MenuSelection = .main
    @State private var showPaywall = false
    @State private var showSixPartWorkout = false
    @State private var selectedSession: TrainingSession?
    @State private var showMainProgramWorkout = false
    @State private var showSprintTimerPro = false
    @State private var selectedSessionForWorkout: TrainingSession?
    @State private var dynamicSessions: [TrainingSession] = []
    @State private var showingRestDayView = false
    @State private var sessionVarietyStats = SessionVarietyStats()
    
    var body: some View {
        ZStack {
            // Background (same as original TrainingView)
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Training Status Card
                    TrainingStatusCard(
                        decision: trainingManager.todaysTrainingDecision,
                        onRestDayTapped: { showingRestDayView = true }
                    )
                    
                    // Session Variety Stats
                    SessionVarietyCard(stats: sessionVarietyStats)
                    
                    // Today's Recommended Session
                    if let recommendedSession = getTodaysRecommendedSession() {
                        TrainingRecommendedSessionCard(
                            session: recommendedSession,
                            onStartTapped: { startRecommendedSession(recommendedSession) }
                        )
                    }
                    
                    // Varied Session Grid
                    VariedSessionGrid(
                        sessions: dynamicSessions,
                        onSessionSelected: { session in
                            selectedSessionForWorkout = session
                            showMainProgramWorkout = true
                        }
                    )
                }
                .padding()
            }
        }
        .onAppear {
            // Ensure profile is valid before proceeding to avoid crashes
            let level = userProfileVM.profile.level
            let freq = userProfileVM.profile.frequency
            let base = userProfileVM.profile.baselineTime
            if level.isEmpty || freq <= 0 || base <= 0 {
                print("⚠️ EnhancedTrainingView: Missing profile values (level=\(level), freq=\(freq), baseline=\(base)). Deferring setup.")
                return
            }
            updateDynamicSessionsWithVariety()
            updateSessionVarietyStats()
        }
        .sheet(isPresented: $showingRestDayView) {
            RestDayView()
        }
        .sheet(isPresented: $showMainProgramWorkout) {
            if let session = selectedSessionForWorkout {
                EnhancedMainProgramWorkoutView(
                    sessionData: convertTrainingSessionToSessionData(session),
                    onWorkoutCompleted: { completedWorkout in
                        recordCompletedTrainingSession(session)
                        showMainProgramWorkout = false
                    }
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startRecommendedSession(_ session: TrainingSession) {
        selectedSessionForWorkout = session
        showMainProgramWorkout = true
    }
    
    private func updateSessionVarietyStats() {
        sessionVarietyStats = getSessionVarietyStats()
    }
    
    // Include all the helper methods from the extension above
    private func getTodaysRecommendedSession() -> TrainingSession? {
        let trainingManager = IntegratedTrainingManager.shared
        
        let decision = trainingManager.canTrainToday()
        
        switch decision {
        case .trainingApproved(_, let recommendedSession, _):
            if let session = recommendedSession {
                return convertSprintSessionToTrainingSession(session)
            }
        case .lightTrainingOnly(_, let allowedSessions, _):
            if let lightSession = allowedSessions.first {
                return convertSprintSessionToTrainingSession(lightSession)
            }
        default:
            return nil
        }
        
        return nil
    }
    
    private func updateDynamicSessionsWithVariety() {
        let userLevel = getUserLevel()
        let variedSessions = getVariedSessionRecommendations(for: userLevel)
        
        DispatchQueue.main.async {
            self.dynamicSessions = variedSessions
        }
    }
    
    private func getVariedSessionRecommendations(for userLevel: String) -> [TrainingSession] {
        let sessionManager = SessionRotationManager.shared
        
        var recommendations: [TrainingSession] = []
        
        for sessionType in RestRecoveryManager.SessionType.allCases {
            let permission = sessionManager.canPerformSessionType(sessionType)
            
            switch permission {
            case .approved, .cautioned:
                if let session = sessionManager.getSessionByType(sessionType, userLevel: userLevel) {
                    let trainingSession = convertSprintSessionToTrainingSession(session)
                    recommendations.append(trainingSession)
                }
            case .denied:
                continue
            }
        }
        
        return Array(recommendations.prefix(6))
    }
    
    private func recordCompletedTrainingSession(_ session: TrainingSession) {
        let sprintSession = convertTrainingSessionToSprintSession(session)
        trainingManager.recordCompletedSession(sprintSession)
        updateDynamicSessionsWithVariety()
        updateSessionVarietyStats()
    }
    
    private func getSessionVarietyStats() -> SessionVarietyStats {
        let sessionManager = SessionRotationManager.shared
        let currentWeek = sessionManager.currentWeekSessions
        
        let sessionTypeCounts = Dictionary(grouping: currentWeek) { $0 }
            .mapValues { $0.count }
        
        let totalSessions = currentWeek.count
        let uniqueSessionTypes = Set(currentWeek).count
        let varietyScore = totalSessions > 0 ? Double(uniqueSessionTypes) / Double(RestRecoveryManager.SessionType.allCases.count) : 0.0
        
        return SessionVarietyStats(
            totalSessionsThisWeek: totalSessions,
            uniqueSessionTypes: uniqueSessionTypes,
            varietyScore: varietyScore,
            sessionTypeCounts: sessionTypeCounts,
            recommendedNextType: getRecommendedNextSessionType()
        )
    }
    
    // Helper methods (same as extension)
    private func convertSprintSessionToTrainingSession(_ sprintSession: SprintSessionTemplate) -> TrainingSession {
        let sprintSet = SprintSet(
            distanceYards: sprintSession.distance,
            reps: sprintSession.reps,
            intensity: getIntensityFromSessionType(sprintSession)
        )
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: 1, day: 1),
            week: 1,
            day: 1,
            type: sprintSession.name,
            focus: sprintSession.focus,
            sprints: [sprintSet],
            accessoryWork: getAccessoryWorkForSession(sprintSession),
            notes: "Rest: \(sprintSession.rest / 60) minutes between reps"
        )
    }
    
    private func convertTrainingSessionToSprintSession(_ trainingSession: TrainingSession) -> SprintSessionTemplate {
        let firstSprint = trainingSession.sprints.first
        
        return SprintSessionTemplate(
            id: Int(trainingSession.id.hashValue) % 10000,
            name: trainingSession.type,
            distance: firstSprint?.distanceYards ?? 40,
            reps: firstSprint?.reps ?? 4,
            rest: 120,
            focus: trainingSession.focus,
            level: getUserLevel(),
            sessionType: .sprint
        )
    }
    
    private func convertTrainingSessionToSessionData(_ session: TrainingSession) -> MainProgramWorkoutView.SessionData {
        let sprintSets = session.sprints.map { sprint in
            MainProgramWorkoutView.SprintSet(distance: sprint.distanceYards, restTime: 120, targetTime: nil)
        }
        
        return MainProgramWorkoutView.SessionData(
            week: session.week,
            day: session.day,
            sessionName: session.type,
            sessionFocus: session.focus,
            sprintSets: sprintSets,
            drillSets: [],
            strideSets: [],
            sessionType: "Sprint",
            level: 2,
            estimatedDuration: 25,
            variety: 0.8,
            engagement: 0.9
        )
    }
    
    private func getIntensityFromSessionType(_ session: SprintSessionTemplate) -> String {
        let sessionType = SessionRotationManager.shared.getSessionTypeFromFocus(session.focus)
        
        switch sessionType {
        case .acceleration: return "moderate"
        case .drivePhase: return "high"
        case .maxVelocity: return "max"
        case .speedEndurance: return "high"
        case .activeRecovery: return "light"
        case .benchmark: return "all-out"
        case .tempo: return "moderate"
        }
    }
    
    private func getAccessoryWorkForSession(_ session: SprintSessionTemplate) -> [String] {
        let sessionType = SessionRotationManager.shared.getSessionTypeFromFocus(session.focus)
        
        switch sessionType {
        case .acceleration: return ["Block starts", "Acceleration drills", "A-skips"]
        case .drivePhase: return ["Drive phase drills", "Wicket runs", "Sled pulls"]
        case .maxVelocity: return ["Flying sprints", "Overspeed training", "Relaxation drills"]
        case .speedEndurance: return ["Tempo runs", "Lactate threshold work", "Recovery runs"]
        case .activeRecovery: return ["Dynamic stretching", "Light jogging", "Mobility work"]
        case .benchmark: return ["Thorough warm-up", "Activation exercises", "Cool-down"]
        case .tempo: return ["Rhythm runs", "Breathing exercises", "Form drills"]
        }
    }
    
    private func getUserLevel() -> String {
        return userProfileVM.profile.level
    }
    
    private func getRecommendedNextSessionType() -> RestRecoveryManager.SessionType? {
        let sessionManager = SessionRotationManager.shared
        let restManager = RestRecoveryManager.shared
        
        return sessionManager.getRecommendedSession(
            for: restManager.trainingFrequency,
            userLevel: getUserLevel()
        ).map { session in
            sessionManager.getSessionTypeFromFocus(session.focus)
        }
    }
}

// MARK: - Supporting Structs

struct SessionVarietyStats {
    let totalSessionsThisWeek: Int
    let uniqueSessionTypes: Int
    let varietyScore: Double
    let sessionTypeCounts: [RestRecoveryManager.SessionType: Int]
    let recommendedNextType: RestRecoveryManager.SessionType?
    
    init() {
        self.totalSessionsThisWeek = 0
        self.uniqueSessionTypes = 0
        self.varietyScore = 0.0
        self.sessionTypeCounts = [:]
        self.recommendedNextType = nil
    }
    
    init(totalSessionsThisWeek: Int, uniqueSessionTypes: Int, varietyScore: Double, sessionTypeCounts: [RestRecoveryManager.SessionType: Int], recommendedNextType: RestRecoveryManager.SessionType?) {
        self.totalSessionsThisWeek = totalSessionsThisWeek
        self.uniqueSessionTypes = uniqueSessionTypes
        self.varietyScore = varietyScore
        self.sessionTypeCounts = sessionTypeCounts
        self.recommendedNextType = recommendedNextType
    }
}

// MARK: - UI Components

struct TrainingStatusCard: View {
    let decision: TrainingDecision
    let onRestDayTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: decision.icon)
                    .foregroundColor(decision.color)
                    .font(.title2)
                
                Text(decision.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !decision.canTrain {
                    Button("View Rest Day") {
                        onRestDayTapped()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

struct SessionVarietyCard: View {
    let stats: SessionVarietyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Session Variety")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(stats.totalSessionsThisWeek)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("This Week")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(stats.varietyScore * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Variety Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

struct TrainingRecommendedSessionCard: View {
    let session: TrainingSession
    let onStartTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Recommended Today")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(session.type)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(session.focus)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button("Start Workout") {
                onStartTapped()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

struct VariedSessionGrid: View {
    let sessions: [TrainingSession]
    let onSessionSelected: (TrainingSession) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(sessions, id: \.id) { session in
                SessionCard(session: session) {
                    onSessionSelected(session)
                }
            }
        }
    }
}

struct SessionCard: View {
    let session: TrainingSession
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text(session.focus)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                if let firstSprint = session.sprints.first {
                    HStack {
                        Text("\(firstSprint.distanceYards)yd")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        Text("×\(firstSprint.reps)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
