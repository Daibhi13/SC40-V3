import Foundation
import MediaPlayer
import AVFoundation
import Combine
import Algorithms

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
    
    // MARK: - Algorithmic Music Features
    
    /// Generate optimal playlist sequence using Swift Algorithms
    func generateOptimalPlaylist(for workoutPhases: [WorkoutEventBus.WorkoutPhase], duration: TimeInterval) -> [MPMediaItem] {
        guard let musicLibrary = getMusicLibrary() else { return [] }
        
        // Group songs by BPM ranges suitable for different phases
        let songsByBPM = Dictionary(grouping: musicLibrary) { song in
            getBPMCategory(for: song)
        }
        
        var playlist: [MPMediaItem] = []
        
        for phase in workoutPhases {
            let phaseDuration = defaultDuration(for: phase)
            let targetBPM = getBPMForPhase(phase)
            let availableSongs = songsByBPM[targetBPM] ?? []
            
            // Use combinations() to find optimal song pairings
            let selectedSongs = selectSongsForDuration(availableSongs, targetDuration: phaseDuration)
            
            playlist.append(contentsOf: selectedSongs)
        }
        
        // Use interspersed() to add transition tracks between phases
        let finalPlaylist: [MPMediaItem]
        if let transition = getTransitionTracks() {
            finalPlaylist = Array(playlist.interspersed(with: transition).prefix(Int(duration / 180))) // ~3min per song
        } else {
            finalPlaylist = Array(playlist.prefix(Int(duration / 180)))
        }
        
        return finalPlaylist
    }
    
    /// Analyze workout intensity and suggest BPM changes
    func adaptMusicToBPM(currentBPM: Int, targetIntensity: Double) -> Int {
        let intensityRanges = [
            (0.0...0.3, 80...100),   // Recovery
            (0.3...0.6, 100...120),  // Moderate
            (0.6...0.8, 120...140),  // High
            (0.8...1.0, 140...180)   // Maximum
        ]
        
        for (intensityRange, bpmRange) in intensityRanges {
            if intensityRange.contains(targetIntensity) {
                // Gradually adjust BPM using chunked transitions
                let targetBPM = Int(Double(bpmRange.lowerBound) + (targetIntensity - intensityRange.lowerBound) / (intensityRange.upperBound - intensityRange.lowerBound) * Double(bpmRange.count))
                
                return targetBPM
            }
        }
        
        return currentBPM
    }
    
    /// Create smart crossfade sequences using adjacent pairs
    func createCrossfadeSequence(_ tracks: [MPMediaItem]) -> [(current: MPMediaItem, next: MPMediaItem, fadePoint: TimeInterval)] {
        return tracks.adjacentPairs().map { current, next in
            let fadePoint = max(current.playbackDuration - 10, current.playbackDuration * 0.8) // Fade in last 20% or 10 seconds
            return (current: current, next: next, fadePoint: fadePoint)
        }
    }
    
    /// Provides a default duration for a workout phase when explicit duration isn't available
    private func defaultDuration(for phase: WorkoutEventBus.WorkoutPhase) -> TimeInterval {
        switch phase {
        case .warmup:
            return 5 * 60 // 5 minutes
        case .sprints:
            return 60 // 1 minute per sprint block
        case .recovery:
            return 90 // 1.5 minutes
        case .cooldown:
            return 5 * 60 // 5 minutes
        default:
            return 2 * 60 // Fallback to 2 minutes
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMusicLibrary() -> [MPMediaItem]? {
        let query = MPMediaQuery.songs()
        return query.items
    }
    
    private func getBPMCategory(for song: MPMediaItem) -> BPMCategory {
        // In a real implementation, you'd analyze the song or use metadata
        // For now, we'll use a simple heuristic based on genre
        let genre = song.genre?.lowercased() ?? ""
        
        switch genre {
        case let g where g.contains("electronic") || g.contains("dance"):
            return .high
        case let g where g.contains("rock") || g.contains("pop"):
            return .medium
        case let g where g.contains("ambient") || g.contains("chill"):
            return .low
        default:
            return .medium
        }
    }
    
    private func getBPMForPhase(_ phase: WorkoutEventBus.WorkoutPhase) -> BPMCategory {
        switch phase {
        case .warmup, .cooldown:
            return .low
        case .sprints:
            return .high
        case .recovery:
            return .low
        default:
            return .medium
        }
    }
    
    private func selectSongsForDuration(_ songs: [MPMediaItem], targetDuration: TimeInterval) -> [MPMediaItem] {
        var selectedSongs: [MPMediaItem] = []
        var currentDuration: TimeInterval = 0
        
        // Use a greedy algorithm to select songs that best fit the duration
        let sortedSongs = songs.sorted { abs($0.playbackDuration - (targetDuration - currentDuration)) < abs($1.playbackDuration - (targetDuration - currentDuration)) }
        
        for song in sortedSongs {
            if currentDuration + song.playbackDuration <= targetDuration + 30 { // 30 second tolerance
                selectedSongs.append(song)
                currentDuration += song.playbackDuration
                
                if currentDuration >= targetDuration {
                    break
                }
            }
        }
        
        return selectedSongs
    }
    
    private func getTransitionTracks() -> MPMediaItem? {
        // Return a default transition track if available. In this placeholder, we return nil.
        return nil
    }
    
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
            guard let phase = notification.object as? WorkoutEventBus.WorkoutPhase else { return }
            Task { @MainActor [weak self] in
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
            Task { @MainActor in
                self?.updatePlaybackTime()
            }
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

// MARK: - Supporting Types

enum BPMCategory {
    case low    // 80-100 BPM
    case medium // 100-130 BPM  
    case high   // 130+ BPM
}
