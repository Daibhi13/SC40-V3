import SwiftUI
import WatchConnectivity
import Combine

// MARK: - Watch-Optimized Sprint Coach View
/// Streamlined version of UnifiedSprintCoachView optimized for Apple Watch
/// Syncs with phone version for seamless experience

struct WatchUnifiedSprintCoachView: View {
    // Session Configuration
    let sessionConfig: SessionConfiguration
    
    // Watch-specific state management
    @StateObject private var watchSyncManager = WatchSyncManager.shared
    @StateObject private var voiceCoach = NikeVoiceCoach()
    
    // Core Sprint Coach Elements - Synced with phone
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var currentRep = 1
    @State private var phaseTimeRemaining = 120
    
    // Watch-optimized animations
    @State private var pulseAnimation = false
    @State private var energyLevel: Double = 0.0
    
    // Rep Log Data - Synced
    @State private var repLog: [RepLogEntry] = []
    
    // GPS and Metrics - Watch optimized
    @State private var currentDistance: Double = 0.0
    @State private var currentTime: Double = 0.0
    @State private var currentSpeed: Double = 0.0
    
    // Computed properties
    private var totalReps: Int { sessionConfig.reps }
    private var sprintDistance: Int { sessionConfig.distance }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Watch-optimized session header
                    watchSessionHeader
                    
                    // Core metrics display
                    watchMetricsDisplay
                    
                    // Control buttons - Watch sized
                    watchControlButtons
                    
                    // Current phase indicator
                    watchPhaseIndicator
                    
                    // Rep log summary
                    watchRepLogSummary
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("Sprint Coach")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            setupWatchSync()
            startWatchAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .phoneWorkoutStateChanged)) { notification in
            if let phoneState = notification.object as? PhoneWorkoutState {
                syncWithPhoneState(phoneState)
            }
        }
    }
    
    // MARK: - Watch-Optimized UI Components
    
    private var watchSessionHeader: some View {
        VStack(spacing: 4) {
            Text(sessionConfig.sessionName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            HStack {
                Circle()
                    .fill(isRunning ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isRunning ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRunning)
                
                Text("REP \(currentRep)/\(totalReps)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var watchMetricsDisplay: some View {
        VStack(spacing: 8) {
            // GPS Stopwatch - Compact for watch
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", currentDistance))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("YDS")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                VStack(spacing: 2) {
                    Text(formatTime(currentTime))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("TIME")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                }
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", currentSpeed))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("MPH")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            
            // Rest Timer - Watch optimized
            if currentPhase == .resting {
                VStack(spacing: 4) {
                    Text("REST")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatCountdownDisplay(phaseTimeRemaining))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(phaseTimeRemaining < 30 ? .red : .orange)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.2))
                )
            }
        }
    }
    
    private var watchControlButtons: some View {
        HStack(spacing: 8) {
            if !isRunning {
                // Start Button
                Button(action: startWorkout) {
                    VStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("START")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 50, height: 40)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            } else {
                // Pause/Resume Button
                Button(action: togglePause) {
                    VStack(spacing: 2) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(isPaused ? "RESUME" : "PAUSE")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 45, height: 35)
                    .background(isPaused ? Color.green : Color.orange)
                    .cornerRadius(6)
                }
                
                // Skip Button
                Button(action: skipPhase) {
                    VStack(spacing: 2) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("SKIP")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 45, height: 35)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                
                // Stop Button
                Button(action: stopWorkout) {
                    VStack(spacing: 2) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("STOP")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 45, height: 35)
                    .background(Color.red)
                    .cornerRadius(6)
                }
            }
        }
    }
    
    private var watchPhaseIndicator: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(getSessionPhases(), id: \.self) { phase in
                    Circle()
                        .fill(phase == currentPhase ? Color.orange : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(phase == currentPhase ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPhase)
                }
            }
            
            Text(getCurrentPhaseName())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.orange)
                .tracking(0.5)
        }
    }
    
    private var watchRepLogSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECENT TIMES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .tracking(0.5)
            
            if repLog.isEmpty {
                Text("Times will appear here")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                VStack(spacing: 3) {
                    ForEach(repLog.suffix(3)) { entry in
                        HStack {
                            Image(systemName: entry.type.icon)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(entry.type.color)
                                .frame(width: 12)
                            
                            Text(entry.type.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            if let time = entry.time {
                                Text(String(format: "%.2fs", time))
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Watch Actions & Sync
    
    private func startWorkout() {
        isRunning = true
        currentPhase = .warmup
        energyLevel = 0.3
        
        // Sync with phone
        syncWorkoutStateWithPhone()
        
        // Voice coaching
        voiceCoach.speak("Workout started on watch! Let's get moving! 🔥")
    }
    
    private func togglePause() {
        isPaused.toggle()
        syncWorkoutStateWithPhone()
        
        if isPaused {
            voiceCoach.speak("Paused on watch. Take a breath! 💪")
        } else {
            voiceCoach.speak("Resumed from watch! Back to action! ⚡")
        }
    }
    
    private func skipPhase() {
        advanceToNextPhase()
        syncWorkoutStateWithPhone()
        voiceCoach.speak("Phase skipped from watch! Moving forward! 🚀")
    }
    
    private func stopWorkout() {
        isRunning = false
        isPaused = false
        currentPhase = .warmup
        currentRep = 1
        
        syncWorkoutStateWithPhone()
        voiceCoach.speak("Workout stopped from watch! Great effort! 🏆")
    }
    
    private func advanceToNextPhase() {
        let phases = getSessionPhases()
        if let currentIndex = phases.firstIndex(of: currentPhase),
           currentIndex < phases.count - 1 {
            currentPhase = phases[currentIndex + 1]
        } else if currentPhase == .sprints && currentRep < totalReps {
            currentPhase = .resting
            currentRep += 1
        } else if currentPhase == .resting {
            currentPhase = .sprints
        } else {
            currentPhase = .completed
            isRunning = false
        }
    }
    
    // MARK: - Watch Sync Functions
    
    private func setupWatchSync() {
        // Initialize watch connectivity
        watchSyncManager.startSession()
    }
    
    private func syncWorkoutStateWithPhone() {
        let watchState = WatchWorkoutState(
            isRunning: isRunning,
            isPaused: isPaused,
            currentPhase: currentPhase,
            currentRep: currentRep,
            phaseTimeRemaining: phaseTimeRemaining,
            currentDistance: currentDistance,
            currentTime: currentTime,
            currentSpeed: currentSpeed,
            timestamp: Date()
        )
        
        watchSyncManager.sendWorkoutState(watchState)
    }
    
    private func syncWithPhoneState(_ phoneState: PhoneWorkoutState) {
        // Update watch state based on phone changes
        DispatchQueue.main.async {
            self.isRunning = phoneState.isRunning
            self.isPaused = phoneState.isPaused
            self.currentPhase = phoneState.currentPhase
            self.currentRep = phoneState.currentRep
            self.phaseTimeRemaining = phoneState.phaseTimeRemaining
            self.currentDistance = phoneState.currentDistance
            self.currentTime = phoneState.currentTime
            self.currentSpeed = phoneState.currentSpeed
            
            // Update rep log if provided
            if let newRepLog = phoneState.repLog {
                self.repLog = newRepLog
            }
        }
    }
    
    private func startWatchAnimations() {
        pulseAnimation = true
    }
    
    // MARK: - Helper Functions
    
    private func getSessionPhases() -> [WorkoutPhase] {
        return sessionConfig.workoutVariation.phases
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
    
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.2f", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    private func formatCountdownDisplay(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Watch Sync Models
struct WatchWorkoutState {
    let isRunning: Bool
    let isPaused: Bool
    let currentPhase: WorkoutPhase
    let currentRep: Int
    let phaseTimeRemaining: Int
    let currentDistance: Double
    let currentTime: Double
    let currentSpeed: Double
    let timestamp: Date
}

struct PhoneWorkoutState {
    let isRunning: Bool
    let isPaused: Bool
    let currentPhase: WorkoutPhase
    let currentRep: Int
    let phaseTimeRemaining: Int
    let currentDistance: Double
    let currentTime: Double
    let currentSpeed: Double
    let repLog: [RepLogEntry]?
    let timestamp: Date
}

// MARK: - Watch Sync Manager  
@MainActor
class WatchSyncManager: ObservableObject {
    static let shared = WatchSyncManager()
    
    @Published var isConnected = false
    private var session: WCSession?
    
    init() {
        if WCSession.isSupported() {
            session = WCSession.default
            // Note: delegate setup would be needed for full WC functionality
        }
    }
    
    func startSession() {
        session?.activate()
    }
    
    func sendWorkoutState(_ state: WatchWorkoutState) {
        // Note: Full WatchConnectivity implementation would encode and send state
        print("📱 Would send workout state to phone: \(state.isRunning ? "Running" : "Stopped")")
    }
}

// MARK: - WCSessionDelegate (Disabled for now)
// Note: Full WatchConnectivity implementation would go here

// MARK: - Notification Extensions (Already defined in WorkoutSyncManager)

// MARK: - Preview
#Preview {
    WatchUnifiedSprintCoachView(sessionConfig: SessionConfiguration.sessions[0])
}
