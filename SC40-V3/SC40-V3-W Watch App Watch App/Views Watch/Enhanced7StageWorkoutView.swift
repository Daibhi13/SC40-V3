import SwiftUI
import WatchKit
import AVFoundation

// MARK: - Enhanced 7-Stage Workout View for Apple Watch
struct Enhanced7StageWorkoutView: View {
    @StateObject private var workoutVM: WorkoutWatchViewModel
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var phaseTimeRemaining: Int = 300 // 5 minutes for warmup
    @State private var phaseTimer: Timer?
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showCompletionView = false
    
    let session: TrainingSession
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "warmup"
        case stretch = "stretch"
        case drill = "drill"
        case strides = "strides"
        case sprints = "sprints"
        case resting = "resting"
        case cooldown = "cooldown"
        case completed = "completed"
        
        var title: String {
            switch self {
            case .warmup: return "Warm-Up"
            case .stretch: return "Stretch"
            case .drill: return "Drills"
            case .strides: return "Strides"
            case .sprints: return "Sprints"
            case .resting: return "Rest"
            case .cooldown: return "Cooldown"
            case .completed: return "Complete"
            }
        }
        
        var color: Color {
            switch self {
            case .warmup: return .orange
            case .stretch: return .pink
            case .drill: return .indigo
            case .strides: return .purple
            case .sprints: return .green
            case .resting: return .yellow
            case .cooldown: return .blue
            case .completed: return .cyan
            }
        }
        
        var icon: String {
            switch self {
            case .warmup: return "figure.walk"
            case .stretch: return "figure.flexibility"
            case .drill: return "figure.run.circle"
            case .strides: return "figure.run"
            case .sprints: return "bolt.fill"
            case .resting: return "pause.fill"
            case .cooldown: return "figure.cooldown"
            case .completed: return "checkmark.circle.fill"
            }
        }
        
        var duration: Int {
            switch self {
            case .warmup: return 300 // 5 minutes
            case .stretch: return 300 // 5 minutes
            case .drill: return 360 // 6 minutes
            case .strides: return 360 // 6 minutes
            case .sprints: return 0 // Dynamic
            case .resting: return 0 // Dynamic
            case .cooldown: return 300 // 5 minutes
            case .completed: return 0
            }
        }
        
        var instructions: String {
            switch self {
            case .warmup:
                return "Light jog to prepare your body. Keep it easy and relaxed."
            case .stretch:
                return "Dynamic stretches: leg swings, high knees, butt kicks."
            case .drill:
                return "Technical drills for form. A-skips, high knees, butt kicks."
            case .strides:
                return "Progressive acceleration runs. Build to 70% effort."
            case .sprints:
                return "Maximum effort! Give everything you have."
            case .resting:
                return "Active recovery. Walk and prepare for next sprint."
            case .cooldown:
                return "Light walking and static stretching."
            case .completed:
                return "Excellent work! Session complete."
            }
        }
    }
    
    init(session: TrainingSession) {
        self.session = session
        self._workoutVM = StateObject(wrappedValue: WorkoutWatchViewModel())
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching iPhone app
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
            
            if showCompletionView {
                WorkoutCompletionView(session: session)
            } else {
                ScrollView {
                    VStack(spacing: WatchAdaptiveSizing.spacing) {
                        // Phase Progress Indicator
                        PhaseProgressView(currentPhase: currentPhase)
                        
                        // Current Phase Display
                        CurrentPhaseDisplayView(
                            phase: currentPhase,
                            timeRemaining: phaseTimeRemaining,
                            isRunning: isRunning
                        )
                        
                        // Phase Instructions
                        PhaseInstructionsView(phase: currentPhase)
                        
                        // Control Buttons
                        WorkoutControlsView(
                            isRunning: isRunning,
                            isPaused: isPaused,
                            onStartPause: toggleWorkout,
                            onNext: advanceToNextPhase,
                            onComplete: completeWorkout
                        )
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            setupWorkout()
        }
        .onDisappear {
            cleanupWorkout()
        }
    }
    
    // MARK: - Workout Control Methods
    
    private func setupWorkout() {
        phaseTimeRemaining = currentPhase.duration
        // Setup workout session - implement workout initialization here
        print("🏃‍♂️ Setting up 7-stage workout for: \(session.type)")
    }
    
    private func toggleWorkout() {
        if isRunning {
            pauseWorkout()
        } else {
            startWorkout()
        }
    }
    
    private func startWorkout() {
        isRunning = true
        isPaused = false
        startPhaseTimer()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
        
        // Voice coaching
        speakPhaseStart()
    }
    
    private func pauseWorkout() {
        isRunning = false
        isPaused = true
        phaseTimer?.invalidate()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }
    
    private func advanceToNextPhase() {
        phaseTimer?.invalidate()
        
        let nextPhase = getNextPhase()
        currentPhase = nextPhase
        phaseTimeRemaining = nextPhase.duration
        
        if nextPhase == .completed {
            completeWorkout()
        } else {
            if isRunning {
                startPhaseTimer()
            }
            speakPhaseTransition()
        }
        
        // Haptic feedback for phase change
        WKInterfaceDevice.current().play(.notification)
    }
    
    private func getNextPhase() -> WorkoutPhase {
        switch currentPhase {
        case .warmup: return .stretch
        case .stretch: return .drill
        case .drill: return .strides
        case .strides: return .sprints
        case .sprints: return .resting
        case .resting: return .cooldown
        case .cooldown: return .completed
        case .completed: return .completed
        }
    }
    
    private func completeWorkout() {
        phaseTimer?.invalidate()
        isRunning = false
        currentPhase = .completed
        showCompletionView = true
        
        // Completion haptic
        WKInterfaceDevice.current().play(.success)
        
        // Save workout results
        print("🏆 Workout completed successfully!")
    }
    
    private func startPhaseTimer() {
        phaseTimer?.invalidate()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if phaseTimeRemaining > 0 {
                phaseTimeRemaining -= 1
            } else {
                // Auto-advance to next phase when timer reaches 0
                advanceToNextPhase()
            }
        }
    }
    
    private func cleanupWorkout() {
        phaseTimer?.invalidate()
    }
    
    // MARK: - Voice Coaching
    
    private func speakPhaseStart() {
        let message = "Starting \(currentPhase.title). \(currentPhase.instructions)"
        speak(message)
    }
    
    private func speakPhaseTransition() {
        let message = "Moving to \(currentPhase.title). \(currentPhase.instructions)"
        speak(message)
    }
    
    private func speak(_ text: String) {
        // Use AVSpeechSynthesizer for voice coaching
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 0.8
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}

// MARK: - Phase Progress View
struct PhaseProgressView: View {
    let currentPhase: Enhanced7StageWorkoutView.WorkoutPhase
    
    private let allPhases: [Enhanced7StageWorkoutView.WorkoutPhase] = [
        .warmup, .stretch, .drill, .strides, .sprints, .resting, .cooldown
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            // Phase indicators
            HStack(spacing: 2) {
                ForEach(Array(allPhases.enumerated()), id: \.offset) { index, phase in
                    Circle()
                        .fill(getPhaseColor(phase: phase))
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase == currentPhase ? 1.3 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPhase)
                }
            }
            
            // Current phase label
            Text("\(getCurrentPhaseIndex() + 1) of 7")
                .font(.adaptiveCaption)
                .foregroundColor(.secondary)
        }
    }
    
    private func getPhaseColor(phase: Enhanced7StageWorkoutView.WorkoutPhase) -> Color {
        let currentIndex = getCurrentPhaseIndex()
        let phaseIndex = getPhaseIndex(phase)
        
        if phaseIndex < currentIndex {
            return .green // Completed
        } else if phaseIndex == currentIndex {
            return phase.color // Current
        } else {
            return .gray.opacity(0.3) // Upcoming
        }
    }
    
    private func getCurrentPhaseIndex() -> Int {
        return allPhases.firstIndex(of: currentPhase) ?? 0
    }
    
    private func getPhaseIndex(_ phase: Enhanced7StageWorkoutView.WorkoutPhase) -> Int {
        return allPhases.firstIndex(of: phase) ?? 0
    }
}

// MARK: - Current Phase Display
struct CurrentPhaseDisplayView: View {
    let phase: Enhanced7StageWorkoutView.WorkoutPhase
    let timeRemaining: Int
    let isRunning: Bool
    
    var body: some View {
        VStack(spacing: WatchAdaptiveSizing.spacing) {
            // Phase icon and title
            VStack(spacing: 8) {
                Image(systemName: phase.icon)
                    .font(.title)
                    .foregroundColor(phase.color)
                    .scaleEffect(isRunning ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRunning)
                
                Text(phase.title.uppercased())
                    .font(.headline)
                    .foregroundColor(.white)
                    .tracking(1)
            }
            
            // Timer display
            if timeRemaining > 0 {
                Text(formatTime(timeRemaining))
                    .font(.largeTitle)
                    .foregroundColor(phase.color)
                    .monospacedDigit()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(phase.color.opacity(0.5), lineWidth: 2)
                )
        )
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Phase Instructions View
struct PhaseInstructionsView: View {
    let phase: Enhanced7StageWorkoutView.WorkoutPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.body)
                    .foregroundColor(.yellow)
                
                Text("INSTRUCTIONS")
                    .font(.caption)
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
            }
            
            Text(phase.instructions)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Workout Controls View
struct WorkoutControlsView: View {
    let isRunning: Bool
    let isPaused: Bool
    let onStartPause: () -> Void
    let onNext: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Primary control button
            Button(action: onStartPause) {
                HStack {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.body)
                    Text(isRunning ? "Pause" : (isPaused ? "Resume" : "Start"))
                        .font(.body)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(8)
            }
            
            // Secondary controls
            HStack(spacing: 8) {
                Button("Next Phase", action: onNext)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
                
                Button("Complete", action: onComplete)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Workout Completion View
struct WorkoutCompletionView: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(spacing: WatchAdaptiveSizing.spacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text("Workout Complete!")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Great job on your \(session.type) session!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Done") {
                // Dismiss workout view
                WKInterfaceController.reloadRootPageControllers(
                    withNames: ["DaySessionCardsWatchView"],
                    contexts: [[:]], 
                    orientation: .horizontal,
                    pageIndex: 0
                )
            }
            .font(.body)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    Enhanced7StageWorkoutView(
        session: TrainingSession(
            week: 1,
            day: 1,
            type: "Sprint Training",
            focus: "Acceleration",
            sprints: [
                SprintSet(distanceYards: 40, reps: 4, intensity: "Max")
            ],
            accessoryWork: []
        )
    )
}
