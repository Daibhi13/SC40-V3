import SwiftUI
import StoreKit

struct StarterProPurchaseView: View {
    @State private var isUnlocked = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var products: [Product] = []
    @State private var purchasedProductIDs: Set<String> = []
    
    private let starterProProductID = "com.accelerate.sc40.starterpro"
    private let monthlyProductID = "com.accelerate.sc40.monthly"
    private let yearlyProductID = "com.accelerate.sc40.yearly"
    private let lifetimeProductID = "com.accelerate.sc40.lifetime"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if isPurchasing {
                        ProgressView("Processing purchase...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if products.isEmpty {
                        loadingSection
                    } else {
                        productsSection
                    }
                    
                    if let error = purchaseError {
                        errorSection(error)
                    }
                    
                    restoreButton
                }
                .padding()
            }
            .navigationTitle("Upgrade to Pro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .task {
            await loadProducts()
            await checkPurchasedProducts()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            Text("Unlock Premium Features")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            Text("Get access to Starter Pro timing, advanced analytics, and unlimited training sessions")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading products...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var productsSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(products, id: \.id) { product in
                ProductPurchaseCard(
                    product: product,
                    isPurchased: purchasedProductIDs.contains(product.id),
                    isLoading: isPurchasing,
                    onPurchase: {
                        Task {
                            await purchaseProduct(product)
                        }
                    }
                )
            }
        }
    }
    
    private var restoreButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.body)
                .foregroundColor(.blue)
        }
        .disabled(isPurchasing)
    }
    
    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Store Operations
    
    private func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [
                starterProProductID,
                monthlyProductID,
                yearlyProductID,
                lifetimeProductID
            ])
            
            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            await MainActor.run {
                self.purchaseError = "Failed to load products: \(error.localizedDescription)"
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        await MainActor.run {
            isPurchasing = true
            purchaseError = nil
        }
        
        do {
            let result = try await product.purchase()
            
            await MainActor.run {
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        // Transaction verified successfully
                        Task {
                            await transaction.finish()
                            await checkPurchasedProducts()
                        }
                    case .unverified(_, let error):
                        self.purchaseError = "Purchase verification failed: \(error.localizedDescription)"
                    }
                case .userCancelled:
                    // User cancelled, no error
                    break
                case .pending:
                    self.purchaseError = "Purchase is pending approval"
                @unknown default:
                    self.purchaseError = "Unknown purchase result"
                }
                self.isPurchasing = false
            }
        } catch {
            await MainActor.run {
                self.purchaseError = "Purchase failed: \(error.localizedDescription)"
                self.isPurchasing = false
            }
        }
    }
    
    private func restorePurchases() async {
        await MainActor.run {
            isPurchasing = true
            purchaseError = nil
        }
        
        await checkPurchasedProducts()
        
        await MainActor.run {
            self.isPurchasing = false
        }
    }
    
    private func checkPurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchased
            self.isUnlocked = purchased.contains(starterProProductID) || 
                             purchased.contains(monthlyProductID) || 
                             purchased.contains(yearlyProductID) || 
                             purchased.contains(lifetimeProductID)
        }
    }
}

struct ProductPurchaseCard: View {
    let product: Product
    let isPurchased: Bool
    let isLoading: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(productDisplayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(productDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let period = subscriptionPeriod {
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    if product.type == .autoRenewable {
                        Text("per " + (subscriptionPeriod?.lowercased() ?? "period"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button {
                if !isPurchased && !isLoading {
                    onPurchase()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing...")
                    } else if isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Purchased")
                    } else {
                        Text("Purchase")
                    }
                }
                .font(.body.bold())
                .foregroundColor(isPurchased ? .green : .white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isPurchased ? Color.green.opacity(0.2) : Color.blue)
                .cornerRadius(12)
            }
            .disabled(isPurchased || isLoading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPurchased ? Color.green : Color.gray.opacity(0.3), lineWidth: isPurchased ? 2 : 1)
        )
        .cornerRadius(16)
    }
    
    private var productDisplayName: String {
        switch product.id {
        case "com.accelerate.sc40.starterpro":
            return "Starter Pro"
        case "com.accelerate.sc40.monthly":
            return "Monthly Pro"
        case "com.accelerate.sc40.yearly":
            return "Yearly Pro"
        case "com.accelerate.sc40.lifetime":
            return "Lifetime Access"
        default:
            return product.displayName
        }
    }
    
    private var productDescription: String {
        switch product.id {
        case "com.accelerate.sc40.starterpro":
            return "Professional timing and analytics"
        case "com.accelerate.sc40.monthly":
            return "Full access to all pro features"
        case "com.accelerate.sc40.yearly":
            return "Full access to all pro features (Save 58%)"
        case "com.accelerate.sc40.lifetime":
            return "One-time purchase for unlimited access"
        default:
            return product.description
        }
    }
    
    private var subscriptionPeriod: String? {
        guard let subscription = product.subscription else { return nil }
        
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

#Preview {
    StarterProPurchaseView()
}
