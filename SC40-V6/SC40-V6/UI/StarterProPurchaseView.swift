import SwiftUI

struct StarterProPurchaseView: View {
    @State private var isUnlocked = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        productsSection
                    }
                    
                    restorePurchasesButton
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss action
                    }
                }
            }
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
        .padding(.top)
    }
    
    private var productsSection: some View {
        VStack(spacing: 16) {
            ProductCard(
                title: "Starter Pro",
                description: "Professional timing and analytics",
                price: "$4.99",
                isPurchased: isUnlocked,
                onPurchase: {
                    unlockStarterPro()
                }
            )
        }
    }
    
    private var restorePurchasesButton: some View {
        Button("Restore Purchases") {
            // Restore action
        }
        .font(.body)
        .foregroundColor(.blue)
        .disabled(isPurchasing)
    }
    
    private func unlockStarterPro() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isUnlocked = true
            isPurchasing = false
        }
    }
}

struct ProductCard: View {
    let title: String
    let description: String
    let price: String
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(price)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
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
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
}

#Preview {
    StarterProPurchaseView()
}
