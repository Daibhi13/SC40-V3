//
//  SocialModels.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import CoreLocation

/// Social features and leaderboard models
struct SocialModels {

    /// User profile for social features
    struct SocialProfile: Identifiable, Codable {
        let id: UUID
        let userId: UUID // Reference to main UserProfile
        let username: String
        let displayName: String
        let bio: String?
        let profileImageUrl: String?
        let location: String?
        let joinedDate: Date
        let isVerified: Bool
        let privacyLevel: PrivacyLevel
        let achievements: [Achievement]
        let followersCount: Int
        let followingCount: Int
        let totalSessions: Int
        let totalDistance: Double

        enum PrivacyLevel: String, Codable, CaseIterable {
            case `public` = "Public"
            case friends = "Friends Only"
            case `private` = "Private"
        }
    }

    /// Achievement system
    struct Achievement: Identifiable, Codable {
        let id: UUID
        let name: String
        let description: String
        let iconName: String
        let category: AchievementCategory
        let rarity: AchievementRarity
        let unlockedDate: Date
        let progress: Double // 0-1
        let isCompleted: Bool

        enum AchievementCategory: String, Codable, CaseIterable {
            case distance = "Distance"
            case speed = "Speed"
            case consistency = "Consistency"
            case social = "Social"
            case milestones = "Milestones"
            case challenges = "Challenges"
        }

        enum AchievementRarity: String, Codable, CaseIterable {
            case common = "Common"
            case uncommon = "Uncommon"
            case rare = "Rare"
            case epic = "Epic"
            case legendary = "Legendary"
        }
    }

    /// Leaderboard entry
    struct LeaderboardEntry: Identifiable, Codable {
        let id: UUID
        let userId: UUID
        let username: String
        let displayName: String
        let profileImageUrl: String?
        let value: Double
        let unit: String
        let rank: Int
        let change: Int // Position change from last period
        let period: LeaderboardPeriod
        let category: LeaderboardCategory

        enum LeaderboardPeriod: String, Codable, CaseIterable {
            case daily = "Daily"
            case weekly = "Weekly"
            case monthly = "Monthly"
            case yearly = "Yearly"
            case allTime = "All Time"
        }

        enum LeaderboardCategory: String, Codable, CaseIterable {
            case totalDistance = "Total Distance"
            case averageSpeed = "Average Speed"
            case maxSpeed = "Max Speed"
            case sessionsCompleted = "Sessions Completed"
            case consistency = "Consistency Score"
            case personalBests = "Personal Bests"
        }
    }

    /// Challenge system for social engagement
    struct Challenge: Identifiable, Codable {
        let id: UUID
        let name: String
        let description: String
        let type: ChallengeType
        let targetValue: Double
        let unit: String
        let startDate: Date
        let endDate: Date
        let participants: [ChallengeParticipant]
        let rewards: [ChallengeReward]
        let rules: String
        let isActive: Bool

        enum ChallengeType: String, Codable, CaseIterable {
            case distance = "Distance Challenge"
            case speed = "Speed Challenge"
            case consistency = "Consistency Challenge"
            case team = "Team Challenge"
            case streak = "Streak Challenge"
        }

        struct ChallengeParticipant: Identifiable, Codable {
            let id: UUID
            let userId: UUID
            let username: String
            let progress: Double
            let isCompleted: Bool
            let joinedDate: Date
        }

        struct ChallengeReward: Codable {
            let type: RewardType
            let value: String
            let description: String

            enum RewardType: String, Codable, CaseIterable {
                case badge = "Achievement Badge"
                case title = "Special Title"
                case discount = "Discount Code"
                case feature = "Premium Feature Access"
            }
        }
    }

    /// Social feed post
    struct SocialPost: Identifiable, Codable {
        let id: UUID
        let authorId: UUID
        let authorUsername: String
        let authorDisplayName: String
        let authorProfileImage: String?
        let content: String
        let type: PostType
        let mediaUrls: [String]
        let sessionData: SessionReference?
        let challengeData: ChallengeReference?
        let timestamp: Date
        let likes: Int
        let comments: Int
        let shares: Int
        let isLiked: Bool
        let tags: [String]
        let location: String?

        enum PostType: String, Codable, CaseIterable {
            case text = "Text Post"
            case session = "Session Share"
            case achievement = "Achievement"
            case challenge = "Challenge Update"
            case milestone = "Milestone"
        }

        struct SessionReference: Codable {
            let sessionId: UUID
            let sessionName: String
            let distance: Double
            let duration: TimeInterval
            let averageSpeed: Double
        }

        struct ChallengeReference: Codable {
            let challengeId: UUID
            let challengeName: String
            let progress: Double
        }
    }

    /// Comment on social posts
    struct Comment: Identifiable, Codable {
        let id: UUID
        let postId: UUID
        let authorId: UUID
        let authorUsername: String
        let authorDisplayName: String
        let authorProfileImage: String?
        let content: String
        let timestamp: Date
        let likes: Int
        let replies: [Reply]
        let isLiked: Bool

        struct Reply: Identifiable, Codable {
            let id: UUID
            let authorId: UUID
            let authorUsername: String
            let content: String
            let timestamp: Date
            let likes: Int
        }
    }

    /// Follow relationship
    struct FollowRelationship: Codable {
        let followerId: UUID
        let followingId: UUID
        let followedDate: Date
    }

    /// Training group/club
    struct TrainingGroup: Identifiable, Codable {
        let id: UUID
        let name: String
        let description: String
        let ownerId: UUID
        let memberCount: Int
        let isPrivate: Bool
        let location: String?
        let tags: [String]
        let createdDate: Date
        let avatarUrl: String?
    }

    /// Group membership
    struct GroupMembership: Codable {
        let groupId: UUID
        let userId: UUID
        let role: GroupRole
        let joinedDate: Date

        enum GroupRole: String, Codable, CaseIterable {
            case owner = "Owner"
            case admin = "Admin"
            case coach = "Coach"
            case member = "Member"
        }
    }

    /// Group activity feed
    struct GroupActivity: Identifiable, Codable {
        let id: UUID
        let groupId: UUID
        let type: ActivityType
        let title: String
        let description: String
        let createdBy: UUID
        let timestamp: Date
        let metadata: [String: String]

        enum ActivityType: String, Codable, CaseIterable {
            case newMember = "New Member"
            case sessionShared = "Session Shared"
            case challengeCreated = "Challenge Created"
            case announcement = "Announcement"
            case milestone = "Group Milestone"
        }
    }
}
