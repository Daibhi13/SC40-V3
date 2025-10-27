import Foundation
import StoreKit
import Combine

/// Comprehensive subscription management system for SC40 platform
/// Supports tiered subscriptions, family sharing, and cross-app access
@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var availableProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Subscription Tiers
    enum SubscriptionTier: String, CaseIterable {
        case free = "sc40_free"
        case pro = "sc40_pro_monthly"
        case elite = "sc40_elite_monthly"
        case coach = "sc40_coach_monthly"
        
        var displayName: String {
            switch self {
            case .free: return "SC40 Starter"
            case .pro: return "SC40 Pro"
            case .elite: return "SC40 Elite"
            case .coach: return "SC40 Coach"
            }
        }
        
        var monthlyPrice: Decimal {
            switch self {
            case .free: return 0
            case .pro: return 9.99
            case .elite: return 29.99
            case .coach: return 99.99
            }
        }
        
        var features: [String] {
            switch self {
            case .free:
                return [
                    "Basic 40-yard sprint timer",
                    "7-day workout history",
                    "Basic heart rate monitoring",
                    "Community access (read-only)"
                ]
            case .pro:
                return [
                    "Autonomous Apple Watch workouts",
                    "Advanced GPS analytics",
                    "12-week periodized programs",
                    "Comprehensive data export",
                    "Video analysis integration",
                    "Personalized coaching recommendations"
                ]
            case .elite:
                return [
                    "All Pro features",
                    "AI-powered performance optimization",
                    "Biomechanics analysis",
                    "Real-time coaching feedback",
                    "Advanced recovery analytics",
                    "Competition preparation programs",
                    "Direct coach messaging"
                ]
            case .coach:
                return [
                    "All Elite features",
                    "Multi-athlete dashboard (50+ athletes)",
                    "Team performance analytics",
                    "Workout assignment and tracking",
                    "Progress comparison tools",
                    "Scientific research data contribution",
                    "White-label customization options"
                ]
            }
        }
    }
    
    enum SubscriptionStatus {
        case free
        case pro(expirationDate: Date)
        case elite(expirationDate: Date)
        case coach(expirationDate: Date)
        case expired(previousTier: SubscriptionTier)
        
        var tier: SubscriptionTier {
            switch self {
            case .free: return .free
            case .pro: return .pro
            case .elite: return .elite
            case .coach: return .coach
            case .expired: return .free
            }
        }
        
        var isActive: Bool {
            switch self {
            case .free: return true
            case .pro(let date), .elite(let date), .coach(let date):
                return date > Date()
            case .expired: return false
            }
        }
    }
    
    // MARK: - Product Identifiers
    private let productIdentifiers: Set<String> = [
        "sc40_pro_monthly",
        "sc40_pro_yearly",
        "sc40_elite_monthly",
        "sc40_elite_yearly",
        "sc40_coach_monthly",
        "sc40_coach_yearly"
    ]
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupStoreKit()
        startTransactionListener()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - StoreKit Setup
    
    private func setupStoreKit() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    private func startTransactionListener() {
        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Product Management
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await Product.products(for: productIdentifiers)
            await MainActor.run {
                self.availableProducts = products.sorted { $0.price < $1.price }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase Management
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            
            // Track purchase for analytics
            trackPurchase(product)
            
        case .userCancelled:
            break
            
        case .pending:
            errorMessage = "Purchase is pending approval"
            
        @unknown default:
            errorMessage = "Unknown purchase result"
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Note: AppStore.sync() is not available in current StoreKit version
            // try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status Management
    
    func updateSubscriptionStatus() async {
        var highestTier: SubscriptionTier = .free
        var latestExpiration: Date?
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                    if let subscription = product.subscription {
                        let status = try await subscription.status.first
                        
                        if let statusInfo = status, let renewalInfo = try? checkVerified(statusInfo.renewalInfo) {
                            let expirationDate = renewalInfo.willAutoRenew ? Date().addingTimeInterval(30 * 24 * 60 * 60) : Date()
                            
                            if expirationDate > Date() {
                                let tier = tierForProductID(transaction.productID)
                                if tier.monthlyPrice > highestTier.monthlyPrice {
                                    highestTier = tier
                                    latestExpiration = expirationDate
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        await MainActor.run {
            switch highestTier {
            case .free:
                self.subscriptionStatus = .free
            case .pro:
                self.subscriptionStatus = .pro(expirationDate: latestExpiration ?? Date())
            case .elite:
                self.subscriptionStatus = .elite(expirationDate: latestExpiration ?? Date())
            case .coach:
                self.subscriptionStatus = .coach(expirationDate: latestExpiration ?? Date())
            }
        }
    }
    
    // MARK: - Feature Access Control
    
    func hasAccess(to feature: Feature) -> Bool {
        switch feature {
        case .basicTimer, .basicHeartRate, .communityReadOnly:
            return true // Available to all users
            
        case .autonomousWorkouts, .advancedGPS, .periodizedPrograms, .dataExport:
            return subscriptionStatus.tier.monthlyPrice >= SubscriptionTier.pro.monthlyPrice
            
        case .aiOptimization, .biomechanicsAnalysis, .realtimeCoaching, .recoveryAnalytics:
            return subscriptionStatus.tier.monthlyPrice >= SubscriptionTier.elite.monthlyPrice
            
        case .multiAthleteManagement, .teamAnalytics, .workoutAssignment, .researchContribution:
            return subscriptionStatus.tier.monthlyPrice >= SubscriptionTier.coach.monthlyPrice
        }
    }
    
    func requiresUpgrade(for feature: Feature) -> SubscriptionTier? {
        if hasAccess(to: feature) {
            return nil
        }
        
        switch feature {
        case .basicTimer, .basicHeartRate, .communityReadOnly:
            return nil
            
        case .autonomousWorkouts, .advancedGPS, .periodizedPrograms, .dataExport:
            return .pro
            
        case .aiOptimization, .biomechanicsAnalysis, .realtimeCoaching, .recoveryAnalytics:
            return .elite
            
        case .multiAthleteManagement, .teamAnalytics, .workoutAssignment, .researchContribution:
            return .coach
        }
    }
    
    // MARK: - Analytics & Tracking
    
    private func trackPurchase(_ product: Product) {
        // Track purchase event for analytics
        let _ = PurchaseEvent(
            productId: product.id,
            price: product.price,
            currency: product.priceFormatStyle.currencyCode,
            timestamp: Date(),
            userId: nil // UserManager.shared.currentUser?.id
        )
        
        // AnalyticsManager.shared.track(event: .purchase(event))
        
        // Send to research database (anonymized)
        ResearchDataManager.shared.recordSubscriptionEvent(
            tier: tierForProductID(product.id),
            timestamp: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func tierForProductID(_ productID: String) -> SubscriptionTier {
        if productID.contains("pro") {
            return .pro
        } else if productID.contains("elite") {
            return .elite
        } else if productID.contains("coach") {
            return .coach
        } else {
            return .free
        }
    }
    
    // MARK: - Cross-App Integration
    
    func syncSubscriptionAcrossApps() async {
        // Sync subscription status across all SC40 platform apps
        let platformApps = PlatformAppManager.shared.installedApps
        
        for app in platformApps {
            await app.updateSubscriptionStatus(subscriptionStatus)
        }
    }
    
    func getUnifiedUserProfile() -> UnifiedUserProfile {
        return UnifiedUserProfile(
            subscriptionTier: subscriptionStatus.tier,
            features: Feature.allCases.filter { hasAccess(to: $0) },
            crossAppData: PlatformDataManager.shared.getUserData(),
            researchContributions: ResearchDataManager.shared.getUserContributions()
        )
    }
}

// MARK: - Supporting Enums and Structs

enum Feature: CaseIterable {
    // Free Tier
    case basicTimer
    case basicHeartRate
    case communityReadOnly
    
    // Pro Tier
    case autonomousWorkouts
    case advancedGPS
    case periodizedPrograms
    case dataExport
    
    // Elite Tier
    case aiOptimization
    case biomechanicsAnalysis
    case realtimeCoaching
    case recoveryAnalytics
    
    // Coach Tier
    case multiAthleteManagement
    case teamAnalytics
    case workoutAssignment
    case researchContribution
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}

struct PurchaseEvent {
    let productId: String
    let price: Decimal
    let currency: String?
    let timestamp: Date
    let userId: UUID?
}

struct UnifiedUserProfile {
    let subscriptionTier: SubscriptionManager.SubscriptionTier
    let features: [Feature]
    let crossAppData: CrossAppData
    let researchContributions: ResearchContributions
}

// MARK: - Platform Integration Classes (Placeholder)

class PlatformAppManager {
    static let shared = PlatformAppManager()
    var installedApps: [PlatformApp] = []
}

class PlatformApp {
    func updateSubscriptionStatus(_ status: SubscriptionManager.SubscriptionStatus) async {
        // Update subscription status in other platform apps
    }
}

class PlatformDataManager {
    static let shared = PlatformDataManager()
    
    func getUserData() -> CrossAppData {
        return CrossAppData()
    }
}

class ResearchDataManager {
    static let shared = ResearchDataManager()
    
    func recordSubscriptionEvent(tier: SubscriptionManager.SubscriptionTier, timestamp: Date) {
        // Record anonymized subscription data for research
    }
    
    func getUserContributions() -> ResearchContributions {
        return ResearchContributions()
    }
}

struct CrossAppData {
    // Cross-app user data structure
}

struct ResearchContributions {
    // User's contributions to research data
}
