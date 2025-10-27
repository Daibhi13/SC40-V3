import Foundation
import GameKit
import SwiftUI
import Combine

/// GameKit integration for achievements, leaderboards, and social features
@MainActor
class GameKitManager: NSObject, ObservableObject {
    static let shared = GameKitManager()
    
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var achievements: [GKAchievement] = []
    @Published var leaderboards: [GKLeaderboard] = []
    @Published var friends: [GKPlayer] = []
    @Published var challenges: [GKChallenge] = []
    
    // Achievement IDs (configure these in App Store Connect)
    private let achievementIDs = [
        "first_sprint": "com.sc40.achievement.first_sprint",
        "sub_5_seconds": "com.sc40.achievement.sub_5_seconds",
        "week_streak": "com.sc40.achievement.week_streak",
        "month_streak": "com.sc40.achievement.month_streak",
        "perfect_form": "com.sc40.achievement.perfect_form",
        "speed_demon": "com.sc40.achievement.speed_demon",
        "consistency_king": "com.sc40.achievement.consistency_king",
        "improvement_master": "com.sc40.achievement.improvement_master"
    ]
    
    // Leaderboard IDs
    private let leaderboardIDs = [
        "com.sc40.leaderboard.fastest_40_yard",
        "com.sc40.leaderboard.weekly_sessions",
        "com.sc40.leaderboard.total_distance",
        "com.sc40.leaderboard.improvement_rate"
    ]
    
    private let leaderboardIDMap = [
        "fastest_40_yard": "com.sc40.leaderboard.fastest_40_yard",
        "weekly_sessions": "com.sc40.leaderboard.weekly_sessions",
        "total_distance": "com.sc40.leaderboard.total_distance",
        "improvement_rate": "com.sc40.leaderboard.improvement_rate"
    ]
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    // MARK: - Authentication
    
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let viewController = viewController {
                // Present authentication view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(viewController, animated: true)
                }
            } else if let error = error {
                print("GameKit authentication error: \(error.localizedDescription)")
                self?.isAuthenticated = false
            } else {
                // Successfully authenticated
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.localPlayer = GKLocalPlayer.local
                self?.loadGameKitData()
                print("GameKit authenticated: \(GKLocalPlayer.local.displayName)")
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadGameKitData() {
        Task {
            await loadAchievements()
            await loadLeaderboards()
            await loadFriends()
            await loadChallenges()
        }
    }
    
    @MainActor
    private func loadAchievements() async {
        do {
            let loadedAchievements = try await GKAchievement.loadAchievements()
            self.achievements = loadedAchievements
        } catch {
            print("Failed to load achievements: \(error)")
        }
    }
    
    @MainActor
    private func loadLeaderboards() async {
        do {
            let loadedLeaderboards = try await GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs)
            self.leaderboards = loadedLeaderboards
        } catch {
            print("Failed to load leaderboards: \(error)")
        }
    }
    
    @MainActor
    private func loadFriends() async {
        do {
            let loadedFriends = try await GKLocalPlayer.local.loadFriends()
            self.friends = loadedFriends
        } catch {
            print("Failed to load friends: \(error)")
        }
    }
    
    @MainActor
    private func loadChallenges() async {
        do {
            let loadedChallenges = try await GKChallenge.loadReceivedChallenges()
            self.challenges = loadedChallenges
        } catch {
            print("Failed to load challenges: \(error)")
        }
    }
    
    // MARK: - Achievements
    
    func unlockAchievement(_ achievementID: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to report achievement: \(error)")
            } else {
                print("Achievement unlocked: \(achievementID)")
            }
        }
    }
    
    // Sprint-specific achievement triggers
    func checkSprintAchievements(time: Double, isFirstSprint: Bool, weekStreak: Int, monthStreak: Int) {
        if isFirstSprint {
            unlockAchievement(achievementIDs["first_sprint"]!)
        }
        
        if time < 5.0 {
            unlockAchievement(achievementIDs["sub_5_seconds"]!)
        }
        
        if time < 4.5 {
            unlockAchievement(achievementIDs["speed_demon"]!)
        }
        
        if weekStreak >= 7 {
            unlockAchievement(achievementIDs["week_streak"]!)
        }
        
        if monthStreak >= 30 {
            unlockAchievement(achievementIDs["month_streak"]!)
        }
    }
    
    func checkFormAchievement(techniqueScore: Double) {
        if techniqueScore >= 95.0 {
            unlockAchievement(achievementIDs["perfect_form"]!)
        }
    }
    
    func checkConsistencyAchievement(consistency: Double) {
        if consistency >= 90.0 {
            unlockAchievement(achievementIDs["consistency_king"]!)
        }
    }
    
    func checkImprovementAchievement(improvementRate: Double) {
        if improvementRate >= 10.0 { // 10% improvement
            unlockAchievement(achievementIDs["improvement_master"]!)
        }
    }
    
    // MARK: - Leaderboards
    
    func submitScore(_ score: Int64, to leaderboardID: String) {
        guard isAuthenticated else { return }
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    Int(score),
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                print("Score submitted to leaderboard: \(leaderboardID)")
            } catch {
                print("Failed to submit score: \(error)")
            }
        }
    }
    
    func submitSprintTime(_ time: Double) {
        let timeInMilliseconds = Int64(time * 1000)
        submitScore(timeInMilliseconds, to: leaderboardIDMap["fastest_40_yard"]!)
    }
    
    func submitWeeklySessionCount(_ count: Int) {
        submitScore(Int64(count), to: leaderboardIDMap["weekly_sessions"]!)
    }
    
    func submitTotalDistance(_ distance: Double) {
        let distanceInMeters = Int64(distance)
        submitScore(distanceInMeters, to: leaderboardIDMap["total_distance"]!)
    }
    
    func submitImprovementRate(_ rate: Double) {
        let rateAsPercentage = Int64(rate * 100)
        submitScore(rateAsPercentage, to: leaderboardIDMap["improvement_rate"]!)
    }
    
    // MARK: - Social Features
    
    func sendChallenge(to players: [GKPlayer], message: String, score: Int64) {
        guard isAuthenticated else { return }
        
        // Create and send challenge
        // Note: This requires specific leaderboard setup in App Store Connect
        print("Sending challenge to \(players.count) players with score: \(score)")
    }
    
    func inviteFriends() {
        guard isAuthenticated else { return }
        
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 8
        
        if let matchmakerVC = GKMatchmakerViewController(matchRequest: request) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(matchmakerVC, animated: true)
            }
        }
    }
    
    // MARK: - UI Presentation
    
    func showAchievements() {
        guard isAuthenticated else { return }
        
        let achievementsVC = GKGameCenterViewController(state: .achievements)
        achievementsVC.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(achievementsVC, animated: true)
        }
    }
    
    func showLeaderboards() {
        guard isAuthenticated else { return }
        
        let leaderboardVC = GKGameCenterViewController(state: .leaderboards)
        leaderboardVC.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(leaderboardVC, animated: true)
        }
    }
    
    func showGameCenter() {
        guard isAuthenticated else { return }
        
        let gameCenterVC = GKGameCenterViewController(state: .default)
        gameCenterVC.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(gameCenterVC, animated: true)
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameKitManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - Achievement Helper

struct SC40Achievement {
    let id: String
    let title: String
    let description: String
    let points: Int
    let isUnlocked: Bool
    let progress: Double
}

extension GameKitManager {
    func getAchievementProgress() -> [SC40Achievement] {
        let achievementData = [
            ("first_sprint", "First Sprint", "Complete your first 40-yard sprint", 10),
            ("sub_5_seconds", "Sub-5 Second Sprint", "Run a 40-yard sprint in under 5 seconds", 25),
            ("week_streak", "Week Warrior", "Complete workouts for 7 consecutive days", 20),
            ("month_streak", "Monthly Master", "Complete workouts for 30 consecutive days", 50),
            ("perfect_form", "Perfect Form", "Achieve 95%+ technique score", 30),
            ("speed_demon", "Speed Demon", "Run a 40-yard sprint in under 4.5 seconds", 50),
            ("consistency_king", "Consistency King", "Maintain 90%+ consistency for a month", 40),
            ("improvement_master", "Improvement Master", "Improve your time by 10% or more", 35)
        ]
        
        return achievementData.map { (id, title, description, points) in
            let gkAchievement = achievements.first { $0.identifier == achievementIDs[id] }
            return SC40Achievement(
                id: id,
                title: title,
                description: description,
                points: points,
                isUnlocked: gkAchievement?.isCompleted ?? false,
                progress: gkAchievement?.percentComplete ?? 0.0
            )
        }
    }
}
