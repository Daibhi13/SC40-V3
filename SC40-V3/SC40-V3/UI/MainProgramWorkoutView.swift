import SwiftUI
import Foundation
import Combine

// MARK: - Performance Optimized View Structure
// This file contains the main workout view with optimized components for better performance

struct MainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let sessionData: SessionData?
    let onWorkoutCompleted: ((CompletedWorkoutData) -> Void)?
    
    // Auto-sync with Apple Watch
    @StateObject private var syncManager = WorkoutSyncManager.shared
    
    // GPS Integration
    @StateObject private var gpsManager = GPSManager()
    
    // Watch Integration
    @StateObject private var watchSessionManager = WatchSessionManager.shared
    
    // Audio Integration
    @StateObject private var audioManager = SimpleAudioManager.shared
    
    // Enhanced AI Coaching Systems
    @StateObject private var biomechanicsEngine = BiomechanicsAnalysisEngine.shared
    @StateObject private var gpsFormEngine = GPSFormFeedbackEngine.shared
    @StateObject private var weatherEngine = WeatherAdaptationEngine.shared
    @StateObject private var mlRecommendationEngine = MLSessionRecommendationEngine.shared
    
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
    
    // Live Tracking State
    @State private var currentDistance: Double = 0.0
    @State private var currentTime: TimeInterval = 0.0
    @State private var currentSpeed: Double = 0.0
    @State private var isLiveTracking = false
    @State private var sprintStartTime: Date?
    @State private var liveTimer: Timer?
    
    // C25K-style coaching
    @State private var coachingMessage: String = ""
    @State private var showCoachingMessage: Bool = false
    @State private var isVoiceCoachingEnabled = true
    @State private var isGPSStopwatchActive = false
    
    // Live Performance Metrics
    @State private var sessionBestTime: Double?
    @State private var sessionAverageTime: Double = 0.0
    @State private var totalDistanceCovered: Double = 0.0
    
    // Stop Workout Warning
    @State private var showStopWarning = false
    @State private var workoutStartTime: Date?
    
    // Session Library Integration
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var isResting = false
    @State private var currentSet = 1
    
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
    
    // Sprint Session Library with Distance-Based Rest Times for 12-Week Program
    struct SprintSessionLibraryEntry {
        let distance: Int
        let restTimeMinutes: Int
        let sessionType: String
        let focus: String
        let level: String
        let voiceCoaching: String
        let weekRange: ClosedRange<Int>
    }
    
    private let sprintSessionLibrary: [SprintSessionLibraryEntry] = [
        // Week 1-3: Foundation Building
        SprintSessionLibraryEntry(distance: 10, restTimeMinutes: 1, sessionType: "Acceleration", focus: "Block Starts", level: "Foundation", voiceCoaching: "10-yard acceleration sprint. Focus on explosive start and drive phase. 1 minute rest.", weekRange: 1...3),
        SprintSessionLibraryEntry(distance: 15, restTimeMinutes: 1, sessionType: "Acceleration", focus: "Drive Phase", level: "Foundation", voiceCoaching: "15-yard sprint. Maintain low body position and powerful arm drive. 1 minute rest.", weekRange: 1...3),
        SprintSessionLibraryEntry(distance: 20, restTimeMinutes: 2, sessionType: "Acceleration", focus: "Early Acceleration", level: "Foundation", voiceCoaching: "20-yard acceleration sprint. Build speed gradually with good mechanics. 2 minutes rest.", weekRange: 1...4),
        SprintSessionLibraryEntry(distance: 25, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Power Development", level: "Foundation", voiceCoaching: "25-yard sprint. Focus on powerful drive phase and smooth transition. 2 minutes rest.", weekRange: 2...4),
        
        // Week 4-6: Development Phase
        SprintSessionLibraryEntry(distance: 30, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Acceleration Mechanics", level: "Development", voiceCoaching: "30-yard sprint. Maintain acceleration through drive phase. 2 minutes rest.", weekRange: 3...6),
        SprintSessionLibraryEntry(distance: 35, restTimeMinutes: 2, sessionType: "Drive Phase", focus: "Speed Building", level: "Development", voiceCoaching: "35-yard sprint. Build speed with controlled acceleration. 2 minutes rest.", weekRange: 4...6),
        SprintSessionLibraryEntry(distance: 40, restTimeMinutes: 3, sessionType: "Max Speed", focus: "Full Sprint", level: "Development", voiceCoaching: "40-yard maximum effort sprint. Give everything you have. 3 minutes rest.", weekRange: 4...8),
        SprintSessionLibraryEntry(distance: 45, restTimeMinutes: 3, sessionType: "Speed", focus: "Max Velocity", level: "Development", voiceCoaching: "45-yard sprint. Reach maximum velocity and maintain form. 3 minutes rest.", weekRange: 5...7),
        
        // Week 7-9: Intensification Phase
        SprintSessionLibraryEntry(distance: 50, restTimeMinutes: 3, sessionType: "Speed", focus: "Acceleration to Top Speed", level: "Intensification", voiceCoaching: "50-yard sprint. Accelerate through to top speed. 3 minutes rest.", weekRange: 6...9),
        SprintSessionLibraryEntry(distance: 55, restTimeMinutes: 3, sessionType: "Speed", focus: "Speed Maintenance", level: "Intensification", voiceCoaching: "55-yard sprint. Focus on maintaining top speed. 3 minutes rest.", weekRange: 7...9),
        SprintSessionLibraryEntry(distance: 60, restTimeMinutes: 4, sessionType: "Max Velocity", focus: "Flying Sprint", level: "Intensification", voiceCoaching: "60-yard flying sprint. Maximum velocity focus. 4 minutes rest.", weekRange: 7...10),
        SprintSessionLibraryEntry(distance: 65, restTimeMinutes: 4, sessionType: "Max Velocity", focus: "Speed Endurance", level: "Intensification", voiceCoaching: "65-yard sprint. Maintain velocity through the distance. 4 minutes rest.", weekRange: 8...10),
        
        // Week 10-12: Peak Performance Phase
        SprintSessionLibraryEntry(distance: 70, restTimeMinutes: 4, sessionType: "Speed Endurance", focus: "Lactate Tolerance", level: "Peak", voiceCoaching: "70-yard sprint. Push through fatigue and maintain speed. 4 minutes rest.", weekRange: 9...12),
        SprintSessionLibraryEntry(distance: 75, restTimeMinutes: 5, sessionType: "Top-End Speed", focus: "Peak Velocity", level: "Peak", voiceCoaching: "75-yard maximum sprint. Peak velocity development. 5 minutes rest.", weekRange: 10...12),
        SprintSessionLibraryEntry(distance: 80, restTimeMinutes: 5, sessionType: "Repeat Sprints", focus: "Speed Endurance", level: "Peak", voiceCoaching: "80-yard repeat sprint. Maintain speed across repetitions. 5 minutes rest.", weekRange: 10...12),
        SprintSessionLibraryEntry(distance: 90, restTimeMinutes: 5, sessionType: "Top-End Speed", focus: "Peak Performance", level: "Peak", voiceCoaching: "90-yard peak performance sprint. Elite level execution. 5 minutes rest.", weekRange: 11...12),
        SprintSessionLibraryEntry(distance: 100, restTimeMinutes: 6, sessionType: "Peak Velocity", focus: "Elite Performance", level: "Peak", voiceCoaching: "100-yard elite performance sprint. Maximum effort and speed. 6 minutes rest.", weekRange: 12...12)
    ]
    
    // Session Data Model
    struct SessionData {
        let week: Int
        let day: Int
        let sessionName: String
        let sessionFocus: String
        let sprintSets: [SprintSet]
        let drillSets: [DrillSet]
        let strideSets: [StrideSet]
        let sessionType: String
        let level: Int
        let estimatedDuration: Int
        let variety: Double
        let engagement: Double
    }
    
    // Completed Workout Data Model
    struct CompletedWorkoutData {
        let originalSession: SessionData
        let completedReps: [RepData]
        let totalDuration: TimeInterval
        let averageTime: Double?
        let bestTime: Double?
        let completionRate: Double
        let effortLevel: Int?
        let notes: String?
        let completionDate: Date
        
        init(originalSession: SessionData, completedReps: [RepData], totalDuration: TimeInterval) {
            self.originalSession = originalSession
            self.completedReps = completedReps
            self.totalDuration = totalDuration
            self.completionDate = Date()
            
            // Calculate performance metrics
            let completedTimes = completedReps.compactMap { $0.time }
            self.averageTime = completedTimes.isEmpty ? nil : completedTimes.reduce(0, +) / Double(completedTimes.count)
            self.bestTime = completedTimes.min()
            self.completionRate = Double(completedReps.filter { $0.isCompleted }.count) / Double(completedReps.count)
            self.effortLevel = nil // Can be set by user
            self.notes = nil // Can be set by user
        }
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
        // Use UnifiedSprintCoachView as the main workout interface
        UnifiedSprintCoachView(
            sessionConfig: createSessionConfigFromSessionData(),
            onClose: {
                presentationMode.wrappedValue.dismiss()
            }
        )
        .navigationBarHidden(true)
        .onAppear {
            setupWorkoutFromSessionData()
            setupWatchIntegration()
            setupAutoSyncWithWatch()
            setupEnhancedCoachingSystems()
        }
        .onDisappear {
            cleanupEnhancedSystems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchWorkoutStartRequested)) { notification in
            if let sessionId = notification.object as? UUID {
                handleWatchWorkoutStart(sessionId: sessionId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchWorkoutEndRequested)) { notification in
            if let sessionId = notification.object as? UUID {
                handleWatchWorkoutEnd(sessionId: sessionId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchRepCompletionRequested)) { notification in
            if let sessionId = notification.object as? UUID {
                handleWatchRepCompletion(sessionId: sessionId)
            }
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
    
    // MARK: - Session Configuration Creation
    private func createSessionConfigFromSessionData() -> SessionConfiguration {
        guard let session = sessionData else {
            // Default configuration if no session data - use dynamic naming
            let namingService = DynamicSessionNamingService.shared
            let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Beginner"
            let sessionConfig = namingService.generateSessionConfiguration(
                userLevel: userLevel,
                distance: 40,
                reps: 4,
                intensity: "Moderate",
                weekNumber: 1,
                dayInWeek: 1
            )
            
            return SessionConfiguration(
                sessionName: sessionConfig.name,
                sessionType: sessionConfig.type,
                distance: 40,
                reps: 4,
                restMinutes: 2,
                description: "Standard sprint workout",
                difficulty: "Intermediate",
                estimatedDuration: "15 min",
                focus: "Maximum speed development",
                hasWarmup: true,
                hasStretching: true,
                hasDrills: true,
                hasStrides: true,
                hasCooldown: true,
                workoutVariation: .standard
            )
        }
        
        // Convert SessionData to SessionConfiguration
        let workoutVariation = determineWorkoutVariationFromSession(session)
        let difficulty = determineDifficultyFromSession(session)
        
        return SessionConfiguration(
            sessionName: session.sessionName,
            sessionType: session.sessionType,
            distance: session.sprintSets.first?.distance ?? 40,
            reps: session.sprintSets.count,
            restMinutes: session.sprintSets.first?.restTime ?? 2,
            description: "Program workout: \(session.sessionFocus)",
            difficulty: difficulty,
            estimatedDuration: "\(session.estimatedDuration) min",
            focus: session.sessionFocus,
            hasWarmup: true,
            hasStretching: true,
            hasDrills: !session.drillSets.isEmpty,
            hasStrides: !session.strideSets.isEmpty,
            hasCooldown: true,
            workoutVariation: workoutVariation
        )
    }
    
    private func determineWorkoutVariationFromSession(_ session: SessionData) -> SessionConfiguration.WorkoutVariation {
        // Check if it's a pyramid (distances go up then down)
        let distances = session.sprintSets.map { $0.distance }
        if isPyramidPattern(distances) {
            return .pyramid
        }
        
        // Check if it's a ladder (progressively increasing distances)
        if isLadderPattern(distances) {
            return .ladder
        }
        
        // Check if it's intervals (high reps with short rest)
        if session.sprintSets.count >= 8 && (session.sprintSets.first?.restTime ?? 0) <= 90 {
            return .intervals
        }
        
        // Check if it's flying sprints (longer distances)
        if (session.sprintSets.first?.distance ?? 0) >= 50 {
            return .flying
        }
        
        // Check if it's acceleration (short distances)
        if (session.sprintSets.first?.distance ?? 0) <= 25 {
            return .acceleration
        }
        
        return .standard
    }
    
    private func isPyramidPattern(_ distances: [Int]) -> Bool {
        guard distances.count >= 3 else { return false }
        let midPoint = distances.count / 2
        let firstHalf = Array(distances[0..<midPoint])
        let secondHalf = Array(distances[midPoint...].reversed())
        return firstHalf == secondHalf
    }
    
    private func isLadderPattern(_ distances: [Int]) -> Bool {
        guard distances.count >= 3 else { return false }
        for i in 1..<distances.count {
            if distances[i] <= distances[i-1] {
                return false
            }
        }
        return true
    }
    
    private func determineDifficultyFromSession(_ session: SessionData) -> String {
        let totalVolume = session.sprintSets.reduce(0) { $0 + $1.distance }
        switch totalVolume {
        case 0...200: return "Beginner"
        case 201...400: return "Intermediate"
        default: return "Advanced"
        }
    }
    
    // MARK: - Main Workout View (exact copy of SprintTimerProWorkoutView UI)
    private var mainWorkoutView: some View {
        ZStack {
            // Enhanced gradient background with depth and sophistication
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.25),
                    Color(red: 0.12, green: 0.18, blue: 0.35),
                    Color(red: 0.18, green: 0.25, blue: 0.45),
                    Color(red: 0.22, green: 0.28, blue: 0.52)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle overlay pattern for texture
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.clear,
                            Color.black.opacity(0.05)
                        ],
                        center: .topTrailing,
                        startRadius: 100,
                        endRadius: 800
                    )
                )
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Header with glassmorphism effect
                HStack {
                    Button(action: {
                        stopWorkoutEarly()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.15), value: false)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("SPRINT COACH")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(2)
                        
                        Text("Training Session")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Settings or info with haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.15), value: false)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Scrollable Content - Same structure as SprintTimerProWorkoutView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Streamlined Sprint Coach Interface
                        VStack(spacing: 20) {
                            
                            // Core Sprint Metrics - Simplified
                            VStack(spacing: 16) {
                                // Session Header - Compact
                                HStack {
                                    Circle()
                                        .fill(isRunning ? Color.green : Color.orange)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(isRunning ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRunning)
                                    
                                    Text(sessionData?.sessionName.uppercased() ?? "SPRINT SESSION")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(1.0)
                                    
                                    Spacer()
                                    
                                    Text("REP \(currentRep)/\(totalReps)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                                
                                // Core GPS Stopwatch - Prominent Display
                                VStack(spacing: 12) {
                                    // GPS Stopwatch Display
                                    HStack(spacing: 20) {
                                        // Distance
                                        VStack(spacing: 4) {
                                            Text(formatLiveDistance(gpsManager.distance))
                                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                            Text("YARDS")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.blue.opacity(0.8))
                                        }
                                        
                                        Divider()
                                            .frame(height: 40)
                                            .background(Color.white.opacity(0.3))
                                        
                                        // Time
                                        VStack(spacing: 4) {
                                            Text(formatLiveTime(gpsManager.elapsedTime))
                                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                            Text("TIME")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.green.opacity(0.8))
                                        }
                                        
                                        Divider()
                                            .frame(height: 40)
                                            .background(Color.white.opacity(0.3))
                                        
                                        // Speed
                                        VStack(spacing: 4) {
                                            Text(formatLiveSpeed(gpsManager.currentSpeed))
                                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                            Text("MPH")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.orange.opacity(0.8))
                                        }
                                    }
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                }
                                
                                // Rest Timer - Only show during rest phase
                                if currentPhase == .resting {
                                    VStack(spacing: 8) {
                                        Text("REST TIMER")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.7))
                                            .tracking(1.0)
                                        
                                        Text(formatCountdownDisplay(phaseTimeRemaining))
                                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                                            .foregroundColor(phaseTimeRemaining < 30 ? .red : .orange)
                                        
                                        Text("UNTIL NEXT SPRINT")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Removed duplicate timeline - keeping only the phase indicator dots
                            }
                            .padding(.horizontal, 20)
                            
                            // Sprint Distance & Type - Compact
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(getMainSprintDistance()) YARD SPRINTS")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    // TODO: Uncomment when WorkoutTypeAnalyzer is implemented
                                    // Text(workoutCategory.rawValue)
                                    //     .font(.system(size: 12, weight: .medium))
                                    //     .foregroundColor(.orange.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                // TODO: Uncomment when WorkoutTypeAnalyzer is implemented
                                // Image(systemName: workoutCategory.icon)
                                //     .font(.system(size: 20, weight: .semibold))
                                //     .foregroundColor(Color(red: workoutCategory.color.red, green: workoutCategory.color.green, blue: workoutCategory.color.blue))
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                            
                            // Dynamic Action Controls - Moved Higher Up
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
                                // Enhanced Workout Controls - Always Visible During Workout
                                VStack(spacing: 16) {
                                    // Main Control Row
                                    HStack(spacing: 20) {
                                        // Pause/Play Button
                                        Button(action: togglePausePlay) {
                                            ZStack {
                                                Circle()
                                                    .fill(isPaused ? Color.green : Color.orange)
                                                    .frame(width: 75, height: 75)
                                                
                                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        // Fast Forward Button
                                        Button(action: fastForward) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 75, height: 75)
                                                
                                                Image(systemName: "forward.fill")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        // Stop Button with Warning
                                        Button(action: showStopWorkoutWarning) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 75, height: 75)
                                                
                                                Image(systemName: "stop.fill")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    // Control Labels
                                    HStack(spacing: 20) {
                                        Text(isPaused ? "RESUME" : "PAUSE")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 75)
                                        
                                        Text("SKIP")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 75)
                                        
                                        Text("STOP")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 75)
                                    }
                                }
                                .padding(.vertical, 20)
                            }
                            
                            // Current Phase Indicator - Simplified
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    ForEach(WorkoutPhase.allCases.prefix(5), id: \.self) { phase in
                                        Circle()
                                            .fill(phase == currentPhase ? Color.orange : Color.white.opacity(0.3))
                                            .frame(width: 10, height: 10)
                                            .scaleEffect(phase == currentPhase ? 1.3 : 1.0)
                                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPhase)
                                    }
                                }
                                
                                Text(getCurrentPhaseName().uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .tracking(1.0)
                            }
                            .padding(.vertical, 16)
                            
                            if currentPhase == .sprints {
                                // Live Tracking Display (C25K Style)
                                VStack(spacing: 20) {
                                    // Current Phase Display
                                    Text(currentPhase.title.uppercased() + " \(formatTime(Int(phaseTimeRemaining)))")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(1)
                                    
                                    // Live Metrics Bar (C25K Style)
                                    HStack(spacing: 0) {
                                        // Since Start
                                        VStack(spacing: 4) {
                                            Text("SINCE\nSTART")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                                .multilineTextAlignment(.center)
                                            Text(formatTime(Int(currentTime)))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        Text("|")
                                            .font(.system(size: 20, weight: .thin))
                                            .foregroundColor(.white.opacity(0.3))
                                        
                                        // Next: Rep/Rest
                                        VStack(spacing: 4) {
                                            Text("NEXT:\n\(currentPhase == .sprints ? "REST" : "REP")")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                                .multilineTextAlignment(.center)
                                            Text(getNextPhaseTime())
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        Text("|")
                                            .font(.system(size: 20, weight: .thin))
                                            .foregroundColor(.white.opacity(0.3))
                                        
                                        // Time Left
                                        VStack(spacing: 4) {
                                            Text("TIME\nLEFT")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                                .multilineTextAlignment(.center)
                                            Text(formatTime(calculateTimeLeft()))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(12)
                                    
                                    // Sprint Progress Indicator
                                    VStack(spacing: 8) {
                                        HStack {
                                            ForEach(1...totalReps, id: \.self) { rep in
                                                Circle()
                                                    .fill(rep < currentRep ? Color.green : 
                                                          rep == currentRep ? Color.yellow : 
                                                          Color.white.opacity(0.3))
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                        Text("Sprint \(currentRep) of \(totalReps)")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Text("\(getMainSprintDistance()) yards")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    
                                    // Sprint-specific information only
                                    VStack(spacing: 12) {
                                        Text("Current Sprint: \(getMainSprintDistance()) yards")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("Rep \(currentRep) of \(totalReps)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.bottom, 10)
                                }
                                .padding(.bottom, 20)
                            } else if currentPhase == .drill || currentPhase == .strides {
                                // Phase-specific information only
                                VStack(spacing: 12) {
                                    Text(getCurrentPhaseName().uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(1)
                                    
                                    Text("Follow the guided instructions")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.bottom, 10)
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
                        
                        // Removed duplicate workout status section
                        
                        // Complete Workout Breakdown - All Drills, Strides, and Sprints
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Complete Workout")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("Session Library")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 12) {
                                    // DRILLS SECTION - List all individual drills
                                    if let session = sessionData, !session.drillSets.isEmpty {
                                        WorkoutSectionHeader(
                                            title: "DRILLS (\(session.drillSets.count))",
                                            icon: "figure.run",
                                            isActive: currentPhase == .drill,
                                            isCompleted: isPhaseCompleted(.drill)
                                        )
                                        
                                        ForEach(Array(session.drillSets.enumerated()), id: \.offset) { index, drill in
                                            WorkoutItemRow(
                                                number: index + 1,
                                                name: drill.name,
                                                details: "\(drill.duration/60)min • \(drill.restTime/60)min rest",
                                                isActive: currentPhase == .drill,
                                                isCompleted: isPhaseCompleted(.drill)
                                            )
                                        }
                                    }
                                    
                                    // STRIDES SECTION - List all individual strides
                                    if let session = sessionData, !session.strideSets.isEmpty {
                                        WorkoutSectionHeader(
                                            title: "STRIDES (\(session.strideSets.count))",
                                            icon: "figure.walk",
                                            isActive: currentPhase == .strides,
                                            isCompleted: isPhaseCompleted(.strides)
                                        )
                                        
                                        ForEach(Array(session.strideSets.enumerated()), id: \.offset) { index, stride in
                                            WorkoutItemRow(
                                                number: index + 1,
                                                name: "\(stride.distance) Yard Stride",
                                                details: "Build-up • \(stride.restTime/60)min rest",
                                                isActive: currentPhase == .strides,
                                                isCompleted: isPhaseCompleted(.strides)
                                            )
                                        }
                                    }
                                    
                                    // SPRINTS SECTION - List all individual sprints with live tracking
                                    if let session = sessionData, !session.sprintSets.isEmpty {
                                        WorkoutSectionHeader(
                                            title: "SPRINTS (\(session.sprintSets.count))",
                                            icon: "bolt.fill",
                                            isActive: [.sprints, .resting].contains(currentPhase),
                                            isCompleted: isPhaseCompleted(.sprints)
                                        )
                                        
                                        ForEach(Array(session.sprintSets.enumerated()), id: \.offset) { index, sprint in
                                            let repNumber = index + 1
                                            let isCurrentRep = repNumber == currentRep && [.sprints, .resting].contains(currentPhase)
                                            let isCompletedRep = repNumber < currentRep || isPhaseCompleted(.sprints)
                                            let repTime = completedReps.first(where: { $0.rep == repNumber })?.time
                                            
                                            WorkoutSprintRow(
                                                number: repNumber,
                                                distance: sprint.distance,
                                                restTime: sprint.restTime/60,
                                                time: repTime,
                                                isActive: isCurrentRep,
                                                isCompleted: isCompletedRep,
                                                targetTime: sprint.targetTime
                                            )
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxHeight: 300) // Limit height for scrolling
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                        // Enhanced Live Rep Log at bottom
                        EnhancedLiveRepLog(
                            currentPhase: currentPhase,
                            completedReps: completedReps,
                            currentRep: currentRep,
                            totalReps: totalReps,
                            sessionData: sessionData,
                            gpsManager: gpsManager
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Extra padding for safe area
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
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.vertical, 8)
                    }
                }
            }
        )
    }
    
    private func isPhaseCompleted(_ phase: WorkoutPhase) -> Bool {
        let phaseIndex = WorkoutPhase.allCases.firstIndex(of: phase) ?? 0
        let currentIndex = WorkoutPhase.allCases.firstIndex(of: currentPhase) ?? 0
        return currentIndex > phaseIndex
    }
    
    // MARK: - SessionLibrary Integration Functions
    
    private func calculateTotalDuration() -> Int {
        // Calculate total workout duration based on session data
        guard let _ = sessionData else { return 47 }
        
        let warmupDuration = 5 // minutes
        let cooldownDuration = 5 // minutes
        
        // Calculate sprint phase duration based on reps and rest
        let sprintDuration = calculateSprintDuration()
        
        return warmupDuration + sprintDuration + cooldownDuration
    }
    
    private func calculateSprintDuration() -> Int {
        // Calculate sprint phase duration from session data
        guard sessionData != nil else { return 6 }
        
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
        
        // Start workout music
        audioManager.startWorkoutMusic()
        
        // Start voice coaching
        startVoiceCoaching()
        
        // Provide haptic feedback
        triggerHapticFeedback(.start)
        
        // Start phase progression with timers
    
    // Initialize GPS stopwatch for sprint tracking
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
        
        // Initialize Rep Log with both strides and sprints
        var allReps: [RepData] = []
        
        // Add stride reps to Rep Log
        for (index, strideSet) in session.strideSets.enumerated() {
            let strideRep = RepData(
                rep: index + 1,
                time: nil,
                isCompleted: false,
                repType: .stride,
                distance: strideSet.distance,
                timestamp: Date()
            )
            allReps.append(strideRep)
        }
        
        // Add sprint reps to Rep Log
        for (index, sprintSet) in session.sprintSets.enumerated() {
            // Note: ML training goals would be integrated here in future versions
            let sprintRep = RepData(
                rep: index + 1,
                time: nil,
                isCompleted: false,
                repType: .sprint,
                distance: sprintSet.distance,
                timestamp: Date()
            )
            allReps.append(sprintRep)
        }
        
        // If no session data, create default reps
        if allReps.isEmpty {
            allReps = Array(1...totalReps).map { rep in
                RepData(rep: rep, time: nil, isCompleted: false, repType: RepData.RepType.sprint, distance: getMainSprintDistance(), timestamp: Date())
            }
        }
        
        completedReps = allReps
        
        // Set phase durations based on session
        phaseTimeRemaining = currentPhase.duration
    }
    
    // MARK: - Enhanced AI Coaching Systems
    
    private func setupEnhancedCoachingSystems() {
        // Start biomechanics analysis for real-time form feedback
        biomechanicsEngine.startBiomechanicsAnalysis()
        
        // Initialize GPS form feedback for sprint detection
        let sprintDistance = sessionData?.sprintSets.first?.distance ?? 40
        gpsFormEngine.startSprintTracking(targetDistance: Double(sprintDistance))
        
        // Apply weather adaptations to the current session
        applyWeatherAdaptationsToSession()
        
        // Generate ML-based session recommendations
        Task {
            await generateMLRecommendationsForSession()
        }
        
        print("🤖 Enhanced AI coaching systems activated for 12-week program")
    }
    
    private func cleanupEnhancedSystems() {
        // Stop biomechanics analysis
        let _ = biomechanicsEngine.stopBiomechanicsAnalysis()
        
        // Stop GPS tracking
        let _ = gpsFormEngine.stopSprintTracking()
        
        print("🤖 Enhanced AI coaching systems deactivated")
    }
    
    private func applyWeatherAdaptationsToSession() {
        guard let session = sessionData else { return }
        
        let trainingSession = TrainingSession(
            id: UUID(),
            week: session.week,
            day: session.day,
            type: session.sessionType,
            focus: session.sessionFocus,
            sprints: session.sprintSets.map { SC40_V3.SprintSet(distanceYards: $0.distance, reps: 1, intensity: "max") },
            accessoryWork: [],
            notes: "12-week program session"
        )
        
        let adaptations = weatherEngine.getWorkoutAdaptationsForSession(trainingSession)
        
        if !adaptations.isEmpty {
            print("🌤️ Applied \(adaptations.count) weather adaptations to 12-week program session")
            
            // Apply adaptations to session parameters
            for adaptation in adaptations {
                applyAdaptationToWorkout(adaptation)
            }
        }
        
        // Check if workout should be postponed due to weather
        if weatherEngine.shouldPostponeWorkout() {
            announceVoiceCoaching("Weather conditions may not be optimal for outdoor training. Consider indoor alternatives.")
        }
    }
    
    private func applyAdaptationToWorkout(_ adaptation: WeatherAdaptationEngine.WorkoutAdaptation) {
        switch adaptation.modification.parameter {
        case "intensity":
            // Reduce intensity if weather is challenging
            if adaptation.modification.adaptedValue < adaptation.modification.originalValue {
                announceVoiceCoaching("Adjusting intensity due to weather conditions. Focus on form over speed.")
            }
        case "rest_periods":
            // Extend rest periods for hot weather
            if adaptation.modification.adaptedValue > adaptation.modification.originalValue {
                announceVoiceCoaching("Extended rest periods recommended due to temperature. Stay hydrated!")
            }
        case "warmup_duration":
            // Extend warmup for cold weather
            if adaptation.modification.adaptedValue > adaptation.modification.originalValue {
                announceVoiceCoaching("Extended warmup recommended due to cold conditions.")
            }
        default:
            break
        }
    }
    
    private func generateMLRecommendationsForSession() async {
        // Create mock user profile based on session data
        let _ = UserProfile(
            name: "Program User",
            email: "user@example.com",
            gender: "Other",
            age: 25,
            height: 180,
            weight: 75,
            personalBests: ["40yd": 4.8],
            level: "intermediate",
            baselineTime: 4.8,
            frequency: 3
        )
        
        print("🧠 ML recommendations system initialized for 12-week program session")
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
        triggerHapticFeedback(.medium)
        
        showCoachingCue("Workout resumed! 🔄")
    }
    
    private func completeCurrentRep(time: Double? = nil) {
        guard currentRep <= totalReps else { return }
        
        // Determine current rep type and distance based on workout phase
        let currentRepType: RepData.RepType
        let currentDistance: Int
        
        switch currentPhase {
        case .strides:
            currentRepType = .stride
            currentDistance = sessionData?.strideSets.first?.distance ?? 20
        case .sprints:
            currentRepType = .sprint
            currentDistance = getMainSprintDistance()
        default:
            currentRepType = .sprint
            currentDistance = getMainSprintDistance()
        }
        
        // Find the correct rep to update based on type and current phase
        var repIndex = -1
        var repCounter = 0
        
        for (index, rep) in completedReps.enumerated() {
            if rep.repType == currentRepType && !rep.isCompleted {
                repCounter += 1
                if repCounter == currentRep {
                    repIndex = index
                    break
                }
            }
        }
        
        // Update the completed rep with actual data
        if repIndex >= 0 && repIndex < completedReps.count {
            completedReps[repIndex] = RepData(
                rep: currentRep,
                time: time,
                isCompleted: true,
                repType: currentRepType,
                distance: currentDistance,
                timestamp: Date()
            )
        }
        
        // Provide feedback
        if let time = time {
            announceVoiceCoaching("Rep \(currentRep) completed in \(String(format: "%.2f", time)) seconds! 🎯")
            showCoachingCue("Rep \(currentRep): \(String(format: "%.2f", time))s ⚡")
        } else {
            announceVoiceCoaching("Rep \(currentRep) completed! 💪")
            showCoachingCue("Rep \(currentRep) completed! ✅")
        }
        
        // Haptic feedback for rep completion
        triggerHapticFeedback(.medium)
        
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
        let restTime = getRestTime()
        phaseTimeRemaining = restTime
        
        // Enhanced rest coaching with session library data
        let restMinutes = restTime / 60
        announceVoiceCoaching("Rest for \(restMinutes) minutes. Prepare for rep \(currentRep)! ⏱️")
        showCoachingCue("Rest: \(restMinutes) min - Rep \(currentRep) next 🔄")
        
        // Start rest timer
        startPhaseTimer()
    }
    
    private func completeSprintPhase() {
        currentPhase = .cooldown
        phaseTimeRemaining = WorkoutPhase.cooldown.duration
        
        announceVoiceCoaching("All sprints completed! Time to cool down! 🌟")
        showCoachingCue("Sprint phase complete! Cool down time 🎉")
        
        // Start cooldown timer
        startPhaseTimer()
    }
    
    private func recordSprintTime(_ time: Double) {
        // This would be called from GPS stopwatch or manual timing
        completeCurrentRep(time: time)
    }
    
    private func skipCurrentRep() {
        // Allow user to skip a rep if needed (injury, equipment issues, etc.)
        completeCurrentRep(time: nil)
        announceVoiceCoaching("Rep \(currentRep - 1) skipped. Moving to next! ⏭️")
    }
    
    // MARK: - Watch Integration Functions
    
    private func setupWatchIntegration() {
        // Start GPS data sync with Watch when workout begins
        if isRunning {
            watchSessionManager.startGPSDataSync(with: gpsManager)
        }
    }
    
    private func handleWatchWorkoutStart(sessionId: UUID) {
        // Start workout from Watch command
        if !isRunning {
            startSprintCoachWorkout()
        }
    }
    
    private func handleWatchWorkoutEnd(sessionId: UUID) {
        // End workout from Watch command
        if isRunning {
            completeWorkout()
        }
    }
    
    private func handleWatchRepCompletion(sessionId: UUID) {
        // Complete current rep from Watch command
        if currentPhase == .sprints {
            completeCurrentRep()
        }
    }
    
    // MARK: - GPS Sprint Control Functions
    
    private func startGPSSprint() {
        guard gpsManager.isReadyForSprint else {
            if !gpsManager.isAuthorized {
                gpsManager.requestLocationPermission()
            }
            return
        }
        
        // Set the target distance for this sprint
        let distanceYards = Double(getMainSprintDistance())
        gpsManager.setSprintDistance(yards: distanceYards)
        
        // Set up GPS callbacks
        setupGPSCallbacks()
        
        // Start GPS sprint tracking
        gpsManager.startSprint()
        
        // Enhanced audio coaching for sprint start
        audioManager.handleSprintStart()
        triggerHapticFeedback(.start)
    }
    
    private func stopGPSSprint() {
        gpsManager.stopSprint()
        announceVoiceCoaching("Sprint stopped manually! ⏹️")
        triggerHapticFeedback(.medium)
    }
    
    private func setupGPSCallbacks() {
        // Callback when sprint is completed automatically
        gpsManager.onSprintCompleted = { (result: SprintResult) in
            Task { @MainActor in
                // Note: No weak self needed since MainProgramWorkoutView is a struct
                self.handleGPSSprintCompletion(result)
            }
        }
        
        // Callback for distance updates during sprint
        gpsManager.onDistanceUpdate = { (distance: Double, time: TimeInterval) in
            Task { @MainActor in
                // Provide audio feedback at milestones
                let distanceYards = distance / 0.9144
                let targetYards = Double(self.getMainSprintDistance())
                
                if distanceYards >= targetYards * 0.5 && distanceYards < targetYards * 0.6 {
                    self.announceVoiceCoaching("Halfway! Keep pushing! 💪")
                } else if distanceYards >= targetYards * 0.8 && distanceYards < targetYards * 0.9 {
                    self.announceVoiceCoaching("Almost there! Final push! 🚀")
                }
            }
        }
    }
    
    private func handleGPSSprintCompletion(_ result: SprintResult) {
        let time = result.time
        let _ = result.accuracy
        
        // Use AudioManager for enhanced coaching
        audioManager.handleSprintComplete(time: time)
        
        // Complete the rep with GPS time
        completeCurrentRep(time: time)
        
        // Provide additional feedback for good performance
        if time < 5.0 { // Under 5 seconds for 40 yards is quite good
            announceVoiceCoaching("Excellent speed! 🔥")
            triggerHapticFeedback(.end)
        }
    }
    
    // MARK: - Phase Timer Management
    
    private func startPhaseTimer() {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if phaseTimeRemaining > 0 {
                phaseTimeRemaining -= 1
            } else {
                handlePhaseCompletion()
            }
        }
    }
    
    private func startPhaseProgression() {
        // Start the overall workout progression
        startPhaseTimer()
        providePhaseCoaching()
    }
    
    private func handlePhaseCompletion() {
        phaseTimer?.invalidate()
        
        let _ = currentPhase
        
        switch currentPhase {
        case .warmup:
            currentPhase = .stretch
            phaseTimeRemaining = WorkoutPhase.stretch.duration
            audioManager.updateWorkoutPhase(currentPhase)
            startPhaseTimer()
            
        case .stretch:
            currentPhase = .drill
            phaseTimeRemaining = WorkoutPhase.drill.duration
            audioManager.updateWorkoutPhase(currentPhase)
            startPhaseTimer()
            
        case .drill:
            currentPhase = .strides
            phaseTimeRemaining = WorkoutPhase.strides.duration
            audioManager.updateWorkoutPhase(currentPhase)
            startPhaseTimer()
            
        case .strides:
            currentPhase = .sprints
            currentRep = 1
            audioManager.updateWorkoutPhase(currentPhase)
            
            // Automatically start GPS monitoring for movement detection
            startAutomaticSprintDetection()
            
            showCoachingCue("Sprint \(currentRep) of \(totalReps) - Ready for automatic detection! ⚡")
            
        case .sprints:
            // This is handled by completeCurrentRep()
            break
            
        case .resting:
            // Rest period complete, ready for next sprint
            if currentRep <= totalReps {
                currentPhase = .sprints
                
                // Automatically prepare for next sprint detection
                startAutomaticSprintDetection()
                
                announceVoiceCoaching("Rest complete! Ready for sprint \(currentRep) of \(totalReps)! 🚀")
                showCoachingCue("Sprint \(currentRep) of \(totalReps) - Movement detection active! ⚡")
            }
            
        case .cooldown:
            currentPhase = .completed
            completeWorkout()
            
        case .completed:
            break
        }
    }
    
    private func completeWorkout() {
        // Stop all timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        
        // Stop GPS tracking
        stopGPSStopwatch()
        
        // Create completion data and send back to TrainingView
        if let sessionData = sessionData {
            let completedWorkout = CompletedWorkoutData(
                originalSession: sessionData,
                completedReps: completedReps,
                totalDuration: TimeInterval(calculateTotalDuration() * 60) // Convert minutes to seconds
            )
            
            // Call completion callback
            onWorkoutCompleted?(completedWorkout)
        }
        
        // Final coaching
        announceVoiceCoaching("Workout complete! Great job! 🎉")
        showCoachingCue("Workout Complete! 🏆")
        
        // Show completion sheet
        showCompletionSheet = true
        
        // Haptic feedback
        triggerHapticFeedback(.end)
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
    
    // MARK: - Missing UI Functions
    
    private func fastForward() {
        // Fast forward to next phase
        advanceToNextPhase()
        triggerHapticFeedback(.medium)
    }
    
    private func showStopWorkoutWarning() {
        // Show confirmation dialog before stopping workout
        stopWorkoutEarly()
    }
    
    private func stopWorkoutEarly() {
        // Stop workout early
        isRunning = false
        isPaused = false
        
        // Stop all timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        
        // Stop GPS tracking
        stopGPSStopwatch()
        
        // Provide feedback
        announceVoiceCoaching("Workout stopped early. Great effort! 💪")
        triggerHapticFeedback(.end)
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
    
    // TODO: Implement WorkoutTypeAnalyzer before enabling
    /*
    private var workoutCategory: WorkoutTypeAnalyzer.WorkoutCategory {
        guard let session = sessionData,
              let firstSprint = session.sprintSets.first else {
            return .speedDistances
        }
        
        return WorkoutTypeAnalyzer.getWorkoutCategoryForSession(
            name: session.sessionName,
            focus: session.sessionFocus,
            distance: firstSprint.distance,
            reps: session.sprintSets.count
        )
    }
    */
    
    // MARK: - Session Description Functions
    
    private func getDrillsDescription(_ drillSets: [DrillSet]) -> String {
        if drillSets.isEmpty { return "No drills scheduled" }
        
        let drillNames = drillSets.map { $0.name }.joined(separator: ", ")
        let totalDuration = drillSets.reduce(0) { $0 + $1.duration }
        return "\(drillSets.count) drills • \(totalDuration/60)min • \(drillNames)"
    }
    
    private func getStridesDescription(_ strideSets: [StrideSet]) -> String {
        if strideSets.isEmpty { return "No strides scheduled" }
        
        let firstStride = strideSets.first!
        let restMinutes = firstStride.restTime / 60
        return "\(strideSets.count) x \(firstStride.distance) yards • \(restMinutes)min rest"
    }
    
    private func getSprintsDescription(_ sprintSets: [SprintSet]) -> String {
        if sprintSets.isEmpty { return "No sprints scheduled" }
        
        let firstSprint = sprintSets.first!
        let restMinutes = firstSprint.restTime / 60
        return "\(sprintSets.count) x \(firstSprint.distance) yards • \(restMinutes)min rest"
    }
    
    // MARK: - Dynamic Summary Functions
    
    private func getCurrentPhaseStatus() -> String {
        switch currentPhase {
        case .warmup: return "Warming Up"
        case .stretch: return "Stretching"
        case .drill: return "Drill Phase"
        case .strides: return "Build-Up Strides"
        case .sprints: return "Sprint \(currentRep)/\(totalReps)"
        case .resting: return "Rest Period"
        case .cooldown: return "Cooling Down"
        case .completed: return "Complete!"
        }
    }
    
    private func getPhaseTimeDisplay() -> String {
        let minutes = phaseTimeRemaining / 60
        let seconds = phaseTimeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Automatic Movement Detection Functions
    
    private func getMovementDetectionColor() -> Color {
        if gpsManager.isTracking {
            return .green // Currently tracking movement
        } else if gpsManager.isReadyForSprint {
            return .orange // Ready to detect movement
        } else {
            return .red // GPS not ready
        }
    }
    
    private func getMovementDetectionStatus() -> String {
        if gpsManager.isTracking {
            return "Tracking Sprint"
        } else if gpsManager.isReadyForSprint {
            return "Ready - Waiting for Movement"
        } else {
            return "GPS Acquiring Signal"
        }
    }
    
    private func getMovementInstructions() -> String {
        if gpsManager.isTracking {
            return "Sprint detected! Keep running to complete the \(getMainSprintDistance()) yards"
        } else if gpsManager.isReadyForSprint {
            return "Start your sprint when ready. Movement will be detected automatically."
        } else {
            return "Please wait while GPS acquires your location for automatic sprint detection"
        }
    }
    
    private func shouldShowManualControls() -> Bool {
        // Show manual controls if GPS has been trying for more than 30 seconds
        // or if GPS accuracy is poor, or if user has been waiting too long
        return !gpsManager.isReadyForSprint || gpsManager.gpsStatus == .error || gpsManager.gpsStatus == .denied
    }
    
    private func getTotalRepsForPhase() -> Int {
        switch currentPhase {
        case .drill:
            return sessionData?.drillSets.count ?? 4
        case .strides:
            return sessionData?.strideSets.count ?? 3
        case .sprints:
            return sessionData?.sprintSets.count ?? 6
        default:
            return 1
        }
    }
    
    private func getTargetDistanceForPhase() -> Int {
        switch currentPhase {
        case .drill:
            return 20 // Drills are typically 20 yards
        case .strides:
            return sessionData?.strideSets.first?.distance ?? 20
        case .sprints:
            return getMainSprintDistance()
        default:
            return 20
        }
    }
    
    // MARK: - Live Metrics Helper Functions
    
    private func formatLiveDistance(_ distance: Double) -> String {
        let yards = distance * 1.09361 // Convert meters to yards
        return String(format: "%.1f", yards)
    }
    
    private func formatLiveTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatLiveSpeed(_ speed: Double) -> String {
        let mph = speed * 2.237 // Convert m/s to mph
        return String(format: "%.1f", mph)
    }
    
    private func formatCountdownDisplay(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func getLiveProgressPercentage() -> Double {
        let targetDistanceMeters = Double(getTargetDistanceForPhase()) * 0.9144
        return min((gpsManager.distance / targetDistanceMeters) * 100, 100)
    }
    
    private func getLiveGPSStatus() -> String {
        if gpsManager.isTracking {
            return "ACTIVE"
        } else if gpsManager.isReadyForSprint {
            return "READY"
        } else {
            return "WAIT"
        }
    }
    
    private func getLiveGPSStatusColor() -> Color {
        if gpsManager.isTracking {
            return .green
        } else if gpsManager.isReadyForSprint {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getPhaseProgress() -> Double {
        let totalDuration = Double(currentPhase.duration)
        let elapsed = totalDuration - Double(phaseTimeRemaining)
        return min(elapsed / totalDuration, 1.0)
    }

    // MARK: - Automatic Workout Flow Functions

    private func startAutomaticSprintDetection() {
        // Set up GPS for automatic sprint detection
        guard gpsManager.isAuthorized else {
            gpsManager.requestLocationPermission()
            return
        }
        
        // Configure GPS for automatic sprint detection
        let distanceYards = Double(getMainSprintDistance())
        gpsManager.setSprintDistance(yards: distanceYards)
        
        // Set up automatic detection callbacks
        setupAutomaticDetectionCallbacks()
        
        // Automatically start GPS sprint tracking
        gpsManager.startSprint()
        
        announceVoiceCoaching("GPS tracking active. Start your sprint when ready!")
        showCoachingCue("Ready for automatic sprint detection 🎯")
    }
    
    private func setupAutomaticDetectionCallbacks() {
        // Callback when sprint distance is completed
        gpsManager.onSprintCompleted = { (result: SprintResult) in
            Task { @MainActor in
                // Handle sprint completion with GPS result
                let time = result.time
                // Use AudioManager for enhanced coaching
                // audioManager.handleSprintComplete(time: time)
                
                // Complete the rep with GPS time
                // completeCurrentRep(time: time)
                
                // Provide performance feedback
                if time < 5.0 { // Under 5 seconds for 40 yards is quite good
                    print("Excellent speed! \(String(format: "%.2f", time)) seconds! 🔥")
                } else {
                    print("Sprint complete! \(String(format: "%.2f", time)) seconds! 💪")
                }
            }
        }
        
        // Callback for progress updates during sprint
        gpsManager.onDistanceUpdate = { (distance: Double, time: TimeInterval) in
            Task { @MainActor in
                // Provide audio feedback at milestones
                let distanceYards = distance / 0.9144
                let targetYards = 40.0 // Default sprint distance
                
                if distanceYards >= targetYards * 0.5 && distanceYards < targetYards * 0.6 {
                    print("Halfway! Keep pushing! 💪")
                } else if distanceYards >= targetYards * 0.8 && distanceYards < targetYards * 0.9 {
                    print("Almost there! Final push! 🚀")
                }
            }
        }
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
        guard let session = sessionData,
              let firstSprint = session.sprintSets.first else { return }
        
        let distance = firstSprint.distance
        let week = session.week
        let restTime = getRestTimeForDistance(distance, week: week)
        
        print("🏃‍♂️ Starting automated sprint session: \(distance)yd with \(restTime)min rest (Week \(week))")
        
        // Update rest time based on session library
        restTimeRemaining = Double(restTime * 60) // Convert to seconds
        
        // Get session library entry for UI display and voice coaching
        if let sessionEntry = getSessionLibraryEntry(for: distance, week: week) {
            // Initial voice coaching for the session
            let sessionIntro = "Starting \(sessionEntry.sessionType) session. Focus: \(sessionEntry.focus). You'll be doing \(totalReps) sprints at \(distance) yards each."
            announceVoiceCoaching(sessionIntro)
        }
        
        // Start first sprint after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startNextAutomatedSprint()
        }
    }
    
    private func startNextAutomatedSprint() {
        guard let session = sessionData,
              let firstSprint = session.sprintSets.first,
              currentRep <= totalReps else {
            completeSprintSession()
            return
        }
        
        let distance = firstSprint.distance
        let week = session.week
        
        // Get adaptive voice coaching for this sprint
        let voiceCoaching = getVoiceCoachingForSprint(
            distance: distance,
            week: week,
            setNumber: currentRep,
            totalSets: totalReps
        )
        
        print("🏃‍♂️ Starting sprint \(currentRep): \(distance)yd")
        
        // Voice coaching for the sprint
        announceVoiceCoaching(voiceCoaching)
        
        // Start GPS tracking
        gpsManager.startSprint()
        
        // Update UI state
        isRunning = true
        
        // Wait for user to complete sprint (this would be triggered by GPS or manual stop)
        // For now, simulate sprint completion after a reasonable time
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            self.completeAutomatedSprint()
        }
    }
    
    private func completeAutomatedSprint() {
        guard let session = sessionData,
              let firstSprint = session.sprintSets.first else { return }
        
        let distance = firstSprint.distance
        let week = session.week
        let restTime = getRestTimeForDistance(distance, week: week)
        
        print("✅ Sprint \(currentRep) completed")
        
        // Stop GPS tracking and record data
        gpsManager.stopSprint()
        
        // Record the sprint result with estimated time
        let estimatedTime = 5.0 // Default sprint time estimate
        let repData = RepData(
            rep: currentRep,
            time: estimatedTime,
            isCompleted: true,
            repType: .sprint,
            distance: distance,
            timestamp: Date()
        )
        completedReps.append(repData)
        
        // Update workout state
        isRunning = false
        
        // Move to next sprint or start rest
        if currentRep < totalReps {
            startAutomatedRestPeriod(restTimeMinutes: restTime)
        } else {
            completeSprintSession()
        }
    }
    
    private func startAutomatedRestPeriod(restTimeMinutes: Int) {
        isResting = true
        restTimeRemaining = Double(restTimeMinutes * 60) // Convert to seconds
        
        announceVoiceCoaching("Excellent sprint! Rest for \(restTimeMinutes) minute\(restTimeMinutes == 1 ? "" : "s"). Walk around and stay loose.")
        
        // Start rest timer
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.restTimeRemaining -= 1
            
            // Countdown announcements
            if self.restTimeRemaining == 60 && restTimeMinutes > 1 {
                self.announceVoiceCoaching("1 minute remaining")
            } else if self.restTimeRemaining == 30 && restTimeMinutes > 1 {
                self.announceVoiceCoaching("30 seconds remaining")
            } else if self.restTimeRemaining == 10 {
                self.announceVoiceCoaching("10 seconds")
            } else if self.restTimeRemaining <= 0 {
                self.endAutomatedRestPeriod()
            }
        }
    }
    
    private func endAutomatedRestPeriod() {
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        
        announceVoiceCoaching("Rest complete. Get ready for your next sprint.")
        
        // Move to next sprint
        currentRep += 1
        
        // Start next sprint after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startNextAutomatedSprint()
        }
    }
    
    private func completeSprintSession() {
        print("🏁 Sprint session completed")
        
        announceVoiceCoaching("Outstanding work! Sprint session complete. Moving to cooldown phase.")
        
        // Advance to cooldown phase
        currentPhase = .cooldown
    }
    
    // MARK: - C25K Style Helper Functions
    
    private func getSessionDescription() -> String {
        guard sessionData != nil else { return "Sprint Training" }
        
        // Get sprint info from session data
        let distance = getMainSprintDistance()
        let reps = getTotalReps()
        let restTime = getRestTime()
        
        return "\(distance)yd × \(reps) reps\n\(restTime)s rest"
    }
    
    private func getPhaseColor(for index: Int) -> Color {
        let phases: [WorkoutPhase] = [.warmup, .stretch, .drill, .strides, .sprints, .resting, .cooldown]
        guard index < phases.count else { return Color.white.opacity(0.3) }
        
        let phase = phases[index]
        let currentIndex = phases.firstIndex(of: currentPhase) ?? 0
        
        if index < currentIndex {
            return Color.green // Completed
        } else if index == currentIndex {
            return phase.color // Current phase
        } else {
            return Color.white.opacity(0.3) // Upcoming
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func getNextPhaseTime() -> String {
        switch currentPhase {
        case .sprints:
            return formatTime(getRestTime())
        case .resting:
            return formatTime(Int(getMainSprintDistance() * 2)) // Estimated sprint time
        default:
            return "1:00"
        }
    }
    
    private func calculateTimeLeft() -> Int {
        // Calculate total remaining time in workout
        let remainingReps = totalReps - currentRep + 1
        let sprintTime = Int(getMainSprintDistance() * 2) // Rough estimate
        let restTime = getRestTime()
        let cooldownTime = currentPhase.rawValue == "cooldown" ? 0 : 300
        
        return (remainingReps * (sprintTime + restTime)) + cooldownTime
    }
    
    
    private func startLiveTracking() {
        guard !isLiveTracking else { return }
        
        isLiveTracking = true
        sprintStartTime = Date()
        currentDistance = 0.0
        currentTime = 0.0
        currentSpeed = 0.0
        
        // Start live timer for updates
        liveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateLiveMetrics()
        }
        
        // Start GPS tracking
        gpsManager.startSprint()
    }
    
    private func stopLiveTracking() {
        isLiveTracking = false
        liveTimer?.invalidate()
        liveTimer = nil
        
        // Record performance
        if let bestTime = sessionBestTime {
            if currentTime < bestTime {
                sessionBestTime = currentTime
            }
        } else {
            sessionBestTime = currentTime
        }
        
        // Update session averages
        let completedSprints = Double(currentRep - 1)
        sessionAverageTime = (sessionAverageTime * completedSprints + currentTime) / Double(currentRep)
        totalDistanceCovered += currentDistance
    }
    
    private func updateLiveMetrics() {
        guard let startTime = sprintStartTime, isLiveTracking else { return }
        
        // Update time
        currentTime = Date().timeIntervalSince(startTime)
        
        // Simulate GPS data (replace with actual GPS data)
        if gpsManager.isTracking {
            currentDistance = gpsManager.distance / 0.9144 // Convert to yards
            currentSpeed = gpsManager.currentSpeed * 2.237 // Convert to mph
        } else {
            // Simulate realistic sprint progression
            let targetDistance = Double(getMainSprintDistance())
            let progress = min(currentTime / 6.0, 1.0) // Assume 6 second sprint
            currentDistance = targetDistance * progress
            
            // Simulate speed curve (acceleration → max → deceleration)
            if progress < 0.3 {
                currentSpeed = progress * 60.0 // Accelerating to 18 mph
            } else if progress < 0.8 {
                currentSpeed = 18.0 // Max speed
            } else {
                currentSpeed = 18.0 * (1.0 - (progress - 0.8) * 2.0) // Deceleration
            }
        }
        
        // Check for sprint completion
        if currentDistance >= Double(getMainSprintDistance()) {
            completeCurrentRep()
        }
    }
    
    // MARK: - Stop Workout Functions (Duplicates removed)
    
    private func resetWorkoutState() {
        currentPhase = .warmup
        isRunning = false
        isPaused = false
        currentRep = 1
        phaseTimeRemaining = 0
        completedReps.removeAll()
        
        // Reset timers
        phaseTimer?.invalidate()
        workoutTimer?.invalidate()
        liveTimer?.invalidate()
        
        // Reset GPS
        gpsManager.stopSprint()
        
        // Sync reset state to Apple Watch
        syncWorkoutStateToWatch()
        
        print("🔄 Workout state reset and synced to Apple Watch")
    }
    
    // MARK: - Auto-Sync with Apple Watch Integration
    
    private func setupAutoSyncWithWatch() {
        // Listen for watch sync requests
        NotificationCenter.default.addObserver(
            forName: .watchRequestedSync,
            object: nil,
            queue: .main
        ) { _ in
            self.performFullSyncToWatch()
        }
        
        // Listen for watch state changes
        NotificationCenter.default.addObserver(
            forName: .watchWorkoutStateChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let watchState = notification.object as? WatchWorkoutStateSync {
                self.handleWatchStateChange(watchState)
            }
        }
        
        // Sync initial state
        syncWorkoutStateToWatch()
        syncUIConfigurationToWatch()
        syncCoachingPreferencesToWatch()
        syncSessionDataToWatch()
        
        print("🔄 Auto-sync with Apple Watch initialized")
    }
    
    private func syncWorkoutStateToWatch() {
        let syncState = WorkoutSyncState(
            currentPhase: currentPhase.rawValue,
            phaseTimeRemaining: phaseTimeRemaining,
            isRunning: isRunning,
            isPaused: isPaused,
            currentRep: currentRep,
            totalReps: totalReps,
            completedReps: completedReps.map { rep in
                RepDataSync(
                    rep: rep.rep,
                    time: rep.time,
                    distance: rep.distance,
                    isCompleted: rep.isCompleted,
                    repType: rep.repType.rawValue,
                    timestamp: Date()
                )
            },
            sessionId: UUID().uuidString,
            timestamp: Date()
        )
        
        syncManager.syncWorkoutState(syncState)
    }
    
    private func syncUIConfigurationToWatch() {
        let uiConfig = UIConfigurationSync(
            primaryColor: "orange",
            secondaryColor: "blue",
            fontScale: 1.0,
            hapticIntensity: "medium",
            animationSpeed: 1.0,
            displayMode: "enhanced",
            timestamp: Date()
        )
        
        syncManager.syncUIConfiguration(uiConfig)
    }
    
    private func syncCoachingPreferencesToWatch() {
        let coachingPrefs = CoachingPreferencesSync(
            isVoiceCoachingEnabled: isVoiceCoachingEnabled,
            voiceRate: 0.6,
            voiceVolume: 0.9,
            coachingFrequency: "normal",
            motivationalLevel: "high",
            language: "en-US",
            timestamp: Date()
        )
        
        syncManager.syncCoachingPreferences(coachingPrefs)
    }
    
    private func syncSessionDataToWatch() {
        guard let session = sessionData else { return }
        
        let sessionSync = SessionDataSync(
            week: session.week,
            day: session.day,
            sessionName: session.sessionName,
            sessionFocus: session.sessionFocus,
            estimatedDuration: session.estimatedDuration,
            sprintSets: session.sprintSets.map { sprint in
                SprintSetSync(
                    distance: sprint.distance,
                    restTime: sprint.restTime,
                    targetTime: nil,
                    intensity: "max"
                )
            },
            drillSets: session.drillSets.map { drill in
                DrillSetSync(
                    name: drill.name,
                    duration: drill.duration,
                    restTime: drill.restTime,
                    description: drill.name // Use name as description since description property doesn't exist
                )
            },
            strideSets: session.strideSets.map { stride in
                StrideSetSync(
                    distance: stride.distance,
                    restTime: stride.restTime,
                    intensity: "progressive"
                )
            },
            timestamp: Date()
        )
        
        syncManager.syncSessionData(sessionSync)
    }
    
    private func syncLiveMetricsToWatch() {
        let liveMetrics = LiveMetricsSync(
            distance: gpsManager.distance,
            elapsedTime: gpsManager.elapsedTime,
            currentSpeed: gpsManager.currentSpeed,
            heartRate: nil,
            calories: nil,
            timestamp: Date()
        )
        
        syncManager.syncLiveMetrics(liveMetrics)
    }
    
    private func performFullSyncToWatch() {
        syncWorkoutStateToWatch()
        syncUIConfigurationToWatch()
        syncCoachingPreferencesToWatch()
        syncSessionDataToWatch()
        syncLiveMetricsToWatch()
        
        print("📱 Full sync performed to Apple Watch")
    }
    
    private func handleWatchStateChange(_ watchState: WatchWorkoutStateSync) {
        if let action = watchState.requestedAction {
            switch action {
            case "pause":
                if isRunning { pauseWorkout() }
            case "resume":
                if isPaused { resumeWorkout() }
            case "next":
                fastForward()
            case "complete":
                completeWorkout()
            default:
                break
            }
        }
        
        print("⌚ Handled watch state change: \(watchState.requestedAction ?? "state update")")
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
        VStack(spacing: 12) {
            // Header
            Text("Workout Phases")
                .font(.headline)
                .foregroundColor(.white)
            
            // Phase breakdown
            VStack(spacing: 8) {
                // Drills Phase
                PhaseRowView(
                    phase: "DRILLS",
                    count: sessionData?.drillSets.count ?? 3,
                    isActive: currentPhase == .drill,
                    isCompleted: isPhaseCompleted(.drill)
                )
                
                // Strides Phase
                PhaseRowView(
                    phase: "STRIDES", 
                    count: sessionData?.strideSets.count ?? 4,
                    isActive: currentPhase == .strides,
                    isCompleted: isPhaseCompleted(.strides)
                )
                
                // Sprints Phase
                PhaseRowView(
                    phase: "SPRINTS",
                    count: sessionData?.sprintSets.count ?? totalReps,
                    isActive: [.sprints, .resting].contains(currentPhase),
                    isCompleted: isPhaseCompleted(.sprints)
                )
            }
            
            // Current rep indicator for sprint phase
            if [.sprints, .resting].contains(currentPhase) {
                Text("Sprint \(currentRep) of \(totalReps)")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func isPhaseCompleted(_ phase: MainProgramWorkoutView.WorkoutPhase) -> Bool {
        switch phase {
        case .drill:
            return currentPhase.rawValue > MainProgramWorkoutView.WorkoutPhase.drill.rawValue
        case .strides:
            return currentPhase.rawValue > MainProgramWorkoutView.WorkoutPhase.strides.rawValue
        case .sprints:
            return currentPhase == .completed
        default:
            return false
        }
    }
}

struct PhaseRowView: View {
    let phase: String
    let count: Int
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            // Phase icon
            Image(systemName: phaseIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(phaseColor)
                .frame(width: 24)
            
            // Phase name
            Text(phase)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Count
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(phaseColor)
            
            // Status indicator
            Image(systemName: statusIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(phaseColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.white.opacity(0.1) : Color.clear)
        )
    }
    
    private var phaseIcon: String {
        switch phase {
        case "DRILLS": return "figure.run"
        case "STRIDES": return "figure.walk"
        case "SPRINTS": return "bolt.fill"
        default: return "circle"
        }
    }
    
    private var phaseColor: Color {
        if isCompleted { return .green }
        if isActive { return .yellow }
        return .white.opacity(0.6)
    }
    
    private var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isActive { return "play.circle.fill" }
        return "circle"
    }
}

struct SessionPhaseRow: View {
    let title: String
    let details: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Phase icon
                Image(systemName: phaseIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(phaseColor)
                    .frame(width: 20)
                
                // Phase title
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Status indicator
                Image(systemName: statusIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(phaseColor)
            }
            
            // Phase details
            Text(details)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(phaseColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var phaseIcon: String {
        switch title {
        case "DRILLS": return "figure.run"
        case "STRIDES": return "figure.walk"
        case "SPRINTS": return "bolt.fill"
        default: return "circle"
        }
    }
    
    private var phaseColor: Color {
        if isCompleted { return .green }
        if isActive { return .yellow }
        return .white.opacity(0.6)
    }
    
    private var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isActive { return "play.circle.fill" }
        return "circle"
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
                .fill(isActive ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.white.opacity(0.4) : Color.white.opacity(0.3), lineWidth: 1)
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

// MARK: - New Workout Breakdown Components

struct WorkoutSectionHeader: View {
    let title: String
    let icon: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(headerColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: statusIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(headerColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? headerColor.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(headerColor.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var headerColor: Color {
        if isCompleted { return .green }
        if isActive { return .orange }
        return .white.opacity(0.6)
    }
    
    private var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isActive { return "play.circle.fill" }
        return "circle"
    }
}

struct WorkoutItemRow: View {
    let number: Int
    let name: String
    let details: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            // Number
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(rowColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(rowColor.opacity(0.2))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Text(details)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Status
            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(rowColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.white.opacity(0.08) : Color.white.opacity(0.02))
        )
    }
    
    private var rowColor: Color {
        if isCompleted { return .green }
        if isActive { return .orange }
        return .white.opacity(0.6)
    }
    
    private var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isActive { return "play.circle.fill" }
        return "circle"
    }
}

struct WorkoutSprintRow: View {
    let number: Int
    let distance: Int
    let restTime: Int
    let time: Double?
    let isActive: Bool
    let isCompleted: Bool
    let targetTime: Double?
    
    var body: some View {
        HStack {
            // Sprint number
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(rowColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(rowColor.opacity(0.2))
                )
            
            // Sprint details
            VStack(alignment: .leading, spacing: 2) {
                Text("\(distance) Yard Sprint")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(restTime)min rest")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Time display
            VStack(alignment: .trailing, spacing: 2) {
                if let time = time {
                    Text(String(format: "%.2fs", time))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    if let target = targetTime {
                        let difference = time - target
                        Text(difference < 0 ? String(format: "%.2fs", difference) : String(format: "+%.2fs", difference))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(difference < 0 ? .green : .red)
                    }
                } else if isActive {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                } else {
                    Text("--")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Status
            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(rowColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.white.opacity(0.08) : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var rowColor: Color {
        if isCompleted { return .green }
        if isActive { return .orange }
        return .white.opacity(0.6)
    }
    
    private var statusIcon: String {
        if isCompleted { return "checkmark.circle.fill" }
        if isActive { return "play.circle.fill" }
        return "circle"
    }
}

// MARK: - Dynamic Live Tracker Component
struct DynamicLiveTracker: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let gpsManager: GPSManager
    let currentRep: Int
    let totalReps: Int
    let targetDistance: Int
    let phaseTimeRemaining: Int
    let isLiveTracking: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Rep Progress Indicator
            VStack(spacing: 8) {
                HStack {
                    ForEach(1...totalReps, id: \.self) { rep in
                        Circle()
                            .fill(rep < currentRep ? Color.green : 
                                  rep == currentRep ? getPhaseColor() : 
                                  Color.white.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                Text("\(currentPhase.displayName) \(currentRep) of \(totalReps)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(targetDistance) yards")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Live GPS Stopwatch & Distance Display
            VStack(spacing: 12) {
                // Primary Metrics Row
                HStack(spacing: 0) {
                    // Live Distance
                    VStack(spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Text(formatDistance(gpsManager.distance))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("|")
                        .font(.system(size: 20, weight: .thin))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // GPS Stopwatch
                    VStack(spacing: 4) {
                        Text("TIME")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Text(formatStopwatchTime(gpsManager.elapsedTime))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("|")
                        .font(.system(size: 20, weight: .thin))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Live Speed
                    VStack(spacing: 4) {
                        Text("SPEED")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Text(formatSpeed(gpsManager.currentSpeed))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Secondary Metrics Row
                HStack(spacing: 0) {
                    // Countdown Timer
                    VStack(spacing: 4) {
                        Text("COUNTDOWN")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Text(formatCountdownTime(phaseTimeRemaining))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(phaseTimeRemaining < 30 ? .orange : .white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("|")
                        .font(.system(size: 20, weight: .thin))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Yard Tracker Progress
                    VStack(spacing: 4) {
                        Text("PROGRESS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Text("\(Int(getProgressPercentage()))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("|")
                        .font(.system(size: 20, weight: .thin))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // GPS Status
                    VStack(spacing: 4) {
                        Text("GPS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Text(getGPSStatusText())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(getGPSStatusColor())
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
                
                // Yard Tracker Progress Bar
                let targetDistanceMeters = Double(targetDistance) * 0.9144
                let progress = min(gpsManager.distance / targetDistanceMeters, 1.0)
                VStack(spacing: 8) {
                    HStack {
                        Text("0 yds")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("\(targetDistance) yds")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: getPhaseColor()))
                        .scaleEffect(x: 1, y: 4, anchor: .center)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(2)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func getPhaseColor() -> Color {
        switch currentPhase {
        case .drill: return .blue
        case .strides: return .purple
        case .sprints: return .orange
        default: return .white
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        let yards = distance * 1.09361 // Convert meters to yards
        return String(format: "%.1f", yards)
    }
    
    private func formatStopwatchTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        let mph = speed * 2.237 // Convert m/s to mph
        return String(format: "%.1f", mph)
    }
    
    private func formatCountdownTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func getProgressPercentage() -> Double {
        let targetDistanceMeters = Double(targetDistance) * 0.9144
        return min((gpsManager.distance / targetDistanceMeters) * 100, 100)
    }
    
    private func getGPSStatusText() -> String {
        if gpsManager.isTracking {
            return "ACTIVE"
        } else if gpsManager.isReadyForSprint {
            return "READY"
        } else {
            return "WAIT"
        }
    }
    
    private func getGPSStatusColor() -> Color {
        if gpsManager.isTracking {
            return .green
        } else if gpsManager.isReadyForSprint {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Colorful Moving Timeline Component
struct ColorfulMovingTimeline: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let phaseProgress: Double
    let isRunning: Bool
    
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Timeline Header
            HStack {
                Text("WORKOUT TIMELINE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1)
                Spacer()
                Text(currentPhase.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(getPhaseColor())
                    .tracking(1)
            }
            
            // Moving Timeline Bar
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Phase Segments
                HStack(spacing: 2) {
                    ForEach(getAllPhases(), id: \.self) { phase in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(getSegmentColor(for: phase))
                            .frame(height: 12)
                            .opacity(getSegmentOpacity(for: phase))
                    }
                }
                .padding(.horizontal, 2)
                
                // Moving Progress Indicator
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [getPhaseColor(), getPhaseColor().opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: getProgressWidth(), height: 16)
                        .overlay(
                            // Animated shimmer effect
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: animationOffset)
                                .mask(RoundedRectangle(cornerRadius: 8))
                        )
                    Spacer()
                }
                
                // Current Phase Pulse Indicator
                if isRunning {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(getPhaseColor())
                            .frame(width: 8, height: 8)
                            .scaleEffect(isRunning ? 1.5 : 1.0)
                            .opacity(isRunning ? 0.8 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isRunning
                            )
                            .offset(x: getProgressWidth() - 4)
                        Spacer()
                    }
                }
            }
            
            // Phase Labels
            HStack {
                ForEach(getAllPhases(), id: \.self) { phase in
                    Text(phase.shortName)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(phase == currentPhase ? getPhaseColor() : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            startShimmerAnimation()
        }
        .onChange(of: isRunning) { _, running in
            if running {
                startShimmerAnimation()
            }
        }
    }
    
    private func getAllPhases() -> [MainProgramWorkoutView.WorkoutPhase] {
        return [.warmup, .stretch, .drill, .strides, .sprints, .resting, .cooldown]
    }
    
    private func getPhaseColor() -> Color {
        switch currentPhase {
        case .warmup: return .orange
        case .stretch: return .pink
        case .drill: return .blue
        case .strides: return .purple
        case .sprints: return .red
        case .resting: return .yellow
        case .cooldown: return .cyan
        case .completed: return .green
        }
    }
    
    private func getSegmentColor(for phase: MainProgramWorkoutView.WorkoutPhase) -> Color {
        switch phase {
        case .warmup: return .orange
        case .stretch: return .pink
        case .drill: return .blue
        case .strides: return .purple
        case .sprints: return .red
        case .resting: return .yellow
        case .cooldown: return .cyan
        case .completed: return .green
        }
    }
    
    private func getSegmentOpacity(for phase: MainProgramWorkoutView.WorkoutPhase) -> Double {
        let allPhases = getAllPhases()
        guard let currentIndex = allPhases.firstIndex(of: currentPhase),
              let phaseIndex = allPhases.firstIndex(of: phase) else { return 0.3 }
        
        if phaseIndex < currentIndex {
            return 1.0 // Completed phases
        } else if phaseIndex == currentIndex {
            return 0.8 // Current phase
        } else {
            return 0.3 // Future phases
        }
    }
    
    private func getProgressWidth() -> CGFloat {
        let allPhases = getAllPhases()
        guard let currentIndex = allPhases.firstIndex(of: currentPhase) else { return 0 }
        
        let totalPhases = Double(allPhases.count)
        let completedPhases = Double(currentIndex)
        let currentPhaseProgress = phaseProgress
        
        let totalProgress = (completedPhases + currentPhaseProgress) / totalPhases
        return CGFloat(totalProgress) * 300 // Approximate timeline width
    }
    
    private func startShimmerAnimation() {
        guard isRunning else { return }
        
        withAnimation(
            Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
        ) {
            animationOffset = 100
        }
    }
}

// MARK: - WorkoutPhase Extension
extension MainProgramWorkoutView.WorkoutPhase {
    var displayName: String {
        switch self {
        case .drill: return "Drill"
        case .strides: return "Stride"
        case .sprints: return "Sprint"
        default: return "Exercise"
        }
    }
    
    var shortName: String {
        switch self {
        case .warmup: return "WARM"
        case .stretch: return "STRCH"
        case .drill: return "DRILL"
        case .strides: return "STRD"
        case .sprints: return "SPRNT"
        case .resting: return "REST"
        case .cooldown: return "COOL"
        case .completed: return "DONE"
        }
    }
}

// MARK: - Performance Optimized Subviews

/// Optimized header view with session information
struct WorkoutHeaderView: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    
    var body: some View {
        VStack(spacing: 12) {
            // Session Title
            if let session = sessionData {
                VStack(spacing: 8) {
                    HStack {
                        Text("Week \(session.week)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("Day \(session.day)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(session.sessionName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(session.sessionFocus.uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(0.5)
                }
            }
        }
        .padding(.top, 20)
    }
}

/// Optimized metrics dashboard with lazy loading
struct OptimizedMetricsDashboard: View {
    let gpsManager: GPSManager
    let phaseTimeRemaining: Int
    
    // Performance optimization: Use @State for expensive calculations
    @State private var cachedDistance: String = "0.0"
    @State private var cachedTime: String = "0:00"
    @State private var cachedSpeed: String = "0.0"
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary Metrics Row
            HStack(spacing: 12) {
                MetricBox(
                    title: "DISTANCE",
                    value: cachedDistance,
                    unit: "YARDS",
                    color: .blue
                )
                
                MetricBox(
                    title: "TIME",
                    value: cachedTime,
                    unit: "LIVE",
                    color: .green
                )
                
                MetricBox(
                    title: "SPEED",
                    value: cachedSpeed,
                    unit: "MPH",
                    color: .orange
                )
            }
            
            // Secondary Metrics Row
            HStack(spacing: 12) {
                MetricBox(
                    title: "COUNTDOWN",
                    value: formatCountdownTime(phaseTimeRemaining),
                    unit: "LEFT",
                    color: .purple,
                    isSmall: true,
                    isUrgent: phaseTimeRemaining < 30
                )
                
                MetricBox(
                    title: "PROGRESS",
                    value: "\(Int(getProgressPercentage()))%",
                    unit: "DONE",
                    color: .yellow,
                    isSmall: true
                )
                
                MetricBox(
                    title: "GPS",
                    value: getGPSStatus(),
                    unit: "STATUS",
                    color: .cyan,
                    isSmall: true,
                    statusColor: getGPSStatusColor()
                )
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateCachedValues()
        }
    }
    
    private func updateCachedValues() {
        let yards = gpsManager.distance * 1.09361
        cachedDistance = String(format: "%.1f", yards)
        
        let minutes = Int(gpsManager.elapsedTime) / 60
        let seconds = Int(gpsManager.elapsedTime) % 60
        cachedTime = String(format: "%d:%02d", minutes, seconds)
        
        let mph = gpsManager.currentSpeed * 2.237
        cachedSpeed = String(format: "%.1f", mph)
    }
    
    private func formatCountdownTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func getProgressPercentage() -> Double {
        // Simplified calculation for performance
        return min((gpsManager.distance / 36.576) * 100, 100) // 40 yards in meters
    }
    
    private func getGPSStatus() -> String {
        if gpsManager.isTracking { return "ACTIVE" }
        else if gpsManager.isReadyForSprint { return "READY" }
        else { return "WAIT" }
    }
    
    private func getGPSStatusColor() -> Color {
        if gpsManager.isTracking { return .green }
        else if gpsManager.isReadyForSprint { return .orange }
        else { return .red }
    }
}

/// Reusable metric box component
struct MetricBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    var isSmall: Bool = false
    var isUrgent: Bool = false
    var statusColor: Color?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: isSmall ? 9 : 10, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: isSmall ? 16 : 18, weight: .bold))
                .foregroundColor(statusColor ?? (isUrgent ? .red : .white))
            
            Text(unit)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isSmall ? 10 : 12)
        .background(color.opacity(0.3))
        .cornerRadius(isSmall ? 10 : 12)
        .overlay(
            RoundedRectangle(cornerRadius: isSmall ? 10 : 12)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

/// Optimized workout controls with haptic feedback
struct OptimizedWorkoutControls: View {
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onFastForward: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Control Row
            HStack(spacing: 20) {
                ControlButton(
                    icon: isPaused ? "play.fill" : "pause.fill",
                    color: isPaused ? .green : .orange,
                    isActive: true,
                    action: onTogglePause
                )
                
                ControlButton(
                    icon: "forward.fill",
                    color: .blue,
                    isActive: true,
                    action: onFastForward
                )
                
                ControlButton(
                    icon: "stop.fill",
                    color: .red,
                    isActive: true,
                    action: onStop
                )
            }
            
            // Control Labels
            HStack(spacing: 20) {
                Text(isPaused ? "RESUME" : "PAUSE")
                    .controlLabel()
                
                Text("SKIP")
                    .controlLabel()
                
                Text("STOP")
                    .controlLabel()
            }
        }
        .padding(.bottom, 20)
    }
}


/// Optimized phase display with smooth transitions
struct PhaseDisplayView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let currentRep: Int
    let totalReps: Int
    let targetDistance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Phase Progress Dots
            HStack {
                ForEach(1...totalReps, id: \.self) { rep in
                    Circle()
                        .fill(rep < currentRep ? Color.green : 
                              rep == currentRep ? currentPhase.color : 
                              Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(rep == currentRep ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentRep)
                }
            }
            
            Text("\(currentPhase.title) \(currentRep) of \(totalReps)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(targetDistance) yards")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - View Extensions for Performance

extension Text {
    func controlLabel() -> some View {
        self
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 75)
    }
}

extension View {
    /// Performance optimization: Reduce view updates
    func onlyUpdateWhen<T: Hashable>(_ value: T) -> some View {
        self.id(value)
    }
    
    /// Add accessibility support
    func workoutAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Enhanced Live Rep Log Component

/// Enhanced live rep log with real-time updates and detailed performance metrics
struct EnhancedLiveRepLog: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let completedReps: [RepData]
    let currentRep: Int
    let totalReps: Int
    let sessionData: MainProgramWorkoutView.SessionData?
    let gpsManager: GPSManager
    
    @State private var isExpanded: Bool = true
    @State private var selectedTab: RepLogTab = .current
    
    enum RepLogTab: String, CaseIterable {
        case current = "CURRENT"
        case completed = "COMPLETED"
        case stats = "STATS"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Text("LIVE REP LOG")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: currentPhase
                        )
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            
            if isExpanded {
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(RepLogTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(selectedTab == tab ? .orange : .white.opacity(0.6))
                                    
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .current:
                            currentRepContent
                        case .completed:
                            completedRepsContent
                        case .stats:
                            statsContent
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                .background(Color.black.opacity(0.6))
            }
        }
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var currentRepContent: some View {
        VStack(spacing: 12) {
            // Current phase and rep info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT PHASE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(currentPhase.title.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(currentPhase.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("REP PROGRESS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(currentRep) / \(totalReps)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Live metrics for current rep
            if currentPhase == .sprints || currentPhase == .strides || currentPhase == .drill {
                VStack(spacing: 8) {
                    Text("LIVE METRICS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 16) {
                        LiveMetricItem(
                            title: "DISTANCE",
                            value: String(format: "%.1f", gpsManager.distance * 1.09361),
                            unit: "YDS"
                        )
                        
                        LiveMetricItem(
                            title: "TIME",
                            value: formatTime(gpsManager.elapsedTime),
                            unit: "SEC"
                        )
                        
                        LiveMetricItem(
                            title: "SPEED",
                            value: String(format: "%.1f", gpsManager.currentSpeed * 2.237),
                            unit: "MPH"
                        )
                    }
                }
            }
            
            // Target for current rep
            if let targetDistance = getTargetDistanceForCurrentRep() {
                HStack {
                    Text("TARGET:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(targetDistance) yards")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    let progress = min((gpsManager.distance * 1.09361) / Double(targetDistance), 1.0)
                    Text("\(Int(progress * 100))% complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(progress >= 1.0 ? .green : .white.opacity(0.8))
                }
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private var completedRepsContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(completedReps.indices, id: \.self) { index in
                    let rep = completedReps[index]
                    CompletedRepRow(rep: rep, index: index + 1)
                }
                
                if completedReps.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No completed reps yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(16)
        }
        .frame(maxHeight: 200)
    }
    
    @ViewBuilder
    private var statsContent: some View {
        VStack(spacing: 16) {
            // Performance stats
            HStack(spacing: 16) {
                StatBox(
                    title: "BEST TIME",
                    value: getBestTime(),
                    color: .green
                )
                
                StatBox(
                    title: "AVG TIME",
                    value: getAverageTime(),
                    color: .blue
                )
                
                StatBox(
                    title: "TOTAL DISTANCE",
                    value: getTotalDistance(),
                    color: .purple
                )
            }
            
            // Phase completion
            VStack(spacing: 8) {
                Text("PHASE COMPLETION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    PhaseCompletionIndicator(
                        phase: "DRILLS",
                        completed: getCompletedCount(.drill),
                        total: sessionData?.drillSets.count ?? 0,
                        color: .blue
                    )
                    
                    PhaseCompletionIndicator(
                        phase: "STRIDES",
                        completed: getCompletedCount(.stride),
                        total: sessionData?.strideSets.count ?? 0,
                        color: .purple
                    )
                    
                    PhaseCompletionIndicator(
                        phase: "SPRINTS",
                        completed: getCompletedCount(.sprint),
                        total: sessionData?.sprintSets.count ?? 0,
                        color: .orange
                    )
                }
            }
        }
        .padding(16)
    }
    
    // Helper functions
    private func getTargetDistanceForCurrentRep() -> Int? {
        switch currentPhase {
        case .drill:
            return 20
        case .strides:
            return sessionData?.strideSets.first?.distance ?? 20
        case .sprints:
            return sessionData?.sprintSets.first?.distance ?? 40
        default:
            return nil
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        return String(format: "%.1f", time)
    }
    
    private func getBestTime() -> String {
        let times = completedReps.compactMap { $0.time }
        guard let best = times.min() else { return "--" }
        return String(format: "%.2fs", best)
    }
    
    private func getAverageTime() -> String {
        let times = completedReps.compactMap { $0.time }
        guard !times.isEmpty else { return "--" }
        let average = times.reduce(0, +) / Double(times.count)
        return String(format: "%.2fs", average)
    }
    
    private func getTotalDistance() -> String {
        let totalYards = completedReps.reduce(0) { $0 + $1.distance }
        return "\(totalYards) yds"
    }
    
    private func getCompletedCount(_ type: RepData.RepType) -> Int {
        return completedReps.filter { $0.repType == type && $0.isCompleted }.count
    }
}

// MARK: - Supporting Components for Enhanced Rep Log

struct LiveMetricItem: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompletedRepRow: View {
    let rep: RepData
    let index: Int
    
    var body: some View {
        HStack {
            // Rep number and type
            HStack(spacing: 8) {
                Text("\(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(rep.repType.uiColor.opacity(0.3))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rep.repType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(rep.distance) yards")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Time and status
            VStack(alignment: .trailing, spacing: 2) {
                if let time = rep.time {
                    Text(String(format: "%.2fs", time))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Image(systemName: rep.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(rep.isCompleted ? .green : .white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PhaseCompletionIndicator: View {
    let phase: String
    let completed: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(phase)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(completed)/\(total)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - RepData Extensions

extension RepData.RepType {
    var uiColor: Color {
        switch self {
        case .drill: return .blue
        case .stride: return .purple
        case .sprint: return .orange
        case .warmup: return .yellow
        case .cooldown: return .cyan
        }
    }
}

// MARK: - Workout Summary Card
// TODO: Implement WorkoutTypeAnalyzer before enabling
/*
struct WorkoutSummaryCard: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    
    var body: some View {
        VStack(spacing: 16) {
            // Workout Type Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: workoutCategory.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: workoutCategory.color.red, green: workoutCategory.color.green, blue: workoutCategory.color.blue))
                    
                    Text(workoutCategory.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(1.2)
                }
                
                Spacer()
                
                Text("WORKOUT TYPE")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.8)
            }
            
            // Session Name and Focus
            if let session = sessionData {
                VStack(spacing: 8) {
                    Text(session.sessionName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(session.sessionFocus.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: workoutCategory.color.red, green: workoutCategory.color.green, blue: workoutCategory.color.blue))
                        .tracking(1)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Workout Description
            Text(workoutCategory.description)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: workoutCategory.color.red, green: workoutCategory.color.green, blue: workoutCategory.color.blue).opacity(0.3),
                                    Color(red: workoutCategory.color.red, green: workoutCategory.color.green, blue: workoutCategory.color.blue).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var workoutCategory: WorkoutTypeAnalyzer.WorkoutCategory {
        guard let session = sessionData,
              let firstSprint = session.sprintSets.first else {
            return .speedDistances
        }
        
        return WorkoutTypeAnalyzer.getWorkoutCategoryForSession(
            name: session.sessionName,
            focus: session.sessionFocus,
            distance: firstSprint.distance,
            reps: session.sprintSets.count
        )
    }
}
*/

// MARK: - Workout Process View
struct WorkoutProcessView: View {
    let sessionData: MainProgramWorkoutView.SessionData?
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let currentRep: Int
    let totalReps: Int
    
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Process Header
            HStack {
                Text("WORKOUT PROCESS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1.2)
                
                Spacer()
                
                Text("STEP BY STEP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.8)
            }
            
            // TODO: Uncomment when WorkoutStep is implemented
            /*
            // Animated Process Steps
            VStack(spacing: 12) {
                ForEach(Array(workoutSteps.enumerated()), id: \.offset) { index, step in
                    WorkoutStepRow(
                        step: step,
                        isActive: index == currentStepIndex,
                        isCompleted: index < currentStepIndex,
                        animationProgress: animationProgress
                    )
                }
            }
            
            // Current Distance Expectation
            if let currentStep = currentWorkoutStep {
                VStack(spacing: 8) {
                    Text("CURRENT DISTANCE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                    
                    HStack(spacing: 4) {
                        Text("\(currentStep.distance)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("YARDS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(currentStep.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            */
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            startAnimation()
        }
    }
    
    // TODO: Implement WorkoutStep and WorkoutTypeAnalyzer before enabling
    /*
    private var workoutSteps: [WorkoutStep] {
        guard let session = sessionData,
              let firstSprint = session.sprintSets.first else {
            return []
        }
        
        return WorkoutTypeAnalyzer.getWorkoutStepsForSession(
            name: session.sessionName,
            focus: session.sessionFocus,
            distance: firstSprint.distance,
            reps: session.sprintSets.count,
            rest: firstSprint.restTime
        )
    }
    
    private var currentStepIndex: Int {
        max(0, min(currentRep - 1, workoutSteps.count - 1))
    }
    
    private var currentWorkoutStep: WorkoutStep? {
        guard currentStepIndex < workoutSteps.count else { return nil }
        return workoutSteps[currentStepIndex]
    }
    */
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationProgress = 1.0
        }
    }
}

// MARK: - Workout Step Row
// TODO: Implement WorkoutStep before enabling
/*
struct WorkoutStepRow: View {
    let step: WorkoutStep
    let isActive: Bool
    let isCompleted: Bool
    let animationProgress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Step Number Circle
            ZStack {
                Circle()
                    .fill(stepColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(stepColor)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isActive ? 1.0 + (animationProgress * 0.2) : 1.0)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step.stepNumber)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Step Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(step.distance) yards")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(step.intensity)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(stepColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(stepColor.opacity(0.2))
                        )
                }
                
                Text(step.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? stepColor.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? stepColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var stepColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .orange
        } else {
            return .white.opacity(0.6)
        }
    }
}
*/

#Preview {
    MainProgramWorkoutView(sessionData: nil, onWorkoutCompleted: nil)
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let watchWorkoutStartRequested = Notification.Name("watchWorkoutStartRequested")
    static let watchWorkoutEndRequested = Notification.Name("watchWorkoutEndRequested")
    static let watchRepCompletionRequested = Notification.Name("watchRepCompletionRequested")
}
