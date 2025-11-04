import SwiftUI

// MARK: - Watch Integration UI Component
struct WatchIntegrationView: View {
    @ObservedObject var watchConnectivity: WatchConnectivityManager
    let session: TrainingSession?
    let onLaunchOnWatch: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            watchStatusHeader
            syncStatusSection
            actionButtonsSection
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    
    private var watchStatusHeader: some View {
        HStack {
            watchIcon
            watchStatusText
            Spacer()
            connectionIndicator
        }
    }
    
    private var watchIcon: some View {
        Image(systemName: watchConnectivity.isWatchConnected ? "applewatch" : "applewatch.slash")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(watchConnectivity.isWatchConnected ? .green : .gray)
    }
    
    private var watchStatusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Apple Watch")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(watchConnectivity.checkWatchStatus())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(watchConnectivity.isWatchConnected ? .green : .gray)
        }
    }
    
    private var connectionIndicator: some View {
        Circle()
            .fill(watchConnectivity.isWatchReachable ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
            .scaleEffect(watchConnectivity.isWatchReachable ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), 
                      value: watchConnectivity.isWatchReachable)
    }
    
    private var syncStatusSection: some View {
        Group {
            if watchConnectivity.isSyncing {
                VStack(spacing: 8) {
                    ProgressView(value: watchConnectivity.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("Syncing to Apple Watch...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        Group {
            if watchConnectivity.isWatchReachable {
                HStack(spacing: 12) {
                    if let session = session {
                        launchOnWatchButton(session: session)
                    }
                    syncButton
                }
            }
        }
    }
    
    private func launchOnWatchButton(session: TrainingSession) -> some View {
        Button(action: {
            Task {
                await watchConnectivity.launchWorkoutOnWatch(session: session)
            }
            onLaunchOnWatch()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Start on Watch")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green)
            .cornerRadius(8)
        }
    }
    
    private var syncButton: some View {
        Button(action: {
            // Sync action - simplified for now
            print("Sync requested")
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .bold))
                Text("Sync")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
}

#Preview {
    WatchIntegrationView(
        watchConnectivity: WatchConnectivityManager.shared,
        session: nil,
        onLaunchOnWatch: {}
    )
}

// MARK: - Compact Watch Status Indicator
struct CompactWatchStatusView: View {
    @ObservedObject var watchConnectivity: WatchConnectivityManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: watchConnectivity.isWatchConnected ? "applewatch" : "applewatch.slash")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(watchConnectivity.isWatchConnected ? .green : .gray)
            
            if watchConnectivity.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Syncing...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
            } else {
                Circle()
                    .fill(watchConnectivity.isWatchReachable ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.1, green: 0.05, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            WatchIntegrationView(
                watchConnectivity: WatchConnectivityManager.shared,
                session: nil,
                onLaunchOnWatch: {}
            )
            
            CompactWatchStatusView(
                watchConnectivity: WatchConnectivityManager.shared
            )
        }
        .padding()
    }
}
