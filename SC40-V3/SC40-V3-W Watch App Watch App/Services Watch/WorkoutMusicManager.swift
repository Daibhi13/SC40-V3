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
}
    }
    
    override init() {
        super.init()
        setupMusicPlayer()
        loadWorkoutPlaylists()
        setupNotifications()
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
            if let phase = notification.object as? WorkoutPhase {
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
    
    // MARK: - Playback Control
    
    func play() {
        guard subscriptionManager.hasAccess(to: .autonomousWorkouts) else {
            // Show upgrade prompt for Pro tier
            return
        }
        
        musicPlayer.play()
        updatePlaybackState()
    }
    
    func pause() {
        musicPlayer.pause()
        updatePlaybackState()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func skipToNext() {
        musicPlayer.skipToNextItem()
        updatePlaybackState()
    }
    
    func skipToPrevious() {
        musicPlayer.skipToPreviousItem()
        updatePlaybackState()
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
        musicPlayer.volume = volume
    }
    
    func seek(to time: TimeInterval) {
        musicPlayer.currentPlaybackTime = time
        playbackTime = time
    }
    
    // MARK: - Workout Synchronization
    
    func syncMusicToWorkout(_ phase: WorkoutPhase) {
        guard autoSyncEnabled else { return }
        
        print("🎵 Syncing music to workout phase: \(phase)")
        
        let targetPlaylist = getPlaylistForPhase(phase)
        
        if currentPlaylist != targetPlaylist {
            switchToPlaylist(targetPlaylist, fadeTransition: fadeTransitions)
        }
        
        // Adjust volume based on phase
        adjustVolumeForPhase(phase)
        
        // Sync haptics if enabled
        if hapticSync {
            syncHapticsToMusic()
        }
    }
    
    private func getPlaylistForPhase(_ phase: WorkoutPhase) -> WorkoutPlaylist? {
        switch phase {
        case .warmup:
            return warmupPlaylists.randomElement()
        case .sprint:
            return sprintPlaylists.randomElement()
        case .recovery:
            return recoveryPlaylists.randomElement()
        case .cooldown:
            return cooldownPlaylists.randomElement()
        case .rest:
            return recoveryPlaylists.randomElement()
        }
    }
    
    private func adjustVolumeForPhase(_ phase: WorkoutPhase) {
        let targetVolume: Float
        
        switch phase {
        case .warmup: targetVolume = 0.6
        case .sprint: targetVolume = 0.8
        case .recovery: targetVolume = 0.5
        case .cooldown: targetVolume = 0.4
        case .rest: targetVolume = 0.3
        }
        
        animateVolumeChange(to: targetVolume, duration: 2.0)
    }
    
    private func animateVolumeChange(to targetVolume: Float, duration: TimeInterval) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = (targetVolume - volume) / Float(steps)
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                self.setVolume(self.volume + volumeStep * Float(i))
            }
        }
    }
    
    // MARK: - Playlist Management
    
    func switchToPlaylist(_ playlist: WorkoutPlaylist?, fadeTransition: Bool = true) {
        guard let playlist = playlist else { return }
        
        currentPlaylist = playlist
        
        if fadeTransition {
            fadeOutAndSwitchPlaylist(playlist)
        } else {
            setPlaylistImmediately(playlist)
        }
    }
    
    private func fadeOutAndSwitchPlaylist(_ playlist: WorkoutPlaylist) {
        // Fade out current music
        animateVolumeChange(to: 0.0, duration: 1.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setPlaylistImmediately(playlist)
            
            // Fade back in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateVolumeChange(to: 0.7, duration: 1.0)
            }
        }
    }
    
    private func setPlaylistImmediately(_ playlist: WorkoutPlaylist) {
        let query = MPMediaQuery.songs()
        
        // Filter by BPM range if available
        if let bpmRange = playlist.bpmRange {
            // Note: BPM filtering requires Apple Music API or pre-curated playlists
            // For now, we'll use genre-based filtering as a proxy
            query.addFilterPredicate(MPMediaPropertyPredicate(
                value: playlist.genre,
                forProperty: MPMediaItemPropertyGenre
            ))
        }
        
        if let items = query.items, !items.isEmpty {
            let collection = MPMediaItemCollection(items: items)
            musicPlayer.setQueue(with: collection)
            
            if isShuffleEnabled {
                musicPlayer.shuffleMode = .songs
            }
            
            updateRepeatMode()
            
            if !isPlaying {
                play()
            }
        }
    }
    
    private func updateRepeatMode() {
        switch repeatMode {
        case .off:
            musicPlayer.repeatMode = .none
        case .one:
            musicPlayer.repeatMode = .one
        case .all:
            musicPlayer.repeatMode = .all
        }
    }
    
    // MARK: - Haptic Synchronization
    
    private func syncHapticsToMusic() {
        guard let currentTrack = currentTrack else { return }
        
        // Get BPM from track metadata or estimate
        let bpm = getBPMFromTrack(currentTrack) ?? 120
        let hapticInterval = 60.0 / Double(bpm)
        
        // Start rhythmic haptic feedback
        startRhythmicHaptics(interval: hapticInterval)
    }
    
    private func getBPMFromTrack(_ track: MPMediaItem) -> Int? {
        // Try to get BPM from metadata
        // Note: This requires additional music analysis or pre-processed data
        return nil
    }
    
    private func startRhythmicHaptics(interval: TimeInterval) {
        // Stop any existing haptic timer
        stopRhythmicHaptics()
        
        // Start new haptic timer
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private func stopRhythmicHaptics() {
        // Implementation to stop haptic timer
    }
    
    // MARK: - Playlist Creation
    
    private func createSprintPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                id: UUID(),
                name: "High-Intensity Sprints",
                description: "High-energy tracks for maximum speed",
                bpmRange: 140...180,
                genre: "Electronic",
                tracks: [],
                workoutPhase: .sprint,
                isPremium: false
            ),
            WorkoutPlaylist(
                id: UUID(),
                name: "Elite Sprinter Mix",
                description: "Professional athlete favorites",
                bpmRange: 150...180,
                genre: "Hip-Hop",
                tracks: [],
                workoutPhase: .sprint,
                isPremium: true
            ),
            WorkoutPlaylist(
                id: UUID(),
                name: "Power & Speed",
                description: "Explosive tracks for power development",
                bpmRange: 140...170,
                genre: "Rock",
                tracks: [],
                workoutPhase: .sprint,
                isPremium: false
            )
        ]
    }
    
    private func createRecoveryPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                id: UUID(),
                name: "Active Recovery",
                description: "Calming tracks for rest periods",
                bpmRange: 80...110,
                genre: "Ambient",
                tracks: [],
                workoutPhase: .recovery,
                isPremium: false
            ),
            WorkoutPlaylist(
                id: UUID(),
                name: "Mindful Recovery",
                description: "Meditation-inspired recovery music",
                bpmRange: 70...100,
                genre: "New Age",
                tracks: [],
                workoutPhase: .recovery,
                isPremium: true
            )
        ]
    }
    
    private func createWarmupPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                id: UUID(),
                name: "Dynamic Warmup",
                description: "Energizing tracks to prepare for training",
                bpmRange: 100...120,
                genre: "Pop",
                tracks: [],
                workoutPhase: .warmup,
                isPremium: false
            )
        ]
    }
    
    private func createCooldownPlaylists() -> [WorkoutPlaylist] {
        return [
            WorkoutPlaylist(
                id: UUID(),
                name: "Cool Down & Stretch",
                description: "Relaxing tracks for post-workout recovery",
                bpmRange: 60...90,
                genre: "Acoustic",
                tracks: [],
                workoutPhase: .cooldown,
                isPremium: false
            )
        ]
    }
    
    // MARK: - Timer Management
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }
    }
    
    private func updatePlaybackTime() {
        playbackTime = musicPlayer.currentPlaybackTime
    }
    
    // MARK: - Notification Handlers
    
    @objc private func playbackStateChanged() {
        updatePlaybackState()
    }
    
    @objc private func nowPlayingItemChanged() {
        currentTrack = musicPlayer.nowPlayingItem
        updatePlaybackState()
    }
    
    private func updatePlaybackState() {
        isPlaying = musicPlayer.playbackState == .playing
    }
    
    // MARK: - Premium Features
    
    func unlockPremiumPlaylists() -> Bool {
        return subscriptionManager.hasAccess(to: .aiOptimization)
    }
    
    func getCelebrityPlaylists() -> [WorkoutPlaylist] {
        guard unlockPremiumPlaylists() else { return [] }
        
        return [
            WorkoutPlaylist(
                id: UUID(),
                name: "Usain Bolt's Lightning Mix",
                description: "The fastest man's favorite training tracks",
                bpmRange: 150...180,
                genre: "Reggae/Hip-Hop",
                tracks: [],
                workoutPhase: .sprint,
                isPremium: true,
                celebrity: "Usain Bolt"
            ),
            WorkoutPlaylist(
                id: UUID(),
                name: "Allyson Felix Power Hour",
                description: "Olympic champion's strength training playlist",
                bpmRange: 130...160,
                genre: "R&B/Pop",
                tracks: [],
                workoutPhase: .sprint,
                isPremium: true,
                celebrity: "Allyson Felix"
            )
        ]
    }
    
    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
        playbackTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Data Models

struct WorkoutPlaylist: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let bpmRange: ClosedRange<Int>?
    let genre: String
    let tracks: [String] // Track identifiers
    let workoutPhase: WorkoutMusicManager.WorkoutPhase
    let isPremium: Bool
    let celebrity: String?
    
    init(id: UUID, name: String, description: String, bpmRange: ClosedRange<Int>?, genre: String, tracks: [String], workoutPhase: WorkoutMusicManager.WorkoutPhase, isPremium: Bool, celebrity: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.bpmRange = bpmRange
        self.genre = genre
        self.tracks = tracks
        self.workoutPhase = workoutPhase
        self.isPremium = isPremium
        self.celebrity = celebrity
    }
}

extension WorkoutMusicManager.WorkoutPhase: Codable {}

// MARK: - Music Integration Extensions

extension Feature {
    static let musicIntegration = Feature.autonomousWorkouts
    static let premiumPlaylists = Feature.aiOptimization
    static let celebrityContent = Feature.biomechanicsAnalysis
}
