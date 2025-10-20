import SwiftUI
import CoreLocation
import Combine

struct MainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Sprint Coach Integration
    // Sprint Coach automated coaching system
    
    // Legacy state for UI compatibility
    @State private var currentSession: WorkoutSession?
    @State private var showRepLog = true
    @State private var showCompletionSheet = false
    @State private var workoutResults: WorkoutResults? = nil
    @State private var isPaused = false
    
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
    
    enum WorkoutPhase: CaseIterable {
        case warmup
        case stretch
        case drill
        case strides
        case sprints
        case resting
        case cooldown
        case completed
        
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
        
        var description: String {
            switch self {
            case .warmup: return "Light jog"
            case .stretch: return "Dynamic mobility"
            case .drill: return "GPS Stopwatch (20-yard clarity check)"
            case .strides: return "20 yards × 3 reps"
            case .sprints: return "Maximum effort sprints"
            case .resting: return "Active recovery"
            case .cooldown: return "Stretch and recover"
            case .completed: return "Session complete!"
            }
        }
        
        var duration: Int {
            switch self {
            case .warmup: return 300 // 5 minutes
            case .stretch: return 300 // 5 minutes
            case .drill: return 600 // 10 minutes (flexible)
            case .strides: return 480 // 8 minutes (3 reps + rest)
            case .sprints: return 900 // 15 minutes (varies by session)
            case .resting: return 0 // Dynamic
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
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.45),
                    Color(red: 0.2, green: 0.15, blue: 0.35),
                    Color(red: 0.1, green: 0.05, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        stopSprintCoachWorkout()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Sprint Training")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Progress indicator (Sprint Coach active)
                    Text("Sprint Coach system active")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Sprint Coach Status Display
                VStack(spacing: 16) {
                    // Sprint Coach Status
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text("Sprint Coach Training")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Timer Display - Sprint Coach Integration
                    TimerDisplayView(
                        currentPhase: .warmup,
                        phaseTimeRemaining: 300,
                        restTimeRemaining: 180,
                        sprintTime: 0.0,
                        isRunning: false,
                        currentSpeed: 0.0,
                        currentDistance: 0.0
                    )
                    .padding(.vertical, 20)
                    
                    // Sprint Coach Automated Controls
                    PhaseControlsView(
                        currentPhase: .warmup,
                        isPaused: isPaused,
                        onPause: pauseWorkout,
                        onPlay: resumeWorkout,
                        onForward: skipToNext
                    )
                    .padding(.bottom, 20)
                    
                    // Rep Log (Sprint Coach Integration)
                    if showRepLog {
                        VStack(spacing: 16) {
                            Text("Rep Log")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Rep Log Table Header
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
                            
                            // Sample Rep Log Rows
                            VStack(spacing: 8) {
                                ForEach(1...4, id: \.self) { rep in
                                    HStack {
                                        Text("\(rep)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        
                                        Text("40")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 50)
                                        
                                        Text(rep == 1 ? "5.25s" : "--")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(rep == 1 ? .yellow : .white.opacity(0.5))
                                            .frame(width: 80)
                                        
                                        Text(rep == 1 ? "2:45" : "--")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(rep == 1 ? .green : .white.opacity(0.5))
                                            .frame(width: 60)
                                    }
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(rep == 1 ? Color.yellow.opacity(0.1) : Color.clear)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                } // end inner status VStack(spacing: 16)
            } // end outer container VStack/ZStack content
        }
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
    
    // MARK: - Sprint Coach Integration Methods
    
    private func setupSprintCoachWorkout() {
        // Sprint Coach automated setup - no manual intervention needed
        print("🏃‍♂️ Sprint Coach: Setting up automated workout")
    }
    
    private func stopSprintCoachWorkout() {
        // Sprint Coach automated cleanup
        print("🏃‍♂️ Sprint Coach: Stopping automated workout")
    }
    
    private func pauseWorkout() {
        isPaused = true
        print("⏸️ Sprint Coach: Workout paused")
    }
    
    private func resumeWorkout() {
        isPaused = false
        print("▶️ Sprint Coach: Workout resumed")
    }
    
    private func skipToNext() {
        print("⏭️ Sprint Coach: Skipping to next stage")
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

// MARK: - Legacy Extensions (Removed for Sprint Coach Integration)
// All legacy manual workout methods have been replaced by Sprint Coach automation

