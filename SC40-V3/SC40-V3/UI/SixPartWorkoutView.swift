import SwiftUI
import Foundation

struct SixPartWorkoutView: View {
    let session: Any // Will be TrainingSession when dependencies are resolved
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var isRunning = false
    @State private var currentRep = 1
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showCompletionSheet = false
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warm-Up"
        case stretch = "Stretch"
        case drills = "Drills"
        case strides = "Strides"
        case sprints = "Sprints"
        case cooldown = "Cool Down"
        
        var icon: String {
            switch self {
            case .warmup: return "thermometer.medium"
            case .stretch: return "figure.flexibility"
            case .drills: return "figure.walk"
            case .strides: return "figure.run.circle"
            case .sprints: return "bolt.fill"
            case .cooldown: return "snowflake"
            }
        }
        
        var color: Color {
            switch self {
            case .warmup: return .orange
            case .stretch: return .green
            case .drills: return .purple
            case .strides: return .blue
            case .sprints: return .red
            case .cooldown: return .cyan
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .warmup: return 300 // 5 minutes
            case .stretch: return 480 // 8 minutes
            case .drills: return 600 // 10 minutes
            case .strides: return 600 // 10 minutes
            case .sprints: return 1200 // 20 minutes
            case .cooldown: return 480 // 8 minutes
            }
        }
        
        var description: String {
            switch self {
            case .warmup: return "Light jogging and dynamic movements to prepare your body"
            case .stretch: return "Dynamic stretching to improve mobility and prevent injury"
            case .drills: return "Technical drills to improve sprint mechanics"
            case .strides: return "Gradual acceleration runs to prepare for sprints"
            case .sprints: return "High-intensity sprint intervals"
            case .cooldown: return "Easy jogging and static stretching to recover"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("W1/D1") // Will use session.week/session.day when dependencies resolved
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sprint Training") // Will use session.type when dependencies resolved
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 20)
                
                // Phase Progress
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WorkoutPhase.allCases, id: \.self) { phase in
                            SixPartPhaseProgressView(
                                phase: phase,
                                isCurrent: phase == currentPhase,
                                isCompleted: isPhaseCompleted(phase)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Current Phase Display
                VStack(spacing: 16) {
                    // Phase Icon and Name
                    VStack(spacing: 12) {
                        Image(systemName: currentPhase.icon)
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(currentPhase.color)
                        
                        Text(currentPhase.rawValue)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(currentPhase.description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Timer Display
                    VStack(spacing: 8) {
                        Text(timeString(from: elapsedTime))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("/ \(timeString(from: currentPhase.duration))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Progress Bar
                    ProgressView(value: elapsedTime, total: currentPhase.duration)
                        .progressViewStyle(LinearProgressViewStyle(tint: currentPhase.color))
                        .scaleEffect(y: 3)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // Control Buttons
                VStack(spacing: 16) {
                    // Main Action Button
                    Button(action: {
                        if isRunning {
                            pauseWorkout()
                        } else {
                            startWorkout()
                        }
                    }) {
                        HStack {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text(isRunning ? "Pause" : "Start")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    
                    // Secondary Actions
                    HStack(spacing: 16) {
                        Button(action: nextPhase) {
                            HStack {
                                Image(systemName: "forward.fill")
                                Text("Next Phase")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showCompletionSheet = true }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Complete")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.green.opacity(0.6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        #endif
        .sheet(isPresented: $showCompletionSheet) {
            SimpleCompletionView {
                dismiss()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Helper Functions
    
    private func startWorkout() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
            
            // Auto-advance to next phase when current phase is complete
            if elapsedTime >= currentPhase.duration {
                nextPhase()
            }
        }
    }
    
    private func pauseWorkout() {
        isRunning = false
        timer?.invalidate()
    }
    
    private func nextPhase() {
        timer?.invalidate()
        
        let phases = WorkoutPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase) else { return }
        
        if currentIndex < phases.count - 1 {
            currentPhase = phases[currentIndex + 1]
            elapsedTime = 0
            isRunning = false
            
            // Haptic feedback
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        } else {
            // Workout complete
            showCompletionSheet = true
        }
    }
    
    private func isPhaseCompleted(_ phase: WorkoutPhase) -> Bool {
        let phases = WorkoutPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else { return false }
        return phaseIndex < currentIndex
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Six Part Phase Progress View
struct SixPartPhaseProgressView: View {
    let phase: SixPartWorkoutView.WorkoutPhase
    let isCurrent: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: phase.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            Text(phase.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textColor)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return phase.color
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        if isCompleted || isCurrent {
            return .white
        } else {
            return .white.opacity(0.6)
        }
    }
    
    private var textColor: Color {
        if isCurrent {
            return .white
        } else {
            return .white.opacity(0.7)
        }
    }
}


// MARK: - Simple Completion View
struct SimpleCompletionView: View {
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.green, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        Text("Workout Complete!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Great job completing your workout!")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: onComplete) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                    .foregroundColor(.white)
                }
            }
            #endif
        }
    }
}

// Note: Using existing TrainingSession from SprintSetAndTrainingSession.swift

#Preview {
    // Preview with simple mock session
    SixPartWorkoutView(session: "Mock Session")
}
