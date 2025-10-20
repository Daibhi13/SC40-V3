import SwiftUI
import CoreLocation
import Combine

struct MainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Sprint Coach Integration
    // Sprint Coach automated coaching system
    
    // Sprint Coach 6-Phase System State
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var phaseTimeRemaining: Int = 300 // 5 minutes for warmup
    @State private var currentRep: Int = 1
    @State private var totalReps: Int = 4
    @State private var sprintTime: Double = 0.0
    @State private var currentSpeed: Double = 0.0
    @State private var currentDistance: Double = 0.0
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var phaseTimer: Timer?
    @State private var workoutTimer: Timer?
    
    // Session Library Integration
    @State private var sessionData: SessionData?
    @State private var completedReps: [RepData] = []
    @State private var isGPSStopwatchActive: Bool = false
    @State private var drillsCompleted: Int = 0
    @State private var stridesCompleted: Int = 0
    @State private var plyometricsCompleted: Int = 0
    
    // Legacy state for UI compatibility
    @State private var currentSession: WorkoutSession?
    @State private var showRepLog = true
    @State private var showCompletionSheet = false
    @State private var workoutResults: WorkoutResults? = nil
    
    // MARK: - Session Library Models
    
    struct SessionData {
        let id = UUID()
        let week: Int
        let day: Int
        let level: Int // 1-7 difficulty levels
        let drillSets: [DrillSet]
        let strideSets: [StrideSet]
        let sprintSets: [SessionSprintSet]
        let plyometricSets: [PlyometricSet]
        
        // Enhanced engagement features
        let librarySession: LibrarySession?
        let sessionVariety: Double // 0.0-1.0 variety score
        let engagementScore: Double // 0.0-1.0 engagement prediction
        
        init(week: Int, day: Int, level: Int, drillSets: [DrillSet], strideSets: [StrideSet], sprintSets: [SessionSprintSet], plyometricSets: [PlyometricSet], librarySession: LibrarySession? = nil, sessionVariety: Double = 0.5, engagementScore: Double = 0.5) {
            self.week = week
            self.day = day
            self.level = level
            self.drillSets = drillSets
            self.strideSets = strideSets
            self.sprintSets = sprintSets
            self.plyometricSets = plyometricSets
            self.librarySession = librarySession
            self.sessionVariety = sessionVariety
            self.engagementScore = engagementScore
        }
        
        static func getSessionForDay(week: Int, day: Int, level: Int) -> SessionData {
            // Dynamic session generation based on week, day, and level
            let drillSets = generateDrillSets(for: level)
            let strideSets = generateStrideSets(for: level)
            let sprintSets = generateSprintSets(for: week, day: day, level: level)
            let plyometricSets = generatePlyometricSets(for: level)
            
            return SessionData(
                week: week,
                day: day,
                level: level,
                drillSets: drillSets,
                strideSets: strideSets,
                sprintSets: sprintSets,
                plyometricSets: plyometricSets
            )
        }
        
        /// Intelligent session selection from 240+ session library with engagement optimization
        static func getIntelligentSessionForDay(
            week: Int,
            day: Int,
            level: Int,
            userPreferences: UserPreferences? = nil,
            completedSessions: [Int] = []
        ) -> SessionData {
            
            // Convert level to string for session library compatibility
            let levelString = getLevelString(from: level)
            
            // Get training phase for intelligent session selection
            let trainingPhase = getTrainingPhase(for: week)
            
            // Select optimal session from 240+ library based on multiple factors
            let selectedSession = selectOptimalSession(
                week: week,
                day: day,
                level: levelString,
                phase: trainingPhase,
                preferences: userPreferences,
                completedSessions: completedSessions
            )
            
            // Generate supporting sets based on selected session
            let drillSets = generateAdaptiveDrillSets(for: level, session: selectedSession)
            let strideSets = generateAdaptiveStrideSets(for: level, session: selectedSession)
            let plyometricSets = generateAdaptivePlyometricSets(for: level, session: selectedSession)
            
            // Convert selected session to sprint sets
            let sprintSets = convertToSessionSprintSets(from: selectedSession, week: week, level: level)
            
            return SessionData(
                week: week,
                day: day,
                level: level,
                drillSets: drillSets,
                strideSets: strideSets,
                sprintSets: sprintSets,
                plyometricSets: plyometricSets,
                librarySession: selectedSession,
                sessionVariety: calculateSessionVariety(completedSessions: completedSessions),
                engagementScore: calculateEngagementScore(session: selectedSession, week: week)
            )
        }
        
        private static func generateDrillSets(for level: Int) -> [DrillSet] {
            let baseReps = min(3 + level, 8) // 3-8 reps based on level
            return [
                DrillSet(name: "High Knees", reps: baseReps, distance: 20),
                DrillSet(name: "Butt Kicks", reps: baseReps, distance: 20),
                DrillSet(name: "A-Skips", reps: baseReps, distance: 20)
            ]
        }
        
        private static func generateStrideSets(for level: Int) -> [StrideSet] {
            return [
                StrideSet(reps: 3, distance: 20, restTime: 120) // Always 3x20yd, 2min rest
            ]
        }
        
        private static func generatePlyometricSets(for level: Int) -> [PlyometricSet] {
            let baseReps = min(2 + level, 6) // 2-6 reps based on level
            return [
                PlyometricSet(name: "Broad Jumps", reps: baseReps, distance: 10, restTime: 90),
                PlyometricSet(name: "Single Leg Bounds", reps: baseReps, distance: 15, restTime: 90),
                PlyometricSet(name: "Box Jumps", reps: baseReps, distance: 0, restTime: 120), // Height-based
                PlyometricSet(name: "Depth Jumps", reps: baseReps, distance: 0, restTime: 120),
                PlyometricSet(name: "Lateral Bounds", reps: baseReps, distance: 12, restTime: 90),
                PlyometricSet(name: "Split Jumps", reps: baseReps, distance: 0, restTime: 90)
            ]
        }
        
        private static func generateSprintSets(for week: Int, day: Int, level: Int) -> [SessionSprintSet] {
            // Dynamic sprint configuration based on progression
            let baseReps = 3 + (week - 1) // Progressive overload
            let adjustedReps = min(baseReps + (level - 1), 8) // Cap at 8 reps
            let distance = getSprintDistance(week: week, day: day)
            let restTime = getRestTime(distance: distance, level: level)
            
            return [
                SessionSprintSet(
                    reps: adjustedReps,
                    distance: distance,
                    restTime: restTime,
                    intensity: getIntensity(week: week, level: level)
                )
            ]
        }
        
        private static func getSprintDistance(week: Int, day: Int) -> Int {
            // Progressive distance based on week and day
            switch (week, day) {
            case (1...2, _): return 30
            case (3...4, _): return 40
            case (5...6, _): return 50
            case (7...8, _): return 60
            case (9...10, _): return 70
            default: return 80
            }
        }
        
        private static func getRestTime(distance: Int, level: Int) -> Int {
            let baseRest = distance * 3 // 3 seconds per yard
            let levelAdjustment = (7 - level) * 10 // Less rest for higher levels
            return max(baseRest + levelAdjustment, 120) // Minimum 2 minutes
        }
        
        private static func getIntensity(week: Int, level: Int) -> String {
            let weekIntensity = min(week * 10 + 70, 100) // 80-100% based on week
            let levelBonus = level * 2 // Higher levels get slightly more intensity
            let totalIntensity = min(weekIntensity + levelBonus, 100)
            return "\(totalIntensity)%"
        }
    }
    
    struct DrillSet {
        let name: String
        let reps: Int
        let distance: Int // yards
    }
    
    struct StrideSet {
        let reps: Int
        let distance: Int // yards
        let restTime: Int // seconds
    }
    
    struct SessionSprintSet {
        let reps: Int
        let distance: Int // yards
        let restTime: Int // seconds
        let intensity: String
    }
    
    struct PlyometricSet {
        let name: String
        let reps: Int
        let distance: Int // yards (0 for height-based exercises)
        let restTime: Int // seconds
    }
    
    struct RepData {
        let id = UUID()
        let type: RepType
        let rep: Int
        let distance: Int
        let time: Double
        let speed: Double
        let timestamp: Date
        
        enum RepType {
            case drill, stride, sprint, plyometric
        }
    }
    
    // MARK: - Models
    
    struct WorkoutSession {
        let id = UUID()
        let week: Int
        let day: Int
        let type: String
        let sprints: [SprintSet]
        let totalDuration: Int // minutes
        
        static let sample = WorkoutSession(
            week: 1,
            day: 1,
            type: "Speed Development",
            sprints: [SprintSet(distanceYards: 30, reps: 4, intensity: "100%")],
            totalDuration: 47
        )
    }
    
    struct SprintSet {
        let distanceYards: Int
        let reps: Int
        let intensity: String
        
        var restTime: Int {
            // Calculate rest based on distance (in seconds)
            switch distanceYards {
            case 0...20: return 60
            case 21...40: return 120
            case 41...60: return 180
            default: return 240
            }
        }
    }
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "warmup"
        case stretch = "stretch"
        case drill = "drill"
        case strides = "strides"
        case sprints = "sprints"
        case plyometrics = "plyometrics"
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
            case .plyometrics: return "Plyometrics"
            case .resting: return "Rest"
            case .cooldown: return "Cooldown"
            case .completed: return "Complete"
            }
        }
        
        var description: String {
            switch self {
            case .warmup: return "Light jog"
            case .stretch: return "Dynamic mobility"
            case .drill: return "GPS Stopwatch (20-yard clarity check)"
            case .strides: return "20 yards × 3 reps"
            case .sprints: return "Maximum effort sprints"
            case .plyometrics: return "GPS Stopwatch (explosive power)"
            case .resting: return "Active recovery"
            case .cooldown: return "Stretch and recover"
            case .completed: return "Session complete!"
            }
        }
        
        var duration: Int {
            switch self {
            case .warmup: return 300 // 5 minutes
            case .stretch: return 300 // 5 minutes
            case .drill: return 600 // 10 minutes (with 1 min rest between sets)
            case .strides: return 480 // 8 minutes (3x20yd with 2min rest)
            case .sprints: return 0 // Dynamic based on Session Library
            case .plyometrics: return 720 // 12 minutes (6 exercises with GPS timing)
            case .resting: return 0 // Dynamic based on Session Library
            case .cooldown: return 300 // 5 minutes
            case .completed: return 0
            }
        }
        
        var color: Color {
            switch self {
            case .warmup: return Color.orange
            case .stretch: return Color.pink
            case .drill: return Color.indigo
            case .strides: return Color.purple
            case .sprints: return Color.green
            case .plyometrics: return Color.red
            case .resting: return Color.yellow
            case .cooldown: return Color.blue
            case .completed: return Color.cyan
            }
        }
        
        var icon: String {
            switch self {
            case .warmup: return "figure.walk"
            case .stretch: return "figure.flexibility"
            case .drill: return "figure.run.circle"
            case .strides: return "figure.run"
            case .sprints: return "bolt.fill"
            case .plyometrics: return "figure.jumprope"
            case .resting: return "pause.fill"
            case .cooldown: return "figure.cooldown"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    // MARK: - Workout Results Model
    struct WorkoutResults {
        let sessionId: UUID
        let date: Date
        let session: WorkoutSession?
        let drillTimes: [Double]
        let strideTimes: [Double]
        let sprintTimes: [Double]
        let bestTime: Double
        let averageTime: Double
        let totalReps: Int
        let personalBest: Bool
        
        var allTimes: [Double] {
            drillTimes + strideTimes + sprintTimes
        }
        
        init(session: WorkoutSession?, drillTimes: [Double], strideTimes: [Double], sprintTimes: [Double]) {
            self.sessionId = UUID()
            self.date = Date()
            self.session = session
            self.drillTimes = drillTimes
            self.strideTimes = strideTimes
            self.sprintTimes = sprintTimes
            
            let allTimes = drillTimes + strideTimes + sprintTimes
            self.bestTime = allTimes.min() ?? 0.0
            self.averageTime = allTimes.isEmpty ? 0.0 : allTimes.reduce(0, +) / Double(allTimes.count)
            self.totalReps = allTimes.count
            
            // Check if this is a personal best (simplified - would normally check against stored history)
            self.personalBest = bestTime > 0 && bestTime < 5.0 // Placeholder logic
        }
    }
    
    // MARK: - Helper Methods for New UI
    
    private func getSessionInfo() -> (week: Int, day: Int, duration: Int) {
        if let session = sessionData {
            return (week: session.week, day: session.day, duration: 47) // Default duration
        }
        return (week: 1, day: 1, duration: 47)
    }
    
    private func getPhaseIndex(_ phase: WorkoutPhase) -> Int {
        switch phase {
        case .warmup: return 0
        case .stretch: return 1
        case .drill: return 2
        case .strides: return 3
        case .plyometrics: return 4
        case .sprints: return 5
        case .cooldown: return 6
        case .resting: return 7
        case .completed: return 8
        }
    }
    
    private func getMainPhaseTitle() -> String {
        switch currentPhase {
        case .drill: return "Drills"
        case .strides: return "Strides"
        case .plyometrics: return "Plyo"
        case .sprints: return "Sprint"
        default: return "30yd Sprint + Rest"
        }
    }
    
    private func getMainPhaseSubtitle() -> String {
        switch currentPhase {
        case .drill: return ""
        case .strides: return ""
        case .plyometrics: return ""
        case .sprints: return "(3 Reps)"
        default: return "(3 Reps)"
        }
    }
    
    private func isMainPhase() -> Bool {
        switch currentPhase {
        case .drill, .strides, .plyometrics, .sprints:
            return true
        default:
            return false
        }
    }
    
    private func getActionButtonText() -> String {
        if isPaused {
            return "RESUME"
        } else if isRunning {
            return "PAUSE"
        } else {
            return "LET'S\nGO"
        }
    }
    
    private func startWorkout() {
        isRunning = true
        isPaused = false
        setupSprintCoachWorkout()
        
        // Start demo timer to show UI flow
        startDemoPhaseProgression()
    }
    
    private func startDemoPhaseProgression() {
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
                        self.showCoachingCue("You're flying! Time for maximum effort sprints 🚀")
                        self.currentPhase = .sprints
                    case .sprints:
                        self.showCoachingCue("Incredible speed! Let's add some explosive power 💥")
                        self.currentPhase = .plyometrics
                    case .plyometrics:
                        self.showCoachingCue("Amazing work! Time to cool down and recover 🌟")
                        self.currentPhase = .cooldown
                    case .cooldown:
                        self.showCoachingCue("Session complete! You're getting faster every day! 🏆")
                        self.currentPhase = .completed
                        timer.invalidate()
                    default:
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    @State private var coachingMessage: String = ""
    @State private var showCoachingMessage: Bool = false
    
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
        case .strides, .plyometrics: return 1
        case .sprints, .cooldown, .resting, .completed: return 2
        }
    }
    
    private func getCurrentPhaseName() -> String {
        switch currentPhase {
        case .warmup: return "WARM-UP PHASE"
        case .stretch: return "STRETCH PHASE"
        case .drill: return "ACTIVATION DRILLS"
        case .strides: return "BUILD-UP STRIDES"
        case .plyometrics: return "EXPLOSIVE POWER"
        case .sprints: return "MAXIMUM SPRINTS"
        case .cooldown: return "COOL DOWN"
        case .resting: return "RECOVERY"
        case .completed: return "SESSION COMPLETE"
        }
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background matching the image
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
                // Header with close button
                HStack {
                    Spacer()
                    
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Show different UI based on current phase
                        switch currentPhase {
                        case .warmup, .stretch, .drill:
                            // Initial phases - show session overview
                            SessionOverviewUI(
                                sessionData: sessionData,
                                onStartWorkout: startWorkout
                            )
                        case .strides:
                            // Strides phase - show timer and strides info
                            StridesPhaseUI()
                        case .sprints:
                            // Sprints phase - show timer and sprint info
                            SprintsPhaseUI()
                        case .plyometrics:
                            // Plyometrics phase - show plyo info
                            PlyometricsPhaseUI(
                                sessionData: sessionData,
                                onStartWorkout: startWorkout
                            )
                        case .cooldown, .resting, .completed:
                            // Final phases - show completion
                            CompletionPhaseUI(
                                sessionData: sessionData,
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
                        AdaptiveRepLogView(
                            currentPhase: currentPhase,
                            completedReps: completedReps,
                            currentRep: currentRep,
                            totalReps: totalReps,
                            sessionData: sessionData
                        )
                        .padding(.bottom, 20) // Extra padding at bottom
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
        .onAppear(perform: setupSprintCoachWorkout)
        .onDisappear(perform: stopSprintCoachWorkout)
        .sheet(isPresented: $showCompletionSheet) {
            WorkoutCompletionView(
                session: currentSession,
                allTimes: [],
                onDismiss: {
                    showCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    } // end body
    
    // MARK: - Sprint Coach 6-Phase Integration Methods
    
    private func setupSprintCoachWorkout() {
        print("🏃‍♂️ Sprint Coach: Setting up 6-phase automated workout with Session Library")
        
        // Load session data from Session Library with intelligent selection
        sessionData = SessionData.getIntelligentSessionForDay(
            week: getCurrentWeek(),
            day: getCurrentDay(),
            level: getUserLevel(),
            userPreferences: getUserPreferences(),
            completedSessions: getCompletedSessionHistory()
        )
        
        // Initialize first phase
        currentPhase = .warmup
        phaseTimeRemaining = currentPhase.duration
        currentRep = 1
        
        // Set total reps based on session data
        if let session = sessionData {
            totalReps = session.sprintSets.first?.reps ?? 4
            print("📚 Session Library: Loaded Week \(session.week), Day \(session.day), Level \(session.level)")
            print("📚 Sprint Configuration: \(totalReps) reps at \(session.sprintSets.first?.distance ?? 40) yards")
        }
        
        // Reset tracking arrays
        completedReps = []
        drillsCompleted = 0
        stridesCompleted = 0
        
        // Voice coaching and haptics
        announcePhaseStart()
        provideHapticFeedback(type: .start)
        
        // Start phase timer
        startPhaseTimer()
    }
    
    private func stopSprintCoachWorkout() {
        print("🏃‍♂️ Sprint Coach: Stopping automated workout")
        
        // Clean up timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        phaseTimer = nil
        workoutTimer = nil
        
        // Voice coaching and haptics
        announceWorkoutComplete()
        provideHapticFeedback(type: .complete)
    }
    
    private func pauseWorkout() {
        guard !isPaused else { return }
        
        isPaused = true
        isRunning = false
        
        // Pause timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        
        print("⏸️ Sprint Coach: Workout paused")
        announceWorkoutPaused()
        provideHapticFeedback(type: .pause)
    }
    
    private func resumeWorkout() {
        guard isPaused else { return }
        
        isPaused = false
        
        print("▶️ Sprint Coach: Workout resumed")
        announceWorkoutResumed()
        provideHapticFeedback(type: .resume)
        
        // Resume appropriate timer based on phase
        if currentPhase == .sprints && sprintTime > 0 {
            startGPSStopwatch(for: currentPhase)
        } else {
            startPhaseTimer()
        }
    }
    
    private func skipToNext() {
        print("⏭️ Sprint Coach: Skipping to next stage")
        
        // Voice coaching and haptics
        announcePhaseSkipped()
        provideHapticFeedback(type: .transition)
        
        // Move to next phase
        advanceToNextPhase()
    }
    
    // MARK: - 6-Phase Automation Logic
    
    private func startPhaseTimer() {
        phaseTimer?.invalidate()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.phaseTimeRemaining > 0 {
                    self.phaseTimeRemaining -= 1
                    
                    // Voice cues at specific intervals
                    self.checkForVoiceCues()
                } else {
                    self.advanceToNextPhase()
                }
            }
        }
    }
    
    private func advanceToNextPhase() {
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        
        let nextPhase = getNextPhase()
        
        // Voice coaching and haptics for phase transition
        announcePhaseComplete()
        provideHapticFeedback(type: .transition)
        
        currentPhase = nextPhase
        phaseTimeRemaining = currentPhase.duration
        
        // Reset phase-specific state
        if currentPhase == .sprints {
            currentRep = 1
            sprintTime = 0.0
            currentSpeed = 0.0
            currentDistance = 0.0
        }
        
        // Announce new phase
        announcePhaseStart()
        
        if currentPhase == .completed {
            completeWorkout()
        } else {
            startPhaseTimer()
        }
    }
    
    private func getNextPhase() -> WorkoutPhase {
        switch currentPhase {
        case .warmup: return .stretch
        case .stretch: return .drill
        case .drill: return .strides
        case .strides: return .plyometrics
        case .plyometrics: return .sprints
        case .sprints:
            if currentRep < totalReps {
                return .resting
            } else {
                return .cooldown
            }
        case .resting: return .sprints
        case .cooldown: return .completed
        case .completed: return .completed
        }
    }
    
    private func startGPSStopwatch(for phase: WorkoutPhase) {
        workoutTimer?.invalidate()
        isRunning = true
        isGPSStopwatchActive = true
        sprintTime = 0.0
        currentDistance = 0.0
        
        // Get target distance based on phase and session data
        let targetDistance = getTargetDistance(for: phase)
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.sprintTime += 0.1
                
                // Simulate GPS data with realistic progression
                self.currentSpeed = self.generateRealisticSpeed(for: phase, time: self.sprintTime)
                self.currentDistance = self.sprintTime * (self.currentSpeed * 1.467) * 1.09361 // Convert to yards
                
                // GPS Auto-stop at target distance
                if self.currentDistance >= Double(targetDistance) {
                    self.stopGPSStopwatch(for: phase)
                }
            }
        }
        
        announceGPSStopwatchStart(for: phase)
        provideHapticFeedback(type: .sprintStart)
    }
    
    private func stopGPSStopwatch(for phase: WorkoutPhase) {
        workoutTimer?.invalidate()
        isRunning = false
        isGPSStopwatchActive = false
        
        // Record the rep data
        let repData = RepData(
            type: getRepType(for: phase),
            rep: getCurrentRepNumber(for: phase),
            distance: Int(currentDistance),
            time: sprintTime,
            speed: currentSpeed,
            timestamp: Date()
        )
        completedReps.append(repData)
        
        // Voice coaching and haptics
        announceRepComplete(repData: repData, phase: phase)
        provideHapticFeedback(type: .sprintComplete)
        
        // Update phase-specific counters
        updatePhaseProgress(for: phase)
        
        // Determine next action based on phase
        handlePhaseProgression(for: phase)
    }
    
    private func getTargetDistance(for phase: WorkoutPhase) -> Int {
        guard let session = sessionData else { return 40 }
        
        switch phase {
        case .drill:
            return session.drillSets.first?.distance ?? 20
        case .strides:
            return session.strideSets.first?.distance ?? 20
        case .plyometrics:
            // Get current plyometric exercise distance
            let plyoIndex = plyometricsCompleted
            if plyoIndex < session.plyometricSets.count {
                let distance = session.plyometricSets[plyoIndex].distance
                return distance > 0 ? distance : 10 // Default 10 yards for height-based exercises
            }
            return 10
        case .sprints:
            return session.sprintSets.first?.distance ?? 40
        default:
            return 40
        }
    }
    
    private func generateRealisticSpeed(for phase: WorkoutPhase, time: Double) -> Double {
        switch phase {
        case .drill:
            // Moderate pace for drills
            return Double.random(in: 8.0...12.0)
        case .strides:
            // Progressive acceleration for strides
            let maxSpeed = 18.0
            let acceleration = min(time * 2.0, maxSpeed)
            return acceleration + Double.random(in: -1.0...1.0)
        case .plyometrics:
            // Explosive power movements - short bursts of high speed
            let maxSpeed = 20.0
            let explosiveAcceleration = min(time * 4.0, maxSpeed)
            return explosiveAcceleration + Double.random(in: -1.5...1.5)
        case .sprints:
            // Maximum effort for sprints
            let maxSpeed = 25.0
            let acceleration = min(time * 3.0, maxSpeed)
            return acceleration + Double.random(in: -2.0...2.0)
        default:
            return Double.random(in: 10.0...15.0)
        }
    }
    
    private func getRepType(for phase: WorkoutPhase) -> RepData.RepType {
        switch phase {
        case .drill: return .drill
        case .strides: return .stride
        case .plyometrics: return .plyometric
        case .sprints: return .sprint
        default: return .sprint
        }
    }
    
    private func getCurrentRepNumber(for phase: WorkoutPhase) -> Int {
        switch phase {
        case .drill: return drillsCompleted + 1
        case .strides: return stridesCompleted + 1
        case .plyometrics: return plyometricsCompleted + 1
        case .sprints: return currentRep
        default: return 1
        }
    }
    
    private func updatePhaseProgress(for phase: WorkoutPhase) {
        switch phase {
        case .drill:
            drillsCompleted += 1
        case .strides:
            stridesCompleted += 1
        case .plyometrics:
            plyometricsCompleted += 1
        case .sprints:
            currentRep += 1
        default:
            break
        }
    }
    
    private func handlePhaseProgression(for phase: WorkoutPhase) {
        guard let session = sessionData else { return }
        
        switch phase {
        case .drill:
            let totalDrillSets = session.drillSets.reduce(0) { $0 + $1.reps }
            if drillsCompleted < totalDrillSets {
                // Start 1-minute rest between drill sets
                startRestPeriod(duration: 60, message: "1-minute rest between drill sets")
            } else {
                // Move to next phase
                advanceToNextPhase()
            }
            
        case .strides:
            let totalStrides = session.strideSets.first?.reps ?? 3
            if stridesCompleted < totalStrides {
                // Start 2-minute rest between strides
                startRestPeriod(duration: 120, message: "2-minute rest between strides")
            } else {
                // Move to next phase
                advanceToNextPhase()
            }
            
        case .plyometrics:
            let totalPlyometrics = session.plyometricSets.count
            if plyometricsCompleted < totalPlyometrics {
                // Get rest time for current plyometric exercise
                let currentPlyoSet = session.plyometricSets[plyometricsCompleted - 1]
                let restTime = currentPlyoSet.restTime
                startRestPeriod(duration: restTime, message: "Rest between plyometric exercises")
            } else {
                // Move to next phase
                advanceToNextPhase()
            }
            
        case .sprints:
            if currentRep <= totalReps {
                // Start rest period based on session data
                let restTime = session.sprintSets.first?.restTime ?? 180
                startRestPeriod(duration: restTime, message: "Rest period between sprints")
            } else {
                // Move to cooldown
                advanceToNextPhase()
            }
            
        default:
            break
        }
    }
    
    private func startRestPeriod(duration: Int, message: String) {
        currentPhase = .resting
        phaseTimeRemaining = duration
        
        print("🗣️ Voice Coach: \(message)")
        announceRestPeriod()
        
        startPhaseTimer()
    }
    
    private func stopSprintTimer() {
        workoutTimer?.invalidate()
        isRunning = false
        
        // Voice coaching and haptics
        announceSprintComplete(time: sprintTime)
        provideHapticFeedback(type: .sprintComplete)
        
        currentRep += 1
        
        if currentRep <= totalReps {
            // Start rest period
            currentPhase = .resting
            phaseTimeRemaining = 180 // 3 minutes rest
            announceRestPeriod()
            startPhaseTimer()
        } else {
            // Move to cooldown
            advanceToNextPhase()
        }
    }
    
    private func completeWorkout() {
        currentPhase = .completed
        
        // Final voice coaching and haptics
        announceWorkoutComplete()
        provideHapticFeedback(type: .complete)
        
        // Show completion sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showCompletionSheet = true
        }
    }
    
    // MARK: - Voice Coaching System
    
    private func announcePhaseStart() {
        let message = "Starting \(currentPhase.title). \(getPhaseInstructions())"
        print("🗣️ Voice Coach: \(message)")
        // TODO: Integrate with actual voice synthesis
    }
    
    private func announcePhaseComplete() {
        print("🗣️ Voice Coach: \(currentPhase.title) complete. Great job!")
    }
    
    private func announcePhaseSkipped() {
        print("🗣️ Voice Coach: Skipping to next phase")
    }
    
    private func announceWorkoutPaused() {
        print("🗣️ Voice Coach: Workout paused. Take your time.")
    }
    
    private func announceWorkoutResumed() {
        print("🗣️ Voice Coach: Resuming workout. Let's go!")
    }
    
    private func announceGPSStopwatchStart(for phase: WorkoutPhase) {
        switch phase {
        case .drill:
            print("🗣️ Voice Coach: Drill \(drillsCompleted + 1). GPS stopwatch active. Focus on form!")
        case .strides:
            print("🗣️ Voice Coach: Stride \(stridesCompleted + 1) of 3. Build up to 70% effort. GPS tracking...")
        case .plyometrics:
            if let session = sessionData, plyometricsCompleted < session.plyometricSets.count {
                let exercise = session.plyometricSets[plyometricsCompleted]
                print("🗣️ Voice Coach: \(exercise.name) - \(exercise.reps) reps. Explosive power! GPS tracking...")
            } else {
                print("🗣️ Voice Coach: Plyometric exercise. Explosive power! GPS tracking...")
            }
        case .sprints:
            let distance = sessionData?.sprintSets.first?.distance ?? 40
            print("🗣️ Voice Coach: Sprint \(currentRep) of \(totalReps) at \(distance) yards. Ready... Set... Go!")
        default:
            print("🗣️ Voice Coach: GPS stopwatch started")
        }
    }
    
    private func announceRepComplete(repData: RepData, phase: WorkoutPhase) {
        let timeString = String(format: "%.2f", repData.time)
        let speedString = String(format: "%.1f", repData.speed)
        
        switch phase {
        case .drill:
            print("🗣️ Voice Coach: Drill complete! Time: \(timeString)s, Speed: \(speedString) mph. Great form!")
        case .strides:
            print("🗣️ Voice Coach: Stride complete! Time: \(timeString)s, Speed: \(speedString) mph. Nice acceleration!")
        case .plyometrics:
            print("🗣️ Voice Coach: Plyometric complete! Time: \(timeString)s, Speed: \(speedString) mph. Explosive power!")
        case .sprints:
            print("🗣️ Voice Coach: Sprint complete! Time: \(timeString)s, Speed: \(speedString) mph. Excellent effort!")
        default:
            print("🗣️ Voice Coach: Rep complete! Time: \(timeString) seconds")
        }
    }
    
    private func announceSprintStart() {
        print("🗣️ Voice Coach: Sprint \(currentRep) of \(totalReps). Ready... Set... Go!")
    }
    
    private func announceSprintComplete(time: Double) {
        print("🗣️ Voice Coach: Sprint complete! Time: \(String(format: "%.2f", time)) seconds")
    }
    
    private func announceRestPeriod() {
        print("🗣️ Voice Coach: Rest period. Recover for the next sprint.")
    }
    
    private func announceWorkoutComplete() {
        print("🗣️ Voice Coach: Workout complete! Excellent work today!")
    }
    
    private func checkForVoiceCues() {
        // Provide time-based voice cues
        switch phaseTimeRemaining {
        case 60:
            print("🗣️ Voice Coach: One minute remaining")
        case 30:
            print("🗣️ Voice Coach: Thirty seconds left")
        case 10:
            print("🗣️ Voice Coach: Ten seconds")
        case 5:
            print("🗣️ Voice Coach: Five")
        case 4:
            print("🗣️ Voice Coach: Four")
        case 3:
            print("🗣️ Voice Coach: Three")
        case 2:
            print("🗣️ Voice Coach: Two")
        case 1:
            print("🗣️ Voice Coach: One")
        default:
            break
        }
    }
    
    private func getPhaseInstructions() -> String {
        switch currentPhase {
        case .warmup:
            return "Light jog to prepare your body. Keep it easy and relaxed."
        case .stretch:
            return "Dynamic stretches to activate your muscles. Focus on leg swings and high knees."
        case .drill:
            return "Technical drills for form and mechanics. Quality over speed."
        case .strides:
            return "Progressive acceleration runs. Build up to 70% effort."
        case .plyometrics:
            return "Explosive power exercises. Focus on maximum force production."
        case .sprints:
            return "Maximum effort sprints. Give it everything you've got!"
        case .resting:
            return "Active recovery. Walk it off and prepare for the next sprint."
        case .cooldown:
            return "Light movement and stretching to help your body recover."
        case .completed:
            return "Session complete!"
        }
    }
    
    // MARK: - Haptic Feedback System
    
    private func provideHapticFeedback(type: HapticType) {
        #if os(iOS)
        switch type {
        case .start:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .pause:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .resume:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .transition:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .sprintStart:
            // Triple haptic for sprint start
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    generator.impactOccurred()
                }
            }
        case .sprintComplete:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .complete:
            // Celebration haptic pattern
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.notificationOccurred(.success)
            }
        }
        #endif
        
        print("📳 Haptic: \(type)")
    }
    
    enum HapticType {
        case start, pause, resume, transition, sprintStart, sprintComplete, complete
    }
    
    // MARK: - Rep Log Helper Methods
    
    private func getRepColor(for type: RepData.RepType) -> Color {
        switch type {
        case .drill: return .indigo
        case .stride: return .purple
        case .plyometric: return .red
        case .sprint: return .yellow
        }
    }
    
    private func getRestTimeDisplay(for repData: RepData) -> String {
        guard let session = sessionData else { return "--" }
        
        switch repData.type {
        case .drill: return "1:00"
        case .stride: return "2:00"
        case .plyometric:
            // Get rest time from plyometric sets
            if let plyoSet = session.plyometricSets.first {
                let restTime = plyoSet.restTime
                let minutes = restTime / 60
                let seconds = restTime % 60
                return String(format: "%d:%02d", minutes, seconds)
            }
            return "1:30"
        case .sprint:
            let restTime = session.sprintSets.first?.restTime ?? 180
            let minutes = restTime / 60
            let seconds = restTime % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func getRemainingReps(session: SessionData) -> [(Int, Int)] {
        var remaining: [(Int, Int)] = []
        
        // Add remaining drills
        let totalDrillReps = session.drillSets.reduce(0) { $0 + $1.reps }
        for rep in (drillsCompleted + 1)...totalDrillReps {
            remaining.append((rep, 20))
        }
        
        // Add remaining strides
        let totalStrideReps = session.strideSets.first?.reps ?? 3
        for rep in (stridesCompleted + 1)...totalStrideReps {
            remaining.append((rep, 20))
        }
        
        // Add remaining plyometrics
        let totalPlyometrics = session.plyometricSets.count
        for rep in (plyometricsCompleted + 1)...totalPlyometrics {
            let distance = session.plyometricSets[rep - 1].distance
            remaining.append((rep, distance > 0 ? distance : 10))
        }
        
        // Add remaining sprints
        let sprintDistance = session.sprintSets.first?.distance ?? 40
        for rep in currentRep...totalReps {
            remaining.append((rep, sprintDistance))
        }
        
        return remaining
    }
    
    // MARK: - Helper Methods for Session Selection
    
    private func getCurrentWeek() -> Int {
        // Get current week from user progress or default to week 1
        // TODO: Integrate with actual progress tracking system
        return UserDefaults.standard.integer(forKey: "currentWeek") == 0 ? 1 : UserDefaults.standard.integer(forKey: "currentWeek")
    }
    
    private func getCurrentDay() -> Int {
        // Get current day from user progress or default to day 1
        // TODO: Integrate with actual progress tracking system
        return UserDefaults.standard.integer(forKey: "currentDay") == 0 ? 1 : UserDefaults.standard.integer(forKey: "currentDay")
    }
    
    private func getUserLevel() -> Int {
        // Convert user level from onboarding to 1-7 scale for session library
        let levelString = UserDefaults.standard.string(forKey: "userLevel") ?? "Intermediate"
        return convertLevelStringToInt(levelString)
    }
    
    private func getUserFrequency() -> Int {
        // Get training frequency (1-7 days) from onboarding
        return UserDefaults.standard.integer(forKey: "trainingFrequency") == 0 ? 3 : UserDefaults.standard.integer(forKey: "trainingFrequency")
    }
    
    private func getUserPreferences() -> UserPreferences? {
        // Get user preferences from onboarding and session history
        let favoriteTypes = UserDefaults.standard.stringArray(forKey: "favoriteSessionTypes") ?? []
        let preferredDistances = UserDefaults.standard.array(forKey: "preferredDistances") as? [Int] ?? []
        let avoidedExercises = UserDefaults.standard.stringArray(forKey: "avoidedExercises") ?? []
        let intensityPreference = UserDefaults.standard.double(forKey: "intensityPreference") == 0 ? 0.5 : UserDefaults.standard.double(forKey: "intensityPreference")
        
        return UserPreferences(
            favoriteSessionTypes: favoriteTypes,
            preferredDistances: preferredDistances,
            avoidedExercises: avoidedExercises,
            intensityPreference: intensityPreference
        )
    }
    
    private func getCompletedSessionHistory() -> [Int] {
        // Get completed session IDs from session history
        return UserDefaults.standard.array(forKey: "completedSessionIDs") as? [Int] ?? []
    }
    
    /// Convert onboarding level string to 1-7 integer scale for session library
    private func convertLevelStringToInt(_ levelString: String) -> Int {
        switch levelString {
        case "Beginner": return 2
        case "Intermediate": return 4
        case "Advanced": return 6
        case "Elite": return 7
        default: return 3 // Default to lower intermediate
        }
    }
}

// MARK: - Enhanced Models for Session Library Integration

struct LibrarySession {
    let id: Int
    let name: String
    let distance: Int
    let reps: Int
    let rest: Int
    let focus: String
    let level: String
    let sessionType: String
    let variety: Double
    let difficulty: Double
}

struct UserPreferences {
    let favoriteSessionTypes: [String]
    let preferredDistances: [Int]
    let avoidedExercises: [String]
    let intensityPreference: Double // 0.0-1.0
}

enum TrainingPhase {
    case foundation      // Weeks 1-3: Basic acceleration and mechanics
    case acceleration    // Weeks 4-6: Advanced acceleration development
    case maxVelocity     // Weeks 7-9: Maximum velocity development
    case peakPerformance // Weeks 10-12: Peak performance and speed endurance
}

// MARK: - Session Library Integration Extensions

extension MainProgramWorkoutView.SessionData {
    
    /// Helper methods for intelligent session selection
    static func getLevelString(from level: Int) -> String {
        switch level {
        case 1...2: return "Beginner"
        case 3...4: return "Intermediate"
        case 5...6: return "Advanced"
        case 7: return "Elite"
        default: return "Intermediate"
        }
    }
    
    static func getTrainingPhase(for week: Int) -> TrainingPhase {
        switch week {
        case 1...3: return .foundation
        case 4...6: return .acceleration
        case 7...9: return .maxVelocity
        case 10...12: return .peakPerformance
        default: return .foundation
        }
    }
    
    /// Select optimal session from 240+ library based on multiple factors
    static func selectOptimalSession(
        week: Int,
        day: Int,
        level: String,
        phase: TrainingPhase,
        preferences: UserPreferences?,
        completedSessions: [Int]
    ) -> LibrarySession {
        
        // Filter sessions by level and phase
        let availableSessions = getSessionsForPhase(phase: phase, level: level)
        
        // Remove recently completed sessions to ensure variety
        let varietySessions = availableSessions.filter { !completedSessions.contains($0.id) }
        
        // Apply user preferences if available
        let preferredSessions = applyUserPreferences(sessions: varietySessions, preferences: preferences)
        
        // Select based on week progression and engagement optimization
        let optimalSession = selectByWeekProgression(sessions: preferredSessions, week: week, day: day)
        
        return optimalSession ?? createFallbackSession(level: level, week: week)
    }
    
    static func getSessionsForPhase(phase: TrainingPhase, level: String) -> [LibrarySession] {
        // Import session library from SessionLibrary.swift
        let allSessions = sessionLibrary
        
        // Filter sessions by level first
        let levelSessions = allSessions.filter { $0.level == level }
        
        // Filter by training phase focus
        let phaseSessions = levelSessions.filter { session in
            let focus = session.focus.lowercased()
            
            switch phase {
            case .foundation:
                return focus.contains("acceleration") || 
                       focus.contains("accel") || 
                       focus.contains("drive") ||
                       focus.contains("starts") ||
                       session.distance <= 30
                       
            case .acceleration:
                return focus.contains("acceleration") || 
                       focus.contains("accel") || 
                       focus.contains("drive") ||
                       focus.contains("progression") ||
                       (session.distance >= 20 && session.distance <= 50)
                       
            case .maxVelocity:
                return focus.contains("max velocity") || 
                       focus.contains("max speed") || 
                       focus.contains("speed") ||
                       focus.contains("velocity") ||
                       focus.contains("flying") ||
                       session.distance >= 40
                       
            case .peakPerformance:
                return focus.contains("peak") || 
                       focus.contains("top-end") || 
                       focus.contains("repeat") ||
                       focus.contains("endurance") ||
                       focus.contains("max velocity") ||
                       session.distance >= 50
            }
        }
        
        // Convert SprintSessionTemplate to LibrarySession format
        return phaseSessions.map { session in
            LibrarySession(
                id: session.id,
                name: session.name,
                distance: session.distance,
                reps: session.reps,
                rest: session.rest,
                focus: session.focus,
                level: session.level,
                sessionType: session.sessionType.rawValue,
                variety: calculateSessionVariety(session: session),
                difficulty: calculateSessionDifficulty(session: session, phase: phase)
            )
        }
    }
    
    /// Calculate variety score for a session based on its characteristics
    static func calculateSessionVariety(session: SprintSessionTemplate) -> Double {
        var variety = 0.5 // Base variety
        
        // Higher variety for unique distances
        if session.distance % 10 != 0 { variety += 0.1 } // Non-standard distances
        if session.name.contains("Pyramid") { variety += 0.2 } // Pyramid sessions are more varied
        if session.name.contains("Flying") { variety += 0.15 } // Flying runs add variety
        if session.name.contains("Split") { variety += 0.1 } // Split runs add variety
        
        return min(variety, 1.0)
    }
    
    /// Calculate difficulty score for a session based on distance, reps, and phase
    static func calculateSessionDifficulty(session: SprintSessionTemplate, phase: TrainingPhase) -> Double {
        var difficulty = 0.2 // Base difficulty
        
        // Distance contribution (0.1-0.4)
        difficulty += min(Double(session.distance) / 250.0, 0.4)
        
        // Reps contribution (0.1-0.3)
        difficulty += min(Double(session.reps) / 20.0, 0.3)
        
        // Rest time (less rest = higher difficulty) (0.0-0.2)
        difficulty += max(0.2 - (Double(session.rest) / 1000.0), 0.0)
        
        // Phase adjustment
        switch phase {
        case .foundation: difficulty *= 0.8 // Easier in foundation
        case .acceleration: difficulty *= 1.0 // Standard
        case .maxVelocity: difficulty *= 1.1 // Slightly harder
        case .peakPerformance: difficulty *= 1.2 // Hardest phase
        }
        
        return min(difficulty, 1.0)
    }
    
    static func applyUserPreferences(sessions: [LibrarySession], preferences: UserPreferences?) -> [LibrarySession] {
        guard let prefs = preferences else { return sessions }
        
        return sessions.filter { session in
            // Filter by preferred session types
            if !prefs.favoriteSessionTypes.isEmpty {
                return prefs.favoriteSessionTypes.contains(session.sessionType)
            }
            
            // Filter by preferred distances
            if !prefs.preferredDistances.isEmpty {
                return prefs.preferredDistances.contains(session.distance)
            }
            
            return true
        }
    }
    
    static func selectByWeekProgression(sessions: [LibrarySession], week: Int, day: Int) -> LibrarySession? {
        // Progressive difficulty selection based on week
        let targetDifficulty = min(0.2 + (Double(week) * 0.07), 1.0) // Progressive from 0.2 to 1.0
        
        // Find session closest to target difficulty
        return sessions.min { abs($0.difficulty - targetDifficulty) < abs($1.difficulty - targetDifficulty) }
    }
    
    static func createFallbackSession(level: String, week: Int) -> LibrarySession {
        return LibrarySession(
            id: 999,
            name: "Adaptive Sprint Session",
            distance: 30 + (week * 2),
            reps: 4 + (week / 3),
            rest: 120,
            focus: "Progressive Training",
            level: level,
            sessionType: "Sprint",
            variety: 0.5,
            difficulty: 0.5
        )
    }
    
    /// Calculate session variety score based on completed sessions
    static func calculateSessionVariety(completedSessions: [Int]) -> Double {
        if completedSessions.isEmpty { return 1.0 }
        
        // Higher variety score for more diverse session history
        let uniqueSessions = Set(completedSessions).count
        let totalSessions = completedSessions.count
        
        return min(Double(uniqueSessions) / Double(totalSessions) * 1.5, 1.0)
    }
    
    /// Calculate engagement score based on session characteristics
    static func calculateEngagementScore(session: LibrarySession, week: Int) -> Double {
        var score = 0.5 // Base score
        
        // Boost score for variety
        score += session.variety * 0.3
        
        // Boost score for appropriate difficulty progression
        let expectedDifficulty = min(0.2 + (Double(week) * 0.07), 1.0)
        let difficultyMatch = 1.0 - abs(session.difficulty - expectedDifficulty)
        score += difficultyMatch * 0.2
        
        return min(score, 1.0)
    }
    
    /// Generate adaptive drill sets based on selected session
    static func generateAdaptiveDrillSets(for level: Int, session: LibrarySession) -> [MainProgramWorkoutView.DrillSet] {
        let baseReps = min(3 + level, 8)
        let sessionFocus = session.focus.lowercased()
        
        if sessionFocus.contains("acceleration") {
            return [
                MainProgramWorkoutView.DrillSet(name: "A-Skips", reps: baseReps, distance: 20),
                MainProgramWorkoutView.DrillSet(name: "Wall Drill", reps: baseReps, distance: 0),
                MainProgramWorkoutView.DrillSet(name: "Falling Starts", reps: baseReps, distance: 10)
            ]
        } else if sessionFocus.contains("max velocity") {
            return [
                MainProgramWorkoutView.DrillSet(name: "High Knees", reps: baseReps, distance: 20),
                MainProgramWorkoutView.DrillSet(name: "Butt Kicks", reps: baseReps, distance: 20),
                MainProgramWorkoutView.DrillSet(name: "Fast Leg", reps: baseReps, distance: 20)
            ]
        } else {
            return [
                MainProgramWorkoutView.DrillSet(name: "High Knees", reps: baseReps, distance: 20),
                MainProgramWorkoutView.DrillSet(name: "Butt Kicks", reps: baseReps, distance: 20),
                MainProgramWorkoutView.DrillSet(name: "A-Skips", reps: baseReps, distance: 20)
            ]
        }
    }
    
    /// Generate adaptive stride sets based on selected session
    static func generateAdaptiveStrideSets(for level: Int, session: LibrarySession) -> [MainProgramWorkoutView.StrideSet] {
        let reps = session.distance > 40 ? 4 : 3 // More strides for longer sessions
        return [MainProgramWorkoutView.StrideSet(reps: reps, distance: 20, restTime: 120)]
    }
    
    /// Generate adaptive plyometric sets based on selected session
    static func generateAdaptivePlyometricSets(for level: Int, session: LibrarySession) -> [MainProgramWorkoutView.PlyometricSet] {
        let baseReps = min(2 + level, 6)
        let sessionFocus = session.focus.lowercased()
        
        if sessionFocus.contains("acceleration") {
            return [
                MainProgramWorkoutView.PlyometricSet(name: "Broad Jumps", reps: baseReps, distance: 10, restTime: 90),
                MainProgramWorkoutView.PlyometricSet(name: "Single Leg Bounds", reps: baseReps, distance: 15, restTime: 90),
                MainProgramWorkoutView.PlyometricSet(name: "Split Jumps", reps: baseReps, distance: 0, restTime: 90)
            ]
        } else {
            return [
                MainProgramWorkoutView.PlyometricSet(name: "Box Jumps", reps: baseReps, distance: 0, restTime: 120),
                MainProgramWorkoutView.PlyometricSet(name: "Depth Jumps", reps: baseReps, distance: 0, restTime: 120),
                MainProgramWorkoutView.PlyometricSet(name: "Lateral Bounds", reps: baseReps, distance: 12, restTime: 90)
            ]
        }
    }
    
    /// Convert library session to sprint sets
    static func convertToSessionSprintSets(from session: LibrarySession, week: Int, level: Int) -> [MainProgramWorkoutView.SessionSprintSet] {
        let restTime = max(session.rest, 120) // Minimum 2 minutes rest
        let intensity = calculateIntensity(week: week, level: level)
        
        return [
            MainProgramWorkoutView.SessionSprintSet(
                reps: session.reps,
                distance: session.distance,
                restTime: restTime,
                intensity: intensity
            )
        ]
    }
    
    static func calculateIntensity(week: Int, level: Int) -> String {
        let weekIntensity = min(week * 8 + 70, 100) // 78-100% based on week
        let levelBonus = level * 2 // Higher levels get slightly more intensity
        let totalIntensity = min(weekIntensity + levelBonus, 100)
        return "\(totalIntensity)%"
    }
}

// MARK: - Supporting Views

struct PhaseProgressIndicator: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainProgramWorkoutView.WorkoutPhase.allCases.dropLast(), id: \.self) { phase in
                RoundedRectangle(cornerRadius: 2)
                    .fill(getPhaseColor(phase))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func getPhaseColor(_ phase: MainProgramWorkoutView.WorkoutPhase) -> Color {
        let currentIndex = MainProgramWorkoutView.WorkoutPhase.allCases.firstIndex(of: currentPhase) ?? 0
        let phaseIndex = MainProgramWorkoutView.WorkoutPhase.allCases.firstIndex(of: phase) ?? 0
        
        if phaseIndex <= currentIndex {
            return phase.color
        } else {
            return Color.white.opacity(0.3)
        }
    }
}

struct TimerDisplayView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let phaseTimeRemaining: Int
    let restTimeRemaining: Int
    let sprintTime: Double
    let isRunning: Bool
    let currentSpeed: Double
    let currentDistance: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Timer Circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .stroke(currentPhase.color, lineWidth: 8)
                    .frame(width: 180, height: 180)
                    .opacity(isRunning ? 1.0 : 0.6)
                
                VStack(spacing: 4) {
                    if currentPhase == .resting {
                        Text(formatTime(restTimeRemaining))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("REST")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else if currentPhase == .drill || currentPhase == .strides || currentPhase == .sprints {
                        Text(String(format: "%.2f", sprintTime))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text(isRunning ? "RUNNING" : "READY")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text(formatTime(phaseTimeRemaining))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("TIME")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            // GPS Data (for drill, strides, sprints)
            if currentPhase == .drill || currentPhase == .strides || currentPhase == .sprints {
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("SPEED")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%.1f", currentSpeed))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("mph")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%.0f", currentDistance))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("yards")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct PhaseControlsView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let isPaused: Bool
    let onPause: () -> Void
    let onPlay: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Pause/Play Button - Wave AI automated control
            Button(action: isPaused ? onPlay : onPause) {
                HStack(spacing: 8) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 120, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isPaused ? Color.green : Color.orange)
                )
            }
            
            // Forward Button - Skip to next phase/rep
            Button(action: onForward) {
                HStack(spacing: 8) {
                    Text("Forward")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: 120, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.blue.opacity(0.8))
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// RepLogView is now provided by WaveAIRepLogView.swift to avoid duplication

struct WorkoutCompletionView: View {
    let session: MainProgramWorkoutView.WorkoutSession?
    let allTimes: [Double]
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Completion Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 8) {
                    Text("Workout Complete!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Great job on your sprint training session")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Results Summary
                if !allTimes.isEmpty {
                    VStack(spacing: 12) {
                        Text("Session Results")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 32) {
                            VStack(spacing: 4) {
                                Text("BEST TIME")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(String(format: "%.2f", allTimes.min() ?? 0.0))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            }
                            
                            VStack(spacing: 4) {
                                Text("TOTAL REPS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(allTimes.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                }
                
                // Data Update Confirmation
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Data Updated Successfully")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 16) {
                            Label("History", systemImage: "clock.arrow.circlepath")
                            Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            Label("Share Ready", systemImage: "square.and.arrow.up")
                            if let bestTime = allTimes.min(), bestTime < 5.0 {
                                Label("Leaderboard", systemImage: "trophy.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                Button("Done") {
                    onDismiss()
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.green)
                )
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Performance Card
struct PerformanceCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Navigation Action Card
struct NavigationActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - New UI Components

struct PhaseCard: View {
    let duration: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(duration)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .orange : .white.opacity(0.8))
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
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
        case 4: return "PLYO"
        case 5: return "SPRINT"
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
        case .plyometrics: return 4
        case .sprints: return 5
        case .cooldown: return 6
        default: return 0
        }
    }
}

// MARK: - Phase-Specific UI Components

struct SessionOverviewUI: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let onStartWorkout: () -> Void
    
    private func getSessionInfo() -> (week: Int, day: Int, duration: Int) {
        if let session = sessionData {
            return (week: session.week, day: session.day, duration: 47)
        }
        return (week: 1, day: 1, duration: 47)
    }
    
    private func getMainPhaseTitle() -> String {
        if let session = sessionData, let firstSet = session.sprintSets.first {
            return "\(firstSet.distance)yd Sprint + Rest"
        }
        return "30yd Sprint + Rest"
    }
    
    private func getMainPhaseSubtitle() -> String {
        if let session = sessionData {
            return "(\(session.sprintSets.count) Reps)"
        }
        return "(3 Reps)"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Session Header
            VStack(spacing: 8) {
                Text("SPRINT COACH 40")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
                
                let sessionInfo = getSessionInfo()
                Text("WEEK \(sessionInfo.week) - DAY \(sessionInfo.day) / \(sessionInfo.duration) Min")
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
                    isActive: true,
                    isCompleted: false
                )
                
                PhaseCard(
                    duration: "6 Min",
                    title: getMainPhaseTitle(),
                    subtitle: getMainPhaseSubtitle(),
                    isActive: false,
                    isCompleted: false
                )
                
                PhaseCard(
                    duration: "5 Min",
                    title: "Cool",
                    subtitle: "Down",
                    isActive: false,
                    isCompleted: false
                )
            }
            .padding(.horizontal, 20)
            
            // C25K-style 7-Phase Progress Bar
            ProgressBar(currentPhase: sessionData?.sprintSets.isEmpty == false ? .warmup : .warmup, totalPhases: 7)
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
            
            // Main Action Button
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
        }
    }
}

struct StridesPhaseUI: View {
    var body: some View {
        VStack(spacing: 32) {
            // Timer Circle
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Color.purple, lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.purple)
                    
                    Text("0.00")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("READY")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Build-Up Strides Info
            VStack(spacing: 12) {
                Text("Build-Up Strides")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("3×20 Yard • 70% Effort • Auto-detected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Start moving to begin stride timing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Control Buttons
            HStack(spacing: 32) {
                Button(action: {}) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
            }
            .padding(.bottom, 30)
        }
    }
}

struct SprintsPhaseUI: View {
    var body: some View {
        VStack(spacing: 32) {
            
            // Timer Circle with Speed/Distance
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Color.green, lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("0.00")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("READY")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Speed and Distance Display
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("SPEED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Text("0.0")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("mph")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 4) {
                    Text("DISTANCE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Text("0.0")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("yards")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Control Buttons
            HStack(spacing: 32) {
                Button(action: {}) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
            }
            .padding(.bottom, 30)
        }
    }
}

struct PlyometricsPhaseUI: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let onStartWorkout: () -> Void
    
    var body: some View {
        SessionOverviewUI(sessionData: sessionData, onStartWorkout: onStartWorkout)
    }
}

struct CompletionPhaseUI: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let onStartWorkout: () -> Void
    
    var body: some View {
        SessionOverviewUI(sessionData: sessionData, onStartWorkout: onStartWorkout)
    }
}

struct AdaptiveRepLogView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let completedReps: [MainProgramWorkoutView.RepData]
    let currentRep: Int
    let totalReps: Int
    let sessionData: MainProgramWorkoutView.SessionData?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rep Log")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if currentPhase == .strides || currentPhase == .sprints {
                    Text("Live Workout Report")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("18:12")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 20)
            
            // Phase-specific content
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("REP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 40)
                    
                    Text("YDS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 50)
                    
                    Text("TIME")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 80)
                    
                    Text("REST")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 60)
                }
                .padding(.horizontal, 20)
                
                // Phase-specific rows
                if currentPhase == .strides {
                    // Strides section
                    VStack(spacing: 8) {
                        HStack {
                            Text("STRIDES")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.purple)
                            Spacer()
                            Text("Build-up • 70% effort")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.purple.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        
                        ForEach(1...3, id: \.self) { rep in
                            RepRow(rep: rep, distance: 20, time: nil, isActive: rep == currentRep)
                        }
                    }
                } else if currentPhase == .sprints {
                    // Sprints section
                    VStack(spacing: 8) {
                        HStack {
                            Text("SPRINTS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                            Spacer()
                            Text("Maximum effort • 100%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        
                        ForEach(1...4, id: \.self) { rep in
                            RepRow(rep: rep, distance: 30, time: rep == 1 ? "..." : nil, isActive: rep == currentRep, isCompleted: rep == 1)
                        }
                    }
                } else {
                    // Default view for other phases - show actual session data
                    if let session = sessionData {
                        ForEach(Array(session.sprintSets.enumerated()), id: \.offset) { index, sprintSet in
                            RepRow(
                                rep: index + 1,
                                distance: sprintSet.distance,
                                time: nil,
                                isActive: false
                            )
                        }
                    } else {
                        // Fallback if no session data
                        ForEach(1...totalReps, id: \.self) { rep in
                            RepRow(rep: rep, distance: 20, time: nil, isActive: false)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct RepRow: View {
    let rep: Int
    let distance: Int
    let time: String?
    let isActive: Bool
    let isCompleted: Bool
    
    init(rep: Int, distance: Int, time: String? = nil, isActive: Bool = false, isCompleted: Bool = false) {
        self.rep = rep
        self.distance = distance
        self.time = time
        self.isActive = isActive
        self.isCompleted = isCompleted
    }
    
    var body: some View {
        HStack {
            Text("\(rep)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40)
            
            Text("\(distance)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50)
            
            Text(time ?? "--")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 80)
            
            Text("--")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCompleted ? Color.yellow.opacity(0.2) : (isActive ? Color.white.opacity(0.1) : Color.clear))
        )
    }
}

// MARK: - Legacy Extensions (Removed for Sprint Coach Integration)
// All legacy manual workout methods have been replaced by Sprint Coach automation

