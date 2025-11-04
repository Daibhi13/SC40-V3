import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct OnboardingRequiredView: View {
    @ObservedObject private var watchManager = WatchSessionManager.shared
    @State private var isConnecting = false
    @State private var connectionProgress: Double = 0.0
    @State private var pulseAnimation = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [Color.brandPrimary.opacity(0.3), Color.brandSecondary.opacity(0.2), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles background
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 4, height: 4)
                    .position(
                        x: CGFloat.random(in: 0...200),
                        y: CGFloat.random(in: 0...200)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
            
            ScrollView {
                VStack(spacing: WatchAdaptiveSizing.spacing) {
                    // Connection status header
                    connectionStatusHeader
                    
                    // Setup instructions
                    setupInstructionsView
                    
                    // Action buttons
                    actionButtonsView
                }
                .adaptivePadding()
            }
        }
        .onAppear {
            pulseAnimation = true
            startConnectionCheck()
        }
    }
    
    private var connectionStatusHeader: some View {
        VStack(spacing: WatchAdaptiveSizing.smallPadding) {
            // Connection icon with pulsing animation
            Image(systemName: watchManager.isPhoneConnected ? "iphone.and.apple.watch" : "exclamationmark.triangle")
                .font(.system(size: WatchAdaptiveSizing.iconSize + 4, weight: .bold))
                .foregroundColor(watchManager.isPhoneConnected ? .green : .orange)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
            
            Text(connectionStatusTitle)
                .font(.adaptiveHeadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if isConnecting {
                ProgressView(value: connectionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary))
                    .frame(height: WatchAdaptiveSizing.isUltra ? 6 : 4)
            }
        }
    }
    
    private var connectionStatusTitle: String {
        if isConnecting {
            return "Connecting..."
        } else if watchManager.isPhoneConnected {
            return "iPhone Connected"
        } else {
            return "Setup Required"
        }
    }
    
    private var setupInstructionsView: some View {
        VStack(spacing: WatchAdaptiveSizing.smallPadding) {
            ForEach(setupSteps.indices, id: \.self) { index in
                setupStepCard(step: setupSteps[index], number: index + 1)
            }
        }
    }
    
    private func setupStepCard(step: String, number: Int) -> some View {
        HStack(spacing: WatchAdaptiveSizing.smallPadding) {
            // Step number badge
            Circle()
                .fill(Color.brandPrimary)
                .frame(width: 20, height: 20)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: WatchAdaptiveSizing.captionFontSize, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(step)
                .font(.adaptiveCaption)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(WatchAdaptiveSizing.smallPadding)
        .background(Color.white.opacity(0.1))
        .adaptiveCornerRadius()
    }
    
    private var setupSteps: [String] {
        [
            "Open Sprint Coach 40 on iPhone",
            "Complete onboarding setup",
            "Keep iPhone nearby",
            "Tap 'Setup' below to connect"
        ]
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: WatchAdaptiveSizing.smallPadding) {
            // Primary setup button
            Button(action: {
                setupButtonTapped()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: WatchAdaptiveSizing.smallIconSize, weight: .semibold))
                    Text("Setup")
                        .font(.adaptiveBody)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: WatchAdaptiveSizing.buttonHeight)
                .background(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .adaptiveCornerRadius()
            }
            .disabled(isConnecting)
        }
    }
    
    private func setupButtonTapped() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        
        isConnecting = true
        connectionProgress = 0.0
        
        // Animate progress
        withAnimation(.linear(duration: 2.0)) {
            connectionProgress = 1.0
        }
        
        // Request sessions from iPhone
        Task { @MainActor in
            await watchManager.requestTrainingSessions()
        }
        
        // Call completion after request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
        
        // Stop connecting animation after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isConnecting = false
            connectionProgress = 0.0
        }
    }
    
    private func startConnectionCheck() {
        // Periodic connection check
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                if !watchManager.isPhoneConnected {
                    await watchManager.requestTrainingSessions()
                }
            }
        }
    }
}


#if DEBUG
#Preview("1. Setup Required - Apple Watch Ultra") {
    OnboardingRequiredView(onComplete: { })
        .preferredColorScheme(.dark)
}

#Preview("2. Connection Flow - Connecting") {
    OnboardingRequiredView(onComplete: { })
        .preferredColorScheme(.dark)
}

#Preview("3. Setup Instructions") {
    OnboardingRequiredView(onComplete: { })
        .preferredColorScheme(.light)
}

#Preview("4. Animated Background") {
    ZStack {
        LinearGradient(
            colors: [Color.brandPrimary.opacity(0.3), Color.brandSecondary.opacity(0.2), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack {
            Text("Premium Gradient")
                .font(.adaptiveTitle)
                .foregroundColor(.white)
            Text("Sprint Coach 40 Branding")
                .font(.adaptiveBody)
                .foregroundColor(.secondary)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("5. Adaptive Sizing Test") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Watch Adaptive Sizing")
            .font(.adaptiveTitle)
        Text("Spacing: \(Int(WatchAdaptiveSizing.spacing))px")
            .font(.adaptiveBody)
        Text("Padding: \(Int(WatchAdaptiveSizing.padding))px")
            .font(.adaptiveCaption)
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif
