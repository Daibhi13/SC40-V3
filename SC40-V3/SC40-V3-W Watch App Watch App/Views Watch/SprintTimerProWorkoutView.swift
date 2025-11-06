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
    @State private var phaseTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var sprintStartTime: Date?
    @State private var phaseElapsedTime: TimeInterval = 0
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var isResting = false
    @State private var showSprintView = false
    @State private var heartRate = 0
    @State private var lastSprintTime: TimeInterval = 0
    @State private var avgSprintTime: TimeInterval = 0
    @State private var sprintTimes: [TimeInterval] = []
    
    // Drills phase management
    @State private var currentDrill = 0
    @State private var drillRestTimer: Timer?
    @State private var drillRestTimeRemaining: TimeInterval = 0
    @State private var isDrillResting = false
    @State private var drillPhaseTimer: Timer?
    
    // Strides phase management
    @State private var currentStride = 0
    @State private var strideRestTimer: Timer?
    @State private var strideRestTimeRemaining: TimeInterval = 0
    @State private var isStrideResting = false
    @State private var stridePhaseTimer: Timer?
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warm-up"
        case stretch = "Stretch"
        case drills = "Drills"
        case strides = "Strides"
        case sprints = "Sprints"
        case cooldown = "Cool-down"
        case complete = "Complete"
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
    
    // Sprint Timer Pro Session Library with GPS Stopwatch Adaptation
    struct SprintTimerProSessionEntry {
        let distance: Int
        let restTimeMinutes: Int
        let sessionType: String
        let focus: String
        let voiceCoaching: String
        let gpsStopwatchMode: GPSStopwatchMode
        let engagementLevel: EngagementLevel
    }
    
    enum GPSStopwatchMode {
        case precision      // High accuracy GPS for shorter distances
        case endurance     // Optimized for longer distances
        case speed         // Maximum velocity tracking
        case custom        // User-defined parameters
    }
    
    enum EngagementLevel {
        case beginner      // More encouragement and guidance
        case intermediate  // Balanced coaching
        case advanced      // Performance-focused
        case elite         // Minimal coaching, data-focused
    }
    
    private let sprintTimerProLibrary: [SprintTimerProSessionEntry] = [
        // Short Distance Sprints (10-30yd) - Precision GPS Mode
        SprintTimerProSessionEntry(distance: 10, restTimeMinutes: 1, sessionType: "Acceleration", focus: "Explosive Start", voiceCoaching: "10-yard acceleration blast! Focus on explosive drive from the blocks. Quick feet, powerful arms. 1 minute recovery.", gpsStopwatchMode: .precision, engagementLevel: .beginner),
        SprintTimerProSessionEntry(distance: 15, restTimeMinutes: 1, sessionType: "Acceleration", focus: "Drive Phase", voiceCoaching: "15-yard power sprint! Stay low, drive hard through the first 15 yards. Feel that acceleration building. 1 minute rest.", gpsStopwatchMode: .precision, engagementLevel: .beginner),
        SprintTimerProSessionEntry(distance: 20, restTimeMinutes: 2, sessionType: "Acceleration", focus: "Early Speed", voiceCoaching: "20-yard speed builder! Accelerate smoothly through 20 yards. Build that early speed with perfect form. 2 minutes recovery.", gpsStopwatchMode: .precision, engagementLevel: .intermediate),
        SprintTimerProSessionEntry(distance: 25, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Power Development", voiceCoaching: "25-yard power drive! Maximum acceleration through the drive phase. Feel the power building. 2 minutes rest.", gpsStopwatchMode: .precision, engagementLevel: .intermediate),
        SprintTimerProSessionEntry(distance: 30, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Transition", voiceCoaching: "30-yard transition sprint! Drive hard then smoothly transition to upright running. Perfect technique. 2 minutes recovery.", gpsStopwatchMode: .precision, engagementLevel: .intermediate),
        
        // Medium Distance Sprints (35-60yd) - Speed GPS Mode
        SprintTimerProSessionEntry(distance: 35, restTimeMinutes: 2, sessionType: "Speed Building", focus: "Acceleration to Speed", voiceCoaching: "35-yard speed developer! Accelerate through drive phase into maximum velocity. Feel that speed building. 2 minutes rest.", gpsStopwatchMode: .speed, engagementLevel: .intermediate),
        SprintTimerProSessionEntry(distance: 40, restTimeMinutes: 3, sessionType: "Max Speed", focus: "Full Sprint", voiceCoaching: "40-yard maximum effort! This is your signature distance. Give everything you have. Chase that personal best! 3 minutes recovery.", gpsStopwatchMode: .speed, engagementLevel: .advanced),
        SprintTimerProSessionEntry(distance: 45, restTimeMinutes: 3, sessionType: "Speed", focus: "Max Velocity", voiceCoaching: "45-yard velocity sprint! Reach your maximum speed and hold it. Feel that top-end velocity. 3 minutes rest.", gpsStopwatchMode: .speed, engagementLevel: .advanced),
        SprintTimerProSessionEntry(distance: 50, restTimeMinutes: 3, sessionType: "Speed", focus: "Speed Maintenance", voiceCoaching: "50-yard speed endurance! Accelerate to max speed and maintain it. Show your speed endurance. 3 minutes recovery.", gpsStopwatchMode: .speed, engagementLevel: .advanced),
        SprintTimerProSessionEntry(distance: 55, restTimeMinutes: 3, sessionType: "Speed", focus: "Velocity Holding", voiceCoaching: "55-yard velocity challenge! Hit max speed early and hold it through the finish. Elite speed control. 3 minutes rest.", gpsStopwatchMode: .speed, engagementLevel: .advanced),
        SprintTimerProSessionEntry(distance: 60, restTimeMinutes: 4, sessionType: "Max Velocity", focus: "Flying Sprint", voiceCoaching: "60-yard flying sprint! Maximum velocity focus. This is elite-level speed training. 4 minutes recovery.", gpsStopwatchMode: .speed, engagementLevel: .elite),
        
        // Long Distance Sprints (65-100yd) - Endurance GPS Mode
        SprintTimerProSessionEntry(distance: 65, restTimeMinutes: 4, sessionType: "Speed Endurance", focus: "Lactate Tolerance", voiceCoaching: "65-yard endurance sprint! Push through the burn. This builds your speed endurance. Elite training. 4 minutes rest.", gpsStopwatchMode: .endurance, engagementLevel: .elite),
        SprintTimerProSessionEntry(distance: 70, restTimeMinutes: 4, sessionType: "Speed Endurance", focus: "Fatigue Resistance", voiceCoaching: "70-yard fatigue fighter! Maintain speed as fatigue builds. This is where champions are made. 4 minutes recovery.", gpsStopwatchMode: .endurance, engagementLevel: .elite),
        SprintTimerProSessionEntry(distance: 75, restTimeMinutes: 5, sessionType: "Top-End Speed", focus: "Peak Velocity", voiceCoaching: "75-yard peak performance! Maximum effort for elite speed development. Push your limits. 5 minutes rest.", gpsStopwatchMode: .endurance, engagementLevel: .elite),
        SprintTimerProSessionEntry(distance: 80, restTimeMinutes: 5, sessionType: "Repeat Sprints", focus: "Speed Endurance", voiceCoaching: "80-yard repeat power! Maintain speed across all repetitions. Elite speed endurance training. 5 minutes recovery.", gpsStopwatchMode: .endurance, engagementLevel: .elite),
        SprintTimerProSessionEntry(distance: 90, restTimeMinutes: 5, sessionType: "Top-End Speed", focus: "Elite Performance", voiceCoaching: "90-yard elite sprint! This is championship-level training. Maximum effort, perfect technique. 5 minutes rest.", gpsStopwatchMode: .endurance, engagementLevel: .elite),
        SprintTimerProSessionEntry(distance: 100, restTimeMinutes: 6, sessionType: "Peak Velocity", focus: "Ultimate Speed", voiceCoaching: "100-yard ultimate challenge! The full sprint distance. Give everything for elite performance. 6 minutes recovery.", gpsStopwatchMode: .endurance, engagementLevel: .elite)
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
            return min(phaseElapsedTime / 180.0, 1.0) // 3 minutes warmup
        case .stretch:
            return min(phaseElapsedTime / 120.0, 1.0) // 2 minutes stretch
        case .drills:
            return min(phaseElapsedTime / 300.0, 1.0) // 5 minutes drills
        case .strides:
            return min(phaseElapsedTime / 180.0, 1.0) // 3 minutes strides
        case .sprints:
            return Double(currentSet) / Double(totalSets)
        case .cooldown:
            return min(phaseElapsedTime / 300.0, 1.0) // 5 minutes cooldown
        case .complete:
            return 1.0
        }
    }
    
    private var phaseTimeRemaining: TimeInterval {
        switch currentPhase {
        case .warmup:
            return max(180.0 - phaseElapsedTime, 0)
        case .stretch:
            return max(120.0 - phaseElapsedTime, 0)
        case .drills:
            return max(300.0 - phaseElapsedTime, 0)
        case .strides:
            return max(180.0 - phaseElapsedTime, 0)
        case .sprints:
            return restTimeRemaining
        case .cooldown:
            return max(300.0 - phaseElapsedTime, 0)
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
                // Control View (Left swipe from Main) - Exact match with MainProgramWorkoutWatchView
                ControlWatchView(
                    selectedIndex: 0, // Control is index 0 in the page indicators
                    workoutVM: sprintWorkoutVM,
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Sprint Timer Pro",
                        focus: "Custom Sprint Training",
                        sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
                        accessoryWork: []
                    )
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
        // Add haptic feedback for button press
        WKInterfaceDevice.current().play(.click)
        
        if isWorkoutActive {
            stopCurrentSprint()
        } else {
            startSprint()
        }
    }
    
    private func startSprint() {
        isWorkoutActive = true
        sprintStartTime = Date()
        elapsedTime = 0
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = true
        sprintWorkoutVM.currentRep = currentSet
        
        // Sync to phone
        syncWorkoutStateToPhone()
        
        // Start workout timer with Date-based calculation
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Calculate elapsed time from start time for accuracy
            if let startTime = sprintStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
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
        // Add haptic feedback for button press
        WKInterfaceDevice.current().play(.click)
        
        if currentSet < sets {
            currentSet += 1
            elapsedTime = 0
            
            // Update WorkoutWatchViewModel
            sprintWorkoutVM.currentRep = currentSet
            
            // Provide audio feedback
            speak("Set \(currentSet) of \(sets)")
        } else {
            // All sprints completed - advance to cooldown phase
            if currentPhase == .sprints {
                advanceToNextPhase()
            }
        }
    }
    
    private func endWorkout() {
        // Add haptic feedback for button press
        WKInterfaceDevice.current().play(.success)
        
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
        phaseTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        phaseTimer = nil
        restTimer = nil
        // Use real resting heart rate or reasonable fallback
        heartRate = workoutManager.currentHeartRate > 0 ? max(workoutManager.currentHeartRate - 40, 60) : 70
    }
    private func speak(_ text: String) {
        // Use unified voice manager for consistent voice settings
        UnifiedVoiceManager.shared.speak(text)
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
        
        // AUTOMATIC WORKOUT START - Key Implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Automatically start the workout after 1 second delay
            self.startSprint()
            
            // Stay on main view as per requirements - do not switch to control view
            // User can manually swipe to control view if needed
            
            // Provide haptic feedback for workout start
            WKInterfaceDevice.current().play(.start)
            
            print("🏃‍♂️ Workout automatically started - Staying on main view")
        }
        
        // Start autonomous phase progression
        startPhaseProgression()
    }
    
    // MARK: - Autonomous Phase Progression
    private func startPhaseProgression() {
        print("🔄 Starting autonomous phase progression...")
        
        // Start with warmup phase
        currentPhase = .warmup
        elapsedTime = 0
        
        // Start separate phase progression timer
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updatePhaseProgression()
        }
    }
    
    private func updatePhaseProgression() {
        phaseElapsedTime += 1.0
        
        // Check for automatic phase transitions
        switch currentPhase {
        case .warmup:
            if phaseElapsedTime >= 180 { // 3 minutes
                advanceToNextPhase()
            }
        case .stretch:
            if phaseElapsedTime >= 120 { // 2 minutes
                advanceToNextPhase()
            }
        case .drills:
            if phaseElapsedTime >= 300 { // 5 minutes
                advanceToNextPhase()
            }
        case .strides:
            if phaseElapsedTime >= 180 { // 3 minutes
                advanceToNextPhase()
            }
        case .sprints:
            // Sprint phase managed by user interaction and rest timers
            break
        case .cooldown:
            if phaseElapsedTime >= 300 { // 5 minutes
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
            
            // Reset phase elapsed time for the new phase
            phaseElapsedTime = 0
            
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
        case .drills:
            // Start GPS tracking and voice coaching for drills phase
            print("🎯 Entering drills phase - GPS tracking enabled with voice coaching")
            gpsManager.startTracking()
            startGPSPhaseTracking(phase: phase)
            startDrillsPhaseCoaching()
            
        case .strides:
            // Start GPS tracking and voice coaching for strides phase
            print("🏃‍♂️ Entering strides phase - GPS tracking active with voice coaching")
            startGPSPhaseTracking(phase: phase)
            startStridesPhaseCoaching()
            
        case .sprints:
            // Initialize Sprint Timer Pro session with GPS Stopwatch adaptation
            currentSet = 1
            isResting = false
            print("🏃‍♂️ Entering Sprint Timer Pro phase - \(sets) sets of \(distance)yd with adaptive GPS")
            startGPSPhaseTracking(phase: phase)
            startSprintTimerProSession()
            
        case .cooldown:
            // Stop GPS tracking and finalize rep log data
            print("🧘‍♂️ Entering cooldown phase")
            stopGPSPhaseTracking()
            
        case .complete:
            // Workout finished
            stopGPSPhaseTracking()
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
        // Update WorkoutWatchViewModel with phase data for rep log
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
    }
    
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
            self.completeDrill()
        }
        
        // Log current drill
        print("🎯 Current drill: \(drill.name)")
    }
    
    private func completeDrill() {
        let drill = drillSequence[currentDrill]
        
        print("✅ Completed drill: \(drill.name)")
        
        // Stop GPS tracking and record data
        if let sprintResult = gpsManager.endSprint() {
            updateRepLogWithGPSData(sprintResult)
        }
        
        // Record drill completion
        recordDrillInRepLog(drill: drill)
        
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
            
            // Update UI with rest countdown
            print("⏱️ Drill rest: \(Int(self.drillRestTimeRemaining))s remaining")
            
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
    }
    
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
        
        // Log current stride
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
            
            // Update UI with rest countdown
            print("⏱️ Stride rest: \(Int(self.strideRestTimeRemaining))s remaining")
            
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
        // Log stride completion for analytics
        print("📝 Stride \(stride.name) (\(stride.intensity)) recorded for analytics")
        print("📊 Stride data: \(stride.distance)yd in \(stride.duration)s")
    }
    
    // MARK: - Sprint Timer Pro Session Library Functions
    
    private func getSprintTimerProEntry(for distance: Int) -> SprintTimerProSessionEntry? {
        return sprintTimerProLibrary.first { entry in
            entry.distance == distance
        }
    }
    
    private func getRestTimeForSprintDistance(_ distance: Int) -> Int {
        if let entry = getSprintTimerProEntry(for: distance) {
            return entry.restTimeMinutes
        }
        
        // Fallback rest times based on distance
        switch distance {
        case 10...15: return 1
        case 16...35: return 2
        case 36...50: return 3
        case 51...70: return 4
        case 71...90: return 5
        default: return 6
        }
    }
    
    private func configureGPSStopwatchForDistance(_ distance: Int) {
        guard let entry = getSprintTimerProEntry(for: distance) else { return }
        
        print("🎯 Configuring GPS Stopwatch: \(entry.gpsStopwatchMode) mode for \(distance)yd")
        
        switch entry.gpsStopwatchMode {
        case .precision:
            // High accuracy GPS for shorter distances (10-30yd)
            print("📍 GPS Mode: Precision - High accuracy for explosive starts")
            
        case .speed:
            // Maximum velocity tracking for medium distances (35-60yd)
            print("📍 GPS Mode: Speed - Maximum velocity tracking enabled")
            
        case .endurance:
            // Optimized for longer distances (65-100yd)
            print("📍 GPS Mode: Endurance - Battery optimized for longer distances")
            
        case .custom:
            // User-defined parameters (future implementation)
            print("📍 GPS Mode: Custom - User-defined parameters")
        }
    }
    
    private func getEngagementVoiceCoaching(distance: Int, setNumber: Int, totalSets: Int, restTime: Int) -> String {
        guard let entry = getSprintTimerProEntry(for: distance) else {
            return "Sprint \(setNumber) of \(totalSets). \(distance)-yard maximum effort! \(restTime) minutes rest."
        }
        
        let setInfo = "Sprint \(setNumber) of \(totalSets). "
        let restInfo = " You've earned \(restTime) minute\(restTime == 1 ? "" : "s") recovery."
        
        // Add engagement based on level
        let engagementPrefix = getEngagementPrefix(for: entry.engagementLevel, setNumber: setNumber, totalSets: totalSets)
        let engagementSuffix = getEngagementSuffix(for: entry.engagementLevel, setNumber: setNumber, totalSets: totalSets)
        
        return engagementPrefix + setInfo + entry.voiceCoaching + restInfo + engagementSuffix
    }
    
    private func getEngagementPrefix(for level: EngagementLevel, setNumber: Int, totalSets: Int) -> String {
        switch level {
        case .beginner:
            if setNumber == 1 {
                return "Let's do this! "
            } else if setNumber == totalSets {
                return "Final sprint! You've got this! "
            } else {
                return "Great work! "
            }
            
        case .intermediate:
            if setNumber == 1 {
                return "Time to work! "
            } else if setNumber == totalSets {
                return "Last one! Make it count! "
            } else {
                return "Keep it going! "
            }
            
        case .advanced:
            if setNumber == totalSets {
                return "Final rep! Leave it all out there! "
            } else {
                return "Execute! "
            }
            
        case .elite:
            return "" // Minimal coaching for elite level
        }
    }
    
    private func getEngagementSuffix(for level: EngagementLevel, setNumber: Int, totalSets: Int) -> String {
        switch level {
        case .beginner:
            return " You're doing amazing!"
            
        case .intermediate:
            if setNumber < totalSets {
                return " Stay focused!"
            } else {
                return " Outstanding effort!"
            }
            
        case .advanced:
            return " Push your limits!"
            
        case .elite:
            return "" // Data-focused, minimal encouragement
        }
    }
    
    private func startSprintTimerProSession() {
        let restTime = getRestTimeForSprintDistance(distance)
        
        print("🏃‍♂️ Starting Sprint Timer Pro: \(distance)yd x \(sets) with \(restTime)min rest")
        
        // Configure GPS Stopwatch based on distance
        configureGPSStopwatchForDistance(distance)
        
        // Get session library entry for UI display
        if let sessionEntry = getSprintTimerProEntry(for: distance) {
            // Session introduction with engagement
            let sessionIntro = getSessionIntroduction(entry: sessionEntry)
            speak(sessionIntro)
            print("🏃‍♂️ Session: \(sessionEntry.sessionType) - \(sessionEntry.focus)")
        }
        
        // Start first sprint after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.startNextSprintTimerProSprint()
        }
    }
    
    private func getSessionIntroduction(entry: SprintTimerProSessionEntry) -> String {
        let baseIntro = "Sprint Timer Pro activated! \(entry.sessionType) session. Focus: \(entry.focus). You'll be doing \(sets) sprints at \(distance) yards each."
        
        switch entry.engagementLevel {
        case .beginner:
            return "Welcome to " + baseIntro + " Take your time, focus on form, and let's build that speed!"
            
        case .intermediate:
            return baseIntro + " Time to push your limits and see what you're made of!"
            
        case .advanced:
            return baseIntro + " This is serious speed training. Execute with precision!"
            
        case .elite:
            return baseIntro + " Elite performance mode engaged."
        }
    }
    
    private func startNextSprintTimerProSprint() {
        guard currentSet <= sets else {
            completeSprintTimerProSession()
            return
        }
        
        let restTime = getRestTimeForSprintDistance(distance)
        
        // Get engagement-based voice coaching
        let voiceCoaching = getEngagementVoiceCoaching(
            distance: distance,
            setNumber: currentSet,
            totalSets: sets,
            restTime: restTime
        )
        
        print("🏃‍♂️ Starting Sprint Timer Pro sprint \(currentSet): \(distance)yd")
        
        // Voice coaching with engagement
        speak(voiceCoaching)
        
        // Start GPS tracking with configured settings
        gpsManager.startSprint()
        
        // Update UI
        sprintWorkoutVM.currentRep = currentSet
        sprintWorkoutVM.isRunning = true
        
        // Provide countdown for sprint start
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.speak("3... 2... 1... GO!")
            
            // Sprint completion would be triggered by GPS distance or manual stop
            // For now, simulate completion after reasonable time
            DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                self.completeSprintTimerProSprint()
            }
        }
    }
    
    private func completeSprintTimerProSprint() {
        let restTime = getRestTimeForSprintDistance(distance)
        
        print("✅ Sprint Timer Pro sprint \(currentSet) completed")
        
        // Stop GPS tracking and record data
        if let sprintResult = gpsManager.endSprint() {
            updateRepLogWithGPSData(sprintResult)
            
            // Provide performance feedback based on engagement level
            providePerfomanceFeedback(sprintResult: sprintResult)
        }
        
        // Update workout state
        sprintWorkoutVM.isRunning = false
        sprintWorkoutVM.lastRepTime = elapsedTime
        
        // Move to next sprint or start rest
        if currentSet < sets {
            startSprintTimerProRestPeriod(restTimeMinutes: restTime)
        } else {
            completeSprintTimerProSession()
        }
    }
    
    private func providePerfomanceFeedback(sprintResult: SprintResult) {
        guard let entry = getSprintTimerProEntry(for: distance) else { return }
        
        let time = sprintResult.time
        let speed = sprintResult.maxSpeed
        
        switch entry.engagementLevel {
        case .beginner:
            speak("Great sprint! Time: \(String(format: "%.2f", time)) seconds. You're getting faster!")
            
        case .intermediate:
            speak("Solid run! \(String(format: "%.2f", time)) seconds at \(String(format: "%.1f", speed)) mph. Keep pushing!")
            
        case .advanced:
            speak("Time: \(String(format: "%.2f", time)) seconds. Max speed: \(String(format: "%.1f", speed)) mph. Execute the next one!")
            
        case .elite:
            speak("\(String(format: "%.2f", time)) seconds. \(String(format: "%.1f", speed)) mph.")
        }
    }
    
    private func startSprintTimerProRestPeriod(restTimeMinutes: Int) {
        isResting = true
        restTimeRemaining = Double(restTimeMinutes * 60)
        
        guard let entry = getSprintTimerProEntry(for: distance) else { return }
        
        let restMessage = getRestMessage(for: entry.engagementLevel, restTime: restTimeMinutes)
        speak(restMessage)
        
        // Start rest timer with engagement-based announcements
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.restTimeRemaining -= 1
            
            // Log rest progress
            let progress = max(0.0, self.restTimeRemaining / Double(restTimeMinutes * 60))
            print("⏱️ Rest progress: \(Int(progress * 100))%")
            
            // Engagement-based countdown announcements
            self.handleRestCountdown(restTimeMinutes: restTimeMinutes, engagementLevel: entry.engagementLevel)
            
            if self.restTimeRemaining <= 0 {
                self.endSprintTimerProRestPeriod()
            }
        }
    }
    
    private func getRestMessage(for level: EngagementLevel, restTime: Int) -> String {
        switch level {
        case .beginner:
            return "Excellent work! Take your full \(restTime) minute\(restTime == 1 ? "" : "s") to recover. Walk around, stay loose, and get ready for the next one!"
            
        case .intermediate:
            return "Good sprint! \(restTime) minute\(restTime == 1 ? "" : "s") recovery. Use this time to prepare mentally for the next rep."
            
        case .advanced:
            return "Sprint complete. \(restTime) minute\(restTime == 1 ? "" : "s") rest. Stay focused and ready."
            
        case .elite:
            return "\(restTime) minute\(restTime == 1 ? "" : "s") recovery."
        }
    }
    
    private func handleRestCountdown(restTimeMinutes: Int, engagementLevel: EngagementLevel) {
        let remaining = Int(restTimeRemaining)
        
        if remaining == 60 && restTimeMinutes > 1 {
            let message = engagementLevel == .elite ? "1 minute." : "1 minute remaining. Start getting ready."
            speak(message)
        } else if remaining == 30 && restTimeMinutes > 1 {
            let message = engagementLevel == .elite ? "30 seconds." : "30 seconds left. Get focused."
            speak(message)
        } else if remaining == 10 {
            let message = engagementLevel == .elite ? "10 seconds." : "10 seconds! Get ready to explode!"
            speak(message)
        }
    }
    
    private func endSprintTimerProRestPeriod() {
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        
        guard let entry = getSprintTimerProEntry(for: distance) else { return }
        
        let readyMessage = getReadyMessage(for: entry.engagementLevel)
        speak(readyMessage)
        
        // Move to next sprint
        currentSet += 1
        
        // Start next sprint after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startNextSprintTimerProSprint()
        }
    }
    
    private func getReadyMessage(for level: EngagementLevel) -> String {
        switch level {
        case .beginner:
            return "Rest complete! You're ready for the next sprint. Let's keep building that speed!"
            
        case .intermediate:
            return "Time's up! Get ready to attack the next sprint!"
            
        case .advanced:
            return "Rest over. Execute the next rep!"
            
        case .elite:
            return "Ready."
        }
    }
    
    private func completeSprintTimerProSession() {
        print("🏁 Sprint Timer Pro session completed")
        
        guard let entry = getSprintTimerProEntry(for: distance) else { return }
        
        let completionMessage = getCompletionMessage(for: entry.engagementLevel)
        speak(completionMessage)
        
        // Move to cooldown phase
        currentPhase = .cooldown
    }
    
    private func getCompletionMessage(for level: EngagementLevel) -> String {
        switch level {
        case .beginner:
            return "Outstanding work! You completed your Sprint Timer Pro session! You're getting faster and stronger every day. Time for cooldown."
            
        case .intermediate:
            return "Excellent session! You pushed through and completed all your sprints. That's how you build speed! Moving to cooldown."
            
        case .advanced:
            return "Session complete! You executed with precision and power. Elite performance! Cooldown time."
            
        case .elite:
            return "Session complete. Cooldown phase."
        }
    }
    
    private func endAutonomousWorkout() {
        print("🏁 Ending autonomous Sprint Timer Pro workout...")
        
        // Stop GPS phase tracking if still active
        stopGPSPhaseTracking()
        
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
