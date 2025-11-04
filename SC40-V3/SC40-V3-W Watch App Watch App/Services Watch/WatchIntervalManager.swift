import Foundation
#if os(watchOS)
import WatchKit
#endif
import Combine
import AVFoundation

/// Native watch interval management system
/// Handles sprint countdown timers, rest periods, and automatic phase progression
class WatchIntervalManager: ObservableObject {
    static let shared = WatchIntervalManager()
    
    // MARK: - Published Properties
    @Published var currentPhase: IntervalWorkoutPhase = .warmup
    @Published var currentInterval: Int = 0
    @Published var totalIntervals: Int = 0
    @Published var isActive = false
    @Published var isPaused = false
    
    // Timer states
    @Published var countdownTime: Int = 0 // For pre-sprint countdown (3-2-1-GO)
    @Published var sprintTime: TimeInterval = 0 // Current sprint duration
    @Published var restTime: TimeInterval = 0 // Current rest duration
    @Published var restTimeRemaining: TimeInterval = 0 // Rest countdown
    
    // Phase timing
    @Published var phaseStartTime: Date?
    @Published var totalWorkoutTime: TimeInterval = 0
    
    // MARK: - Private Properties
    private var countdownTimer: Timer?
    private var sprintTimer: Timer?
    private var restTimer: Timer?
    private var workoutTimer: Timer?
    
    private var sprintStartTime: Date?
    private var restStartTime: Date?
    private var workoutStartTime: Date?
    
    // Workout configuration
    private var workoutPlan: WorkoutPlan?
    private var currentIntervalIndex = 0
    
    // Haptic feedback
    #if os(watchOS)
    private let hapticDevice = WKInterfaceDevice.current()
    #endif
    
    // Audio feedback
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func playHapticStop() {
        #if os(watchOS)
        hapticDevice.play(.stop)
        #endif
    }
    
    private func playHapticStart() {
        #if os(watchOS)
        hapticDevice.play(.start)
        #endif
    }
    
    private func playHapticClick() {
        #if os(watchOS)
        hapticDevice.play(.click)
        #endif
    }
    
    private func playHapticSuccess() {
        #if os(watchOS)
        hapticDevice.play(.success)
        #endif
    }
    
    private func playHapticNotification() {
        #if os(watchOS)
        hapticDevice.play(.notification)
        #endif
    }
    
    // MARK: - Workout Control
    
    func startWorkout(plan: WorkoutPlan) {
        print("⏱️ Starting workout with \(plan.intervals.count) intervals")
        
        workoutPlan = plan
        totalIntervals = plan.intervals.count
        currentInterval = 0
        currentIntervalIndex = 0
        isActive = true
        isPaused = false
        workoutStartTime = Date()
        
        // Start with warmup phase
        currentPhase = .warmup
        startPhase(.warmup)
        
        // Start overall workout timer
        startWorkoutTimer()
        
        print("⏱️ Workout started successfully")
    }
    
    func pauseWorkout() {
        guard isActive && !isPaused else { return }
        
        print("⏸️ Pausing workout")
        isPaused = true
        
        // Pause all timers
        countdownTimer?.invalidate()
        sprintTimer?.invalidate()
        restTimer?.invalidate()
        
        // Haptic feedback
        playHapticStop()
    }
    
    func resumeWorkout() {
        guard isActive && isPaused else { return }
        
        print("▶️ Resuming workout")
        isPaused = false
        
        // Resume appropriate timer based on current phase
        switch currentPhase {
        case .countdown:
            startCountdown()
        case .sprint:
            resumeSprintTimer()
        case .rest:
            resumeRestTimer()
        default:
            break
        }
        
        // Haptic feedback
        playHapticStart()
    }
    
    func stopWorkout() {
        print("🛑 Stopping workout")
        
        isActive = false
        isPaused = false
        
        // Stop all timers
        stopAllTimers()
        
        // Reset state
        resetWorkoutState()
        
        // Haptic feedback
        playHapticStop()
        
        print("🛑 Workout stopped")
    }
    
    func skipToNextInterval() {
        guard isActive, let plan = workoutPlan else { return }
        
        print("⏭️ Skipping to next interval")
        
        // Stop current timers
        stopCurrentPhaseTimers()
        
        // Move to next interval
        if currentIntervalIndex < plan.intervals.count - 1 {
            currentIntervalIndex += 1
            currentInterval = currentIntervalIndex + 1
            startNextInterval()
        } else {
            // Workout complete
            completeWorkout()
        }
        
        // Haptic feedback
        playHapticClick()
    }
    
    // MARK: - Phase Management
    
    private func startPhase(_ phase: IntervalWorkoutPhase) {
        currentPhase = phase
        phaseStartTime = Date()
        
        print("🔄 Starting phase: \(phase.rawValue)")
        
        switch phase {
        case .warmup:
            startWarmupPhase()
        case .countdown:
            startCountdown()
        case .sprint:
            startSprintPhase()
        case .rest:
            startRestPhase()
        case .cooldown:
            startCooldownPhase()
        }
        
        // Voice announcement
        announcePhase(phase)
    }
    
    private func startWarmupPhase() {
        // Warmup duration (configurable)
        let warmupDuration: TimeInterval = 300 // 5 minutes
        
        DispatchQueue.main.asyncAfter(deadline: .now() + warmupDuration) { [weak self] in
            self?.startPhase(.countdown)
        }
    }
    
    private func startCountdown() {
        guard let plan = workoutPlan,
              currentIntervalIndex < plan.intervals.count else { return }
        
        print("⏰ Starting sprint countdown")
        
        countdownTime = 3
        currentPhase = .countdown
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.handleCountdownTick(timer)
        }
    }
    
    private func handleCountdownTick(_ timer: Timer) {
        // Note: self is not optional in instance methods
        // guard let self else { ... } is not needed here
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.countdownTime > 0 {
                print("⏰ Countdown: \(self.countdownTime)")
                
                // Haptic feedback for each count
                self.playHapticClick()
                
                // Voice countdown
                self.speakCountdown(self.countdownTime)
                
                self.countdownTime -= 1
            } else {
                // GO!
                timer.invalidate()
                self.countdownTimer = nil
                
                print("🏃‍♂️ GO!")
                self.playHapticStart()
                self.speak("Go!")
                
                self.startPhase(.sprint)
            }
        }
    }
    
    private func startSprintPhase() {
        guard let plan = workoutPlan,
              currentIntervalIndex < plan.intervals.count else { return }
        
        let interval = plan.intervals[currentIntervalIndex]
        
        print("🏃‍♂️ Starting sprint: \(interval.distance)yd")
        
        sprintStartTime = Date()
        sprintTime = 0
        currentPhase = .sprint
        
        // Start sprint timer
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let startTime = self.sprintStartTime else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                self.sprintTime = Date().timeIntervalSince(startTime)
            }
        }
        
        // Auto-transition after maximum sprint time (safety)
        let maxSprintTime: TimeInterval = 30.0 // 30 seconds max
        DispatchQueue.main.asyncAfter(deadline: .now() + maxSprintTime) { [weak self] in
            if self?.currentPhase == .sprint {
                print("⚠️ Sprint auto-ended after max time")
                self?.endSprint()
            }
        }
    }
    
    func endSprint() {
        guard currentPhase == .sprint else { return }
        
        print("🏁 Sprint completed in \(String(format: "%.2f", sprintTime))s")
        
        // Stop sprint timer
        sprintTimer?.invalidate()
        sprintTimer = nil
        
        // Haptic feedback
        playHapticSuccess()
        
        // Voice feedback
        speak("Sprint complete")
        
        // Transition to rest or next interval
        if let plan = workoutPlan,
           currentIntervalIndex < plan.intervals.count - 1 {
            startPhase(.rest)
        } else {
            completeWorkout()
        }
    }
    
    private func startRestPhase() {
        guard let plan = workoutPlan,
              currentIntervalIndex < plan.intervals.count else { return }
        
        let interval = plan.intervals[currentIntervalIndex]
        let restDuration = interval.restTime
        
        print("😴 Starting rest: \(Int(restDuration))s")
        
        restStartTime = Date()
        restTime = 0
        restTimeRemaining = restDuration
        currentPhase = .rest
        
        // Start rest timer
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.handleRestTick(timer, restDuration: restDuration)
        }
    }
    
    private func handleRestTick(_ timer: Timer, restDuration: TimeInterval) {
        guard let startTime = self.restStartTime else {
            timer.invalidate()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.restTime = Date().timeIntervalSince(startTime)
            self.restTimeRemaining = max(0, restDuration - self.restTime)
            
            // Check if rest is complete
            if self.restTimeRemaining <= 0 {
                timer.invalidate()
                self.restTimer = nil
                self.endRest()
            } else if self.restTimeRemaining <= 10 {
                // Final 10 seconds countdown
                let currentSecond = Int(self.restTimeRemaining)
                let previousSecond = Int(self.restTimeRemaining + 1)
                
                if currentSecond != previousSecond {
                    self.playHapticClick()
                    if currentSecond <= 3 {
                        self.speakCountdown(currentSecond)
                    }
                }
            }
        }
    }
    
    private func endRest() {
        print("✅ Rest period complete")
        
        // Haptic feedback
        playHapticNotification()
        
        // Move to next interval
        startNextInterval()
    }
    
    private func startNextInterval() {
        guard let plan = workoutPlan else { return }
        
        if currentIntervalIndex < plan.intervals.count - 1 {
            currentIntervalIndex += 1
            currentInterval = currentIntervalIndex + 1
            
            print("➡️ Moving to interval \(currentInterval)/\(totalIntervals)")
            
            // Start countdown for next sprint
            startPhase(.countdown)
        } else {
            // All intervals complete
            completeWorkout()
        }
    }
    
    private func startCooldownPhase() {
        print("🧘‍♂️ Starting cooldown")
        
        currentPhase = .cooldown
        
        // Cooldown duration
        let cooldownDuration: TimeInterval = 300 // 5 minutes
        
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration) { [weak self] in
            self?.completeWorkout()
        }
    }
    
    private func completeWorkout() {
        print("🏆 Workout completed!")
        
        // Stop all timers
        stopAllTimers()
        
        // Haptic celebration
        playHapticSuccess()
        
        // Voice feedback
        speak("Workout complete! Great job!")
        
        // Reset state
        isActive = false
        currentPhase = .cooldown
        
        // Notify completion
        NotificationCenter.default.post(name: .workoutCompleted, object: nil)
    }
    
    // MARK: - Timer Management
    
    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.workoutStartTime else { return }
            
            DispatchQueue.main.async {
                self.totalWorkoutTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func resumeSprintTimer() {
        guard let startTime = sprintStartTime else { return }
        
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                self.sprintTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func resumeRestTimer() {
        guard let startTime = restStartTime,
              let plan = workoutPlan,
              currentIntervalIndex < plan.intervals.count else { return }
        
        let interval = plan.intervals[currentIntervalIndex]
        let restDuration = interval.restTime
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                self.restTime = Date().timeIntervalSince(startTime)
                self.restTimeRemaining = max(0, restDuration - self.restTime)
                
                if self.restTimeRemaining <= 0 {
                    timer.invalidate()
                    self.restTimer = nil
                    self.endRest()
                }
            }
        }
    }
    
    private func stopCurrentPhaseTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        sprintTimer?.invalidate()
        sprintTimer = nil
        
        restTimer?.invalidate()
        restTimer = nil
    }
    
    private func stopAllTimers() {
        stopCurrentPhaseTimers()
        
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    private func resetWorkoutState() {
        currentPhase = .warmup
        currentInterval = 0
        totalIntervals = 0
        countdownTime = 0
        sprintTime = 0
        restTime = 0
        restTimeRemaining = 0
        totalWorkoutTime = 0
        
        phaseStartTime = nil
        sprintStartTime = nil
        restStartTime = nil
        workoutStartTime = nil
        
        workoutPlan = nil
        currentIntervalIndex = 0
    }
    
    // MARK: - Audio Feedback
    
    private func announcePhase(_ phase: IntervalWorkoutPhase) {
        let message: String
        
        switch phase {
        case .warmup:
            message = "Starting warmup"
        case .countdown:
            message = "Get ready"
        case .sprint:
            message = "Sprint!"
        case .rest:
            message = "Rest period"
        case .cooldown:
            message = "Cool down"
        }
        
        speak(message)
    }
    
    private func speakCountdown(_ count: Int) {
        speak("\(count)")
    }
    
    private func speak(_ text: String) {
        // Use unified voice manager for consistent voice settings
        // Voice feedback (simplified)
        print("🗣️ Voice: \(text)")
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Data Access
    
    func getCurrentIntervalData() -> IntervalData? {
        guard let plan = workoutPlan,
              currentIntervalIndex < plan.intervals.count else { return nil }
        
        let interval = plan.intervals[currentIntervalIndex]
        
        return IntervalData(
            number: currentInterval,
            total: totalIntervals,
            distance: interval.distance,
            restTime: interval.restTime,
            currentPhase: currentPhase,
            sprintTime: sprintTime,
            restTimeRemaining: restTimeRemaining
        )
    }
    
    func getWorkoutProgress() -> WorkoutProgress {
        let progress = totalIntervals > 0 ? Double(currentInterval) / Double(totalIntervals) : 0.0
        
        return WorkoutProgress(
            currentInterval: currentInterval,
            totalIntervals: totalIntervals,
            progress: progress,
            totalTime: totalWorkoutTime,
            currentPhase: currentPhase
        )
    }
}

// MARK: - Supporting Data Models

enum IntervalWorkoutPhase: String, CaseIterable {
    case warmup = "warmup"
    case countdown = "countdown"
    case sprint = "sprint"
    case rest = "rest"
    case cooldown = "cooldown"
}

struct WorkoutPlan {
    let intervals: [IntervalConfig]
    let warmupTime: TimeInterval
    let cooldownTime: TimeInterval
}

struct IntervalConfig {
    let distance: Int // yards
    let restTime: TimeInterval // seconds
    let intensity: String
}

struct IntervalData {
    let number: Int
    let total: Int
    let distance: Int
    let restTime: TimeInterval
    let currentPhase: IntervalWorkoutPhase
    let sprintTime: TimeInterval
    let restTimeRemaining: TimeInterval
}

struct WorkoutProgress {
    let currentInterval: Int
    let totalIntervals: Int
    let progress: Double // 0.0 to 1.0
    let totalTime: TimeInterval
    let currentPhase: IntervalWorkoutPhase
}

// MARK: - Notification Names

extension Notification.Name {
    static let workoutCompleted = Notification.Name("workoutCompleted")
    static let intervalCompleted = Notification.Name("intervalCompleted")
    static let phaseChanged = Notification.Name("phaseChanged")
}
