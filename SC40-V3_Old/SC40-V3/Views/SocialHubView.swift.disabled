import SwiftUI

struct SocialHubView: View {
    @StateObject private var socialService = MockSocialService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Friends Tab
            FriendsView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "person.2.fill" : "person.2")
                    Text("Friends")
                }
                .tag(0)
            
            // Challenges Tab
            ChallengesView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "target.fill" : "target")
                    Text("Challenges")
                }
                .tag(1)
            
            // Leaderboard Tab
            LeaderboardView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "list.number" : "list.number")
                    Text("Leaderboard")
                }
                .tag(2)
            
            // Activity Feed Tab
            SocialActivityView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "bell.fill" : "bell")
                    Text("Activity")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct SocialActivityView: View {
    @StateObject private var socialService = MockSocialService()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    LoadingActivityView()
                } else if socialService.activityFeed.isEmpty {
                    EmptyActivityView()
                } else {
                    List {
                        ForEach(socialService.activityFeed) { activity in
                            SocialActivityRowView(activity: activity)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await loadActivity()
                    }
                }
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadActivity()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadActivity()
            }
        }
    }
    
    private func loadActivity() async {
        isLoading = true
        do {
            try await socialService.loadActivityFeed()
        } catch {
            print("Error loading activity feed: \(error)")
        }
        isLoading = false
    }
}

struct SocialActivityRowView: View {
    let activity: SocialActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Type Icon
            Image(systemName: activityIcon)
                .foregroundColor(activityColor)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                // Activity Description
                Text(activityDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                // Timestamp
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Additional info based on activity type
            if let metadata = activity.metadata {
                activityMetadataView(metadata)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var activityIcon: String {
        switch activity.type {
        case .friendAdded:
            return "person.badge.plus"
        case .challengeCompleted:
            return "checkmark.circle.fill"
        case .challengeJoined:
            return "target"
        case .personalRecord:
            return "trophy.fill"
        case .workoutCompleted:
            return "figure.run"
        case .leaderboardRank:
            return "list.number"
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .friendAdded:
            return .blue
        case .challengeCompleted:
            return .green
        case .challengeJoined:
            return .orange
        case .personalRecord:
            return .yellow
        case .workoutCompleted:
            return .purple
        case .leaderboardRank:
            return .red
        }
    }
    
    private var activityDescription: String {
        switch activity.type {
        case .friendAdded:
            return "\(activity.user.displayName) added a new friend"
        case .challengeCompleted:
            return "\(activity.user.displayName) completed a challenge"
        case .challengeJoined:
            return "\(activity.user.displayName) joined a new challenge"
        case .personalRecord:
            return "\(activity.user.displayName) set a new personal record!"
        case .workoutCompleted:
            return "\(activity.user.displayName) completed a workout"
        case .leaderboardRank:
            return "\(activity.user.displayName) moved up in the leaderboard"
        }
    }
    
    @ViewBuilder
    private func activityMetadataView(_ metadata: [String: String]) -> some View {
        switch activity.type {
        case .challengeCompleted, .challengeJoined:
            if let challengeName = metadata["challengeName"] {
                VStack(alignment: .trailing) {
                    Text(challengeName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        case .personalRecord:
            if let record = metadata["record"] {
                VStack(alignment: .trailing) {
                    Text(record)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
        case .leaderboardRank:
            if let rank = metadata["rank"] {
                VStack(alignment: .trailing) {
                    Text("#\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
        default:
            EmptyView()
        }
    }
}

struct LoadingActivityView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Activity...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Recent Activity")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Follow friends and join challenges to see activity updates here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Social Features Dashboard Card (for integration with main app)
struct SocialFeaturesCard: View {
    @StateObject private var socialService = MockSocialService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Social")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: SocialHubView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 8) {
                // Quick stats
                HStack {
                    StatQuickView(
                        icon: "person.2",
                        title: "Friends",
                        value: "\(socialService.friends.count)"
                    )
                    
                    Spacer()
                    
                    StatQuickView(
                        icon: "target",
                        title: "Active Challenges",
                        value: "\(socialService.activeChallenges.count)"
                    )
                }
                
                // Recent activity
                if let recentActivity = socialService.activityFeed.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent Activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("New friend request from \(recentActivity.user.displayName)")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatQuickView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Social Hub") {
    SocialHubView()
}

#Preview("Social Card") {
    SocialFeaturesCard()
        .padding()
}
