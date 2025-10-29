import SwiftUI
import AVFoundation
import Combine
import WatchConnectivity

// MARK: - Nike-Style Voice Coach System
class NikeVoiceCoach: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isEnabled = true
    @Published var currentMessage = ""
    @Published var showMessage = false
    
    func speak(_ message: String, priority: MessagePriority = .normal) {
        guard isEnabled else { return }
        
        // Update UI message
        currentMessage = message
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showMessage = true
        }
        
        // Hide message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.showMessage = false
            }
        }
        
        // Speak the message
        let utterance = AVSpeechUtterance(string: message.replacingOccurrences(of: "🔥|⚡|💪|🚀|🎯|✨|🏃‍♂️|💨", with: "", options: .regularExpression))
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        // Use energetic voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        synthesizer.speak(utterance)
    }
    
    enum MessagePriority {
        case low, normal, high, urgent
    }
}

// MARK: - Nike-Style Motivational Messages
struct MotivationalMessages {
    static let warmupMessages = [
        "Let's get that body ready! 🔥 Time to activate those fast-twitch muscles!",
        "Warm-up time! 💪 Your speed journey starts with preparation!",
        "Fire up those engines! ⚡ Every champion starts with a proper warm-up!"
    ]
    
    static let stretchMessages = [
        "Stretch it out! 🧘‍♂️ Flexibility equals speed - let's unlock that range of motion!",
        "Time to lengthen those muscles! ✨ Every stretch brings you closer to your PR!",
        "Dynamic stretching mode activated! 🚀 Prepare for explosive movement!"
    ]
    
    static let drillMessages = [
        "Drill time! 🎯 Perfect technique creates perfect speed!",
        "Let's build that foundation! 💪 Every drill sharpens your sprint mechanics!",
        "Technique work! ⚡ Champions are made in the details!"
    ]
    
    static let strideMessages = [
        "Build-up strides! 🏃‍♂️ Feel that speed building with each step!",
        "Acceleration mode! 🚀 Smooth, controlled, and powerful!",
        "Progressive speed! ✨ Let your body find its rhythm!"
    ]
    
    static let sprintMessages = [
        "SPRINT TIME! ⚡ This is where legends are made!",
        "MAXIMUM EFFORT! 🔥 Leave everything on the track!",
        "GO TIME! 💨 Unleash that speed demon inside you!",
        "BEAST MODE ACTIVATED! 💪 Show that track who's boss!"
    ]
    
    static let restMessages = [
        "Recovery time! 😤 Champions know when to rest and when to attack!",
        "Breathe and reset! 🧘‍♂️ Your next rep is going to be even faster!",
        "Active recovery! ✨ Stay loose, stay ready, stay hungry!"
    ]
    
    static let cooldownMessages = [
        "Cool down time! 🌟 You just crushed that session!",
        "Recovery mode! 💪 Your body is already getting stronger!",
        "Session complete! 🏆 That's how champions train!"
    ]
}

// MARK: - Rep Data Model
struct RepLogEntry: Identifiable {
    let id = UUID()
    let rep: Int
    let type: RepType
    let distance: Int
    let time: Double?
    let timestamp: Date
    let isCompleted: Bool
    
    enum RepType: String, CaseIterable {
        case drill = "DRILL"
        case stride = "STRIDE"
        case sprint = "SPRINT"
        
        var color: Color {
            switch self {
            case .drill: return .blue
            case .stride: return .purple
            case .sprint: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .drill: return "figure.run"
            case .stride: return "figure.walk"
            case .sprint: return "bolt.fill"
            }
        }
    }
}

// MARK: - Unified Sprint Coach Design System
/// A clean, focused design that captures the essence of sprint coaching
/// Combines the best of MainProgramWorkoutView and SprintTimerProWorkoutView

// MARK: - Adaptive Session Configuration
struct SessionConfiguration {
    let sessionName: String
    let sessionType: String
    let distance: Int
    let reps: Int
    let restMinutes: Int
    let description: String
    let difficulty: String
    let estimatedDuration: String
    let focus: String
    let hasWarmup: Bool
    let hasStretching: Bool
    let hasDrills: Bool
    let hasStrides: Bool
    let hasCooldown: Bool
    let workoutVariation: WorkoutVariation
    
    enum WorkoutVariation {
        case standard
        case pyramid
        case ladder
        case intervals
        case flying
        case acceleration
        case endurance
        
        var phases: [WorkoutPhase] {
            switch self {
            case .standard:
                return [.warmup, .stretch, .drill, .strides, .sprints, .cooldown]
            case .pyramid, .ladder:
                return [.warmup, .stretch, .drill, .sprints, .cooldown] // Skip strides for complex patterns
            case .intervals:
                return [.warmup, .drill, .sprints, .cooldown] // Quick intervals
            case .flying:
                return [.warmup, .stretch, .strides, .sprints, .cooldown] // Emphasis on strides
            case .acceleration:
                return [.warmup, .drill, .sprints, .cooldown] // Focus on explosive starts
            case .endurance:
                return [.warmup, .stretch, .drill, .strides, .sprints, .cooldown] // Full progression
            }
        }
    }
    
    // Comprehensive session library based on SessionLibrary data
    static let sessions: [SessionConfiguration] = [
        // Beginner Sessions
        SessionConfiguration(
            sessionName: "20 Yard Acceleration Builder",
            sessionType: "Acceleration Training",
            distance: 20,
            reps: 10,
            restMinutes: 1,
            description: "Perfect for beginners learning proper sprint mechanics",
            difficulty: "Beginner",
            estimatedDuration: "18 min",
            focus: "First step quickness and acceleration technique",
            hasWarmup: true, hasStretching: true, hasDrills: true, hasStrides: true, hasCooldown: true,
            workoutVariation: .acceleration
        ),
        SessionConfiguration(
            sessionName: "30 Yard Speed Foundation",
            sessionType: "Speed Training",
            distance: 30,
            reps: 8,
            restMinutes: 2,
            description: "Build your speed foundation with manageable distances",
            difficulty: "Beginner",
            estimatedDuration: "22 min",
            focus: "Speed endurance and proper running form",
            hasWarmup: true, hasStretching: true, hasDrills: true, hasStrides: true, hasCooldown: true,
            workoutVariation: .standard
        ),
        
        // Intermediate Sessions
        SessionConfiguration(
            sessionName: "40 Yard Speed Development",
            sessionType: "Speed Training",
            distance: 40,
            reps: 6,
            restMinutes: 2,
            description: "Classic 40-yard training for maximum speed development",
            difficulty: "Intermediate",
            estimatedDuration: "25 min",
            focus: "Maximum velocity and acceleration power",
            hasWarmup: true, hasStretching: true, hasDrills: true, hasStrides: true, hasCooldown: true,
            workoutVariation: .standard
        ),
        SessionConfiguration(
            sessionName: "Pyramid Power (20-30-40-30-20)",
            sessionType: "Pyramid Training",
            distance: 40, // Max distance
            reps: 5,
            restMinutes: 3,
            description: "Progressive distance pyramid for speed and endurance",
            difficulty: "Intermediate",
            estimatedDuration: "30 min",
            focus: "Speed endurance and lactate threshold",
            hasWarmup: true, hasStretching: true, hasDrills: true, hasStrides: false, hasCooldown: true,
            workoutVariation: .pyramid
        ),
        
        // Advanced Sessions
        SessionConfiguration(
            sessionName: "60 Yard Flying Sprints",
            sessionType: "Max Velocity Training",
            distance: 60,
            reps: 4,
            restMinutes: 4,
            description: "Elite-level maximum velocity development",
            difficulty: "Advanced",
            estimatedDuration: "32 min",
            focus: "Top-end speed and velocity maintenance",
            hasWarmup: true, hasStretching: true, hasDrills: false, hasStrides: true, hasCooldown: true,
            workoutVariation: .flying
        ),
        SessionConfiguration(
            sessionName: "Speed Ladder (10-20-30-40-50)",
            sessionType: "Ladder Training",
            distance: 50, // Max distance
            reps: 5,
            restMinutes: 3,
            description: "Progressive ladder for comprehensive speed development",
            difficulty: "Advanced",
            estimatedDuration: "35 min",
            focus: "Progressive speed building and mental toughness",
            hasWarmup: true, hasStretching: true, hasDrills: true, hasStrides: false, hasCooldown: true,
            workoutVariation: .ladder
        ),
        
        // Specialized Sessions
        SessionConfiguration(
            sessionName: "Quick Fire Intervals",
            sessionType: "Interval Training",
            distance: 25,
            reps: 12,
            restMinutes: 1,
            description: "High-intensity intervals for speed endurance",
            difficulty: "Intermediate",
            estimatedDuration: "20 min",
            focus: "Speed endurance and lactate tolerance",
            hasWarmup: true, hasStretching: false, hasDrills: true, hasStrides: false, hasCooldown: true,
            workoutVariation: .intervals
        ),
        SessionConfiguration(
            sessionName: "Endurance Speed Builder",
            sessionType: "Endurance Training",
            distance: 35,
            reps: 10,
            restMinutes: 2,
            description: "Build speed endurance for longer events",
            difficulty: "Intermediate",
            estimatedDuration: "40 min",
            focus: "Speed endurance and aerobic power",
            hasWarmup: true, hasStretching: true, hasDrills: true, hasStrides: true, hasCooldown: true,
            workoutVariation: .endurance
        )
    ]
}

struct UnifiedSprintCoachView: View {
    // Session Configuration
    let sessionConfig: SessionConfiguration
    
    // Close callback
    var onClose: (() -> Void)? = nil
    
    // Voice Coach Integration
    @StateObject private var voiceCoach = NikeVoiceCoach()
    
    // Phone-Watch Sync Manager
    @StateObject private var phoneSyncManager = PhoneSyncManager.shared
    
    // Core Sprint Coach Elements
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var currentRep = 1
    @State private var phaseTimeRemaining = 120
    
    // Nike-style animations and effects
    @State private var pulseAnimation = false
    @State private var energyLevel: Double = 0.0
    @State private var showEnergyBurst = false
    
    // Rep Log Data
    @State private var repLog: [RepLogEntry] = []
    @State private var showRepLog = false
    @State private var showDetailedView = false
    
    // GPS and Metrics (Mock for now - would integrate with actual GPSManager)
    @State private var currentDistance: Double = 0.0
    @State private var currentTime: Double = 0.0
    @State private var currentSpeed: Double = 0.0
    
    // Computed properties based on session config
    private var totalReps: Int { sessionConfig.reps }
    private var sprintDistance: Int { sessionConfig.distance }
    private var restTime: Int { sessionConfig.restMinutes }
    
    // Initialize with default session or passed configuration
    init(sessionConfig: SessionConfiguration = SessionConfiguration.sessions[0], onClose: (() -> Void)? = nil) {
        self.sessionConfig = sessionConfig
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            // Nike-style dynamic gradient background
            nikeStyleBackground
            
            // Energy burst effect
            if showEnergyBurst {
                energyBurstEffect
            }
            
            VStack(spacing: 0) {
                // Header with Nike styling
                nikeStyleHeader
                
                // Adaptive Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        // Adaptive Core Sprint Elements
                        adaptiveCoreSprintSection
                        
                        // Nike-style Control Buttons
                        controlButtonsSection
                        
                        // Adaptive Phase Information
                        if isRunning {
                            adaptivePhaseInfoSection
                        }
                        
                        // Session-Specific Workout Details
                        if !isRunning || showDetailedView {
                            sessionSpecificDetailsSection
                        }
                        
                        // Rep Log Section - Always visible
                        repLogSection
                        
                        // Additional session info for complex workouts
                        if sessionConfig.workoutVariation != .standard {
                            workoutVariationInfoSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Extra padding for better scrolling
                }
            }
            
            // Voice Coach Message Overlay
            if voiceCoach.showMessage {
                voiceCoachOverlay
            }
        }
        .onAppear {
            startNikeAnimations()
            setupPhoneSync()
            voiceCoach.speak("Welcome to your sprint session! Let's unlock your speed potential! 🔥")
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchWorkoutStateChanged)) { notification in
            if let watchState = notification.object as? WatchWorkoutState {
                syncWithWatchState(watchState)
            }
        }
    }
    
    // MARK: - Nike-Style Visual Components
    
    private var nikeStyleBackground: some View {
        ZStack {
            // Dynamic gradient that changes with energy
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1 + energyLevel * 0.1, green: 0.15 + energyLevel * 0.1, blue: 0.3 + energyLevel * 0.2),
                    Color(red: 0.15 + energyLevel * 0.15, green: 0.2 + energyLevel * 0.15, blue: 0.4 + energyLevel * 0.3),
                    Color(red: 0.2 + energyLevel * 0.2, green: 0.25 + energyLevel * 0.2, blue: 0.5 + energyLevel * 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0), value: energyLevel)
            
            // Nike-style geometric patterns
            GeometryReader { geometry in
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.1 + energyLevel * 0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(
                            x: geometry.size.width * (0.2 + Double(i) * 0.3),
                            y: geometry.size.height * (0.1 + Double(i) * 0.4)
                        )
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 3.0 + Double(i))
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
            }
        }
    }
    
    private var energyBurstEffect: some View {
        ZStack {
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red, Color.clear],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 4)
                    .offset(x: 100)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .scaleEffect(showEnergyBurst ? 2.0 : 0.1)
                    .opacity(showEnergyBurst ? 1.0 : 0.0)
                    .animation(
                        .easeOut(duration: 0.8).delay(Double(i) * 0.1),
                        value: showEnergyBurst
                    )
            }
        }
    }
    
    private var nikeStyleHeader: some View {
        VStack(spacing: 0) {
            // Top status bar with proper spacing
            HStack {
                Button("Close") {
                    onClose?()
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: { voiceCoach.isEnabled.toggle() }) {
                    Image(systemName: voiceCoach.isEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(voiceCoach.isEnabled ? .orange : .gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Status indicators row with proper spacing
            if isRunning {
                HStack(spacing: 16) {
                    // BPM indicator
                    StatusIndicator(
                        title: "BPM",
                        isActive: true,
                        icon: "heart.fill"
                    )
                    
                    // Speed indicator
                    StatusIndicator(
                        title: "Speed",
                        isActive: true,
                        icon: "speedometer"
                    )
                    
                    // Phase indicator
                    StatusIndicator(
                        title: "Phase",
                        isActive: true,
                        icon: "timer"
                    )
                    
                    // Rep indicator
                    StatusIndicator(
                        title: "Set",
                        isActive: true,
                        icon: "repeat"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    private var voiceCoachOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Text(voiceCoach.currentMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Core Components
    
    private var headerView: some View {
        HStack {
            Button("Close") {
                // Close action
            }
            .foregroundColor(.white)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("SPRINT COACH")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(2)
                
                Text(sessionConfig.sessionName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Info") {
                // Info action
            }
            .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Adaptive Core Sprint Section
    private var adaptiveCoreSprintSection: some View {
        VStack(spacing: 20) {
            // Session Information Card - Adapts to session type
            adaptiveSessionInfoCard
            
            // Session Status - Shows current workout info (simplified)
            if !isRunning {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(getAdaptiveSessionTitle())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1.0)
                    
                    Spacer()
                }
            }
            
            // GPS Stopwatch - The Heart of Sprint Coach
            gpsStopwatchView
            
            // Adaptive Rest Timer - Shows different info based on session type
            if currentPhase == .resting {
                adaptiveRestTimerView
            }
        }
    }
    
    // MARK: - Adaptive Phase Information Section
    private var adaptivePhaseInfoSection: some View {
        VStack(spacing: 16) {
            // Current Phase Indicator - Adapts to session phases
            HStack(spacing: 8) {
                ForEach(getSessionPhases(), id: \.self) { phase in
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
            
            // Phase-specific guidance
            if let phaseGuidance = getPhaseGuidance() {
                Text(phaseGuidance)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Session-Specific Details Section
    private var sessionSpecificDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("WORKOUT DETAILS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.0)
                
                Spacer()
                
                Button(action: { showDetailedView.toggle() }) {
                    Image(systemName: showDetailedView ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            
            if showDetailedView || !isRunning {
                VStack(alignment: .leading, spacing: 12) {
                    // Workout structure based on session type
                    workoutStructureView
                    
                    // Expected times and targets
                    if sessionConfig.workoutVariation != .standard {
                        workoutTargetsView
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Workout Variation Info Section
    private var workoutVariationInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WORKOUT PATTERN")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
                .tracking(1.0)
            
            Text(getWorkoutPatternDescription())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
            
            // Pattern visualization for complex workouts
            if sessionConfig.workoutVariation == .pyramid || sessionConfig.workoutVariation == .ladder {
                workoutPatternVisualization
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(sessionConfig.workoutVariation == .pyramid ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(sessionConfig.workoutVariation == .pyramid ? Color.purple.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Session Information Card
    private var sessionInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Session Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionConfig.sessionType.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .tracking(1.0)
                    
                    Text(sessionConfig.sessionName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Difficulty Badge
                Text(sessionConfig.difficulty)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(difficultyColor.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(difficultyColor, lineWidth: 1)
                            )
                    )
            }
            
            // Session Details
            VStack(alignment: .leading, spacing: 8) {
                Text(sessionConfig.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                // Key Metrics Row
                HStack(spacing: 16) {
                    SessionMetric(
                        icon: "ruler",
                        label: "DISTANCE",
                        value: "\(sessionConfig.distance) yd"
                    )
                    
                    SessionMetric(
                        icon: "repeat",
                        label: "REPS",
                        value: "\(sessionConfig.reps)x"
                    )
                    
                    SessionMetric(
                        icon: "clock",
                        label: "REST",
                        value: "\(sessionConfig.restMinutes) min"
                    )
                    
                    SessionMetric(
                        icon: "timer",
                        label: "DURATION",
                        value: sessionConfig.estimatedDuration
                    )
                }
                
                // Focus Area
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text("FOCUS: \(sessionConfig.focus)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(0.5)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var difficultyColor: Color {
        switch sessionConfig.difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
    
    private var gpsStopwatchView: some View {
        HStack(spacing: 16) {
            // Distance - Optimized for 3 digits (100.0)
            VStack(spacing: 4) {
                Text(String(format: "%.1f", currentDistance))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minWidth: 70, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("YARDS")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            // Time - Optimized for MM:SS format
            VStack(spacing: 4) {
                Text(formatTime(currentTime))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minWidth: 70, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("TIME")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.3))
            
            // Speed - Optimized for 2 digits (99.9)
            VStack(spacing: 4) {
                Text(String(format: "%.1f", currentSpeed))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minWidth: 70, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("MPH")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
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
    
    private var restTimerView: some View {
        VStack(spacing: 8) {
            Text("REST TIMER")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.0)
            
            Text("2:00")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
            
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
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var controlButtonsSection: some View {
        VStack(spacing: 16) {
            if !isRunning {
                // Let's Go Button
                Button(action: startWorkout) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 4) {
                            Text("LET'S")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("GO")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            } else {
                // Control Buttons
                HStack(spacing: 20) {
                    // Pause/Play
                    Button(action: togglePause) {
                        ZStack {
                            Circle()
                                .fill(isPaused ? Color.green : Color.orange)
                                .frame(width: 75, height: 75)
                            
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Skip
                    Button(action: skipPhase) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 75, height: 75)
                            
                            Image(systemName: "forward.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Stop
                    Button(action: stopWorkout) {
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
                
                // Labels
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
        }
    }
    
    private var additionalInfoSection: some View {
        VStack(spacing: 16) {
            // Phase Indicator
            HStack(spacing: 8) {
                ForEach(WorkoutPhase.allCases.prefix(5), id: \.self) { phase in
                    Circle()
                        .fill(phase == currentPhase ? Color.orange : Color.white.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .scaleEffect(phase == currentPhase ? 1.3 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPhase)
                }
            }
            
            Text(getCurrentPhaseName())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.orange)
                .tracking(1.0)
        }
    }
    
    // MARK: - Nike-Style Actions with Voice Coaching
    
    private func startWorkout() {
        isRunning = true
        currentPhase = .warmup
        energyLevel = 0.3
        
        // Clear previous rep log for new workout
        repLog.removeAll()
        
        // Nike-style energy burst
        triggerEnergyBurst()
        
        // Voice coaching for workout start
        voiceCoach.speak(MotivationalMessages.warmupMessages.randomElement() ?? "Let's get started!")
        
        // Sync with watch
        syncWorkoutStateWithWatch()
        
        // Start workout logic with automated progression
        startPhaseProgression()
    }
    
    private func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            energyLevel = 0.1
            voiceCoach.speak("Paused! Take a breath, champion. Hit play when you're ready to dominate! 💪")
        } else {
            energyLevel = 0.5
            voiceCoach.speak("Back in action! Let's pick up where we left off! 🔥")
        }
        
        // Sync with watch
        syncWorkoutStateWithWatch()
    }
    
    private func skipPhase() {
        // Complete current rep if in active phase
        if [.drill, .strides, .sprints].contains(currentPhase) {
            completeCurrentRep()
        }
        
        voiceCoach.speak("Moving to the next phase! Stay focused, stay strong! ⚡")
        advanceToNextPhase()
        
        // Sync with watch
        syncWorkoutStateWithWatch()
    }
    
    private func stopWorkout() {
        isRunning = false
        isPaused = false
        currentPhase = .warmup
        currentRep = 1
        energyLevel = 0.0
        
        voiceCoach.speak("Workout complete! You showed up and put in the work. That's what champions do! 🏆")
        
        // Sync with watch
        syncWorkoutStateWithWatch()
    }
    
    private func startPhaseProgression() {
        // Start with warmup phase coaching
        providePhaseCoaching()
        
        // This would integrate with actual timers in real implementation
        // For demo, we'll simulate phase progression with voice coaching
    }
    
    private func advanceToNextPhase() {
        let _ = currentPhase // For potential future use
        
        switch currentPhase {
        case .warmup:
            currentPhase = .stretch
            energyLevel = 0.4
        case .stretch:
            currentPhase = .drill
            energyLevel = 0.5
        case .drill:
            currentPhase = .strides
            energyLevel = 0.6
        case .strides:
            currentPhase = .sprints
            energyLevel = 0.8
            triggerEnergyBurst()
        case .sprints:
            if currentRep < totalReps {
                currentPhase = .resting
                currentRep += 1
                energyLevel = 0.3
            } else {
                currentPhase = .cooldown
                energyLevel = 0.2
            }
        case .resting:
            currentPhase = .sprints
            energyLevel = 0.8
            triggerEnergyBurst()
        case .cooldown:
            currentPhase = .completed
            isRunning = false
            energyLevel = 0.0
        case .completed:
            break
        }
        
        // Provide voice coaching for new phase
        providePhaseCoaching()
    }
    
    private func providePhaseCoaching() {
        let messages: [String]
        
        switch currentPhase {
        case .warmup:
            messages = MotivationalMessages.warmupMessages
        case .stretch:
            messages = MotivationalMessages.stretchMessages
        case .drill:
            messages = MotivationalMessages.drillMessages
        case .strides:
            messages = MotivationalMessages.strideMessages
        case .sprints:
            messages = MotivationalMessages.sprintMessages
        case .resting:
            messages = MotivationalMessages.restMessages
        case .cooldown:
            messages = MotivationalMessages.cooldownMessages
        case .completed:
            voiceCoach.speak("Session complete! You just crushed that workout! Time to recover and get ready for the next one! 🌟")
            return
        }
        
        if let message = messages.randomElement() {
            voiceCoach.speak(message)
        }
    }
    
    private func startNikeAnimations() {
        pulseAnimation = true
        
        // Continuous energy level fluctuation
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if self.isRunning {
                withAnimation(.easeInOut(duration: 2.0)) {
                    self.energyLevel = Double.random(in: 0.3...0.9)
                }
            }
        }
    }
    
    private func triggerEnergyBurst() {
        withAnimation(.easeOut(duration: 0.1)) {
            showEnergyBurst = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.showEnergyBurst = false
            }
        }
    }
    
    private func getCurrentPhaseName() -> String {
        switch currentPhase {
        case .warmup: return "WARM-UP"
        case .stretch: return "STRETCH"
        case .drill: return "DRILLS"
        case .strides: return "STRIDES"
        case .sprints: return "SPRINTS"
        case .resting: return "REST"
        case .cooldown: return "COOL DOWN"
        case .completed: return "COMPLETE"
        }
    }
    
    // MARK: - Adaptive Helper Functions
    
    private func getAdaptiveSessionTitle() -> String {
        switch sessionConfig.workoutVariation {
        case .pyramid:
            return "PYRAMID TRAINING"
        case .ladder:
            return "LADDER PROGRESSION"
        case .intervals:
            return "INTERVAL TRAINING"
        case .flying:
            return "FLYING SPRINTS"
        case .acceleration:
            return "ACCELERATION WORK"
        case .endurance:
            return "ENDURANCE SPEED"
        case .standard:
            return "\(sprintDistance) YARD SPRINTS"
        }
    }
    
    private func getSessionPhases() -> [WorkoutPhase] {
        return sessionConfig.workoutVariation.phases
    }
    
    private func getPhaseGuidance() -> String? {
        switch currentPhase {
        case .warmup:
            return "Prepare your body for explosive movement"
        case .stretch:
            return "Dynamic stretching for optimal range of motion"
        case .drill:
            return "Focus on perfect technique and form"
        case .strides:
            return "Build speed progressively with controlled acceleration"
        case .sprints:
            return getSprintGuidance()
        case .resting:
            return "Active recovery - stay loose and focused"
        case .cooldown:
            return "Gradual recovery to prevent injury"
        case .completed:
            return nil
        }
    }
    
    private func getSprintGuidance() -> String {
        switch sessionConfig.workoutVariation {
        case .pyramid:
            return "Progressive distances - pace yourself for the full pyramid"
        case .ladder:
            return "Build speed with each distance - finish strong"
        case .intervals:
            return "High intensity with short recovery - maintain speed"
        case .flying:
            return "Maximum velocity with running start - pure speed"
        case .acceleration:
            return "Explosive starts - first 10 yards are crucial"
        case .endurance:
            return "Maintain speed over longer distances"
        case .standard:
            return "Maximum effort - give everything you have"
        }
    }
    
    private func getWorkoutPatternDescription() -> String {
        switch sessionConfig.workoutVariation {
        case .pyramid:
            return "Progressive distance pyramid building up to peak distance then back down. Develops both speed and endurance through varied distances."
        case .ladder:
            return "Progressive ladder starting short and building to maximum distance. Each rep should be faster than the last."
        case .intervals:
            return "High-intensity intervals with short recovery periods. Focus on maintaining speed throughout the session."
        case .flying:
            return "Flying sprints with 20-yard buildup before timing zone. Develops maximum velocity and speed maintenance."
        case .acceleration:
            return "Pure acceleration work focusing on explosive starts and first-step quickness from stationary position."
        case .endurance:
            return "Speed endurance training combining speed work with longer recovery for sustained high-intensity efforts."
        case .standard:
            return "Classic sprint training at consistent distance. Focus on maximum effort and perfect technique."
        }
    }
    
    // MARK: - Adaptive UI Components
    
    private var adaptiveSessionInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Session Header with variation-specific styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionConfig.sessionType.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(getVariationColor())
                        .tracking(1.0)
                    
                    Text(sessionConfig.sessionName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Difficulty Badge with variation styling
                Text(sessionConfig.difficulty)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(difficultyColor.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(difficultyColor, lineWidth: 1)
                            )
                    )
            }
            
            // Session Details
            VStack(alignment: .leading, spacing: 8) {
                Text(sessionConfig.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                // Adaptive Key Metrics Row
                HStack(spacing: 12) {
                    SessionMetric(
                        icon: "ruler",
                        label: "DISTANCE",
                        value: getDistanceDisplay()
                    )
                    
                    SessionMetric(
                        icon: "repeat",
                        label: "REPS",
                        value: "\(sessionConfig.reps)x"
                    )
                    
                    SessionMetric(
                        icon: "clock",
                        label: "REST",
                        value: "\(sessionConfig.restMinutes) min"
                    )
                    
                    SessionMetric(
                        icon: "timer",
                        label: "DURATION",
                        value: sessionConfig.estimatedDuration
                    )
                }
                
                // Focus Area
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(getVariationColor())
                    
                    Text("FOCUS: \(sessionConfig.focus)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(0.5)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getVariationColor().opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var adaptiveRestTimerView: some View {
        VStack(spacing: 8) {
            Text("REST TIMER")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.0)
            
            Text(formatCountdownDisplay(phaseTimeRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(phaseTimeRemaining < 30 ? .red : .orange)
            
            Text(getRestTimerSubtitle())
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
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var workoutStructureView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKOUT STRUCTURE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.orange)
                .tracking(1.0)
            
            ForEach(getSessionPhases(), id: \.self) { phase in
                HStack {
                    Image(systemName: getPhaseIcon(phase))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(phase == currentPhase ? .orange : .white.opacity(0.6))
                        .frame(width: 20)
                    
                    Text(getPhaseDisplayName(phase))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(phase == currentPhase ? .white : .white.opacity(0.7))
                    
                    Spacer()
                    
                    if phase == currentPhase {
                        Text("CURRENT")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.orange)
                            .tracking(0.5)
                    }
                }
            }
        }
    }
    
    private var workoutTargetsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TARGET TIMES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
                .tracking(1.0)
            
            Text(getTargetTimesDescription())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private var workoutPatternVisualization: some View {
        HStack(spacing: 4) {
            ForEach(getPatternDistances(), id: \.self) { distance in
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: 30, height: CGFloat(distance) / 2)
                    
                    Text("\(distance)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Functions for Adaptive UI
    
    private func getVariationColor() -> Color {
        switch sessionConfig.workoutVariation {
        case .pyramid: return .purple
        case .ladder: return .blue
        case .intervals: return .red
        case .flying: return .cyan
        case .acceleration: return .green
        case .endurance: return .yellow
        case .standard: return .orange
        }
    }
    
    private func getDistanceDisplay() -> String {
        switch sessionConfig.workoutVariation {
        case .pyramid: return "20-\(sessionConfig.distance) yd"
        case .ladder: return "10-\(sessionConfig.distance) yd"
        default: return "\(sessionConfig.distance) yd"
        }
    }
    
    private func getRestTimerSubtitle() -> String {
        switch sessionConfig.workoutVariation {
        case .intervals: return "UNTIL NEXT INTERVAL"
        case .pyramid: return "UNTIL NEXT DISTANCE"
        case .ladder: return "UNTIL NEXT LEVEL"
        default: return "UNTIL NEXT SPRINT"
        }
    }
    
    private func getPhaseIcon(_ phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup: return "figure.walk"
        case .stretch: return "figure.flexibility"
        case .drill: return "figure.run"
        case .strides: return "figure.run.motion"
        case .sprints: return "bolt.fill"
        case .resting: return "pause.circle"
        case .cooldown: return "figure.cooldown"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    private func getPhaseDisplayName(_ phase: WorkoutPhase) -> String {
        switch phase {
        case .warmup: return "Dynamic Warm-up"
        case .stretch: return "Dynamic Stretching"
        case .drill: return "Technique Drills"
        case .strides: return "Build-up Strides"
        case .sprints: return "Sprint Intervals"
        case .resting: return "Active Recovery"
        case .cooldown: return "Cool Down"
        case .completed: return "Session Complete"
        }
    }
    
    private func getTargetTimesDescription() -> String {
        switch sessionConfig.difficulty {
        case "Beginner":
            return "Focus on form over speed. Times will improve with consistency."
        case "Intermediate":
            return "Target: 4.8-5.5s for 40yd. Push your limits while maintaining form."
        case "Advanced":
            return "Target: 4.3-4.8s for 40yd. Elite speed with perfect technique."
        default:
            return "Give maximum effort on every rep."
        }
    }
    
    private func getPatternDistances() -> [Int] {
        switch sessionConfig.workoutVariation {
        case .pyramid:
            let max = sessionConfig.distance
            return [20, 30, max, 30, 20]
        case .ladder:
            let max = sessionConfig.distance
            return Array(stride(from: 10, through: max, by: 10))
        default:
            return [sessionConfig.distance]
        }
    }
    
    private func formatCountdownDisplay(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Rep Log Section
    
    private var repLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rep Log Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("REP LOG")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1.0)
                }
                
                Spacer()
                
                Button(action: { showRepLog.toggle() }) {
                    Image(systemName: showRepLog ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Rep Log Content
            if showRepLog || !repLog.isEmpty {
                VStack(spacing: 8) {
                    if repLog.isEmpty {
                        // Empty State
                        VStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("Times will appear here automatically")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    } else {
                        // Rep Log Entries
                        LazyVStack(spacing: 6) {
                            ForEach(repLog.suffix(6)) { entry in
                                RepLogRow(entry: entry)
                            }
                        }
                        
                        // Show More Button if there are more than 6 entries
                        if repLog.count > 6 {
                            Button("Show All (\(repLog.count) total)") {
                                showRepLog = true
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            // Initialize with sample data for demonstration
            initializeSampleRepLog()
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.2f", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    private func addRepLogEntry(type: RepLogEntry.RepType, distance: Int, time: Double?) {
        let entry = RepLogEntry(
            rep: repLog.filter { $0.type == type }.count + 1,
            type: type,
            distance: distance,
            time: time,
            timestamp: Date(),
            isCompleted: time != nil
        )
        repLog.append(entry)
    }
    
    private func initializeSampleRepLog() {
        // Add some sample entries to demonstrate the rep log
        if repLog.isEmpty {
            addRepLogEntry(type: .drill, distance: 20, time: 15.2)
            addRepLogEntry(type: .drill, distance: 20, time: 14.8)
            addRepLogEntry(type: .stride, distance: 30, time: 4.1)
            addRepLogEntry(type: .stride, distance: 30, time: 3.9)
            addRepLogEntry(type: .sprint, distance: 40, time: 5.2)
            addRepLogEntry(type: .sprint, distance: 40, time: 5.1)
        }
    }
    
    // MARK: - Automated Timer Integration
    
    private func completeCurrentRep() {
        let repType: RepLogEntry.RepType
        let distance: Int
        
        switch currentPhase {
        case .drill:
            repType = .drill
            distance = 20 // Standard drill distance
        case .strides:
            repType = .stride
            distance = Int(Double(sprintDistance) * 0.75) // 75% of sprint distance
        case .sprints:
            repType = .sprint
            distance = sprintDistance // Use session configuration
        default:
            return
        }
        
        // Simulate GPS time capture based on distance
        let baseTime = Double(distance) / 8.0 // Base speed calculation
        let variation = Double.random(in: -0.3...0.3)
        let simulatedTime = baseTime + variation
        
        addRepLogEntry(type: repType, distance: distance, time: simulatedTime)
        
        // Update current metrics for display
        currentDistance = Double(distance)
        currentTime = simulatedTime
        currentSpeed = Double(distance) / simulatedTime * 2.045 // Convert to mph approximation
        
        // Nike-style performance feedback with voice coaching
        providePerformanceFeedback(repType: repType, time: simulatedTime, distance: distance)
        
        // Energy burst for sprint completions
        if repType == .sprint {
            triggerEnergyBurst()
        }
    }
    
    private func providePerformanceFeedback(repType: RepLogEntry.RepType, time: Double, distance: Int) {
        var message = ""
        
        switch repType {
        case .drill:
            let encouragement = ["Perfect form! 🎯", "Technique on point! ⚡", "Smooth execution! 💪"]
            message = encouragement.randomElement() ?? "Great drill work!"
            
        case .stride:
            let buildUp = ["Feel that acceleration! 🚀", "Building speed beautifully! ✨", "Rhythm is everything! 🏃‍♂️"]
            message = buildUp.randomElement() ?? "Nice stride work!"
            
        case .sprint:
            // Performance-based feedback for sprints
            if distance == 40 {
                if time < 4.5 {
                    message = "ELITE SPEED! 🔥 That's championship level right there!"
                } else if time < 5.0 {
                    message = "SOLID TIME! 💪 You're in the zone, keep pushing!"
                } else if time < 5.5 {
                    message = "Good effort! ⚡ Every rep makes you faster!"
                } else {
                    message = "Keep grinding! 🚀 Speed comes with consistency!"
                }
            } else {
                let sprintEncouragement = [
                    "EXPLOSIVE! 💨 That's how you attack the track!",
                    "BEAST MODE! 🔥 You're getting stronger every rep!",
                    "POWERFUL! ⚡ Feel that speed building!"
                ]
                message = sprintEncouragement.randomElement() ?? "Great sprint!"
            }
        }
        
        voiceCoach.speak(message)
    }
    
    // MARK: - Phone-Watch Sync Functions
    
    private func setupPhoneSync() {
        phoneSyncManager.startSession()
    }
    
    private func syncWorkoutStateWithWatch() {
        let phoneState = PhoneWorkoutState(
            isRunning: isRunning,
            isPaused: isPaused,
            currentPhase: currentPhase,
            currentRep: currentRep,
            phaseTimeRemaining: phaseTimeRemaining,
            currentDistance: currentDistance,
            currentTime: currentTime,
            currentSpeed: currentSpeed,
            repLog: repLog,
            timestamp: Date()
        )
        
        phoneSyncManager.sendWorkoutState(phoneState)
    }
    
    private func syncWithWatchState(_ watchState: WatchWorkoutState) {
        // Update phone state based on watch changes
        DispatchQueue.main.async {
            // Only sync if watch initiated the change (check timestamp)
            if watchState.timestamp > Date().addingTimeInterval(-2) {
                self.isRunning = watchState.isRunning
                self.isPaused = watchState.isPaused
                self.currentPhase = watchState.currentPhase
                self.currentRep = watchState.currentRep
                self.phaseTimeRemaining = watchState.phaseTimeRemaining
                
                // Update energy level based on state
                if watchState.isRunning {
                    self.energyLevel = 0.6
                } else {
                    self.energyLevel = 0.2
                }
                
                // Provide voice feedback for watch-initiated changes
                if watchState.isRunning && !self.isRunning {
                    self.voiceCoach.speak("Workout started from watch! 📱⌚")
                } else if !watchState.isRunning && self.isRunning {
                    self.voiceCoach.speak("Workout stopped from watch! 🛑")
                }
            }
        }
    }
}

// MARK: - Phone Sync Manager
class PhoneSyncManager: NSObject, ObservableObject {
    static let shared = PhoneSyncManager()
    
    private var session: WCSession?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
        }
    }
    
    func startSession() {
        session?.activate()
    }
    
    func sendWorkoutState(_ state: PhoneWorkoutState) {
        // Note: Full WatchConnectivity implementation would encode and send state
        print("📱 Would send workout state to watch: \(state.isRunning ? "Running" : "Stopped")")
    }
}

// MARK: - WCSessionDelegate for Phone
extension PhoneSyncManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("📱 Phone session activated with state: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 Phone session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 Phone session deactivated")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Note: Full WatchConnectivity implementation would decode and process message
        print("📱 Received message from watch")
    }
}

// MARK: - Rep Log Row Component
struct RepLogRow: View {
    let entry: RepLogEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Rep Type Icon
            Image(systemName: entry.type.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(entry.type.color)
                .frame(width: 20)
            
            // Rep Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(entry.type.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(entry.distance)yd")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text("Rep \(entry.rep)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Time Display
            VStack(alignment: .trailing, spacing: 2) {
                if let time = entry.time {
                    Text(String(format: "%.2fs", time))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    // Performance indicator
                    if entry.type == .sprint {
                        let performance = getPerformanceIndicator(time: time, distance: entry.distance)
                        Text(performance.text)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(performance.color)
                    }
                } else {
                    Text("--")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(entry.type.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(entry.type.color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    private func getPerformanceIndicator(time: Double, distance: Int) -> (text: String, color: Color) {
        // Simple performance indicators for 40-yard sprints
        if distance == 40 {
            if time < 4.5 {
                return ("ELITE", .green)
            } else if time < 5.0 {
                return ("GOOD", .yellow)
            } else if time < 5.5 {
                return ("AVG", .orange)
            } else {
                return ("SLOW", .red)
            }
        }
        return ("", .clear)
    }
}

// MARK: - Session Metric Component
struct SessionMetric: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Phase Enum
enum WorkoutPhase: CaseIterable {
    case warmup, stretch, drill, strides, sprints, resting, cooldown, completed
}


#Preview {
    UnifiedSprintCoachView(sessionConfig: SessionConfiguration.sessions[0])
}
