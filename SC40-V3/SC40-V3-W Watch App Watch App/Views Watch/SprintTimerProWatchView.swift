import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct SprintTimerProWatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDistance: Int = 40
    @State private var selectedReps: Int = 3
    @State private var selectedRestMinutes: Int = 2
    @State private var showWorkout = false
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    
    // Optimized options for Apple Watch
    private let distanceOptions = [20, 30, 40, 50, 60, 75, 100]
    private let repsOptions = Array(1...8)
    private let restOptions = Array(1...5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color.brandPrimary.opacity(0.3),
                        Color.brandSecondary.opacity(0.2),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: WatchAdaptiveSizing.spacing) {
                        // Pro header with crown
                        proHeaderSection
                        
                        // Compact pickers section
                        compactPickersSection
                        
                        // Workout preview
                        workoutPreviewSection
                        
                        // Start button
                        startWorkoutButton
                    }
                    .adaptivePadding()
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showWorkout) {
            if let workoutVM = createCustomWorkoutViewModel() {
                MainWorkoutWatchView(workoutVM: workoutVM)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var proHeaderSection: some View {
        VStack(spacing: WatchAdaptiveSizing.smallPadding) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: WatchAdaptiveSizing.iconSize))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Image(systemName: "crown.fill")
                    .font(.system(size: WatchAdaptiveSizing.iconSize * 1.5))
                    .foregroundColor(.yellow)
                
                Spacer()
                
                // Balance spacer
                Color.clear
                    .frame(width: 32, height: 32)
            }
            
            Text("SPRINT TIMER PRO")
                .font(.adaptiveTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Custom Sprint Workouts")
                .font(.adaptiveCaption)
                .foregroundColor(.secondary)
        }
    }
    
    private var compactPickersSection: some View {
        VStack(spacing: WatchAdaptiveSizing.smallPadding) {
            // Three-column picker layout optimized for watch
            HStack(spacing: 4) {
                pickerColumn(
                    title: "DIST",
                    selection: $selectedDistance,
                    options: distanceOptions,
                    suffix: "YD"
                )
                
                pickerColumn(
                    title: "REPS",
                    selection: $selectedReps,
                    options: repsOptions,
                    suffix: ""
                )
                
                pickerColumn(
                    title: "REST",
                    selection: $selectedRestMinutes,
                    options: restOptions,
                    suffix: "MIN"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: WatchAdaptiveSizing.cornerRadius)
                .fill(Color.white.opacity(0.1))
        )
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
    
    private var workoutPreviewSection: some View {
        VStack(spacing: WatchAdaptiveSizing.smallPadding) {
            Text("WORKOUT PREVIEW")
                .font(.adaptiveCaption)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            
            VStack(spacing: 4) {
                HStack {
                    Text("Distance:")
                        .font(.adaptiveBody)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedDistance) yards")
                        .font(.adaptiveBody)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Repetitions:")
                        .font(.adaptiveBody)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedReps) rep\(selectedReps == 1 ? "" : "s")")
                        .font(.adaptiveBody)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Rest Time:")
                        .font(.adaptiveBody)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedRestMinutes) min\(selectedRestMinutes == 1 ? "" : "s")")
                        .font(.adaptiveBody)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                HStack {
                    Text("Total Time:")
                        .font(.adaptiveBody)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("~\(estimatedDuration) min")
                        .font(.adaptiveBody)
                        .fontWeight(.bold)
                        .foregroundColor(.brandPrimary)
                }
            }
            .adaptiveSmallPadding()
            .background(
                RoundedRectangle(cornerRadius: WatchAdaptiveSizing.cornerRadius)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private var startWorkoutButton: some View {
        Button(action: startCustomWorkout) {
            VStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: WatchAdaptiveSizing.iconSize))
                
                Text("START WORKOUT")
                    .font(.adaptiveHeadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: WatchAdaptiveSizing.buttonHeight)
            .background(
                LinearGradient(
                    colors: [Color.brandPrimary, Color.brandSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(WatchAdaptiveSizing.cornerRadius)
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
    
    // MARK: - Actions
    
    private func startCustomWorkout() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
        
        let customSession = TrainingSession(
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
        
        // Set as current workout session
        sessionManager.setCurrentWorkoutSession(customSession)
        showWorkout = true
        
        print("🏃‍♂️ Starting Sprint Timer Pro workout: \(selectedDistance)yd x\(selectedReps) reps")
    }
    
    private func createCustomWorkoutViewModel() -> WorkoutWatchViewModel? {
        guard let currentSession = sessionManager.currentWorkoutSession else {
            print("❌ No current workout session available")
            return nil
        }
        
        // Create WorkoutWatchViewModel with custom parameters
        let workoutVM = WorkoutWatchViewModel(totalReps: selectedReps, restTime: TimeInterval(selectedRestMinutes * 60))
        
        // Update with session distances
        let distances = Array(repeating: selectedDistance, count: selectedReps)
        workoutVM.updateFromSession(distances: distances)
        
        return workoutVM
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
