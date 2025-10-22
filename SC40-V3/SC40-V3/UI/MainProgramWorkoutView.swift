import SwiftUI
import Foundation

struct MainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let sessionData: SessionData?
    
    // Enhanced Sprint Coach Integration
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var phaseTimeRemaining: Int = 300 // 5 minutes for warmup
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var currentRep = 1
    @State private var totalReps: Int = 4
    @State private var completedReps: [RepData] = []
    @State private var showCompletionSheet = false
    @State private var phaseTimer: Timer?
    @State private var workoutTimer: Timer?
    
    // C25K-style coaching
    @State private var coachingMessage: String = ""
    @State private var showCoachingMessage: Bool = false
    @State private var isVoiceCoachingEnabled = true
    @State private var isGPSStopwatchActive = false
    
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
        
        var duration: Int {
            switch self {
            case .warmup: return 300 // 5 minutes
            case .stretch: return 300 // 5 minutes
            case .drill: return 360 // 6 minutes
            case .strides: return 360 // 6 minutes
            case .sprints: return 0 // Dynamic based on session
            case .resting: return 0 // Dynamic based on session
            case .cooldown: return 300 // 5 minutes
            case .completed: return 0
            }
        }
        
        var color: Color {
            switch self {
            case .warmup: return .orange
            case .stretch: return .blue
            case .drill: return .green
            case .strides: return .purple
            case .sprints: return .red
            case .resting: return .yellow
            case .cooldown: return .cyan
            case .completed: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .warmup: return "figure.walk"
            case .stretch: return "figure.flexibility"
            case .drill: return "figure.run"
            case .strides: return "figure.run.motion"
            case .sprints: return "bolt.fill"
            case .resting: return "pause.circle.fill"
            case .cooldown: return "figure.cooldown"
            case .completed: return "checkmark.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .warmup: return "Prepare your body with light movement and dynamic stretches"
            case .stretch: return "Improve flexibility and mobility with targeted stretches"
            case .drill: return "Practice technique with focused skill-building exercises"
            case .strides: return "Build speed and form with progressive acceleration runs"
            case .sprints: return "Maximum effort sprints to develop top-end speed"
            case .resting: return "Active recovery to prepare for the next set"
            case .cooldown: return "Gradually reduce intensity and promote recovery"
            case .completed: return "Great work! Your training session is complete"
            }
        }
    }
    
    // Session Data Model
    struct SessionData {
        let week: Int
        let day: Int
        let sprintSets: [SprintSet]
        let drillSets: [DrillSet]
        let strideSets: [StrideSet]
        let sessionType: String
        let level: Int
        let estimatedDuration: Int
        let variety: Double
        let engagement: Double
    }
    
    struct SprintSet {
        let distance: Int
        let restTime: Int
        let targetTime: Double?
    }
    
    struct DrillSet {
        let name: String
        let duration: Int
        let restTime: Int
    }
    
    struct StrideSet {
        let distance: Int
        let restTime: Int
    }
    
    var body: some View {
        mainWorkoutView
        .onAppear {
            setupSprintCoachWorkout()
        }
        .sheet(isPresented: $showCompletionSheet) {
            MainWorkoutCompletionView(
                sessionData: sessionData,
                completedReps: completedReps,
                onDismiss: {
                    showCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Main Workout View (exact copy of SprintTimerProWorkoutView UI)
    private var mainWorkoutView: some View {
        ZStack {
            // Same gradient background as SprintTimerProWorkoutView
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
                // Header - Same as SprintTimerProWorkoutView
                HStack {
                    Button(action: {
                        stopSprintCoachWorkout()
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
                    
                    Text("Sprint Training")
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
                
                // Scrollable Content - Same structure as SprintTimerProWorkoutView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Session Overview UI - Exact copy from SprintTimerProWorkoutView
                        VStack(spacing: 24) {
                            // Session Header
                            VStack(spacing: 8) {
                                Text("SPRINT COACH 40")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(2)
                                
                                Text("WEEK \(sessionData?.week ?? 1) - DAY \(sessionData?.day ?? 1) / \(calculateTotalDuration()) Min")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 20)
                            
                            // Phase Overview Cards
                            HStack(spacing: 12) {
                                PhaseCard(
                                    duration: "5 Min",
                                    title: "Warm",
                                    subtitle: "Up",
                                    isActive: currentPhase == .warmup,
                                    isCompleted: isPhaseCompleted(.warmup)
                                )
                                
                                PhaseCard(
                                    duration: "\(calculateSprintDuration()) Min",
                                    title: "\(getMainSprintDistance())yd Sprint",
                                    subtitle: "+ Rest",
                                    subtitle2: "(\(getTotalReps()) Reps)",
                                    isActive: [.sprints, .resting].contains(currentPhase),
                                    isCompleted: isPhaseCompleted(.sprints)
                                )
                                
                                PhaseCard(
                                    duration: "5 Min",
                                    title: "Cool",
                                    subtitle: "Down",
                                    isActive: currentPhase == .cooldown,
                                    isCompleted: isPhaseCompleted(.cooldown)
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // 7-Phase Progress Bar
                            ProgressBar(currentPhase: currentPhase, totalPhases: 7)
                                .padding(.horizontal, 20)
                            
                            // Speed Badge
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                
                                Text("SPEED BADGE")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1)
                            }
                            .padding(.vertical, 30)
                            
                            // Dynamic Action Controls
                            if !isRunning {
                                // Initial LET'S GO Button
                                Button(action: startSprintCoachWorkout) {
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
                                    Button(action: togglePausePlay) {
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
                                    Button(action: fastForward) {
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
                        
                        // Phase indicator dots
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
                            
                            Text(getCurrentPhaseName())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)
                                .animation(.easeInOut(duration: 0.3), value: currentPhase)
                        }
                        .padding(.vertical, 16)
                        
                        // Rep Log Section - Exact copy from image
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Rep Log")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("Live Workout Report 18:12")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Rep Log Table Header
                            HStack {
                                Text("REP")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("YDS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("TIME")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("REST")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 50, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            
                            // Sample Rep Row
                            HStack {
                                Text("1")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("40")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("2m")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 50, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .overlay(
            // Coaching message overlay - same as SprintTimerProWorkoutView
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
    }
    
    // MARK: - Helper Methods
    
    private func setupSprintCoachWorkout() {
        totalReps = sessionData?.sprintSets.count ?? 4
        completedReps = Array(1...totalReps).map { rep in
            RepData(rep: rep, time: nil, isCompleted: false, repType: RepData.RepType.sprint, distance: 40, timestamp: Date())
        }
    }
    
    private func isPhaseCompleted(_ phase: WorkoutPhase) -> Bool {
        let phaseIndex = WorkoutPhase.allCases.firstIndex(of: phase) ?? 0
        let currentIndex = WorkoutPhase.allCases.firstIndex(of: currentPhase) ?? 0
        return currentIndex > phaseIndex
    }
    
    // MARK: - SessionLibrary Integration Functions
    
    private func calculateTotalDuration() -> Int {
        // Calculate total workout duration based on session data
        guard let session = sessionData else { return 47 }
        
        let warmupDuration = 5 // minutes
        let cooldownDuration = 5 // minutes
        
        // Calculate sprint phase duration based on reps and rest
        let sprintDuration = calculateSprintDuration()
        
        return warmupDuration + sprintDuration + cooldownDuration
    }
    
    private func calculateSprintDuration() -> Int {
        // Calculate sprint phase duration from session data
        guard let session = sessionData else { return 6 }
        
        let totalReps = getTotalReps()
        let restBetweenReps = getRestTime() // seconds
        let sprintTime = 10 // estimated seconds per sprint
        
        let totalTimeSeconds = (totalReps * sprintTime) + ((totalReps - 1) * restBetweenReps)
        return max(Int(totalTimeSeconds / 60), 1) // Convert to minutes, minimum 1
    }
    
    private func getMainSprintDistance() -> Int {
        // Get the primary sprint distance from session data
        guard let session = sessionData,
              let firstSprintSet = session.sprintSets.first else { return 30 }
        return firstSprintSet.distance
    }
    
    private func getTotalReps() -> Int {
        // Get total number of reps from session data
        guard let session = sessionData else { return 1 }
        return session.sprintSets.count // Each sprint set represents one rep
    }
    
    private func getRestTime() -> Int {
        // Get rest time between reps (in seconds)
        // This would come from session template or default based on distance
        let distance = getMainSprintDistance()
        
        // Rest time scales with distance (Sprint Coach methodology)
        switch distance {
        case 0...20: return 60  // 1 minute
        case 21...40: return 120 // 2 minutes  
        case 41...60: return 180 // 3 minutes
        case 61...80: return 240 // 4 minutes
        default: return 300     // 5 minutes
        }
    }
    
    private func startSprintCoachWorkout() {
        isRunning = true
        isPaused = false
        
        // Initialize workout with session data
        setupWorkoutFromSessionData()
        
        // Start voice coaching
        startVoiceCoaching()
        
        // Provide haptic feedback
        triggerHapticFeedback(.start)
        
        // Start phase progression with timers
        startPhaseProgression()
        
        // Initialize GPS stopwatch for sprint tracking
        initializeGPSStopwatch()
        
        showCoachingCue("Let's begin your Sprint Coach 40 workout! 🚀")
    }
    
    private func stopSprintCoachWorkout() {
        isRunning = false
        isPaused = false
        
        // Stop all timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        
        // Stop GPS tracking
        stopGPSStopwatch()
        
        // Stop voice coaching
        stopVoiceCoaching()
        
        // Provide haptic feedback
        triggerHapticFeedback(.end)
        
        showCoachingCue("Workout stopped. Great effort! 💪")
    }
    
    private func togglePausePlay() {
        isPaused.toggle()
        
        if isPaused {
            pauseWorkout()
        } else {
            resumeWorkout()
        }
    }
    
    // MARK: - Workout Integration Functions
    
    private func setupWorkoutFromSessionData() {
        // Initialize workout parameters from session data
        guard let session = sessionData else { return }
        
        totalReps = getTotalReps()
        completedReps = Array(1...totalReps).map { rep in
            RepData(rep: rep, time: nil, isCompleted: false, repType: RepData.RepType.sprint, distance: getMainSprintDistance(), timestamp: Date())
        }
        
        // Set phase durations based on session
        phaseTimeRemaining = currentPhase.duration
    }
    
    private func pauseWorkout() {
        // Pause all timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        
        // Pause GPS tracking
        pauseGPSStopwatch()
        
        // Voice coaching
        announceVoiceCoaching("Workout paused. Take your time! ⏸️")
        
        // Haptic feedback
        triggerHapticFeedback(.medium)
        
        showCoachingCue("Workout paused. Tap play to continue! ⏸️")
    }
    
    private func resumeWorkout() {
        // Resume timers
        startPhaseProgression()
        
        // Resume GPS tracking
        resumeGPSStopwatch()
        
        // Voice coaching
        announceVoiceCoaching("Back to training! Let's keep pushing! ▶️")
        
        // Haptic feedback
        triggerHapticFeedback(.light)
        
        showCoachingCue("Back to training! Let's keep pushing! ▶️")
    }
    
    private func fastForward() {
        // Skip to next phase
        advanceToNextPhase()
        
        // Haptic feedback
        triggerHapticFeedback(.heavy)
        
        // Voice coaching
        let nextPhaseName = getCurrentPhaseName()
        announceVoiceCoaching("Skipping to \(nextPhaseName)! ⏭️")
        
        showCoachingCue("Skipping to \(nextPhaseName)! ⏭️")
    }
    
    // MARK: - Voice Coaching Integration
    
    private func startVoiceCoaching() {
        // Initialize text-to-speech or audio coaching system
        announceVoiceCoaching("Welcome to Sprint Coach 40! Let's get started! 🎯")
    }
    
    private func stopVoiceCoaching() {
        // Stop any ongoing voice coaching
        // This would integrate with AVSpeechSynthesizer or audio system
    }
    
    private func announceVoiceCoaching(_ message: String) {
        // This would integrate with AVSpeechSynthesizer for text-to-speech
        // For now, we'll use the visual coaching cue system
        print("🗣️ Voice Coach: \(message)")
    }
    
    // MARK: - Haptic Feedback Integration
    
    enum HapticType {
        case light, medium, heavy, start, end
    }
    
    private func triggerHapticFeedback(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .start:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .end:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }
    
    // MARK: - GPS Stopwatch Integration
    
    private func initializeGPSStopwatch() {
        // Initialize GPS tracking for sprint timing
        // This would integrate with CoreLocation and GPS timing
        isGPSStopwatchActive = true
        print("🛰️ GPS Stopwatch initialized for sprint tracking")
    }
    
    private func stopGPSStopwatch() {
        // Stop GPS tracking
        isGPSStopwatchActive = false
        print("🛰️ GPS Stopwatch stopped")
    }
    
    private func pauseGPSStopwatch() {
        // Pause GPS tracking during workout pause
        print("🛰️ GPS Stopwatch paused")
    }
    
    private func resumeGPSStopwatch() {
        // Resume GPS tracking
        print("🛰️ GPS Stopwatch resumed")
    }
    
    private func recordSprintTime() -> Double {
        // Record sprint time using GPS
        // This would return actual GPS-measured time
        let simulatedTime = Double.random(in: 4.5...6.5) // Simulated for now
        print("🛰️ Sprint time recorded: \(String(format: "%.2f", simulatedTime))s")
        return simulatedTime
    }

    private func providePhaseCoaching() {
        // Provide phase-specific coaching and instructions
        let coaching = currentPhase.description
        announceVoiceCoaching(coaching)
        showCoachingCue(coaching)
    }

    private func handleWorkoutProgress() {
        // Handle overall workout progress tracking
        // This could include periodic motivation, progress updates, etc.
    }

    private func startPhaseProgression() {
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { timer in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.2)) {
                    switch self.currentPhase {
                    case .warmup:
                        self.showCoachingCue("Great warm-up! Time to stretch those muscles ")
                        self.currentPhase = .stretch
                    case .stretch:
                        self.showCoachingCue("Perfect! Let's move to activation drills ")
                        self.currentPhase = .drill
                    case .drill:
                        self.showCoachingCue("Excellent form! Ready for build-up strides? ")
                        self.currentPhase = .strides
                    case .strides:
                        self.showCoachingCue("You're flying! Time for your sprints ")
                        self.currentPhase = .sprints
                    case .sprints:
                        self.showCoachingCue("Incredible speed! Time for recovery ")
                        self.currentPhase = .resting
                    case .resting:
                        self.showCoachingCue("Perfect recovery! Time to cool down ")
                        self.currentPhase = .cooldown
                    case .cooldown:
                        self.showCoachingCue("Sprint Coach workout complete! ")
                        self.currentPhase = .completed
                        timer.invalidate()
                    default:
                        timer.invalidate()
                    }
                }
            }
        }
    }

    private func advanceToNextPhase() {
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
            showCoachingCue("Fast forwarding to sprints! 🚀")
            currentPhase = .sprints
        case .sprints:
            showCoachingCue("Moving to recovery phase! 💪")
            currentPhase = .resting
        case .resting:
            showCoachingCue("Skipping to cool down! 🌟")
            currentPhase = .cooldown
        case .cooldown:
            showCoachingCue("Sprint Coach workout complete! 🏆")
            currentPhase = .completed
        default:
            break
        }
    }

    private func goToPreviousPhase() {
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

    private func toggleVoiceCoaching() {
        isVoiceCoachingEnabled.toggle()
        let message = isVoiceCoachingEnabled ? "Voice coaching enabled 🔊" : "Voice coaching disabled 🔇"
        showCoachingCue(message)
            
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
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
        case .sprints: return "MAXIMUM SPRINTS"
        case .resting: return "RECOVERY PHASE"
        case .cooldown: return "COOL DOWN"
        case .completed: return "SESSION COMPLETE"
        }
    }
    
    private func getSessionInfo() -> (week: Int, day: Int, duration: Int) {
        if let session = sessionData {
            return (week: session.week, day: session.day, duration: session.estimatedDuration)
        }
        return (week: 1, day: 1, duration: 47)
    }
}

// MARK: - Phase UI Components (Placeholder implementations)

struct SessionOverviewUI: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let isRunning: Bool
    let isPaused: Bool
    let onStartWorkout: () -> Void
    let onTogglePausePlay: () -> Void
    let onFastForward: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Sprint Coach Session Overview")
                .font(.title2)
                .foregroundColor(.white)
            
            if !isRunning {
                Button("Start Workout", action: onStartWorkout)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct StridesPhaseUI: View {
    var body: some View {
        VStack {
            Text("Strides Phase")
                .font(.title2)
                .foregroundColor(.white)
            Text("Build-up strides in progress...")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
}

struct SprintsPhaseUI: View {
    var body: some View {
        VStack {
            Text("Sprints Phase")
                .font(.title2)
                .foregroundColor(.white)
            Text("Maximum sprint efforts!")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
}

struct CompletionPhaseUI: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let onStartWorkout: () -> Void
    
    var body: some View {
        VStack {
            Text("Phase Complete!")
                .font(.title2)
                .foregroundColor(.white)
            Text("Great work on your session!")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
    }
}

struct AdaptiveRepLogView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let completedReps: [RepData]
    let currentRep: Int
    let totalReps: Int
    let sessionData: MainProgramWorkoutView.SessionData?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rep Log")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Rep \(currentRep) of \(totalReps)")
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PhaseCard: View {
    let duration: String
    let title: String
    let subtitle: String
    let subtitle2: String?
    let isActive: Bool
    let isCompleted: Bool
    
    init(duration: String, title: String, subtitle: String, subtitle2: String? = nil, isActive: Bool, isCompleted: Bool) {
        self.duration = duration
        self.title = title
        self.subtitle = subtitle
        self.subtitle2 = subtitle2
        self.isActive = isActive
        self.isCompleted = isCompleted
    }
    
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
                if let subtitle2 = subtitle2 {
                    Text(subtitle2)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
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

struct ProgressBar: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let totalPhases: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Phase Labels
            HStack {
                ForEach(0..<totalPhases, id: \.self) { index in
                    Text(getPhaseLabel(index: index))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(getPhaseColor(index: index))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Progress Bar
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
            return .green // Completed
        } else if index == currentIndex {
            return .orange // Current
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
}

struct MainWorkoutCompletionView: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let completedReps: [RepData]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Great job on your Sprint Coach session!")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            if let session = sessionData {
                VStack(spacing: 8) {
                    Text("Week \(session.week) - Day \(session.day)")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Completed \(completedReps.filter { $0.isCompleted }.count) of \(completedReps.count) reps")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
            
            Button("Done") {
                onDismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(25)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.3, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    MainProgramWorkoutView(sessionData: nil)
}
