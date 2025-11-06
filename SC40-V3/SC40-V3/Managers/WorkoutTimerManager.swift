import Foundation
import Combine

// MARK: - Workout Timer Manager
// Handles countdowns for warm-ups, rests, and cooldowns with automatic transitions

class WorkoutTimerManager: ObservableObject {
    static let shared = WorkoutTimerManager()
    
    // MARK: - Published Properties
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var progress: Double = 0.0
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var onProgressCallback: ((Double) -> Void)?
    private var onCompleteCallback: (() -> Void)?
    private var onWarningCallback: ((TimeInterval) -> Void)?
    
    // MARK: - Timer Configuration
    private let warningThresholds: [TimeInterval] = [10, 5, 3, 2, 1] // Warning at these seconds
    private var warningsTriggered: Set<Int> = []
    
    private init() {}
    
    // MARK: - Timer Control
    func startTimer(
        duration: TimeInterval,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping () -> Void,
        onWarning: ((TimeInterval) -> Void)? = nil
    ) {
        stopTimer() // Stop any existing timer
        
        print("⏱️ Starting timer for \(duration) seconds")
        
        totalDuration = duration
        remainingTime = duration
        pausedTime = 0
        startTime = Date()
        isRunning = true
        isPaused = false
        warningsTriggered.removeAll()
        
        onProgressCallback = onProgress
        onCompleteCallback = onComplete
        onWarningCallback = onWarning
        
        // Start the timer with 0.1 second precision
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        
        // Trigger initial progress
        updateProgress()
    }
    
    func pauseTimer() {
        guard isRunning && !isPaused else { return }
        
        print("⏸️ Timer paused")
        
        isPaused = true
        pausedTime = Date().timeIntervalSince(startTime ?? Date())
        timer?.invalidate()
        timer = nil
    }
    
    func resumeTimer() {
        guard isRunning && isPaused else { return }
        
        print("▶️ Timer resumed")
        
        isPaused = false
        startTime = Date().addingTimeInterval(-pausedTime)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func stopTimer() {
        print("⏹️ Timer stopped")
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingTime = 0
        totalDuration = 0
        progress = 0
        pausedTime = 0
        warningsTriggered.removeAll()
        
        onProgressCallback = nil
        onCompleteCallback = nil
        onWarningCallback = nil
    }
    
    func addTime(_ seconds: TimeInterval) {
        guard isRunning else { return }
        
        totalDuration += seconds
        remainingTime += seconds
        updateProgress()
        
        print("⏱️ Added \(seconds) seconds to timer")
    }
    
    // MARK: - Timer Updates
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        remainingTime = max(0, totalDuration - elapsed)
        
        updateProgress()
        checkWarnings()
        
        if remainingTime <= 0 {
            completeTimer()
        }
    }
    
    private func updateProgress() {
        if totalDuration > 0 {
            progress = min(1.0, max(0.0, (totalDuration - remainingTime) / totalDuration))
        } else {
            progress = 0.0
        }
        
        onProgressCallback?(progress)
    }
    
    private func checkWarnings() {
        for threshold in warningThresholds {
            let thresholdInt = Int(threshold)
            
            if remainingTime <= threshold && 
               remainingTime > threshold - 0.2 && 
               !warningsTriggered.contains(thresholdInt) {
                
                warningsTriggered.insert(thresholdInt)
                onWarningCallback?(threshold)
                
                print("⚠️ Timer warning: \(thresholdInt) seconds remaining")
            }
        }
    }
    
    private func completeTimer() {
        print("✅ Timer completed")
        
        let callback = onCompleteCallback
        stopTimer()
        callback?()
    }
    
    // MARK: - Utility Methods
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%d.%d", seconds, milliseconds)
        }
    }
    
    func formatTimeDetailed(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%02d", seconds, milliseconds)
        }
    }
    
    // MARK: - Preset Timers
    func startWarmupTimer(duration: TimeInterval = 300, onComplete: @escaping () -> Void) {
        startTimer(
            duration: duration,
            onProgress: { progress in
                print("🔥 Warmup progress: \(Int(progress * 100))%")
            },
            onComplete: onComplete,
            onWarning: { remaining in
                VoiceHapticsManager.shared.timerWarning(remaining: remaining, stage: .warmUp)
            }
        )
    }
    
    func startRecoveryTimer(duration: TimeInterval, onComplete: @escaping () -> Void) {
        startTimer(
            duration: duration,
            onProgress: { progress in
                print("💤 Recovery progress: \(Int(progress * 100))%")
            },
            onComplete: onComplete,
            onWarning: { remaining in
                VoiceHapticsManager.shared.timerWarning(remaining: remaining, stage: .recovery)
            }
        )
    }
    
    func startCooldownTimer(duration: TimeInterval = 300, onComplete: @escaping () -> Void) {
        startTimer(
            duration: duration,
            onProgress: { progress in
                print("🧊 Cooldown progress: \(Int(progress * 100))%")
            },
            onComplete: onComplete,
            onWarning: { remaining in
                VoiceHapticsManager.shared.timerWarning(remaining: remaining, stage: .cooldown)
            }
        )
    }
    
    // MARK: - Advanced Timer Features
    func startIntervalTimer(
        workDuration: TimeInterval,
        restDuration: TimeInterval,
        intervals: Int,
        onWorkStart: @escaping () -> Void,
        onRestStart: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        var currentInterval = 0
        var isWorkPhase = true
        
        func startNextPhase() {
            if isWorkPhase {
                onWorkStart()
                startTimer(
                    duration: workDuration,
                    onProgress: { _ in },
                    onComplete: {
                        isWorkPhase = false
                        if currentInterval < intervals - 1 {
                            startNextPhase()
                        } else {
                            onComplete()
                        }
                    }
                )
            } else {
                onRestStart()
                startTimer(
                    duration: restDuration,
                    onProgress: { _ in },
                    onComplete: {
                        isWorkPhase = true
                        currentInterval += 1
                        startNextPhase()
                    }
                )
            }
        }
        
        startNextPhase()
    }
}

// MARK: - Timer Extensions
extension WorkoutTimerManager {
    
    // MARK: - Countdown Announcements
    func shouldAnnounceCountdown(at time: TimeInterval) -> Bool {
        let announcePoints: [TimeInterval] = [60, 30, 10, 5, 3, 2, 1]
        return announcePoints.contains { abs($0 - time) < 0.2 }
    }
    
    // MARK: - Timer State
    var timeRemaining: String {
        formatTime(remainingTime)
    }
    
    var timeElapsed: TimeInterval {
        totalDuration - remainingTime
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    // MARK: - Timer Validation
    var isValid: Bool {
        isRunning && remainingTime >= 0
    }
    
    var canPause: Bool {
        isRunning && !isPaused
    }
    
    var canResume: Bool {
        isRunning && isPaused
    }
}
