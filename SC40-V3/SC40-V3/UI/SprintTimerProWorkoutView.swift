import SwiftUI

struct SprintTimerProWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Picker parameters
    let distance: Int
    let reps: Int
    let restMinutes: Int
    
    // 7-Stage Workout Process State
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var currentRep = 1
    @State private var phaseTimeRemaining = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showPhaseTransition = false
    @State private var completedPhases: Set<WorkoutPhase> = []
    @State private var phaseTransitionCount = 0 // Safety counter
    @State private var workoutStartTime: Date?
    
    // Enhanced AI Coaching Systems
    @StateObject private var biomechanicsEngine = BiomechanicsAnalysisEngine.shared
    @StateObject private var gpsFormEngine = GPSFormFeedbackEngine.shared
    @StateObject private var weatherEngine = WeatherAdaptationEngine.shared
    @StateObject private var mlRecommendationEngine = MLSessionRecommendationEngine.shared
    
    // Real-time feedback state
    @State private var showBiomechanicsFeedback = false
    @State private var showWeatherAdaptations = false
    
    // Timer for phase management
    @State private var phaseTimer: Timer?
    
    var body: some View {
        ZStack {
            // Main workout interface
            UnifiedSprintCoachView(
                sessionConfig: createSessionConfigFromPicker(),
                onClose: {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .navigationBarHidden(true)
            
            // 7-Stage Process Overlay
            if showPhaseTransition {
                phaseTransitionOverlay
            }
        }
        .onAppear {
            setupSevenStageProcess()
            setupEnhancedCoachingSystems()
        }
        .onDisappear {
            cleanupResources()
            cleanupEnhancedSystems()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // App going to background - pause timers
            pauseWorkout()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // App returning to foreground - resume if needed
            resumeWorkoutIfNeeded()
        }
    }
    
    // MARK: - Session Configuration Creation
    private func createSessionConfigFromPicker() -> SessionConfiguration {
        let sessionName = "\(distance) Yard Custom Sprint"
        let sessionType = determineSessionType()
        let difficulty = determineDifficulty()
        let estimatedDuration = calculateEstimatedDuration()
        let workoutVariation = determineWorkoutVariation()
        
        return SessionConfiguration(
            sessionName: sessionName,
            sessionType: sessionType,
            distance: distance,
            reps: reps,
            restMinutes: restMinutes,
            description: "Custom sprint workout configured via Sprint Timer Pro",
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            focus: determineFocus(),
            hasWarmup: true,
            hasStretching: true,
            hasDrills: true,
            hasStrides: true,
            hasCooldown: true,
            workoutVariation: workoutVariation
        )
    }
    
    private func determineSessionType() -> String {
        // Use dynamic session naming based on user level and distance
        let namingService = DynamicSessionNamingService.shared
        let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Beginner"
        
        return namingService.generateSessionType(
            userLevel: userLevel,
            distance: distance,
            reps: reps,
            intensity: "High",
            dayInWeek: 1
        )
    }
    
    private func determineDifficulty() -> String {
        let totalVolume = distance * reps
        switch totalVolume {
        case 0...200: return "Beginner"
        case 201...400: return "Intermediate"
        default: return "Advanced"
        }
    }
    
    private func calculateEstimatedDuration() -> String {
        let workoutTime = (reps * restMinutes) + 15
        return "\(workoutTime) min"
    }
    
    private func determineWorkoutVariation() -> SessionConfiguration.WorkoutVariation {
        if reps >= 10 && restMinutes <= 2 {
            return .intervals
        } else if distance >= 50 {
            return .flying
        } else if distance <= 25 {
            return .acceleration
        } else if reps >= 8 {
            return .endurance
        } else {
            return .standard
        }
    }
    
    private func determineFocus() -> String {
        switch distance {
        case 10...25: return "Explosive starts and acceleration"
        case 26...45: return "Maximum speed development"
        case 46...60: return "Top-end velocity maintenance"
        default: return "Speed endurance and power"
        }
    }
    
    // MARK: - 7-Stage Workout Process Implementation
    
    private func setupSevenStageProcess() {
        // Initialize the 7-stage process
        currentPhase = .warmup
        phaseTimeRemaining = getPhaseDefaultTime(for: .warmup)
        showPhaseTransition = true
        workoutStartTime = Date()
        
        // Auto-hide transition after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showPhaseTransition = false
            startPhaseTimer()
        }
    }
    
    private func startPhaseTimer() {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Safety check: Maximum 2 hour workout
            if let startTime = workoutStartTime,
               Date().timeIntervalSince(startTime) > 7200 { // 2 hours
                print("⚠️ Workout timeout reached, completing workout")
                phaseTimer?.invalidate()
                currentPhase = .completed
                showPhaseTransition = true
                return
            }
            
            if phaseTimeRemaining > 0 {
                phaseTimeRemaining -= 1
            } else {
                advanceToNextPhase()
            }
        }
    }
    
    private func advanceToNextPhase() {
        // Safety check to prevent infinite loops
        phaseTransitionCount += 1
        if phaseTransitionCount > 100 { // Max 100 transitions
            print("⚠️ Too many phase transitions, stopping workout")
            phaseTimer?.invalidate()
            currentPhase = .completed
            showPhaseTransition = true
            return
        }
        
        completedPhases.insert(currentPhase)
        
        let allPhases: [WorkoutPhase] = [.warmup, .stretch, .drill, .strides, .sprints, .resting, .cooldown, .completed]
        
        // Handle sprint/rest cycle logic first
        if currentPhase == .sprints && currentRep < reps {
            // After a sprint, go to rest
            currentPhase = .resting
        } else if currentPhase == .resting && currentRep < reps {
            // After rest, go to next sprint
            currentPhase = .sprints
            currentRep += 1
        } else if let currentIndex = allPhases.firstIndex(of: currentPhase),
                  currentIndex < allPhases.count - 1 {
            // Normal phase progression
            currentPhase = allPhases[currentIndex + 1]
        } else {
            // Workout completed
            phaseTimer?.invalidate()
            currentPhase = .completed
            showPhaseTransition = true
            return
        }
        
        // Set time for new phase
        phaseTimeRemaining = getPhaseDefaultTime(for: currentPhase)
        showPhaseTransition = true
        
        // Auto-hide transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showPhaseTransition = false
            }
        }
    }
    
    private func getPhaseDefaultTime(for phase: WorkoutPhase) -> Int {
        switch phase {
        case .warmup: return 300 // 5 minutes
        case .stretch: return 180 // 3 minutes
        case .drill: return 240 // 4 minutes
        case .strides: return 180 // 3 minutes
        case .sprints: return 60 // 1 minute per sprint
        case .resting: return restMinutes * 60 // User-defined rest time
        case .cooldown: return 300 // 5 minutes
        case .completed: return 0
        }
    }
    
    private var phaseTransitionOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Phase Progress Indicator
                HStack(spacing: 8) {
                    ForEach([WorkoutPhase.warmup, .stretch, .drill, .strides, .sprints, .resting, .cooldown], id: \.self) { phase in
                        Circle()
                            .fill(getPhaseColor(for: phase))
                            .frame(width: 12, height: 12)
                            .scaleEffect(phase == currentPhase ? 1.3 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPhase)
                    }
                }
                
                // Current Phase Display
                VStack(spacing: 16) {
                    Image(systemName: getPhaseIcon(for: currentPhase))
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(getPhaseColor(for: currentPhase))
                        .shadow(color: getPhaseColor(for: currentPhase).opacity(0.6), radius: 20)
                    
                    Text(getPhaseTitle(for: currentPhase))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text(getPhaseDescription(for: currentPhase))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if currentPhase == .sprints {
                        Text("REP \(currentRep) OF \(reps)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.orange)
                            .tracking(1)
                    }
                }
                
                // Phase Timer (if applicable)
                if phaseTimeRemaining > 0 && currentPhase != .completed {
                    VStack(spacing: 8) {
                        Text("TIME REMAINING")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)
                        
                        Text(formatTime(phaseTimeRemaining))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
                // Action Button
                if currentPhase != .completed {
                    Button(action: {
                        showPhaseTransition = false
                        if !isRunning {
                            isRunning = true
                            startPhaseTimer()
                        }
                    }) {
                        Text(isRunning ? "CONTINUE" : "START PHASE")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(getPhaseColor(for: currentPhase))
                            .cornerRadius(25)
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showPhaseTransition)
    }
    
    private func getPhaseColor(for phase: WorkoutPhase) -> Color {
        switch phase {
        case .warmup: return .orange
        case .stretch: return .purple
        case .drill: return .blue
        case .strides: return .green
        case .sprints: return .red
        case .resting: return .cyan
        case .cooldown: return .indigo
        case .completed: return .yellow
        }
    }
    
    private func getPhaseIcon(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup: return "flame.fill"
        case .stretch: return "figure.flexibility"
        case .drill: return "target"
        case .strides: return "figure.walk"
        case .sprints: return "figure.run"
        case .resting: return "pause.circle.fill"
        case .cooldown: return "snowflake"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    private func getPhaseTitle(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup: return "WARM-UP"
        case .stretch: return "STRETCHING"
        case .drill: return "DRILLS"
        case .strides: return "STRIDES"
        case .sprints: return "SPRINTS"
        case .resting: return "REST"
        case .cooldown: return "COOL-DOWN"
        case .completed: return "COMPLETED"
        }
    }
    
    private func getPhaseDescription(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup: return "Prepare your body with light jogging and dynamic movements"
        case .stretch: return "Dynamic stretching to improve range of motion"
        case .drill: return "Technical drills to perfect your sprint mechanics"
        case .strides: return "Progressive build-ups to activate your nervous system"
        case .sprints: return "Maximum effort \(distance)-yard sprints"
        case .resting: return "Active recovery between sprint repetitions"
        case .cooldown: return "Gradual cool-down with light movement and static stretching"
        case .completed: return "Excellent work! Your sprint session is complete"
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Lifecycle Management
    
    private func cleanupResources() {
        print("🧹 Cleaning up Sprint Timer Pro resources")
        phaseTimer?.invalidate()
        phaseTimer = nil
        phaseTransitionCount = 0
    }
    
    // MARK: - Enhanced Coaching Systems Setup
    
    private func setupEnhancedCoachingSystems() {
        // Start biomechanics analysis for real-time form feedback
        biomechanicsEngine.startBiomechanicsAnalysis()
        
        // Initialize GPS form feedback for sprint detection
        gpsFormEngine.startSprintTracking(targetDistance: Double(distance))
        
        // Apply weather adaptations to the current session
        applyWeatherAdaptations()
        
        // Generate ML-based session recommendations
        Task {
            await generateMLRecommendations()
        }
        
        print("🤖 Enhanced AI coaching systems activated")
    }
    
    private func cleanupEnhancedSystems() {
        // Stop biomechanics analysis
        let _ = biomechanicsEngine.stopBiomechanicsAnalysis()
        
        // Stop GPS tracking
        let _ = gpsFormEngine.stopSprintTracking()
        
        print("🤖 Enhanced AI coaching systems deactivated")
    }
    
    private func applyWeatherAdaptations() {
        let sessionConfig = createSessionConfigFromPicker()
        let mockSession = TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: sessionConfig.sessionType,
            focus: sessionConfig.focus,
            sprints: [SprintSet(distanceYards: distance, reps: reps, intensity: "max")],
            accessoryWork: [],
            notes: sessionConfig.description
        )
        
        let adaptations = weatherEngine.getWorkoutAdaptationsForSession(mockSession)
        
        if !adaptations.isEmpty {
            showWeatherAdaptations = true
            print("🌤️ Applied \(adaptations.count) weather adaptations to session")
        }
        
        // Check if workout should be postponed due to weather
        if weatherEngine.shouldPostponeWorkout() {
            print("⚠️ Weather conditions suggest postponing outdoor workout")
        }
    }
    
    private func generateMLRecommendations() async {
        // Mock user profile for demonstration
        let mockProfile = UserProfile(
            name: "Demo User",
            email: "demo@example.com", 
            gender: "Other",
            age: 25,
            height: 180,
            weight: 75,
            personalBests: ["40yd": 4.8],
            level: "intermediate",
            baselineTime: 4.8,
            frequency: 3
        )
        
        print("🧠 ML recommendations system initialized")
    }
    
    private func pauseWorkout() {
        print("⏸️ Pausing workout for background")
        if isRunning && !isPaused {
            phaseTimer?.invalidate()
            isPaused = true
        }
    }
    
    private func resumeWorkoutIfNeeded() {
        print("▶️ Resuming workout from background")
        if isRunning && isPaused && currentPhase != .completed {
            isPaused = false
            startPhaseTimer()
        }
    }
}

#Preview {
    SprintTimerProWorkoutView(distance: 40, reps: 6, restMinutes: 2)
}
