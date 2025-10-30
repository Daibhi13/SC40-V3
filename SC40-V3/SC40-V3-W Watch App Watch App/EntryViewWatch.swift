import SwiftUI
import WatchConnectivity

// MARK: - Main Watch App Entry Point
// C25K Fitness22 style - shows buffer when phone not synced, main content when ready
struct EntryViewWatch: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @State private var showMainContent = false
    @State private var hasCheckedSync = false
    
    var body: some View {
        Group {
            if showMainContent {
                // Main app content
                ContentView()
            } else if hasCheckedSync && needsSync {
                // Show premium buffer when sync needed
                WatchSyncBufferView {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showMainContent = true
                    }
                }
            } else {
                // Premium splash screen
                premiumSplashView
            }
        }
        .onAppear {
            checkSyncStatus()
        }
    }
    
    // MARK: - Premium Splash View
    private var premiumSplashView: some View {
        ZStack {
            // Premium liquid glass background
            Canvas { context, size in
                let splashGradient = Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.6),
                    Color(red: 0.2, green: 0.1, blue: 0.3).opacity(0.4),
                    Color.black
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(splashGradient, 
                                               startPoint: CGPoint(x: 0, y: 0), 
                                               endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Premium floating elements
                context.addFilter(.blur(radius: 10))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.2, y: size.height * 0.3, width: 25, height: 25)),
                           with: .color(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.25)))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.7, y: size.height * 0.7, width: 30, height: 30)),
                           with: .color(Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.2)))
            }
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Premium app branding
                VStack(spacing: 8) {
                    // Animated runner icon with premium effects
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3))
                            .frame(width: 50, height: 50)
                            .blur(radius: 15)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 12)
                    }
                    
                    Text("SC40")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6))
                        .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.4), radius: 8)
                    
                    Text("SPRINT COACH")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(3)
                }
                
                Text("Elite Sprint Training")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1)
            }
        }
    }
    
    // MARK: - Sync Status Logic
    private var needsSync: Bool {
        return !watchConnectivity.trainingSessionsSynced || !watchConnectivity.isWatchConnected
    }
    
    private func checkSyncStatus() {
        Task { @MainActor in
            // Brief splash display
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            hasCheckedSync = true
            
            // If already synced and connected, go directly to main content
            if !needsSync {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                withAnimation(.easeInOut(duration: 0.8)) {
                    showMainContent = true
                }
            }
            // Otherwise, the buffer view will be shown automatically
        }
    }
}

// MARK: - Preview
#Preview {
    EntryViewWatch()
}
