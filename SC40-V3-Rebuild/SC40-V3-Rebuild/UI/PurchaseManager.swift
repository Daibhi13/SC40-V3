import SwiftUI
import StoreKit

#if canImport(UIKit)
import UIKit
#endif

// Import the custom service
import Foundation

struct PurchaseManager: View {
    @StateObject private var storeKit = StoreKitService.shared
    @AppStorage("isProUser") private var isProUser: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if storeKit.isLoading {
                        ProgressView("Loading products...")
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
        LazyVStack(spacing: 16) {
            ForEach(storeKit.products, id: \.id) { product in
                ProductCard(
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
    
    private func purchaseProduct(_ product: Product) async {
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
}

struct ProductCard: View {
    let product: Product
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    private var productType: StoreKitService.ProductID? {
        return StoreKitService.ProductID(rawValue: product.id)
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
