import Foundation
import AVFoundation
import SwiftUI
import Combine

// MARK: - WorkoutPhase enum for audio integration
public enum AudioWorkoutPhase: String, CaseIterable {
    case warmup = "warmup"
    case stretch = "stretch"
    case drill = "drill"
    case strides = "strides"
    case sprints = "sprints"
    case resting = "resting"
    case cooldown = "cooldown"
    case completed = "completed"
}

// MARK: - Simple Audio Manager for Sprint Training
@MainActor
class SimpleAudioManager: NSObject, ObservableObject {
    
    static let shared = SimpleAudioManager()
    
    // MARK: - Published Properties
    @Published var isPlayingMusic: Bool = false
    @Published var isMusicEnabled: Bool = true
    @Published var isCoachingEnabled: Bool = true
    @Published var musicVolume: Float = 0.7
    @Published var coachingVolume: Float = 1.0
    
    // MARK: - Audio Components
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var musicPlayer: AVAudioPlayer?
    
    // MARK: - Motivational Cues
    private var lastCueTime: Date = Date()
    private let minCueInterval: TimeInterval = 30
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth])
            try audioSession.setActive(true)
            print("🔊 Audio session configured successfully")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    // MARK: - Music Control
    func startWorkoutMusic() {
        guard isMusicEnabled else { return }
        
        // For now, just indicate music is playing
        // In a full implementation, this would start Apple Music/Spotify
        isPlayingMusic = true
        playCoachingCue("Workout music started! Let's get energized! 🎵")
        print("🎵 Workout music started")
    }
    
    func pauseMusic() {
        isPlayingMusic = false
        musicPlayer?.pause()
    }
    
    func resumeMusic() {
        isPlayingMusic = true
        musicPlayer?.play()
    }
    
    func stopMusic() {
        isPlayingMusic = false
        musicPlayer?.stop()
    }
    
    // MARK: - Voice Coaching
    func playCoachingCue(_ message: String, priority: AudioCoachingPriority = .normal) {
        guard isCoachingEnabled else { return }
        
        // Check timing for non-critical cues
        let now = Date()
        if priority != .critical && now.timeIntervalSince(lastCueTime) < minCueInterval {
            return
        }
        lastCueTime = now
        
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = coachingVolume
        
        // Temporarily lower music for coaching
        if isPlayingMusic {
            let originalVolume = musicVolume
            musicPlayer?.volume = originalVolume * 0.3
            
            // Restore volume after speech
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.musicPlayer?.volume = originalVolume
            }
        }
        
        speechSynthesizer.speak(utterance)
        print("🗣️ Coaching: \(message)")
    }
    
    // MARK: - Workout Phase Integration
    func updateWorkoutPhase(_ phase: Any) {
        let message = getPhaseTransitionMessage(phase)
        playCoachingCue(message, priority: .critical)
    }
    
    private func getPhaseTransitionMessage(_ phase: Any) -> String {
        let phaseString = String(describing: phase).lowercased()
        
        if phaseString.contains("warmup") {
            return "Let's begin with a proper warm-up! Take your time and prepare your body."
        } else if phaseString.contains("stretch") {
            return "Time to stretch those muscles! Get ready for action."
        } else if phaseString.contains("drill") {
            return "Moving to drills! Focus on perfect form and technique."
        } else if phaseString.contains("strides") {
            return "Build-up strides! Gradually increase your speed."
        } else if phaseString.contains("sprints") {
            return "Sprint time! This is where you show your speed! Give it everything!"
        } else if phaseString.contains("resting") {
            return "Rest period. Recover well and prepare for the next rep!"
        } else if phaseString.contains("cooldown") {
            return "Cool down time! Great session! Let's help your body recover."
        } else if phaseString.contains("completed") {
            return "Workout complete! Outstanding effort! You're getting faster every day!"
        } else {
            return "Keep going! You're doing great! 💪"
        }
    }
    
    // MARK: - Sprint-Specific Coaching
    func handleSprintStart() {
        playCoachingCue("Sprint! Give it everything you've got! ⚡", priority: .critical)
        
        // Random motivational cue
        let motivationalCues = [
            "Explosive power! You've got this!",
            "Perfect form, maximum speed!",
            "Feel the speed! Dominate this sprint!",
            "Every step counts! Make it your best!"
        ]
        
        if let randomCue = motivationalCues.randomElement() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.playCoachingCue(randomCue, priority: .motivational)
            }
        }
    }
    
    func handleSprintComplete(time: Double) {
        let message: String
        
        if time < 4.5 {
            message = "Incredible speed! \(String(format: "%.2f", time)) seconds! You're flying! 🚀"
        } else if time < 5.5 {
            message = "Great sprint! \(String(format: "%.2f", time)) seconds! Solid performance! 💪"
        } else {
            message = "Good effort! \(String(format: "%.2f", time)) seconds! Keep pushing! 🔥"
        }
        
        playCoachingCue(message, priority: .normal)
    }
    
    func handleRepComplete(repNumber: Int, totalReps: Int) {
        if repNumber == totalReps {
            playCoachingCue("Final rep complete! Outstanding session! You crushed it! 🏆", priority: .critical)
        } else {
            let remaining = totalReps - repNumber
            playCoachingCue("Rep \(repNumber) complete! \(remaining) more to go! Stay strong! 💪", priority: .normal)
        }
    }
    
    // MARK: - Motivational Cues
    func playMotivationalCue(for phase: Any) {
        let phaseString = String(describing: phase).lowercased()
        let cues: [String]
        
        if phaseString.contains("warmup") {
            cues = [
                "Let's get those muscles ready for action! 🔥",
                "Perfect warm-up sets the stage for greatness!",
                "Feel that energy building up! You've got this!"
            ]
        } else if phaseString.contains("sprints") {
            cues = [
                "You're building speed with every rep! 🚀",
                "Channel that inner athlete! Sprint like lightning!",
                "This is where champions are made! Push harder!",
                "Perfect form, maximum speed! You're unstoppable!"
            ]
        } else if phaseString.contains("resting") {
            cues = [
                "Great work! Use this rest to prepare for greatness!",
                "Breathe deep, stay focused. Next rep will be better!",
                "Recovery is where the magic happens. Stay ready!"
            ]
        } else if phaseString.contains("cooldown") {
            cues = [
                "Outstanding session! Your speed is improving! 🌟",
                "You just got faster! Great job pushing your limits!",
                "Champions always finish strong. Excellent work!"
            ]
        } else {
            cues = ["Keep going! You're doing great! 💪"]
        }
        
        if let randomCue = cues.randomElement() {
            playCoachingCue(randomCue, priority: .motivational)
        }
    }
}

// MARK: - Supporting Types
enum AudioCoachingPriority {
    case critical      // Always plays (phase transitions, safety)
    case normal        // Respects timing intervals
    case motivational  // Motivational cues
}

// MARK: - Extensions for MainProgramWorkoutView Integration
extension SimpleAudioManager {
    
    /// Adjust volume settings
    func adjustMusicVolume(_ volume: Float) {
        musicVolume = volume
        musicPlayer?.volume = volume
    }
    
    func adjustCoachingVolume(_ volume: Float) {
        coachingVolume = volume
    }
    
    /// Enable/disable audio features
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopMusic()
        }
    }
    
    func setCoachingEnabled(_ enabled: Bool) {
        isCoachingEnabled = enabled
        if !enabled {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
