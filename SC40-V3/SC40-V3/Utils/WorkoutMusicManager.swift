import Foundation
import AVFoundation
import Combine
#if canImport(WatchKit)
import WatchKit
#endif

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
    
    #if os(watchOS)
    @available(*, deprecated, message: "Use setupMusicForWorkoutSession(_:) on watchOS stub")
    func setupMusicForWorkout(_ session: TrainingSession) {
        // Forward to distinct name to avoid duplicate symbol with iOS implementation
        setupMusicForWorkoutSession(session)
    }

    /// Distinctly named stub to avoid redeclaration conflicts with iOS/macOS implementations
    func setupMusicForWorkoutSession(_ session: TrainingSession) {
        print("🎵 Music setup for workout (Watch stub)")
    }
    #else
    func setupMusicForWorkout(_ session: TrainingSession) {
        print("🎵 Music setup for workout (Watch stub)")
    }
    #endif
    
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
}

