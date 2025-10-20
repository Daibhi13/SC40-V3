import Foundation
import AVFoundation
import Combine

#if os(iOS)
import UIKit
#endif

// MARK: - Voice & Haptics Manager
// Communicates all instructions via voice prompts and haptic feedback

class VoiceHapticsManager: ObservableObject {
    static let shared = VoiceHapticsManager()
    
    // MARK: - Published Properties
    @Published var isVoiceEnabled: Bool = true
    @Published var isHapticsEnabled: Bool = true
    @Published var voiceVolume: Float = 0.8
    @Published var isSpeaking: Bool = false
    
    // MARK: - Voice Synthesis
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var speechQueue: [String] = []
    private var isProcessingQueue: Bool = false
    
    // MARK: - Haptic Feedback
    #if os(iOS)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif
    
    private init() {
        setupAudioSession()
        setupSpeechSynthesizer()
        prepareHaptics()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }
    
    private func setupSpeechSynthesizer() {
        speechSynthesizer.delegate = self
    }
    
    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Voice Commands
    private func speak(_ text: String, priority: SpeechPriority = .normal) {
        guard isVoiceEnabled else { return }
        
        print("🗣️ Speaking: \(text)")
        
        if priority == .high {
            // Stop current speech and speak immediately
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
            speakImmediately(text)
        } else {
            // Add to queue
            speechQueue.append(text)
            processQueue()
        }
    }
    
    private func speakImmediately(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = voiceVolume
        
        isSpeaking = true
        speechSynthesizer.speak(utterance)
    }
    
    private func processQueue() {
        guard !isProcessingQueue && !speechQueue.isEmpty && !isSpeaking else { return }
        
        isProcessingQueue = true
        let text = speechQueue.removeFirst()
        speakImmediately(text)
    }
    
    // MARK: - Haptic Patterns
    private func haptic(_ pattern: HapticPattern) {
        guard isHapticsEnabled else { return }
        
        switch pattern {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .doublePulse:
            impactMedium.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactMedium.impactOccurred()
            }
        case .longBuzz:
            impactHeavy.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.impactHeavy.impactOccurred()
            }
        case .gentlePulse:
            impactLight.impactOccurred()
        }
    }
    
    // MARK: - Session Commands
    func sessionWelcome(session: TrainingSession) {
        speak("Let's begin your \(session.type.lowercased()) training session.")
        haptic(.medium)
    }
    
    func sessionPaused() {
        speak("Session paused.", priority: .high)
        haptic(.warning)
    }
    
    func sessionResumed() {
        speak("Session resumed.")
        haptic(.medium)
    }
    
    func sessionComplete(summary: WorkoutSessionSummary?) {
        let message = "Session complete. Great work!"
        speak(message)
        haptic(.success)
        
        // Additional summary if available
        if let summary = summary {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let summaryText = "Your fastest split was \(self.formatTime(summary.fastestSplit))."
                self.speak(summaryText)
            }
        }
    }
    
    // MARK: - Stage Commands
    func stageStarted(stage: WorkoutStageConfig) {
        let message = getStageStartMessage(stage)
        speak(message)
        haptic(getStageStartHaptic(stage.stage))
    }
    
    func stageCompleted(stage: WorkoutStageConfig, time: TimeInterval) {
        let message = getStageCompleteMessage(stage.stage, time: time)
        speak(message)
        haptic(.success)
    }
    
    private func getStageStartMessage(_ stage: WorkoutStageConfig) -> String {
        switch stage.stage {
        case .warmUp:
            return "Let's begin your warm-up. Take it easy for the next \(Int(stage.duration / 60)) minutes."
        case .drills:
            return "Get ready for drills. \(stage.instructions)"
        case .strides:
            return "Time for strides. Run \(Int(stage.targetDistance)) yards at 70% effort."
        case .sprints:
            return "Sprint time! Give me \(Int(stage.targetDistance)) yards at \(stage.intensity) effort."
        case .recovery:
            return "Recovery time. Walk it off and breathe easy."
        case .cooldown:
            return "Cool down time. Ease down and breathe for the next \(Int(stage.duration / 60)) minutes."
        case .idle:
            return ""
        }
    }
    
    private func getStageCompleteMessage(_ stage: WorkoutStage, time: TimeInterval) -> String {
        switch stage {
        case .warmUp:
            return "Warm-up complete. You're ready to go."
        case .drills:
            return "Drills complete. Nice work."
        case .strides:
            return "Stride complete in \(formatTime(time)). Well done."
        case .sprints:
            return "Sprint complete! Time: \(formatTime(time)). Excellent effort."
        case .recovery:
            return "Recovery complete. Ready for the next one."
        case .cooldown:
            return "Cool down complete. Great session."
        case .idle:
            return ""
        }
    }
    
    private func getStageStartHaptic(_ stage: WorkoutStage) -> HapticPattern {
        switch stage {
        case .warmUp, .cooldown:
            return .gentlePulse
        case .drills, .strides:
            return .medium
        case .sprints:
            return .doublePulse
        case .recovery:
            return .light
        case .idle:
            return .light
        }
    }
    
    // MARK: - Timer Commands
    func timerWarning(remaining: TimeInterval, stage: WorkoutStage) {
        let seconds = Int(remaining)
        
        if seconds <= 3 {
            speak("\(seconds)", priority: .high)
            haptic(.warning)
        } else if seconds == 5 {
            speak("5 seconds")
            haptic(.medium)
        } else if seconds == 10 {
            speak("10 seconds remaining")
            haptic(.light)
        }
    }
    
    func recoveryStarted(duration: TimeInterval) {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            speak("Recover for \(minutes) minutes and \(seconds) seconds.")
        } else {
            speak("Recover for \(seconds) seconds.")
        }
        
        haptic(.gentlePulse)
        
        // Gentle pulse every 10 seconds during recovery
        startRecoveryPulses(duration: duration)
    }
    
    private func startRecoveryPulses(duration: TimeInterval) {
        let pulseInterval: TimeInterval = 10.0
        let totalPulses = Int(duration / pulseInterval)
        
        for i in 1...totalPulses {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(i) * pulseInterval) {
                self.haptic(.gentlePulse)
            }
        }
    }
    
    // MARK: - Movement Commands
    func movementDetected() {
        speak("Go!", priority: .high)
        haptic(.doublePulse)
    }
    
    func distanceWarning(remaining: Double) {
        let yards = Int(remaining)
        
        if yards <= 10 && yards > 0 {
            speak("\(yards) yards left")
            haptic(.medium)
        }
    }
    
    func sprintComplete(distance: Double, time: TimeInterval) {
        speak("Stop! Well done. Time: \(formatTime(time))")
        haptic(.longBuzz)
    }
    
    // MARK: - Countdown Commands
    func startCountdown(from: Int, onComplete: @escaping () -> Void) {
        guard from > 0 else {
            onComplete()
            return
        }
        
        func countdown(_ count: Int) {
            if count > 0 {
                speak("\(count)", priority: .high)
                haptic(.medium)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    countdown(count - 1)
                }
            } else {
                speak("Go!", priority: .high)
                haptic(.doublePulse)
                onComplete()
            }
        }
        
        countdown(from)
    }
    
    // MARK: - Performance Commands
    func personalBest(time: TimeInterval) {
        speak("Personal best! \(formatTime(time)). Outstanding!")
        haptic(.success)
    }
    
    func goodPerformance(improvement: Double) {
        speak("Great improvement! \(String(format: "%.1f", improvement))% faster.")
        haptic(.success)
    }
    
    func encouragement() {
        let messages = [
            "Keep it up!",
            "You've got this!",
            "Strong finish!",
            "Push through!",
            "Almost there!"
        ]
        
        speak(messages.randomElement() ?? "Keep going!")
        haptic(.medium)
    }
    
    // MARK: - Utility Methods
    private func formatTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.2f seconds", time)
        } else {
            let minutes = Int(time / 60)
            let seconds = time.truncatingRemainder(dividingBy: 60)
            return String(format: "%d minutes and %.1f seconds", minutes, seconds)
        }
    }
    
    // MARK: - Settings
    func setVoiceEnabled(_ enabled: Bool) {
        isVoiceEnabled = enabled
        if !enabled {
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
        }
    }
    
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
    }
    
    func setVoiceVolume(_ volume: Float) {
        voiceVolume = max(0.0, min(1.0, volume))
    }
    
    // MARK: - Emergency Commands
    func emergencyStop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        speak("Workout stopped.", priority: .high)
        haptic(.error)
    }
    
    func testVoice() {
        speak("Voice test. Sprint Coach 40 is ready to guide your training.")
        haptic(.medium)
    }
    
    func testHaptics() {
        haptic(.doublePulse)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceHapticsManager: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isProcessingQueue = false
        
        // Process next item in queue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.processQueue()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isProcessingQueue = false
    }
}

// MARK: - Supporting Enums
enum HapticPattern {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case doublePulse
    case longBuzz
    case gentlePulse
}

enum SpeechPriority {
    case normal
    case high
}
