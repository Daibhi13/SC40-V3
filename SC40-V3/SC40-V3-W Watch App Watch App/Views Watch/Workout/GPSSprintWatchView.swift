import SwiftUI
import WatchKit
import HealthKit

struct GPSSprintWatchView: View {
    @ObservedObject var sessionManager = WatchSessionManager.shared
    @State private var currentSession: TrainingSession?
    @State private var currentRep = 1
    @State private var isWorkoutActive = false
    @State private var workoutSession: HKWorkoutSession?
    @State private var builder: HKLiveWorkoutBuilder?
    @State private var showingWorkoutSummary = false
    
    // Sprint tracking
    @State private var sprintStartTime: Date?
    @State private var currentSprintTime: TimeInterval = 0
    @State private var completedReps: [SprintRepData] = []
    @State private var restTimeRemaining: Int = 0
    @State private var isResting = false
    
    // GPS status from iPhone
    @State private var gpsStatus: String = "Connecting..."
    @State private var gpsAccuracy: Double = 0.0
    @State private var currentDistance: Double = 0.0
    @State private var currentSpeed: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                if let session = currentSession {
                    // Session Header
                    VStack(spacing: 4) {
                        Text("W\(session.week)D\(session.day)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(session.type)
                            .font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(session.focus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)
                    
                    // GPS Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(gpsStatusColor)
                            .frame(width: 6, height: 6)
                        Text(gpsStatus)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Sprint Progress
                    if !session.sprints.isEmpty {
                        let totalReps = session.sprints.first?.reps ?? 1
                        let distance = session.sprints.first?.distanceYards ?? 40
                        
                        VStack(spacing: 8) {
                            // Rep Counter
                            Text("Rep \(currentRep) of \(totalReps)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(distance) yards")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Current Sprint Data (when active)
                            if isWorkoutActive && !isResting {
                                VStack(spacing: 4) {
                                    HStack {
                                        VStack {
                                            Text(String(format: "%.1f", currentDistance))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.cyan)
                                            Text("YD")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        VStack {
                                            Text(String(format: "%.2f", currentSprintTime))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.yellow)
                                            Text("SEC")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        VStack {
                                            Text(String(format: "%.1f", currentSpeed))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                            Text("MPH")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // Rest Timer
                            if isResting {
                                VStack(spacing: 4) {
                                    Text("REST")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text(formatTime(restTimeRemaining))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            // Workout Controls
                            HStack(spacing: 12) {
                                if !isWorkoutActive {
                                    // Start Workout Button
                                    Button(action: startWorkout) {
                                        VStack(spacing: 2) {
                                            Image(systemName: "play.fill")
                                                .font(.title2)
                                            Text("START")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.green)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    // End Workout Button
                                    Button(action: endWorkout) {
                                        VStack(spacing: 2) {
                                            Image(systemName: "stop.fill")
                                                .font(.title2)
                                            Text("END")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if !isResting {
                                        // Complete Rep Button
                                        Button(action: completeCurrentRep) {
                                            VStack(spacing: 2) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title2)
                                                Text("DONE")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.blue)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Completed Reps Summary
                    if !completedReps.isEmpty {
                        VStack(spacing: 2) {
                            Text("COMPLETED")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(completedReps.indices, id: \.self) { index in
                                        VStack(spacing: 1) {
                                            Text("\(index + 1)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            if let time = completedReps[index].time {
                                                Text(String(format: "%.2f", time))
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            } else {
                                                Text("--")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(4)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                } else {
                    // No Session Available
                    VStack(spacing: 8) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No Session")
                            .font(.headline)
                        
                        Text("Start a workout on your iPhone to see it here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 8)
            .navigationTitle("Sprint Training")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            setupSession()
            setupWatchConnectivity()
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchConnectivityDataReceived)) { _ in
            updateFromiPhone()
        }
        .sheet(isPresented: $showingWorkoutSummary) {
            WorkoutSummaryView(
                completedReps: completedReps,
                session: currentSession,
                onDismiss: { showingWorkoutSummary = false }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var gpsStatusColor: Color {
        switch gpsStatus {
        case "GPS Ready", "Tracking": return .green
        case "GPS Denied", "GPS Error": return .red
        case "Requesting Permission": return .orange
        default: return .gray
        }
    }
    
    // MARK: - Setup Functions
    
    private func setupSession() {
        // Get the current session from WatchSessionManager
        if let session = sessionManager.trainingSessions.first(where: { !$0.isCompleted }) {
            currentSession = session
            
            // Initialize completed reps array
            if let firstSprint = session.sprints.first {
                completedReps = Array(1...firstSprint.reps).map { repNumber in
                    SprintRepData(repNumber: repNumber, time: nil, isCompleted: false)
                }
            }
        }
    }
    
    private func setupWatchConnectivity() {
        // Watch connectivity is handled by the existing sessionManager
        print("🔗 Watch connectivity setup completed")
    }
    
    private func updateFromiPhone() {
        // Update GPS data from iPhone (simplified for now)
        // This would be enhanced when the full Watch connectivity is implemented
        gpsStatus = "GPS Ready"
        print("📱 Updated data from iPhone")
    }
    
    // MARK: - Workout Control Functions
    
    private func startWorkout() {
        guard let session = currentSession else { return }
        
        // Start HealthKit workout
        startHealthKitWorkout()
        
        // Send start command to iPhone (simplified for now)
        print("📱 Sending start command to iPhone for session \(session.id)")
        
        isWorkoutActive = true
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
        
        print("🏃‍♂️ Watch: Workout started for session \(session.id)")
    }
    
    private func endWorkout() {
        guard let session = currentSession else { return }
        
        // End HealthKit workout
        endHealthKitWorkout()
        
        // Send end command to iPhone (simplified for now)
        print("📱 Sending end command to iPhone for session \(session.id)")
        
        isWorkoutActive = false
        
        // Show summary
        showingWorkoutSummary = true
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        print("⏹️ Watch: Workout ended for session \(session.id)")
    }
    
    private func completeCurrentRep() {
        guard currentRep <= completedReps.count else { return }
        
        // Mark current rep as completed
        completedReps[currentRep - 1] = SprintRepData(
            repNumber: currentRep,
            time: currentSprintTime > 0 ? currentSprintTime : nil,
            isCompleted: true
        )
        
        // Send rep completion to iPhone (simplified for now)
        print("📱 Sending rep completion to iPhone: Rep \(currentRep), Time: \(currentSprintTime > 0 ? String(format: "%.2f", currentSprintTime) : "nil")")
        
        // Start rest period or move to next rep
        if currentRep < completedReps.count {
            startRestPeriod()
            currentRep += 1
        } else {
            // All reps completed
            endWorkout()
        }
        
        // Reset sprint timer
        currentSprintTime = 0
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        print("✅ Watch: Rep \(currentRep) completed")
    }
    
    private func startRestPeriod() {
        isResting = true
        restTimeRemaining = 60 // Default 1 minute rest
        
        // Start rest timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                timer.invalidate()
                isResting = false
                
                // Haptic feedback for rest completion
                WKInterfaceDevice.current().play(.directionUp)
            }
        }
    }
    
    // MARK: - HealthKit Integration
    
    private func startHealthKitWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: HKHealthStore(), configuration: configuration)
            builder = workoutSession?.associatedWorkoutBuilder()
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: HKHealthStore(), workoutConfiguration: configuration)
            
            workoutSession?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { success, error in
                if success {
                    print("✅ HealthKit workout started")
                } else {
                    print("❌ HealthKit workout failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        } catch {
            print("❌ Failed to start HealthKit workout: \(error.localizedDescription)")
        }
    }
    
    private func endHealthKitWorkout() {
        workoutSession?.end()
        builder?.endCollection(withEnd: Date()) { success, error in
            if success {
                self.builder?.finishWorkout { workout, error in
                    if let workout = workout {
                        print("✅ HealthKit workout saved: \(workout)")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Supporting Types

struct SprintRepData {
    let repNumber: Int
    var time: Double?
    var isCompleted: Bool
}

struct WorkoutSummaryView: View {
    let completedReps: [SprintRepData]
    let session: TrainingSession?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("Workout Complete!")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let session = session {
                    Text(session.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Rep Summary
                VStack(spacing: 8) {
                    Text("REPS COMPLETED")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(completedReps.indices, id: \.self) { index in
                            VStack(spacing: 2) {
                                Text("Rep \(index + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if let time = completedReps[index].time {
                                    Text(String(format: "%.2fs", time))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Skipped")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                
                // Performance Stats
                let completedTimes = completedReps.compactMap { $0.time }
                if !completedTimes.isEmpty {
                    VStack(spacing: 4) {
                        Text("PERFORMANCE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack {
                                Text(String(format: "%.2fs", completedTimes.min() ?? 0))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Best")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(String(format: "%.2fs", completedTimes.reduce(0, +) / Double(completedTimes.count)))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Average")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let watchConnectivityDataReceived = Notification.Name("watchConnectivityDataReceived")
}

#Preview {
    GPSSprintWatchView()
}
