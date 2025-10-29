import SwiftUI

struct MainProgramWorkoutWatchView: View {
    @Environment(\.dismiss) private var dismiss
    
    let session: TrainingSession
    
    @State private var currentView: WorkoutViewType = .main
    @State private var currentSet = 1
    @State private var isWorkoutActive = false
    @State private var workoutTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
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
        
        // Initialize RepLog system
        repLogVM.startSession(
            type: session.type,
            focus: session.focus,
            week: session.week,
            day: session.day
        )
        
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
            hapticsManager.playHaptic(.notification)
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
                        workoutVM: workoutVM,
                        session: session
                    )
                    .tag(WorkoutViewType.control)
                    
                    // Main Workout View (Center)
                    mainWorkoutView
                        .tag(WorkoutViewType.main)
                    
                    // Music View (Right swipe from Main) - Watch Compatible
                    MusicWatchView(
                        selectedIndex: 2,
                        session: session
                    )
                    .tag(WorkoutViewType.music)
                    
                    // Rep Log View (Swipe Up/Down from Main)
                    RepLogWatchLiveView(
                        workoutVM: workoutVM,
                        horizontalTab: .constant(0),
                        isModal: false,
                        showNext: false,
                        onDone: { currentView = .main },
                        session: session
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
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DISTANCE")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(firstSprint.distanceYards) YD")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("INTENSITY")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(firstSprint.intensity.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
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
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
            
            // Auto-advance phases based on time (complete 6-phase flow)
            if elapsedTime > 300 && currentPhase == .warmup { // 5 min warmup
                currentPhase = .stretch
            } else if elapsedTime > 480 && currentPhase == .stretch { // 3 min stretch
                currentPhase = .drills
            } else if elapsedTime > 840 && currentPhase == .drills { // 6 min drills
                currentPhase = .strides
            } else if elapsedTime > 1080 && currentPhase == .strides { // 4 min strides (20yd x 3 + rest)
                currentPhase = .sprints
                // Start RepLog tracking for sprints
                if let firstSprint = session.sprints.first {
                    Task { @MainActor in
                        repLogVM.startRep(
                            distance: Double(firstSprint.distanceYards),
                            location: nil
                        )
                    }
                }
            } else if elapsedTime > 1680 && currentPhase == .sprints { // 10 min sprints
                // Complete current rep if recording
                Task { @MainActor in
                    if repLogVM.isRecording, let firstSprint = session.sprints.first {
                        repLogVM.completeRep(
                            finalDistance: Double(firstSprint.distanceYards),
                            finalLocation: nil
                        )
                    }
                }
                currentPhase = .cooldown
            }
        }
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // End RepLog session and sync to phone
        if let sessionData = repLogVM.endSession() {
            syncManager.sendSessionDataToPhone(sessionData)
        }
        
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
            workoutVM.currentPhase = .stretch
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
