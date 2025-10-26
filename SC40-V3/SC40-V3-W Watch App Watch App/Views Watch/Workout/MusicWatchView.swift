import SwiftUI
import MediaPlayer

struct MusicApp {
    let name: String
    let icon: String
    let bundleId: String
}

import SwiftUI

struct MusicWatchView: View {
    /// 0 = Control, 1 = MainWorkout, 2 = Music (default)
    var selectedIndex: Int = 2
    let session: TrainingSession
    
    @State private var isPlaying: Bool = false
    @State private var currentTrack: String = "Not Playing"
    @State private var currentArtist: String = ""
    @State private var showingAppLauncher: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    private let musicApps = [
        MusicApp(name: "Apple Music", icon: "music.note", bundleId: "com.apple.Music"),
        MusicApp(name: "Radio", icon: "radio", bundleId: "com.apple.RadioApp"),
        MusicApp(name: "Podcasts", icon: "podcast", bundleId: "com.apple.podcasts"),
        MusicApp(name: "Spotify", icon: "music.note.list", bundleId: "com.spotify.client")
    ]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.brandBackground, Color.brandTertiary.opacity(0.18)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Time at top
                Text(currentTimeString())
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.brandSecondary)
                    .padding(.top, 8)

                Spacer()

                // Centered media info and controls
                VStack(spacing: 8) {
                    // Current media display
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.brandTertiary.opacity(0.13))
                                .frame(width: 60, height: 60)
                            Image(systemName: isPlaying ? "music.note" : "applewatch")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(isPlaying ? Color.brandPrimary : Color.brandAccent)
                        }
                        
                        VStack(spacing: 2) {
                            Text(currentTrack)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color.brandPrimary)
                                .lineLimit(1)
                            
                            if !currentArtist.isEmpty {
                                Text(currentArtist)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.brandSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    // Subtle app launcher - small icon button
                    Button(action: { showingAppLauncher.toggle() }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.brandTertiary.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()

                // Media controls at the bottom - properly centered
                HStack(spacing: 20) {
                    Button(action: { previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.brandSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.brandTertiary.opacity(0.13)))
                    }
                    
                    Button(action: { togglePlayPause() }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.brandBackground)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.brandPrimary))
                            .shadow(color: Color.brandPrimary.opacity(0.18), radius: 3, x: 0, y: 1)
                    }
                    
                    Button(action: { nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.brandSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.brandTertiary.opacity(0.13)))
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 12)
        }
        .sheet(isPresented: $showingAppLauncher) {
            MusicAppLauncherView(musicApps: musicApps)
        }
        .gesture(swipeBackGesture)
        .onAppear {
            setupMediaPlayer()
            updateNowPlayingInfo()
        }
    }
    
    // MARK: - Swipe Back Gesture
    private var swipeBackGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                // Swipe Left to go back to Enhanced7StageWorkoutView
                if value.translation.width < -30 {
                    print("🎵 MusicView - Swipe Left to return to workout")
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
    
    // MARK: - Media Control Functions
    private func setupMediaPlayer() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            self.isPlaying = true
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            self.isPlaying = false
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { _ in
            self.nextTrack()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { _ in
            self.previousTrack()
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        let nowPlayingInfo = MPNowPlayingInfoCenter.default()
        
        // Try to get current media info
        if let mediaItem = nowPlayingInfo.nowPlayingInfo {
            if let title = mediaItem[MPMediaItemPropertyTitle] as? String {
                currentTrack = title
            }
            if let artist = mediaItem[MPMediaItemPropertyArtist] as? String {
                currentArtist = artist
            }
        }
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        if isPlaying {
            commandCenter.playCommand.isEnabled = false
            commandCenter.pauseCommand.isEnabled = true
        } else {
            commandCenter.playCommand.isEnabled = true
            commandCenter.pauseCommand.isEnabled = false
        }
        
        print("📱 Music \(isPlaying ? "playing" : "paused")")
    }
    
    private func nextTrack() {
        // Simulate track change
        updateTrackInfo()
        print("📱 Next track")
    }
    
    private func previousTrack() {
        // Simulate track change
        updateTrackInfo()
        print("📱 Previous track")
    }
    
    private func updateTrackInfo() {
        // This would typically be updated by the media player
        // For demo purposes, we'll just update the display
        updateNowPlayingInfo()
    }

    // Helper to show the current time in 24h format
    func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Music App Launcher View
struct MusicAppLauncherView: View {
    let musicApps: [MusicApp]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(musicApps, id: \.bundleId) { app in
                        Button(action: { launchApp(app) }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandTertiary.opacity(0.12))
                                        .frame(width: 55, height: 55)
                                    
                                    Image(systemName: app.icon)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color.brandPrimary)
                                }
                                
                                Text(app.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.brandSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                }
            }
        }
    }
    
    private func launchApp(_ app: MusicApp) {
        // Attempt to open the app using its bundle identifier
        let urlString = "\(app.bundleId)://"
        print("📱 Would launch \(app.name) with URL: \(urlString)")
        
        // On watchOS, we can't directly launch third-party apps programmatically
        // But we can provide visual feedback that the action was triggered
        // In a real implementation, this might:
        // 1. Open Apple Music/Radio if those are the selected apps
        // 2. Show the app in the app grid for user to tap
        // 3. Use WatchConnectivity to trigger app launch on iPhone
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview
#Preview {
    MusicWatchView(
        selectedIndex: 2,
        session: TrainingSession(
            week: 1,
            day: 1,
            type: "Preview",
            focus: "Test Session",
            sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "max")],
            accessoryWork: []
        )
    )
}
