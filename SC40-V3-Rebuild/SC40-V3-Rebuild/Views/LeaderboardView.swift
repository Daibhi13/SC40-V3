import SwiftUI
import Combine

struct LeaderboardView: View {
    @StateObject private var socialService = MockSocialService()
    @State private var selectedCategory = LeaderboardCategory.overall
    @State private var selectedTimeframe = LeaderboardTimeframe.weekly
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Timeframe Picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(LeaderboardTimeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Leaderboard Content
                if isLoading {
                    LoadingLeaderboardView()
                } else {
                    LeaderboardContentView(
                        leaderboard: currentLeaderboard,
                        category: selectedCategory
                    )
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshLeaderboard) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            loadLeaderboard()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            loadLeaderboard()
        }
        .onAppear {
            loadLeaderboard()
        }
    }
    
    private var currentLeaderboard: Leaderboard? {
        socialService.leaderboards.first { leaderboard in
            leaderboard.category == selectedCategory &&
            leaderboard.timeframe == selectedTimeframe
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        Task {
            do {
                try await socialService.loadLeaderboard(
                    category: selectedCategory,
                    timeframe: selectedTimeframe
                )
                isLoading = false
            } catch {
                print("Error loading leaderboard: \(error)")
                isLoading = false
            }
        }
    }
    
    private func refreshLeaderboard() {
        loadLeaderboard()
    }
}

struct LeaderboardContentView: View {
    let leaderboard: Leaderboard?
    let category: LeaderboardCategory
    
    var body: some View {
        if let leaderboard = leaderboard {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Top 3 Podium
                    if leaderboard.entries.count >= 3 {
                        PodiumView(entries: Array(leaderboard.entries.prefix(3)), category: category)
                            .padding()
                    }
                    
                    // Full Rankings
                    VStack(spacing: 0) {
                        ForEach(Array(leaderboard.entries.enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRowView(
                                entry: entry,
                                rank: index + 1,
                                category: category,
                                isCurrentUser: entry.user.id == "current_user_id" // Replace with actual current user ID
                            )
                            
                            if index < leaderboard.entries.count - 1 {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding()
                }
            }
        } else {
            EmptyLeaderboardView()
        }
    }
}

struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let category: LeaderboardCategory
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Top Performers")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(alignment: .bottom, spacing: 8) {
                // Second place
                if entries.count > 1 {
                    PodiumPositionView(
                        entry: entries[1],
                        position: 2,
                        category: category,
                        height: 80
                    )
                }
                
                // First place
                if entries.count > 0 {
                    PodiumPositionView(
                        entry: entries[0],
                        position: 1,
                        category: category,
                        height: 100
                    )
                }
                
                // Third place
                if entries.count > 2 {
                    PodiumPositionView(
                        entry: entries[2],
                        position: 3,
                        category: category,
                        height: 60
                    )
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct PodiumPositionView: View {
    let entry: LeaderboardEntry
    let position: Int
    let category: LeaderboardCategory
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile Image with medal
            ZStack {
                AsyncImage(url: entry.user.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(medalColor(position), lineWidth: 3)
                )
                
                // Medal badge
                Image(systemName: medalIcon(position))
                    .foregroundColor(medalColor(position))
                    .font(.title2)
                    .offset(x: 20, y: -20)
            }
            
            // User info
            VStack(spacing: 2) {
                Text(entry.user.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(formatScore(entry.value, category: category))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(medalColor(position))
            }
        }
        .frame(width: 80)
        .padding(.bottom, height)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(medalColor(position).opacity(0.1))
                .frame(height: height)
                .offset(y: height / 2)
        )
    }
    
    private func medalColor(_ position: Int) -> Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .blue
        }
    }
    
    private func medalIcon(_ position: Int) -> String {
        switch position {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "star.fill"
        }
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let rank: Int
    let category: LeaderboardCategory
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .leading)
            
            // Profile Image
            AsyncImage(url: entry.user.profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                Text("@\(entry.user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score and trend
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatScore(entry.value, category: category))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let previousRank = entry.previousRank {
                    HStack(spacing: 2) {
                        Image(systemName: trendIcon(currentRank: rank, previousRank: previousRank))
                            .foregroundColor(trendColor(currentRank: rank, previousRank: previousRank))
                            .font(.caption)
                        
                        Text("\(abs(rank - previousRank))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .primary
        }
    }
    
    private func trendIcon(currentRank: Int, previousRank: Int) -> String {
        if currentRank < previousRank {
            return "arrow.up"
        } else if currentRank > previousRank {
            return "arrow.down"
        } else {
            return "minus"
        }
    }
    
    private func trendColor(currentRank: Int, previousRank: Int) -> Color {
        if currentRank < previousRank {
            return .green
        } else if currentRank > previousRank {
            return .red
        } else {
            return .gray
        }
    }
}

struct LoadingLeaderboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Leaderboard...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.number")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Leaderboard Data")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Complete some workouts to see your ranking!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper function to format scores based on category
private func formatScore(_ value: Double, category: LeaderboardCategory) -> String {
    switch category {
    case .overall:
        return "\(Int(value)) pts"
    case .speed:
        return String(format: "%.2fs", value)
    case .distance:
        return "\(Int(value))m"
    case .consistency:
        return "\(Int(value)) days"
    case .improvement:
        return String(format: "%.1f%%", value)
    }
}

// Extensions for better display
extension LeaderboardCategory {
    var displayName: String {
        switch self {
        case .overall:
            return "Overall"
        case .speed:
            return "Speed"
        case .distance:
            return "Distance"
        case .consistency:
            return "Consistency"
        case .improvement:
            return "Improvement"
        }
    }
    
    static var allCases: [LeaderboardCategory] {
        return [.overall, .speed, .distance, .consistency, .improvement]
    }
}

extension LeaderboardTimeframe {
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .allTime:
            return "All Time"
        }
    }
    
    static var allCases: [LeaderboardTimeframe] {
        return [.daily, .weekly, .monthly, .allTime]
    }
}

#Preview {
    LeaderboardView()
}
