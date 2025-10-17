import AVFoundation

/// Plays audio cues for the workout.
class AudioCueManager: @unchecked Sendable {
    static let shared = AudioCueManager()
    private var player: AVAudioPlayer?

    func playCue(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
