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
    
    // Note: PremiumVoiceCoach, WorkoutMusicManager, and SubscriptionManager 
    // are iOS-only and not available in Watch target
    
    enum WorkoutViewType {
        case main, control, music, repLog
    }
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warm-up"
        case drills = "Drills"
        case sprints = "Sprints"
        case cooldown = "Cool-down"
    }
    
    var totalSets: Int {
        session.sprints.first?.reps ?? 1
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
        
        print("🎵 Premium systems initialized for Watch target")
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
    
    // MARK: - Main Workout View
    private var mainWorkoutView: some View {
        VStack(spacing: 12) {
            // Header
            workoutHeader
            
            // Autonomous Systems Status
            autonomousSystemsStatus
            
            // Phase Indicator
            phaseIndicator
            
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
        .padding(16)
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
        VStack(spacing: 8) {
            // Current Phase from Interval Manager
            Text(intervalManager.currentPhase.rawValue.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.yellow)
                .tracking(1)
            
            // Distance and Pace
            HStack(spacing: 16) {
                VStack {
                    Text(String(format: "%.0f", gpsManager.currentDistance))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("YDS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack {
                    Text(String(format: "%.1f", gpsManager.currentPace))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("MIN/MI")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
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
        HStack(spacing: 8) {
            ForEach(WorkoutPhase.allCases, id: \.self) { phase in
                VStack(spacing: 2) {
                    Circle()
                        .fill(currentPhase == phase ? Color.green : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Text(phase.rawValue)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(currentPhase == phase ? .green : .white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var currentSetDisplay: some View {
        VStack(spacing: 8) {
            if currentPhase == .sprints {
                VStack(spacing: 4) {
                    Text("SET")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(currentSet)")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("/ \(totalSets)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 2)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Text("PHASE")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                    
                    Text(currentPhase.rawValue.uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                        .tracking(0.5)
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
            
            // Auto-advance phases based on time (demo logic)
            if elapsedTime > 300 && currentPhase == .warmup { // 5 min warmup
                currentPhase = .drills
            } else if elapsedTime > 600 && currentPhase == .drills { // 5 min drills
                currentPhase = .sprints
            } else if elapsedTime > 1200 && currentPhase == .sprints { // 10 min sprints
                currentPhase = .cooldown
            }
        }
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // Save workout data when stopping
        let completedReps = (1...currentSet).map { repNumber in
            CompletedRep(
                repNumber: repNumber,
                distance: session.sprints.first?.distanceYards ?? 40,
                time: Double.random(in: 4.5...6.0), // Mock time - would be real data
                heartRate: Int.random(in: 140...180),
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
        case .drills:
            workoutVM.currentPhase = .drills
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
