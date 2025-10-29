import SwiftUI
import WatchKit
import AVFoundation

struct SprintTimerProWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    
    let distance: Int
    let sets: Int
    let restMinutes: Int
    
    enum WorkoutViewType {
        case main, control, music, repLog
    }
    
    @State private var currentView: WorkoutViewType = .main
    @State private var currentSet = 1
    @State private var isWorkoutActive = false
    @State private var workoutTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var isResting = false
    @State private var showSprintView = false
    @State private var heartRate = 0
    @State private var lastSprintTime: TimeInterval = 0
    @State private var avgSprintTime: TimeInterval = 0
    @State private var sprintTimes: [TimeInterval] = []
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warm-up"
        case stretch = "Stretch"
        case drills = "Drills"
        case strides = "Strides"
        case sprints = "Sprints"
        case cooldown = "Cool-down"
        case complete = "Complete"
    }
    
    private let speechSynth = AVSpeechSynthesizer()
    private let colorTheme: ColorTheme = .apple
    
    // WorkoutWatchViewModel for RepLogWatchLiveView
    @StateObject private var sprintWorkoutVM = WorkoutWatchViewModel()
    
    // Sync manager for phone communication
    @StateObject private var syncManager = WatchWorkoutSyncManager.shared
    
    // Data manager for workout persistence
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
    
    // MARK: - Computed Properties for Autonomous Flow
    private var totalSets: Int {
        return sets
    }
    
    private var currentPhaseProgress: Double {
        switch currentPhase {
        case .warmup:
            return min(elapsedTime / 180.0, 1.0) // 3 minutes warmup
        case .stretch:
            return min(elapsedTime / 120.0, 1.0) // 2 minutes stretch
        case .drills:
            return min(elapsedTime / 300.0, 1.0) // 5 minutes drills
        case .strides:
            return min(elapsedTime / 180.0, 1.0) // 3 minutes strides
        case .sprints:
            return Double(currentSet) / Double(totalSets)
        case .cooldown:
            return min(elapsedTime / 300.0, 1.0) // 5 minutes cooldown
        case .complete:
            return 1.0
        }
    }
    
    private var phaseTimeRemaining: TimeInterval {
        switch currentPhase {
        case .warmup:
            return max(180.0 - elapsedTime, 0)
        case .stretch:
            return max(120.0 - elapsedTime, 0)
        case .drills:
            return max(300.0 - elapsedTime, 0)
        case .strides:
            return max(180.0 - elapsedTime, 0)
        case .sprints:
            return restTimeRemaining
        case .cooldown:
            return max(300.0 - elapsedTime, 0)
        case .complete:
            return 0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - MainProgramWorkoutWatchView style
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
                SprintControlWatchView(
                    isWorkoutActive: $isWorkoutActive,
                    currentSet: currentSet,
                    totalSets: sets,
                    currentTime: formatTime(elapsedTime),
                    totalTime: formatTime(Double(sets * restMinutes * 60 + sets * 30)), // Estimated total
                    onStartStop: toggleWorkout,
                    onNextSet: nextSet,
                    onEndWorkout: endWorkout
                )
                .tag(WorkoutViewType.control)
                
                // Main Workout View (Center) - MainProgramWorkoutWatchView style
                mainWorkoutView
                    .tag(WorkoutViewType.main)
                
                // Music View (Right swipe from Main) - Watch Compatible
                MusicWatchView(
                    selectedIndex: 2,
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Sprint Timer Pro",
                        focus: "Speed",
                        sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
                        accessoryWork: []
                    )
                )
                .tag(WorkoutViewType.music)
                
                // Rep Log View (Swipe Up/Down from Main)
                RepLogWatchLiveView(
                    workoutVM: sprintWorkoutVM,
                    horizontalTab: .constant(0),
                    isModal: false,
                    showNext: false,
                    onDone: { currentView = .main },
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Sprint Timer Pro",
                        focus: "Custom Sprint Training",
                        sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
                        accessoryWork: []
                    )
                )
                .tag(WorkoutViewType.repLog)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Sprint Detail View (Swipe Up) - Overlay
            if showSprintView {
                SprintDetailWatchView(
                    distance: distance,
                    currentTime: elapsedTime,
                    onDismiss: { showSprintView = false }
                )
                .transition(.move(edge: .top))
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
            setupWorkout()
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
    
    // MARK: - Phase Indicator (Adaptive for All Watch Models)
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
                    ForEach(Array(WorkoutPhase.allCases.filter { $0 != .complete }.enumerated()), id: \.element) { index, phase in
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
    
    // MARK: - Real-time Metrics (Matching MainProgramWorkoutWatchView)
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
    
    private func adaptiveMetricsSpacing(for size: CGSize) -> CGFloat {
        if size.width < 170 {
            return 15  // Smaller watches - tighter spacing
        } else {
            return 20  // Larger watches - more spacing
        }
    }
    
    // MARK: - Current Set Display (Matching MainProgramWorkoutWatchView)
    private var currentSetDisplay: some View {
        VStack(spacing: 8) {
            // Show different information based on current phase
            switch currentPhase {
            case .sprints:
                // Sprint phase - show current distance and set information
                VStack(spacing: 4) {
                    // Show current distance prominently
                    Text("\(distance)YD")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                        .tracking(1)
                    
                    // Show set progress
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(currentSet)")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.green)
                        
                        Text("/ \(sets)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 2)
                    }
                    
                    // Show set details
                    Text("SET")
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
    
    // MARK: - Timer Display (Matching MainProgramWorkoutWatchView)
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
    
    // MARK: - Session Details (Matching MainProgramWorkoutWatchView)
    private var sessionDetails: some View {
        VStack(spacing: 8) {
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
                    Text("INTENSITY")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("MAX")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("REST")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(restMinutes) MIN")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Progress Indicator (Matching MainProgramWorkoutWatchView)
    private var progressIndicator: some View {
        VStack(spacing: 4) {
            // Progress bar
            ProgressView(value: Double(currentSet), total: Double(sets))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Progress text
            Text("\(currentSet) of \(sets) sets completed")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Top Stats Row (Enhanced with Autonomous Systems)
    private var topStatsRow: some View {
        HStack(spacing: 6) {
            StatModuleView(
                icon: "heart.fill",
                label: "BPM",
                value: "\(workoutManager.currentHeartRate > 0 ? workoutManager.currentHeartRate : heartRate)",
                color: workoutManager.isWorkoutActive ? .red : .gray,
                theme: colorTheme
            )
            StatModuleView(
                icon: "location.fill",
                label: "Speed",
                value: String(format: "%.1f", gpsManager.currentSpeed),
                color: gpsManager.isTracking ? .green : .gray,
                theme: colorTheme
            )
            StatModuleView(
                icon: "timer",
                label: "Phase",
                value: intervalManager.currentPhase.rawValue.prefix(4).uppercased(),
                color: intervalManager.isActive ? .blue : .gray,
                theme: colorTheme
            )
            StatModuleView(
                icon: "repeat",
                label: "Set",
                value: "\(intervalManager.currentInterval > 0 ? intervalManager.currentInterval : currentSet)/\(sets)",
                color: .accentColor,
                theme: colorTheme
            )
        }
    }
    
    // MARK: - Main Module (Phase-Aware Display)
    private var mainModule: some View {
        VStack(spacing: 4) {
            // Phase-specific content
            switch currentPhase {
            case .warmup, .stretch, .drills, .strides, .cooldown:
                // Preparation phases
                VStack(spacing: 8) {
                    Image(systemName: getPhaseIcon())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(phaseColor(for: currentPhase))
                    
                    Text(getMotivationalText())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(phaseColor(for: currentPhase))
                    
                    Text(formatTime(phaseTimeRemaining))
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    ProgressView(value: currentPhaseProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: phaseColor(for: currentPhase)))
                        .scaleEffect(y: 2)
                }
                
            case .sprints:
                if isResting {
                    // Rest Timer Display
                    VStack(spacing: 8) {
                        Text("REST")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text(formatTime(restTimeRemaining))
                            .font(.system(size: 36, weight: .black, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        ProgressView(value: 1.0 - (restTimeRemaining / Double(restMinutes * 60)))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 2)
                    }
                } else {
                    // Sprint Timer Display
                    VStack(spacing: 8) {
                        Text(isWorkoutActive ? "SPRINT" : "READY")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isWorkoutActive ? .green : .yellow)
                        
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 42, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
            case .complete:
                // Workout Complete Display
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("COMPLETE!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Great Job!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            handleMainModuleTap()
        }
    }
    
    private func handleMainModuleTap() {
        switch currentPhase {
        case .sprints:
            if !isResting {
                toggleWorkout()
            }
        case .warmup, .stretch, .drills, .strides, .cooldown:
            // Allow manual phase advancement for preparation phases
            if !isWorkoutActive {
                advanceToNextPhase()
            }
        case .complete:
            // Dismiss workout view
            dismiss()
        }
    }
    
    // MARK: - Bottom Stats Row
    private var bottomStatsRow: some View {
        HStack(spacing: 6) {
            // Rest Timer Module
            RestTimerModuleView(
                restTime: formatTime(restTimeRemaining),
                progress: isResting ? (1.0 - (restTimeRemaining / Double(restMinutes * 60))) : 0.0,
                theme: colorTheme
            )
            
            // Sprint Times Module
            SprintTimesModuleView(
                avg: formatTime(avgSprintTime),
                last: formatTime(lastSprintTime),
                theme: colorTheme
            )
        }
    }
    
    // MARK: - Swipe Instructions
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
                    currentView = currentView == .repLog ? .main : .repLog
                }
            }
        } else {
            // Horizontal swipe - Navigation between views
            if value.translation.width > threshold {
                // Swipe right - Music
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .music
                    } else if currentView == .control {
                        currentView = .main
                    }
                }
            } else if value.translation.width < -threshold {
                // Swipe left - Control
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .control
                    } else if currentView == .music {
                        currentView = .main
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Control Functions
    private func setupWorkout() {
        heartRate = workoutManager.currentHeartRate > 0 ? workoutManager.currentHeartRate : 75 // Real heart rate with fallback
        restTimeRemaining = Double(restMinutes * 60)
        
        // Debug logging
        print("🏃‍♂️ SprintTimer Setup - Distance: \(distance)yd, Sets: \(sets), Rest: \(restMinutes)min")
        
        // Configure WorkoutWatchViewModel for RepLogWatchLiveView
        sprintWorkoutVM.totalReps = sets
        sprintWorkoutVM.currentRep = currentSet
        sprintWorkoutVM.restTime = Double(restMinutes * 60)
        sprintWorkoutVM.repDistances = Array(repeating: distance, count: sets)
        
        print("🏃‍♂️ SprintTimer VM configured - TotalReps: \(sprintWorkoutVM.totalReps), RestTime: \(sprintWorkoutVM.restTime)")
    }
    
    private func toggleWorkout() {
        if isWorkoutActive {
            stopCurrentSprint()
        } else {
            startSprint()
        }
    }
    
    private func startSprint() {
        isWorkoutActive = true
        elapsedTime = 0
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = true
        sprintWorkoutVM.currentRep = currentSet
        
        // Sync to phone
        syncWorkoutStateToPhone()
        
        // Start workout timer
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            // Update heart rate from workout manager during active sprint
            if workoutManager.currentHeartRate > 0 {
                heartRate = workoutManager.currentHeartRate
            }
        }
        
        // Speech feedback
        speak("Sprint \(currentSet) of \(sets). \(distance) yards. Go!")
        WKInterfaceDevice.current().play(.start)
    }
    
    private func stopCurrentSprint() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // Record sprint time
        lastSprintTime = elapsedTime
        sprintTimes.append(elapsedTime)
        
        // Calculate average
        avgSprintTime = sprintTimes.reduce(0, +) / Double(sprintTimes.count)
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = false
        sprintWorkoutVM.lastRepTime = elapsedTime
        
        // Sync to phone
        syncWorkoutStateToPhone()
        
        // Start rest period if not last set
        if currentSet < sets {
            startRestPeriod()
        } else {
            endWorkout()
        }
        
        WKInterfaceDevice.current().play(.stop)
    }
    
    private func startRestPeriod() {
        isResting = true
        restTimeRemaining = Double(restMinutes * 60)
        // Use real recovery heart rate or reasonable fallback
        heartRate = workoutManager.currentHeartRate > 0 ? max(workoutManager.currentHeartRate - 20, 100) : 120
        
        // Initialize WorkoutWatchViewModel rest progress
        sprintWorkoutVM.repProgress = 1.0 // Start at full rest time
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            restTimeRemaining -= 1
            
            // Update WorkoutWatchViewModel rest progress
            let totalRestTime = Double(restMinutes * 60)
            DispatchQueue.main.async {
                sprintWorkoutVM.repProgress = max(0.0, restTimeRemaining / totalRestTime)
            }
            
            if restTimeRemaining <= 0 {
                endRestPeriod()
            }
        }
        
        speak("Rest for \(restMinutes) minutes")
    }
    
    private func endRestPeriod() {
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        nextSet()
        
        speak("Rest complete. Ready for next sprint.")
        WKInterfaceDevice.current().play(.click)
    }
    
    private func nextSet() {
        if currentSet < sets {
            currentSet += 1
            elapsedTime = 0
            
            // Update WorkoutWatchViewModel
            sprintWorkoutVM.currentRep = currentSet
        } else {
            // All sprints completed - advance to cooldown phase
            if currentPhase == .sprints {
                advanceToNextPhase()
            }
        }
    }
    
    private func endWorkout() {
        stopWorkout()
        
        // Save workout data
        dataManager.saveSprintWorkout(
            distance: distance,
            sets: sets,
            sprintTimes: sprintTimes,
            avgTime: avgSprintTime,
            totalTime: elapsedTime
        )
        
        speak("Workout complete. Great job!")
        dismiss()
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        isResting = false
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        restTimer = nil
        // Use real resting heart rate or reasonable fallback
        heartRate = workoutManager.currentHeartRate > 0 ? max(workoutManager.currentHeartRate - 40, 60) : 70
    }
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynth.speak(utterance)
    }
    
    // MARK: - Integrated Autonomous Workout Lifecycle
    private func startAutonomousWorkout() {
        print("🚀 Starting integrated Sprint Timer Pro workout...")
        
        // Initialize workout data
        workoutData = WatchWorkoutData(
            workoutType: .power,
            sessionName: "Sprint Timer Pro - \(distance)yd x \(sets)",
            totalIntervals: sets
        )
        
        // Register all systems with event bus
        eventBus.registerAllSystems()
        
        // Create session for event broadcasting
        let session = TrainingSession(
            week: 1,
            day: 1,
            type: "Sprint Timer Pro",
            focus: "Speed",
            sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
            accessoryWork: []
        )
        
        // Broadcast workout start event
        eventBus.broadcast(.workoutStarted(session))
        
        // Start autonomous systems
        workoutManager.startWorkout()
        gpsManager.startTracking()
        
        // Configure interval manager for sprint timer
        let intervals = (0..<sets).map { index in
            IntervalConfig(
                distance: distance,
                restTime: TimeInterval(restMinutes * 60),
                intensity: "Max"
            )
        }
        
        let workoutPlan = WorkoutPlan(
            intervals: intervals,
            warmupTime: 180, // 3 minutes
            cooldownTime: 180 // 3 minutes
        )
        
        intervalManager.startWorkout(plan: workoutPlan)
        
        // Start premium entertainment systems
        startPremiumSystems(session: session)
        
        // Start autonomous phase progression
        startPhaseProgression()
    }
    
    // MARK: - Autonomous Phase Progression
    private func startPhaseProgression() {
        print("🔄 Starting autonomous phase progression...")
        
        // Start with warmup phase
        currentPhase = .warmup
        elapsedTime = 0
        
        // Start the main workout timer for phase progression
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updatePhaseProgression()
        }
    }
    
    private func updatePhaseProgression() {
        elapsedTime += 1.0
        
        // Check for automatic phase transitions
        switch currentPhase {
        case .warmup:
            if elapsedTime >= 180 { // 3 minutes
                advanceToNextPhase()
            }
        case .stretch:
            if elapsedTime >= 120 { // 2 minutes (reset elapsedTime on phase change)
                advanceToNextPhase()
            }
        case .drills:
            if elapsedTime >= 300 { // 5 minutes
                advanceToNextPhase()
            }
        case .strides:
            if elapsedTime >= 180 { // 3 minutes
                advanceToNextPhase()
            }
        case .sprints:
            // Sprint phase managed by user interaction and rest timers
            break
        case .cooldown:
            if elapsedTime >= 300 { // 5 minutes
                advanceToNextPhase()
            }
        case .complete:
            // Workout finished
            break
        }
    }
    
    private func advanceToNextPhase() {
        let phases: [WorkoutPhase] = [.warmup, .stretch, .drills, .strides, .sprints, .cooldown, .complete]
        
        if let currentIndex = phases.firstIndex(of: currentPhase),
           currentIndex < phases.count - 1 {
            
            let nextPhase = phases[currentIndex + 1]
            
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhase = nextPhase
            }
            
            // Reset elapsed time for the new phase
            elapsedTime = 0
            
            // Provide haptic and audio feedback
            WKInterfaceDevice.current().play(.notification)
            announcePhaseTransition(to: nextPhase)
            
            print("🔄 Advanced to phase: \(nextPhase.rawValue)")
            
            // Handle special phase transitions
            handlePhaseTransition(to: nextPhase)
        }
    }
    
    private func handlePhaseTransition(to phase: WorkoutPhase) {
        switch phase {
        case .sprints:
            // Initialize sprint tracking
            currentSet = 1
            isResting = false
            restTimeRemaining = Double(restMinutes * 60)
            print("🏃‍♂️ Entering sprint phase - \(sets) sets of \(distance)yd")
            
        case .cooldown:
            // Ensure all sprints are completed
            print("🧘‍♂️ Entering cooldown phase")
            
        case .complete:
            // Workout finished
            endAutonomousWorkout()
            
        default:
            break
        }
    }
    
    private func announcePhaseTransition(to phase: WorkoutPhase) {
        let announcement: String
        
        switch phase {
        case .warmup:
            announcement = "Starting warm-up. Get your body ready."
        case .stretch:
            announcement = "Time to stretch. Prepare your muscles."
        case .drills:
            announcement = "Drill time. Focus on technique."
        case .strides:
            announcement = "Build-up strides. Increase your pace gradually."
        case .sprints:
            announcement = "Sprint time! Give it everything you've got."
        case .cooldown:
            announcement = "Cool down time. Well done on completing your sprints."
        case .complete:
            announcement = "Workout complete! Great job today."
        }
        
        let utterance = AVSpeechUtterance(string: announcement)
        utterance.rate = 0.5
        utterance.volume = 0.8
        speechSynth.speak(utterance)
    }
    
    private func startPremiumSystems(session: TrainingSession) {
        // Initialize advanced haptics (Watch compatible)
        hapticsManager.handleWorkoutPhaseChange("warmup")
        
        // Start with warmup phase
        eventBus.broadcastPhaseChange(to: .warmup)
        
        print("🎵 Premium systems initialized for Sprint Timer Pro (Watch)")
    }
    
    private func endAutonomousWorkout() {
        print("🏁 Ending autonomous Sprint Timer Pro workout...")
        
        // Stop all systems
        workoutManager.endWorkout()
        intervalManager.stopWorkout()
        gpsManager.stopTracking()
        
        // Finalize workout data
        if let data = workoutData {
            data.completeWorkout()
            
            // Save to local storage
            dataStore.saveWorkout(data)
            
            print("✅ Autonomous Sprint Timer Pro workout completed and saved")
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        if time < 60 {
            return String(format: "%02d.%02d", seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
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
        
        // Listen for Pro picker data updates
        NotificationCenter.default.addObserver(
            forName: .proPickerDataAdapted,
            object: nil,
            queue: .main
        ) { notification in
            if let proPickerData = notification.object as? ProPickerDataSync {
                self.handleProPickerDataUpdate(proPickerData)
            }
        }
        
        print("🏃‍♂️ SprintTimer sync listeners setup complete")
    }
    
    private func syncWorkoutStateToPhone() {
        let watchState = syncManager.createWatchStateSync(
            currentPhase: isResting ? "rest" : (isWorkoutActive ? "sprint" : "ready"),
            isRunning: isWorkoutActive,
            isPaused: false,
            currentRep: currentSet
        )
        
        syncManager.sendWatchStateToPhone(watchState)
        
        // Update WorkoutWatchViewModel with current state
        sprintWorkoutVM.isRunning = isWorkoutActive
        sprintWorkoutVM.currentRep = currentSet
        sprintWorkoutVM.currentRepTime = elapsedTime
        
        print("🏃‍♂️ SprintTimer workout state synced to phone")
    }
    
    private func handlePhoneWorkoutStateUpdate(_ workoutState: WorkoutSyncState) {
        // Update local state based on phone updates
        isWorkoutActive = workoutState.isRunning
        currentSet = workoutState.currentRep
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = workoutState.isRunning
        sprintWorkoutVM.currentRep = workoutState.currentRep
        
        print("🏃‍♂️ SprintTimer updated from phone: \(workoutState.currentPhase)")
    }
    
    private func handleProPickerDataUpdate(_ proPickerData: ProPickerDataSync) {
        // Update sprint parameters from Pro picker
        // Note: This would typically update distance and sets, but those are let constants
        // In a real implementation, these would be @State variables
        print("🎯 SprintTimer Pro picker data updated: \(proPickerData.selectedDistance)yd x\(proPickerData.selectedReps) reps")
    }
    
    // MARK: - MainProgramWorkoutWatchView Style Components
    
    private var workoutHeader: some View {
        VStack(spacing: 4) {
            Text("Sprint Timer Pro")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.yellow)
                .tracking(0.5)
                .multilineTextAlignment(.center)
            
            Text("CUSTOM SPRINT TRAINING")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1)
                .multilineTextAlignment(.center)
            
            Text("\(distance) yards x \(sets) sets")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Enhanced Autonomous Systems Display
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
    
    // MARK: - Helper Functions
    private func phaseColor(for phase: WorkoutPhase) -> Color {
        switch phase {
        case .warmup:
            return .orange
        case .stretch:
            return .purple
        case .drills:
            return .yellow
        case .strides:
            return .cyan
        case .sprints:
            return .red
        case .cooldown:
            return .blue
        case .complete:
            return .green
        }
    }
    
    private func getMotivationalText() -> String {
        switch currentPhase {
        case .warmup:
            return "WARMING UP"
        case .stretch:
            return "STRETCHING"
        case .drills:
            return "DRILL TIME"
        case .strides:
            return "BUILD UP"
        case .sprints:
            return "SPRINT \(currentSet)/\(totalSets)"
        case .cooldown:
            return "COOLING DOWN"
        case .complete:
            return "COMPLETE!"
        }
    }
    
    private func getPhaseIcon() -> String {
        switch currentPhase {
        case .warmup:
            return "flame.fill"
        case .stretch:
            return "figure.flexibility"
        case .drills:
            return "target"
        case .strides:
            return "speedometer"
        case .sprints:
            return "bolt.fill"
        case .cooldown:
            return "snowflake"
        case .complete:
            return "checkmark.circle.fill"
        }
    }
    
    // MARK: - MainProgramWorkoutWatchView Style Helper Functions
    
    /// Returns specific instructions for what to do in each phase - EXACT match
    private func phaseInstructions(for phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup:
            return "Light jogging, leg swings, arm circles"
        case .stretch:
            return "Dynamic stretching routine"
        case .drills:
            return "A-skips, B-skips, high knees"
        case .strides:
            return "Build to 80% effort over 20 yards"
        case .sprints:
            return "Maximum effort \(distance)-yard sprints"
        case .cooldown:
            return "Easy walking, static stretching"
        case .complete:
            return "Workout completed successfully"
        }
    }
    
    /// Returns progress text for each phase - EXACT match
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
        case .complete:
            return "Well done!"
        }
    }
    
    /// Returns motivational text for each phase - EXACT match
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
        case .complete:
            return "Workout complete!"
        }
    }
    
    /// Returns appropriate icon for each phase - EXACT match
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
        case .complete:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Supporting Views

// Status Icon Component
struct StatusIcon: View {
    let icon: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(isActive ? color : .gray)
            .frame(width: 12, height: 12)
    }
}
struct SprintControlWatchView: View {
    @Binding var isWorkoutActive: Bool
    let currentSet: Int
    let totalSets: Int
    let currentTime: String
    let totalTime: String
    let onStartStop: () -> Void
    let onNextSet: () -> Void
    let onEndWorkout: () -> Void
    
    @State private var showEndWorkoutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer display at top
            VStack(spacing: 4) {
                Text(currentTime)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("ELAPSED TIME")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Control buttons grid matching the uploaded design
            VStack(spacing: 12) {
                // Top row: Pause/Play and Stop
                HStack(spacing: 12) {
                    // Start/Stop Button (Orange border)
                    ControlButton(
                        icon: isWorkoutActive ? "pause.fill" : "play.fill",
                        borderColor: .orange,
                        action: onStartStop
                    )
                    
                    // End Workout Button (Pink border)
                    ControlButton(
                        icon: "stop.fill",
                        borderColor: .pink,
                        action: {
                            showEndWorkoutAlert = true
                        }
                    )
                }
                
                // Bottom row: Next Set and Skip
                HStack(spacing: 12) {
                    // Next Set Button (Cyan border)
                    ControlButton(
                        icon: "forward.fill",
                        borderColor: .cyan,
                        action: onNextSet
                    )
                    
                    // Skip Button (Blue border)
                    ControlButton(
                        icon: "forward.end.fill",
                        borderColor: .blue,
                        action: {
                            // Skip current set
                            onNextSet()
                        }
                    )
                }
                
                // Set indicator (Gray border) - centered
                HStack {
                    VStack(spacing: 2) {
                        Text("SET")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(currentSet)/\(totalSets)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                    )
                }
            }
            
            Spacer()
            
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 4)
            
            // Navigation hints
            Text("Main →")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 4)
        }
        .background(Color.black.ignoresSafeArea())
        .alert(isPresented: $showEndWorkoutAlert) {
            Alert(
                title: Text("End Workout?"),
                message: Text("Save your progress and end the workout?"),
                primaryButton: .default(Text("CONTINUE WORKOUT")),
                secondaryButton: .default(Text("END & SAVE")) {
                    onEndWorkout()
                }
            )
        }
    }
}


struct SprintTimesModuleView: View {
    let avg: String
    let last: String
    let theme: ColorTheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Sprint Times")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text("Avg: \(avg)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
            Text("Last: \(last)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 44)
        .background(Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

struct SprintRepLogWatchView: View {
    let currentSet: Int
    let totalSets: Int
    let sprintTimes: [TimeInterval]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Rep Log")
                .font(.title2)
                .foregroundColor(.white)
            Text("Set \(currentSet)/\(totalSets)")
                .foregroundColor(.gray)
            Button("Close", action: onDismiss)
                .foregroundColor(.blue)
        }
    }
}

struct SprintDetailWatchView: View {
    let distance: Int
    let currentTime: TimeInterval
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Sprint Detail")
                .font(.title2)
                .foregroundColor(.white)
            Text("\(distance) yards")
                .foregroundColor(.gray)
            Button("Close", action: onDismiss)
                .foregroundColor(.blue)
        }
    }
}

#Preview("Sprint Timer Pro Workout") {
    SprintTimerProWorkoutView(
        distance: 40,
        sets: 5,
        restMinutes: 2
    )
    .preferredColorScheme(.dark)
}
