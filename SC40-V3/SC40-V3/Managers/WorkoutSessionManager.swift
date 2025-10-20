import Foundation
import Combine
import AVFoundation

// MARK: - Workout Session Manager
// Core controller for fully automated training sessions with voice + haptics + GPS

class WorkoutSessionManager: ObservableObject {
    static let shared = WorkoutSessionManager()
    
    // MARK: - Published Properties
    @Published var currentStage: WorkoutStage = .idle
    @Published var currentSession: TrainingSession?
    @Published var isSessionActive: Bool = false
    @Published var stageProgress: Double = 0.0
    @Published var currentDistance: Double = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var sessionSummary: WorkoutSessionSummary?
    
    // MARK: - Managers
    private let timerManager = WorkoutTimerManager.shared
    private let gpsManager = WorkoutGPSManager.shared
    private let voiceHapticsManager = VoiceHapticsManager.shared
    private let algorithmEngine = WorkoutAlgorithmEngine.shared
    private let dataRecorder = WorkoutDataRecorder.shared
    
    // MARK: - Session State
    private var currentStageIndex: Int = 0
    private var sessionStages: [WorkoutStageConfig] = []
    private var sessionStartTime: Date?
    private var stageStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
    }
    
    // MARK: - Session Control
    func startSession(_ session: TrainingSession) {
        guard !isSessionActive else { return }
        
        print("🏃‍♂️ Starting automated workout session: \(session.type)")
        
        currentSession = session
        sessionStages = algorithmEngine.generateStageConfigs(for: session)
        currentStageIndex = 0
        sessionStartTime = Date()
        isSessionActive = true
        
        // Initialize all managers
        dataRecorder.startRecording(session: session)
        voiceHapticsManager.sessionWelcome(session: session)
        
        // Start first stage
        advanceToNextStage()
    }
    
    func pauseSession() {
        guard isSessionActive else { return }
        
        timerManager.pauseTimer()
        gpsManager.pauseTracking()
        voiceHapticsManager.sessionPaused()
        
        print("⏸️ Session paused")
    }
    
    func resumeSession() {
        guard isSessionActive else { return }
        
        timerManager.resumeTimer()
        gpsManager.resumeTracking()
        voiceHapticsManager.sessionResumed()
        
        print("▶️ Session resumed")
    }
    
    func endSession() {
        guard isSessionActive else { return }
        
        print("🏁 Ending workout session")
        
        // Stop all managers
        timerManager.stopTimer()
        gpsManager.stopTracking()
        
        // Generate session summary
        generateSessionSummary()
        
        // Save session data
        dataRecorder.endRecording()
        
        // Reset state
        isSessionActive = false
        currentStage = .idle
        currentStageIndex = 0
        sessionStages = []
        stageProgress = 0.0
        
        voiceHapticsManager.sessionComplete(summary: sessionSummary)
    }
    
    // MARK: - Stage Management
    private func advanceToNextStage() {
        guard currentStageIndex < sessionStages.count else {
            endSession()
            return
        }
        
        let stageConfig = sessionStages[currentStageIndex]
        currentStage = stageConfig.stage
        stageStartTime = Date()
        stageProgress = 0.0
        
        print("📍 Starting stage: \(stageConfig.stage.rawValue)")
        
        // Configure stage based on type
        switch stageConfig.stage {
        case .warmUp, .cooldown:
            startTimerStage(config: stageConfig)
        case .drills, .strides, .sprints:
            startDistanceStage(config: stageConfig)
        case .recovery:
            startRecoveryStage(config: stageConfig)
        case .idle:
            break
        }
        
        voiceHapticsManager.stageStarted(stage: stageConfig)
    }
    
    private func startTimerStage(config: WorkoutStageConfig) {
        timerManager.startTimer(
            duration: config.duration,
            onProgress: { [weak self] progress in
                self?.stageProgress = progress
            },
            onComplete: { [weak self] in
                self?.completeCurrentStage()
            }
        )
    }
    
    private func startDistanceStage(config: WorkoutStageConfig) {
        gpsManager.startDistanceTracking(
            targetDistance: config.targetDistance,
            onProgress: { [weak self] distance, progress in
                self?.currentDistance = distance
                self?.stageProgress = progress
            },
            onComplete: { [weak self] finalDistance, time in
                self?.currentDistance = finalDistance
                self?.currentTime = time
                self?.completeCurrentStage()
            }
        )
    }
    
    private func startRecoveryStage(config: WorkoutStageConfig) {
        let recoveryTime = algorithmEngine.calculateRecoveryTime(
            for: config,
            lastSprintTime: currentTime
        )
        
        timerManager.startTimer(
            duration: recoveryTime,
            onProgress: { [weak self] progress in
                self?.stageProgress = progress
            },
            onComplete: { [weak self] in
                self?.completeCurrentStage()
            }
        )
        
        voiceHapticsManager.recoveryStarted(duration: recoveryTime)
    }
    
    private func completeCurrentStage() {
        let stageConfig = sessionStages[currentStageIndex]
        let stageTime = Date().timeIntervalSince(stageStartTime ?? Date())
        
        print("✅ Stage complete: \(stageConfig.stage.rawValue) in \(stageTime)s")
        
        // Record stage data
        dataRecorder.recordStage(
            stage: stageConfig.stage,
            distance: currentDistance,
            time: stageTime,
            targetDistance: stageConfig.targetDistance
        )
        
        // Update algorithm with performance data
        algorithmEngine.updatePerformance(
            stage: stageConfig.stage,
            actualTime: stageTime,
            targetTime: stageConfig.predictedTime,
            distance: currentDistance
        )
        
        voiceHapticsManager.stageCompleted(stage: stageConfig, time: stageTime)
        
        // Move to next stage
        currentStageIndex += 1
        
        // Brief pause before next stage
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.advanceToNextStage()
        }
    }
    
    // MARK: - Session Summary
    private func generateSessionSummary() {
        guard let session = currentSession,
              let startTime = sessionStartTime else { return }
        
        let totalTime = Date().timeIntervalSince(startTime)
        let stageData = dataRecorder.getStageData()
        
        sessionSummary = WorkoutSessionSummary(
            session: session,
            totalTime: totalTime,
            stageData: stageData,
            fastestSplit: stageData.compactMap { $0.time }.min() ?? 0,
            averagePace: calculateAveragePace(stageData),
            recoveryEfficiency: calculateRecoveryEfficiency(stageData),
            suggestedNextLevel: algorithmEngine.suggestNextLevel()
        )
    }
    
    private func calculateAveragePace(_ stageData: [WorkoutStageData]) -> Double {
        let sprintStages = stageData.filter { $0.stage == .sprints }
        guard !sprintStages.isEmpty else { return 0 }
        
        let totalTime = sprintStages.reduce(0) { $0 + $1.time }
        return totalTime / Double(sprintStages.count)
    }
    
    private func calculateRecoveryEfficiency(_ stageData: [WorkoutStageData]) -> Double {
        // Calculate based on heart rate recovery if available
        // For now, return a baseline efficiency
        return 0.85
    }
    
    // MARK: - Subscriptions
    private func setupSubscriptions() {
        // Listen for GPS updates
        gpsManager.$currentLocation
            .sink { [weak self] location in
                // Handle location updates if needed
                guard let self = self else { return }
                // Use self here for future location processing
                _ = self // Suppress warning until location processing is implemented
            }
            .store(in: &cancellables)
        
        // Listen for timer updates
        timerManager.$remainingTime
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)
    }
}

// MARK: - Workout Stage Enum
enum WorkoutStage: String, CaseIterable {
    case idle = "Idle"
    case warmUp = "Warm-Up"
    case drills = "Drills"
    case strides = "Strides"
    case sprints = "Sprints"
    case recovery = "Recovery"
    case cooldown = "Cooldown"
}

// MARK: - Workout Stage Configuration
struct WorkoutStageConfig {
    let stage: WorkoutStage
    let duration: TimeInterval
    let targetDistance: Double // in yards
    let predictedTime: TimeInterval
    let intensity: String
    let instructions: String
}

// MARK: - Workout Session Summary
struct WorkoutSessionSummary {
    let session: TrainingSession
    let totalTime: TimeInterval
    let stageData: [WorkoutStageData]
    let fastestSplit: TimeInterval
    let averagePace: Double
    let recoveryEfficiency: Double
    let suggestedNextLevel: String
}

// MARK: - Workout Stage Data
struct WorkoutStageData {
    let stage: WorkoutStage
    let distance: Double
    let time: TimeInterval
    let targetDistance: Double
    let timestamp: Date
}
