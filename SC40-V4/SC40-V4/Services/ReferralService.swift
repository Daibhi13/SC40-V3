import Foundation
import Combine

// MARK: - Referral Models

struct ReferralCode: Identifiable, Codable {
    let id: UUID
    let code: String
    let userId: String
    let createdAt: Date
    let expiresAt: Date?
    let maxUses: Int?
    let currentUses: Int
    let rewardType: ReferralRewardType
    let isActive: Bool
}

struct ReferralRedemption: Identifiable, Codable {
    let id: UUID
    let referralCode: String
    let referrerId: String
    let refereeId: String
    let redeemedAt: Date
    let rewardGranted: Bool
    let rewardType: ReferralRewardType
}

enum ReferralRewardType: String, Codable, CaseIterable {
    case freeWeek = "free_week"
    case proDiscount = "pro_discount"
    case premiumFeatures = "premium_features"
    case extendedTrial = "extended_trial"
    
    var displayName: String {
        switch self {
        case .freeWeek:
            return "1 Week Free Access"
        case .proDiscount:
            return "Pro Discount"
        case .premiumFeatures:
            return "Premium Features"
        case .extendedTrial:
            return "Extended Trial"
        }
    }
    
    var description: String {
        switch self {
        case .freeWeek:
            return "7 days of full access to all Sprint Coach 40 features"
        case .proDiscount:
            return "25% discount on Pro subscription"
        case .premiumFeatures:
            return "Access to premium training programs"
        case .extendedTrial:
            return "Extended 14-day trial period"
        }
    }
    
    var durationDays: Int {
        switch self {
        case .freeWeek:
            return 7
        case .proDiscount:
            return 30
        case .premiumFeatures:
            return 14
        case .extendedTrial:
            return 14
        }
    }
}

// MARK: - Referral Service

@MainActor
class ReferralService: ObservableObject {
    static let shared = ReferralService()
    
    @Published var userReferralCode: ReferralCode?
    @Published var referralStats: ReferralStats = ReferralStats()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let referralCodeKey = "UserReferralCode"
    private let referralStatsKey = "ReferralStats"
    
    private init() {
        loadCachedData()
        generateUserReferralCode()
    }
    
    // MARK: - Public Methods
    
    /// Generate a unique referral code for the current user
    func generateUserReferralCode() {
        guard userReferralCode == nil else { return }
        
        let code = generateReferralCode()
        let referralCode = ReferralCode(
            id: UUID(),
            code: code,
            userId: getCurrentUserId(),
            createdAt: Date(),
            expiresAt: nil, // Never expires
            maxUses: nil, // Unlimited uses
            currentUses: 0,
            rewardType: .freeWeek,
            isActive: true
        )
        
        self.userReferralCode = referralCode
        cacheReferralCode(referralCode)
        
        print("📱 Generated referral code: \(code)")
    }
    
    /// Generate shareable referral link
    func generateReferralLink() -> String {
        guard let code = userReferralCode?.code else {
            generateUserReferralCode()
            return generateReferralLink()
        }
        
        return "https://sprintcoach40.com/join?ref=\(code)&reward=freeweek"
    }
    
    /// Generate shareable message for social sharing
    func generateShareMessage() -> String {
        let link = generateReferralLink()
        return """
        🏃‍♂️ Join me on Sprint Coach 40 and get 1 week FREE!
        
        The best 40-yard dash training app with:
        ⚡ GPS timing & analysis
        🏆 Leaderboards & competitions  
        📊 Performance tracking
        🎯 Personalized training programs
        
        Download now: \(link)
        
        #SprintCoach40 #40YardDash #SprintTraining
        """
    }
    
    /// Redeem a referral code
    func redeemReferralCode(_ code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Validate referral code
            guard isValidReferralCode(code) else {
                errorMessage = "Invalid or expired referral code"
                isLoading = false
                return false
            }
            
            // Check if user is eligible
            guard isUserEligibleForReferral() else {
                errorMessage = "This offer is only available to new users"
                isLoading = false
                return false
            }
            
            // Grant reward
            let success = await grantReferralReward(.freeWeek)
            
            if success {
                // Track redemption
                let redemption = ReferralRedemption(
                    id: UUID(),
                    referralCode: code,
                    referrerId: "referrer_id", // Would come from API
                    refereeId: getCurrentUserId(),
                    redeemedAt: Date(),
                    rewardGranted: true,
                    rewardType: .freeWeek
                )
                
                trackRedemption(redemption)
                updateReferralStats()
                
                print("✅ Referral code redeemed successfully")
            }
            
            isLoading = false
            return success
            
        } catch {
            errorMessage = "Failed to redeem referral code: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Grant referral reward to user
    private func grantReferralReward(_ rewardType: ReferralRewardType) async -> Bool {
        // In a real app, this would call your backend API
        // For now, we'll simulate granting the reward locally
        
        switch rewardType {
        case .freeWeek:
            // Grant 7 days of Pro access
            let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            UserDefaults.standard.set(expirationDate, forKey: "ReferralProExpirationDate")
            UserDefaults.standard.set(true, forKey: "HasActiveReferralReward")
            
        case .proDiscount:
            // Grant discount for next purchase
            UserDefaults.standard.set(0.25, forKey: "ReferralDiscountPercentage")
            UserDefaults.standard.set(true, forKey: "HasReferralDiscount")
            
        case .premiumFeatures:
            // Grant premium features access
            let expirationDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
            UserDefaults.standard.set(expirationDate, forKey: "PremiumFeaturesExpirationDate")
            
        case .extendedTrial:
            // Extend trial period
            let expirationDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
            UserDefaults.standard.set(expirationDate, forKey: "ExtendedTrialExpirationDate")
        }
        
        return true
    }
    
    /// Check if user has active referral rewards
    func hasActiveReferralReward() -> Bool {
        guard UserDefaults.standard.bool(forKey: "HasActiveReferralReward") else { return false }
        
        if let expirationDate = UserDefaults.standard.object(forKey: "ReferralProExpirationDate") as? Date {
            return Date() < expirationDate
        }
        
        return false
    }
    
    /// Get remaining days of referral reward
    func getReferralRewardDaysRemaining() -> Int {
        guard hasActiveReferralReward(),
              let expirationDate = UserDefaults.standard.object(forKey: "ReferralProExpirationDate") as? Date else {
            return 0
        }
        
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, daysRemaining)
    }
    
    // MARK: - Private Methods
    
    private func generateReferralCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 8
        
        var code = ""
        for _ in 0..<codeLength {
            let randomIndex = Int.random(in: 0..<characters.count)
            let character = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            code.append(character)
        }
        
        return code
    }
    
    private func getCurrentUserId() -> String {
        // In a real app, this would return the actual user ID
        if let userId = UserDefaults.standard.string(forKey: "CurrentUserId") {
            return userId
        }
        
        let newUserId = UUID().uuidString
        UserDefaults.standard.set(newUserId, forKey: "CurrentUserId")
        return newUserId
    }
    
    private func isValidReferralCode(_ code: String) -> Bool {
        // In a real app, this would validate against your backend
        // For demo purposes, accept any 8-character alphanumeric code
        return code.count == 8 && code.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    private func isUserEligibleForReferral() -> Bool {
        // Check if user has already redeemed a referral code
        return !UserDefaults.standard.bool(forKey: "HasRedeemedReferralCode")
    }
    
    private func trackRedemption(_ redemption: ReferralRedemption) {
        UserDefaults.standard.set(true, forKey: "HasRedeemedReferralCode")
        
        // In a real app, send to analytics/backend
        print("📊 Tracked referral redemption: \(redemption.referralCode)")
    }
    
    private func updateReferralStats() {
        referralStats.totalRedemptions += 1
        referralStats.rewardsGranted += 1
        cacheReferralStats()
    }
    
    // MARK: - Caching
    
    private func cacheReferralCode(_ code: ReferralCode) {
        do {
            let data = try JSONEncoder().encode(code)
            userDefaults.set(data, forKey: referralCodeKey)
        } catch {
            print("❌ Failed to cache referral code: \(error)")
        }
    }
    
    private func cacheReferralStats() {
        do {
            let data = try JSONEncoder().encode(referralStats)
            userDefaults.set(data, forKey: referralStatsKey)
        } catch {
            print("❌ Failed to cache referral stats: \(error)")
        }
    }
    
    private func loadCachedData() {
        // Load referral code
        if let data = userDefaults.data(forKey: referralCodeKey),
           let code = try? JSONDecoder().decode(ReferralCode.self, from: data) {
            self.userReferralCode = code
        }
        
        // Load referral stats
        if let data = userDefaults.data(forKey: referralStatsKey),
           let stats = try? JSONDecoder().decode(ReferralStats.self, from: data) {
            self.referralStats = stats
        }
    }
}

// MARK: - Referral Stats

struct ReferralStats: Codable {
    var totalRedemptions: Int = 0
    var rewardsGranted: Int = 0
    var totalReferrals: Int = 0
    var conversionRate: Double {
        guard totalReferrals > 0 else { return 0.0 }
        return Double(totalRedemptions) / Double(totalReferrals)
    }
}

// MARK: - Referral Analytics

extension ReferralService {
    
    /// Track referral link share
    func trackReferralShare(method: ShareMethod) {
        referralStats.totalReferrals += 1
        cacheReferralStats()
        
        // In a real app, send to analytics
        print("📈 Referral shared via \(method.rawValue)")
    }
    
    /// Get referral performance metrics
    func getReferralMetrics() -> ReferralMetrics {
        return ReferralMetrics(
            totalShares: referralStats.totalReferrals,
            totalRedemptions: referralStats.totalRedemptions,
            conversionRate: referralStats.conversionRate,
            rewardsGranted: referralStats.rewardsGranted,
            estimatedValue: Double(referralStats.rewardsGranted) * 9.99 // Assuming $9.99 value per reward
        )
    }
}

enum ShareMethod: String, CaseIterable {
    case messages = "messages"
    case email = "email"
    case social = "social"
    case copyLink = "copy_link"
    case other = "other"
}

struct ReferralMetrics {
    let totalShares: Int
    let totalRedemptions: Int
    let conversionRate: Double
    let rewardsGranted: Int
    let estimatedValue: Double
}
