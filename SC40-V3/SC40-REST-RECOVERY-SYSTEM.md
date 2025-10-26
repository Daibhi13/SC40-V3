# 🛌 SC40 Rest & Recovery Management System

## 📋 **Training Frequency & Rest Requirements**

### **🎯 Training Frequency Categories:**

#### **Category 1: Casual Athletes (2-3 days/week)**
- **Mandatory Rest:** 1-2 days between sprint sessions
- **Active Rest:** Light movement on off days
- **Recovery Focus:** Full muscle recovery, technique retention

#### **Category 2: Regular Athletes (4-5 days/week)**
- **Mandatory Rest:** 1 day between high-intensity sessions
- **Active Rest:** 2-3 active recovery sessions per week
- **Recovery Focus:** Balanced training load, injury prevention

#### **Category 3: Serious Athletes (5-7 days/week)**
- **Mandatory Rest:** 1 complete rest day per week minimum
- **Active Rest:** Daily light activity on non-sprint days
- **Recovery Focus:** Performance optimization, overtraining prevention

---

## 🔄 **Rest & Recovery System Architecture**

### **1. Intelligent Rest Scheduling** 🧠

```swift
class RestRecoveryManager: ObservableObject {
    @Published var trainingFrequency: TrainingFrequency = .regular
    @Published var lastSprintDate: Date?
    @Published var lastSessionType: SessionRotationManager.SessionType?
    @Published var restDaysRequired: Int = 1
    @Published var activeRestRecommendations: [ActiveRestActivity] = []
    @Published var recoveryScore: Double = 1.0 // 0.0 = exhausted, 1.0 = fully recovered
    
    enum TrainingFrequency {
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
    }
    
    // Calculate if user can train today (integrates with session rotation)
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
    
    // Update training history with session type
    func recordTrainingSession(sessionType: SessionRotationManager.SessionType) {
        lastSprintDate = Date()
        lastSessionType = sessionType
        
        // Update recovery score based on session intensity
        updateRecoveryScoreAfterSession(sessionType)
    }
    
    private func updateRecoveryScoreAfterSession(_ sessionType: SessionRotationManager.SessionType) {
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
}

enum TrainingPermission {
    case approved(reason: String)
    case cautioned(reason: String, suggestedActivity: RestActivity)
    case denied(reason: String, suggestedActivity: RestActivity)
}
```

### **2. Active Rest Activity System** 🚶‍♂️

```swift
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

class ActiveRestManager {
    let activeRestActivities = [
        // Light Movement Activities
        ActiveRestActivity(
            name: "Recovery Walk",
            duration: 1200, // 20 minutes
            intensity: .light,
            benefits: [.bloodFlow, .mentalRecovery],
            instructions: "Gentle 20-minute walk at conversational pace",
            videoURL: "recovery-walk-guide"
        ),
        
        ActiveRestActivity(
            name: "Dynamic Stretching",
            duration: 900, // 15 minutes
            intensity: .veryLight,
            benefits: [.flexibility, .muscleRecovery],
            instructions: "Full-body dynamic stretching routine",
            videoURL: "dynamic-stretching-routine"
        ),
        
        ActiveRestActivity(
            name: "Foam Rolling Session",
            duration: 600, // 10 minutes
            intensity: .veryLight,
            benefits: [.muscleRecovery, .injuryPrevention],
            instructions: "Target legs, glutes, and back with foam roller",
            videoURL: "foam-rolling-guide"
        ),
        
        // Moderate Activities
        ActiveRestActivity(
            name: "Easy Bike Ride",
            duration: 1800, // 30 minutes
            intensity: .moderate,
            benefits: [.bloodFlow, .muscleRecovery],
            instructions: "Leisurely bike ride maintaining easy conversation",
            videoURL: "recovery-cycling"
        ),
        
        ActiveRestActivity(
            name: "Swimming (Easy)",
            duration: 1200, // 20 minutes
            intensity: .light,
            benefits: [.muscleRecovery, .bloodFlow, .flexibility],
            instructions: "Easy swimming focusing on smooth, relaxed strokes",
            videoURL: "recovery-swimming"
        ),
        
        ActiveRestActivity(
            name: "Yoga Flow",
            duration: 1800, // 30 minutes
            intensity: .light,
            benefits: [.flexibility, .mentalRecovery, .muscleRecovery],
            instructions: "Gentle yoga flow focusing on hip flexors and hamstrings",
            videoURL: "recovery-yoga"
        )
    ]
    
    func recommendActiveRest(for frequency: TrainingFrequency, 
                           recoveryScore: Double) -> [ActiveRestActivity] {
        switch frequency {
        case .casual:
            return [activeRestActivities[0], activeRestActivities[1]] // Walk + stretch
        case .regular:
            return Array(activeRestActivities[0...2]) // Walk, stretch, foam roll
        case .serious:
            return activeRestActivities // All options available
        }
    }
}
```

### **3. Recovery Monitoring System** 📊

```swift
class RecoveryMonitor: ObservableObject {
    @Published var sleepQuality: SleepQuality = .good
    @Published var muscleStiffness: StiffnessLevel = .none
    @Published var energyLevel: EnergyLevel = .high
    @Published var heartRateVariability: Double = 50.0
    @Published var restingHeartRate: Double = 60.0
    
    enum SleepQuality: Int, CaseIterable {
        case poor = 1, fair = 2, good = 3, excellent = 4
    }
    
    enum StiffnessLevel: Int, CaseIterable {
        case none = 0, mild = 1, moderate = 2, severe = 3
    }
    
    enum EnergyLevel: Int, CaseIterable {
        case low = 1, moderate = 2, high = 3, excellent = 4
    }
    
    // Calculate overall recovery score
    func calculateRecoveryScore() -> Double {
        let sleepScore = Double(sleepQuality.rawValue) / 4.0
        let stiffnessScore = 1.0 - (Double(muscleStiffness.rawValue) / 3.0)
        let energyScore = Double(energyLevel.rawValue) / 4.0
        
        // Weight the factors
        let overallScore = (sleepScore * 0.4) + (stiffnessScore * 0.3) + (energyScore * 0.3)
        
        return max(0.0, min(1.0, overallScore))
    }
    
    // Generate recovery recommendations
    func getRecoveryRecommendations() -> [RecoveryRecommendation] {
        var recommendations: [RecoveryRecommendation] = []
        
        if sleepQuality.rawValue < 3 {
            recommendations.append(.improveSleep)
        }
        
        if muscleStiffness.rawValue > 1 {
            recommendations.append(.focusOnStretching)
        }
        
        if energyLevel.rawValue < 3 {
            recommendations.append(.lightActivityOnly)
        }
        
        return recommendations
    }
}

enum RecoveryRecommendation {
    case improveSleep
    case focusOnStretching
    case lightActivityOnly
    case considerMassage
    case increaseHydration
    case reduceTrainingLoad
    
    var description: String {
        switch self {
        case .improveSleep:
            return "Focus on getting 7-9 hours of quality sleep"
        case .focusOnStretching:
            return "Add extra stretching and mobility work"
        case .lightActivityOnly:
            return "Stick to light active recovery today"
        case .considerMassage:
            return "Consider massage or self-massage techniques"
        case .increaseHydration:
            return "Increase water intake for better recovery"
        case .reduceTrainingLoad:
            return "Consider reducing training intensity"
        }
    }
}
```

### **4. Rest Day Scheduling & Notifications** 📅

```swift
class RestDayScheduler: ObservableObject {
    @Published var weeklySchedule: [DayOfWeek: WorkoutType] = [:]
    @Published var mandatoryRestDays: Set<DayOfWeek> = []
    @Published var activeRestDays: Set<DayOfWeek> = []
    
    enum WorkoutType {
        case sprintTraining
        case activeRest(ActiveRestActivity)
        case completeRest
        case flexible // User can choose
    }
    
    enum DayOfWeek: Int, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
    
    func generateOptimalSchedule(frequency: TrainingFrequency) -> [DayOfWeek: WorkoutType] {
        var schedule: [DayOfWeek: WorkoutType] = [:]
        
        switch frequency {
        case .casual(let days):
            // 2-3 sprint days with mandatory rest between
            if days == 2 {
                schedule = [
                    .monday: .sprintTraining,
                    .tuesday: .activeRest(ActiveRestManager().activeRestActivities[0]),
                    .wednesday: .completeRest,
                    .thursday: .sprintTraining,
                    .friday: .activeRest(ActiveRestManager().activeRestActivities[1]),
                    .saturday: .completeRest,
                    .sunday: .flexible
                ]
            }
            
        case .regular(let days):
            // 4-5 days with strategic rest placement
            schedule = [
                .monday: .sprintTraining,
                .tuesday: .activeRest(ActiveRestManager().activeRestActivities[2]),
                .wednesday: .sprintTraining,
                .thursday: .activeRest(ActiveRestManager().activeRestActivities[0]),
                .friday: .sprintTraining,
                .saturday: .activeRest(ActiveRestManager().activeRestActivities[5]),
                .sunday: .completeRest
            ]
            
        case .serious(let days):
            // 5-7 days with mandatory complete rest
            schedule = [
                .monday: .sprintTraining,
                .tuesday: .activeRest(ActiveRestManager().activeRestActivities[3]),
                .wednesday: .sprintTraining,
                .thursday: .activeRest(ActiveRestManager().activeRestActivities[1]),
                .friday: .sprintTraining,
                .saturday: .activeRest(ActiveRestManager().activeRestActivities[4]),
                .sunday: .completeRest // Mandatory complete rest
            ]
        }
        
        return schedule
    }
    
    func scheduleRestReminders() {
        // Schedule notifications for rest days
        let notificationManager = RestNotificationManager()
        
        for (day, workoutType) in weeklySchedule {
            switch workoutType {
            case .completeRest:
                notificationManager.scheduleCompleteRestReminder(for: day)
            case .activeRest(let activity):
                notificationManager.scheduleActiveRestReminder(for: day, activity: activity)
            default:
                break
            }
        }
    }
}
```

### **5. Rest Day UI & User Experience** 📱

```swift
struct RestDayView: View {
    @StateObject private var restManager = RestRecoveryManager()
    @StateObject private var recoveryMonitor = RecoveryMonitor()
    @State private var selectedActivity: ActiveRestActivity?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Recovery Status Card
                    RecoveryStatusCard(
                        recoveryScore: recoveryMonitor.calculateRecoveryScore(),
                        recommendations: recoveryMonitor.getRecoveryRecommendations()
                    )
                    
                    // Training Permission Status
                    TrainingPermissionCard(
                        permission: restManager.canTrainToday()
                    )
                    
                    // Active Rest Activities
                    if case .denied(_, let suggestedActivity) = restManager.canTrainToday() {
                        ActiveRestActivityCard(activity: suggestedActivity)
                    }
                    
                    // Recovery Tracking
                    RecoveryTrackingSection(monitor: recoveryMonitor)
                    
                    // Weekly Schedule Preview
                    WeeklySchedulePreview()
                }
                .padding()
            }
            .navigationTitle("Recovery & Rest")
        }
    }
}

struct RecoveryStatusCard: View {
    let recoveryScore: Double
    let recommendations: [RecoveryRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recoveryIcon)
                    .foregroundColor(recoveryColor)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Recovery Status")
                        .font(.headline)
                    Text(recoveryDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(progress: recoveryScore)
            }
            
            if !recommendations.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.blue)
                            Text(recommendation.description)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recoveryIcon: String {
        if recoveryScore > 0.8 { return "heart.fill" }
        else if recoveryScore > 0.6 { return "heart" }
        else { return "heart.slash" }
    }
    
    private var recoveryColor: Color {
        if recoveryScore > 0.8 { return .green }
        else if recoveryScore > 0.6 { return .orange }
        else { return .red }
    }
    
    private var recoveryDescription: String {
        if recoveryScore > 0.8 { return "Fully Recovered" }
        else if recoveryScore > 0.6 { return "Moderate Recovery" }
        else { return "Needs More Rest" }
    }
}
```

### **6. Smart Rest Notifications** 🔔

```swift
class RestNotificationManager {
    func scheduleRestReminders() {
        // Day before sprint training
        scheduleNotification(
            title: "Rest Day Tomorrow",
            body: "Get quality sleep tonight for tomorrow's sprint session",
            timeInterval: 24 * 60 * 60 // 24 hours before
        )
        
        // Active rest reminders
        scheduleNotification(
            title: "Active Recovery Time",
            body: "Try a 20-minute recovery walk to boost circulation",
            timeInterval: 2 * 60 * 60 // 2 hours after workout
        )
        
        // Overtraining prevention
        scheduleNotification(
            title: "Rest Day Recommended",
            body: "You've trained 3 days in a row. Consider active recovery today",
            trigger: .overtrainingRisk
        )
    }
    
    func scheduleRecoveryCheckIn() {
        // Morning recovery assessment
        scheduleNotification(
            title: "How are you feeling?",
            body: "Quick recovery check-in to optimize today's training",
            timeInterval: .morningCheckIn
        )
    }
}
```

---

## 🎯 **Implementation Priority**

### **Phase 1: Core Rest System (Week 1-2)**
- [ ] **Rest Permission Logic** - Can user train today?
- [ ] **Basic Active Rest Activities** - 3-4 core activities
- [ ] **Recovery Score Calculation** - Simple sleep/energy tracking
- [ ] **Rest Day Notifications** - Basic reminder system

### **Phase 2: Enhanced Monitoring (Week 3-4)**
- [ ] **Advanced Recovery Tracking** - HRV, sleep quality, stiffness
- [ ] **Personalized Rest Recommendations** - AI-driven suggestions
- [ ] **Weekly Schedule Optimization** - Automatic rest day placement
- [ ] **Active Rest Video Guides** - In-app instruction videos

### **Phase 3: Smart Integration (Week 5-6)**
- [ ] **Health App Integration** - Sleep and HRV data
- [ ] **Overtraining Prevention** - Advanced warning system
- [ ] **Social Rest Challenges** - Community rest day activities
- [ ] **Coach Integration** - Professional rest recommendations

---

## 💡 **Key Benefits**

### **For Users:**
- **Injury Prevention** - Mandatory rest between high-intensity sessions
- **Better Performance** - Optimized recovery leads to better training
- **Sustainable Training** - Long-term adherence through proper rest
- **Education** - Learn importance of recovery in athletic performance

### **For App Engagement:**
- **Daily Touchpoints** - Users engage even on rest days
- **Habit Formation** - Rest becomes part of training routine
- **Premium Value** - Advanced recovery features justify subscription
- **Retention** - Prevents burnout and app abandonment

This comprehensive rest and recovery system ensures users train sustainably while maintaining engagement with your app every day of the week! 🏃‍♂️💪
