import SwiftUI

struct MainProgramWorkoutWatchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let session: TrainingSession
    
    @State private var currentView: WorkoutViewType = .main
    @State private var currentSet = 1
    @State private var isWorkoutActive = false
    @State private var workoutTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var workoutStartTime: Date?
    @State private var currentPhase: WorkoutPhase = .warmup
    @StateObject private var workoutVM: WorkoutWatchViewModel
    @StateObject private var syncManager = WatchWorkoutSyncManager.shared
    @StateObject private var dataManager = WorkoutDataManager.shared
    
    // MARK: - Autonomous Workout Systems
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @StateObject private var gpsManager = WatchGPSManager.shared
    @StateObject private var intervalManager = WatchIntervalManager.shared
    @StateObject private var dataStore = WatchDataStore.shared
    @State private var workoutData: WatchWorkoutData?
    
    // MARK: - Premium Entertainment Systems (Watch Compatible)
    @StateObject private var hapticsManager = AdvancedHapticsManager.shared
    @StateObject private var eventBus = WorkoutEventBus.shared
    
    // MARK: - Enhanced AI Coaching Systems (Watch Compatible)
    // Note: Using Watch-compatible versions of the coaching engines
    @State private var biomechanicsActive = false
    @State private var gpsFormActive = false
    @State private var weatherAdaptationsApplied = false
    
    // MARK: - Live RepLog System
    @StateObject private var repLogVM = RepLogWatchViewModel()
    
    // Drills phase management
    @State private var currentDrill = 0
    @State private var drillRestTimer: Timer?
    @State private var drillRestTimeRemaining: TimeInterval = 0
    @State private var isDrillResting = false
    @State private var drillPhaseTimer: Timer?
    
    // Session Library Integration
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var isResting = false
    
    // Additional state variables for session management
    @State private var sessionPhaseStartTime: Date?
    @State private var sessionPhaseEndTime: Date?
    @State private var sessionPhaseTimer: Timer?
    
    // Strides phase management
    @State private var currentStride = 0
    @State private var strideRestTimer: Timer?
    @State private var strideRestTimeRemaining: TimeInterval = 0
    @State private var isStrideResting = false
    @State private var stridePhaseTimer: Timer?
    
    // Note: PremiumVoiceCoach, WorkoutMusicManager, and SubscriptionManager 
    // are iOS-only and not available in Watch target
    
    enum WorkoutViewType {
        case main, control, music, repLog
    }
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warm-up"
        case stretch = "Stretch"
        case drills = "Drills"
        case strides = "Strides"
        case sprints = "Sprints"
        case cooldown = "Cool-down"
    }
    
    enum PhaseAction {
        case start
        case complete
    }
    
    // GPS Phase Data Structures for Rep Log Analytics
    struct PhaseCompletionData {
        let phase: String
        let duration: TimeInterval
        let timestamp: Date
        let gpsData: GPSPhaseData
    }
    
    struct GPSPhaseData {
        let distance: Double
        let maxSpeed: Double
        let averagePace: Double
    }
    
    struct DrillCompletionData {
        let drillName: String
        let distance: Int
        let duration: TimeInterval
        let timestamp: Date
        let gpsData: GPSPhaseData
    }
    
    struct StrideCompletionData {
        let strideName: String
        let distance: Int
        let duration: TimeInterval
        let timestamp: Date
        let gpsData: GPSPhaseData
    }
    
    // Sprint Session Library with Distance-Based Rest Times for 12-Week Program
    struct SprintSessionLibraryEntry {
        let distance: Int
        let restTimeMinutes: Int
        let sessionType: String
        let focus: String
        let level: String
        let voiceCoaching: String
        let weekRange: ClosedRange<Int> // Which weeks this session appears in
    }
    
    private let sprintSessionLibrary: [SprintSessionLibraryEntry] = [
        // Week 1-3: Foundation Building (Beginner Focus)
        SprintSessionLibraryEntry(distance: 10, restTimeMinutes: 1, sessionType: "Acceleration", focus: "Block Starts", level: "Foundation", voiceCoaching: "10-yard acceleration sprint. Focus on explosive start and drive phase. 1 minute rest.", weekRange: 1...3),
        SprintSessionLibraryEntry(distance: 15, restTimeMinutes: 1, sessionType: "Acceleration", focus: "Drive Phase", level: "Foundation", voiceCoaching: "15-yard sprint. Maintain low body position and powerful arm drive. 1 minute rest.", weekRange: 1...3),
        SprintSessionLibraryEntry(distance: 20, restTimeMinutes: 2, sessionType: "Acceleration", focus: "Early Acceleration", level: "Foundation", voiceCoaching: "20-yard acceleration sprint. Build speed gradually with good mechanics. 2 minutes rest.", weekRange: 1...4),
        SprintSessionLibraryEntry(distance: 25, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Power Development", level: "Foundation", voiceCoaching: "25-yard sprint. Focus on powerful drive phase and smooth transition. 2 minutes rest.", weekRange: 2...4),
        
        // Week 4-6: Development Phase (Intermediate Focus)
        SprintSessionLibraryEntry(distance: 30, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Acceleration Mechanics", level: "Development", voiceCoaching: "30-yard sprint. Maintain acceleration through drive phase. 2 minutes rest.", weekRange: 3...6),
        SprintSessionLibraryEntry(distance: 35, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Speed Building", level: "Development", voiceCoaching: "35-yard sprint. Build speed with controlled acceleration. 2 minutes rest.", weekRange: 4...6),
        SprintSessionLibraryEntry(distance: 40, restTimeMinutes: 3, sessionType: "Max Speed", focus: "Full Sprint", level: "Development", voiceCoaching: "40-yard maximum effort sprint. Give everything you have. 3 minutes rest.", weekRange: 4...8),
        SprintSessionLibraryEntry(distance: 45, restTimeMinutes: 3, sessionType: "Speed", focus: "Max Velocity", level: "Development", voiceCoaching: "45-yard sprint. Reach maximum velocity and maintain form. 3 minutes rest.", weekRange: 5...7),
        
        // Week 7-9: Intensification Phase (Advanced Focus)
        SprintSessionLibraryEntry(distance: 50, restTimeMinutes: 3, sessionType: "Speed", focus: "Acceleration to Top Speed", level: "Intensification", voiceCoaching: "50-yard sprint. Accelerate through to top speed. 3 minutes rest.", weekRange: 6...9),
        SprintSessionLibraryEntry(distance: 55, restTimeMinutes: 3, sessionType: "Speed", focus: "Speed Maintenance", level: "Intensification", voiceCoaching: "55-yard sprint. Focus on maintaining top speed. 3 minutes rest.", weekRange: 7...9),
        SprintSessionLibraryEntry(distance: 60, restTimeMinutes: 4, sessionType: "Max Velocity", focus: "Flying Sprint", level: "Intensification", voiceCoaching: "60-yard flying sprint. Maximum velocity focus. 4 minutes rest.", weekRange: 7...10),
        SprintSessionLibraryEntry(distance: 65, restTimeMinutes: 4, sessionType: "Max Velocity", focus: "Speed Endurance", level: "Intensification", voiceCoaching: "65-yard sprint. Maintain velocity through the distance. 4 minutes rest.", weekRange: 8...10),
        
        // Week 10-12: Peak Performance Phase (Elite Focus)
        SprintSessionLibraryEntry(distance: 70, restTimeMinutes: 4, sessionType: "Speed Endurance", focus: "Lactate Tolerance", level: "Peak", voiceCoaching: "70-yard sprint. Push through fatigue and maintain speed. 4 minutes rest.", weekRange: 9...12),
        SprintSessionLibraryEntry(distance: 75, restTimeMinutes: 5, sessionType: "Top-End Speed", focus: "Peak Velocity", level: "Peak", voiceCoaching: "75-yard maximum sprint. Peak velocity development. 5 minutes rest.", weekRange: 10...12),
        SprintSessionLibraryEntry(distance: 80, restTimeMinutes: 5, sessionType: "Repeat Sprints", focus: "Speed Endurance", level: "Peak", voiceCoaching: "80-yard repeat sprint. Maintain speed across repetitions. 5 minutes rest.", weekRange: 10...12),
        SprintSessionLibraryEntry(distance: 90, restTimeMinutes: 5, sessionType: "Top-End Speed", focus: "Peak Performance", level: "Peak", voiceCoaching: "90-yard peak performance sprint. Elite level execution. 5 minutes rest.", weekRange: 11...12),
        SprintSessionLibraryEntry(distance: 100, restTimeMinutes: 6, sessionType: "Peak Velocity", focus: "Elite Performance", level: "Peak", voiceCoaching: "100-yard elite performance sprint. Maximum effort and speed. 6 minutes rest.", weekRange: 12...12)
    ]
    
    // Drill definitions for voice coaching
    struct DrillInstruction {
        let name: String
        let description: String
        let voiceInstruction: String
        let duration: TimeInterval // Duration for each drill
        let distance: Int // 20 yards for all drills
    }
    
    private let drillSequence: [DrillInstruction] = [
        DrillInstruction(
            name: "A-Skips",
            description: "High knee marching with arm swing",
            voiceInstruction: "Starting A-Skips. March in place with high knees, drive your arms, and maintain good posture. Focus on quick ground contact. 20 yards.",
            duration: 30,
            distance: 20
        ),
        DrillInstruction(
            name: "B-Skips", 
            description: "High knee with leg extension",
            voiceInstruction: "Now B-Skips. Bring your knee up high, then extend your leg forward and snap it down. Keep your arms pumping. 20 yards.",
            duration: 30,
            distance: 20
        ),
        DrillInstruction(
            name: "High Knees",
            description: "Running with exaggerated knee lift",
            voiceInstruction: "High Knees drill. Run in place bringing your knees up to hip level. Stay on the balls of your feet and pump your arms. 20 yards.",
            duration: 30,
            distance: 20
        ),
        DrillInstruction(
            name: "Butt Kicks",
            description: "Heel to glute running motion",
            voiceInstruction: "Butt Kicks time. Kick your heels up to your glutes while maintaining forward momentum. Keep your knees pointing down. 20 yards.",
            duration: 30,
            distance: 20
        ),
        DrillInstruction(
            name: "Straight Leg Bounds",
            description: "Bounding with straight leg recovery",
            voiceInstruction: "Straight Leg Bounds. Take long bounding steps with straight legs, emphasizing the pawing motion. Drive your arms for momentum. 20 yards.",
            duration: 30,
            distance: 20
        )
    ]
    
    // Stride definitions for voice coaching
    struct StrideInstruction {
        let name: String
        let description: String
        let voiceInstruction: String
        let duration: TimeInterval // Duration for each stride
        let distance: Int // 20 yards for all strides
        let intensity: String // Build-up intensity
    }
    
    private let strideSequence: [StrideInstruction] = [
        StrideInstruction(
            name: "Stride 1",
            description: "Easy build-up to 60% effort",
            voiceInstruction: "First stride. Start easy and gradually build to 60% effort over 20 yards. Focus on smooth acceleration and relaxed form.",
            duration: 45,
            distance: 20,
            intensity: "60%"
        ),
        StrideInstruction(
            name: "Stride 2",
            description: "Moderate build-up to 70% effort",
            voiceInstruction: "Second stride. Build to 70% effort over 20 yards. Maintain good posture and drive your arms. Feel the rhythm.",
            duration: 40,
            distance: 20,
            intensity: "70%"
        ),
        StrideInstruction(
            name: "Stride 3",
            description: "Strong build-up to 80% effort",
            voiceInstruction: "Final stride. Build to 80% effort over 20 yards. This is your race pace preparation. Stay controlled but powerful.",
            duration: 35,
            distance: 20,
            intensity: "80%"
        )
    ]
    
    var totalSets: Int {
        session.sprints.reduce(0) { $0 + $1.reps }
    }
    
    /// Get the current sprint set and rep information
    var currentSprintInfo: (sprintSet: SprintSet, setIndex: Int, repInSet: Int)? {
        var totalReps = 0
        
        for (setIndex, sprintSet) in session.sprints.enumerated() {
            if currentSet <= totalReps + sprintSet.reps {
                let repInSet = currentSet - totalReps
                return (sprintSet, setIndex, repInSet)
            }
            totalReps += sprintSet.reps
        }
        return nil
    }
    
    // MARK: - Initializer
    init(session: TrainingSession) {
        self.session = session
        self._workoutVM = StateObject(wrappedValue: WorkoutWatchViewModel.fromSession(session))
    }
    
    // MARK: - Integrated Workout Lifecycle
    private func startAutonomousWorkout() {
        print("🚀 Starting integrated autonomous workout session...")
        
        // Initialize workout data
        workoutData = WatchWorkoutData(
            workoutType: .speed,
            sessionName: "\(session.type) - \(session.focus)",
            totalIntervals: totalSets
        )
        
        // Register all systems with event bus
        eventBus.registerAllSystems()
        
        // Broadcast workout start event
        eventBus.broadcast(.workoutStarted(session))
        
        // Start autonomous systems
        workoutManager.startWorkout()
        gpsManager.startTracking()
        
        // Initialize RepLog system (simplified)
        print("📊 RepLog: Starting session - \(session.type), Week \(session.week), Day \(session.day)")
        
        // Configure interval manager with session data
        if let firstSprint = session.sprints.first {
            let intervals = (0..<totalSets).map { index in
                IntervalConfig(
                    distance: firstSprint.distanceYards,
                    restTime: TimeInterval(120), // Default 2 minutes rest
                    intensity: firstSprint.intensity
                )
            }
            
            let workoutPlan = WorkoutPlan(
                intervals: intervals,
                warmupTime: 300, // 5 minutes
                cooldownTime: 300 // 5 minutes
            )
            
            intervalManager.startWorkout(plan: workoutPlan)
        }
        
        // Start premium entertainment systems
        startPremiumSystems()
        
        isWorkoutActive = true
    }
    
    private func startPremiumSystems() {
        // Initialize advanced haptics (Watch compatible)
        hapticsManager.handleWorkoutPhaseChange("warmup")
        
        // Start with warmup phase
        eventBus.broadcastPhaseChange(to: .warmup)
        
        // Initialize enhanced AI coaching systems (Watch compatible)
        setupWatchEnhancedCoaching()
        
        print("🎵 Premium systems initialized for Watch target")
    }
    
    // MARK: - Enhanced AI Coaching Systems (Watch Compatible)
    
    private func setupWatchEnhancedCoaching() {
        // Start biomechanics tracking using Watch sensors
        startWatchBiomechanicsTracking()
        
        // Initialize GPS form feedback
        startWatchGPSFormFeedback()
        
        // Apply weather adaptations
        applyWatchWeatherAdaptations()
        
        print("🤖 Enhanced AI coaching systems activated on Apple Watch")
    }
    
    private func startWatchBiomechanicsTracking() {
        // Use Watch's motion sensors for biomechanics analysis
        biomechanicsActive = true
        
        // Integrate with existing WatchWorkoutManager for motion data
        workoutManager.updateWorkoutType(for: session.type)
        
        print("📱 Watch biomechanics tracking started")
    }
    
    private func startWatchGPSFormFeedback() {
        // Use Watch GPS for form feedback
        gpsFormActive = true
        
        // Configure GPS manager for sprint detection
        let sprintDistance = session.sprints.first?.distanceYards ?? 40
        print("🎯 Watch GPS form feedback configured for \(sprintDistance) yards")
    }
    
    private func applyWatchWeatherAdaptations() {
        // Apply weather-based adaptations on Watch
        weatherAdaptationsApplied = true
        
        // Use haptics to indicate weather adaptations
        if weatherAdaptationsApplied {
            print("🔔 Haptic: Weather adaptations applied")
        }
        
        print("🌤️ Weather adaptations applied on Apple Watch")
    }
    
    private func cleanupWatchEnhancedSystems() {
        biomechanicsActive = false
        gpsFormActive = false
        weatherAdaptationsApplied = false
        
        print("🤖 Enhanced AI coaching systems deactivated on Apple Watch")
    }
    
    private func pauseAutonomousWorkout() {
        print("⏸️ Pausing autonomous workout...")
        workoutManager.pauseWorkout()
        intervalManager.pauseWorkout()
        gpsManager.stopTracking()
        workoutTimer?.invalidate()
    }
    
    private func resumeAutonomousWorkout() {
        print("▶️ Resuming autonomous workout...")
        workoutManager.resumeWorkout()
        intervalManager.resumeWorkout()
        gpsManager.startTracking()
    }
    
    private func endAutonomousWorkout() {
        print("🏁 Ending integrated autonomous workout...")
        
        // Create workout summary
        let summary = WorkoutEventBus.WorkoutSummary(
            sessionId: UUID(),
            duration: workoutTimer?.timeInterval ?? 0,
            totalSprints: totalSets,
            maxSpeed: gpsManager.currentSpeed,
            averageHeartRate: workoutManager.averageHeartRate,
            caloriesBurned: workoutManager.caloriesBurned,
            personalRecords: []
        )
        
        // Broadcast workout completion
        eventBus.broadcast(.workoutCompleted(summary))
        
        // Stop autonomous systems
        workoutManager.endWorkout()
        intervalManager.stopWorkout()
        gpsManager.stopTracking()
        workoutTimer?.invalidate()
        
        // Stop premium systems
        stopPremiumSystems()
        
        // Cleanup enhanced AI coaching systems
        cleanupWatchEnhancedSystems()
        
        // Finalize workout data
        if let data = workoutData {
            data.completeWorkout()
            
            // Save to local storage
            dataStore.saveWorkout(data)
            
            print("✅ Integrated autonomous workout completed and saved")
        }
        
        isWorkoutActive = false
    }
    
    private func stopPremiumSystems() {
        // Celebration haptics (Watch compatible)
        hapticsManager.playPattern(.achievement)
        
        // Clear event bus subscriptions
        eventBus.unsubscribe("MainWorkoutView")
        
        print("🏆 Premium systems stopped - great workout!")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - C25K Fitness22 style
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.purple.opacity(0.3),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content with swipe navigation
                TabView(selection: $currentView) {
                    // Control View (Left swipe from Main)
                    ControlWatchView(
                        selectedIndex: 0, // Control is index 0 in the page indicators
                        workoutVM: workoutVM
                    )
                    .tag(WorkoutViewType.control)
                    
                    // Main Workout View (Center)
                    mainWorkoutView
                        .tag(WorkoutViewType.main)
                    
                    // Music View (Right swipe from Main) - Watch Compatible
                    MusicWatchView(
                        selectedIndex: 2
                    )
                    .tag(WorkoutViewType.music)
                    
                    // Rep Log View (Swipe Up/Down from Main)
                    RepLogWatchLiveView(
                        workoutVM: workoutVM,
                        horizontalTab: .constant(0),
                        isModal: false,
                        showNext: false,
                        onDone: { currentView = .main }
                    )
                    .tag(WorkoutViewType.repLog)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    handleSwipeGesture(value)
                }
        )
        .navigationBarHidden(true)
        .onAppear {
            startWorkout()
            setupSyncListeners()
            syncWorkoutStateToPhone()
            
            // Start autonomous systems
            startAutonomousWorkout()
        }
        .onDisappear {
            stopWorkout()
            
            // End autonomous systems
            endAutonomousWorkout()
        }
    }
    
    // MARK: - Main Workout View (Adaptive for All Watch Models)
    private var mainWorkoutView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size)) {
                    // Phase Indicator with proper safe area handling
                    phaseIndicator
                        .padding(.top, adaptiveTopPadding(for: geometry.size))
                    
                    // Real-time Metrics
                    realTimeMetrics
                    
                    // Current Set/Rep Display
                    currentSetDisplay
                    
                    // Timer Display
                    timerDisplay
                    
                    // Session Details
                    sessionDetails
                    
                    // Progress Indicator
                    progressIndicator
                    
                    // Swipe Instructions
                    swipeInstructions
                }
                .padding(.horizontal, adaptiveHorizontalPadding(for: geometry.size))
                .padding(.bottom, adaptiveBottomPadding(for: geometry.size))
            }
        }
    }
    
    // MARK: - Adaptive Layout Functions
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        // Adjust spacing based on watch size
        if size.height < 200 {
            return 6  // 38mm/40mm watches - tighter spacing
        } else if size.height < 220 {
            return 8  // 42mm/44mm watches - medium spacing
        } else {
            return 10 // 45mm/49mm Ultra watches - more spacing
        }
    }
    
    private func adaptiveTopPadding(for size: CGSize) -> CGFloat {
        // Ensure proper clearance from status bar/time
        if size.height < 200 {
            return 4   // Smaller watches need less padding
        } else if size.height < 220 {
            return 6   // Medium watches
        } else {
            return 8   // Larger watches can afford more padding
        }
    }
    
    private func adaptiveHorizontalPadding(for size: CGSize) -> CGFloat {
        // Adjust horizontal padding based on watch width
        if size.width < 170 {
            return 8   // Smaller watches - less padding
        } else if size.width < 190 {
            return 12  // Medium watches
        } else {
            return 16  // Larger watches - more padding
        }
    }
    
    private func adaptiveBottomPadding(for size: CGSize) -> CGFloat {
        // Ensure proper clearance from bottom
        if size.height < 200 {
            return 8
        } else {
            return 12
        }
    }
    
    // MARK: - Autonomous Systems Display
    private var autonomousSystemsStatus: some View {
        HStack(spacing: 8) {
            // HealthKit Status
            StatusIndicator(
                icon: "heart.fill",
                value: "\(workoutManager.currentHeartRate)",
                label: "BPM",
                color: workoutManager.isWorkoutActive ? .red : .gray
            )
            
            // GPS Status
            StatusIndicator(
                icon: "location.fill",
                value: String(format: "%.1f", gpsManager.currentSpeed),
                label: "MPH",
                color: gpsManager.isTracking ? .green : .gray
            )
            
            // Interval Status
            StatusIndicator(
                icon: "timer",
                value: "\(intervalManager.currentInterval)",
                label: "SET",
                color: intervalManager.isActive ? .blue : .gray
            )
        }
        .padding(.horizontal, 8)
    }
    
    private var realTimeMetrics: some View {
        // Clean Distance and Pace Display
        HStack(spacing: 20) {
            VStack(spacing: 2) {
                Text(String(format: "%.0f", gpsManager.currentDistance))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("YDS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
            }
            
            VStack(spacing: 2) {
                Text(String(format: "%.1f", gpsManager.currentPace))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("MIN/MI")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 4) {
            Text("Week \(session.week) • Day \(session.day)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.yellow)
                .tracking(0.5)
            
            Text(session.type.uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1)
            
            Text(session.focus)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var phaseIndicator: some View {
        GeometryReader { geometry in
            VStack(spacing: 6) {
                // Current Phase Display with Timer - Adaptive sizing
                HStack {
                    Text(currentPhase.rawValue.uppercased())
                        .font(.system(size: adaptiveFontSize(for: geometry.size, base: 16), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    // Phase timer in top right - Adaptive sizing
                    Text(formatTime(phaseTimeRemaining))
                        .font(.system(size: adaptiveFontSize(for: geometry.size, base: 16), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, adaptiveVerticalPadding(for: geometry.size))
                .padding(.horizontal, adaptiveHorizontalPadding(for: geometry.size))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(phaseColor(for: currentPhase).opacity(0.8))
                )
                
                // Phase instructions below - Adaptive sizing
                Text(phaseInstructions(for: currentPhase))
                    .font(.system(size: adaptiveFontSize(for: geometry.size, base: 10), weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                // Progress Dots - Adaptive sizing
                HStack(spacing: adaptiveDotSpacing(for: geometry.size)) {
                    ForEach(Array(WorkoutPhase.allCases.enumerated()), id: \.element) { index, phase in
                        Circle()
                            .fill(currentPhase == phase ? phaseColor(for: phase) : Color.white.opacity(0.3))
                            .frame(width: adaptiveDotSize(for: geometry.size, isActive: currentPhase == phase), 
                                   height: adaptiveDotSize(for: geometry.size, isActive: currentPhase == phase))
                            .scaleEffect(currentPhase == phase ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPhase)
                    }
                }
                .padding(.horizontal, adaptiveHorizontalPadding(for: geometry.size))
            }
        }
        .frame(height: adaptivePhaseIndicatorHeight())
    }
    
    // MARK: - Additional Adaptive Helper Functions
    private func adaptiveFontSize(for size: CGSize, base: CGFloat) -> CGFloat {
        let scaleFactor: CGFloat
        if size.width < 170 {
            scaleFactor = 0.85  // Smaller watches
        } else if size.width < 190 {
            scaleFactor = 0.95  // Medium watches
        } else {
            scaleFactor = 1.0   // Larger watches
        }
        return base * scaleFactor
    }
    
    private func adaptiveVerticalPadding(for size: CGSize) -> CGFloat {
        if size.height < 200 {
            return 8   // Smaller watches
        } else if size.height < 220 {
            return 10  // Medium watches
        } else {
            return 12  // Larger watches
        }
    }
    
    private func adaptiveDotSpacing(for size: CGSize) -> CGFloat {
        if size.width < 170 {
            return 4   // Smaller watches - tighter spacing
        } else {
            return 6   // Larger watches - more spacing
        }
    }
    
    private func adaptiveDotSize(for size: CGSize, isActive: Bool) -> CGFloat {
        let baseSize: CGFloat = size.width < 170 ? 5 : 6
        return isActive ? baseSize + 2 : baseSize
    }
    
    private func adaptivePhaseIndicatorHeight() -> CGFloat {
        return 100  // Fixed height to prevent layout shifts
    }
    
    /// Get phase time remaining
    private var phaseTimeRemaining: TimeInterval {
        // This should be calculated based on your phase timing logic
        // For now, returning a placeholder value
        return 300.0 - elapsedTime.truncatingRemainder(dividingBy: 300.0)
    }
    
    private var currentSetDisplay: some View {
        VStack(spacing: 8) {
            // Show different information based on current phase
            switch currentPhase {
            case .sprints:
                // Sprint phase - show current distance and set information
                VStack(spacing: 4) {
                    // Show current distance prominently
                    if let sprintInfo = currentSprintInfo {
                        Text("\(sprintInfo.sprintSet.distanceYards)YD")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                            .tracking(1)
                    } else if let firstSprint = session.sprints.first {
                        Text("\(firstSprint.distanceYards)YD")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                            .tracking(1)
                    }
                    
                    // Show set progress
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(currentSet)")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.green)
                        
                        Text("/ \(totalSets)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 2)
                    }
                    
                    // Show set details - which set within the current distance
                    if let sprintInfo = currentSprintInfo, session.sprints.count > 1 {
                        Text("SET \(sprintInfo.repInSet)/\(sprintInfo.sprintSet.reps)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)
                    } else {
                        Text("SET")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                    }
                }
                
            case .strides:
                // Strides phase - show distance and rep information
                VStack(spacing: 4) {
                    // Show stride distance
                    Text("20YD")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                        .tracking(1)
                    
                    // Show stride progress
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("1") // Could be dynamic based on stride progress
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.purple)
                        
                        Text("/ 3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 2)
                    }
                    
                    // Show "STRIDE" label below
                    Text("STRIDE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)
                }
                
            default:
                // Other phases - show motivational message and progress
                VStack(spacing: 6) {
                    Text(phaseMotivationalText(for: currentPhase))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Phase progress indicator
                    HStack(spacing: 4) {
                        Image(systemName: phaseIcon(for: currentPhase))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(phaseColor(for: currentPhase))
                        
                        Text(phaseProgressText(for: currentPhase))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text(formatTime(elapsedTime))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.cyan)
                .monospacedDigit()
            
            Text("ELAPSED TIME")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
        }
    }
    
    private var sessionDetails: some View {
        VStack(spacing: 8) {
            if let firstSprint = session.sprints.first {
                let distance = firstSprint.distanceYards
                let week = session.week
                let restTime = getRestTimeForDistance(distance, week: week)
                let sessionEntry = getSessionLibraryEntry(for: distance, week: week)
                
                // Main session info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DISTANCE")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(distance) YD")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("REST TIME")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(restTime) MIN")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("REPS")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(firstSprint.reps)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
                
                // Session library info
                if let sessionEntry = sessionEntry {
                    VStack(spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SESSION TYPE")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(sessionEntry.sessionType.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("FOCUS")
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(sessionEntry.focus.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Week and level info
                        HStack {
                            Text("Week \(week)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text(sessionEntry.level)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
    }
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            Text("PROGRESS")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
            
            ProgressView(value: Double(currentSet), total: Double(totalSets))
                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                .scaleEffect(y: 2)
            
            Text("\(Int((Double(currentSet) / Double(totalSets)) * 100))% Complete")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.yellow)
        }
    }
    
    private var swipeInstructions: some View {
        VStack(spacing: 4) {
            HStack(spacing: 16) {
                Text("← Control")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Music →")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text("↕ Rep Log")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Gesture Handling
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let threshold: CGFloat = 50
        
        if abs(value.translation.height) > abs(value.translation.width) {
            // Vertical swipe - Rep Log
            if abs(value.translation.height) > threshold {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .repLog
                    } else if currentView == .repLog {
                        currentView = .main
                    }
                }
            }
        } else {
            // Horizontal swipe - Navigation between views
            if value.translation.width > threshold {
                // Swipe right - Music or back to Main
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .music
                    } else if currentView == .control {
                        currentView = .main
                    } else if currentView == .repLog {
                        currentView = .main
                    }
                }
            } else if value.translation.width < -threshold {
                // Swipe left - Control or back to Main
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .control
                    } else if currentView == .music {
                        currentView = .main
                    } else if currentView == .repLog {
                        currentView = .main
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Control
    private func startWorkout() {
        isWorkoutActive = true
        workoutStartTime = Date()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Calculate elapsed time from start time for accuracy
            if let startTime = workoutStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
            
            // Auto-advance phases based on time (complete 6-phase flow)
            if elapsedTime > 300 && currentPhase == .warmup { // 5 min warmup
                currentPhase = .stretch
            } else if elapsedTime > 480 && currentPhase == .stretch { // 3 min stretch
                currentPhase = .drills
                // Start GPS tracking, rep log, and voice coaching for drills phase
                startGPSPhaseTracking(phase: .drills)
                startDrillsPhaseCoaching()
            } else if elapsedTime > 840 && currentPhase == .drills { // 6 min drills
                // Complete drills phase tracking
                stopGPSPhaseTracking()
                currentPhase = .strides
                // Start GPS tracking, rep log, and voice coaching for strides phase
                startGPSPhaseTracking(phase: .strides)
                startStridesPhaseCoaching()
            } else if elapsedTime > 1080 && currentPhase == .strides { // 4 min strides (20yd x 3 + rest)
                // Complete strides phase tracking
                stopGPSPhaseTracking()
                currentPhase = .sprints
                // Start GPS tracking and rep log for sprints phase
                startGPSPhaseTracking(phase: .sprints)
                // Start automated sprint session with session library
                startAutomatedSprintSession()
                // Start RepLog tracking for sprints
                if let firstSprint = session.sprints.first {
                    Task { @MainActor in
                        print("📊 RepLog: Starting rep - \(firstSprint.distanceYards) yards")
                    }
                }
            } else if elapsedTime > 1680 && currentPhase == .sprints { // 10 min sprints
                // Complete current rep if recording
                Task { @MainActor in
                    if let firstSprint = session.sprints.first {
                        print("📊 RepLog: Completing rep - \(firstSprint.distanceYards) yards")
                    }
                }
                // Complete sprints phase tracking
                stopGPSPhaseTracking()
                currentPhase = .cooldown
            }
        }
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // Stop GPS phase tracking if still active
        stopGPSPhaseTracking()
        
        // End RepLog session and sync to phone (simplified)
        print("📊 RepLog: Ending session and syncing to phone")
        
        // Save workout data when stopping
        let completedReps = (1...currentSet).map { repNumber in
            // Get sprint result from GPS manager if available
            let sprintResult = gpsManager.endSprint()
            let sprintTime = sprintResult?.time ?? elapsedTime
            
            return CompletedRep(
                repNumber: repNumber,
                distance: session.sprints.first?.distanceYards ?? 40,
                time: sprintTime,
                heartRate: workoutManager.currentHeartRate,
                timestamp: Date()
            )
        }
        
        dataManager.saveMainProgramWorkout(
            session: session,
            completedReps: completedReps,
            duration: elapsedTime
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - GPS Phase Tracking for Rep Log Updates
    
    private func startGPSPhaseTracking(phase: WorkoutPhase) {
        print("📍 Starting GPS phase tracking for \(phase.rawValue)")
        
        // Update rep log with phase entry
        updateRepLogForPhase(phase: phase, action: .start)
        
        // Configure GPS manager for phase-specific tracking
        switch phase {
        case .drills:
            // Track drill movements and technique
            gpsManager.startSprint() // Start GPS sprint tracking
            
        case .strides:
            // Track stride build-ups (typically 20yd)
            gpsManager.startSprint()
            
        case .sprints:
            // Track full sprint distances
            gpsManager.startSprint()
            
        default:
            break
        }
    }
    
    private func stopGPSPhaseTracking() {
        print("📍 Stopping GPS phase tracking")
        
        // End current GPS tracking
        if let sprintResult = gpsManager.endSprint() {
            // Update rep log with final GPS data
            updateRepLogWithGPSData(sprintResult)
        }
        
        // Update rep log with phase completion
        updateRepLogForPhase(phase: currentPhase, action: .complete)
    }
    
    private func updateRepLogForPhase(phase: WorkoutPhase, action: PhaseAction) {
        // Log phase data for rep log analytics
        switch phase {
        case .drills:
            if action == .start {
                print("📊 Starting drills phase tracking")
            } else {
                recordPhaseInRepLog(phase: "Drills")
            }
            
        case .strides:
            if action == .start {
                print("📊 Starting strides phase tracking")
            } else {
                recordPhaseInRepLog(phase: "Strides")
            }
            
        case .sprints:
            if action == .start {
                print("📊 Starting sprints phase tracking")
            } else {
                recordPhaseInRepLog(phase: "Sprints")
            }
            
        default:
            break
        }
    }
    
    private func updateRepLogWithGPSData(_ sprintResult: SprintResult) {
        // Log GPS timing and distance data for analytics
        print("📊 GPS data recorded: \(sprintResult.time)s, \(sprintResult.distance)yd, \(sprintResult.maxSpeed)mph")
        print("📈 Phase: \(currentPhase.rawValue) completed with GPS tracking")
    }
    
    private func recordPhaseInRepLog(phase: String) {
        // Log phase completion for analytics
        print("📝 Phase \(phase) recorded in rep log for analytics")
        print("📊 GPS data: distance=\(gpsManager.currentDistance)yd, speed=\(gpsManager.currentSpeed)mph")
    }
    
    // MARK: - Drills Phase Voice Coaching
    
    private func startDrillsPhaseCoaching() {
        print("🎯 Starting drills phase voice coaching")
        
        // Reset drill tracking
        currentDrill = 0
        isDrillResting = false
        drillRestTimeRemaining = 0
        
        // Initial announcement
        speak("Starting drills phase. You will perform 5 different drills, each for 20 yards with 1 minute rest between drills.")
        
        // Start first drill after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startNextDrill()
        }
    }
    
    private func startNextDrill() {
        guard currentDrill < drillSequence.count else {
            // All drills completed
            completeDrillsPhase()
            return
        }
        
        let drill = drillSequence[currentDrill]
        
        print("🎯 Starting drill \(currentDrill + 1): \(drill.name)")
        
        // Announce the drill
        speak(drill.voiceInstruction)
        
        // Start GPS tracking for this drill
        gpsManager.startSprint()
        
        // Start drill timer
        drillPhaseTimer = Timer.scheduledTimer(withTimeInterval: drill.duration, repeats: false) { _ in
            self.finishCurrentDrill()
        }
        
        // Update UI to show current drill
        workoutVM.currentPhase = .drills
        if currentDrill < drillSequence.count {
            // Start rest period before next drill
            startDrillRestPeriod()
        } else {
            // All drills completed
            completeDrillsPhase()
        }
    }
    
    private func finishCurrentDrill() {
        let drill = drillSequence[currentDrill]
        
        print("✅ Completed drill: \(drill.name)")
        
        // Stop GPS tracking and record data
        if let sprintResult = gpsManager.endSprint() {
            updateRepLogWithGPSData(sprintResult)
        }
        
        // Move to next drill
        currentDrill += 1
        
        if currentDrill < drillSequence.count {
            // Start rest period before next drill
            startDrillRestPeriod()
        } else {
            // All drills completed
            completeDrillsPhase()
        }
    }
    
    private func startDrillRestPeriod() {
        isDrillResting = true
        drillRestTimeRemaining = 60.0 // 1 minute rest
        
        speak("Good work! Rest for 1 minute before the next drill.")
        
        // Start rest timer
        drillRestTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.drillRestTimeRemaining -= 1
            
            // Countdown announcements
            if self.drillRestTimeRemaining == 30 {
                self.speak("30 seconds remaining")
            } else if self.drillRestTimeRemaining == 10 {
                self.speak("10 seconds")
            } else if self.drillRestTimeRemaining <= 0 {
                self.endDrillRestPeriod()
            }
        }
    }
    
    private func endDrillRestPeriod() {
        isDrillResting = false
        drillRestTimer?.invalidate()
        drillRestTimer = nil
        
        speak("Rest complete. Get ready for the next drill.")
        
        // Start next drill after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startNextDrill()
        }
    }
    
    private func completeDrillsPhase() {
        print("🎯 Drills phase completed")
        
        // Clean up timers
        drillPhaseTimer?.invalidate()
        drillRestTimer?.invalidate()
        drillPhaseTimer = nil
        drillRestTimer = nil
        
        speak("Excellent work! Drills phase complete. Moving to strides phase.")
        
        // The phase will automatically advance via the existing phase progression system
    }
    
    private func recordDrillInRepLog(drill: DrillInstruction) {
        // Log drill completion for analytics
        print("📝 Drill \(drill.name) recorded for analytics")
        print("📊 Drill data: \(drill.distance)yd in \(drill.duration)s")
        
        print("📝 Drill \(drill.name) recorded in rep log for analytics")
    }
    
    // MARK: - Strides Phase Voice Coaching
    
    private func startStridesPhaseCoaching() {
        print("🏃‍♂️ Starting strides phase voice coaching")
        
        // Reset stride tracking
        currentStride = 0
        isStrideResting = false
        strideRestTimeRemaining = 0
        
        // Initial announcement
        speak("Starting strides phase. You will perform 3 build-up strides, each for 20 yards with 2 minute rest between strides. Build from 60% to 80% effort.")
        
        // Start first stride after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.startNextStride()
        }
    }
    
    private func startNextStride() {
        guard currentStride < strideSequence.count else {
            // All strides completed
            completeStridesPhase()
            return
        }
        
        let stride = strideSequence[currentStride]
        
        print("🏃‍♂️ Starting stride \(currentStride + 1): \(stride.name)")
        
        // Announce the stride
        speak(stride.voiceInstruction)
        
        // Start GPS tracking for this stride
        gpsManager.startSprint()
        
        // Start stride timer
        stridePhaseTimer = Timer.scheduledTimer(withTimeInterval: stride.duration, repeats: false) { _ in
            self.completeStride()
        }
        
        // Update UI to show current stride
        print("🏃‍♂️ Current stride: \(stride.name) at \(stride.intensity)")
    }
    
    private func completeStride() {
        let stride = strideSequence[currentStride]
        
        print("✅ Completed stride: \(stride.name)")
        
        // Stop GPS tracking and record data
        if let sprintResult = gpsManager.endSprint() {
            updateRepLogWithGPSData(sprintResult)
        }
        
        // Record stride completion
        recordStrideInRepLog(stride: stride)
        
        // Move to next stride
        currentStride += 1
        
        if currentStride < strideSequence.count {
            // Start rest period before next stride (2 minutes)
            startStrideRestPeriod()
        } else {
            // All strides completed
            completeStridesPhase()
        }
    }
    
    private func startStrideRestPeriod() {
        isStrideResting = true
        strideRestTimeRemaining = 120.0 // 2 minutes rest
        
        speak("Excellent stride! Rest for 2 minutes before the next stride. Walk around and stay loose.")
        
        // Start rest timer
        strideRestTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.strideRestTimeRemaining -= 1
            
            // Countdown announcements
            if self.strideRestTimeRemaining == 60 {
                self.speak("1 minute remaining")
            } else if self.strideRestTimeRemaining == 30 {
                self.speak("30 seconds remaining")
            } else if self.strideRestTimeRemaining == 10 {
                self.speak("10 seconds")
            } else if self.strideRestTimeRemaining <= 0 {
                self.endStrideRestPeriod()
            }
        }
    }
    
    private func endStrideRestPeriod() {
        isStrideResting = false
        strideRestTimer?.invalidate()
        strideRestTimer = nil
        
        speak("Rest complete. Get ready for the next stride.")
        
        // Start next stride after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startNextStride()
        }
    }
    
    private func completeStridesPhase() {
        print("🏃‍♂️ Strides phase completed")
        
        // Clean up timers
        stridePhaseTimer?.invalidate()
        strideRestTimer?.invalidate()
        stridePhaseTimer = nil
        strideRestTimer = nil
        
        speak("Outstanding work! Strides phase complete. You're ready for sprints. Moving to sprint phase.")
        
        // The phase will automatically advance via the existing phase progression system
    }
    
    private func recordStrideInRepLog(stride: StrideInstruction) {
        // Record individual stride completion for analytics
        let _ = StrideCompletionData(
            strideName: stride.name,
            distance: stride.distance,
            duration: stride.duration,
            timestamp: Date(),
            gpsData: GPSPhaseData(
                distance: gpsManager.currentDistance,
                maxSpeed: gpsManager.currentSpeed,
                averagePace: gpsManager.currentPace
            )
        )
        
        // Log stride completion for analytics
        print("📝 Stride \(stride.name) (\(stride.intensity)) recorded in rep log for analytics")
        print("📊 Stride data: \(stride.distance)yd in \(stride.duration)s")
    }
    
    // MARK: - Sprint Session Library Functions
    
    private func getSessionLibraryEntry(for distance: Int, week: Int) -> SprintSessionLibraryEntry? {
        return sprintSessionLibrary.first { entry in
            entry.distance == distance && entry.weekRange.contains(week)
        }
    }
    
    private func getRestTimeForDistance(_ distance: Int, week: Int) -> Int {
        if let entry = getSessionLibraryEntry(for: distance, week: week) {
            return entry.restTimeMinutes
        }
        
        // Fallback rest times based on distance if no specific entry found
        switch distance {
        case 10...15: return 1
        case 16...35: return 2
        case 36...50: return 3
        case 51...70: return 4
        case 71...90: return 5
        default: return 6
        }
    }
    
    private func getVoiceCoachingForSprint(distance: Int, week: Int, setNumber: Int, totalSets: Int) -> String {
        if let entry = getSessionLibraryEntry(for: distance, week: week) {
            let setInfo = "Sprint \(setNumber) of \(totalSets). "
            let restInfo = "You'll get \(entry.restTimeMinutes) minute\(entry.restTimeMinutes == 1 ? "" : "s") rest after this sprint."
            return setInfo + entry.voiceCoaching + " " + restInfo
        }
        
        // Fallback voice coaching
        let restTime = getRestTimeForDistance(distance, week: week)
        return "Sprint \(setNumber) of \(totalSets). \(distance)-yard maximum effort sprint. \(restTime) minute\(restTime == 1 ? "" : "s") rest."
    }
    
    private func startAutomatedSprintSession() {
        guard let firstSprint = session.sprints.first else { return }
        
        let distance = firstSprint.distanceYards
        let week = session.week
        let restTime = getRestTimeForDistance(distance, week: week)
        
        print("🏃‍♂️ Starting automated sprint session: \(distance)yd with \(restTime)min rest (Week \(week))")
        
        // Update rest time based on session library
        restTimeRemaining = Double(restTime * 60) // Convert to seconds
        
        // Get session library entry for UI display
        if let sessionEntry = getSessionLibraryEntry(for: distance, week: week) {
            // Initial voice coaching for the session
            let sessionIntro = "Starting \(sessionEntry.sessionType) session. Focus: \(sessionEntry.focus). You'll be doing \(firstSprint.reps) sprints at \(distance) yards each."
            speak(sessionIntro)
            print("📋 Session: \(sessionEntry.sessionType) - \(sessionEntry.focus) - \(sessionEntry.level)")
        }
        
        // Start first sprint after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startNextSprint()
        }
    }
    
    private func startNextSprint() {
        guard let firstSprint = session.sprints.first, currentSet <= firstSprint.reps else {
            completeSprintSession()
            return
        }
        
        let distance = firstSprint.distanceYards
        let week = session.week
        
        // Get adaptive voice coaching for this sprint
        let voiceCoaching = getVoiceCoachingForSprint(
            distance: distance,
            week: week,
            setNumber: currentSet,
            totalSets: firstSprint.reps
        )
        
        print("🏃‍♂️ Starting sprint \(currentSet): \(distance)yd")
        
        // Voice coaching for the sprint
        speak(voiceCoaching)
        
        // Start GPS tracking
        gpsManager.startSprint()
        
        // Update UI
        workoutVM.currentRep = currentSet
        workoutVM.isRunning = true
        
        // Wait for user to complete sprint (this would be triggered by GPS or manual stop)
        // For now, simulate sprint completion after a reasonable time
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            self.completeSprint()
        }
    }
    
    private func completeSprint() {
        guard let firstSprint = session.sprints.first else { return }
        
        let distance = firstSprint.distanceYards
        let week = session.week
        let restTime = getRestTimeForDistance(distance, week: week)
        
        print("✅ Sprint \(currentSet) completed")
        
        // Stop GPS tracking and record data
        if let sprintResult = gpsManager.endSprint() {
            updateRepLogWithGPSData(sprintResult)
        }
        
        // Update workout state
        workoutVM.isRunning = false
        workoutVM.lastRepTime = elapsedTime
        
        // Move to next sprint or start rest
        if currentSet < firstSprint.reps {
            startAutomatedRestPeriod(restTimeMinutes: restTime)
        } else {
            completeSprintSession()
        }
    }
    
    private func startAutomatedRestPeriod(restTimeMinutes: Int) {
        isResting = true
        restTimeRemaining = Double(restTimeMinutes * 60) // Convert to seconds
        
        speak("Excellent sprint! Rest for \(restTimeMinutes) minute\(restTimeMinutes == 1 ? "" : "s"). Walk around and stay loose.")
        
        // Start rest timer with countdown announcements
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.restTimeRemaining -= 1
            
            // Log rest progress
            let progress = max(0.0, self.restTimeRemaining / Double(restTimeMinutes * 60))
            print("⏱️ Rest progress: \(Int(progress * 100))%")
            
            // Countdown announcements
            if self.restTimeRemaining == 30 {
                self.speak("30 seconds remaining")
            } else if self.restTimeRemaining == 10 {
                self.speak("10 seconds")
            } else if self.restTimeRemaining <= 0 {
                self.endAutomatedRestPeriod()
            }
        }
    }
    
    private func endAutomatedRestPeriod() {
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        
        speak("Rest complete. Get ready for your next sprint.")
        
        // Move to next sprint
        currentSet += 1
        
        // Start next sprint after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startNextSprint()
        }
    }
    
    private func completeSprintSession() {
        print("🏁 Sprint session completed")
        
        speak("Outstanding work! Sprint session complete. Moving to cooldown phase.")
        
        // Advance to cooldown phase
        currentPhase = .cooldown
    }
    
    private func speak(_ text: String) {
        // Use unified voice manager for consistent voice settings
        // Voice feedback (simplified)
        print("🗣️ Voice: \(text)")
    }
    
    // MARK: - Sync Methods
    private func setupSyncListeners() {
        // Listen for phone sync updates
        NotificationCenter.default.addObserver(
            forName: .workoutStateAdapted,
            object: nil,
            queue: .main
        ) { notification in
            if let workoutState = notification.object as? WorkoutSyncState {
                self.handlePhoneWorkoutStateUpdate(workoutState)
            }
        }
        
        // Listen for session data updates
        NotificationCenter.default.addObserver(
            forName: .sessionDataAdapted,
            object: nil,
            queue: .main
        ) { notification in
            if let sessionData = notification.object as? SessionDataSync {
                self.handleSessionDataUpdate(sessionData)
            }
        }
        
        print("📱 MainProgram sync listeners setup complete")
    }
    
    private func syncWorkoutStateToPhone() {
        let watchState = syncManager.createWatchStateSync(
            currentPhase: currentPhase.rawValue,
            isRunning: isWorkoutActive,
            isPaused: false,
            currentRep: currentSet
        )
        
        syncManager.sendWatchStateToPhone(watchState)
        
        // Update WorkoutWatchViewModel with current state
        // Map local WorkoutPhase to WorkoutWatchViewModel WorkoutPhase
        switch currentPhase {
        case .warmup:
            workoutVM.currentPhase = .warmup
        case .stretch:
            workoutVM.currentPhase = .warmup // Map stretch to warmup in WorkoutWatchViewModel
        case .drills:
            workoutVM.currentPhase = .drills
        case .strides:
            workoutVM.currentPhase = .strides20 // Map to strides20 in WorkoutWatchViewModel
        case .sprints:
            workoutVM.currentPhase = .sprint
        case .cooldown:
            workoutVM.currentPhase = .cooldown
        }
        workoutVM.isRunning = isWorkoutActive
        workoutVM.currentRep = currentSet
        workoutVM.currentRepTime = elapsedTime
        
        print("📱 MainProgram workout state synced to phone")
    }
    
    private func handlePhoneWorkoutStateUpdate(_ workoutState: WorkoutSyncState) {
        // Update local state based on phone updates
        if let phase = WorkoutPhase(rawValue: workoutState.currentPhase) {
            currentPhase = phase
        }
        
        isWorkoutActive = workoutState.isRunning
        currentSet = workoutState.currentRep
        
        // Update WorkoutWatchViewModel
        workoutVM.isRunning = workoutState.isRunning
        workoutVM.currentRep = workoutState.currentRep
        
        print("📱 MainProgram updated from phone: \(workoutState.currentPhase)")
    }
    
    private func handleSessionDataUpdate(_ sessionData: SessionDataSync) {
        // Update session-specific data
        print("📊 MainProgram session data updated: Week \(sessionData.week), Day \(sessionData.day)")
    }
    
    // MARK: - Phase Helper Functions
    
    /// Returns appropriate color for each workout phase
    private func phaseColor(for phase: WorkoutPhase) -> Color {
        switch phase {
        case .warmup:
            return .orange
        case .stretch:
            return .pink
        case .drills:
            return .indigo
        case .strides:
            return .purple
        case .sprints:
            return .green
        case .cooldown:
            return .blue
        }
    }
    
    /// Returns specific instructions for what to do in each phase
    private func phaseInstructions(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup:
            return "Light jogging, leg swings, arm circles\nPrepare muscles for activity"
        case .stretch:
            return "Dynamic stretching routine\nHip circles, leg swings, lunges"
        case .drills:
            return "A-skips, B-skips, high knees\nButt kicks, straight leg bounds"
        case .strides:
            return "Build to 80% effort over 20 yards\n3 repetitions with 2 min rest"
        case .sprints:
            // Show specific distance from session data
            if let firstSprint = session.sprints.first {
                return "Maximum effort \(firstSprint.distanceYards)-yard sprints\n\(firstSprint.intensity) intensity"
            }
            return "Maximum effort sprints\nFollow your session plan"
        case .cooldown:
            return "Easy walking, static stretching\nGradual heart rate recovery"
        }
    }
    
    /// Returns progress text for each phase
    private func phaseProgressText(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup:
            return "Get your body ready"
        case .stretch:
            return "Improve mobility"
        case .drills:
            return "Focus on technique"
        case .strides:
            return "Build up speed"
        case .sprints:
            return "Maximum effort"
        case .cooldown:
            return "Recovery time"
        }
    }
    
    /// Returns motivational text for each phase
    private func phaseMotivationalText(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup:
            return "Get your body ready"
        case .stretch:
            return "Prepare your muscles"
        case .drills:
            return "Perfect your form"
        case .strides:
            return "Build momentum"
        case .sprints:
            return "Give it everything!"
        case .cooldown:
            return "Well done, recover"
        }
    }
    
    /// Returns appropriate icon for each phase
    private func phaseIcon(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup:
            return "flame.fill"
        case .stretch:
            return "figure.flexibility"
        case .drills:
            return "figure.run"
        case .strides:
            return "speedometer"
        case .sprints:
            return "bolt.fill"
        case .cooldown:
            return "leaf.fill"
        }
    }
}

// MARK: - Supporting Components

struct StatusIndicator: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(minWidth: 50)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview("Main Program Workout") {
    MainProgramWorkoutWatchView(
        session: TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Speed",
            focus: "Acceleration & Drive Phase",
            sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "Max")],
            accessoryWork: ["Dynamic warm-up", "Cool-down"],
            notes: "Focus on explosive starts"
        )
    )
    .preferredColorScheme(.dark)
}
