import Foundation
import SwiftUI
import Combine

struct LeaderboardUser: Identifiable, Decodable {
    var id: UUID = UUID() // Generated after decoding
    let initials: String
    let name: String
    let countryFlag: String
    let country: String
    let state: String
    let county: String
    let time: Double
    
    // Computed property for location display
    var locationDisplay: String {
        if !county.isEmpty && !state.isEmpty {
            return "\(county), \(state)"
        } else if !state.isEmpty {
            return state
        } else {
            return country
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case initials, name, countryFlag, country, state, county, time
    }
}

// Add a wrapper struct for decoding if the API response is wrapped, e.g. { "users": [...] }
struct LeaderboardResponse: Decodable {
    let users: [LeaderboardUser]
}

class LeaderboardViewModel: ObservableObject, @unchecked Sendable {
    enum LeaderboardTab: String, CaseIterable {
        case global = "Global"
        case friends = "Friends"
        case nearby = "Nearby"
        case thisWeek = "This week"
    }
    @Published var selectedTab: LeaderboardTab = .global
    @Published var users: [LeaderboardUser] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchLeaderboard(for tab: LeaderboardTab) {
        isLoading = true
        errorMessage = nil
        let endpoint: String
        switch tab {
        case .global:
            endpoint = "https://example.com/api/leaderboard/global"
        case .friends:
            endpoint = "https://example.com/api/leaderboard/friends"
        case .nearby:
            endpoint = "https://example.com/api/leaderboard/nearby"
        case .thisWeek:
            endpoint = "https://example.com/api/leaderboard/thisweek"
        }
        guard let url = URL(string: endpoint) else {
            self.isLoading = false
            self.errorMessage = "Invalid URL"
            return
        }
        URLSession.shared.dataTask(with: url) { @Sendable data, response, error in
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.users = []
                    return
                }
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    self?.users = []
                    return
                }
                do {
                    // Try decoding as a wrapped response first
                    if let wrapper = try? JSONDecoder().decode(LeaderboardResponse.self, from: data) {
                        self?.users = wrapper.users
                    } else {
                        // Fallback: try decoding as a top-level array
                        self?.users = try JSONDecoder().decode([LeaderboardUser].self, from: data)
                    }
                } catch {
                    self?.errorMessage = "Failed to parse leaderboard data"
                    self?.users = []
                }
            }
        }.resume()
    }
}
