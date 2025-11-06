import Foundation
import MusicKit
import MediaPlayer
import Combine
import SwiftUI

/// Enhanced Apple Music integration using MusicKit for direct catalog access
class MusicKitManager: ObservableObject {
    static let shared = MusicKitManager()
    
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var isAuthorized = false
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0
    @Published var currentPlaylist: MusicItemCollection<Song>?
    
    // Workout-specific playlists
    @Published var sprintPlaylists: [Playlist] = []
    @Published var workoutSongs: [Song] = []
    @Published var recommendedSongs: [Song] = []
    
    private let player = ApplicationMusicPlayer.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMusicKit()
        observePlaybackState()
    }
    
    // MARK: - Setup & Authorization
    
    private func setupMusicKit() {
        Task {
            await requestAuthorization()
            await loadInitialData()
        }
        setupNotifications()
        print("🎵 MusicKitManager initialized")
    }
    
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
        
        if isAuthorized {
            await loadInitialData()
        }
    }
    
    private func setupNotifications() {
        // Setup music player notifications and observers
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackState()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCurrentSong()
            }
        }
    }
    
    private func updatePlaybackState() {
        isPlaying = player.state.playbackStatus == .playing
    }
    
    private func updateCurrentSong() {
        // Update current song from player state
        if let currentEntry = player.queue.currentEntry {
            // Handle different types of music items
            switch currentEntry.item {
            case let song as Song:
                currentSong = song
            case let track as Track:
                // Convert track to song if possible, or handle differently
                print("🎵 Currently playing track: \(track.title)")
                currentSong = nil // Track is not a Song type
            default:
                currentSong = nil
            }
        }
        print("🎵 Now playing item changed")
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadInitialData() async {
        await loadWorkoutPlaylists()
        await loadRecommendedSongs()
    }
    
    private func loadWorkoutPlaylists() async {
        guard isAuthorized else { return }
        
        do {
            // Search for workout-related playlists
            let searchRequest = MusicCatalogSearchRequest(
                term: "workout sprint running",
                types: [Playlist.self]
            )
            let searchResponse = try await searchRequest.response()
            
            sprintPlaylists = Array(searchResponse.playlists.prefix(10))
            
            // Load user's library playlists
            let libraryRequest = MusicLibraryRequest<Playlist>()
            let libraryResponse = try await libraryRequest.response()
            
            // Filter for workout playlists
            let workoutLibraryPlaylists = libraryResponse.items.filter { playlist in
                let name = playlist.name.lowercased()
                return name.contains("workout") || name.contains("sprint") || 
                       name.contains("running") || name.contains("gym")
            }
            
            sprintPlaylists.append(contentsOf: workoutLibraryPlaylists)
            
        } catch {
            print("Failed to load workout playlists: \(error)")
        }
    }
    
    private func loadRecommendedSongs() async {
        guard isAuthorized else { return }
        
        do {
            // Search for high-energy songs suitable for sprinting
            let genres = ["Electronic", "Hip-Hop", "Rock", "Pop"]
            var allSongs: [Song] = []
            
            for genre in genres {
                let searchRequest = MusicCatalogSearchRequest(
                    term: "\(genre) high energy workout",
                    types: [Song.self]
                )
                let searchResponse = try await searchRequest.response()
                allSongs.append(contentsOf: Array(searchResponse.songs.prefix(25)))
            }
            
            // Filter songs by BPM and energy (if available in metadata)
            recommendedSongs = allSongs.filter { song in
                // In a real implementation, you'd check BPM metadata
                // For now, filter by genre and explicit content
                return song.genreNames.contains { genre in
                    ["Electronic", "Hip-Hop", "Rock", "Pop"].contains(genre)
                }
            }
            
        } catch {
            print("Failed to load recommended songs: \(error)")
        }
    }
    
    // MARK: - Playback Control
    
    func play(_ song: Song) async {
        guard isAuthorized else { return }
        
        do {
            try await player.queue.insert(song, position: .tail)
            try await player.play()
            currentSong = song
            isPlaying = true
        } catch {
            print("Failed to play song: \(error)")
        }
    }
    
    func play(_ songs: [Song]) async {
        guard isAuthorized, !songs.isEmpty else { return }
        
        do {
            for song in songs {
                try await player.queue.insert(song, position: .tail)
            }
            try await player.play()
            currentSong = songs.first
            isPlaying = true
        } catch {
            print("Failed to play songs: \(error)")
        }
    }
    
    func playPlaylist(_ playlist: Playlist) async {
        guard isAuthorized else { return }
        
        do {
            // Load playlist tracks
            let detailedPlaylist = try await playlist.with(.tracks)
            if let tracks = detailedPlaylist.tracks {
                // Handle tracks properly - they might not all be Songs
                let playableItems = Array(tracks)
                let songs = playableItems.compactMap { track -> Song? in
                    // Only return if it's actually a Song
                    return track as? Song
                }
                
                if !songs.isEmpty {
                    await play(songs)
                    currentPlaylist = MusicItemCollection(songs)
                } else {
                    print("No playable songs found in playlist")
                }
            }
        } catch {
            print("Failed to play playlist: \(error)")
        }
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func resume() async {
        do {
            try await player.play()
            isPlaying = true
        } catch {
            print("Failed to resume playback: \(error)")
        }
    }
    
    func skipToNext() async {
        do {
            try await player.skipToNextEntry()
        } catch {
            print("Failed to skip to next: \(error)")
        }
    }
    
    func skipToPrevious() async {
        do {
            try await player.skipToPreviousEntry()
        } catch {
            print("Failed to skip to previous: \(error)")
        }
    }
    
    // MARK: - Workout-Specific Features
    
    func generateWorkoutPlaylist(
        duration: TimeInterval,
        intensity: WorkoutIntensity,
        preferredGenres: [String] = []
    ) async -> [Song] {
        guard isAuthorized else { return [] }
        
        var searchTerms: [String] = []
        
        switch intensity {
        case .low:
            searchTerms = ["chill workout", "yoga music", "meditation"]
        case .medium:
            searchTerms = ["workout music", "gym playlist", "fitness"]
        case .high:
            searchTerms = ["high energy workout", "sprint music", "intense training"]
        case .maximum:
            searchTerms = ["hardcore workout", "beast mode", "maximum intensity"]
        }
        
        // Add preferred genres
        if !preferredGenres.isEmpty {
            searchTerms.append(contentsOf: preferredGenres.map { "\($0) workout" })
        }
        
        var playlistSongs: [Song] = []
        let targetSongCount = Int(duration / 180) // ~3 minutes per song
        
        for term in searchTerms {
            if playlistSongs.count >= targetSongCount { break }
            
            do {
                let searchRequest = MusicCatalogSearchRequest(
                    term: term,
                    types: [Song.self]
                )
                let searchResponse = try await searchRequest.response()
                
                let songsToAdd = Array(searchResponse.songs.prefix(targetSongCount - playlistSongs.count))
                playlistSongs.append(contentsOf: songsToAdd)
                
            } catch {
                print("Failed to search for songs with term '\(term)': \(error)")
            }
        }
        
        // Shuffle and return
        return playlistSongs.shuffled()
    }
    
    func findSongsByBPM(targetBPM: Int, tolerance: Int = 10) async -> [Song] {
        guard isAuthorized else { return [] }
        
        // Note: MusicKit doesn't directly expose BPM data
        // This would require additional audio analysis or third-party services
        // For now, we'll return songs from genres typically matching the BPM range
        
        let genresByBPM: [ClosedRange<Int>: [String]] = [
            60...90: ["Ambient", "Chill", "Lo-Fi"],
            90...120: ["Pop", "R&B", "Indie"],
            120...140: ["Rock", "Hip-Hop", "Dance"],
            140...180: ["Electronic", "Techno", "Drum & Bass"]
        ]
        
        let targetRange = (targetBPM - tolerance)...(targetBPM + tolerance)
        var matchingGenres: [String] = []
        
        for (bpmRange, genres) in genresByBPM {
            if bpmRange.overlaps(targetRange) {
                matchingGenres.append(contentsOf: genres)
            }
        }
        
        var songs: [Song] = []
        for genre in matchingGenres {
            do {
                let searchRequest = MusicCatalogSearchRequest(
                    term: "\(genre) workout",
                    types: [Song.self]
                )
                let searchResponse = try await searchRequest.response()
                songs.append(contentsOf: Array(searchResponse.songs.prefix(10)))
            } catch {
                print("Failed to search for \(genre) songs: \(error)")
            }
        }
        
        return songs
    }
    
    // MARK: - Playlist Management
    
    func createWorkoutPlaylist(name: String, songs: [Song]) async -> Bool {
        guard isAuthorized else { return false }
        
        do {
            // Create playlist in user's library
            let playlist = try await MusicLibrary.shared.createPlaylist(
                name: name,
                description: "Created by SC40 Sprint Coach",
                items: songs
            )
            
            print("Created playlist: \(playlist.name)")
            return true
            
        } catch {
            print("Failed to create playlist: \(error)")
            return false
        }
    }
    
    func addToLibrary(_ song: Song) async {
        guard isAuthorized else { return }
        
        do {
            try await MusicLibrary.shared.add(song)
            print("Added song to library: \(song.title)")
        } catch {
            print("Failed to add song to library: \(error)")
        }
    }
    
    // MARK: - Playback Observation
    
    private func observePlaybackState() {
        // Observe playback state changes
        player.state.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updatePlaybackState()
            }
            .store(in: &cancellables)
        
        // Observe playback time
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePlaybackTime()
            }
            .store(in: &cancellables)
    }
    
    private func updatePlaybackTime() {
        playbackTime = player.playbackTime
    }
}

// MARK: - Supporting Types

enum WorkoutIntensity {
    case low      // 60-90 BPM
    case medium   // 90-120 BPM
    case high     // 120-140 BPM
    case maximum  // 140+ BPM
}

struct WorkoutMusicPreferences {
    let preferredGenres: [String]
    let excludedGenres: [String]
    let explicitContentAllowed: Bool
    let preferredBPMRange: ClosedRange<Int>
    let preferredDuration: ClosedRange<TimeInterval>
}

// MARK: - SwiftUI Integration

struct MusicKitAuthView: View {
    @StateObject private var musicManager = MusicKitManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Enhanced Music Experience")
                .font(.title2.bold())
            
            Text("Connect Apple Music for personalized workout playlists")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Connect Apple Music") {
                Task {
                    await musicManager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(musicManager.isAuthorized)
            
            if musicManager.isAuthorized {
                Text("✅ Apple Music Connected")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}
