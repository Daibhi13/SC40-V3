//
//  AudioCueManager.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import AVFoundation
import Combine

/// Manages audio cues and guidance during workouts
class AudioCueManager: NSObject, ObservableObject {

    static let shared = AudioCueManager()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentCue: String?
    @Published private(set) var volume: Float = 0.7
    @Published private(set) var isMuted = false

    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var cueTimer: Timer?
    private var workoutTimer: Timer?
    private var currentWorkout: WorkoutSession?

    private let audioSession = AVAudioSession.sharedInstance()

    // MARK: - Audio Session Management

    /// Setup audio session for workout guidance
    func setupAudioSession() async throws {
        do {
            try audioSession.setCategory(.playAndRecord,
                                       mode: .default,
                                       options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            throw AudioCueError.audioSessionSetupFailed(error)
        }
    }

    // MARK: - Workout Audio Guidance

    /// Start audio guidance for a workout session
    func startWorkoutGuidance(for session: WorkoutSession) {
        currentWorkout = session

        // Setup workout timer for periodic updates
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.provideWorkoutUpdate()
        }

        // Start with initial cue
        speak("Workout started. Good luck!")
        currentCue = "Workout began"
    }

    /// Stop workout audio guidance
    func stopWorkoutGuidance() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        currentWorkout = nil

        speak("Workout completed. Great job!")
        currentCue = "Workout completed"
    }

    // MARK: - Sprint Set Audio Cues

    /// Provide audio cues for sprint set timing
    func startSprintSet(_ sprintSet: SprintSetConfiguration) {
        speak("Starting \(sprintSet.name). Get ready.")

        // Countdown before sprint
        provideCountdown(count: 3)

        // Start sprint timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.startSprintTimer(for: sprintSet)
        }
    }

    /// Start timing for a sprint with audio cues
    private func startSprintTimer(for sprintSet: SprintSetConfiguration) {
        var elapsedTime = 0.0
        let targetTime = sprintSet.targetTime

        cueTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            elapsedTime += 1.0

            // Provide time updates
            if elapsedTime <= targetTime {
                self?.provideSprintTimeUpdate(elapsed: elapsedTime, target: targetTime)
            }

            // Sprint completed
            if elapsedTime >= targetTime {
                timer.invalidate()
                self?.sprintCompleted(sprintSet)
            }
        }
    }

    /// Provide countdown before sprint
    private func provideCountdown(count: Int) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                self.speak("\(count - i)")
            }
        }
    }

    /// Provide time updates during sprint
    private func provideSprintTimeUpdate(elapsed: Double, target: Double) {
        let remaining = target - elapsed

        if remaining <= 3 && remaining > 0 {
            speak("\(Int(remaining))")
        } else if elapsed == target {
            speak("Sprint complete!")
        }
    }

    /// Handle sprint completion
    private func sprintCompleted(_ sprintSet: SprintSetConfiguration) {
        speak("Sprint completed. Rest for \(Int(sprintSet.restBetweenReps)) seconds.")
        currentCue = "Sprint completed - resting"
    }

    // MARK: - Periodic Workout Updates

    /// Provide workout progress updates
    private func provideWorkoutUpdate() {
        guard let workout = currentWorkout else { return }

        let elapsed = Date().timeIntervalSince(workout.startTime)
        let progress = min(elapsed / workout.estimatedDuration, 1.0)

        if progress >= 0.25 && progress < 0.3 {
            speak("Quarter way through workout. Keep it up!")
        } else if progress >= 0.5 && progress < 0.55 {
            speak("Halfway point. You're doing great!")
        } else if progress >= 0.75 && progress < 0.8 {
            speak("Three quarters complete. Almost there!")
        } else if progress >= 0.9 && progress < 0.95 {
            speak("Final stretch. Push through!")
        }
    }

    // MARK: - Audio Playback

    /// Speak text using text-to-speech
    func speak(_ text: String, rate: Float = 0.5, pitch: Float = 1.0) {
        guard !isMuted else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        speechSynthesizer.speak(utterance)
    }

    /// Play audio file for specific cues
    func playAudioCue(_ cueType: AudioCueType) {
        guard !isMuted, let url = Bundle.main.url(forResource: cueType.fileName, withExtension: "mp3") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.play()
        } catch {
            print("Failed to play audio cue: \(error.localizedDescription)")
        }
    }

    /// Set audio volume
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        audioPlayer?.volume = self.volume
    }

    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audioPlayer?.stop()
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - Audio Cue Types

    enum AudioCueType {
        case start
        case countdown
        case halfway
        case final
        case complete
        case rest
        case encouragement

        var fileName: String {
            switch self {
            case .start: return "start_tone"
            case .countdown: return "countdown_beep"
            case .halfway: return "halfway_chime"
            case .final: return "final_warning"
            case .complete: return "completion_bell"
            case .rest: return "rest_period"
            case .encouragement: return "encouragement"
            }
        }
    }

    // MARK: - Data Structures

    struct WorkoutSession {
        let startTime: Date
        let estimatedDuration: TimeInterval
        let name: String
    }

    // MARK: - Error Handling

    enum AudioCueError: Error {
        case audioSessionSetupFailed(Error)
        case audioFileNotFound
        case playbackFailed
    }
}
