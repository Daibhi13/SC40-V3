import SwiftUI

// MARK: - Pro Workout Session Model for Partial Session Tracking
struct ProWorkoutSession {
    let id: UUID
    let sessionId: String
    let startTime: Date
    let endTime: Date?
    let phase: SprintTimerProWorkoutView.WorkoutPhase
    let completedReps: Int
    let totalReps: Int
    let distance: Int
    let restMinutes: Int
    let isCompleted: Bool
    let sessionType: String
}

struct SprintTimerProWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let distance: Int
    let reps: Int
    let restMinutes: Int
    
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var currentRep = 1
    @State private var completedReps: [RepData] = []
    @State private var showCompletionSheet = false
    
    // C25K-style coaching
    @State private var coachingMessage: String = ""
    @State private var showCoachingMessage: Bool = false
    
    enum WorkoutPhase {
        case warmup, stretch, drill, strides, sprints, resting, cooldown, completed
    }
    
    // RepData model moved to Models/RepData.swift for shared use
    
    var body: some View {
        SwipeableWorkoutContainer(
            mainContent: {
                mainProWorkoutView
            },
            controlContent: {
                ProControlWorkoutView(
                    isRunning: $isRunning,
                    isPaused: $isPaused,
                    currentPhase: $currentPhase,
                    currentRep: $currentRep,
                    totalReps: Binding.constant(reps),
                    distance: Binding.constant(distance),
                    restMinutes: Binding.constant(restMinutes),
                    onPlayPause: togglePausePlay,
                    onStop: {
                        presentationMode.wrappedValue.dismiss()
                    },
                    onPrevious: {
                        goToPreviousProPhase()
                    },
                    onNext: {
                        advanceToNextProPhase()
                    },
                    onVolumeToggle: {
                        toggleProVoiceCoaching()
                    }
                )
            },
            musicContent: {
                MusicWorkoutView()
            },
            repLogContent: {
                RepLogLiveView(
                    completedReps: $completedReps,
                    currentRep: $currentRep,
                    totalReps: Binding.constant(reps),
                    currentPhase: Binding.constant(convertToMainWorkoutPhase(currentPhase))
                )
            }
        )
    }
    
    private var mainProWorkoutView: some View {
        ZStack {
            // Same gradient background as MainProgramWorkoutView
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.3, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - Same as MainProgramWorkoutView
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Sprint Timer Pro")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // Settings or info
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Scrollable Content - Same structure as MainProgramWorkoutView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Show different UI based on current phase
                        switch currentPhase {
                        case .warmup, .stretch, .drill:
                            // Initial phases - show session overview
                            ProSessionOverviewUI(
                                distance: distance,
                                reps: reps,
                                restMinutes: restMinutes,
                                isRunning: isRunning,
                                isPaused: isPaused,
                                onStartWorkout: startWorkout,
                                onTogglePausePlay: togglePausePlay,
                                onFastForward: fastForward
                            )
                        case .strides:
                            // Strides phase - show timer and strides info
                            ProStridesPhaseUI()
                        case .sprints:
                            // Sprints phase - show timer and sprint info
                            ProSprintsPhaseUI()
                        case .resting, .cooldown, .completed:
                            // Final phases - show completion
                            ProCompletionPhaseUI(
                                distance: distance,
                                reps: reps,
                                restMinutes: restMinutes,
                                onStartWorkout: startWorkout
                            )
                        }
                        
                        // C25K-style Current Phase Indicator
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .fill(index == getCurrentDotIndex() ? Color.orange : Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(index == getCurrentDotIndex() ? 1.3 : 1.0)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPhase)
                                }
                            }
                            
                            // Current Phase Name
                            Text(getCurrentPhaseName())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                                .animation(.easeInOut(duration: 0.3), value: currentPhase)
                        }
                        .padding(.vertical, 16)
                        
                        // Adaptive Rep Log - Always visible at bottom
                        ProAdaptiveRepLogView(
                            currentPhase: currentPhase,
                            completedReps: completedReps,
                            currentRep: currentRep,
                            totalReps: reps,
                            distance: distance,
                            restMinutes: restMinutes
                        )
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .overlay(
            // C25K-style Coaching Message Overlay
            VStack {
                if showCoachingMessage {
                    VStack(spacing: 12) {
                        Text(coachingMessage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange, lineWidth: 2)
                                    )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 30)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                Spacer()
            }
            .padding(.top, 100)
        )
        .onAppear {
            setupCustomWorkout()
        }
        .sheet(isPresented: $showCompletionSheet) {
            ProWorkoutCompletionView(
                distance: distance,
                reps: reps,
                restMinutes: restMinutes,
                completedReps: completedReps,
                onDismiss: {
                    showCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func startWorkout() {
        isRunning = true
        isPaused = false
        
        // Log workout start for partial session tracking
        logProWorkoutStart()
        
        // Start C25K-style progression
        startProPhaseProgression()
    }
    
    private func togglePausePlay() {
        isPaused.toggle()
        
        if isPaused {
            // Pause the workout and log current progress
            pauseProWorkout()
        } else {
            // Resume the workout
            resumeProWorkout()
        }
    }
    
    private func fastForward() {
        // Skip to next phase immediately
        advanceToNextProPhase()
        
        // Log the fast forward action
        logProFastForwardAction()
    }
    
    private func pauseProWorkout() {
        // Log current progress as partial session
        logProPartialSession()
        
        // Show pause coaching message
        showCoachingCue("Pro workout paused. Tap play to continue! ⏸️")
    }
    
    private func resumeProWorkout() {
        // Show resume coaching message
        showCoachingCue("Back to Pro training! Let's keep pushing! ▶️")
    }
    
    private func advanceToNextProPhase() {
        // Manually advance to next phase
        switch currentPhase {
        case .warmup:
            showCoachingCue("Skipping to stretch phase! 🏃‍♂️")
            currentPhase = .stretch
        case .stretch:
            showCoachingCue("Moving to activation drills! 💪")
            currentPhase = .drill
        case .drill:
            showCoachingCue("Jumping to build-up strides! ⚡")
            currentPhase = .strides
        case .strides:
            showCoachingCue("Fast forwarding to your custom \(distance)yd sprints! 🚀")
            currentPhase = .sprints
        case .sprints:
            showCoachingCue("Moving to recovery phase! 💪")
            currentPhase = .resting
        case .resting:
            showCoachingCue("Skipping to cool down! 🌟")
            currentPhase = .cooldown
        case .cooldown:
            showCoachingCue("Pro workout complete! You crushed those \(distance)yd sprints! 🏆")
            currentPhase = .completed
        default:
            break
        }
    }
    
    private func logProWorkoutStart() {
        // Create initial session entry with start time
        let workoutSession = ProWorkoutSession(
            id: UUID(),
            sessionId: "Pro-\(distance)yd-\(reps)reps",
            startTime: Date(),
            endTime: nil,
            phase: currentPhase,
            completedReps: completedReps.count,
            totalReps: reps,
            distance: distance,
            restMinutes: restMinutes,
            isCompleted: false,
            sessionType: "Sprint Timer Pro"
        )
        
        // Save to HistoryManager for analytics
        saveProPartialSession(workoutSession)
    }
    
    private func logProPartialSession() {
        // Update session with current progress
        let workoutSession = ProWorkoutSession(
            id: UUID(),
            sessionId: "Pro-\(distance)yd-\(reps)reps",
            startTime: Date().addingTimeInterval(-300), // Approximate start time
            endTime: Date(),
            phase: currentPhase,
            completedReps: completedReps.count,
            totalReps: reps,
            distance: distance,
            restMinutes: restMinutes,
            isCompleted: false,
            sessionType: "Sprint Timer Pro (Partial)"
        )
        
        // Save partial progress to analytics
        saveProPartialSession(workoutSession)
    }
    
    private func logProFastForwardAction() {
        // Log user interaction for analytics
        print("Pro fast forward action logged - Phase: \(currentPhase), Distance: \(distance)yd")
    }
    
    private func saveProPartialSession(_ session: ProWorkoutSession) {
        // Save to HistoryManager and analytics
        // This ensures even partial Pro workouts appear in HistoryView and analytics
        // For now, just log the session (will integrate with actual HistoryManager)
        print("Saving Pro partial session: \(session.sessionId) - Phase: \(session.phase)")
    }
    
    private func setupCustomWorkout() {
        // Initialize completed reps array
        completedReps = Array(1...reps).map { rep in
            RepData(rep: rep, time: nil, isCompleted: false, repType: .sprint, distance: 40, timestamp: Date())
        }
    }
    
    private func startProPhaseProgression() {
        // C25K Fitness22-style seamless progression with coaching cues
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { timer in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.2)) {
                    switch self.currentPhase {
                    case .warmup:
                        self.showCoachingCue("Great warm-up! Time to stretch those muscles 💪")
                        self.currentPhase = .stretch
                    case .stretch:
                        self.showCoachingCue("Perfect! Let's move to activation drills 🔥")
                        self.currentPhase = .drill
                    case .drill:
                        self.showCoachingCue("Excellent form! Ready for build-up strides? ⚡")
                        self.currentPhase = .strides
                    case .strides:
                        self.showCoachingCue("You're flying! Time for your custom \(self.distance)yd sprints 🚀")
                        self.currentPhase = .sprints
                    case .sprints:
                        self.showCoachingCue("Incredible speed! Time for recovery 💪")
                        self.currentPhase = .resting
                    case .resting:
                        self.showCoachingCue("Perfect recovery! Time to cool down 🌟")
                        self.currentPhase = .cooldown
                    case .cooldown:
                        self.showCoachingCue("Custom workout complete! You crushed those \(self.distance)yd sprints! 🏆")
                        self.currentPhase = .completed
                        timer.invalidate()
                    default:
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    private func showCoachingCue(_ message: String) {
        coachingMessage = message
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCoachingMessage = true
        }
        
        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.showCoachingMessage = false
            }
        }
    }
    
    private func getCurrentDotIndex() -> Int {
        switch currentPhase {
        case .warmup, .stretch, .drill: return 0
        case .strides: return 1
        case .sprints, .resting, .cooldown, .completed: return 2
        }
    }
    
    private func getCurrentPhaseName() -> String {
        switch currentPhase {
        case .warmup: return "WARM-UP PHASE"
        case .stretch: return "STRETCH PHASE"
        case .drill: return "ACTIVATION DRILLS"
        case .strides: return "BUILD-UP STRIDES"
        case .sprints: return "CUSTOM SPRINTS"
        case .resting: return "RECOVERY PHASE"
        case .cooldown: return "COOL DOWN"
        case .completed: return "WORKOUT COMPLETE"
        }
    }
    
    private func goToPreviousProPhase() {
        switch currentPhase {
        case .stretch:
            currentPhase = .warmup
        case .drill:
            currentPhase = .stretch
        case .strides:
            currentPhase = .drill
        case .sprints:
            currentPhase = .strides
        case .resting:
            currentPhase = .sprints
        case .cooldown:
            currentPhase = .resting
        case .completed:
            currentPhase = .cooldown
        default:
            break
        }
        
        showCoachingCue("Moved to \(getCurrentPhaseName())")
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    
    private func toggleProVoiceCoaching() {
        isProVoiceCoachingEnabled.toggle()
        let message = isProVoiceCoachingEnabled ? "Voice coaching enabled 🔊" : "Voice coaching disabled 🔇"
        showCoachingCue(message)
    }
    
    @State private var isProVoiceCoachingEnabled = true
    
    private func convertToMainWorkoutPhase(_ phase: WorkoutPhase) -> MainProgramWorkoutView.WorkoutPhase {
        switch phase {
        case .warmup: return .warmup
        case .stretch: return .stretch
        case .drill: return .drill
        case .strides: return .strides
        case .sprints: return .sprints
        case .resting: return .resting
        case .cooldown: return .cooldown
        case .completed: return .completed
        }
    }
}

// MARK: - Pro Phase-Specific UI Components

struct ProSessionOverviewUI: View {
    let distance: Int
    let reps: Int
    let restMinutes: Int
    let isRunning: Bool
    let isPaused: Bool
    let onStartWorkout: () -> Void
    let onTogglePausePlay: () -> Void
    let onFastForward: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Session Header
            VStack(spacing: 8) {
                Text("SPRINT TIMER PRO")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
                
                Text("CUSTOM WORKOUT / \(estimatedDuration()) Min")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            
            // Phase Overview Cards
            HStack(spacing: 12) {
                ProPhaseCard(
                    duration: "5 Min",
                    title: "Warm",
                    subtitle: "Up",
                    isActive: true,
                    isCompleted: false
                )
                
                ProPhaseCard(
                    duration: "\(estimatedSprintDuration()) Min",
                    title: "\(distance)yd Sprint + Rest",
                    subtitle: "(\(reps) Reps)",
                    isActive: false,
                    isCompleted: false
                )
                
                ProPhaseCard(
                    duration: "5 Min",
                    title: "Cool",
                    subtitle: "Down",
                    isActive: false,
                    isCompleted: false
                )
            }
            .padding(.horizontal, 20)
            
            // C25K-style 7-Phase Progress Bar
            ProProgressBar(currentPhase: .warmup, totalPhases: 7)
                .padding(.horizontal, 20)
            
            // Pro Badge
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Text("PRO TIMER")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1)
            }
            .padding(.vertical, 30)
            
            // Dynamic Action Controls
            if !isRunning {
                // Initial LET'S GO Button
                Button(action: onStartWorkout) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 4) {
                            Text("LET'S\nGO")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.bottom, 20)
            } else {
                // Workout Controls (Pause/Play + Fast Forward)
                HStack(spacing: 24) {
                    // Pause/Play Button
                    Button(action: onTogglePausePlay) {
                        ZStack {
                            Circle()
                                .fill(isPaused ? Color.green : Color.orange)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Fast Forward Button
                    Button(action: onFastForward) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "forward.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func estimatedDuration() -> Int {
        return 10 + (reps * restMinutes) + 10 // Warm-up + sprints/rest + cool-down
    }
    
    private func estimatedSprintDuration() -> Int {
        return reps * restMinutes
    }
}

// Additional Pro UI components would continue here...
// (ProStridesPhaseUI, ProSprintsPhaseUI, etc. - similar to MainProgramWorkoutView)

struct ProPhaseCard: View {
    let duration: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(duration)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .orange : .white.opacity(0.6))
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.orange : Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ProProgressBar: View {
    let currentPhase: SprintTimerProWorkoutView.WorkoutPhase
    let totalPhases: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // C25K-style Phase Labels
            HStack {
                ForEach(0..<totalPhases, id: \.self) { index in
                    Text(getPhaseLabel(index: index))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(getPhaseColor(index: index))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Beautiful Progress Bar
            HStack(spacing: 2) {
                ForEach(0..<totalPhases, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(getPhaseColor(index: index))
                        .frame(height: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(index == getCurrentPhaseIndex() ? 1.1 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPhase)
                }
            }
        }
    }
    
    private func getPhaseLabel(index: Int) -> String {
        switch index {
        case 0: return "WARM"
        case 1: return "STRETCH"
        case 2: return "DRILLS"
        case 3: return "STRIDES"
        case 4: return "SPRINT"
        case 5: return "REST"
        case 6: return "COOL"
        default: return ""
        }
    }
    
    private func getPhaseColor(index: Int) -> Color {
        let currentIndex = getCurrentPhaseIndex()
        if index < currentIndex {
            return .green // Completed - C25K green
        } else if index == currentIndex {
            return .orange // Current - Sprint Coach orange
        } else {
            return .white.opacity(0.3) // Upcoming
        }
    }
    
    private func getCurrentPhaseIndex() -> Int {
        switch currentPhase {
        case .warmup: return 0
        case .stretch: return 1
        case .drill: return 2
        case .strides: return 3
        case .sprints: return 4
        case .resting: return 5
        case .cooldown: return 6
        default: return 0
        }
    }
    
    // MARK: - Pro Control View Helper Methods
    
    private func showCoachingCue(_ message: String) {
        print("🗣️ Coaching: \(message)")
    }
    
    // Duplicate functions removed - they are now properly inside the main struct
}

// Placeholder components for other phases
struct ProStridesPhaseUI: View {
    var body: some View {
        Text("Strides Phase UI")
            .foregroundColor(.white)
    }
}

struct ProSprintsPhaseUI: View {
    var body: some View {
        Text("Sprints Phase UI")
            .foregroundColor(.white)
    }
}


struct ProCompletionPhaseUI: View {
    let distance: Int
    let reps: Int
    let restMinutes: Int
    let onStartWorkout: () -> Void
    
    var body: some View {
        // Completion phase
        VStack {
            Text("Workout Complete!")
                .font(.title)
                .foregroundColor(.white)
            Text("Great job on your \(distance)yd sprints!")
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct ProAdaptiveRepLogView: View {
    let currentPhase: SprintTimerProWorkoutView.WorkoutPhase
    let completedReps: [RepData]
    let currentRep: Int
    let totalReps: Int
    let distance: Int
    let restMinutes: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Rep Log")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Live Workout Report")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("18:12")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            // Rep Log Content
            VStack(spacing: 12) {
                // Headers
                HStack {
                    Text("REP")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 40, alignment: .leading)
                    
                    Text("YDS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 50, alignment: .leading)
                    
                    Text("TIME")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 60, alignment: .leading)
                    
                    Text("REST")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                
                // Show custom sprint data
                ForEach(Array(completedReps.enumerated()), id: \.offset) { index, repData in
                    ProRepRow(
                        rep: repData.rep,
                        distance: distance,
                        time: repData.time,
                        restMinutes: restMinutes,
                        isActive: repData.rep == currentRep,
                        isCompleted: repData.isCompleted
                    )
                }
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding(.horizontal, 20)
    }
}

struct ProRepRow: View {
    let rep: Int
    let distance: Int
    let time: Double?
    let restMinutes: Int
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Text("\(rep)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
            
            Text("\(distance)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)
            
            if let time = time {
                Text(String(format: "%.2f", time))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
            } else if isActive {
                Text("...")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(width: 60, alignment: .leading)
            } else {
                Text("--")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 60, alignment: .leading)
            }
            
            Text("\(restMinutes)m")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            isActive ? Color.yellow.opacity(0.2) : Color.clear
        )
    }
}

struct ProWorkoutCompletionView: View {
    let distance: Int
    let reps: Int
    let restMinutes: Int
    let completedReps: [RepData]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Workout Complete!")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("You completed \(reps) × \(distance)yd sprints")
                .foregroundColor(.white.opacity(0.8))
            
            Button("Done", action: onDismiss)
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    SprintTimerProWorkoutView(distance: 40, reps: 3, restMinutes: 2)
}
