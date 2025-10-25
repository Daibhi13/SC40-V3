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
                    // Main Workout View
                    mainWorkoutView
                        .tag(WorkoutViewType.main)
                    
                    // Control View (Swipe Right)
                    SimpleControlWatchView(
                        isWorkoutActive: $isWorkoutActive,
                        onBack: { currentView = .main }
                    )
                    .tag(WorkoutViewType.control)
                    
                    // Music View (Swipe Left)
                    SimpleMusicWatchView(
                        onBack: { currentView = .main }
                    )
                    .tag(WorkoutViewType.music)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Rep Log View (Swipe Up/Down) - Overlay
                if currentView == .repLog {
                    SimpleRepLogWatchView(
                        currentSet: currentSet,
                        totalSets: totalSets,
                        onBack: { currentView = .main }
                    )
                    .transition(.move(edge: .bottom))
                }
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
        }
        .onDisappear {
            stopWorkout()
        }
    }
    
    // MARK: - Main Workout View
    private var mainWorkoutView: some View {
        VStack(spacing: 12) {
            // Header
            workoutHeader
            
            // Phase Indicator
            phaseIndicator
            
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
                Text("← Music")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Control →")
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
            // Horizontal swipe - Control/Music
            if value.translation.width > threshold {
                // Swipe right - Control
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentView = .control
                }
            } else if value.translation.width < -threshold {
                // Swipe left - Music
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentView = .music
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
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
