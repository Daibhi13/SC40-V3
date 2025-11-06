import SwiftUI

// MARK: - Startup Sync Buffer UI
// Displays sync progress and handles connectivity states during app launch
struct StartupSyncView: View {
    @ObservedObject var startupManager: AppStartupManager
    @State private var animateProgress = false
    @State private var animatePulse = false
    
    var body: some View {
        ZStack {
            // Premium gradient background matching app theme
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),  // Deep blue top
                    Color(red: 0.15, green: 0.05, blue: 0.25),  // Rich purple middle
                    Color(red: 0.05, green: 0.02, blue: 0.15)   // Dark indigo bottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App branding
                VStack(spacing: 16) {
                    // Animated runner icon
                    Image(systemName: "figure.run")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 30)
                        .scaleEffect(animatePulse ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animatePulse)
                    
                    Text("SPRINT COACH")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                    
                    Text("40")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6))
                        .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.4), radius: 30)
                }
                
                // Sync status section
                VStack(spacing: 24) {
                    // Status message
                    Text(startupManager.syncMessage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Progress indicator based on phase
                    syncProgressView
                    
                    // Action buttons for error states
                    if startupManager.startupPhase == .syncError {
                        actionButtons
                    }
                }
                
                Spacer()
                
                // Connectivity status
                connectivityStatus
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            animatePulse = true
        }
    }
    
    // MARK: - Progress View
    @ViewBuilder
    private var syncProgressView: some View {
        switch startupManager.startupPhase {
        case .splash:
            // Simple loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
        case .connectivityCheck:
            // Connectivity check animation
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 12, height: 12)
                        .scaleEffect(animateProgress ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: animateProgress)
                }
            }
            .onAppear { animateProgress = true }
            
        case .syncBuffer:
            // Progress bar with percentage
            VStack(spacing: 16) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: startupManager.syncProgress)
                        .stroke(
                            Color(red: 1.0, green: 0.8, blue: 0.0),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: startupManager.syncProgress)
                    
                    Text("\(Int(startupManager.syncProgress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Progress description
                Text("Preparing your training sessions")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
        case .syncError:
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(.orange)
                .shadow(color: .orange.opacity(0.3), radius: 10)
            
        case .ready:
            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.3), radius: 15)
                .scaleEffect(animateProgress ? 1.2 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateProgress)
                .onAppear { animateProgress = true }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Retry button
            Button(action: {
                HapticManager.shared.medium()
                startupManager.retrySync()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Retry Sync")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                .cornerRadius(25)
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 10)
            }
            
            // Skip button
            Button(action: {
                HapticManager.shared.light()
                startupManager.skipSync()
            }) {
                Text("Continue Without Sync")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Connectivity Status
    private var connectivityStatus: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Watch connection indicator
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WatchConnectivityManager.shared.isWatchConnected ? .green : .red)
                    
                    Text(WatchConnectivityManager.shared.isWatchConnected ? "Connected" : "Not Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Sync status indicator
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WatchConnectivityManager.shared.trainingSessionsSynced ? .green : .orange)
                    
                    Text(WatchConnectivityManager.shared.trainingSessionsSynced ? "Synced" : "Pending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Additional status info for debugging
            if startupManager.startupPhase == .syncError, let error = startupManager.syncError {
                Text(error)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Preview
#Preview("Startup Sync - Loading") {
    let manager = AppStartupManager.shared
    manager.startupPhase = .syncBuffer
    manager.syncProgress = 0.6
    manager.syncMessage = "Syncing your training sessions..."
    
    return StartupSyncView(startupManager: manager)
        .preferredColorScheme(.dark)
}

#Preview("Startup Sync - Error") {
    let manager = AppStartupManager.shared
    manager.startupPhase = .syncError
    manager.syncError = "Move closer to your Apple Watch to connect"
    manager.syncMessage = "Connection failed"
    
    return StartupSyncView(startupManager: manager)
        .preferredColorScheme(.dark)
}

#Preview("Startup Sync - Success") {
    let manager = AppStartupManager.shared
    manager.startupPhase = .ready
    manager.syncProgress = 1.0
    manager.syncMessage = "Ready!"
    
    return StartupSyncView(startupManager: manager)
        .preferredColorScheme(.dark)
}
