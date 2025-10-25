import SwiftUI

struct SprintTimerProWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    
    let distance: Int
    let sets: Int
    let restMinutes: Int
    
    @State private var currentView: WorkoutViewType = .main
    @State private var currentSet = 1
    @State private var isWorkoutActive = false
    @State private var workoutTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    
    enum WorkoutViewType {
        case main, control, music, repLog
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
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
                        totalSets: sets,
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
        VStack(spacing: 16) {
            // Header
            workoutHeader
            
            // Current Set Display
            currentSetDisplay
            
            // Timer Display
            timerDisplay
            
            // Sprint Details
            sprintDetails
            
            // Progress Indicator
            progressIndicator
            
            // Swipe Instructions
            swipeInstructions
        }
        .padding(16)
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 4) {
            Text("Sprint Timer Pro")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("Custom Workout")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var currentSetDisplay: some View {
        VStack(spacing: 8) {
            Text("SET")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(currentSet)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                
                Text("/ \(sets)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 4)
            }
        }
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text(formatTime(elapsedTime))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.green)
                .monospacedDigit()
            
            Text("ELAPSED TIME")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
        }
    }
    
    private var sprintDetails: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DISTANCE")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(distance) YD")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("REST")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(restMinutes) MIN")
                        .font(.system(size: 14, weight: .bold))
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
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            Text("PROGRESS")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
            
            ProgressView(value: Double(currentSet), total: Double(sets))
                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                .scaleEffect(y: 2)
            
            Text("\(Int((Double(currentSet) / Double(sets)) * 100))% Complete")
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

#Preview("Sprint Timer Pro Workout") {
    SprintTimerProWorkoutView(
        distance: 40,
        sets: 5,
        restMinutes: 2
    )
    .preferredColorScheme(.dark)
}
