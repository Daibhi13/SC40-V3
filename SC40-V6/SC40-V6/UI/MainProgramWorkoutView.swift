import SwiftUI
import CoreLocation

struct MainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentSession: TrainingSession?
    @State private var currentPhase: WorkoutPhase = .warmup
    @State private var currentRep = 1
    @State private var phaseTimeRemaining: Int = 300 // 5 minutes warmup
    @State private var restTimeRemaining: Int = 0
    @State private var sprintTime: Double = 0.0
    @State private var currentSpeed: Double = 0.0
    @State private var currentDistance: Double = 0.0
    @State private var isRunning = false
    @State private var sprintTimes: [Double] = []
    @State private var strideTimes: [Double] = []
    @State private var showRepLog = false
    @State private var workoutTimer: Timer?
    @State private var phaseTimer: Timer?
    @State private var showCompletionSheet = false
    
    enum WorkoutPhase {
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
            case .warmup: return "Warm Up"
            case .stretch: return "Dynamic Stretch"
            case .drill: return "Sprint Drills"
            case .strides: return "Build-Up Strides"
            case .sprints: return "SPRINT!"
            case .resting: return "Rest & Recover"
            case .cooldown: return "Cool Down"
            case .completed: return "Workout Complete"
            }
        }
        
        var subtitle: String {
            switch self {
            case .warmup: return "Prepare your body"
            case .stretch: return "Dynamic mobility • 5-8 minutes"
            case .drill: return "A-skips • High knees • Butt kicks"
            case .strides: return "3×20 Yard • 70% Effort • Auto-detected"
            case .sprints: return "Maximum effort"
            case .resting: return "Active recovery"
            case .cooldown: return "Stretch and recover"
            case .completed: return "Great work!"
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
                        
                        if let session = currentSession {
                            Text("WEEK \(session.week) - DAY \(session.day) / \(getTotalWorkoutTime()) Min")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("WEEK 1 - DAY 1 / 47 Min")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Phase Progress Bar
                    WorkoutProgressBar(
                        currentPhase: currentPhase,
                        warmupTime: 5,
                        sprintTime: getSprintPhaseTime(),
                        cooldownTime: 5
                    )
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
                                
                                Image(systemName: currentPhase.icon)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(currentPhase.color)
                            }
                            
                            VStack(spacing: 4) {
                                Text(currentPhase.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if currentPhase == .sprints && currentSession != nil {
                                    Text("Rep \(currentRep) of \(getTotalReps())")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else if currentPhase == .strides {
                                    Text(currentPhase.subtitle)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
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
                                } else if currentPhase == .sprints || currentPhase == .strides {
                                    Text(String(format: "%.2f", sprintTime))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(isRunning ? "GO!" : "READY")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    Text(formatTime(phaseTimeRemaining))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Go!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        
                        // Speed and Distance (during sprints and strides)
                        if currentPhase == .sprints || currentPhase == .strides {
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
                                handleMainAction()
                            }) {
                                Image(systemName: getMainActionIcon())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Rep Log Section (Scrollable within main scroll)
                        MainProgramRepLogSheet(
                            sprintTimes: sprintTimes,
                            strideTimes: strideTimes,
                            currentRep: currentRep,
                            currentPhase: currentPhase,
                            session: currentSession,
                            showRepLog: .constant(true)
                        )
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            setupWorkout()
            showRepLog = true
        }
        .onDisappear {
            stopWorkout()
        }
        .sheet(isPresented: $showCompletionSheet) {
            WorkoutCompletionSheet(
                session: currentSession,
                sprintTimes: sprintTimes,
                strideTimes: strideTimes,
                onDismiss: {
                    showCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Workout Setup and Control
    
    private func setupWorkout() {
        // Create a default session for the workout
        currentSession = TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Sprint Training",
            focus: "Speed Development",
            sprints: [SprintSet(distanceYards: 30, reps: 4, intensity: "100%")],
            accessoryWork: [],
            notes: nil
        )
        startWarmup()
    }
    
    private func startWarmup() {
        currentPhase = .warmup
        phaseTimeRemaining = 300 // 5 minutes
        startPhaseTimer()
    }
    
    private func startPhaseTimer() {
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if phaseTimeRemaining > 0 {
                    phaseTimeRemaining -= 1
                } else {
                    nextPhase()
                }
            }
        }
    }
    
    private func nextPhase() {
        phaseTimer?.invalidate()
        
        switch currentPhase {
        case .warmup:
            currentPhase = .stretch
            phaseTimeRemaining = 420 // 7 minutes for dynamic stretching
            startPhaseTimer()
        case .stretch:
            currentPhase = .drill
            phaseTimeRemaining = 600 // 10 minutes for sprint drills
            startPhaseTimer()
        case .drill:
            currentPhase = .strides
            currentRep = 1
        case .strides:
            if currentRep >= 3 {
                currentPhase = .sprints
                currentRep = 1
            }
        case .sprints:
            if currentRep >= getTotalReps() {
                currentPhase = .cooldown
                phaseTimeRemaining = 300 // 5 minutes
                startPhaseTimer()
            }
        case .resting:
            currentRep += 1
            currentPhase = currentRep <= getTotalReps() ? .sprints : .cooldown
            if currentPhase == .cooldown {
                phaseTimeRemaining = 300
                startPhaseTimer()
            }
        case .cooldown:
            completeWorkout()
        case .completed:
            break
        }
    }
    
    private func handleMainAction() {
        switch currentPhase {
        case .warmup, .stretch, .drill, .cooldown:
            skipPhase() // Allow user to skip ahead if desired
        case .strides, .sprints:
            // Fully automated phases with voice cues and haptics
            // No manual intervention - user listens through earbuds/watch
            // Olympic-style automated coaching
            break
        case .resting:
            skipRest() // Allow user to skip rest if ready
        case .completed:
            break
        }
    }
    
    private func startSprint() {
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
        
        if currentPhase == .strides {
            strideTimes.append(sprintTime)
        } else {
            sprintTimes.append(sprintTime)
        }
        
        HapticManager.shared.success()
        
        if currentPhase == .sprints && currentRep < getTotalReps() {
            startRest()
        } else {
            nextPhase()
        }
    }
    
    private func startRest() {
        currentPhase = .resting
        restTimeRemaining = getRestTime()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if restTimeRemaining > 0 {
                    restTimeRemaining -= 1
                } else {
                    nextPhase()
                }
            }
        }
    }
    
    private func skipRest() {
        phaseTimer?.invalidate()
        nextPhase()
    }
    
    private func skipPhase() {
        phaseTimer?.invalidate()
        nextPhase()
    }
    
    private func pauseWorkout() {
        workoutTimer?.invalidate()
        phaseTimer?.invalidate()
        isRunning = false
        HapticManager.shared.light()
    }
    
    private func stopWorkout() {
        workoutTimer?.invalidate()
        phaseTimer?.invalidate()
        isRunning = false
    }
    
    private func completeWorkout() {
        currentPhase = .completed
        HapticManager.shared.success()
        
        // Save completed session with results
        if let session = currentSession {
            // Session completion logic (simplified for now)
            print("Session completed: \(session.type)")
            
            // Update personal best if applicable
            if let bestTime = sprintTimes.min() {
                print("Best time: \(String(format: "%.2f", bestTime))s")
            }
        }
        
        // Show completion sheet with navigation options
        showCompletionSheet = true
    }
    
    // MARK: - Helper Methods
    
    private func getTotalReps() -> Int {
        return currentSession?.sprints.first?.reps ?? 4
    }
    
    private func getRestTime() -> Int {
        // Use session data or fallback to default
        if let session = currentSession,
           let sprintSet = session.sprints.first {
            // Estimate rest time based on distance and intensity
            let distance = sprintSet.distanceYards
            if distance >= 60 {
                return 300 // 5 minutes for longer sprints
            } else if distance >= 40 {
                return 240 // 4 minutes for medium sprints
            } else {
                return 180 // 3 minutes for short sprints
            }
        }
        return 180 // Default 3 minutes
    }
    
    private func getTotalWorkoutTime() -> Int {
        // Calculate based on session structure
        if currentSession != nil {
            let warmup = 5 // 5 minutes
            let cooldown = 5 // 5 minutes
            let reps = getTotalReps()
            let restMinutes = getRestTime() / 60
            let sprintPhase = (reps * 2) + ((reps - 1) * restMinutes) // Estimate
            let strides = 10 // 10 minutes for strides
            return warmup + strides + sprintPhase + cooldown
        }
        return 47 // Default workout time
    }
    
    private func getSprintPhaseTime() -> Int {
        let reps = getTotalReps()
        let restMinutes = getRestTime() / 60
        return (reps * 2) + ((reps - 1) * restMinutes) // Estimate: 2 min per rep + rest
    }
    
    private func getMainActionIcon() -> String {
        switch currentPhase {
        case .warmup, .stretch, .drill, .cooldown:
            return "forward.fill" // Skip button available
        case .strides, .sprints:
            return "speaker.wave.3.fill" // Voice-guided automatic phase
        case .resting:
            return "forward.fill" // Skip rest button
        case .completed:
            return "checkmark.fill"
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Workout Progress Bar

struct WorkoutProgressBar: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let warmupTime: Int
    let sprintTime: Int
    let cooldownTime: Int
    
    var body: some View {
        HStack(spacing: 4) {
            // Warmup
            RoundedRectangle(cornerRadius: 2)
                .fill(getPhaseColor(.warmup))
                .frame(height: 4)
                .frame(width: CGFloat(warmupTime * 8)) // Scale factor
            
            // Sprint Phase
            RoundedRectangle(cornerRadius: 2)
                .fill(getPhaseColor(.sprints))
                .frame(height: 4)
                .frame(width: CGFloat(sprintTime * 8))
            
            // Cooldown
            RoundedRectangle(cornerRadius: 2)
                .fill(getPhaseColor(.cooldown))
                .frame(height: 4)
                .frame(width: CGFloat(cooldownTime * 8))
        }
    }
    
    private func getPhaseColor(_ phase: MainProgramWorkoutView.WorkoutPhase) -> Color {
        switch (currentPhase, phase) {
        case (.warmup, .warmup), (.strides, .sprints), (.sprints, .sprints), (.resting, .sprints):
            return phase.color
        case (.cooldown, .cooldown), (.completed, _):
            return phase.color
        default:
            return Color.white.opacity(0.3)
        }
    }
}

// MARK: - Main Program Rep Log Sheet

struct MainProgramRepLogSheet: View {
    let sprintTimes: [Double]
    let strideTimes: [Double]
    let currentRep: Int
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let session: TrainingSession?
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
            
            ScrollView {
                VStack(spacing: 0) {
                    // Strides Section
                    if !strideTimes.isEmpty || currentPhase == .strides {
                        VStack(spacing: 0) {
                            HStack {
                                Text("STRIDES")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.purple)
                                
                                Spacer()
                                
                                Text("Build-up • 70% effort")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.purple.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            
                            ForEach(1...3, id: \.self) { rep in
                                RepLogRow(
                                    rep: rep,
                                    distance: 20,
                                    time: rep <= strideTimes.count ? strideTimes[rep - 1] : nil,
                                    isActive: currentPhase == .strides && rep == currentRep,
                                    color: Color.purple
                                )
                            }
                        }
                    }
                    
                    // Sprints Section
                    if currentPhase == .sprints || currentPhase == .resting || !sprintTimes.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text("SPRINTS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.green)
                                
                                Spacer()
                                
                                Text("Maximum effort • 100%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.green.opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            
                            let totalReps = session?.sprints.first?.reps ?? 4
                            let distance = session?.sprints.first?.distanceYards ?? 30
                            
                            ForEach(1...totalReps, id: \.self) { rep in
                                RepLogRow(
                                    rep: rep,
                                    distance: distance,
                                    time: rep <= sprintTimes.count ? sprintTimes[rep - 1] : nil,
                                    isActive: (currentPhase == .sprints || currentPhase == .resting) && rep == currentRep,
                                    color: Color.green
                                )
                            }
                        }
                    }
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

// MARK: - Rep Log Row

struct RepLogRow: View {
    let rep: Int
    let distance: Int
    let time: Double?
    let isActive: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Text("\(rep)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
            
            Text("\(distance)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .center)
            
            if let time = time {
                Text(String(format: "%.2f", time))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if isActive {
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
            isActive ?
            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.1) :
            Color.clear
        )
    }
}

// MARK: - Preview

// MARK: - Workout Completion Sheet

struct WorkoutCompletionSheet: View {
    let session: TrainingSession?
    let sprintTimes: [Double]
    let strideTimes: [Double]
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
                                Text("Workout Complete!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if let session = session {
                                    Text("Week \(session.week), Day \(session.day)")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
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
                                    // This would trigger navigation to History in parent view
                                }
                                
                                NavigationActionCard(
                                    title: "Advanced Analytics",
                                    subtitle: "Detailed performance insights",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: Color.orange
                                ) {
                                    // Navigate to Advanced Analytics
                                    onDismiss()
                                    // This would trigger navigation to Analytics in parent view
                                }
                                
                                NavigationActionCard(
                                    title: "Share Performance",
                                    subtitle: "Share your results with teammates",
                                    icon: "square.and.arrow.up",
                                    color: Color.cyan
                                ) {
                                    // Navigate to Share Performance
                                    onDismiss()
                                    // This would trigger sharing functionality
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

// MARK: - Preview

struct MainProgramWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        MainProgramWorkoutView()
    }
}
