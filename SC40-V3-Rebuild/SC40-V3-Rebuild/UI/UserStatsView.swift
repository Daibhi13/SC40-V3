import SwiftUI

struct UserStatsView: View {
    var currentUser: UserProfile
    
    @State private var selectedFilter: Filter = .all
    @State private var showShareSheet: Bool = false
    @State private var shareText: String = ""
    @StateObject private var locationService = LocationService()
    @State private var showLocationPrompt = false
    
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case region = "Region"
        case county = "County"
        case friends = "Friends"
        case age = "Age Group"
        var id: String { rawValue }
    }
    
    // Mock friend list and region/age for demo
    let friends = ["Ava Smith", "Mia Lee"]
    let userRegion = "USA"
    let userAgeGroup = "18-25"
    
    var leaderboard: [LeaderboardUser] {
        let currentUserTime = currentUser.personalBests["40yd"] ?? currentUser.baselineTime
        print("🏆 Leaderboard: Current user PB = \(currentUserTime)")
        print("🏆 Leaderboard: personalBests['40yd'] = \(currentUser.personalBests["40yd"] ?? -1)")
        print("🏆 Leaderboard: baselineTime = \(currentUser.baselineTime)")
        
        // Use current user's location if available, otherwise use detected location
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
                          country: "France", state: "Île-de-France", county: "Paris", time: 4.40)
        ]
        switch selectedFilter {
        case .all:
            return all.sorted { $0.time < $1.time }
        case .region:
            return all.filter { $0.country == userRegion }.sorted { $0.time < $1.time }
        case .county:
            return all.filter { $0.county == userCounty }.sorted { $0.time < $1.time }
        case .friends:
            return all.filter { friends.contains($0.name) || $0.name == currentUser.name }.sorted { $0.time < $1.time }
        case .age:
            // For demo, just return all (add age property to LeaderboardUser for real filter)
            return all.sorted { $0.time < $1.time }
        }
    }
    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBackground.ignoresSafeArea(.all)
                
                VStack(spacing: 8) {
                    // Location detection prompt
                    if !locationService.isAuthorized && !currentUser.locationPermissionGranted {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.blue)
                                Text("Enable location to show your county on the leaderboard")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Allow") {
                                    locationService.requestLocationPermission()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(Filter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.horizontal, .top])
                    
                    List {
                        ForEach(Array(leaderboard.enumerated()), id: \ .element.id) { index, user in
                            HStack(spacing: 16) {
                                Text("#\(index + 1)")
                                    .font(.headline)
                                    .frame(width: 32)
                                    .foregroundColor(.brandPrimary)
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                        .foregroundColor(.brandSecondary)
                                    Text(user.locationDisplay)
                                        .font(.subheadline)
                                        .foregroundColor(.brandTertiary)
                                }
                                Spacer()
                                Text(String(format: "%.2f s", user.time))
                                    .font(.title3.bold())
                                    .foregroundColor(index == 0 ? .yellow : .brandPrimary)
                                // Friend/Challenge/Share buttons
                                Menu {
                                    Button("Add Friend") { /* TODO: Add friend logic */ }
                                    Button("Challenge") { /* TODO: Challenge logic */ }
                                    Button("Share") {
                                        shareText = "Check out my sprint time: \(user.time)s! #SprintCoach40"
                                        showShareSheet = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title2)
                                        .foregroundColor(.brandAccent)
                                }
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.brandAccent.opacity(0.13))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.brandBackground)
                }
            }
            .navigationTitle("Leaderboard")
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: [shareText])
            }
        }
    }
}
