import SwiftUI

// MARK: - Entry iOS View

struct EntryIOSView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var startupManager = AppStartupManager.shared
    
    var body: some View {
        Group {
            if !startupManager.isInitialized {
                StartupSyncView(startupManager: startupManager)
                    .task {
                        await startupManager.initializeApp()
                    }
            } else if !authManager.isAuthenticated {
                WelcomeView { name, email in
                    // Handle welcome completion
                    print("Welcome completed for \(name), email: \(email ?? "none")")
                }
            } else {
                MainAppView()
            }
        }
        .animation(.easeInOut, value: startupManager.isInitialized)
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

// MARK: - Main App View
private struct MainAppView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var syncManager = TrainingSynchronizationManager.shared
    @StateObject private var userProfileVM = UserProfileViewModel()
    
    var body: some View {
        TabView {
            // Home Tab
            HomeDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Training Tab
            TrainingView(userProfileVM: userProfileVM)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Training")
                }
            
            // History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            // Performance Tab
            PerformanceView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Performance")
                }
            
            // Profile Tab
            ProfileView(userProfileVM: userProfileVM)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .environmentObject(syncManager)
        .onAppear {
            // Initialize connectivity
            _ = watchConnectivity
        }
    }
}

// MARK: - Preview
#Preview {
    EntryIOSView()
        .preferredColorScheme(.dark)
}
