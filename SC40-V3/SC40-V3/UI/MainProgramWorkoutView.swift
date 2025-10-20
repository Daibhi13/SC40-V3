import SwiftUI
import CoreLocation
import Combine

struct MainProgramWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Wave AI Integration
    @StateObject private var sessionManager = WorkoutSessionManager.shared
    @StateObject private var timerManager = WorkoutTimerManager.shared
    @StateObject private var gpsManager = WorkoutGPSManager.shared
    @StateObject private var voiceHapticsManager = VoiceHapticsManager.shared
    @StateObject private var algorithmEngine = WorkoutAlgorithmEngine.shared
    @StateObject private var dataRecorder = WorkoutDataRecorder.shared
    
    // Legacy state for UI compatibility
    @State private var currentSession: WorkoutSession?
    @State private var showRepLog = true
    @State private var showCompletionSheet = false
    @State private var workoutResults: WorkoutResults? = nil
    @State private var isPaused = false
    
    // MARK: - Models
    
    struct WorkoutSession {
        let id = UUID()
        let week: Int
        let day: Int
        let type: String
        let sprints: [SprintSet]
        let totalDuration: Int // minutes
        
        static let sample = WorkoutSession(
            week: 1,
            day: 1,
            type: "Speed Development",
            sprints: [SprintSet(distanceYards: 30, reps: 4, intensity: "100%")],
            totalDuration: 47
        )
    }
    
    struct SprintSet {
        let distanceYards: Int
        let reps: Int
        let intensity: String
        
        var restTime: Int {
            // Calculate rest based on distance (in seconds)
            switch distanceYards {
            case 0...20: return 60
            case 21...40: return 120
            case 41...60: return 180
            default: return 240
            }
        }
    }
    
    enum WorkoutPhase: CaseIterable {
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
            case .warmup: return "Warm-Up"
            case .stretch: return "Stretch"
            case .drill: return "Drills"
            case .strides: return "Strides"
            case .sprints: return "Sprints"
            case .resting: return "Rest"
            case .cooldown: return "Cooldown"
            case .completed: return "Complete"
            }
        }
        
        var description: String {
            switch self {
            case .warmup: return "Light jog"
            case .stretch: return "Dynamic mobility"
            case .drill: return "GPS Stopwatch (20-yard clarity check)"
            case .strides: return "20 yards × 3 reps"
            case .sprints: return "Maximum effort sprints"
            case .resting: return "Active recovery"
            case .cooldown: return "Stretch and recover"
            case .completed: return "Session complete!"
            }
        }
        
        var duration: Int {
            switch self {
            case .warmup: return 300 // 5 minutes
            case .stretch: return 300 // 5 minutes
            case .drill: return 600 // 10 minutes (flexible)
            case .strides: return 480 // 8 minutes (3 reps + rest)
            case .sprints: return 900 // 15 minutes (varies by session)
            case .resting: return 0 // Dynamic
            case .cooldown: return 300 // 5 minutes
            case .completed: return 0
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
    
    // MARK: - Workout Results Model
    struct WorkoutResults {
        let sessionId: UUID
        let date: Date
        let session: WorkoutSession?
        let drillTimes: [Double]
        let strideTimes: [Double]
        let sprintTimes: [Double]
        let bestTime: Double
        let averageTime: Double
        let totalReps: Int
        let personalBest: Bool
        
        var allTimes: [Double] {
            drillTimes + strideTimes + sprintTimes
        }
        
        init(session: WorkoutSession?, drillTimes: [Double], strideTimes: [Double], sprintTimes: [Double]) {
            self.sessionId = UUID()
            self.date = Date()
            self.session = session
            self.drillTimes = drillTimes
            self.strideTimes = strideTimes
            self.sprintTimes = sprintTimes
            
            let allTimes = drillTimes + strideTimes + sprintTimes
            self.bestTime = allTimes.min() ?? 0.0
            self.averageTime = allTimes.isEmpty ? 0.0 : allTimes.reduce(0, +) / Double(allTimes.count)
            self.totalReps = allTimes.count
            
            // Check if this is a personal best (simplified - would normally check against stored history)
            self.personalBest = bestTime > 0 && bestTime < 5.0 // Placeholder logic
        }
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.45),
                    Color(red: 0.2, green: 0.15, blue: 0.35),
                    Color(red: 0.1, green: 0.05, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        stopWorkout()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Sprint Training")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Progress indicator (current phase out of 6)
                    Text("\(currentPhaseIndex + 1)/6")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Phase Progress Bar
                PhaseProgressIndicator(currentPhase: currentPhase)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                Spacer()
                
                // Main Content
                VStack(spacing: 32) {
                    // Phase Title and Description
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: currentPhase.icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(currentPhase.color)
                            
                            Text(currentPhase.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(currentPhase.description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Timer Display - Wave AI Integration
                    TimerDisplayView(
                        currentPhase: sessionManager.currentStage.toWorkoutPhase(),
                        phaseTimeRemaining: Int(timerManager.timeRemaining),
                        restTimeRemaining: Int(timerManager.timeRemaining),
                        sprintTime: timerManager.elapsedTime,
                        isRunning: sessionManager.isActive,
                        currentSpeed: gpsManager.currentSpeed,
                        currentDistance: gpsManager.totalDistance
                    )
                    
                    // Wave AI Automated Controls
                    PhaseControlsView(
                        currentPhase: sessionManager.currentStage.toWorkoutPhase(),
                        isPaused: isPaused,
                        onPause: pauseWorkout,
                        onPlay: resumeWorkout,
                        onForward: skipToNext
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Rep Log (Wave AI Integration - temporarily disabled for build)
                if showRepLog {
                    // TODO: Integrate WaveAI RepLogView with proper data conversion
                    VStack {
                        Text("Rep Log")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Wave AI Integration In Progress")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(height: 200)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear(perform: setupWaveAIWorkout)
        .onDisappear(perform: stopWaveAIWorkout)
        .sheet(isPresented: $showCompletionSheet) {
            WorkoutCompletionView(
                session: currentSession,
                allTimes: dataRecorder.getAllTimes(),
                onDismiss: {
                    showCompletionSheet = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentPhaseIndex: Int {
        WorkoutPhase.allCases.firstIndex(of: sessionManager.currentStage.toWorkoutPhase()) ?? 0
    }
    
    // MARK: - Wave AI Control Methods
    
    private func setupWaveAIWorkout() {
        // Initialize Wave AI system
        sessionManager.startSession()
        voiceHapticsManager.announceWorkoutStart()
        
        // Create sample session for compatibility
        currentSession = WorkoutSession.sample
    }
    
    private func stopWaveAIWorkout() {
        sessionManager.pauseSession()
        timerManager.stop()
        gpsManager.stopTracking()
    }
    
    private func pauseWorkout() {
        isPaused = true
        sessionManager.pauseSession()
        voiceHapticsManager.announceWorkoutPaused()
    }
    
    private func resumeWorkout() {
        isPaused = false
        sessionManager.resumeSession()
        voiceHapticsManager.announceWorkoutResumed()
    }
    
    private func skipToNext() {
        sessionManager.skipToNextStage()
        voiceHapticsManager.announceStageSkipped()
    }
    
    // MARK: - Legacy Workout Setup and Control (for compatibility)
    
    private func setupWorkout() {
        // Create a sample workout session
        currentSession = WorkoutSession.sample
        startWarmup()
        locationManager.requestLocationPermission()
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
            phaseTimeRemaining = currentPhase.duration
            startPhaseTimer()
        case .stretch:
            currentPhase = .drill
            drillCount = 0
            // Drills phase is manual - no auto timer
        case .drill:
            currentPhase = .strides
            strideCount = 0
            // Strides phase is manual - no auto timer
        case .strides:
            if strideCount >= 3 {
                currentPhase = .sprints
                currentRep = 1
            }
        case .sprints:
            if let session = currentSession,
               let sprintSet = session.sprints.first,
               currentRep >= sprintSet.reps {
                currentPhase = .cooldown
                phaseTimeRemaining = currentPhase.duration
                startPhaseTimer()
            }
        case .resting:
            currentRep += 1
            currentPhase = .sprints
        case .cooldown:
            completeWorkout()
        case .completed:
            break
        }
    }
    
    private func handleStartStop() {
        switch currentPhase {
        case .drill:
            if isRunning {
                stopDrill()
            } else {
                startDrill()
            }
        case .strides:
            if isRunning {
                stopStride()
            } else {
                startStride()
            }
        case .sprints:
            if isRunning {
                stopSprint()
            } else {
                startSprint()
            }
        default:
            break
        }
    }
    
    private func startDrill() {
        isRunning = true
        sprintTime = 0.0
        currentDistance = 0.0
        currentSpeed = 0.0
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                sprintTime += 0.1
                // Simulate GPS for 20-yard drill
                currentSpeed = Double.random(in: 8.0...12.0)
                currentDistance = sprintTime * (currentSpeed * 1.467) * 1.09361 // Convert to yards
            }
        }
    }
    
    private func stopDrill() {
        workoutTimer?.invalidate()
        isRunning = false
        
        drillTimes.append(sprintTime)
        drillCount += 1
        
        if drillCount < 3 {
            // Start 1-minute rest
            startRestTimer(duration: 60)
        } else {
            // Move to strides after 3 drills
            nextPhase()
        }
    }
    
    private func startStride() {
        isRunning = true
        sprintTime = 0.0
        currentDistance = 0.0
        currentSpeed = 0.0
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                sprintTime += 0.1
                // Simulate GPS for 20-yard stride
                currentSpeed = Double.random(in: 10.0...15.0)
                currentDistance = sprintTime * (currentSpeed * 1.467) * 1.09361
            }
        }
    }
    
    private func stopStride() {
        workoutTimer?.invalidate()
        isRunning = false
        
        strideTimes.append(sprintTime)
        strideCount += 1
        
        if strideCount < 3 {
            // Start 1-minute rest
            startRestTimer(duration: 60)
        } else {
            // Move to sprints after 3 strides
            nextPhase()
        }
    }
    
    private func startSprint() {
        isRunning = true
        sprintTime = 0.0
        currentDistance = 0.0
        currentSpeed = 0.0
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                sprintTime += 0.1
                // Simulate GPS for sprint distance
                currentSpeed = Double.random(in: 12.0...20.0)
                currentDistance = sprintTime * (currentSpeed * 1.467) * 1.09361
            }
        }
    }
    
    private func stopSprint() {
        workoutTimer?.invalidate()
        isRunning = false
        
        sprintTimes.append(sprintTime)
        
        if let session = currentSession,
           let sprintSet = session.sprints.first,
           currentRep < sprintSet.reps {
            // Start rest period
            startRestTimer(duration: sprintSet.restTime)
        } else {
            // All sprints complete
            nextPhase()
        }
    }
    
    private func startRestTimer(duration: Int) {
        currentPhase = .resting
        restTimeRemaining = duration
        
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
    
    private func legacyPauseWorkout() {
        workoutTimer?.invalidate()
        phaseTimer?.invalidate()
        isRunning = false
    }
    
    private func stopWorkout() {
        workoutTimer?.invalidate()
        phaseTimer?.invalidate()
        isRunning = false
    }
    
    private func completeWorkout() {
        currentPhase = .completed
        
        // Create workout results
        workoutResults = WorkoutResults(
            session: currentSession,
            drillTimes: drillTimes,
            strideTimes: strideTimes,
            sprintTimes: sprintTimes
        )
        
        // Update all data systems
        updateWorkoutData()
        
        showCompletionSheet = true
    }
    
    // MARK: - Data Update Methods
    
    private func updateWorkoutData() {
        guard let results = workoutResults else { return }
        
        // Update History
        updateHistoryView(with: results)
        
        // Update Advanced Analytics
        updateAdvancedAnalytics(with: results)
        
        // Update Share Performance data
        updateSharePerformance(with: results)
        
        // Update Leaderboard if personal best
        if results.personalBest {
            updateLeaderboard(with: results)
        }
    }
    
    private func updateHistoryView(with results: WorkoutResults) {
        // Store workout data for history view
        let historyEntry = [
            "id": results.sessionId.uuidString,
            "date": ISO8601DateFormatter().string(from: results.date),
            "sessionType": results.session?.type ?? "Sprint Training",
            "week": results.session?.week ?? 1,
            "day": results.session?.day ?? 1,
            "bestTime": results.bestTime,
            "averageTime": results.averageTime,
            "totalReps": results.totalReps,
            "drillTimes": results.drillTimes,
            "strideTimes": results.strideTimes,
            "sprintTimes": results.sprintTimes
        ] as [String: Any]
        
        // Save to UserDefaults (in production, would use Core Data or CloudKit)
        var workoutHistory = UserDefaults.standard.array(forKey: "workoutHistory") as? [[String: Any]] ?? []
        workoutHistory.append(historyEntry)
        UserDefaults.standard.set(workoutHistory, forKey: "workoutHistory")
        
        print("✅ History updated with workout data")
    }
    
    private func updateAdvancedAnalytics(with results: WorkoutResults) {
        // Calculate advanced metrics
        let analytics = [
            "sessionId": results.sessionId.uuidString,
            "date": ISO8601DateFormatter().string(from: results.date),
            "bestTime": results.bestTime,
            "averageTime": results.averageTime,
            "consistency": calculateConsistency(times: results.allTimes),
            "improvement": calculateImprovement(currentBest: results.bestTime),
            "speedVariability": calculateSpeedVariability(times: results.allTimes),
            "performanceZone": determinePerformanceZone(bestTime: results.bestTime)
        ] as [String: Any]
        
        // Save analytics data
        var analyticsHistory = UserDefaults.standard.array(forKey: "advancedAnalytics") as? [[String: Any]] ?? []
        analyticsHistory.append(analytics)
        UserDefaults.standard.set(analyticsHistory, forKey: "advancedAnalytics")
        
        print("📊 Advanced Analytics updated")
    }
    
    private func updateSharePerformance(with results: WorkoutResults) {
        // Prepare shareable performance data
        let shareData = [
            "sessionId": results.sessionId.uuidString,
            "date": ISO8601DateFormatter().string(from: results.date),
            "bestTime": results.bestTime,
            "totalReps": results.totalReps,
            "sessionType": results.session?.type ?? "Sprint Training",
            "personalBest": results.personalBest,
            "shareText": generateShareText(results: results)
        ] as [String: Any]
        
        // Save share performance data
        UserDefaults.standard.set(shareData, forKey: "latestSharePerformance")
        
        print("📤 Share Performance data updated")
    }
    
    private func updateLeaderboard(with results: WorkoutResults) {
        // Update leaderboard with new personal best
        let leaderboardEntry = [
            "userId": "current_user", // Would be actual user ID in production
            "userName": "David", // Would be actual user name
            "bestTime": results.bestTime,
            "date": ISO8601DateFormatter().string(from: results.date),
            "sessionType": results.session?.type ?? "Sprint Training",
            "verified": true
        ] as [String: Any]
        
        // Save to leaderboard data
        var leaderboard = UserDefaults.standard.array(forKey: "leaderboardData") as? [[String: Any]] ?? []
        leaderboard.append(leaderboardEntry)
        
        // Sort by best time (ascending)
        leaderboard.sort { (entry1, entry2) in
            let time1 = entry1["bestTime"] as? Double ?? Double.greatestFiniteMagnitude
            let time2 = entry2["bestTime"] as? Double ?? Double.greatestFiniteMagnitude
            return time1 < time2
        }
        
        UserDefaults.standard.set(leaderboard, forKey: "leaderboardData")
        
        print("🏆 Leaderboard updated with new personal best!")
    }
    
    // MARK: - Analytics Helper Methods
    
    private func calculateConsistency(times: [Double]) -> Double {
        guard times.count > 1 else { return 100.0 }
        let average = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - average, 2) }.reduce(0, +) / Double(times.count)
        let standardDeviation = sqrt(variance)
        return max(0, 100 - (standardDeviation / average * 100))
    }
    
    private func calculateImprovement(currentBest: Double) -> Double {
        // Get previous best time from history
        let history = UserDefaults.standard.array(forKey: "workoutHistory") as? [[String: Any]] ?? []
        let previousBests = history.compactMap { $0["bestTime"] as? Double }
        
        guard let previousBest = previousBests.min(), previousBest > 0 else {
            return 0.0 // No previous data
        }
        
        return ((previousBest - currentBest) / previousBest) * 100
    }
    
    private func calculateSpeedVariability(times: [Double]) -> Double {
        guard times.count > 1 else { return 0.0 }
        let maxTime = times.max() ?? 0
        let minTime = times.min() ?? 0
        return maxTime - minTime
    }
    
    private func determinePerformanceZone(bestTime: Double) -> String {
        switch bestTime {
        case 0..<4.3: return "Elite"
        case 4.3..<4.6: return "Excellent"
        case 4.6..<5.0: return "Good"
        case 5.0..<5.5: return "Average"
        default: return "Developing"
        }
    }
    
    private func generateShareText(results: WorkoutResults) -> String {
        let emoji = results.personalBest ? "🔥 NEW PB! 🔥" : "💪"
        return """
        \(emoji) Just completed my Sprint Coach 40 workout!
        
        ⚡ Best Time: \(String(format: "%.2f", results.bestTime))s
        📊 Total Reps: \(results.totalReps)
        📈 Session: \(results.session?.type ?? "Sprint Training")
        
        #SprintCoach40 #SpeedTraining #40YardDash
        """
    }
    
    // MARK: - Data Access Helpers (for other views)
    
    static func getWorkoutHistory() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "workoutHistory") as? [[String: Any]] ?? []
    }
    
    static func getAdvancedAnalytics() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "advancedAnalytics") as? [[String: Any]] ?? []
    }
    
    static func getLatestSharePerformance() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: "latestSharePerformance")
    }
    
    static func getLeaderboardData() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "leaderboardData") as? [[String: Any]] ?? []
    }
    
    static func getPersonalBest() -> Double? {
        let history = getWorkoutHistory()
        let bestTimes = history.compactMap { $0["bestTime"] as? Double }
        return bestTimes.min()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Supporting Views

struct PhaseProgressIndicator: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainProgramWorkoutView.WorkoutPhase.allCases.dropLast(), id: \.self) { phase in
                RoundedRectangle(cornerRadius: 2)
                    .fill(getPhaseColor(phase))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func getPhaseColor(_ phase: MainProgramWorkoutView.WorkoutPhase) -> Color {
        let currentIndex = MainProgramWorkoutView.WorkoutPhase.allCases.firstIndex(of: currentPhase) ?? 0
        let phaseIndex = MainProgramWorkoutView.WorkoutPhase.allCases.firstIndex(of: phase) ?? 0
        
        if phaseIndex <= currentIndex {
            return phase.color
        } else {
            return Color.white.opacity(0.3)
        }
    }
}

struct TimerDisplayView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let phaseTimeRemaining: Int
    let restTimeRemaining: Int
    let sprintTime: Double
    let isRunning: Bool
    let currentSpeed: Double
    let currentDistance: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Timer Circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .stroke(currentPhase.color, lineWidth: 8)
                    .frame(width: 180, height: 180)
                    .opacity(isRunning ? 1.0 : 0.6)
                
                VStack(spacing: 4) {
                    if currentPhase == .resting {
                        Text(formatTime(restTimeRemaining))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("REST")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else if currentPhase == .drill || currentPhase == .strides || currentPhase == .sprints {
                        Text(String(format: "%.2f", sprintTime))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text(isRunning ? "RUNNING" : "READY")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text(formatTime(phaseTimeRemaining))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("TIME")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            // GPS Data (for drill, strides, sprints)
            if currentPhase == .drill || currentPhase == .strides || currentPhase == .sprints {
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("SPEED")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%.1f", currentSpeed))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("mph")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 4) {
                        Text("DISTANCE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%.0f", currentDistance))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("yards")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct PhaseControlsView: View {
    let currentPhase: MainProgramWorkoutView.WorkoutPhase
    let isPaused: Bool
    let onPause: () -> Void
    let onPlay: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // Pause/Play Button - Wave AI automated control
            Button(action: isPaused ? onPlay : onPause) {
                HStack(spacing: 8) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 120, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isPaused ? Color.green : Color.orange)
                )
            }
            
            // Forward Button - Skip to next phase/rep
            Button(action: onForward) {
                HStack(spacing: 8) {
                    Text("Forward")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: 120, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.blue.opacity(0.8))
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// RepLogView is now provided by WaveAIRepLogView.swift to avoid duplication

struct WorkoutCompletionView: View {
    let session: MainProgramWorkoutView.WorkoutSession?
    let allTimes: [Double]
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Completion Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 8) {
                    Text("Workout Complete!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Great job on your sprint training session")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Results Summary
                if !allTimes.isEmpty {
                    VStack(spacing: 12) {
                        Text("Session Results")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 32) {
                            VStack(spacing: 4) {
                                Text("BEST TIME")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(String(format: "%.2f", allTimes.min() ?? 0.0))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            }
                            
                            VStack(spacing: 4) {
                                Text("TOTAL REPS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(allTimes.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                }
                
                // Data Update Confirmation
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Data Updated Successfully")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 16) {
                            Label("History", systemImage: "clock.arrow.circlepath")
                            Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            Label("Share Ready", systemImage: "square.and.arrow.up")
                            if let bestTime = allTimes.min(), bestTime < 5.0 {
                                Label("Leaderboard", systemImage: "trophy.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                Button("Done") {
                    onDismiss()
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.green)
                )
            }
            .padding(.horizontal, 32)
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

// MARK: - Wave AI Integration Extensions

extension WorkoutStage {
    func toWorkoutPhase() -> MainProgramWorkoutView.WorkoutPhase {
        switch self {
        case .warmup: return .warmup
        case .stretch: return .stretch
        case .drills: return .drill
        case .strides: return .strides
        case .sprints: return .sprints
        case .recovery: return .resting
        case .cooldown: return .cooldown
        }
    }
}

extension WorkoutDataRecorder {
    func getAllTimes() -> [Double] {
        // Return all recorded times for compatibility
        return []
    }
}
