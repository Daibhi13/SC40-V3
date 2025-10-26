import SwiftUI
import WatchKit
import AVFoundation

struct SprintTimerProWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    
    let distance: Int
    let sets: Int
    let restMinutes: Int
    
    enum WorkoutViewType {
        case main, control, music, repLog
    }
    
    @State private var currentView: WorkoutViewType = .main
    @State private var currentSet = 1
    @State private var isWorkoutActive = false
    @State private var workoutTimer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var restTimer: Timer?
    @State private var restTimeRemaining: TimeInterval = 0
    @State private var isResting = false
    @State private var showSprintView = false
    @State private var heartRate = 0
    @State private var lastSprintTime: TimeInterval = 0
    @State private var avgSprintTime: TimeInterval = 0
    @State private var sprintTimes: [TimeInterval] = []
    
    private let speechSynth = AVSpeechSynthesizer()
    private let colorTheme: ColorTheme = .apple
    
    // WorkoutWatchViewModel for RepLogWatchLiveView
    @StateObject private var sprintWorkoutVM = WorkoutWatchViewModel()
    
    // Sync manager for phone communication
    @StateObject private var syncManager = WatchWorkoutSyncManager.shared
    
    // Data manager for workout persistence
    @StateObject private var dataManager = WorkoutDataManager.shared
    
    // MARK: - Autonomous Workout Systems
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @StateObject private var gpsManager = WatchGPSManager.shared
    @StateObject private var intervalManager = WatchIntervalManager.shared
    @StateObject private var dataStore = WatchDataStore.shared
    @State private var workoutData: WatchWorkoutData?
    
    // MARK: - Premium Entertainment Systems (Watch Compatible)
    @StateObject private var hapticsManager = AdvancedHapticsManager.shared
    @StateObject private var eventBus = WorkoutEventBus.shared
    
    // Note: PremiumVoiceCoach, WorkoutMusicManager, and SubscriptionManager 
    // are iOS-only and not available in Watch target
    
    var body: some View {
        ZStack {
            // Match phone app gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.3, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content with swipe navigation
            TabView(selection: $currentView) {
                // Control View (Left swipe from Main)
                SprintControlWatchView(
                    isWorkoutActive: $isWorkoutActive,
                    currentSet: currentSet,
                    totalSets: sets,
                    currentTime: formatTime(elapsedTime),
                    totalTime: formatTime(Double(sets * restMinutes * 60 + sets * 30)), // Estimated total
                    onStartStop: toggleWorkout,
                    onNextSet: nextSet,
                    onEndWorkout: endWorkout
                )
                .tag(WorkoutViewType.control)
                
                // Main Workout View (Center)
                mainTabContent
                    .tag(WorkoutViewType.main)
                
                // Music View (Right swipe from Main) - Watch Compatible
                MusicWatchView(
                    selectedIndex: 2,
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Sprint Timer Pro",
                        focus: "Speed",
                        sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
                        accessoryWork: []
                    )
                )
                .tag(WorkoutViewType.music)
                
                // Rep Log View (Swipe Up/Down from Main)
                RepLogWatchLiveView(
                    workoutVM: sprintWorkoutVM,
                    horizontalTab: .constant(0),
                    isModal: false,
                    showNext: false,
                    onDone: { currentView = .main },
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Sprint Timer Pro",
                        focus: "Custom Sprint Training",
                        sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
                        accessoryWork: []
                    )
                )
                .tag(WorkoutViewType.repLog)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Sprint Detail View (Swipe Up) - Overlay
            if showSprintView {
                SprintDetailWatchView(
                    distance: distance,
                    currentTime: elapsedTime,
                    onDismiss: { showSprintView = false }
                )
                .transition(.move(edge: .top))
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
            setupWorkout()
            setupSyncListeners()
            syncWorkoutStateToPhone()
            
            // Start autonomous systems
            startAutonomousWorkout()
        }
        .onDisappear {
            stopWorkout()
            
            // End autonomous systems
            endAutonomousWorkout()
        }
    }
    
    // MARK: - Main Tab Content (Following MainWorkoutWatchView Pattern)
    private var mainTabContent: some View {
        VStack(spacing: 6) {
            topStatsRow
            Divider().background(Color.gray.opacity(0.4))
            mainModule
            Divider().background(Color.gray.opacity(0.4))
            bottomStatsRow
            
            // Swipe Instructions
            swipeInstructions
        }
        .padding(.horizontal, 6)
    }
    
    // MARK: - Top Stats Row (Enhanced with Autonomous Systems)
    private var topStatsRow: some View {
        HStack(spacing: 6) {
            StatModuleView(
                icon: "heart.fill",
                label: "BPM",
                value: "\(workoutManager.currentHeartRate > 0 ? workoutManager.currentHeartRate : heartRate)",
                color: workoutManager.isWorkoutActive ? .red : .gray,
                theme: colorTheme
            )
            StatModuleView(
                icon: "location.fill",
                label: "Speed",
                value: String(format: "%.1f", gpsManager.currentSpeed),
                color: gpsManager.isTracking ? .green : .gray,
                theme: colorTheme
            )
            StatModuleView(
                icon: "timer",
                label: "Phase",
                value: intervalManager.currentPhase.rawValue.prefix(4).uppercased(),
                color: intervalManager.isActive ? .blue : .gray,
                theme: colorTheme
            )
            StatModuleView(
                icon: "repeat",
                label: "Set",
                value: "\(intervalManager.currentInterval > 0 ? intervalManager.currentInterval : currentSet)/\(sets)",
                color: .accentColor,
                theme: colorTheme
            )
        }
    }
    
    // MARK: - Main Module
    private var mainModule: some View {
        VStack(spacing: 4) {
            if isResting {
                // Rest Timer Display
                VStack(spacing: 8) {
                    Text("REST")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text(formatTime(restTimeRemaining))
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    ProgressView(value: 1.0 - (restTimeRemaining / Double(restMinutes * 60)))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2)
                }
            } else {
                // Sprint Timer Display
                VStack(spacing: 8) {
                    Text(isWorkoutActive ? "SPRINT" : "READY")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isWorkoutActive ? .green : .yellow)
                    
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isResting {
                toggleWorkout()
            }
        }
    }
    
    // MARK: - Bottom Stats Row
    private var bottomStatsRow: some View {
        HStack(spacing: 6) {
            // Rest Timer Module
            RestTimerModuleView(
                restTime: formatTime(restTimeRemaining),
                progress: isResting ? (1.0 - (restTimeRemaining / Double(restMinutes * 60))) : 0.0,
                theme: colorTheme
            )
            
            // Sprint Times Module
            SprintTimesModuleView(
                avg: formatTime(avgSprintTime),
                last: formatTime(lastSprintTime),
                theme: colorTheme
            )
        }
    }
    
    // MARK: - Swipe Instructions
    private var swipeInstructions: some View {
        VStack(spacing: 4) {
            HStack(spacing: 16) {
                Text("← Control")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Music →")
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
            // Horizontal swipe - Navigation between views
            if value.translation.width > threshold {
                // Swipe right - Music
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .music
                    } else if currentView == .control {
                        currentView = .main
                    }
                }
            } else if value.translation.width < -threshold {
                // Swipe left - Control
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentView == .main {
                        currentView = .control
                    } else if currentView == .music {
                        currentView = .main
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Control Functions
    private func setupWorkout() {
        heartRate = Int.random(in: 60...80) // Mock heart rate
        restTimeRemaining = Double(restMinutes * 60)
        
        // Debug logging
        print("🏃‍♂️ SprintTimer Setup - Distance: \(distance)yd, Sets: \(sets), Rest: \(restMinutes)min")
        
        // Configure WorkoutWatchViewModel for RepLogWatchLiveView
        sprintWorkoutVM.totalReps = sets
        sprintWorkoutVM.currentRep = currentSet
        sprintWorkoutVM.restTime = Double(restMinutes * 60)
        sprintWorkoutVM.repDistances = Array(repeating: distance, count: sets)
        
        print("🏃‍♂️ SprintTimer VM configured - TotalReps: \(sprintWorkoutVM.totalReps), RestTime: \(sprintWorkoutVM.restTime)")
    }
    
    private func toggleWorkout() {
        if isWorkoutActive {
            stopCurrentSprint()
        } else {
            startSprint()
        }
    }
    
    private func startSprint() {
        isWorkoutActive = true
        elapsedTime = 0
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = true
        sprintWorkoutVM.currentRep = currentSet
        
        // Sync to phone
        syncWorkoutStateToPhone()
        
        // Start workout timer
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            heartRate = Int.random(in: 140...180) // Mock elevated heart rate
        }
        
        // Speech feedback
        speak("Sprint \(currentSet) of \(sets). \(distance) yards. Go!")
        WKInterfaceDevice.current().play(.start)
    }
    
    private func stopCurrentSprint() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // Record sprint time
        lastSprintTime = elapsedTime
        sprintTimes.append(elapsedTime)
        
        // Calculate average
        avgSprintTime = sprintTimes.reduce(0, +) / Double(sprintTimes.count)
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = false
        sprintWorkoutVM.lastRepTime = elapsedTime
        
        // Sync to phone
        syncWorkoutStateToPhone()
        
        // Start rest period if not last set
        if currentSet < sets {
            startRestPeriod()
        } else {
            endWorkout()
        }
        
        WKInterfaceDevice.current().play(.stop)
    }
    
    private func startRestPeriod() {
        isResting = true
        restTimeRemaining = Double(restMinutes * 60)
        heartRate = Int.random(in: 100...140) // Mock recovery heart rate
        
        // Initialize WorkoutWatchViewModel rest progress
        sprintWorkoutVM.repProgress = 1.0 // Start at full rest time
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            restTimeRemaining -= 1
            
            // Update WorkoutWatchViewModel rest progress
            let totalRestTime = Double(restMinutes * 60)
            DispatchQueue.main.async {
                sprintWorkoutVM.repProgress = max(0.0, restTimeRemaining / totalRestTime)
            }
            
            if restTimeRemaining <= 0 {
                endRestPeriod()
            }
        }
        
        speak("Rest for \(restMinutes) minutes")
    }
    
    private func endRestPeriod() {
        isResting = false
        restTimer?.invalidate()
        restTimer = nil
        nextSet()
        
        speak("Rest complete. Ready for next sprint.")
        WKInterfaceDevice.current().play(.click)
    }
    
    private func nextSet() {
        if currentSet < sets {
            currentSet += 1
            elapsedTime = 0
            
            // Update WorkoutWatchViewModel
            sprintWorkoutVM.currentRep = currentSet
        }
    }
    
    private func endWorkout() {
        stopWorkout()
        
        // Save workout data
        dataManager.saveSprintWorkout(
            distance: distance,
            sets: sets,
            sprintTimes: sprintTimes,
            avgTime: avgSprintTime,
            totalTime: elapsedTime
        )
        
        speak("Workout complete. Great job!")
        dismiss()
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        isResting = false
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        restTimer = nil
        heartRate = Int.random(in: 60...80) // Mock resting heart rate
    }
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynth.speak(utterance)
    }
    
    // MARK: - Integrated Autonomous Workout Lifecycle
    private func startAutonomousWorkout() {
        print("🚀 Starting integrated Sprint Timer Pro workout...")
        
        // Initialize workout data
        workoutData = WatchWorkoutData(
            workoutType: .power,
            sessionName: "Sprint Timer Pro - \(distance)yd x \(sets)",
            totalIntervals: sets
        )
        
        // Register all systems with event bus
        eventBus.registerAllSystems()
        
        // Create session for event broadcasting
        let session = TrainingSession(
            week: 1,
            day: 1,
            type: "Sprint Timer Pro",
            focus: "Speed",
            sprints: [SprintSet(distanceYards: distance, reps: sets, intensity: "max")],
            accessoryWork: []
        )
        
        // Broadcast workout start event
        eventBus.broadcast(.workoutStarted(session))
        
        // Start autonomous systems
        workoutManager.startWorkout()
        gpsManager.startTracking()
        
        // Configure interval manager for sprint timer
        let intervals = (0..<sets).map { index in
            IntervalConfig(
                distance: distance,
                restTime: TimeInterval(restMinutes * 60),
                intensity: "Max"
            )
        }
        
        let workoutPlan = WorkoutPlan(
            intervals: intervals,
            warmupTime: 180, // 3 minutes
            cooldownTime: 180 // 3 minutes
        )
        
        intervalManager.startWorkout(plan: workoutPlan)
        
        // Start premium entertainment systems
        startPremiumSystems(session: session)
    }
    
    private func startPremiumSystems(session: TrainingSession) {
        // Initialize advanced haptics (Watch compatible)
        hapticsManager.handleWorkoutPhaseChange("warmup")
        
        // Start with warmup phase
        eventBus.broadcastPhaseChange(to: .warmup)
        
        print("🎵 Premium systems initialized for Sprint Timer Pro (Watch)")
    }
    
    private func endAutonomousWorkout() {
        print("🏁 Ending autonomous Sprint Timer Pro workout...")
        
        // Stop all systems
        workoutManager.endWorkout()
        intervalManager.stopWorkout()
        gpsManager.stopTracking()
        
        // Finalize workout data
        if let data = workoutData {
            data.completeWorkout()
            
            // Save to local storage
            dataStore.saveWorkout(data)
            
            print("✅ Autonomous Sprint Timer Pro workout completed and saved")
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        if time < 60 {
            return String(format: "%02d.%02d", seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Sync Methods
    private func setupSyncListeners() {
        // Listen for phone sync updates
        NotificationCenter.default.addObserver(
            forName: .workoutStateAdapted,
            object: nil,
            queue: .main
        ) { notification in
            if let workoutState = notification.object as? WorkoutSyncState {
                self.handlePhoneWorkoutStateUpdate(workoutState)
            }
        }
        
        // Listen for Pro picker data updates
        NotificationCenter.default.addObserver(
            forName: .proPickerDataAdapted,
            object: nil,
            queue: .main
        ) { notification in
            if let proPickerData = notification.object as? ProPickerDataSync {
                self.handleProPickerDataUpdate(proPickerData)
            }
        }
        
        print("🏃‍♂️ SprintTimer sync listeners setup complete")
    }
    
    private func syncWorkoutStateToPhone() {
        let watchState = syncManager.createWatchStateSync(
            currentPhase: isResting ? "rest" : (isWorkoutActive ? "sprint" : "ready"),
            isRunning: isWorkoutActive,
            isPaused: false,
            currentRep: currentSet
        )
        
        syncManager.sendWatchStateToPhone(watchState)
        
        // Update WorkoutWatchViewModel with current state
        sprintWorkoutVM.isRunning = isWorkoutActive
        sprintWorkoutVM.currentRep = currentSet
        sprintWorkoutVM.currentRepTime = elapsedTime
        
        print("🏃‍♂️ SprintTimer workout state synced to phone")
    }
    
    private func handlePhoneWorkoutStateUpdate(_ workoutState: WorkoutSyncState) {
        // Update local state based on phone updates
        isWorkoutActive = workoutState.isRunning
        currentSet = workoutState.currentRep
        
        // Update WorkoutWatchViewModel
        sprintWorkoutVM.isRunning = workoutState.isRunning
        sprintWorkoutVM.currentRep = workoutState.currentRep
        
        print("🏃‍♂️ SprintTimer updated from phone: \(workoutState.currentPhase)")
    }
    
    private func handleProPickerDataUpdate(_ proPickerData: ProPickerDataSync) {
        // Update sprint parameters from Pro picker
        // Note: This would typically update distance and sets, but those are let constants
        // In a real implementation, these would be @State variables
        print("🎯 SprintTimer Pro picker data updated: \(proPickerData.selectedDistance)yd x\(proPickerData.selectedReps) reps")
    }
}

// MARK: - Supporting Views
struct SprintControlWatchView: View {
    @Binding var isWorkoutActive: Bool
    let currentSet: Int
    let totalSets: Int
    let currentTime: String
    let totalTime: String
    let onStartStop: () -> Void
    let onNextSet: () -> Void
    let onEndWorkout: () -> Void
    
    @State private var showEndWorkoutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer display at top
            VStack(spacing: 4) {
                Text(currentTime)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("ELAPSED TIME")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Control buttons grid matching the uploaded design
            VStack(spacing: 12) {
                // Top row: Pause/Play and Stop
                HStack(spacing: 12) {
                    // Start/Stop Button (Orange border)
                    ControlButton(
                        icon: isWorkoutActive ? "pause.fill" : "play.fill",
                        borderColor: .orange,
                        action: onStartStop
                    )
                    
                    // End Workout Button (Pink border)
                    ControlButton(
                        icon: "stop.fill",
                        borderColor: .pink,
                        action: {
                            showEndWorkoutAlert = true
                        }
                    )
                }
                
                // Bottom row: Next Set and Skip
                HStack(spacing: 12) {
                    // Next Set Button (Cyan border)
                    ControlButton(
                        icon: "forward.fill",
                        borderColor: .cyan,
                        action: onNextSet
                    )
                    
                    // Skip Button (Blue border)
                    ControlButton(
                        icon: "forward.end.fill",
                        borderColor: .blue,
                        action: {
                            // Skip current set
                            onNextSet()
                        }
                    )
                }
                
                // Set indicator (Gray border) - centered
                HStack {
                    VStack(spacing: 2) {
                        Text("SET")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(currentSet)/\(totalSets)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 70, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                    )
                }
            }
            
            Spacer()
            
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 4)
            
            // Navigation hints
            Text("Main →")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 4)
        }
        .background(Color.black.ignoresSafeArea())
        .alert(isPresented: $showEndWorkoutAlert) {
            Alert(
                title: Text("End Workout?"),
                message: Text("Save your progress and end the workout?"),
                primaryButton: .default(Text("CONTINUE WORKOUT")),
                secondaryButton: .default(Text("END & SAVE")) {
                    onEndWorkout()
                }
            )
        }
    }
}


struct SprintTimesModuleView: View {
    let avg: String
    let last: String
    let theme: ColorTheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Sprint Times")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text("Avg: \(avg)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
            Text("Last: \(last)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 44)
        .background(Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

struct SprintRepLogWatchView: View {
    let currentSet: Int
    let totalSets: Int
    let sprintTimes: [TimeInterval]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Rep Log")
                .font(.title2)
                .foregroundColor(.white)
            Text("Set \(currentSet)/\(totalSets)")
                .foregroundColor(.gray)
            Button("Close", action: onDismiss)
                .foregroundColor(.blue)
        }
    }
}

struct SprintDetailWatchView: View {
    let distance: Int
    let currentTime: TimeInterval
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Sprint Detail")
                .font(.title2)
                .foregroundColor(.white)
            Text("\(distance) yards")
                .foregroundColor(.gray)
            Button("Close", action: onDismiss)
                .foregroundColor(.blue)
        }
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
