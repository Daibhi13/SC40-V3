import SwiftUI
import AVFoundation
import Combine

// MARK: - Enhanced 7-Stage Workout View for Apple Watch with Advanced Logic
struct Enhanced7StageWorkoutView: View {
    @StateObject private var watchSyncManager = WatchWorkoutSyncManager.shared
    @StateObject private var workoutVM: WorkoutWatchViewModel
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var phaseTimeRemaining: Int = 300 // 5 minutes for warmup
    @State private var phaseTimer: Timer?
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showCompletionView = false
    
    // Enhanced coaching and feedback system
    @State private var coachingMessage: String = ""
    @State private var showCoachingMessage: Bool = false
    @State private var isVoiceCoachingEnabled = true
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var currentRep = 1
    @State private var totalReps = 4
    
    // Navigation state for swipe gestures
    @State private var showControlView = false
    @State private var showMusicView = false
    @State private var showRepLogView = false
    @State private var horizontalTab = 0
    
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
            // STANDARDIZED: Matching gradient across all views
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.25),
                    Color(red: 0.12, green: 0.18, blue: 0.35),
                    Color(red: 0.15, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showCompletionView {
                WorkoutCompletionView(session: session)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
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
                    }
                    .padding()
                }
                
                // Enhanced Coaching Message Overlay
                if showCoachingMessage {
                    VStack {
                        Spacer()
                        
                        Text(coachingMessage)
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.orange, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            setupWorkout()
            setupAutoAdaptation()
        }
        .onDisappear {
            cleanupWorkout()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutStateAdapted)) { notification in
            if let adaptedState = notification.object as? WorkoutSyncState {
                adaptToPhoneWorkoutState(adaptedState)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .uiConfigurationAdapted)) { notification in
            if let adaptedConfig = notification.object as? UIConfigurationSync {
                adaptToPhoneUIConfiguration(adaptedConfig)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .coachingPreferencesAdapted)) { notification in
            if let adaptedPrefs = notification.object as? CoachingPreferencesSync {
                adaptToPhoneCoachingPreferences(adaptedPrefs)
            }
        }
        .gesture(swipeGesture)
        .fullScreenCover(isPresented: $showControlView) {
            ControlWatchView(workoutVM: workoutVM)
        }
        .fullScreenCover(isPresented: $showMusicView) {
            MusicWatchView()
        }
        .fullScreenCover(isPresented: $showRepLogView) {
            RepLogWatchLiveView(
                workoutVM: workoutVM, 
                horizontalTab: $horizontalTab,
                onDone: {
                    showRepLogView = false
                }
            )
        }
    }
    
    // MARK: - Swipe Gesture Handler
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) {
                    // Horizontal swipes
                    if horizontalAmount < 0 {
                        // Swipe Left → ControlView
                        print("🔄 Swipe Left - Opening ControlView")
                        showControlView = true
                    } else {
                        // Swipe Right → MusicView
                        print("🎵 Swipe Right - Opening MusicView")
                        showMusicView = true
                    }
                } else {
                    // Vertical swipes
                    if verticalAmount < 0 {
                        // Swipe Up → RepLogView
                        print("📊 Swipe Up - Opening RepLogView")
                        showRepLogView = true
                    }
                    // Swipe Down - could be used for other functionality if needed
                }
                
                // Add haptic feedback for swipe gestures
                #if os(watchOS)
                WKInterfaceDevice.current().play(.click)
                #endif
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
        
        // Enhanced haptic feedback
        triggerHapticFeedback(.start)
        
        // Enhanced voice coaching
        startVoiceCoaching()
        speakPhaseStart()
        
        // Show coaching cue
        showCoachingCue("Workout started! Let's achieve greatness! 🚀")
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
        guard isVoiceCoachingEnabled else { return }
        
        // Use AVSpeechSynthesizer for voice coaching
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 0.8
        
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Enhanced Logic Transfer from MainProgramWorkoutView
    
    // MARK: - Voice Coaching Integration
    
    private func startVoiceCoaching() {
        announceVoiceCoaching("Welcome to Sprint Coach 40 on Apple Watch! Let's get started! 🎯")
    }
    
    private func stopVoiceCoaching() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    private func announceVoiceCoaching(_ message: String) {
        guard isVoiceCoachingEnabled else { return }
        
        // Enhanced voice coaching with Apple Watch optimization
        let cleanMessage = message.replacingOccurrences(of: "🎯|🚀|💪|⚡|🔥|🏆|🌟|⏸️|▶️|⏭️|✅|🔄|🎉", with: "", options: .regularExpression)
        
        let utterance = AVSpeechUtterance(string: cleanMessage)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.6 // Slightly faster for watch
        utterance.volume = 0.9 // Louder for watch speaker
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for clarity
        
        speechSynthesizer.speak(utterance)
        
        // Also show visual coaching cue
        showCoachingCue(message)
        
        print("🗣️ Watch Voice Coach: \(cleanMessage)")
    }
    
    private func toggleVoiceCoaching() {
        isVoiceCoachingEnabled.toggle()
        let message = isVoiceCoachingEnabled ? "Voice coaching enabled 🔊" : "Voice coaching disabled 🔇"
        showCoachingCue(message)
        triggerHapticFeedback(.light)
    }
    
    // MARK: - Haptic Feedback Integration
    
    enum HapticType {
        case light, medium, heavy, start, end, success, warning, error
    }
    
    private func triggerHapticFeedback(_ type: HapticType) {
        // Apple Watch haptic feedback using WKHapticType
        #if os(watchOS)
        switch type {
        case .light:
            // Use digital crown haptic for light feedback
            WKInterfaceDevice.current().play(.click)
        case .medium:
            WKInterfaceDevice.current().play(.notification)
        case .heavy:
            WKInterfaceDevice.current().play(.directionUp)
        case .start:
            WKInterfaceDevice.current().play(.start)
        case .end:
            WKInterfaceDevice.current().play(.stop)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .warning:
            WKInterfaceDevice.current().play(.retry)
        case .error:
            WKInterfaceDevice.current().play(.failure)
        }
        #endif
    }
    
    // MARK: - Enhanced Coaching Cue System
    
    private func showCoachingCue(_ message: String) {
        coachingMessage = message
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCoachingMessage = true
        }
        
        // Hide after 4 seconds (longer for watch readability)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.showCoachingMessage = false
            }
        }
    }
    
    // MARK: - Enhanced Phase Management
    
    private func providePhaseCoaching() {
        let coaching = currentPhase.instructions
        announceVoiceCoaching(coaching)
        showCoachingCue(coaching)
    }
    
    private func handlePhaseTransition() {
        // Enhanced phase transition with coaching
        let phaseName = currentPhase.title
        announceVoiceCoaching("Moving to \(phaseName). \(currentPhase.instructions)")
        showCoachingCue("Moved to \(phaseName)")
        triggerHapticFeedback(.medium)
    }
    
    // MARK: - Rep Management for Sprint Phases
    
    private func completeCurrentRep(time: Double? = nil) {
        guard currentPhase == .sprints else { return }
        
        // Provide feedback
        if let time = time {
            announceVoiceCoaching("Rep \(currentRep) completed in \(String(format: "%.2f", time)) seconds! 🎯")
            showCoachingCue("Rep \(currentRep): \(String(format: "%.2f", time))s ⚡")
        } else {
            announceVoiceCoaching("Rep \(currentRep) completed! 💪")
            showCoachingCue("Rep \(currentRep) completed! ✅")
        }
        
        // Haptic feedback for rep completion
        triggerHapticFeedback(.success)
        
        // Move to next rep or complete workout
        if currentRep < totalReps {
            currentRep += 1
            startRestPeriod()
        } else {
            completeSprintPhase()
        }
    }
    
    private func startRestPeriod() {
        currentPhase = .resting
        phaseTimeRemaining = 120 // 2 minutes rest
        
        announceVoiceCoaching("Rest for 2 minutes. Prepare for rep \(currentRep)! ⏱️")
        showCoachingCue("Rest: 2 min - Rep \(currentRep) next 🔄")
        
        startPhaseTimer()
        triggerHapticFeedback(.medium)
    }
    
    private func completeSprintPhase() {
        currentPhase = .cooldown
        phaseTimeRemaining = WorkoutPhase.cooldown.duration
        
        announceVoiceCoaching("All sprints completed! Time to cool down! 🌟")
        showCoachingCue("Sprint phase complete! Cool down time 🎉")
        
        startPhaseTimer()
        triggerHapticFeedback(.success)
    }
    
    // MARK: - Enhanced Workout Controls
    
    private func enhancedPauseWorkout() {
        isRunning = false
        isPaused = true
        phaseTimer?.invalidate()
        
        // Enhanced feedback
        announceVoiceCoaching("Workout paused. Take your time! ⏸️")
        showCoachingCue("Workout paused. Tap play to continue! ⏸️")
        triggerHapticFeedback(.medium)
    }
    
    private func enhancedResumeWorkout() {
        isRunning = true
        isPaused = false
        startPhaseTimer()
        
        announceVoiceCoaching("Back to training! Let's keep pushing! ▶️")
        showCoachingCue("Back to training! Let's keep pushing! ▶️")
        triggerHapticFeedback(.light)
    }
    
    
    // MARK: - Auto-Adaptation Methods
    
    private func setupAutoAdaptation() {
        // Request initial sync from iPhone
        watchSyncManager.requestFullSyncFromPhone()
        
        print("⌚ Auto-adaptation setup complete - watching for iPhone changes")
    }
    
    private func adaptToPhoneWorkoutState(_ phoneState: WorkoutSyncState) {
        // Adapt workout state based on iPhone changes
        if let adaptedPhase = WorkoutPhase(rawValue: phoneState.currentPhase) {
            currentPhase = adaptedPhase
        }
        
        phaseTimeRemaining = phoneState.phaseTimeRemaining
        isRunning = phoneState.isRunning
        isPaused = phoneState.isPaused
        currentRep = phoneState.currentRep
        totalReps = phoneState.totalReps
        
        // Show adaptation message
        showCoachingCue("Synced with iPhone workout state 📱")
        triggerHapticFeedback(.light)
        
        print("⌚ Adapted to iPhone workout state: \(phoneState.currentPhase)")
    }
    
    private func adaptToPhoneUIConfiguration(_ phoneConfig: UIConfigurationSync) {
        // Adapt UI configuration based on iPhone changes
        // This could include color themes, animation speeds, etc.
        
        showCoachingCue("UI updated from iPhone settings 🎨")
        
        print("⌚ Adapted to iPhone UI configuration")
    }
    
    private func adaptToPhoneCoachingPreferences(_ phonePrefs: CoachingPreferencesSync) {
        // Adapt coaching preferences based on iPhone changes
        isVoiceCoachingEnabled = phonePrefs.isVoiceCoachingEnabled
        
        // Update speech synthesizer settings
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        let message = phonePrefs.isVoiceCoachingEnabled ? 
            "Voice coaching enabled from iPhone 🔊" : 
            "Voice coaching disabled from iPhone 🔇"
        
        showCoachingCue(message)
        triggerHapticFeedback(.light)
        
        print("⌚ Adapted to iPhone coaching preferences: voice=\(phonePrefs.isVoiceCoachingEnabled)")
    }
    
    // MARK: - Send Watch State to iPhone
    
    private func sendWatchStateToPhone() {
        let watchState = watchSyncManager.createWatchStateSync(
            currentPhase: currentPhase.rawValue,
            isRunning: isRunning,
            isPaused: isPaused,
            currentRep: currentRep
        )
        
        watchSyncManager.sendWatchStateToPhone(watchState)
    }
    
    private func sendWatchActionToPhone(_ action: String) {
        let watchState = watchSyncManager.createWatchStateSync(
            currentPhase: currentPhase.rawValue,
            isRunning: isRunning,
            isPaused: isPaused,
            currentRep: currentRep,
            requestedAction: action
        )
        
        watchSyncManager.sendWatchStateToPhone(watchState)
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

// MARK: - Enhanced Workout Controls View
struct EnhancedWorkoutControlsView: View {
    let isRunning: Bool
    let isPaused: Bool
    let onStartPause: () -> Void
    let onNext: () -> Void
    let onComplete: () -> Void
    let onToggleVoice: () -> Void
    let isVoiceEnabled: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Primary control button with enhanced styling
            Button(action: onStartPause) {
                HStack {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.body)
                    Text(isRunning ? "Pause" : (isPaused ? "Resume" : "Start"))
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.9), Color.green],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Secondary controls with enhanced layout
            HStack(spacing: 6) {
                Button("Next", action: onNext)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(6)
                
                Button("Complete", action: onComplete)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.8))
                    .cornerRadius(6)
                
                // Voice coaching toggle
                Button(action: onToggleVoice) {
                    Image(systemName: isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isVoiceEnabled ? Color.purple.opacity(0.8) : Color.gray.opacity(0.6))
                .cornerRadius(6)
            }
        }
    }
}

// MARK: - Legacy Workout Controls View (for compatibility)
struct WorkoutControlsView: View {
    let isRunning: Bool
    let isPaused: Bool
    let onStartPause: () -> Void
    let onNext: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        EnhancedWorkoutControlsView(
            isRunning: isRunning,
            isPaused: isPaused,
            onStartPause: onStartPause,
            onNext: onNext,
            onComplete: onComplete,
            onToggleVoice: {},
            isVoiceEnabled: true
        )
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
            
            Text("ENHANCED 7-STAGE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .tracking(2)
            
            Text("Training Session")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
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
