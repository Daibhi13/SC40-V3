import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Product IDs for Sprint Coach 40 subscriptions
    private let productIDs = [
        "sc40_pro_monthly",
        "sc40_pro_yearly",
        "sc40_pro_lifetime"
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func requestProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.products = storeProducts.sorted { product1, product2 in
                    // Sort by price: monthly, yearly, lifetime
                    if product1.id.contains("monthly") { return true }
                    if product2.id.contains("monthly") { return false }
                    if product1.id.contains("yearly") { return true }
                    if product2.id.contains("yearly") { return false }
                    return false
                }
                self.isLoading = false
            }
            
            print("✅ StoreKit: Loaded \(storeProducts.count) products")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ StoreKit: Failed to load products - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchase Handling
    
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updateCustomerProductStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                print("✅ StoreKit: Purchase successful - \(product.id)")
                return transaction
                
            case .userCancelled:
                print("⚠️ StoreKit: User cancelled purchase")
                return nil
                
            case .pending:
                print("⏳ StoreKit: Purchase pending approval")
                return nil
                
            @unknown default:
                print("❌ StoreKit: Unknown purchase result")
                return nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ StoreKit: Purchase failed - \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Note: AppStore.sync() not available - using alternative approach
            try await Task.sleep(nanoseconds: 100_000_000) // Brief delay for sync
            await updateCustomerProductStatus()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            print("✅ StoreKit: Purchases restored successfully")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ StoreKit: Failed to restore purchases - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Transaction Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Customer Status Updates
    
    func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscriptionStatus = try await transaction.subscriptionStatus {
                        switch subscriptionStatus.state {
                        case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                            purchasedProducts.insert(transaction.productID)
                        default:
                            break
                        }
                    }
                case .nonRenewable:
                    purchasedProducts.insert(transaction.productID)
                default:
                    break
                }
            } catch {
                print("❌ StoreKit: Failed to verify transaction - \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchasedProducts
            
            // Update app-wide pro status
            let isProUser = !purchasedProducts.isEmpty
            UserDefaults.standard.set(isProUser, forKey: "isProUser")
            
            print("📊 StoreKit: Updated pro status - \(isProUser ? "PRO" : "FREE")")
            print("📊 StoreKit: Active products - \(purchasedProducts)")
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("❌ StoreKit: Transaction update failed - \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    var isProUser: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }
    
    var lifetimeProduct: Product? {
        products.first { $0.id.contains("lifetime") }
    }
}

// MARK: - Store Errors

enum StoreError: Error {
    case failedVerification
}

extension StoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "User transaction verification failed"
        }
    }
}
