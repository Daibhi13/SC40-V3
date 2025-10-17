import Foundation
import AVFoundation
import Combine

// MARK: - Audio Cue Manager
class AudioCueManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isPlaying = false
    @Published var currentCue: String?
    
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private let speechQueue = DispatchQueue(label: "com.sc40.audioQueue")
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Speech Synthesis
    func speak(_ text: String, rate: Float = 0.5, pitch: Float = 1.0, volume: Float = 0.8) {
        guard !isPlaying else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        speechQueue.async {
            DispatchQueue.main.async {
                self.currentCue = text
                self.isPlaying = true
                self.synthesizer.speak(utterance)
            }
        }
    }
    
    // MARK: - Predefined Cues
    func speakWorkoutStart() {
        speak("Workout starting. Get ready!", rate: 0.6)
    }
    
    func speakSetStart(setNumber: Int, totalSets: Int) {
        speak("Set \(setNumber) of \(totalSets). On your marks!", rate: 0.5)
    }
    
    func speakRepStart(repNumber: Int, totalReps: Int) {
        speak("Rep \(repNumber) of \(totalReps). Go!", rate: 0.4)
    }
    
    func speakRestStart(duration: TimeInterval) {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            speak("Rest for \(minutes) minutes \(seconds) seconds", rate: 0.5)
        } else {
            speak("Rest for \(seconds) seconds", rate: 0.5)
        }
    }
    
    func speakRestEnd() {
        speak("Rest complete. Next set starting!", rate: 0.5)
    }
    
    func speakWorkoutComplete() {
        speak("Workout complete! Great job!", rate: 0.6)
    }
    
    func speakEncouragement() {
        let encouragements = [
            "You're doing great! Keep it up!",
            "Push through! Almost there!",
            "Excellent form! Stay focused!",
            "You're crushing this workout!",
            "Dig deep! You've got this!"
        ]
        
        let randomEncouragement = encouragements.randomElement() ?? encouragements[0]
        speak(randomEncouragement, rate: 0.5)
    }
    
    // MARK: - Countdown Timer
    func startCountdown(from count: Int, completion: @escaping () -> Void) {
        guard count > 0 else {
            completion()
            return
        }
        
        speak("\(count)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startCountdown(from: count - 1, completion: completion)
        }
    }
    
    // MARK: - Pace Guidance
    func speakPaceGuidance(currentPace: TimeInterval, targetPace: TimeInterval) {
        let paceDifference = currentPace - targetPace
        
        if paceDifference > 2.0 {
            speak("Slow down slightly. You're ahead of pace.", rate: 0.5)
        } else if paceDifference < -2.0 {
            speak("Pick up the pace. You're behind target.", rate: 0.5)
        } else {
            speak("Perfect pace! Keep it steady.", rate: 0.5)
        }
    }
    
    // MARK: - Heart Rate Alerts
    func speakHeartRateAlert(currentHR: Double, maxHR: Double) {
        let percentage = (currentHR / maxHR) * 100
        
        switch percentage {
        case 90...100:
            speak("Heart rate very high. Consider slowing down.", rate: 0.4)
        case 80..<90:
            speak("Heart rate elevated. Monitor your pace.", rate: 0.5)
        default:
            break
        }
    }
    
    // MARK: - Sound Effects
    func playStartSound() {
        playSystemSound(named: "begin_record.caf")
    }
    
    func playEndSound() {
        playSystemSound(named: "end_record.caf")
    }
    
    func playRestSound() {
        playSystemSound(named: "tick.caf")
    }
    
    private func playSystemSound(named soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: nil) ??
                            Bundle.main.url(forResource: soundName, withExtension: "wav") ??
                            Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = 0.3
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Control Methods
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentCue = nil
    }
    
    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func resumeSpeaking() {
        synthesizer.continueSpeaking()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentCue = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentCue = nil
        }
    }
}
