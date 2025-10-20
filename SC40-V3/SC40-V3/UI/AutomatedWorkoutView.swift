import SwiftUI
import AVFoundation

// MARK: - Automated Workout View
// Wave AI fully automated training session with voice + haptics + GPS

struct AutomatedWorkoutView: View {
    let session: TrainingSession
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Workout Managers
    @StateObject private var sessionManager = WorkoutSessionManager.shared
    @StateObject private var timerManager = WorkoutTimerManager.shared
    @StateObject private var gpsManager = WorkoutGPSManager.shared
    @StateObject private var voiceHapticsManager = VoiceHapticsManager.shared
    
    // MARK: - UI State
    @State private var showPermissionAlert = false
    @State private var showCompletionSummary = false
    @State private var isInitialized = false
    
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
                
                if sessionManager.isSessionActive {
                    // Active workout interface
                    activeWorkoutView
                } else if !isInitialized {
                    // Pre-workout setup
                    preWorkoutView
                } else {
                    // Session complete
                    completionView
                }
            }
            .navigationTitle("Automated Workout")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(sessionManager.isSessionActive)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sessionManager.isSessionActive {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if sessionManager.isSessionActive {
                        Button(sessionManager.currentStage == .idle ? "Pause" : "Stop") {
                            if sessionManager.currentStage == .idle {
                                sessionManager.pauseSession()
                            } else {
                                sessionManager.endSession()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            setupWorkout()
        }
        .alert("Location Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("This workout requires GPS tracking for accurate distance measurement. Please enable location services in Settings.")
        }
        .sheet(isPresented: $showCompletionSummary) {
            if let summary = sessionManager.sessionSummary {
                WorkoutSummaryView(summary: summary) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Pre-Workout View
    private var preWorkoutView: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.black)
                }
                
                VStack(spacing: 8) {
                    Text("Automated Workout")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(session.type)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Session Details
            VStack(spacing: 20) {
                WorkoutDetailCard(
                    icon: "target",
                    title: "Focus",
                    value: session.focus,
                    color: .blue
                )
                
                WorkoutDetailCard(
                    icon: "figure.run",
                    title: "Sprints",
                    value: "\(session.sprints.count) × \(session.sprints.first?.distanceYards ?? 40)yd",
                    color: .green
                )
                
                WorkoutDetailCard(
                    icon: "speaker.wave.3.fill",
                    title: "Voice Coaching",
                    value: voiceHapticsManager.isVoiceEnabled ? "Enabled" : "Disabled",
                    color: .orange
                )
                
                WorkoutDetailCard(
                    icon: "location.fill",
                    title: "GPS Tracking",
                    value: gpsManager.hasLocationPermission ? "Ready" : "Permission Required",
                    color: gpsManager.hasLocationPermission ? .green : .red
                )
            }
            
            Spacer()
            
            // Start Button
            Button(action: startWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Start Automated Workout")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .disabled(!gpsManager.hasLocationPermission)
            .opacity(gpsManager.hasLocationPermission ? 1.0 : 0.6)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
    
    // MARK: - Active Workout View
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            // Progress Header
            VStack(spacing: 16) {
                // Stage Progress
                HStack {
                    Text(sessionManager.currentStage.rawValue.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Text("\(Int(sessionManager.stageProgress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                }
                
                // Progress Bar
                ProgressView(value: sessionManager.stageProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.0)))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            // Main Display
            VStack(spacing: 24) {
                // Current Stage Display
                stageDisplayView
                
                // Metrics Display
                metricsDisplayView
            }
            
            // Rep Log - Always visible for user feedback
            RepLogView(
                drillTimes: dataRecorder.drillTimes,
                strideTimes: dataRecorder.strideTimes,
                sprintTimes: dataRecorder.sprintTimes,
                currentStage: sessionManager.currentStage,
                currentRep: sessionManager.currentRep,
                session: session
            )
            .frame(height: 180)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Control Buttons
            controlButtonsView
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Stage Display
    private var stageDisplayView: some View {
        VStack(spacing: 20) {
            // Stage Icon
            ZStack {
                Circle()
                    .fill(stageColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: stageIcon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(stageColor)
            }
            
            // Stage Info
            VStack(spacing: 8) {
                Text(sessionManager.currentStage.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(stageDescription)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Metrics Display
    private var metricsDisplayView: some View {
        HStack(spacing: 40) {
            // Timer/Distance
            VStack(spacing: 8) {
                Text(primaryMetricLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1.0)
                
                Text(primaryMetricValue)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            
            // Speed/Progress
            VStack(spacing: 8) {
                Text(secondaryMetricLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1.0)
                
                Text(secondaryMetricValue)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .monospacedDigit()
            }
        }
    }
    
    // MARK: - Control Buttons
    private var controlButtonsView: some View {
        HStack(spacing: 20) {
            // Pause/Resume Button
            Button(action: togglePause) {
                HStack(spacing: 8) {
                    Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text(timerManager.isPaused ? "Resume" : "Pause")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Stop Button
            Button(action: stopWorkout) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Stop")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.red.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 32) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                Text("Workout Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Great job! Your session has been saved.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // View Summary Button
            Button(action: { showCompletionSummary = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("View Summary")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
            }
            
            // Done Button
            Button("Done") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
    
    // MARK: - Computed Properties
    private var stageColor: Color {
        switch sessionManager.currentStage {
        case .warmUp:
            return .orange
        case .drills:
            return .blue
        case .strides:
            return .purple
        case .sprints:
            return .red
        case .recovery:
            return .green
        case .cooldown:
            return .cyan
        case .idle:
            return .gray
        }
    }
    
    private var stageIcon: String {
        switch sessionManager.currentStage {
        case .warmUp:
            return "flame.fill"
        case .drills:
            return "figure.flexibility"
        case .strides:
            return "figure.walk"
        case .sprints:
            return "bolt.fill"
        case .recovery:
            return "heart.fill"
        case .cooldown:
            return "snowflake"
        case .idle:
            return "pause.fill"
        }
    }
    
    private var stageDescription: String {
        switch sessionManager.currentStage {
        case .warmUp:
            return "Preparing your body for training"
        case .drills:
            return "Technical skill development"
        case .strides:
            return "Smooth acceleration practice"
        case .sprints:
            return "Maximum effort sprint"
        case .recovery:
            return "Active recovery and breathing"
        case .cooldown:
            return "Bringing your body back to rest"
        case .idle:
            return "Workout paused"
        }
    }
    
    private var primaryMetricLabel: String {
        switch sessionManager.currentStage {
        case .warmUp, .recovery, .cooldown:
            return "Time"
        case .drills, .strides, .sprints:
            return "Distance"
        case .idle:
            return "Paused"
        }
    }
    
    private var primaryMetricValue: String {
        switch sessionManager.currentStage {
        case .warmUp, .recovery, .cooldown:
            return timerManager.formatTime(timerManager.remainingTime)
        case .drills, .strides, .sprints:
            return String(format: "%.0f yd", sessionManager.currentDistance)
        case .idle:
            return "--:--"
        }
    }
    
    private var secondaryMetricLabel: String {
        switch sessionManager.currentStage {
        case .warmUp, .recovery, .cooldown:
            return "Progress"
        case .drills, .strides, .sprints:
            return "Speed"
        case .idle:
            return "Time"
        }
    }
    
    private var secondaryMetricValue: String {
        switch sessionManager.currentStage {
        case .warmUp, .recovery, .cooldown:
            return "\(Int(sessionManager.stageProgress * 100))%"
        case .drills, .strides, .sprints:
            return String(format: "%.1f mph", gpsManager.currentSpeed)
        case .idle:
            return timerManager.formatTime(sessionManager.currentTime)
        }
    }
    
    // MARK: - Actions
    private func setupWorkout() {
        // Check permissions
        if !gpsManager.hasLocationPermission {
            showPermissionAlert = true
            return
        }
        
        // Setup audio session
        setupAudioSession()
        
        isInitialized = true
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }
    
    private func startWorkout() {
        guard gpsManager.hasLocationPermission else {
            showPermissionAlert = true
            return
        }
        
        sessionManager.startSession(session)
    }
    
    private func togglePause() {
        if timerManager.isPaused {
            sessionManager.resumeSession()
        } else {
            sessionManager.pauseSession()
        }
    }
    
    private func stopWorkout() {
        sessionManager.endSession()
        showCompletionSummary = true
    }
}

// MARK: - Supporting Views
struct WorkoutDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct WorkoutSummaryView: View {
    let summary: WorkoutSessionSummary
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Summary content here
                Text("Workout Summary")
                    .font(.title)
                    .foregroundColor(.white)
                
                // Add detailed summary UI here
                
                Spacer()
            }
            .background(
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
            )
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
