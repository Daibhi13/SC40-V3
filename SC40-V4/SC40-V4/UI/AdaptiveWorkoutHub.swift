import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Enhanced workout selection that works on both iPhone and Apple Watch
struct AdaptiveWorkoutHub: View {
    @State private var selectedPlatform: WorkoutPlatform = .auto
    @State private var showingWorkout = false
    @State private var isWatchAvailable = false
    @State private var watchStatus = "Checking..."
    
    enum WorkoutPlatform: String, CaseIterable {
        case auto = "Smart Choice"
        case phone = "iPhone Only"  
        case watch = "Apple Watch"
        
        var icon: String {
            switch self {
            case .auto: return "brain.head.profile"
            case .phone: return "iphone"
            case .watch: return "applewatch"
            }
        }
        
        var description: String {
            switch self {
            case .auto: return "Automatically choose the best option based on your devices"
            case .phone: return "Use iPhone GPS tracking and display for workouts"
            case .watch: return "Use Apple Watch for optimal wrist-based experience"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SC40 Sprint Training")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Works seamlessly on iPhone & Apple Watch")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Platform Status Card
                VStack(spacing: 16) {
                    Text("Your Available Platforms")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        // iPhone Platform (Always Available)
                        PlatformStatusRow(
                            title: "iPhone",
                            icon: "iphone",
                            isAvailable: true,
                            description: "GPS tracking ready • Full session library access"
                        )
                        
                        // Apple Watch Platform
                        PlatformStatusRow(
                            title: "Apple Watch",
                            icon: "applewatch",
                            isAvailable: isWatchAvailable,
                            description: watchStatus
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                
                // Workout Selection
                VStack(spacing: 16) {
                    Text("Choose Your Workout Experience")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        // Smart Choice Button (Recommended)
                        WorkoutOptionButton(
                            title: "🧠 Smart Workout",
                            subtitle: "Automatically choose the best platform for your situation",
                            isPrimary: true,
                            isRecommended: true
                        ) {
                            selectedPlatform = .auto
                            showingWorkout = true
                        }
                        
                        HStack(spacing: 12) {
                            // iPhone Button
                            WorkoutOptionButton(
                                title: "📱 iPhone",
                                subtitle: "GPS tracking with phone display"
                            ) {
                                selectedPlatform = .phone
                                showingWorkout = true
                            }
                            
                            // Apple Watch Button
                            WorkoutOptionButton(
                                title: "⌚ Watch", 
                                subtitle: isWatchAvailable ? "Wrist-based experience" : "Not available",
                                isEnabled: isWatchAvailable
                            ) {
                                selectedPlatform = .watch
                                showingWorkout = true
                            }
                        }
                    }
                }
                
                // Benefits Section
                BenefitsSection()
                
                // Session Preview
                SessionQuickPreview()
            }
            .padding()
        }
        .navigationTitle("SC40 Workouts")
        .sheet(isPresented: $showingWorkout) {
            WorkoutLauncherView(platform: selectedPlatform)
        }
        .onAppear {
            checkWatchAvailability()
        }
    }
    
    private func checkWatchAvailability() {
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            let session = WCSession.default
            isWatchAvailable = session.isPaired && session.isWatchAppInstalled
            
            if isWatchAvailable {
                watchStatus = session.isReachable ? "Connected and ready" : "Available but not reachable"
            } else {
                watchStatus = session.isPaired ? "Watch paired but app not installed" : "Apple Watch not paired"
            }
        } else {
            watchStatus = "WatchConnectivity not supported"
        }
        #else
        watchStatus = "Apple Watch support not available"
        #endif
    }
}

struct PlatformStatusRow: View {
    let title: String
    let icon: String
    let isAvailable: Bool
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isAvailable ? .green : .gray)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct WorkoutOptionButton: View {
    let title: String
    let subtitle: String
    var isPrimary: Bool = false
    var isRecommended: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Text(title)
                        .font(isPrimary ? .headline : .subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isPrimary ? .white : .primary)
                    
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isPrimary ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                isPrimary ? 
                AnyView(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                AnyView(Color.gray.opacity(0.1))
            )
            .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct BenefitsSection: View {
    let benefits = [
        ("📱 iPhone Benefits", "Large display, GPS tracking, full session library, longer battery life"),
        ("⌚ Watch Benefits", "Wrist convenience, heart rate monitoring, always-on display, quick access"),
        ("🧠 Smart Benefits", "Automatic platform selection, seamless switching, optimal user experience")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Why Choose Dual Platform?")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(Array(benefits.enumerated()), id: \.0) { index, benefit in
                    HStack(alignment: .top, spacing: 12) {
                        Text(benefit.0.prefix(2))
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(benefit.0.dropFirst(3)))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(benefit.1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct SessionQuickPreview: View {
    let sessions = [
        ("Sprint Training", "40 yard focus runs"),
        ("Benchmark Tests", "Track your progress"), 
        ("Tempo Runs", "Build sprint endurance")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Available Training Sessions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("240+ sessions")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(sessions.enumerated()), id: \.0) { index, session in
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text(session.0)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(session.1)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct WorkoutLauncherView: View {
    let platform: AdaptiveWorkoutHub.WorkoutPlatform
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Platform Icon
                Image(systemName: platform.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Title
                Text("\(platform.rawValue) Workout")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Description
                Text(platform.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Launch based on platform
                Group {
                    switch platform {
                    case .phone:
                        PhoneLaunchView()
                    case .watch:
                        WatchLaunchView()
                    case .auto:
                        SmartLaunchView()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("SC40 Workout")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if !os(macOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

struct PhoneLaunchView: View {
    @State private var showingPhoneWorkout = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📱 iPhone Workout Ready")
                .font(.headline)
            
            Text("Your workout will use your iPhone's GPS for accurate distance tracking and display the full session interface.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Launch button for the phone workout
            NavigationLink("Start iPhone Workout") {
                PhoneWorkoutInterface()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

struct SmartLaunchView: View {
    @State private var isAnalyzing = true
    @State private var showingPhoneWorkout = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isAnalyzing {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("🧠 Analyzing your devices...")
                        .font(.headline)
                    
                    Text("SC40 is determining the best workout experience based on your available devices and current context.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .onAppear {
                    // Simulate analysis delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isAnalyzing = false
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text("📱 iPhone Selected")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Based on your current setup, iPhone provides the best workout experience with GPS tracking and full session access.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    NavigationLink("Start Smart Workout") {
                        PhoneWorkoutInterface()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

// Enhanced phone workout interface with full session library integration
struct PhoneWorkoutInterface: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: MockTrainingSession?
    @State private var showingWorkout = false
    @State private var todaysRecommendedSessions: [MockTrainingSession] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📱 iPhone Workout")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("GPS Sprint Training • Full Session Library")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
                
                // GPS Status Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.green)
                        Text("GPS Ready")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    
                    Text("Your iPhone will provide precision GPS tracking for accurate sprint timing and distance measurement. Ensure you have a clear view of the sky for optimal results.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
                
                // Today's Recommended Sessions
                if !todaysRecommendedSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("🎯 Today's Recommended Sessions")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(todaysRecommendedSessions.count) sessions")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(todaysRecommendedSessions, id: \.id) { session in
                                    RecommendedSessionCard(session: session) {
                                        selectedSession = session
                                        showingWorkout = true
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                // Full Session Library Access
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("📚 Complete Session Library")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("240+ sessions")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Text("Access the complete SC40 training library with sessions for all levels and training phases.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Browse All Sessions") {
                        // TODO: Navigate to session library browser
                        print("📚 Opening session library browser...")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                
                // Quick Start Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("⚡ Quick Start")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        QuickStartButton(
                            icon: "⚡",
                            title: "40-Yard Test",
                            description: "Benchmark sprint"
                        ) {
                            startBenchmarkSession()
                        }
                        
                        QuickStartButton(
                            icon: "🏃‍♂️",
                            title: "Acceleration",
                            description: "10-20 yard focus"
                        ) {
                            startAccelerationSession()
                        }
                        
                        QuickStartButton(
                            icon: "💨",
                            title: "Top Speed",
                            description: "30+ yard sprints"
                        ) {
                            startTopSpeedSession()
                        }
                        
                        QuickStartButton(
                            icon: "🔋",
                            title: "Endurance",
                            description: "Repeated sprints"
                        ) {
                            startEnduranceSession()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("iPhone Workout")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            loadRecommendedSessions()
        }
        .sheet(isPresented: $showingWorkout) {
            if let session = selectedSession {
                PhoneWorkoutFlowView(session: session)
            }
        }
    }
    
    private func loadRecommendedSessions() {
        // Mock recommended sessions for now - replace with SessionLibrary integration
        todaysRecommendedSessions = [
            mockTrainingSession(type: "40 Yard Sprint", focus: "Benchmark Test", distance: 40, reps: 3),
            mockTrainingSession(type: "Acceleration", focus: "Drive Phase", distance: 20, reps: 6),
            mockTrainingSession(type: "Speed Endurance", focus: "Repeated Sprints", distance: 60, reps: 4)
        ]
    }
    
    private func mockTrainingSession(type: String, focus: String, distance: Int, reps: Int) -> MockTrainingSession {
        MockTrainingSession(
            type: type,
            focus: focus,
            distance: distance,
            reps: reps,
            description: "iPhone GPS workout session"
        )
    }
    
    private func startBenchmarkSession() {
        selectedSession = mockTrainingSession(type: "40 Yard Test", focus: "Benchmark", distance: 40, reps: 3)
        showingWorkout = true
    }
    
    private func startAccelerationSession() {
        selectedSession = mockTrainingSession(type: "Acceleration Focus", focus: "Drive Phase", distance: 20, reps: 8)
        showingWorkout = true
    }
    
    private func startTopSpeedSession() {
        selectedSession = mockTrainingSession(type: "Max Velocity", focus: "Top Speed", distance: 40, reps: 5)
        showingWorkout = true
    }
    
    private func startEnduranceSession() {
        selectedSession = mockTrainingSession(type: "Speed Endurance", focus: "Repeated Sprints", distance: 30, reps: 10)
        showingWorkout = true
    }
}

// MARK: - Supporting Data Models

struct MockTrainingSession: Identifiable {
    let id = UUID()
    let type: String
    let focus: String
    let distance: Int
    let reps: Int
    let description: String
}

// MARK: - Supporting View Components

struct RecommendedSessionCard: View {
    let session: MockTrainingSession
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(session.type)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Text(session.focus)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                HStack {
                    Text("\(session.reps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(session.distance) yards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 180, height: 100)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickStartButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PhoneWorkoutFlowView: View {
    let session: MockTrainingSession
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var isRunning = false
    @State private var currentRep = 1
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var workoutResults: [WorkoutResult] = []
    @State private var showCompletion = false
    
    // Add a way to access UserProfileViewModel for saving
    // Assuming it's passed or accessed via environment
    @State private var userProfileVM: UserProfileViewModel? // For saving progress
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warm-Up"
        case stretch = "Stretch"
        case drill = "Drill"
        case strides = "Strides"
        case sprints = "Sprints"
        case cooldown = "Cool Down"
        
        var icon: String {
            switch self {
            case .warmup: return "thermometer.medium"
            case .stretch: return "figure.flexibility"
            case .drill: return "figure.flexibility"
            case .strides: return "figure.walk"
            case .sprints: return "figure.run"
            case .cooldown: return "snowflake"
            }
        }
        
        var color: Color {
            switch self {
            case .warmup: return .orange
            case .stretch: return .purple
            case .drill: return .purple
            case .strides: return .blue
            case .sprints: return .red
            case .cooldown: return .cyan
            }
        }
        
        var description: String {
            switch self {
            case .warmup: return "Jog lightly and do dynamic stretches"
            case .stretch: return "Static stretches for mobility"
            case .drill: return "Technical drills for form"
            case .strides: return "Build-up runs for rhythm"
            case .sprints: return "Full effort sprint reps"
            case .cooldown: return "Light jogging and recovery"
            }
        }
    }
    
    struct WorkoutResult {
        let phase: WorkoutPhase
        let duration: TimeInterval
        let notes: String
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Session Header
                VStack(spacing: 8) {
                    Text(session.type)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(session.focus)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    HStack {
                        Text("\(session.reps) reps")
                        Text("•")
                        Text("\(session.distance) yards")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Phase Progress
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WorkoutPhase.allCases, id: \.self) { phase in
                            PhaseProgressView(
                                phase: phase,
                                isCurrent: phase == currentPhase,
                                isCompleted: isPhaseCompleted(phase)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Main Workout Display
                VStack(spacing: 20) {
                    Image(systemName: currentPhase.icon)
                        .font(.system(size: 60))
                        .foregroundColor(currentPhase.color)
                    
                    Text(currentPhase.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(currentPhase.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if currentPhase == .sprints {
                        VStack(spacing: 8) {
                            Text("Rep \(currentRep) of \(session.reps)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text(formatTime(elapsedTime))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Control Buttons
                VStack(spacing: 16) {
                    if currentPhase == .sprints {
                        Button(isRunning ? "Stop Sprint" : "Start Sprint") {
                            toggleSprint()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isRunning ? Color.red : Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button("Next Phase") {
                        nextPhase()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("iPhone Workout")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if !os(macOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End Workout") {
                        endWorkout()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("End Workout") {
                        endWorkout()
                    }
                }
                #endif
            }
            .sheet(isPresented: $showCompletion) {
                WorkoutCompletionView(results: workoutResults, session: session)
            }
        }
    }
    
    private func isPhaseCompleted(_ phase: WorkoutPhase) -> Bool {
        let phases = WorkoutPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else { return false }
        return phaseIndex < currentIndex
    }
    
    private func nextPhase() {
        let phases = WorkoutPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase) else { return }
        
        // Save current phase result
        workoutResults.append(WorkoutResult(phase: currentPhase, duration: elapsedTime, notes: "Completed"))
        
        if currentIndex < phases.count - 1 {
            currentPhase = phases[currentIndex + 1]
            elapsedTime = 0
        } else {
            // Workout complete
            saveWorkout()
            showCompletion = true
        }
    }
    
    private func toggleSprint() {
        if isRunning {
            stopSprint()
        } else {
            startSprint()
        }
    }
    
    private func startSprint() {
        isRunning = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                elapsedTime += 0.1
            }
        }
    }
    
    private func stopSprint() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Move to next rep or phase
        if currentRep < session.reps {
            currentRep += 1
        } else {
            nextPhase()
        }
    }
    
    private func endWorkout() {
        timer?.invalidate()
        saveWorkout()
        dismiss()
    }
    
    private func saveWorkout() {
        // Save to UserProfileViewModel or a service
        // For now, print to console
        print("Saving workout results for \(session.type)")
        for result in workoutResults {
            print("Phase: \(result.phase.rawValue), Duration: \(result.duration)")
        }
        // TODO: Integrate with UserProfileViewModel to update progress
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        String(format: "%.2f", time)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Session Header
                VStack(spacing: 8) {
                    Text(session.type)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(session.focus)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    HStack {
                        Text("\(session.reps) reps")
                        Text("•")
                        Text("\(session.distance) yards")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Phase Progress
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WorkoutPhase.allCases, id: \.self) { phase in
                            PhaseProgressView(
                                phase: phase,
                                isCurrent: phase == currentPhase,
                                isCompleted: isPhaseCompleted(phase)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Main Workout Display
                VStack(spacing: 20) {
                    Image(systemName: currentPhase.icon)
                        .font(.system(size: 60))
                        .foregroundColor(currentPhase.color)
                    
                    Text(currentPhase.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(currentPhase.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if currentPhase == .sprints {
                        VStack(spacing: 8) {
                            Text("Rep \(currentRep) of \(session.reps)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text(formatTime(elapsedTime))
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Control Buttons
                VStack(spacing: 16) {
                    if currentPhase == .sprints {
                        Button(isRunning ? "Stop Sprint" : "Start Sprint") {
                            toggleSprint()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isRunning ? Color.red : Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button("Next Phase") {
                        nextPhase()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("iPhone Workout")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if !os(macOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End Workout") {
                        endWorkout()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("End Workout") {
                        endWorkout()
                    }
                }
                #endif
            }
            .sheet(isPresented: $showCompletion) {
                WorkoutCompletionView(results: workoutResults, session: session)
            }
        }
    }
    
    private func isPhaseCompleted(_ phase: WorkoutPhase) -> Bool {
        let phases = WorkoutPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else { return false }
        return phaseIndex < currentIndex
    }
    
    private func nextPhase() {
        let phases = WorkoutPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase) else { return }
        
        // Save current phase result
        workoutResults.append(WorkoutResult(phase: currentPhase, duration: elapsedTime, notes: "Completed"))
        
        if currentIndex < phases.count - 1 {
            currentPhase = phases[currentIndex + 1]
            elapsedTime = 0
        } else {
            // Workout complete
            saveWorkout()
            showCompletion = true
        }
    }
    
    private func toggleSprint() {
        if isRunning {
            stopSprint()
        } else {
            startSprint()
        }
    }
    
    private func startSprint() {
        isRunning = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                elapsedTime += 0.1
            }
        }
    }
    
    private func stopSprint() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Move to next rep or phase
        if currentRep < session.reps {
            currentRep += 1
        } else {
            nextPhase()
        }
    }
    
    private func endWorkout() {
        timer?.invalidate()
        saveWorkout()
        dismiss()
    }
    
    private func saveWorkout() {
        // Save to UserProfileViewModel or a service
        // For now, print to console
        print("Saving workout results for \(session.type)")
        for result in workoutResults {
            print("Phase: \(result.phase.rawValue), Duration: \(result.duration)")
        }
        // TODO: Integrate with UserProfileViewModel to update progress
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        String(format: "%.2f", time)
    }
}

struct WorkoutCompletionView: View {
    let results: [WorkoutResult]
    let session: MockTrainingSession
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Completion Header
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Workout Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Great job on \(session.type)!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Results Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Phase Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(results, id: \.phase) { result in
                            HStack {
                                Text(result.phase.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(result.phase.color)
                                Spacer()
                                Text("\(String(format: "%.1f", result.duration))s")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Progress Update (Placeholder)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress Updated")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Your session has been saved. Check your profile for updated stats and streaks.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Close Button
                    Button("Close") {
                        // Dismiss the sheet
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Workout Summary")
        }
    }
}

struct SessionOption {
    let name: String
    let reps: Int
    let distance: String
    let focus: String
}

struct SessionOptionCard: View {
    let session: SessionOption
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(session.reps) reps")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(session.distance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(session.focus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "figure.run.circle")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct WatchLaunchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("⌚ Check your Apple Watch")
                .font(.headline)
            
            Text("Your workout will begin on your Apple Watch. Please check your watch to start your sprint training session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Send Launch Signal to Watch") {
                // In a real implementation, this would send a message to the watch
                print("Sending launch command to Apple Watch...")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        AdaptiveWorkoutHub()
    }
}
