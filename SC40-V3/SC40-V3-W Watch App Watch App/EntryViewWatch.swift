import SwiftUI
import WatchConnectivity

// MARK: - Main Watch App Entry Point
// C25K Fitness22 style - always shows splash buffer initially, then main content when ready
struct EntryViewWatch: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @State private var showMainContent = false
    @State private var hasCheckedSync = false
    
    var body: some View {
        Group {
            if showMainContent {
                // Main app content
                ContentView()
            } else {
                // Always show premium splash buffer initially
                WatchSyncBufferView {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showMainContent = true
                    }
                }
            }
        }
        .onAppear {
            checkSyncStatus()
        }
    }
    
    
    // MARK: - Sync Status Logic
    private var needsSync: Bool {
        return !watchConnectivity.trainingSessionsSynced || !watchConnectivity.isWatchConnected
    }
    
    private func checkSyncStatus() {
        Task { @MainActor in
            // Allow splash buffer to show and perform sync check
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds to show splash
            
            hasCheckedSync = true
            
            // The WatchSyncBufferView will handle the sync process and call completion
            // when ready to proceed to main content
        }
    }
}

// MARK: - Preview
#Preview {
    EntryViewWatch()
}
