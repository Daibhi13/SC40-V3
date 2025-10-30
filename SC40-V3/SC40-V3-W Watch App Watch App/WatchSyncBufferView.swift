import SwiftUI
import WatchConnectivity

// MARK: - C25K Fitness22 Style Watch Buffer View
// Premium sync buffer that appears when phone is not synced
struct WatchSyncBufferView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @State private var animatePulse = false
    @State private var animateProgress = false
    @State private var syncProgress: Double = 0.0
    @State private var showRetryButton = false
    @State private var syncMessage = "Connecting to iPhone..."
    
    var onSyncComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Premium liquid glass background similar to C25K style
            Canvas { context, size in
                // Dark gradient base
                let backgroundGradient = Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.8),
                    Color(red: 0.2, green: 0.1, blue: 0.3).opacity(0.6),
                    Color.black
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(backgroundGradient, 
                                               startPoint: CGPoint(x: 0, y: 0), 
                                               endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Floating premium particles
                context.addFilter(.blur(radius: 8))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.15, y: size.height * 0.25, width: 20, height: 20)),
                           with: .color(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3)))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.75, y: size.height * 0.65, width: 25, height: 25)),
                           with: .color(Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.25)))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.3, y: size.height * 0.8, width: 15, height: 15)),
                           with: .color(Color.cyan.opacity(0.2)))
                
                // Subtle wave pattern at bottom
                let waveHeight: CGFloat = 4
                let waveLength = size.width / 1.5
                var wavePath = Path()
                wavePath.move(to: CGPoint(x: 0, y: size.height * 0.85))
                for x in stride(from: 0, through: size.width, by: 1) {
                    let y = size.height * 0.85 + waveHeight * sin((x / waveLength) * 2 * .pi)
                    wavePath.addLine(to: CGPoint(x: x, y: y))
                }
                wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                
                context.fill(wavePath, with: .color(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.15)))
            }
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Premium app branding
                VStack(spacing: 6) {
                    // Animated runner icon with premium glow
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                            .frame(width: 35, height: 35)
                            .blur(radius: 8)
                            .scaleEffect(animatePulse ? 1.2 : 1.0)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 8)
                            .scaleEffect(animatePulse ? 1.1 : 1.0)
                    }
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animatePulse)
                    
                    Text("SC40")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6))
                        .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.4), radius: 6)
                    
                    Text("SPRINT COACH")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                }
                .padding(.bottom, 8)
                
                // Sync status message
                Text(syncMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                // Premium progress indicator
                syncProgressIndicator
                
                // Action buttons for error states
                if showRetryButton {
                    actionButtons
                }
                
                // Connection status
                connectionStatusView
            }
            .padding(.horizontal, 12)
        }
        .onAppear {
            animatePulse = true
            startSyncProcess()
        }
    }
    
    // MARK: - Progress Indicator
    @ViewBuilder
    private var syncProgressIndicator: some View {
        if showRetryButton {
            // Error state
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.orange)
                .shadow(color: .orange.opacity(0.4), radius: 6)
        } else if syncProgress > 0 {
            // Progress state
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: syncProgress)
                        .stroke(
                            Color(red: 1.0, green: 0.8, blue: 0.0),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: syncProgress)
                    
                    Text("\(Int(syncProgress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        } else {
            // Loading state with C25K style dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8))
                        .frame(width: 6, height: 6)
                        .scaleEffect(animateProgress ? 1.3 : 0.7)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: animateProgress)
                }
            }
            .onAppear { animateProgress = true }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button(action: {
                showRetryButton = false
                syncProgress = 0.0
                startSyncProcess()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Retry")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                .cornerRadius(14)
            }
            
            Button(action: {
                // Skip sync and proceed
                onSyncComplete()
            }) {
                Text("Continue")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Connection Status
    private var connectionStatusView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "iphone")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(watchConnectivity.isWatchConnected ? .green : .red)
                
                Text(watchConnectivity.isWatchConnected ? "iPhone Connected" : "iPhone Disconnected")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if !watchConnectivity.trainingSessionsSynced {
                Text("Training data syncing...")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Sync Process
    private func startSyncProcess() {
        syncMessage = "Connecting to iPhone..."
        
        Task { @MainActor in
            // Check connectivity
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            if watchConnectivity.isWatchConnected {
                syncMessage = "Syncing training data..."
                
                // Simulate sync progress
                for progress in stride(from: 0.1, through: 1.0, by: 0.1) {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    syncProgress = progress
                }
                
                // Complete sync
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                syncMessage = "Sync complete!"
                
                // Mark as synced and proceed
                watchConnectivity.trainingSessionsSynced = true
                
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                onSyncComplete()
                
            } else {
                // Connection failed
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                syncMessage = "iPhone not found"
                showRetryButton = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    WatchSyncBufferView {
        print("Sync completed!")
    }
}
