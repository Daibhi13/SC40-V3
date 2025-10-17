import SwiftUI
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

import Combine

enum PurchaseProductID: String {
    case monthly = "com.sprintcoach40.pro.monthly"
    case annual = "com.sprintcoach40.pro.annual"
    case lifetime = "com.sprintcoach40.pro.lifetime"
    
    var displayName: String {
        switch self {
        case .monthly: return "Pro Monthly"
        case .annual: return "Pro Annual"
        case .lifetime: return "Pro Lifetime"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "Full access for one month"
        case .annual: return "Full access for one year"
        case .lifetime: return "Lifetime access"
        }
    }
}

#if DEBUG && MOCK_STOREKIT
// Mock StoreKitService for demo purposes
class MockStoreKitService: ObservableObject {
    static let shared = MockStoreKitService()
    
    @Published var isLoading = false
    @Published var products: [MockProduct] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var errorMessage: String?
    
    func loadProducts() async {
        // Mock loading
        isLoading = true
        // Simulate async loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.products = [
                MockProduct(id: "com.sprintcoach40.pro.monthly", displayName: "Pro Monthly", description: "Full access for one month", price: 9.99, isSubscription: true),
                MockProduct(id: "com.sprintcoach40.pro.annual", displayName: "Pro Annual", description: "Full access for one year", price: 59.99, isSubscription: true),
                MockProduct(id: "com.sprintcoach40.pro.lifetime", displayName: "Pro Lifetime", description: "Lifetime access", price: 149.99, isSubscription: false)
            ]
            self.isLoading = false
        }
    }
    
    func purchase(_ product: MockProduct) async -> MockPurchaseResult {
        // Mock purchase
        purchasedProductIDs.insert(product.id)
        return .success
    }
    
    func restorePurchases() async -> Bool {
        // Mock restore
        return true
    }
    
    // Mock StoreKit methods
    static func products(for productIDs: [String]) async throws -> [MockProduct] {
        // Mock products
        return [
            MockProduct(id: "com.sprintcoach40.pro.monthly", displayName: "Pro Monthly", description: "Full access for one month", price: 9.99, isSubscription: true),
            MockProduct(id: "com.sprintcoach40.pro.annual", displayName: "Pro Annual", description: "Full access for one year", price: 59.99, isSubscription: true),
            MockProduct(id: "com.sprintcoach40.pro.lifetime", displayName: "Pro Lifetime", description: "Lifetime access", price: 149.99, isSubscription: false)
        ]
    }

    func hasProAccess() -> Bool {
        // Consider any purchase as Pro access in this mock
        return !purchasedProductIDs.isEmpty
    }
}
#endif

// Fallback minimal StoreKit service to allow compilation when MOCK_STOREKIT is not enabled
final class FallbackStoreKitService: ObservableObject {
    static let shared = FallbackStoreKitService()

    @Published var isLoading = false
    @Published var products: [MockProduct] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var errorMessage: String?

    func loadProducts() async {
        await MainActor.run {
            self.isLoading = false
            self.products = []
            self.errorMessage = "StoreKit mock disabled in this build."
        }
    }

    func purchase(_ product: MockProduct) async -> MockPurchaseResult {
        return .failed(NSError(domain: "Store", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purchases are unavailable in this configuration."]))
    }

    func restorePurchases() async -> Bool {
        return false
    }

    func hasProAccess() -> Bool {
        return false
    }
}

// MARK: - Types moved outside StoreKitService

enum MockPurchaseResult {
    case success, userCancelled, pending, failed(Error)
}

// Mock Product struct
struct MockProduct: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let price: Double
    let isSubscription: Bool
    
    var localizedPrice: String {
        return String(format: "$%.2f", price)
    }
    
    var subscriptionPeriod: String? {
        return isSubscription ? "month" : nil
    }
}

struct PurchaseManager: View {
    #if DEBUG && MOCK_STOREKIT
    @StateObject private var storeKit = MockStoreKitService.shared
    #else
    @StateObject private var storeKit = FallbackStoreKitService.shared
    #endif
    @AppStorage("isProUser") private var isProUser: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if storeKit.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if storeKit.products.isEmpty {
                        emptyStateView
                    } else {
                        productsSection
                    }
                    
                    restorePurchasesButton
                    
                    if let errorMessage = storeKit.errorMessage {
                        errorView(errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await storeKit.loadProducts()
        }
        .onChange(of: storeKit.purchasedProductIDs) { _, _ in
            updateProStatus()
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
            
            Text("Get access to advanced analytics, Starter Pro timing, and unlimited training sessions")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var productsSection: some View {
        let mockProducts = storeKit.products

        return LazyVStack(spacing: 16) {
            ForEach(mockProducts) { product in
                PurchaseProductCard(
                    product: product,
                    isPurchased: storeKit.purchasedProductIDs.contains(product.id),
                    onPurchase: {
                        Task {
                            await purchaseProduct(product)
                        }
                    }
                )
            }
        }
    }
    
    private var restorePurchasesButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.body)
                .foregroundColor(.blue)
        }
        .disabled(storeKit.isLoading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Products Not Available")
                .font(.headline)
            
            Text("Unable to load products from the App Store. Please check your connection and try again.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await storeKit.loadProducts()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func errorView(_ message: String) -> some View {
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
    
    private func purchaseProduct(_ product: MockProduct) async {
        let result = await storeKit.purchase(product)
        
        switch result {
        case .success:
            await MainActor.run {
                triggerSuccessHaptic()
            }
        case .userCancelled:
            break // User cancelled, no action needed
        case .pending:
            await MainActor.run {
                // Show pending message
            }
        case .failed(let error):
            await MainActor.run {
                print("Purchase failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func restorePurchases() async {
        let success = await storeKit.restorePurchases()
        if success {
            await MainActor.run {
                triggerSuccessHaptic()
            }
        }
    }
    
    private func updateProStatus() {
        isProUser = storeKit.hasProAccess()
    }
    
    // MARK: - Haptic Feedback
    private func triggerSuccessHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

struct PurchaseProductCard: View {
    let product: MockProduct
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    private var productType: PurchaseProductID? {
        return PurchaseProductID(rawValue: product.id)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(productType?.displayName ?? product.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(productType?.description ?? product.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let period = product.subscriptionPeriod {
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(product.localizedPrice)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    if product.isSubscription {
                        Text("per " + (product.subscriptionPeriod?.lowercased() ?? "period"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button {
                if !isPurchased {
                    onPurchase()
                }
            } label: {
                HStack {
                    if isPurchased {
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
            .disabled(isPurchased)
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPurchased ? Color.green : Color.gray.opacity(0.3), lineWidth: isPurchased ? 2 : 1)
        )
        .cornerRadius(16)
    }
    
    // MARK: - Haptic Feedback
    private func triggerSuccessHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

#Preview {
    PurchaseManager()
}
