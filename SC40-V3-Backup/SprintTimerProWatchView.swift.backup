import SwiftUI

struct SprintTimerProWatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDistance: Int = 40
    @State private var selectedReps: Int = 3
    @State private var selectedRestMinutes: Int = 2
    @State private var showWorkout = false
    
    // ENHANCED: Auto-sync with iPhone Pro view
    @StateObject private var watchSyncManager = WatchWorkoutSyncManager.shared
    
    // ENHANCED: Pro picker state management
    @State private var adaptedProPickerData: ProPickerDataSync?
    @State private var isAutoAdaptingFromPhone = false
    
    // PRESERVED: Match phone picker system exactly
    private let distanceOptions = [10, 20, 25, 30, 40, 50, 60, 75, 100] // Same as phone
    private let repsOptions = Array(1...10) // Same as phone  
    private let restOptions = Array(1...10) // Same as phone
    
    var body: some View {
        NavigationStack {
            ZStack {
                // STANDARDIZED: Matching gradient across all views
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.25),
                        Color(red: 0.12, green: 0.18, blue: 0.35),
                        Color(red: 0.15, green: 0.2, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // ENHANCED: Pro header matching phone
                        proHeaderSection
                        
                        // ENHANCED: Watch-optimized pickers matching phone functionality
                        watchPickersSection
                        
                        // ENHANCED: Workout preview matching phone
                        workoutPreviewSection
                        
                        // ENHANCED: Start button matching phone
                        startWorkoutButton
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupProWatchAutoAdaptation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .proPickerDataAdapted)) { notification in
            if let adaptedPickerData = notification.object as? ProPickerDataSync {
                adaptToPhoneProPickerData(adaptedPickerData)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutStateAdapted)) { notification in
            if let adaptedState = notification.object as? WorkoutSyncState {
                adaptToPhoneProWorkoutState(adaptedState)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .uiConfigurationAdapted)) { notification in
            if let adaptedConfig = notification.object as? UIConfigurationSync {
                adaptToPhoneProUIConfiguration(adaptedConfig)
            }
        }
        .fullScreenCover(isPresented: $showWorkout) {
            // ENHANCED: Launch Enhanced7StageWorkoutView with custom parameters
            Enhanced7StageWorkoutView(session: createCustomTrainingSession())
        }
    }
    
    // MARK: - ENHANCED UI Components Matching Phone
    
    private var proHeaderSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                
                Spacer()
                
                // Balance spacer
                Color.clear
                    .frame(width: 28, height: 28)
            }
            
            Text("SPRINT TIMER PRO")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Custom Sprint Workouts")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // ENHANCED: Watch pickers section matching phone functionality
    private var watchPickersSection: some View {
        VStack(spacing: 12) {
            // Distance Picker - matches phone exactly
            VStack(spacing: 8) {
                Text("DISTANCE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Picker("Distance", selection: $selectedDistance) {
                    ForEach(distanceOptions, id: \.self) { distance in
                        Text("\(distance) YD")
                            .font(.system(size: 14, weight: .bold))
                            .tag(distance)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
            
            // Reps Picker - matches phone exactly
            VStack(spacing: 8) {
                Text("REPETITIONS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Picker("Reps", selection: $selectedReps) {
                    ForEach(repsOptions, id: \.self) { reps in
                        Text("\(reps) REP\(reps == 1 ? "" : "S")")
                            .font(.system(size: 14, weight: .bold))
                            .tag(reps)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
            
            // Rest Time Picker - matches phone exactly
            VStack(spacing: 8) {
                Text("REST TIME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Picker("Rest", selection: $selectedRestMinutes) {
                    ForEach(restOptions, id: \.self) { rest in
                        Text("\(rest) MIN\(rest == 1 ? "" : "S")")
                            .font(.system(size: 14, weight: .bold))
                            .tag(rest)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }
    
    private func pickerColumn<T: Hashable>(
        title: String,
        selection: Binding<T>,
        options: [T],
        suffix: String
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.adaptiveCaption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text("\(option)\(suffix.isEmpty ? "" : " \(suffix)")")
                        .font(.adaptiveBody)
                        .fontWeight(.medium)
                        .tag(option)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: compactPickerHeight)
        }
        .frame(maxWidth: .infinity)
    }
    
    // ENHANCED: Workout preview matching phone
    private var workoutPreviewSection: some View {
        VStack(spacing: 8) {
            Text("WORKOUT PREVIEW")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                    
                    Text("\(selectedReps) × \(selectedDistance) Yard Sprints")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Text("\(selectedRestMinutes) minute\(selectedRestMinutes == 1 ? "" : "s") rest between reps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    let totalTime = (selectedReps * selectedRestMinutes) + 10
                    Text("~\(totalTime) minute workout")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // ENHANCED: Start button matching phone
    private var startWorkoutButton: some View {
        Button(action: startCustomWorkout) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("START CUSTOM WORKOUT")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                LinearGradient(
                    colors: [
                        Color.yellow,
                        Color.orange
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(22)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    
    private var compactPickerHeight: CGFloat {
        if WatchAdaptiveSizing.isUltra { return 70 }
        if WatchAdaptiveSizing.isLarge { return 65 }
        return 60
    }
    
    private var estimatedDuration: Int {
        // Estimate: warmup (2min) + sprints + rest + cooldown (2min)
        let sprintTime = selectedReps * 1 // ~1 min per sprint including setup
        let restTime = (selectedReps - 1) * selectedRestMinutes
        return 4 + sprintTime + restTime
    }
    
    // MARK: - ENHANCED Actions
    
    private func startCustomWorkout() {
        showWorkout = true
        print("🏃‍♂️ Starting Sprint Timer Pro workout: \(selectedDistance)yd x\(selectedReps) reps with \(selectedRestMinutes)min rest")
    }
    
    // ENHANCED: Create custom training session for Enhanced7StageWorkoutView
    private func createCustomTrainingSession() -> TrainingSession {
        return TrainingSession(
            week: 0, // Custom session indicator
            day: 0,
            type: "Sprint Timer Pro",
            focus: "Custom \(selectedDistance)yd x\(selectedReps)",
            sprints: [
                SprintSet(
                    distanceYards: selectedDistance,
                    reps: selectedReps,
                    intensity: "Custom"
                )
            ],
            accessoryWork: [],
            notes: "Custom Sprint Timer Pro workout - \(selectedDistance)yd x\(selectedReps) with \(selectedRestMinutes)min rest"
        )
    }
    
    // MARK: - Pro Watch Auto-Adaptation Methods
    
    private func setupProWatchAutoAdaptation() {
        // Request initial sync from iPhone Pro view
        watchSyncManager.requestFullSyncFromPhone()
        
        print("⌚ Pro Watch auto-adaptation setup complete - watching for iPhone Pro changes")
    }
    
    private func adaptToPhoneProPickerData(_ phonePickerData: ProPickerDataSync) {
        // ENHANCED: Auto-adapt picker values from iPhone Pro view
        isAutoAdaptingFromPhone = true
        
        selectedDistance = phonePickerData.selectedDistance
        selectedReps = phonePickerData.selectedReps
        selectedRestMinutes = phonePickerData.selectedRestMinutes
        
        adaptedProPickerData = phonePickerData
        
        // Show adaptation feedback
        print("⌚ Pro Watch adapted picker data from iPhone: \(phonePickerData.selectedDistance)yd x\(phonePickerData.selectedReps) reps, \(phonePickerData.selectedRestMinutes)min rest")
        
        isAutoAdaptingFromPhone = false
    }
    
    private func adaptToPhoneProWorkoutState(_ phoneState: WorkoutSyncState) {
        // ENHANCED: Auto-adapt workout state from iPhone Pro view
        if phoneState.sessionId.hasPrefix("pro-") {
            // This is a Pro session state update
            print("⌚ Pro Watch adapted workout state from iPhone Pro: \(phoneState.currentPhase)")
        }
    }
    
    private func adaptToPhoneProUIConfiguration(_ phoneConfig: UIConfigurationSync) {
        // ENHANCED: Auto-adapt UI configuration from iPhone Pro view
        if phoneConfig.displayMode == "pro" {
            // This is a Pro UI configuration update
            print("⌚ Pro Watch adapted UI configuration from iPhone Pro")
        }
    }
    
    // MARK: - Pro Watch State Management
    
    private func sendProWatchStateToPhone() {
        let proWatchState = watchSyncManager.createWatchStateSync(
            currentPhase: "picker", // Pro picker phase
            isRunning: false,
            isPaused: false,
            currentRep: 0,
            requestedAction: nil
        )
        
        watchSyncManager.sendWatchStateToPhone(proWatchState)
    }
    
    private func sendProPickerChangeToPhone(_ action: String) {
        let proWatchState = watchSyncManager.createWatchStateSync(
            currentPhase: "picker",
            isRunning: false,
            isPaused: false,
            currentRep: 0,
            requestedAction: action
        )
        
        watchSyncManager.sendWatchStateToPhone(proWatchState)
    }
}

// MARK: - Preview
#if DEBUG
#Preview("Sprint Timer Pro Watch") {
    SprintTimerProWatchView()
        .preferredColorScheme(.dark)
}

#Preview("Sprint Timer Pro - Ultra") {
    SprintTimerProWatchView()
        .preferredColorScheme(.dark)
}

#Preview("Sprint Timer Pro - Series 9") {
    SprintTimerProWatchView()
        .preferredColorScheme(.dark)
}
#endif
