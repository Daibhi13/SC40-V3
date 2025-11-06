import SwiftUI

// MARK: - Watch Integration UI Component
struct WatchIntegrationView: View {
    @ObservedObject var watchConnectivity: WatchConnectivityManager
    let session: TrainingSession?
    let onLaunchOnWatch: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Watch Status Header
            HStack {
                Image(systemName: watchConnectivity.isWatchConnected ? "applewatch" : "applewatch.slash")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(watchConnectivity.isWatchConnected ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Watch")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(watchConnectivity.checkWatchStatus())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(watchConnectivity.isWatchConnected ? .green : .gray)
                }
                
                Spacer()
                
                // Connection indicator
                Circle()
                    .fill(watchConnectivity.isWatchReachable ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(watchConnectivity.isWatchReachable ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), 
                              value: watchConnectivity.isWatchReachable)
            }
            
            // Sync Status (if syncing)
            if watchConnectivity.isSyncing {
                VStack(spacing: 8) {
                    ProgressView(value: watchConnectivity.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("Syncing to Apple Watch...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            // Action Buttons
            if watchConnectivity.isWatchReachable {
                HStack(spacing: 12) {
                    // Launch on Watch button
                    if let session = session {
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
                    
                    // Sync button
                    Button(action: {
                        Task {
                            if let profile = session {
                                await watchConnectivity.syncTrainingSessions([profile])
                            }
                        }
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
            } else if watchConnectivity.connectionError != nil {
                // Connection help
                Button(action: {
                    // Open Watch app or show instructions
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 12, weight: .bold))
                        Text("Setup Help")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(watchConnectivity.isWatchConnected ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
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
