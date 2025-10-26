import SwiftUI

struct RestDayView: View {
    @StateObject private var trainingManager = IntegratedTrainingManager.shared
    @State private var selectedActivity: ActiveRestActivity?
    @State private var showingActivityDetail = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Training Status
                    TodaysTrainingStatusCard(decision: trainingManager.todaysTrainingDecision)
                    
                    // Active Rest Activities (if applicable)
                    if let restActivity = trainingManager.getTodaysRestRecommendation() {
                        ActiveRestSection(restActivity: restActivity)
                    }
                    
                    // Weekly Plan Overview
                    if let weeklyPlan = trainingManager.weeklyPlan {
                        WeeklyPlanSection(plan: weeklyPlan)
                    }
                    
                    // Recovery Tips
                    RecoveryTipsSection()
                }
                .padding()
            }
            .navigationTitle("Recovery & Rest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TodaysTrainingStatusCard: View {
    let decision: TrainingDecision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: decision.icon)
                    .foregroundColor(decision.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(decisionSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(decisionDescription)
                .font(.body)
                .foregroundColor(.primary)
            
            // Action buttons based on decision type
            decisionActionButtons
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var decisionSubtitle: String {
        switch decision {
        case .loading:
            return "Checking your training status..."
        case .mandatoryRest:
            return "Complete rest required today"
        case .activeRestRecommended:
            return "Light activity recommended"
        case .lightTrainingOnly:
            return "Low intensity training only"
        case .trainingApproved:
            return "Full training approved"
        }
    }
    
    private var decisionDescription: String {
        switch decision {
        case .loading:
            return "Analyzing your recent training and recovery status..."
        case .mandatoryRest(let reason, _):
            return reason
        case .activeRestRecommended(let reason, _):
            return reason
        case .lightTrainingOnly(let reason, _, _):
            return reason
        case .trainingApproved(let reason, _, _):
            return reason
        }
    }
    
    @ViewBuilder
    private var decisionActionButtons: some View {
        switch decision {
        case .trainingApproved(_, let session, _):
            if let recommendedSession = session {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Session")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(recommendedSession.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Button("Start Workout") {
                        // Navigate to workout
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
        case .lightTrainingOnly(_, let sessions, _):
            if let lightSession = sessions.first {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Light Training Option")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(lightSession.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Button("Light Workout") {
                        // Navigate to light workout
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
        default:
            EmptyView()
        }
    }
}

struct ActiveRestSection: View {
    let restActivity: RestActivity
    @State private var isPerformingActivity = false
    @State private var activityTimer: Timer?
    @State private var timeRemaining: TimeInterval = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Active Recovery")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let activity = restActivity.activity {
                ActiveRestActivityCard(
                    activity: activity,
                    isPerforming: $isPerformingActivity,
                    timeRemaining: $timeRemaining
                )
            } else {
                CompleteRestCard(restActivity: restActivity)
            }
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(16)
    }
}

struct ActiveRestActivityCard: View {
    let activity: ActiveRestActivity
    @Binding var isPerforming: Bool
    @Binding var timeRemaining: TimeInterval
    @State private var activityTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(Int(activity.duration / 60)) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                IntensityBadge(intensity: activity.intensity)
            }
            
            Text(activity.instructions)
                .font(.body)
                .foregroundColor(.primary)
            
            // Benefits
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(activity.benefits, id: \.self) { benefit in
                    BenefitTag(benefit: benefit)
                }
            }
            
            // Timer and controls
            if isPerforming {
                VStack(spacing: 12) {
                    HStack {
                        Text("Time Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(timeRemaining))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: 1.0 - (timeRemaining / activity.duration))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Button("Stop Activity") {
                        stopActivity()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button("Start Activity") {
                    startActivity()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func startActivity() {
        isPerforming = true
        timeRemaining = activity.duration
        
        activityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopActivity()
            }
        }
    }
    
    private func stopActivity() {
        isPerforming = false
        activityTimer?.invalidate()
        activityTimer = nil
        
        if timeRemaining <= 0 {
            // Activity completed - could trigger achievement or feedback
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct CompleteRestCard: View {
    let restActivity: RestActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("Complete Rest")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text(restActivity.description)
                .font(.body)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus on:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    RestFocusItem(icon: "moon.fill", text: "Quality sleep (7-9 hours)")
                    RestFocusItem(icon: "drop.fill", text: "Hydration (8+ glasses water)")
                    RestFocusItem(icon: "leaf.fill", text: "Gentle stretching")
                    RestFocusItem(icon: "heart.fill", text: "Stress management")
                }
            }
        }
    }
}

struct RestFocusItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct IntensityBadge: View {
    let intensity: ActiveRestActivity.RestIntensity
    
    var body: some View {
        Text(intensityText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(intensityColor.opacity(0.2))
            .foregroundColor(intensityColor)
            .cornerRadius(8)
    }
    
    private var intensityText: String {
        switch intensity {
        case .veryLight: return "Very Light"
        case .light: return "Light"
        case .moderate: return "Moderate"
        }
    }
    
    private var intensityColor: Color {
        switch intensity {
        case .veryLight: return .green
        case .light: return .blue
        case .moderate: return .orange
        }
    }
}

struct BenefitTag: View {
    let benefit: ActiveRestActivity.RecoveryBenefit
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: benefitIcon)
                .font(.caption2)
            
            Text(benefitText)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    private var benefitIcon: String {
        switch benefit {
        case .muscleRecovery: return "figure.strengthtraining.traditional"
        case .flexibility: return "figure.flexibility"
        case .bloodFlow: return "heart.circle"
        case .mentalRecovery: return "brain.head.profile"
        case .injuryPrevention: return "shield.fill"
        }
    }
    
    private var benefitText: String {
        switch benefit {
        case .muscleRecovery: return "Muscle Recovery"
        case .flexibility: return "Flexibility"
        case .bloodFlow: return "Blood Flow"
        case .mentalRecovery: return "Mental Recovery"
        case .injuryPrevention: return "Injury Prevention"
        }
    }
}

struct WeeklyPlanSection: View {
    let plan: WeeklyTrainingPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Weekly Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    if let dayPlan = plan.getDayPlan(for: day) {
                        WeeklyPlanDayCard(day: day, plan: dayPlan)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(16)
    }
}

struct WeeklyPlanDayCard: View {
    let day: DayOfWeek
    let plan: DayPlan
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day.shortName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Circle()
                .fill(planColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: planIcon)
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            Text(planTypeText)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
    
    private var planColor: Color {
        if plan.isRestDay {
            return .gray
        }
        
        switch plan.planType {
        case .training(.acceleration): return .red
        case .training(.drivePhase): return .orange
        case .training(.maxVelocity): return .purple
        case .training(.speedEndurance): return .blue
        case .training(.activeRecovery): return .green
        case .training(.benchmark): return .black
        case .training(.tempo): return .cyan
        case .activeRest: return .mint
        case .completeRest: return .gray
        }
    }
    
    private var planIcon: String {
        if plan.isRestDay {
            return "bed.double.fill"
        }
        
        switch plan.planType {
        case .training: return "bolt.fill"
        case .activeRest: return "figure.walk"
        case .completeRest: return "bed.double.fill"
        }
    }
    
    private var planTypeText: String {
        if plan.isRestDay {
            return "Rest"
        }
        
        switch plan.planType {
        case .training(let sessionType): return sessionType.rawValue
        case .activeRest: return "Active Rest"
        case .completeRest: return "Rest"
        }
    }
}

struct RecoveryTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Recovery Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                RecoveryTip(
                    icon: "moon.fill",
                    title: "Prioritize Sleep",
                    description: "Aim for 7-9 hours of quality sleep for optimal recovery"
                )
                
                RecoveryTip(
                    icon: "drop.fill",
                    title: "Stay Hydrated",
                    description: "Drink water throughout the day, especially after training"
                )
                
                RecoveryTip(
                    icon: "leaf.fill",
                    title: "Active Recovery",
                    description: "Light movement promotes blood flow and reduces stiffness"
                )
                
                RecoveryTip(
                    icon: "heart.fill",
                    title: "Listen to Your Body",
                    description: "Rest when you feel overly fatigued or sore"
                )
            }
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(16)
    }
}

struct RecoveryTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    RestDayView()
}
