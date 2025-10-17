import SwiftUI
import StoreKit

#if os(iOS)
import WatchConnectivity
#endif


struct StarterProSession: Identifiable {
    let id = UUID()
    let date: Date
    let results: [StarterProResult]
}

struct StarterProResult: Identifiable {
    let id = UUID()
    let time: Double
}

struct StarterProView: View {
    @EnvironmentObject var userProfileVM: UserProfileViewModel
    @State private var isUnlocked = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var reps = 3
    @State private var restTime = 60
    @State private var sessions: [StarterProSession] = []
    
    private let starterProProductID = "com.accelerate.sc40.starterpro"
    
    var body: some View {
        ZStack {
            // Starter Pro Canvas liquid glass background
            Canvas { context, size in
                // Professional timer gradient
                let starterGradient = Gradient(colors: [
                    Color.brandBackground.opacity(0.95),
                    Color.brandAccent.opacity(0.85),
                    Color.brandPrimary.opacity(0.75),
                    Color.orange.opacity(0.3)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(starterGradient,
                                        startPoint: CGPoint(x: 0, y: 0),
                                        endPoint: CGPoint(x: size.width, y: size.height))
                )
                
                // Timer precision elements
                let timerElements = 6
                for i in 0..<timerElements {
                    let x = size.width * (0.2 + CGFloat(i % 3) * 0.3)
                    let y = size.height * (0.25 + CGFloat(i / 3) * 0.35)
                    let radius: CGFloat = 20 + CGFloat(i) * 5
                    
                    // Precision timing visualization
                    context.addFilter(.blur(radius: 12))
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                               with: .color(Color.orange.opacity(0.20)))
                    
                    // Inner precision dot
                    context.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                               with: .color(Color.red.opacity(0.8)))
                }
                
                // Start line visualization
                context.fill(Path(CGRect(x: 0, y: size.height * 0.8, width: size.width, height: 3)),
                           with: .color(Color.yellow.opacity(0.6)))
                
                // Finish line
                context.fill(Path(CGRect(x: 0, y: size.height * 0.85, width: size.width, height: 3)),
                           with: .color(Color.green.opacity(0.6)))
                
                // Glass overlay
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color.brandPrimary.opacity(0.05))
                )
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if !isUnlocked {
                    PaywallView(
                        title: "Unlock Starter Pro",
                        description: "Starter Pro is your dedicated 40 yard dash timer. Set your reps and rest, start the session, and your 40 yard times will be recorded and added to your history. Unlock for a one-time payment.",
                        price: "$4.99"
                    ) {
                        unlockStarterPro()
                    }
                } else {
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.brandAccent.opacity(0.18))
                            .overlay(
                                VStack(spacing: 8) {
                                    Text("Starter Pro")
                                        .font(.title.bold())
                                        .foregroundColor(.brandPrimary)
                                    Text("Official 40 Yard Dash Timer")
                                        .font(.headline)
                                        .foregroundColor(.brandTertiary)
                                    Text("Your times will be saved to your history.")
                                        .font(.subheadline)
                                        .foregroundColor(.brandSecondary)
                                }
                                .padding()
                            )
                            .frame(height: 120)
                            .padding(.horizontal)
                        Form {
                            Section(header: Text("New Session").foregroundColor(.brandPrimary)) {
                                Stepper("Reps: \(reps)", value: $reps, in: 1...20)
                                Stepper("Rest: \(restTime) sec", value: $restTime, in: 15...300, step: 15)
                                Button(action: { sendToWatch(reps: reps, rest: restTime) }) {
                                    Text("Send to Watch & Start")
                                        .font(.headline)
                                        .foregroundColor(.brandBackground)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.brandPrimary)
                                        .cornerRadius(12)
                                }
                            }
                            Section(header: Text("History").foregroundColor(.brandPrimary)) {
                                if sessions.isEmpty {
                                    Text("No sessions yet.")
                                        .foregroundColor(.brandSecondary)
                                } else {
                                    List(sessions) { session in
                                        VStack(alignment: .leading) {
                                            Text("Session: \(session.date.formatted(date: .abbreviated, time: .shortened))")
                                                .foregroundColor(.brandTertiary)
                                            if let best = session.results.map({ $0.time }).min() {
                                                Text("Best: \(best, specifier: "%.2f")s")
                                                    .foregroundColor(.brandPrimary)
                                            }
                                            if !session.results.isEmpty {
                                                let avg = session.results.map({ $0.time }).reduce(0,+) / Double(session.results.count)
                                                Text("Average: \(avg, specifier: "%.2f")s")
                                                    .font(.caption)
                                                    .foregroundColor(.brandSecondary)
                                            }
                                            // Show all rep times with dates
                                            ForEach(session.results) { result in
                                                Text("\(result.time, specifier: "%.2f")s  •  \(session.date.formatted(date: .abbreviated, time: .shortened))")
                                                    .font(.caption2)
                                                    .foregroundColor(.brandSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color.brandBackground)
                    }
                }
            }
        }
        .navigationTitle("Starter Pro")
        .onAppear {
            NotificationCenter.default.addObserver(forName: Notification.Name("didReceiveStarterProResults"), object: nil, queue: .main) { @Sendable notification in
                // Extract data from notification outside the Task to avoid data races
                let session = notification.object as? StarterProSession
                Task { @MainActor in
                    if let session = session {
                        sessions.append(session)
                        
                        // Check for new personal best
                        let sessionTimes = session.results.map { $0.time }
                        if let fastestTime = sessionTimes.min() {
                            let currentPB = userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime
                            
                            // If this is a new personal best, update the profile
                            if fastestTime < currentPB {
                                userProfileVM.profile.personalBests["40yd"] = fastestTime
                                userProfileVM.profile.baselineTime = fastestTime
                                
                                print("🎉 New Personal Best! \(String(format: "%.2f", fastestTime))s (Previous: \(String(format: "%.2f", currentPB))s)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func unlockStarterPro() {
        Task {
            isPurchasing = true
            do {
                let result = try await AppStore.purchase(productID: starterProProductID)
                await MainActor.run {
                    switch result {
                    case .success:
                        isUnlocked = true
                        purchaseError = nil
                    case .userCancelled:
                        purchaseError = nil
                    case .pending:
                        purchaseError = "Purchase is pending approval"
                    case .failed(let error):
                        purchaseError = error.localizedDescription
                    }
                    isPurchasing = false
                }
            } catch {
                await MainActor.run {
                    purchaseError = error.localizedDescription
                    isPurchasing = false
                }
            }
        }
    }
    
    private func sendToWatch(reps: Int, rest: Int) {
        // WatchConnectivity: send config to watch
        #if os(iOS)
        if WCSession.isSupported() && WCSession.default.isReachable {
            let message: [String: Any] = [
                "type": "starterProConfig",
                "reps": reps,
                "rest": rest
            ]
            WCSession.default.sendMessage(message, replyHandler: { _ in }, errorHandler: { error in
                print("WatchConnectivity error: \(error.localizedDescription)")
            })
        }
        #endif
    }
}

struct PaywallView: View {
    var title: String
    var description: String
    var price: String
    var onUnlock: () -> Void
    var body: some View {
        VStack(spacing: 28) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.yellow)
                .padding(.top, 12)
            Text(description)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.yellow)
                Text("One-time unlock")
                    .font(.headline)
                    .foregroundColor(.brandTertiary)
            }
            .padding(.top, 8)
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.brandPrimary)
                    .frame(height: 60)
                Text("Unlock for \(price)")
                    .font(.title2.bold())
                    .foregroundColor(.brandBackground)
            }
            .onTapGesture { onUnlock() }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.brandAccent.opacity(0.13))
        .cornerRadius(24)
        .padding(.horizontal, 24)
        .shadow(color: Color.brandPrimary.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}

// StoreKit2 helper (updated implementation)
enum AppStore {
    enum PurchaseResult {
        case success, userCancelled, pending, failed(Error)
    }
    
    static func purchase(productID: String) async throws -> PurchaseResult {
        do {
            guard let product = try await Product.products(for: [productID]).first else {
                throw NSError(domain: "No product found", code: 0, userInfo: [NSLocalizedDescriptionKey: "Product \(productID) not found"])
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    return .success
                case .unverified(_, let error):
                    return .failed(error)
                }
            case .userCancelled:
                return .userCancelled
            case .pending:
                return .pending
            @unknown default:
                return .pending
            }
        } catch {
            return .failed(error)
        }
    }
    
    static func restorePurchases() async throws -> Bool {
        try await StoreKit.AppStore.sync()
        return true
    }
    
    static func hasPurchased(productID: String) async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                return true
            }
        }
        return false
    }
}
