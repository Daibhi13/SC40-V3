import Foundation
import Combine

// MARK: - Social Models (Detailed Implementation)
struct SocialModels {
    
    // MARK: - Leaderboard Entry
    struct LeaderboardEntry: Identifiable, Codable {
        let id: UUID
        let userId: String
        let username: String
        let distance: Double // meters
        let time: TimeInterval // seconds
        let date: Date
        let profileImage: String?
        let ageGroup: String?
        let location: String?
        
        // MARK: - Computed Properties
        var speed: Double {
            return distance / time // m/s
        }
        
        var pace: TimeInterval {
            return time / (distance / 1000) // seconds per km
        }
        
        var formattedTime: String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        var formattedPace: String {
            let paceMinutes = Int(pace) / 60
            let paceSeconds = Int(pace) % 60
            return String(format: "%d:%02d/km", paceMinutes, paceSeconds)
        }
    }
    
    // MARK: - Challenge Model
    struct Challenge: Identifiable, Codable {
        let id: UUID
        let name: String
        let description: String
        let distance: Double // meters
        let targetTime: TimeInterval // seconds
        var participants: [String]
        let startDate: Date
        let endDate: Date
        let isActive: Bool
        let createdBy: String
        let challengeType: ChallengeType
        let maxParticipants: Int?
        let entryFee: Double?
        
        enum ChallengeType: String, Codable {
            case speed, endurance, consistency, headToHead
        }
        
        // MARK: - Computed Properties
        var duration: TimeInterval {
            return endDate.timeIntervalSince(startDate)
        }
        
        var participantCount: Int {
            return participants.count
        }
        
        var isFull: Bool {
            guard let max = maxParticipants else { return false }
            return participantCount >= max
        }
        
        var daysRemaining: Int {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            return max(0, days)
        }
    }
    
    // MARK: - User Stats Model
    struct UserStats: Codable {
        let userId: String
        let totalDistance: Double // meters
        let totalSessions: Int
        let averageSpeed: Double // m/s
        let personalBests: [String: TimeInterval] // distance: time
        let streakCount: Int // consecutive days
        let rank: Int
        let followers: Int
        let following: Int
        let achievements: [Achievement]
        
        struct Achievement: Identifiable, Codable {
            let id: UUID
            let name: String
            let description: String
            let icon: String
            let unlockedAt: Date
            let rarity: Rarity
            
            enum Rarity: String, Codable {
                case common, rare, epic, legendary
            }
        }
    }
    
    // MARK: - Social Feed Models
    struct FeedItem: Identifiable, Codable {
        let id: UUID
        let userId: String
        let username: String
        let type: FeedItemType
        let content: String
        let imageUrl: String?
        let createdAt: Date
        let likes: Int
        let comments: Int
        let isLiked: Bool
        
        enum FeedItemType: String, Codable {
            case workout, achievement, challenge, milestone
        }
    }
    
    // MARK: - Comment Model
    struct Comment: Identifiable, Codable {
        let id: UUID
        let feedItemId: UUID
        let userId: String
        let username: String
        let content: String
        let createdAt: Date
        let likes: Int
    }
}

// MARK: - Social Manager
class SocialManager: ObservableObject {
    @Published var leaderboard: [SocialModels.LeaderboardEntry] = []
    @Published var challenges: [SocialModels.Challenge] = []
    @Published var userStats: SocialModels.UserStats?
    @Published var feedItems: [SocialModels.FeedItem] = []
    @Published var isLoading = false
    
    // MARK: - Leaderboard Management
    func loadLeaderboard(for distance: Double) {
        // Implementation would fetch from API or local storage
        isLoading = true
        // Simulated data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.leaderboard = self.generateMockLeaderboard(distance: distance)
            self.isLoading = false
        }
    }
    
    func submitScore(distance: Double, time: TimeInterval) {
        let entry = SocialModels.LeaderboardEntry(
            id: UUID(),
            userId: "currentUser",
            username: "Current User",
            distance: distance,
            time: time,
            date: Date(),
            profileImage: nil,
            ageGroup: nil,
            location: nil
        )
        
        // Insert in correct position based on time
        leaderboard.append(entry)
        leaderboard.sort { $0.time < $1.time }
    }
    
    // MARK: - Challenge Management
    func loadChallenges() {
        isLoading = true
        // Implementation would fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.challenges = self.generateMockChallenges()
            self.isLoading = false
        }
    }
    
    func joinChallenge(_ challenge: SocialModels.Challenge) {
        // Implementation would send join request to API
        if var updatedChallenge = challenges.first(where: { $0.id == challenge.id }) {
            if !updatedChallenge.participants.contains("currentUser") {
                updatedChallenge.participants.append("currentUser")
                // Update the challenge in array
                if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
                    challenges[index] = updatedChallenge
                }
            }
        }
    }
    
    // MARK: - Mock Data Generators
    private func generateMockLeaderboard(distance: Double) -> [SocialModels.LeaderboardEntry] {
        return [
            SocialModels.LeaderboardEntry(id: UUID(), userId: "1", username: "SpeedRunner", distance: distance, time: 11.2, date: Date(), profileImage: nil, ageGroup: nil, location: nil),
            SocialModels.LeaderboardEntry(id: UUID(), userId: "2", username: "FastFeet", distance: distance, time: 11.8, date: Date(), profileImage: nil, ageGroup: nil, location: nil),
            SocialModels.LeaderboardEntry(id: UUID(), userId: "3", username: "QuickStart", distance: distance, time: 12.1, date: Date(), profileImage: nil, ageGroup: nil, location: nil),
        ]
    }
    
    private func generateMockChallenges() -> [SocialModels.Challenge] {
        return [
            SocialModels.Challenge(
                id: UUID(),
                name: "100m Sprint Challenge",
                description: "Beat your personal best in the 100m sprint!",
                distance: 100,
                targetTime: 12.0,
                participants: ["user1", "user2"],
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 3600),
                isActive: true,
                createdBy: "admin",
                challengeType: .speed,
                maxParticipants: 50,
                entryFee: nil
            )
        ]
    }
}
