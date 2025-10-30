import Foundation
import Combine
import StoreKit

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // Required for ObservableObject conformance
    var objectWillChange = ObservableObjectPublisher()

    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case monthlySubscription = "com.accelerate.sc40.monthly"
        case yearlySubscription = "com.accelerate.sc40.yearly" 
        case lifetimeUnlock = "com.accelerate.sc40.lifetime"
        case starterProUnlock = "com.accelerate.sc40.starterpro"
        
        var displayName: String {
            switch self {
            case .monthlySubscription: return "Monthly Pro"
            case .yearlySubscription: return "Yearly Pro"
            case .lifetimeUnlock: return "Lifetime Access"
            case .starterProUnlock: return "Starter Pro"
            }
        }
        
        var description: String {
            switch self {
            case .monthlySubscription: return "Full access to all pro features"
            case .yearlySubscription: return "Full access to all pro features (Save 58%)"
            case .lifetimeUnlock: return "One-time purchase for unlimited access"
            case .starterProUnlock: return "Professional timing and analytics"
            }
        }
    }
    
    // MARK: - Purchase Results
    enum PurchaseResult {
        case success
        case userCancelled
        case pending
        case failed(Error)
    }
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        
        // For development/testing - simulate some products
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load products from App Store Connect
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            
            await MainActor.run {
                self.products = storeProducts.sorted { product1, product2 in
                    // Sort by price, lowest first
                    product1.price < product2.price
                }
                self.isLoading = false
            }
            
            await updatePurchasedProducts()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Purchase a product
    func purchase(_ product: Product) async -> PurchaseResult {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Successfully verified transaction
                    await transaction.finish()
                    await updatePurchasedProducts()
                    
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return .success
                    
                case .unverified(_, let verificationError):
                    await MainActor.run {
                        self.errorMessage = "Transaction verification failed: \(verificationError.localizedDescription)"
                        self.isLoading = false
                    }
                    return .failed(verificationError)
                }
                
            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                return .userCancelled
                
            case .pending:
                await MainActor.run {
                    self.isLoading = false
                }
                return .pending
                
            @unknown default:
                await MainActor.run {
                    self.errorMessage = "Unknown purchase result"
                    self.isLoading = false
                }
                return .failed(NSError(domain: "StoreKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown purchase result"]))
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            return .failed(error)
        }
    }
    
    /// Purchase by product ID (for legacy compatibility)
    func purchase(productID: String) async -> PurchaseResult {
        guard let product = products.first(where: { $0.id == productID }) else {
            await MainActor.run {
                self.errorMessage = "Product not found: \(productID)"
            }
            return .failed(NSError(domain: "StoreKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Product not found"]))
        }
        
        return await purchase(product)
    }
    
    /// Restore purchases
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Sync App Store receipts and update purchased products
        await updatePurchasedProducts()
        
        await MainActor.run {
            self.isLoading = false
        }
        return true
    }
    
    /// Check if user has active subscription or lifetime access
    func hasProAccess() -> Bool {
        return purchasedProductIDs.contains(ProductID.lifetimeUnlock.rawValue) ||
               purchasedProductIDs.contains(ProductID.monthlySubscription.rawValue) ||
               purchasedProductIDs.contains(ProductID.yearlySubscription.rawValue)
    }
    
    /// Check if user has Starter Pro access
    func hasStarterProAccess() -> Bool {
        return hasProAccess() || purchasedProductIDs.contains(ProductID.starterProUnlock.rawValue)
    }
    
    /// Get product by ID
    func product(for productID: ProductID) -> Product? {
        return products.first { $0.id == productID.rawValue }
    }
    
    // MARK: - Development/Testing Methods
    
    /// Simulate purchase for development (remove in production)
    func simulatePurchase(productID: ProductID) {
        purchasedProductIDs.insert(productID.rawValue)
        print("🛒 Simulated purchase: \(productID.displayName)")
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProducts.insert(transaction.productID)
                
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchasedProducts
        }
    }
    
    private nonisolated func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signedType):
            return signedType
        case .unverified(_, let verificationError):
            throw verificationError
        }
    }
}

// MARK: - Convenience Extensions

extension Product {
    var localizedPrice: String {
        return priceFormatStyle.format(price)
    }
    
    var isSubscription: Bool {
        return type == .autoRenewable
    }
    
    var subscriptionPeriod: String? {
        guard let subscription = subscription else { return nil }
        
        let period = subscription.subscriptionPeriod
        let unit = period.unit
        let value = period.value
        
        switch unit {
        case .day:
            return value == 1 ? "Daily" : "\(value) Days"
        case .week:
            return value == 1 ? "Weekly" : "\(value) Weeks"
        case .month:
            return value == 1 ? "Monthly" : "\(value) Months"
        case .year:
            return value == 1 ? "Yearly" : "\(value) Years"
        @unknown default:
            return "Unknown"
        }
    }
}
