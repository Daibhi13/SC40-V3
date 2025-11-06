import SwiftUI

struct ProFeaturesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var isPurchased = false // This would come from your purchase manager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching app design
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Crown Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 20)
                            
                            VStack(spacing: 8) {
                                Text("Pro Features")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Unlock premium features")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Advanced Analytics Card
                        ProFeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                            title: "Advanced Analytics",
                            price: "$2.99 one-time",
                            description: "Global sports benchmarks, percentile rankings, PDF recruiting cards, and detailed performance insights.",
                            features: [
                                "Global Sports Benchmarks (10 sports)",
                                "Percentile Rankings",
                                "PDF Recruiting Card Export",
                                "Advanced Performance Metrics"
                            ],
                            isPurchased: isPurchased,
                            onPurchase: {
                                // Handle Advanced Analytics purchase
                                HapticManager.shared.success()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        
                        // Sprint Timer Pro Card
                        ProFeatureCard(
                            icon: "stopwatch.fill",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                            title: "Sprint Timer Pro",
                            price: "$4.99 one-time",
                            description: "Professional timing app for sprint training and testing. Practice starts, time trials, and custom workouts from 10-100 yards with precision GPS timing.",
                            features: [
                                "Professional Sprint Starter & Timer",
                                "Custom Distance (10-100 yards, 10yd increments)",
                                "Flexible Rest Periods (1-60 minutes)",
                                "Multiple Reps (1-10 repetitions)",
                                "GPS-Verified Precision Timing",
                                "Results sync to analytics"
                            ],
                            isPurchased: isPurchased,
                            onPurchase: {
                                // Handle Sprint Timer Pro purchase
                                HapticManager.shared.success()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        
                        // Pro Bundle Card
                        ProBundleCard(
                            onPurchase: {
                                // Handle Pro Bundle purchase
                                HapticManager.shared.success()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        
                        // Restore Purchases Card
                        RestorePurchasesCard(
                            onRestore: {
                                // Handle restore purchases
                                HapticManager.shared.medium()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showContent = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Supporting Components

struct ProFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let price: String
    let description: String
    let features: [String]
    let isPurchased: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        let cardBackground = RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        
        let buttonBackground = isPurchased 
            ? AnyView(Color.green)
            : AnyView(LinearGradient(
                colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                startPoint: .leading,
                endPoint: .trailing
            ))
        
        return VStack(spacing: 20) {
            // Header
            headerSection
            
            // Description
            Text(description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            
            // Features
            featuresSection
            
            // Purchase button
            Button(action: onPurchase) {
                HStack(spacing: 8) {
                    if isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Purchased")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text("Purchase")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(isPurchased ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(buttonBackground)
                .cornerRadius(12)
            }
            .disabled(isPurchased)
        }
        .padding(20)
        .background(cardBackground)
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(price)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            }
            
            Spacer()
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 8) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    
                    Text(feature)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    
                    Spacer()
                }
            }
        }
    }
}

struct ProBundleCard: View {
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Bundle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Both features at a discount")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Button(action: onPurchase) {
                HStack {
                    Text("Get Pro Bundle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$5.99")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        Text("Save $1.99")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), lineWidth: 2)
                )
        )
    }
}

struct RestorePurchasesCard: View {
    let onRestore: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restore Purchases")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Already purchased? Restore here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Button(action: onRestore) {
                Text("Restore Purchases")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
struct ProFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        ProFeaturesView()
    }
}
#endif
