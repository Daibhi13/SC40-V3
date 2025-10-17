import SwiftUI

/// Enhanced Leaderboard View with podium, medals, and animations
struct EnhancedLeaderboardView: View {
    var currentUser: UserProfile
    @State private var selectedFilter: LeaderboardFilter = .all
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var animatePodium = false
    
    enum LeaderboardFilter: String, CaseIterable, Identifiable {
        case all = "🌍 Global"
        case region = "📍 Region"
        case county = "🏘️ County"
        case friends = "👥 Friends"
        case age = "🎂 Age Group"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "globe.americas.fill"
            case .region: return "map.fill"
            case .county: return "building.2.fill"
            case .friends: return "person.2.fill"
            case .age: return "calendar"
            }
        }
    }
    
    var leaderboard: [LeaderboardUser] {
        let currentUserTime = currentUser.personalBests["40yd"] ?? currentUser.baselineTime
        
        let all = [
            LeaderboardUser(initials: "CU", name: currentUser.name, countryFlag: "🇺🇸",
                          country: "USA", state: "CA", county: "Los Angeles",
                          time: currentUserTime),
            LeaderboardUser(initials: "AS", name: "Ava Smith", countryFlag: "🇺🇸",
                          country: "USA", state: "CA", county: "Orange", time: 4.32),
            LeaderboardUser(initials: "LC", name: "Liam Chen", countryFlag: "🇺🇸",
                          country: "USA", state: "CA", county: "Los Angeles", time: 4.41),
            LeaderboardUser(initials: "NP", name: "Noah Patel", countryFlag: "🇺🇸",
                          country: "USA", state: "TX", county: "Harris", time: 4.38),
            LeaderboardUser(initials: "EM", name: "Emma Müller", countryFlag: "🇩🇪",
                          country: "Germany", state: "Bayern", county: "München", time: 4.29),
            LeaderboardUser(initials: "LR", name: "Lucas Rossi", countryFlag: "🇧🇷",
                          country: "Brazil", state: "São Paulo", county: "São Paulo", time: 4.36),
            LeaderboardUser(initials: "ML", name: "Mia Lee", countryFlag: "🇰🇷",
                          country: "South Korea", state: "Seoul", county: "Gangnam", time: 4.35),
            LeaderboardUser(initials: "SD", name: "Sophia Dubois", countryFlag: "🇫🇷",
                          country: "France", state: "Île-de-France", county: "Paris", time: 4.40),
            LeaderboardUser(initials: "JW", name: "James Wilson", countryFlag: "🇬🇧",
                          country: "UK", state: "England", county: "London", time: 4.45),
            LeaderboardUser(initials: "OA", name: "Olivia Anderson", countryFlag: "🇨🇦",
                          country: "Canada", state: "Ontario", county: "Toronto", time: 4.42)
        ]
        
        let friends = ["Ava Smith", "Mia Lee"]
        
        switch selectedFilter {
        case .all:
            return all.sorted(by: { $0.time < $1.time })
        case .region:
            return all.filter({ $0.country == "USA" }).sorted(by: { $0.time < $1.time })
        case .county:
            return all.filter({ $0.county == "Los Angeles" }).sorted(by: { $0.time < $1.time })
        case .friends:
            return all.filter({ friends.contains($0.name) || $0.name == currentUser.name }).sorted(by: { $0.time < $1.time })
        case .age:
            return all.sorted(by: { $0.time < $1.time })
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.yellow.opacity(0.1),
                        Color.orange.opacity(0.05),
                        Color.red.opacity(0.03)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if leaderboard.isEmpty {
                    EmptyStateView.noLeaderboardData(action: {
                        selectedFilter = .all
                    })
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header Stats
                            LeaderboardHeaderStats(
                                totalAthletes: leaderboard.count,
                                userRank: (leaderboard.firstIndex(where: { $0.name == currentUser.name }) ?? 0) + 1,
                            userTime: currentUser.personalBests["40yd"] ?? currentUser.baselineTime
                        )
                        
                        // Filter Picker
                        FilterPicker(selectedFilter: $selectedFilter)
                        
                        // Top 3 Podium
                        if leaderboard.count >= 3 {
                            PodiumView(
                                first: leaderboard[0],
                                second: leaderboard[1],
                                third: leaderboard[2],
                                animate: animatePodium
                            )
                            .padding(.vertical)
                        }
                        
                        // Rest of Leaderboard
                        VStack(spacing: 12) {
                            ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, user in
                                if index >= 3 {
                                    LeaderboardRow(
                                        user: user,
                                        rank: index + 1,
                                        isCurrentUser: user.name == currentUser.name,
                                        onShare: {
                                            shareText = "I'm ranked #\(index + 1) with a time of \(String(format: "%.2f", user.time))s! 🏃‍♂️⚡ #SprintCoach40"
                                            showShareSheet = true
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    }
                }
            }
            .navigationTitle("🏆 Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    animatePodium = true
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: [shareText])
            }
        }
    }
}

// MARK: - Header Stats
struct LeaderboardHeaderStats: View {
    let totalAthletes: Int
    let userRank: Int
    let userTime: Double
    
    var body: some View {
        HStack(spacing: 16) {
            LeaderboardStatCard(
                icon: "person.3.fill",
                value: "\(totalAthletes)",
                label: "Athletes",
                color: .blue
            )
            
            LeaderboardStatCard(
                icon: "trophy.fill",
                value: "#\(userRank)",
                label: "Your Rank",
                color: .orange
            )
            
            LeaderboardStatCard(
                icon: "stopwatch.fill",
                value: String(format: "%.2f", userTime),
                label: "Your Time",
                color: .green
            )
        }
        .padding(.horizontal)
    }
}

struct LeaderboardStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Filter Picker
struct FilterPicker: View {
    @Binding var selectedFilter: EnhancedLeaderboardView.LeaderboardFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EnhancedLeaderboardView.LeaderboardFilter.allCases) { filter in
                    FilterChipButton(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChipButton: View {
    let filter: EnhancedLeaderboardView.LeaderboardFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.white.opacity(0.6))
            .cornerRadius(20)
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Podium View
struct PodiumView: View {
    let first: LeaderboardUser
    let second: LeaderboardUser
    let third: LeaderboardUser
    let animate: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Second Place
            PodiumPosition(
                user: second,
                rank: 2,
                height: 100,
                color: Color.gray,
                medal: "🥈",
                animate: animate
            )
            .offset(y: animate ? 0 : 100)
            
            // First Place
            PodiumPosition(
                user: first,
                rank: 1,
                height: 140,
                color: Color.yellow,
                medal: "🥇",
                animate: animate
            )
            .offset(y: animate ? 0 : 150)
            
            // Third Place
            PodiumPosition(
                user: third,
                rank: 3,
                height: 80,
                color: Color.brown,
                medal: "🥉",
                animate: animate
            )
            .offset(y: animate ? 0 : 80)
        }
        .padding(.horizontal)
    }
}

struct PodiumPosition: View {
    let user: LeaderboardUser
    let rank: Int
    let height: CGFloat
    let color: Color
    let medal: String
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Medal
            Text(medal)
                .font(.system(size: 40))
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Text(user.initials)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // Name
            Text(user.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Time
            Text(String(format: "%.2f s", user.time))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            // Podium Block
            VStack {
                Text("#\(rank)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(8)
            .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let user: LeaderboardUser
    let rank: Int
    let isCurrentUser: Bool
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isCurrentUser ? .blue : .secondary)
                .frame(width: 40)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(user.initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentUser ? .blue : .gray)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isCurrentUser {
                        Text("YOU")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 4) {
                    Text(user.countryFlag)
                        .font(.caption)
                    Text(user.locationDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", user.time))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                
                Text("seconds")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Actions Menu
            Menu {
                Button(action: {}) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                }
                Button(action: {}) {
                    Label("Challenge", systemImage: "bolt")
                }
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.white.opacity(0.6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#if DEBUG
struct EnhancedLeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = UserProfile(
            name: "Test User",
            email: "test@example.com",
            gender: "Male",
            age: 25,
            height: 70,
            weight: 170,
            personalBests: ["40yd": 5.0],
            level: "Intermediate",
            baselineTime: 5.0,
            frequency: 3
        )
        EnhancedLeaderboardView(currentUser: mockUser)
    }
}
#endif
