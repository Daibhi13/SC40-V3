import SwiftUI
import MediaPlayer

struct EnhancedMusicWatchView: View {
    @StateObject private var musicManager = WorkoutMusicManager.shared
    @StateObject private var hapticsManager = AdvancedHapticsManager.shared
    // Note: SubscriptionManager not available in Watch target
    // Using basic functionality for Watch
    
    @State private var selectedTab: MusicTab = .nowPlaying
    @State private var showingPlaylistSelector = false
    @State private var showingSettings = false
    @State private var showingUpgradePrompt = false
    
    let session: TrainingSession
    
    enum MusicTab: String, CaseIterable {
        case nowPlaying = "Now Playing"
        case playlists = "Playlists"
        case controls = "Controls"
        
        var icon: String {
            switch self {
            case .nowPlaying: return "music.note"
            case .playlists: return "music.note.list"
            case .controls: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                musicTabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    nowPlayingView
                        .tag(MusicTab.nowPlaying)
                    
                    playlistsView
                        .tag(MusicTab.playlists)
                    
                    controlsView
                        .tag(MusicTab.controls)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.purple.opacity(0.3),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            MusicSettingsView()
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            MusicUpgradePromptView()
        }
        .onAppear {
            setupMusicForWorkout()
        }
    }
    
    // MARK: - Tab Selector
    
    private var musicTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(MusicTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                    hapticsManager.playHaptic(.click)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .yellow : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Now Playing View
    
    private var nowPlayingView: some View {
        VStack(spacing: 16) {
            // Album Art & Track Info
            trackInfoCard
            
            // Playback Controls
            playbackControls
            
            // Progress Bar
            progressBar
            
            // Volume Control
            volumeControl
        }
        .padding(16)
    }
    
    private var trackInfoCard: some View {
        VStack(spacing: 8) {
            // Album Art Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: musicManager.isPlaying ? "music.note" : "music.note.slash")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            // Track Information
            VStack(spacing: 4) {
                Text(musicManager.currentTrack?.title ?? "No Track Selected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(musicManager.currentTrack?.artist ?? "Select a playlist to begin")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var playbackControls: some View {
        HStack(spacing: 24) {
            // Previous Track
            Button(action: {
                musicManager.skipToPrevious()
                hapticsManager.playHaptic(.click)
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .disabled(!hasProAccess)
            
            // Play/Pause
            Button(action: {
                musicManager.togglePlayPause()
                hapticsManager.playHaptic(musicManager.isPlaying ? .success : .notification)
            }) {
                Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            
            // Next Track
            Button(action: {
                musicManager.skipToNext()
                hapticsManager.playHaptic(.click)
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .disabled(!hasProAccess)
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 4) {
            // Progress Slider
            Slider(
                value: Binding(
                    get: { musicManager.playbackTime },
                    set: { musicManager.seek(to: $0) }
                ),
                in: 0...(musicManager.currentTrack?.playbackDuration ?? 1)
            )
            .accentColor(.green)
            .disabled(!hasProAccess)
            
            // Time Labels
            HStack {
                Text(formatTime(musicManager.playbackTime))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(formatTime(musicManager.currentTrack?.playbackDuration ?? 0))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var volumeControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            
            Slider(
                value: Binding(
                    get: { musicManager.volume },
                    set: { musicManager.setVolume($0) }
                ),
                in: 0...1
            )
            .accentColor(.white.opacity(0.7))
            
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Playlists View
    
    private var playlistsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Workout Phase Playlists
                playlistSection("Sprint Playlists", playlists: musicManager.sprintPlaylists)
                playlistSection("Recovery Playlists", playlists: musicManager.recoveryPlaylists)
                playlistSection("Warmup Playlists", playlists: musicManager.warmupPlaylists)
                playlistSection("Cooldown Playlists", playlists: musicManager.cooldownPlaylists)
                
                // Premium Celebrity Playlists
                if hasEliteAccess {
                    playlistSection("Celebrity Playlists", playlists: musicManager.getCelebrityPlaylists())
                } else {
                    premiumPlaylistsTeaser
                }
            }
            .padding(16)
        }
    }
    
    private func playlistSection(_ title: String, playlists: [WorkoutPlaylist]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(playlists) { playlist in
                PlaylistCard(playlist: playlist) {
                    selectPlaylist(playlist)
                }
            }
        }
    }
    
    private var premiumPlaylistsTeaser: some View {
        VStack(spacing: 12) {
            Text("Celebrity Playlists")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Button(action: { showingUpgradePrompt = true }) {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Text("Unlock Elite Playlists")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Get exclusive playlists from Olympic athletes")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow, lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Controls View
    
    private var controlsView: some View {
        VStack(spacing: 20) {
            // Auto-Sync Toggle
            autoSyncToggle
            
            // Haptic Sync Toggle
            hapticSyncToggle
            
            // Fade Transitions Toggle
            fadeTransitionsToggle
            
            // Shuffle & Repeat Controls
            shuffleRepeatControls
            
            Spacer()
        }
        .padding(16)
    }
    
    private var autoSyncToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Auto-Sync to Workout")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Automatically switch playlists based on workout phase")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $musicManager.autoSyncEnabled)
                .labelsHidden()
                .disabled(!hasProAccess)
        }
        .padding(.vertical, 8)
    }
    
    private var hapticSyncToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Haptic Music Sync")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !hasProAccess {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("Feel the beat with rhythmic haptic feedback")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $musicManager.hapticSync)
                .labelsHidden()
                .disabled(!hasProAccess)
        }
        .padding(.vertical, 8)
        .onTapGesture {
            if !hasProAccess {
                showingUpgradePrompt = true
            }
        }
    }
    
    private var fadeTransitionsToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Smooth Transitions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Fade between playlists during phase changes")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $musicManager.fadeTransitions)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
    
    private var shuffleRepeatControls: some View {
        HStack(spacing: 24) {
            // Shuffle Button
            Button(action: {
                musicManager.isShuffleEnabled.toggle()
                hapticsManager.playHaptic(.click)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: musicManager.isShuffleEnabled ? "shuffle" : "shuffle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(musicManager.isShuffleEnabled ? .green : .white.opacity(0.5))
                    
                    Text("Shuffle")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(musicManager.isShuffleEnabled ? .green : .white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Repeat Button
            Button(action: {
                cycleRepeatMode()
                hapticsManager.playHaptic(.click)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: repeatIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(musicManager.repeatMode != .off ? .green : .white.opacity(0.5))
                    
                    Text(musicManager.repeatMode.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(musicManager.repeatMode != .off ? .green : .white.opacity(0.5))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var hasProAccess: Bool {
        subscriptionManager.hasAccess(to: .autonomousWorkouts)
    }
    
    private var hasEliteAccess: Bool {
        subscriptionManager.hasAccess(to: .aiOptimization)
    }
    
    private var repeatIcon: String {
        switch musicManager.repeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }
    
    private func setupMusicForWorkout() {
        // Auto-select appropriate playlist based on session type
        if session.type.lowercased().contains("sprint") {
            if let sprintPlaylist = musicManager.sprintPlaylists.first {
                selectPlaylist(sprintPlaylist)
            }
        }
    }
    
    private func selectPlaylist(_ playlist: WorkoutPlaylist) {
        if playlist.isPremium && !hasEliteAccess {
            showingUpgradePrompt = true
            return
        }
        
        musicManager.switchToPlaylist(playlist)
        hapticsManager.playHaptic(.success)
    }
    
    private func cycleRepeatMode() {
        switch musicManager.repeatMode {
        case .off:
            musicManager.repeatMode = .all
        case .all:
            musicManager.repeatMode = .one
        case .one:
            musicManager.repeatMode = .off
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct PlaylistCard: View {
    let playlist: WorkoutPlaylist
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Playlist Icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: playlist.isPremium ? "crown.fill" : "music.note.list")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(playlist.isPremium ? .yellow : .white.opacity(0.7))
                    )
                
                // Playlist Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(playlist.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if playlist.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(playlist.description)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    if let bpmRange = playlist.bpmRange {
                        Text("\(bpmRange.lowerBound)-\(bpmRange.upperBound) BPM")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

struct MusicSettingsView: View {
    @StateObject private var musicManager = WorkoutMusicManager.shared
    @StateObject private var hapticsManager = AdvancedHapticsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Music Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Settings content here
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}

struct MusicUpgradePromptView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                
                Text("Unlock Premium Music")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get access to celebrity playlists, haptic sync, and advanced music features")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("Upgrade to Pro") {
                    // Handle upgrade
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                
                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

#Preview {
    EnhancedMusicWatchView(
        session: TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Sprint Training",
            focus: "Speed Development",
            sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
            accessoryWork: []
        )
    )
}
