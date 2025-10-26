import Foundation
import AVFoundation
import Combine
import WatchKit

// Watch-compatible stub for WorkoutMusicManager
// Note: Full music functionality requires iOS MediaPlayer framework

@MainActor
class WorkoutMusicManager: NSObject, ObservableObject {
    static let shared = WorkoutMusicManager()
    
    // MARK: - Published Properties (Watch Compatible)
    @Published var isPlaying: Bool = false
    @Published var playbackTime: TimeInterval = 0
    @Published var volume: Float = 0.7
    @Published var isShuffleEnabled: Bool = true
    @Published var repeatMode: RepeatMode = .off
    
    // Music sync settings
    @Published var autoSyncEnabled: Bool = true
    @Published var fadeTransitions: Bool = true
    @Published var hapticSync: Bool = true
    
    // MARK: - Private Properties
    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum RepeatMode: String, CaseIterable {
        case off = "Off"
        case one = "Repeat One"
        case all = "Repeat All"
    }
    
    enum WorkoutPhase {
        case warmup, sprint, recovery, cooldown, rest
        
        var targetBPMRange: ClosedRange<Int> {
            switch self {
            case .warmup: return 100...120
            case .sprint: return 140...180
            case .recovery: return 80...110
            case .cooldown: return 60...90
            case .rest: return 70...100
            }
        }
    }
    
    override init() {
        super.init()
        print("🎵 WorkoutMusicManager initialized (Watch stub)")
    }
    
    // MARK: - Watch-Compatible Stub Methods
    
    func syncMusicToWorkout(_ phase: WorkoutPhase) {
        print("🎵 Music sync to \(phase) (Watch stub)")
    }
    
    func setupMusicForWorkout(_ session: TrainingSession) {
        print("🎵 Music setup for workout (Watch stub)")
    }
    
    func playCompletionMusic() {
        print("🎵 Playing completion music (Watch stub)")
    }
    
    func play() {
        isPlaying = true
        print("▶️ Music play (Watch stub)")
    }
    
    func pause() {
        isPlaying = false
        print("⏸️ Music pause (Watch stub)")
    }
    
    func stop() {
        isPlaying = false
        playbackTime = 0
        print("⏹️ Music stop (Watch stub)")
    }
    
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        print("🔊 Volume set to \(Int(self.volume * 100))% (Watch stub)")
    }
    
    func nextTrack() {
        print("⏭️ Next track (Watch stub)")
    }
    
    func previousTrack() {
        print("⏮️ Previous track (Watch stub)")
    }
    
    func toggleShuffle() {
        isShuffleEnabled.toggle()
        print("🔀 Shuffle \(isShuffleEnabled ? "enabled" : "disabled") (Watch stub)")
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .one
        case .one: repeatMode = .all
        case .all: repeatMode = .off
        }
        print("🔁 Repeat mode: \(repeatMode.rawValue) (Watch stub)")
    }
}

// MARK: - TrainingSession Compatibility

extension TrainingSession {
    var musicGenre: String {
        switch type.lowercased() {
        case let t where t.contains("sprint"): return "High Energy"
        case let t where t.contains("endurance"): return "Steady Beat"
        case let t where t.contains("recovery"): return "Calm"
        default: return "Motivational"
        }
    }
}
