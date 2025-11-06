import AVFoundation
#if os(watchOS)
import WatchKit
#endif

/// Plays audio cues for the workout.
class AudioCueManager: @unchecked Sendable {
    static let shared = AudioCueManager()
    private var player: AVAudioPlayer?
    private var audioSessionConfigured = false

    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(watchOS)
        // Configure audio session for Watch
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
            audioSessionConfigured = true
            print("🔊 Watch audio session configured successfully")
        } catch {
            print("❌ Watch audio session setup failed: \(error)")
            audioSessionConfigured = false
        }
        #endif
    }

    func playCue(named name: String) {
        // Check if audio session is configured
        guard audioSessionConfigured else {
            print("⚠️ Audio session not configured, using haptic feedback instead")
            playHapticFeedback()
            return
        }
        
        // Try different audio file extensions
        let extensions = ["mp3", "wav", "m4a", "aiff"]
        var audioURL: URL?
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                audioURL = url
                break
            }
        }
        
        guard let url = audioURL else {
            print("⚠️ Audio file '\(name)' not found, using haptic feedback instead")
            playHapticFeedback()
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            
            // Validate audio buffer before playing
            guard let player = player, player.duration > 0 else {
                print("❌ Invalid audio file '\(name)' - zero duration, using haptic feedback")
                playHapticFeedback()
                return
            }
            
            let success = player.play()
            if success {
                print("🔊 Playing audio cue: \(name)")
            } else {
                print("❌ Failed to play audio cue '\(name)', using haptic feedback")
                playHapticFeedback()
            }
        } catch {
            print("❌ Audio playback error for '\(name)': \(error), using haptic feedback")
            playHapticFeedback()
        }
    }
    
    private func playHapticFeedback() {
        #if os(watchOS)
        // Use haptic feedback as fallback when audio fails
        WKInterfaceDevice.current().play(.notification)
        print("📳 Haptic feedback played as audio fallback")
        #endif
    }
    
    func stopAudio() {
        player?.stop()
        player = nil
    }
}
