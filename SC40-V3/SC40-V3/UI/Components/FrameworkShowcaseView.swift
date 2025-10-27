import SwiftUI
import GameKit
import MusicKit
import UserNotifications
import ActivityKit
import Intents
import ARKit

/// Comprehensive showcase of all implemented frameworks in SC40
struct FrameworkShowcaseView: View {
    @StateObject private var gameKitManager = GameKitManager.shared
    @StateObject private var musicKitManager = MusicKitManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var messagesManager = MessagesManager.shared
    @StateObject private var intentsManager = IntentsManager.shared
    
    @State private var selectedTab = 0
    @State private var showingARView = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // GameKit Tab
                GameKitShowcaseTab()
                    .tabItem {
                        Image(systemName: "gamecontroller.fill")
                        Text("GameKit")
                    }
                    .tag(0)
                
                // MusicKit Tab
                MusicKitShowcaseTab()
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Music")
                    }
                    .tag(1)
                
                // Notifications Tab
                NotificationsShowcaseTab()
                    .tabItem {
                        Image(systemName: "bell.fill")
                        Text("Notifications")
                    }
                    .tag(2)
                
                // Messages Tab
                MessagesShowcaseTab()
                    .tabItem {
                        Image(systemName: "message.fill")
                        Text("Messages")
                    }
                    .tag(3)
                
                // Siri Tab
                SiriShowcaseTab()
                    .tabItem {
                        Image(systemName: "mic.fill")
                        Text("Siri")
                    }
                    .tag(4)
                
                // Advanced Tab
                AdvancedFeaturesTab()
                    .tabItem {
                        Image(systemName: "sparkles")
                        Text("Advanced")
                    }
                    .tag(5)
            }
            .navigationTitle("Framework Showcase")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - GameKit Showcase

struct GameKitShowcaseTab: View {
    @StateObject private var gameKitManager = GameKitManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authentication Status
                StatusCard(
                    title: "GameKit Authentication",
                    status: gameKitManager.isAuthenticated ? "Connected" : "Not Connected",
                    isConnected: gameKitManager.isAuthenticated,
                    icon: "gamecontroller.fill"
                )
                
                if gameKitManager.isAuthenticated {
                    // Player Info
                    if let player = gameKitManager.localPlayer {
                        PlayerInfoCard(player: player)
                    }
                    
                    // Achievements
                    AchievementsCard(achievements: gameKitManager.getAchievementProgress())
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("View Achievements") {
                            gameKitManager.showAchievements()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        Button("View Leaderboards") {
                            gameKitManager.showLeaderboards()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Test Achievement") {
                            gameKitManager.checkSprintAchievements(
                                time: 4.85,
                                isFirstSprint: false,
                                weekStreak: 7,
                                monthStreak: 30
                            )
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - MusicKit Showcase

struct MusicKitShowcaseTab: View {
    @StateObject private var musicKitManager = MusicKitManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authorization Status
                StatusCard(
                    title: "Apple Music",
                    status: musicKitManager.isAuthorized ? "Connected" : "Not Connected",
                    isConnected: musicKitManager.isAuthorized,
                    icon: "music.note"
                )
                
                if !musicKitManager.isAuthorized {
                    Button("Connect Apple Music") {
                        Task {
                            await musicKitManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                if musicKitManager.isAuthorized {
                    // Current Song
                    if let currentSong = musicKitManager.currentSong {
                        CurrentSongCard(song: currentSong, isPlaying: musicKitManager.isPlaying)
                    }
                    
                    // Workout Playlists
                    if !musicKitManager.sprintPlaylists.isEmpty {
                        PlaylistsCard(playlists: musicKitManager.sprintPlaylists)
                    }
                    
                    // Music Controls
                    VStack(spacing: 12) {
                        Button("Generate Workout Playlist") {
                            Task {
                                let playlist = await musicKitManager.generateWorkoutPlaylist(
                                    duration: 1800, // 30 minutes
                                    intensity: .high
                                )
                                if !playlist.isEmpty {
                                    await musicKitManager.play(playlist)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        HStack(spacing: 20) {
                            Button(musicKitManager.isPlaying ? "Pause" : "Play") {
                                Task {
                                    if musicKitManager.isPlaying {
                                        musicKitManager.pause()
                                    } else {
                                        await musicKitManager.resume()
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Skip") {
                                Task {
                                    await musicKitManager.skipToNext()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - Notifications Showcase

struct NotificationsShowcaseTab: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authorization Status
                StatusCard(
                    title: "Notifications",
                    status: notificationManager.isAuthorized ? "Enabled" : "Disabled",
                    isConnected: notificationManager.isAuthorized,
                    icon: "bell.fill"
                )
                
                if !notificationManager.isAuthorized {
                    Button("Enable Notifications") {
                        Task {
                            await notificationManager.requestAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                if notificationManager.isAuthorized {
                    // Test Notifications
                    VStack(spacing: 12) {
                        Button("Test Achievement Notification") {
                            Task {
                                await notificationManager.notifyAchievementUnlocked(
                                    title: "Speed Demon",
                                    description: "Run under 4.5 seconds",
                                    points: 50
                                )
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        Button("Test Personal Record") {
                            Task {
                                await notificationManager.notifyPersonalRecord(
                                    newTime: 4.75,
                                    improvement: 0.10
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Schedule Workout Reminder") {
                            Task {
                                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                await notificationManager.scheduleWorkoutReminder(
                                    for: tomorrow,
                                    sessionType: "Sprint Training",
                                    weekNumber: 3,
                                    dayNumber: 2
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

// MARK: - Messages Showcase

struct MessagesShowcaseTab: View {
    @StateObject private var messagesManager = MessagesManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Capabilities
                HStack(spacing: 20) {
                    StatusCard(
                        title: "iMessage",
                        status: messagesManager.canSendMessages ? "Available" : "Not Available",
                        isConnected: messagesManager.canSendMessages,
                        icon: "message.fill"
                    )
                    
                    StatusCard(
                        title: "Email",
                        status: messagesManager.canSendMail ? "Available" : "Not Available",
                        isConnected: messagesManager.canSendMail,
                        icon: "envelope.fill"
                    )
                }
                
                // Sharing Options
                VStack(spacing: 12) {
                    Button("Share Workout Result") {
                        messagesManager.shareWorkoutResult(
                            sprintTime: 4.85,
                            improvement: 0.05,
                            weekNumber: 3,
                            dayNumber: 2
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!messagesManager.canSendMessages)
                    
                    Button("Share Personal Record") {
                        messagesManager.sharePersonalRecord(
                            newRecord: 4.75,
                            previousRecord: 4.85,
                            improvement: 0.10
                        )
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(!messagesManager.canSendMessages)
                    
                    Button("Send Challenge") {
                        messagesManager.sendChallenge(challengerTime: 4.85)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(!messagesManager.canSendMessages)
                    
                    Button("Email Detailed Report") {
                        let mockData = WeeklyProgressData(
                            weekNumber: 3,
                            sessionsCompleted: 5,
                            totalSessions: 6,
                            bestTime: 4.85,
                            averageTime: 5.12,
                            improvement: -0.05,
                            sessions: []
                        )
                        messagesManager.shareDetailedReport(weeklyData: mockData)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(!messagesManager.canSendMail)
                }
                .padding()
            }
            .padding()
        }
    }
}

// MARK: - Siri Showcase

struct SiriShowcaseTab: View {
    @StateObject private var intentsManager = IntentsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Siri Shortcuts Info
                InfoCard(
                    title: "Siri Shortcuts",
                    description: "Add voice commands to quickly start workouts, check progress, and log times.",
                    icon: "mic.fill"
                )
                
                // Suggested Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Voice Commands")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ShortcutRow(phrase: "Start my sprint workout", description: "Begin today's training session")
                        ShortcutRow(phrase: "Check my sprint progress", description: "View weekly stats and trends")
                        ShortcutRow(phrase: "What's my personal best", description: "Get your fastest 40-yard time")
                        ShortcutRow(phrase: "Log my sprint time", description: "Record a new sprint result")
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button("Open Siri Shortcuts Settings") {
                        // This would open the SiriShortcutsView
                        print("Opening Siri shortcuts settings")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Donate Test Intent") {
                        intentsManager.donateStartWorkoutIntent(
                            sessionType: "Sprint",
                            weekNumber: 3,
                            dayNumber: 2
                        )
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .padding()
        }
    }
}

// MARK: - Advanced Features

struct AdvancedFeaturesTab: View {
    @State private var showingARView = false
    @State private var showingAlgorithmicInsights = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Live Activities
                if #available(iOS 16.1, *) {
                    FrameworkFeatureCard(
                        title: "Live Activities",
                        description: "Real-time workout progress on Lock Screen and Dynamic Island",
                        icon: "iphone",
                        action: {
                            // Demo Live Activity
                            Task {
                                await ActivityKitManager.shared.startWorkoutActivity(
                                    sessionType: "Sprint Training",
                                    weekNumber: 3,
                                    dayNumber: 2,
                                    totalSprints: 6
                                )
                            }
                        }
                    )
                }
                
                // AR Coaching
                if ARWorldTrackingConfiguration.isSupported {
                    FrameworkFeatureCard(
                        title: "AR Sprint Coaching",
                        description: "Augmented reality sprint lane and virtual coach",
                        icon: "arkit",
                        action: {
                            showingARView = true
                        }
                    )
                }
                
                // Algorithmic Insights
                FrameworkFeatureCard(
                    title: "Algorithmic Insights",
                    description: "Advanced analytics powered by Swift Algorithms",
                    icon: "cpu",
                    action: {
                        showingAlgorithmicInsights = true
                    }
                )
                
                // Watch Integration
                FrameworkFeatureCard(
                    title: "Apple Watch Integration",
                    description: "Native workout sessions, complications, and sync",
                    icon: "applewatch",
                    action: {
                        print("Watch features demonstrated in Watch app")
                    }
                )
            }
            .padding()
        }
        .sheet(isPresented: $showingARView) {
            if #available(iOS 13.0, *) {
                ARSprintCoachView()
            }
        }
        .sheet(isPresented: $showingAlgorithmicInsights) {
            AlgorithmicInsightsView(userProfileVM: UserProfileViewModel())
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let status: String
    let isConnected: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isConnected ? .green : .red)
            
            Text(title)
                .font(.headline)
            
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FrameworkFeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct ShortcutRow: View {
    let phrase: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\"\(phrase)\"")
                    .font(.body.bold())
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Additional supporting views would be implemented here...
struct PlayerInfoCard: View {
    let player: GKLocalPlayer
    
    var body: some View {
        Text("Player: \(player.displayName)")
    }
}

struct AchievementsCard: View {
    let achievements: [SC40Achievement]
    
    var body: some View {
        Text("Achievements: \(achievements.count)")
    }
}

struct CurrentSongCard: View {
    let song: Song
    let isPlaying: Bool
    
    var body: some View {
        Text("Now Playing: \(song.title)")
    }
}

struct PlaylistsCard: View {
    let playlists: [Playlist]
    
    var body: some View {
        Text("Playlists: \(playlists.count)")
    }
}

#Preview {
    FrameworkShowcaseView()
}
