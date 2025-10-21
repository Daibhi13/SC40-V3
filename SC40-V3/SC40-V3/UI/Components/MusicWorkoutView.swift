import SwiftUI
import MediaPlayer
import AVFoundation

// MARK: - Music Workout View - Apple Fitness Style
struct MusicWorkoutView: View {
    @State private var isPlaying = false
    @State private var currentTrack: MusicTrack?
    @State private var playbackProgress: Double = 0.0
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var volume: Float = 0.7
    @State private var showVolumeControl = false
    
    // Music library state
    @State private var workoutPlaylists: [WorkoutPlaylist] = []
    @State private var currentPlaylist: WorkoutPlaylist?
    @State private var showPlaylistSelector = false
    
    var body: some View {
        ZStack {
            // Background matching workout views
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.3, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                musicHeaderView
                
                Spacer()
                
                // Album Art and Track Info
                albumArtSection
                
                // Progress Bar
                progressBarSection
                
                // Music Controls
                musicControlsSection
                
                Spacer()
                
                // Page Indicator
                pageIndicatorView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
        .onAppear {
            setupMusicSession()
            loadWorkoutPlaylists()
        }
        .sheet(isPresented: $showPlaylistSelector) {
            PlaylistSelectorView(
                playlists: workoutPlaylists,
                selectedPlaylist: $currentPlaylist,
                onDismiss: { showPlaylistSelector = false }
            )
        }
    }
    
    // MARK: - Header Section
    private var musicHeaderView: some View {
        VStack(spacing: 8) {
            Text("21:44")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text("MUSIC")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(2)
        }
    }
    
    // MARK: - Album Art Section
    private var albumArtSection: some View {
        VStack(spacing: 20) {
            // Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6),
                                Color.blue.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                if let track = currentTrack {
                    // Custom album art or music icon
                    if let artworkImage = track.artwork {
                        Image(uiImage: artworkImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    // Default "Not Playing" state
                    VStack(spacing: 12) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("SC40")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .scaleEffect(isPlaying ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isPlaying)
            
            // Track Info
            VStack(spacing: 8) {
                if let track = currentTrack {
                    Text(track.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text("Not Playing")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {
                        showPlaylistSelector = true
                    }) {
                        Text("Choose Music")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Bar Section
    private var progressBarSection: some View {
        VStack(spacing: 8) {
            if currentTrack != nil {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * playbackProgress, height: 4)
                            .animation(.linear(duration: 0.1), value: playbackProgress)
                    }
                }
                .frame(height: 4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let progress = value.location.x / UIScreen.main.bounds.width
                            playbackProgress = max(0, min(1, progress))
                            seekToProgress(playbackProgress)
                        }
                )
                
                // Time labels
                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Music Controls Section
    private var musicControlsSection: some View {
        HStack(spacing: 40) {
            // Previous Track
            Button(action: previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .disabled(currentTrack == nil)
            
            // Play/Pause
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2) // Slight offset for play icon centering
                }
            }
            .scaleEffect(isPlaying ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPlaying)
            
            // Next Track
            Button(action: nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .disabled(currentTrack == nil)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Page Indicator
    private var pageIndicatorView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
            
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
            
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
        }
    }
    
    // MARK: - Music Control Methods
    
    private func setupMusicSession() {
        // Configure audio session for workout music
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func loadWorkoutPlaylists() {
        // Load curated workout playlists
        workoutPlaylists = [
            WorkoutPlaylist(
                name: "Sprint Training Mix",
                description: "High-energy tracks for sprint workouts",
                tracks: generateSprintTracks(),
                artwork: nil
            ),
            WorkoutPlaylist(
                name: "Warm-Up Vibes",
                description: "Moderate tempo for warm-up phases",
                tracks: generateWarmupTracks(),
                artwork: nil
            ),
            WorkoutPlaylist(
                name: "Cool Down",
                description: "Relaxing tracks for recovery",
                tracks: generateCooldownTracks(),
                artwork: nil
            )
        ]
        
        // Set default playlist
        currentPlaylist = workoutPlaylists.first
        currentTrack = currentPlaylist?.tracks.first
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            startPlayback()
        } else {
            pausePlayback()
        }
        
        // Haptic feedback
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    
    private func startPlayback() {
        // Start music playback
        print("🎵 Starting playback: \(currentTrack?.title ?? "Unknown")")
        // Implement actual music playback here
    }
    
    private func pausePlayback() {
        // Pause music playback
        print("⏸️ Pausing playback")
        // Implement actual music pause here
    }
    
    private func previousTrack() {
        guard let playlist = currentPlaylist,
              let current = currentTrack,
              let currentIndex = playlist.tracks.firstIndex(where: { $0.id == current.id }),
              currentIndex > 0 else { return }
        
        currentTrack = playlist.tracks[currentIndex - 1]
        if isPlaying {
            startPlayback()
        }
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    private func nextTrack() {
        guard let playlist = currentPlaylist,
              let current = currentTrack,
              let currentIndex = playlist.tracks.firstIndex(where: { $0.id == current.id }),
              currentIndex < playlist.tracks.count - 1 else { return }
        
        currentTrack = playlist.tracks[currentIndex + 1]
        if isPlaying {
            startPlayback()
        }
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    private func seekToProgress(_ progress: Double) {
        currentTime = duration * progress
        // Implement actual seek functionality here
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Music Data Models

struct MusicTrack: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: TimeInterval
    let artwork: UIImage?
    let bpm: Int? // Beats per minute for workout matching
    
    static func == (lhs: MusicTrack, rhs: MusicTrack) -> Bool {
        lhs.id == rhs.id
    }
}

struct WorkoutPlaylist: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let tracks: [MusicTrack]
    let artwork: UIImage?
}

// MARK: - Playlist Selector View
struct PlaylistSelectorView: View {
    let playlists: [WorkoutPlaylist]
    @Binding var selectedPlaylist: WorkoutPlaylist?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.2, blue: 0.35),
                        Color(red: 0.2, green: 0.25, blue: 0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(playlists) { playlist in
                            PlaylistCard(
                                playlist: playlist,
                                isSelected: selectedPlaylist?.id == playlist.id,
                                onSelect: {
                                    selectedPlaylist = playlist
                                    onDismiss()
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workout Playlists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct PlaylistCard: View {
    let playlist: WorkoutPlaylist
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Playlist artwork placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(playlist.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    Text("\(playlist.tracks.count) tracks")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sample Data Generation
extension MusicWorkoutView {
    private func generateSprintTracks() -> [MusicTrack] {
        return [
            MusicTrack(title: "Thunder", artist: "Imagine Dragons", duration: 187, artwork: nil, bpm: 168),
            MusicTrack(title: "Stronger", artist: "Kanye West", duration: 312, artwork: nil, bpm: 104),
            MusicTrack(title: "Eye of the Tiger", artist: "Survivor", duration: 245, artwork: nil, bpm: 109),
            MusicTrack(title: "Pump It", artist: "Black Eyed Peas", duration: 213, artwork: nil, bpm: 124),
            MusicTrack(title: "Till I Collapse", artist: "Eminem", duration: 297, artwork: nil, bpm: 85)
        ]
    }
    
    private func generateWarmupTracks() -> [MusicTrack] {
        return [
            MusicTrack(title: "Good as Hell", artist: "Lizzo", duration: 219, artwork: nil, bpm: 96),
            MusicTrack(title: "Uptown Funk", artist: "Bruno Mars", duration: 270, artwork: nil, bpm: 115),
            MusicTrack(title: "Can't Stop the Feeling", artist: "Justin Timberlake", duration: 236, artwork: nil, bpm: 113)
        ]
    }
    
    private func generateCooldownTracks() -> [MusicTrack] {
        return [
            MusicTrack(title: "Weightless", artist: "Marconi Union", duration: 485, artwork: nil, bpm: 60),
            MusicTrack(title: "Clair de Lune", artist: "Claude Debussy", duration: 300, artwork: nil, bpm: 70),
            MusicTrack(title: "Aqueous Transmission", artist: "Incubus", duration: 451, artwork: nil, bpm: 65)
        ]
    }
}

#Preview {
    MusicWorkoutView()
}
