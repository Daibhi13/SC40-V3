import Foundation
import MediaPlayer
import AVFoundation
import Combine

/// Enhanced music management system for workout-synchronized audio experience (iOS)
/// Provides direct Apple Music integration, BPM-matched playlists, and workout phase synchronization
@MainActor
class WorkoutMusicManager: NSObject, ObservableObject {
    static let shared = WorkoutMusicManager()
    
    // MARK: - Published Properties
    @Published var currentTrack: MPMediaItem?
    @Published var isPlaying: Bool = false
    @Published var playbackTime: TimeInterval = 0
    @Published var volume: Float = 0.7
    @Published var currentPlaylist: WorkoutPlaylist?
    @Published var isShuffleEnabled: Bool = true
    @Published var repeatMode: RepeatMode = .off
    
    // Workout-specific playlists
    @Published var sprintPlaylists: [WorkoutPlaylist] = []
    @Published var recoveryPlaylists: [WorkoutPlaylist] = []
    @Published var warmupPlaylists: [WorkoutPlaylist] = []
    @Published var cooldownPlaylists: [WorkoutPlaylist] = []
    
    // Music sync settings
    @Published var autoSyncEnabled: Bool = true
    @Published var fadeTransitions: Bool = true
    @Published var hapticSync: Bool = true
    
    // MARK: - Private Properties
    private let musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum RepeatMode: String, CaseIterable {
        case off = "Off"
        case one = "Repeat One"
        case all = "Repeat All"
    }
    
    // Use WorkoutEventBus.WorkoutPhase instead of defining our own
    
    // MARK: - Data Models
    struct WorkoutPlaylist {
        let id: UUID
        let name: String
        let description: String
        let tracks: [MPMediaItem]
        let averageBPM: Int
        let workoutPhase: WorkoutEventBus.WorkoutPhase
        let duration: TimeInterval
        
        init(id: UUID = UUID(), name: String, description: String, tracks: [MPMediaItem] = [], averageBPM: Int, workoutPhase: WorkoutEventBus.WorkoutPhase, duration: TimeInterval = 0) {
            self.id = id
            self.name = name
            self.description = description
            self.tracks = tracks
            self.averageBPM = averageBPM
            self.workoutPhase = workoutPhase
            self.duration = duration
        }
    }
    
    override init() {
        super.init()
        setupMusicPlayer()
        loadWorkoutPlaylists()
        setupNotifications()
        print("🎵 WorkoutMusicManager initialized (iOS)")
    }
    
    // MARK: - Setup
    private func setupMusicPlayer() {
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        // Setup playback notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )
        
        // Start playback timer
        startPlaybackTimer()
    }
    
    private func setupNotifications() {
        // Listen for workout phase changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkoutPhaseChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let phase = notification.object as? WorkoutEventBus.WorkoutPhase {
                self?.syncMusicToWorkout(phase)
            }
        }
    }
    
    private func loadWorkoutPlaylists() {
        // Load curated workout playlists
        sprintPlaylists = createSprintPlaylists()
        recoveryPlaylists = createRecoveryPlaylists()
        warmupPlaylists = createWarmupPlaylists()
        cooldownPlaylists = createCooldownPlaylists()
    }
    
    // MARK: - Public Methods
    func syncMusicToWorkout(_ phase: WorkoutEventBus.WorkoutPhase) {
        guard autoSyncEnabled else { return }
        
        selectOptimalPlaylist(for: phase)
        print("🎵 Music synced to \(phase.rawValue) phase")
    }
    
    func setupMusicForWorkout(_ session: TrainingSession) {
        // Select appropriate playlists based on workout type
        let workoutType = session.type.lowercased()
        
        if workoutType.contains("sprint") {
            currentPlaylist = sprintPlaylists.first
        } else if workoutType.contains("recovery") {
            currentPlaylist = recoveryPlaylists.first
        } else {
            currentPlaylist = warmupPlaylists.first
        }
        
        print("🎵 Music setup for \(session.type) workout")
    }
    
    func playCompletionMusic() {
        // Play celebration music for workout completion
        if let celebrationPlaylist = cooldownPlaylists.first {
            currentPlaylist = celebrationPlaylist
            play()
        }
        print("🎵 Playing completion music")
    }
    
    func play() {
        musicPlayer.play()
        isPlaying = true
    }
    
    func pause() {
        musicPlayer.pause()
        isPlaying = false
    }
    
    func stop() {
        musicPlayer.stop()
        isPlaying = false
        playbackTime = 0
    }
    
    // MARK: - Private Methods
    private func selectOptimalPlaylist(for phase: WorkoutEventBus.WorkoutPhase) {
        let playlists: [WorkoutPlaylist]
        
        switch phase {
        case .warmup:
            playlists = warmupPlaylists
        case .sprints:
            playlists = sprintPlaylists
        case .recovery:
            playlists = recoveryPlaylists
        case .cooldown:
            playlists = cooldownPlaylists
        default:
            playlists = recoveryPlaylists
        }
        
        currentPlaylist = playlists.first
    }
    
    private func createSprintPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                name: "High Intensity Sprint",
                description: "High-energy tracks for maximum performance",
                averageBPM: 160,
                workoutPhase: .sprints
            )
        ]
    }
    
    private func createRecoveryPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                name: "Active Recovery",
                description: "Moderate tempo for recovery periods",
                averageBPM: 100,
                workoutPhase: .recovery
            )
        ]
    }
    
    private func createWarmupPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                name: "Dynamic Warmup",
                description: "Building energy for workout preparation",
                averageBPM: 120,
                workoutPhase: .warmup
            )
        ]
    }
    
    private func createCooldownPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                name: "Cool Down & Celebrate",
                description: "Relaxing tracks for post-workout recovery",
                averageBPM: 80,
                workoutPhase: .cooldown
            )
        ]
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }
    }
    
    @MainActor
    private func updatePlaybackTime() {
        playbackTime = musicPlayer.currentPlaybackTime
    }
    
    // MARK: - Notification Handlers
    @objc private func playbackStateChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = self?.musicPlayer.playbackState == .playing
        }
    }
    
    @objc private func nowPlayingItemChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.currentTrack = self?.musicPlayer.nowPlayingItem
        }
    }
    
    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
        playbackTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
