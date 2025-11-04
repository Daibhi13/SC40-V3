import SwiftUI

// MARK: - Enhanced Workout Phase Indicator with Dynamic Exercise Guidance
struct WorkoutPhaseIndicator: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let phaseProgress: Double // 0.0 to 1.0
    let timeRemaining: Int // seconds
    
    var body: some View {
        VStack(spacing: 16) {
            // Phase Timeline with Color Coding
            PhaseTimelineView(currentPhase: currentPhase)
            
            // Current Phase Card with Dynamic Indicators
            CurrentPhaseCard(
                phase: currentPhase,
                progress: phaseProgress,
                timeRemaining: timeRemaining
            )
            
            // Exercise Execution Guidance
            ExerciseGuidanceView(phase: currentPhase)
        }
    }
}

// MARK: - Phase Timeline with 7-Stage Color Coding
struct PhaseTimelineView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    
    private let allPhases: [MainProgramWorkoutView.WorkoutPhase] = [
        .warmup, .stretch, .drill, .strides, .sprints, .resting, .cooldown
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Phase Labels
            HStack {
                ForEach(Array(allPhases.enumerated()), id: \.offset) { index, phase in
                    Text(phase.title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(getPhaseColor(phase: phase))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Progress Bar with Color Coding
            HStack(spacing: 2) {
                ForEach(Array(allPhases.enumerated()), id: \.offset) { index, phase in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(getPhaseColor(phase: phase))
                        .frame(height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                        .scaleEffect(phase == currentPhase ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPhase)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func getPhaseColor(phase: MainProgramWorkoutView.WorkoutPhase) -> Color {
        let currentIndex = getPhaseIndex(currentPhase)
        let phaseIndex = getPhaseIndex(phase)
        
        if phaseIndex < currentIndex {
            return .green // Completed
        } else if phaseIndex == currentIndex {
            return phase.color // Current phase color
        } else {
            return .white.opacity(0.3) // Upcoming
        }
    }
    
    private func getPhaseIndex(_ phase: MainProgramWorkoutView.WorkoutPhase) -> Int {
        switch phase {
        case .warmup: return 0
        case .stretch: return 1
        case .drill: return 2
        case .strides: return 3
        case .sprints: return 4
        case .resting: return 5
        case .cooldown: return 6
        case .completed: return 7
        }
    }
}

// MARK: - Current Phase Card with Dynamic Progress
struct CurrentPhaseCard: View {
    let phase: MainProgramWorkoutView.WorkoutPhase
    let progress: Double
    let timeRemaining: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Phase Header with Icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(phase.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: phase.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(phase.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.title.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text(phase.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Time Remaining
                if timeRemaining > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(formatTime(timeRemaining))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(phase.color)
                        
                        Text("remaining")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            // Progress Bar
            if progress > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(phase.color)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(phase.color.opacity(0.5), lineWidth: 2)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Exercise Execution Guidance
struct ExerciseGuidanceView: View {
    let phase: MainProgramWorkoutView.WorkoutPhase
    
    var body: some View {
        VStack(spacing: 12) {
            // Dynamic Exercise Instructions
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("EXERCISE GUIDANCE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Spacer()
                }
                
                Text(getExerciseInstructions())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
            }
            
            // Visual Exercise Indicators
            ExerciseVisualizationView(phase: phase)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
    }
    
    private func getExerciseInstructions() -> String {
        switch phase {
        case .warmup:
            return "Start with a light 5-minute jog. Keep your pace conversational and focus on gradually warming up your muscles."
        case .stretch:
            return "Perform dynamic stretches: leg swings (10 each), high knees (20), butt kicks (20), and walking lunges (10 each leg)."
        case .drill:
            return "Execute technical drills with GPS tracking: A-skips, high knees, and butt kicks for 20 yards each. Focus on form over speed."
        case .strides:
            return "Run 3 progressive strides of 20 yards each. Start at 50% effort and build to 70%. Walk back for recovery between each."
        case .sprints:
            return "Maximum effort sprints! Drive hard from the start, maintain form, and give everything you have for the full distance."
        case .resting:
            return "Active recovery: walk slowly, take deep breaths, and prepare mentally for the next sprint. Stay loose and hydrated."
        case .cooldown:
            return "Cool down with light walking and static stretching. Hold each stretch for 30 seconds to help your muscles recover."
        case .completed:
            return "Excellent work! You've completed your sprint training session. Great job pushing your limits today!"
        }
    }
}

// MARK: - Exercise Visualization
struct ExerciseVisualizationView: View {
    let phase: MainProgramWorkoutView.WorkoutPhase
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(getExerciseSteps(), id: \.self) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(phase.color.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Text(step)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func getExerciseSteps() -> [String] {
        switch phase {
        case .warmup:
            return ["Start", "Jog", "Warm", "Ready"]
        case .stretch:
            return ["Legs", "Hips", "Ankles", "Core"]
        case .drill:
            return ["A-Skip", "High Knees", "Butt Kicks", "Form"]
        case .strides:
            return ["50%", "60%", "70%", "Build"]
        case .sprints:
            return ["Drive", "Maintain", "Finish", "Max"]
        case .resting:
            return ["Walk", "Breathe", "Relax", "Prepare"]
        case .cooldown:
            return ["Walk", "Stretch", "Hold", "Recover"]
        case .completed:
            return ["Done", "Great", "Job", "🏆"]
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.2, blue: 0.35),
                Color(red: 0.2, green: 0.25, blue: 0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        WorkoutPhaseIndicator(
            currentPhase: .sprints,
            phaseProgress: 0.6,
            timeRemaining: 45
        )
    }
}
