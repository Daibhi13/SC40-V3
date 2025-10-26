# 🔄 SC40 Session Rotation & Variety Management System

## 📋 **Session Type Analysis from SessionLibrary**

Based on the SessionLibrary analysis, we have these distinct session categories:

### **🎯 Primary Session Types:**
1. **Sprint** - Pure speed development (40+ sessions)
2. **Active Recovery** - Light tempo work (6 sessions)
3. **Benchmark** - Time trials and testing (4 sessions)
4. **Tempo** - Speed endurance work (8 sessions)

### **🏃‍♂️ Focus Categories:**
1. **Acceleration** - 0-30 yard focus (25 sessions)
2. **Drive Phase** - 20-40 yard focus (15 sessions)
3. **Max Velocity** - 40+ yard focus (20 sessions)
4. **Speed Endurance** - Multiple reps/longer distances (18 sessions)
5. **Peak Velocity** - Elite level max speed (8 sessions)

### **📏 Distance Categories:**
1. **Short (5-25 yards)** - Acceleration focus
2. **Medium (30-50 yards)** - Speed development
3. **Long (55+ yards)** - Max velocity/endurance

---

## 🔄 **Session Rotation Management System**

### **1. Weekly Session Tracker** 📅

```swift
class SessionRotationManager: ObservableObject {
    @Published var weeklySessionHistory: [Date: SessionType] = [:]
    @Published var currentWeekSessions: [SessionType] = []
    @Published var availableSessions: [SprintSessionTemplate] = []
    @Published var recommendedNextSession: SprintSessionTemplate?
    
    enum SessionType: String, CaseIterable {
        case acceleration = "Acceleration"
        case drivePhase = "Drive Phase"
        case maxVelocity = "Max Velocity"
        case speedEndurance = "Speed Endurance"
        case activeRecovery = "Active Recovery"
        case benchmark = "Benchmark"
        case tempo = "Tempo"
        
        var priority: Int {
            switch self {
            case .acceleration: return 1      // Foundational - highest priority
            case .drivePhase: return 2        // Core development
            case .maxVelocity: return 3       // Peak performance
            case .speedEndurance: return 4    // Conditioning
            case .tempo: return 5             // Recovery-focused training
            case .activeRecovery: return 6    // Light recovery
            case .benchmark: return 7         // Testing - lowest frequency
            }
        }
        
        var maxWeeklyFrequency: Int {
            switch self {
            case .acceleration: return 2      // Can do twice per week
            case .drivePhase: return 2        // Can do twice per week
            case .maxVelocity: return 1       // Once per week max
            case .speedEndurance: return 1    // Once per week max
            case .tempo: return 2             // Can do twice per week
            case .activeRecovery: return 3    // Multiple times per week
            case .benchmark: return 1         // Once per week max
            }
        }
    }
    
    // Check if user can do a specific session type today
    func canPerformSessionType(_ sessionType: SessionType) -> SessionPermission {
        let currentWeek = getCurrentWeekSessions()
        let sessionCount = currentWeek.filter { $0 == sessionType }.count
        
        // Check weekly frequency limits
        if sessionCount >= sessionType.maxWeeklyFrequency {
            return .denied(
                reason: "Already completed \(sessionType.rawValue) \(sessionCount) time(s) this week",
                alternatives: getAlternativeSessionTypes(excluding: sessionType)
            )
        }
        
        // Check if same session type was done yesterday (for high-intensity sessions)
        if isHighIntensitySession(sessionType) && wasSessionTypePerformedYesterday(sessionType) {
            return .cautioned(
                reason: "Same high-intensity session type performed yesterday",
                alternatives: getLowerIntensityAlternatives()
            )
        }
        
        return .approved(reason: "Session type available for training")
    }
    
    // Get recommended session based on training history and variety
    func getRecommendedSession(for trainingFrequency: RestRecoveryManager.TrainingFrequency, 
                              userLevel: String) -> SprintSessionTemplate? {
        let currentWeek = getCurrentWeekSessions()
        let availableTypes = getAvailableSessionTypes(currentWeek: currentWeek)
        
        // Prioritize session types based on training frequency
        let prioritizedTypes = prioritizeSessionTypes(
            availableTypes: availableTypes,
            trainingFrequency: trainingFrequency,
            currentWeek: currentWeek
        )
        
        // Get sessions from library matching the prioritized type and user level
        guard let targetType = prioritizedTypes.first else { return nil }
        
        let matchingSessions = sessionLibrary.filter { session in
            getSessionTypeFromFocus(session.focus) == targetType &&
            (session.level.lowercased() == userLevel.lowercased() || session.level.lowercased() == "all levels")
        }
        
        // Return a session that hasn't been done recently
        return selectVariedSession(from: matchingSessions)
    }
}

enum SessionPermission {
    case approved(reason: String)
    case cautioned(reason: String, alternatives: [SessionType])
    case denied(reason: String, alternatives: [SessionType])
}
```

### **2. Training Frequency-Based Session Planning** 📊

```swift
extension SessionRotationManager {
    
    // Generate optimal weekly schedule based on training frequency
    func generateWeeklySchedule(frequency: RestRecoveryManager.TrainingFrequency, 
                               userLevel: String) -> [DayOfWeek: SessionPlan] {
        var schedule: [DayOfWeek: SessionPlan] = [:]
        
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
    
    private func generateCasualSchedule(days: Int, userLevel: String) -> [DayOfWeek: SessionPlan] {
        // 2-3 days per week - focus on variety and recovery
        if days == 2 {
            return [
                .monday: SessionPlan(
                    sessionType: .acceleration,
                    session: getSessionByTypeAndLevel(.acceleration, userLevel),
                    restDay: false
                ),
                .tuesday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: false),
                .wednesday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true),
                .thursday: SessionPlan(
                    sessionType: .maxVelocity,
                    session: getSessionByTypeAndLevel(.maxVelocity, userLevel),
                    restDay: false
                ),
                .friday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: false),
                .saturday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true),
                .sunday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true)
            ]
        } else { // 3 days
            return [
                .monday: SessionPlan(
                    sessionType: .acceleration,
                    session: getSessionByTypeAndLevel(.acceleration, userLevel),
                    restDay: false
                ),
                .tuesday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true),
                .wednesday: SessionPlan(
                    sessionType: .drivePhase,
                    session: getSessionByTypeAndLevel(.drivePhase, userLevel),
                    restDay: false
                ),
                .thursday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true),
                .friday: SessionPlan(
                    sessionType: .maxVelocity,
                    session: getSessionByTypeAndLevel(.maxVelocity, userLevel),
                    restDay: false
                ),
                .saturday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: false),
                .sunday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true)
            ]
        }
    }
    
    private func generateRegularSchedule(days: Int, userLevel: String) -> [DayOfWeek: SessionPlan] {
        // 4-5 days per week - balanced variety with strategic rest
        return [
            .monday: SessionPlan(
                sessionType: .acceleration,
                session: getSessionByTypeAndLevel(.acceleration, userLevel),
                restDay: false
            ),
            .tuesday: SessionPlan(
                sessionType: .activeRecovery,
                session: getSessionByTypeAndLevel(.activeRecovery, userLevel),
                restDay: false
            ),
            .wednesday: SessionPlan(
                sessionType: .drivePhase,
                session: getSessionByTypeAndLevel(.drivePhase, userLevel),
                restDay: false
            ),
            .thursday: SessionPlan(
                sessionType: .tempo,
                session: getSessionByTypeAndLevel(.tempo, userLevel),
                restDay: false
            ),
            .friday: SessionPlan(
                sessionType: .maxVelocity,
                session: getSessionByTypeAndLevel(.maxVelocity, userLevel),
                restDay: false
            ),
            .saturday: SessionPlan(
                sessionType: .activeRecovery,
                session: getSessionByTypeAndLevel(.activeRecovery, userLevel),
                restDay: false
            ),
            .sunday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true)
        ]
    }
    
    private func generateSeriousSchedule(days: Int, userLevel: String) -> [DayOfWeek: SessionPlan] {
        // 5-7 days per week - maximum variety with mandatory complete rest
        return [
            .monday: SessionPlan(
                sessionType: .acceleration,
                session: getSessionByTypeAndLevel(.acceleration, userLevel),
                restDay: false
            ),
            .tuesday: SessionPlan(
                sessionType: .tempo,
                session: getSessionByTypeAndLevel(.tempo, userLevel),
                restDay: false
            ),
            .wednesday: SessionPlan(
                sessionType: .drivePhase,
                session: getSessionByTypeAndLevel(.drivePhase, userLevel),
                restDay: false
            ),
            .thursday: SessionPlan(
                sessionType: .activeRecovery,
                session: getSessionByTypeAndLevel(.activeRecovery, userLevel),
                restDay: false
            ),
            .friday: SessionPlan(
                sessionType: .maxVelocity,
                session: getSessionByTypeAndLevel(.maxVelocity, userLevel),
                restDay: false
            ),
            .saturday: SessionPlan(
                sessionType: .speedEndurance,
                session: getSessionByTypeAndLevel(.speedEndurance, userLevel),
                restDay: false
            ),
            .sunday: SessionPlan(sessionType: .activeRecovery, session: nil, restDay: true) // Mandatory complete rest
        ]
    }
}

struct SessionPlan {
    let sessionType: SessionRotationManager.SessionType
    let session: SprintSessionTemplate?
    let restDay: Bool
    
    var isActiveRest: Bool {
        return sessionType == .activeRecovery && !restDay
    }
    
    var isCompleteRest: Bool {
        return restDay
    }
}
```

### **3. Session Variety & Selection Algorithm** 🎲

```swift
extension SessionRotationManager {
    
    // Intelligent session selection to maximize variety
    func selectVariedSession(from sessions: [SprintSessionTemplate]) -> SprintSessionTemplate? {
        guard !sessions.isEmpty else { return nil }
        
        let recentSessions = getRecentSessionHistory(days: 14) // Last 2 weeks
        let recentSessionIds = Set(recentSessions.map { $0.id })
        
        // Filter out recently performed sessions
        let unperformedSessions = sessions.filter { !recentSessionIds.contains($0.id) }
        
        if !unperformedSessions.isEmpty {
            // Prioritize sessions not done recently
            return selectByVarietyScore(unperformedSessions)
        } else {
            // If all sessions have been done recently, pick the least recent
            return selectLeastRecentSession(sessions, recentHistory: recentSessions)
        }
    }
    
    private func selectByVarietyScore(_ sessions: [SprintSessionTemplate]) -> SprintSessionTemplate? {
        // Score sessions based on variety factors
        let scoredSessions = sessions.map { session in
            (session: session, score: calculateVarietyScore(session))
        }
        
        // Return session with highest variety score
        return scoredSessions.max(by: { $0.score < $1.score })?.session
    }
    
    private func calculateVarietyScore(_ session: SprintSessionTemplate) -> Double {
        var score: Double = 0
        
        // Distance variety (prefer different distances from recent sessions)
        let recentDistances = getRecentDistances(days: 7)
        if !recentDistances.contains(session.distance) {
            score += 3.0
        }
        
        // Rep count variety
        let recentRepCounts = getRecentRepCounts(days: 7)
        if !recentRepCounts.contains(session.reps) {
            score += 2.0
        }
        
        // Focus variety
        let recentFocuses = getRecentFocuses(days: 7)
        if !recentFocuses.contains(session.focus) {
            score += 2.5
        }
        
        // Session type variety
        let recentTypes = getRecentSessionTypes(days: 7)
        if !recentTypes.contains(session.sessionType) {
            score += 4.0
        }
        
        return score
    }
    
    // Map session focus to session type for categorization
    func getSessionTypeFromFocus(_ focus: String) -> SessionType {
        let focusLower = focus.lowercased()
        
        if focusLower.contains("acceleration") || focusLower.contains("start") {
            return .acceleration
        } else if focusLower.contains("drive") {
            return .drivePhase
        } else if focusLower.contains("max velocity") || focusLower.contains("peak velocity") || focusLower.contains("top-end") {
            return .maxVelocity
        } else if focusLower.contains("speed endurance") || focusLower.contains("repeat") {
            return .speedEndurance
        } else if focusLower.contains("active recovery") || focusLower.contains("tempo") {
            return .activeRecovery
        } else if focusLower.contains("benchmark") || focusLower.contains("time trial") {
            return .benchmark
        } else if focusLower.contains("tempo") {
            return .tempo
        } else {
            return .acceleration // Default fallback
        }
    }
}
```

### **4. Integration with Rest & Recovery System** 🔗

```swift
class IntegratedTrainingManager: ObservableObject {
    @StateObject private var restManager = RestRecoveryManager()
    @StateObject private var sessionManager = SessionRotationManager()
    @StateObject private var recoveryMonitor = RecoveryMonitor()
    
    // Unified training permission check
    func canTrainToday() -> TrainingDecision {
        // First check rest requirements
        let restPermission = restManager.canTrainToday()
        
        switch restPermission {
        case .denied(let reason, let activity):
            return .mandatoryRest(reason: reason, activity: activity)
            
        case .cautioned(let reason, let activity):
            // Check if we can do light training instead
            let lightSessions = sessionManager.getAvailableSessionTypes(intensity: .light)
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
                userLevel: getCurrentUserLevel()
            )
            
            return .trainingApproved(
                reason: reason,
                recommendedSession: recommendedSession,
                alternatives: getAlternativeSessions()
            )
        }
    }
    
    // Generate complete weekly training plan
    func generateWeeklyPlan() -> WeeklyTrainingPlan {
        let restSchedule = restManager.generateOptimalSchedule(frequency: restManager.trainingFrequency)
        let sessionSchedule = sessionManager.generateWeeklySchedule(
            frequency: restManager.trainingFrequency,
            userLevel: getCurrentUserLevel()
        )
        
        return WeeklyTrainingPlan(
            restSchedule: restSchedule,
            sessionSchedule: sessionSchedule,
            trainingFrequency: restManager.trainingFrequency
        )
    }
}

enum TrainingDecision {
    case mandatoryRest(reason: String, activity: RestActivity)
    case activeRestRecommended(reason: String, activity: RestActivity)
    case lightTrainingOnly(reason: String, allowedSessions: [SessionRotationManager.SessionType], alternativeActivity: RestActivity)
    case trainingApproved(reason: String, recommendedSession: SprintSessionTemplate?, alternatives: [SprintSessionTemplate])
}

struct WeeklyTrainingPlan {
    let restSchedule: [DayOfWeek: RestDayScheduler.WorkoutType]
    let sessionSchedule: [DayOfWeek: SessionPlan]
    let trainingFrequency: RestRecoveryManager.TrainingFrequency
    
    func getDayPlan(for day: DayOfWeek) -> DayPlan {
        let restPlan = restSchedule[day] ?? .flexible
        let sessionPlan = sessionSchedule[day]
        
        return DayPlan(
            day: day,
            restType: restPlan,
            sessionPlan: sessionPlan
        )
    }
}

struct DayPlan {
    let day: DayOfWeek
    let restType: RestDayScheduler.WorkoutType
    let sessionPlan: SessionPlan?
    
    var isTrainingDay: Bool {
        return sessionPlan?.session != nil && !sessionPlan!.restDay
    }
    
    var isActiveRestDay: Bool {
        return sessionPlan?.isActiveRest == true
    }
    
    var isCompleteRestDay: Bool {
        return sessionPlan?.isCompleteRest == true
    }
}
```

### **5. Session Rotation UI & User Experience** 📱

```swift
struct SessionRotationView: View {
    @StateObject private var trainingManager = IntegratedTrainingManager()
    @State private var selectedDay: DayOfWeek = .monday
    @State private var showingSessionDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Training Decision
                    TodaysTrainingCard(decision: trainingManager.canTrainToday())
                    
                    // Weekly Plan Overview
                    WeeklyPlanView(plan: trainingManager.generateWeeklyPlan())
                    
                    // Session Variety Stats
                    SessionVarietyStatsCard()
                    
                    // Upcoming Sessions Preview
                    UpcomingSessionsCard()
                }
                .padding()
            }
            .navigationTitle("Training Plan")
        }
    }
}

struct TodaysTrainingCard: View {
    let decision: TrainingDecision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: decisionIcon)
                    .foregroundColor(decisionColor)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Today's Training")
                        .font(.headline)
                    Text(decisionTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(decisionDescription)
                .font(.body)
                .foregroundColor(.primary)
            
            if case .trainingApproved(_, let session, _) = decision,
               let recommendedSession = session {
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Session")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SessionSummaryRow(session: recommendedSession)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var decisionIcon: String {
        switch decision {
        case .mandatoryRest: return "bed.double.fill"
        case .activeRestRecommended: return "figure.walk"
        case .lightTrainingOnly: return "figure.run"
        case .trainingApproved: return "bolt.fill"
        }
    }
    
    private var decisionColor: Color {
        switch decision {
        case .mandatoryRest: return .red
        case .activeRestRecommended: return .orange
        case .lightTrainingOnly: return .yellow
        case .trainingApproved: return .green
        }
    }
    
    private var decisionTitle: String {
        switch decision {
        case .mandatoryRest: return "Rest Day Required"
        case .activeRestRecommended: return "Active Recovery"
        case .lightTrainingOnly: return "Light Training Only"
        case .trainingApproved: return "Ready to Train"
        }
    }
    
    private var decisionDescription: String {
        switch decision {
        case .mandatoryRest(let reason, _): return reason
        case .activeRestRecommended(let reason, _): return reason
        case .lightTrainingOnly(let reason, _, _): return reason
        case .trainingApproved(let reason, _, _): return reason
        }
    }
}
```

---

## 🎯 **Key Benefits of Session Rotation System**

### **🚫 Prevents Overuse:**
- **No Same Session Type** within 48 hours for high-intensity work
- **Weekly Frequency Limits** prevent overtraining specific movement patterns
- **Automatic Variety** ensures balanced development

### **📈 Optimizes Development:**
- **Progressive Overload** through varied stimuli
- **Balanced Training** across all speed components
- **Periodized Approach** with strategic session placement

### **🧠 Maintains Engagement:**
- **Never Boring** - always something different
- **Anticipation** for new session types
- **Achievement Variety** across different focuses

### **🔗 Seamless Integration:**
- **Works with Rest System** - respects recovery needs
- **Adapts to Frequency** - scales with user's training level
- **User Level Aware** - appropriate sessions for skill level

This comprehensive system ensures users training 2+ days per week never repeat the same session type, maintaining variety, preventing overuse injuries, and optimizing development across all aspects of sprint performance! 🏃‍♂️💪
