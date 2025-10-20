import SwiftUI

/// Enhanced Leaderboard View matching the professional UI design
struct EnhancedLeaderboardView: View {
    var currentUser: UserProfile
    @StateObject private var locationService = LocationService()
    @State private var selectedFilter: LeaderboardFilter = .all
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var animateEntrance = false
    
    enum LeaderboardFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case region = "Region"
        case county = "County"
        case friends = "Friends"
        case age = "Age"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .region: return "Region"
            case .county: return "County"
            case .friends: return "Friends"
            case .age: return "Age"
            }
        }
    }
    
    var leaderboard: [LeaderboardUser] {
        let currentUserTime = currentUser.personalBests["40yd"] ?? currentUser.baselineTime
        let userCounty = !currentUser.county.isEmpty ? currentUser.county : locationService.county
        let userState = !currentUser.state.isEmpty ? currentUser.state : locationService.state
        let userCountry = !currentUser.country.isEmpty ? currentUser.country : locationService.country
        
        let all = [
            LeaderboardUser(initials: "CU", name: currentUser.name, countryFlag: "🇺🇸",
                          country: userCountry.isEmpty ? "USA" : userCountry,
                          state: userState.isEmpty ? "CA" : userState,
                          county: userCounty.isEmpty ? "Los Angeles" : userCounty,
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
            return all.sorted { $0.time < $1.time }
        case .region:
            return all.filter { $0.country == (userCountry.isEmpty ? "USA" : userCountry) }.sorted { $0.time < $1.time }
        case .county:
            return all.filter { $0.county == userCounty }.sorted { $0.time < $1.time }
        case .friends:
            return all.filter { friends.contains($0.name) || $0.name == currentUser.name }.sorted { $0.time < $1.time }
        case .age:
            return all.sorted { $0.time < $1.time }
        }
    }
    
    var body: some View {
        ZStack {
            // Professional gradient background matching the design
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.6),
                    Color(red: 0.3, green: 0.4, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 20) {
                    // Title
                    Text("Leaderboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Subtitle
                    Text("Compete with athletes worldwide")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // User Rank Card
                    UserRankCard(
                        rank: (leaderboard.firstIndex(where: { $0.name == currentUser.name }) ?? 0) + 1,
                        time: currentUser.personalBests["40yd"] ?? currentUser.baselineTime
                    )
                    .scaleEffect(animateEntrance ? 1.0 : 0.8)
                    .opacity(animateEntrance ? 1.0 : 0.0)
                    
                    // Filter Tabs
                    FilterTabsView(selectedFilter: $selectedFilter)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
                
                // Leaderboard List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, user in
                            AthleteCard(
                                user: user,
                                rank: index + 1,
                                isCurrentUser: user.name == currentUser.name
                            )
                            .scaleEffect(animateEntrance ? 1.0 : 0.9)
                            .opacity(animateEntrance ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateEntrance)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateEntrance = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareText])
        }
    }
}

// MARK: - User Rank Card
struct UserRankCard: View {
    let rank: Int
    let time: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 50, height: 50)
                
                Text("#\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(String(format: "%.2f", time))s")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("40-Yard Dash")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Personal Best")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}


// MARK: - Filter Tabs View
struct FilterTabsView: View {
    @Binding var selectedFilter: EnhancedLeaderboardView.LeaderboardFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EnhancedLeaderboardView.LeaderboardFilter.allCases) { filter in
                    FilterTab(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Athlete Card
struct AthleteCard: View {
    let user: LeaderboardUser
    let rank: Int
    let isCurrentUser: Bool
    
    var rankIcon: String {
        switch rank {
        case 1: return "👑"
        case 2: return "🥈"
        case 3: return "🥉"
        case 4: return "4"
        case 5: return "5"
        case 6: return "6"
        default: return "\(rank)"
        }
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .white.opacity(0.3)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                if rank <= 3 {
                    Text(rankIcon)
                        .font(.title3)
                } else {
                    Text(rankIcon)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Text(user.countryFlag)
                        .font(.subheadline)
                    Text(user.locationDisplay)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.2f", user.time))s")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("40 YD")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isCurrentUser ? 0.2 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentUser ? Color.yellow : Color.white.opacity(0.1), lineWidth: isCurrentUser ? 2 : 1)
                )
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
