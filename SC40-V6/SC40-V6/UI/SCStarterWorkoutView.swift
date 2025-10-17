import SwiftUI
import CoreLocation

struct SCStarterWorkoutView: View {
    let distance: Int
    let reps: Int
    let restMinutes: Int
    
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPhase: WorkoutPhase = .ready
    @State private var currentRep = 1
    @State private var sprintTime: Double = 0.0
    @State private var restTimeRemaining: Int = 0
    @State private var currentSpeed: Double = 0.0
    @State private var currentDistance: Double = 0.0
    @State private var isRunning = false
    @State private var sprintTimes: [Double] = []
    @State private var showRepLog = false
    @State private var workoutTimer: Timer?
    @State private var restTimer: Timer?
    @State private var showCompletionSheet = false
    
    enum WorkoutPhase {
        case ready
        case sprinting
        case resting
        case completed
        
        var title: String {
            switch self {
            case .ready: return "SPRINT!"
            case .sprinting: return "SPRINT!"
            case .resting: return "Rest & Recover"
            case .completed: return "Workout Complete"
            }
        }
        
        var color: Color {
            switch self {
            case .ready: return Color.green
            case .sprinting: return Color.green
            case .resting: return Color.yellow
            case .completed: return Color.blue
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                    .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                    .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                    .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                    .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            stopWorkout()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    // Workout Header
                    VStack(spacing: 8) {
                        Text("SPRINT COACH 40")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(2)
                        
                        Text("SC STARTER / \(distance)YD")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Progress Bar
                    HStack(spacing: 4) {
                        ForEach(1...reps, id: \.self) { rep in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(rep <= currentRep ? currentPhase.color : Color.white.opacity(0.3))
                                .frame(height: 4)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Main Content Area
                    VStack(spacing: 40) {
                        // Phase Icon and Title
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(currentPhase.color.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: currentPhase == .resting ? "pause.fill" : "bolt.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(currentPhase.color)
                            }
                            
                            VStack(spacing: 4) {
                                Text(currentPhase.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if currentPhase != .completed {
                                    Text("Rep \(currentRep) of \(reps)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        // Main Timer Circle
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .stroke(currentPhase.color, lineWidth: 8)
                                .frame(width: 200, height: 200)
                                .opacity(isRunning ? 1.0 : 0.5)
                            
                            VStack(spacing: 8) {
                                if currentPhase == .resting {
                                    Text(formatTime(restTimeRemaining))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Rest")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    Text(String(format: "%.2f", sprintTime))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(currentPhase == .ready ? "READY" : "GO!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        
                        // Speed and Distance (only during sprinting)
                        if currentPhase == .sprinting || currentPhase == .ready {
                            HStack(spacing: 40) {
                                VStack(spacing: 4) {
                                    Text("SPEED")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text(String(format: "%.1f", currentSpeed))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("mph")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                VStack(spacing: 4) {
                                    Text("DISTANCE")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text(String(format: "%.0f", currentDistance))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("yards")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                            )
                        }
                        
                        // Control Buttons
                        HStack(spacing: 40) {
                            Button(action: {
                                pauseWorkout()
                            }) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                if currentPhase == .ready {
                                    // Sprint phases are fully automated with voice cues and haptics
                                    // Olympic-style coaching through earbuds/watch
                                } else if currentPhase == .sprinting {
                                    // Sprinting is voice-guided and automatic - no manual control
                                } else if currentPhase == .resting {
                                    skipRest() // Allow user to skip rest if ready
                                }
                            }) {
                                Image(systemName: {
                                    switch currentPhase {
                                    case .ready, .sprinting:
                                        return "speaker.wave.3.fill" // Voice-guided automatic coaching
                                    case .resting:
                                        return "forward.fill" // Skip rest button
                                    case .completed:
                                        return "checkmark.fill"
                                    }
                                }())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Rep Log Section (Scrollable within main scroll)
                        RepLogSheet(
                            sprintTimes: sprintTimes,
                            currentRep: currentRep,
                            totalReps: reps,
                            distance: distance,
                            showRepLog: .constant(true)
                        )
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            showRepLog = true
        }
        .onDisappear {
            stopWorkout()
        }
        .sheet(isPresented: $showCompletionSheet) {
            SCStarterCompletionSheet(
                distance: distance,
                reps: reps,
                sprintTimes: sprintTimes,
                onDismiss: {
                    showCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Workout Control Methods
    
    private func startSprint() {
        currentPhase = .sprinting
        isRunning = true
        sprintTime = 0.0
        currentDistance = 0.0
        
        HapticManager.shared.heavy()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            Task { @MainActor in
                sprintTime += 0.01
                
                // Simulate GPS data (in real app, use actual GPS)
                currentSpeed = Double.random(in: 12.0...18.0) // mph
                currentDistance = sprintTime * (currentSpeed * 1.467) * 1.09361 // Convert to yards
            }
        }
    }
    
    private func stopSprint() {
        workoutTimer?.invalidate()
        isRunning = false
        
        sprintTimes.append(sprintTime)
        
        HapticManager.shared.success()
        
        if currentRep < reps {
            startRest()
        } else {
            completeWorkout()
        }
    }
    
    private func startRest() {
        currentPhase = .resting
        restTimeRemaining = restMinutes * 60
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    nextRep()
                }
            }
        }
    }
    
    private func skipRest() {
        restTimer?.invalidate()
        nextRep()
    }
    
    private func nextRep() {
        restTimer?.invalidate()
        currentRep += 1
        currentPhase = .ready
        sprintTime = 0.0
        currentSpeed = 0.0
        currentDistance = 0.0
    }
    
    private func pauseWorkout() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        isRunning = false
        HapticManager.shared.light()
    }
    
    private func stopWorkout() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        isRunning = false
    }
    
    private func completeWorkout() {
        currentPhase = .completed
        HapticManager.shared.success()
        
        // Show completion sheet with navigation options
        showCompletionSheet = true
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Rep Log Sheet

struct RepLogSheet: View {
    let sprintTimes: [Double]
    let currentRep: Int
    let totalReps: Int
    let distance: Int
    @Binding var showRepLog: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rep Log")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Live Workout Report")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("18:11")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Table Header
            HStack {
                Text("REP")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 40, alignment: .leading)
                
                Text("YDS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 50, alignment: .center)
                
                Text("TIME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("REST")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Sprint Rows
            VStack(spacing: 0) {
                Text("SPRINTS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                Text("Maximum effort • 100%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.green.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                ForEach(1...totalReps, id: \.self) { rep in
                    HStack {
                        Text("\(rep)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("\(distance)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, alignment: .center)
                        
                        if rep <= sprintTimes.count {
                            Text(String(format: "%.2f", sprintTimes[rep - 1]))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if rep == currentRep {
                            Text("•••")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("—")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        Text("—")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        rep == currentRep ?
                        Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.1) :
                        Color.clear
                    )
                }
            }
            
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

// MARK: - SC Starter Completion Sheet

struct SCStarterCompletionSheet: View {
    let distance: Int
    let reps: Int
    let sprintTimes: [Double]
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
    var bestTime: Double? {
        sprintTimes.min()
    }
    
    var averageTime: Double? {
        guard !sprintTimes.isEmpty else { return nil }
        return sprintTimes.reduce(0, +) / Double(sprintTimes.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Success Header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: showContent)
                            
                            VStack(spacing: 8) {
                                Text("SC Starter Complete!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("\(reps) × \(distance)yd Sprints")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
                        }
                        .padding(.top, 40)
                        
                        // Performance Summary
                        if let bestTime = bestTime, let averageTime = averageTime {
                            VStack(spacing: 20) {
                                Text("Performance Summary")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 20) {
                                    PerformanceCard(
                                        title: "Best Time",
                                        value: String(format: "%.2fs", bestTime),
                                        icon: "trophy.fill",
                                        color: Color(red: 1.0, green: 0.8, blue: 0.0)
                                    )
                                    
                                    PerformanceCard(
                                        title: "Average",
                                        value: String(format: "%.2fs", averageTime),
                                        icon: "chart.bar.fill",
                                        color: Color.blue
                                    )
                                }
                                
                                PerformanceCard(
                                    title: "Total Sprints",
                                    value: "\(sprintTimes.count)",
                                    icon: "bolt.fill",
                                    color: Color.green
                                )
                            }
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.7), value: showContent)
                        }
                        
                        // Navigation Options
                        VStack(spacing: 16) {
                            Text("What's Next?")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                NavigationActionCard(
                                    title: "View History",
                                    subtitle: "See all your training sessions",
                                    icon: "clock.arrow.circlepath",
                                    color: Color.purple
                                ) {
                                    // Navigate to History
                                    onDismiss()
                                }
                                
                                NavigationActionCard(
                                    title: "Advanced Analytics",
                                    subtitle: "Detailed performance insights",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: Color.orange
                                ) {
                                    // Navigate to Advanced Analytics
                                    onDismiss()
                                }
                                
                                NavigationActionCard(
                                    title: "Share Performance",
                                    subtitle: "Share your results with teammates",
                                    icon: "square.and.arrow.up",
                                    color: Color.cyan
                                ) {
                                    // Navigate to Share Performance
                                    onDismiss()
                                }
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.9), value: showContent)
                        
                        // Done Button
                        Button(action: onDismiss) {
                            HStack(spacing: 12) {
                                Text("Done")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.8, blue: 0.0),
                                        Color(red: 1.0, green: 0.6, blue: 0.0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(1.1), value: showContent)
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            showContent = true
        }
    }
}

// MARK: - Preview

struct SCStarterWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        SCStarterWorkoutView(distance: 40, reps: 4, restMinutes: 3)
    }
}
