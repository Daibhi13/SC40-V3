import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// SC40 Premium Splash Screen - Professional Style with Adaptive Glass Effect
struct SC40SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var taglineOpacity: Double = 0.0
    @State private var particleAnimation: Bool = false
    @State private var showContent = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Adaptive glass effect background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.brandBackground.opacity(0.9),
                            Color.brandTertiary.opacity(0.7),
                            Color.brandPrimary.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.regularMaterial) // Glass effect for watchOS
                .ignoresSafeArea()
            
            // Animated energy particles (adaptive sizing)
            Canvas { context, size in
                // Animated energy particles with adaptive positioning
                if particleAnimation {
                    for i in 0..<12 {
                        let angle = Double(i) * (2 * .pi / 12)
                        let radius = WatchAdaptiveSizing.spacing * 5 + sin(Date().timeIntervalSince1970 * 2 + Double(i)) * (WatchAdaptiveSizing.spacing * 2)
                        let x = size.width / 2 + cos(angle) * radius
                        let y = size.height / 2 + sin(angle) * radius
                        let particleSize = WatchAdaptiveSizing.spacing / 2 + sin(Date().timeIntervalSince1970 * 3 + Double(i)) * (WatchAdaptiveSizing.spacing / 4)
                        
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - particleSize/2, y: y - particleSize/2, width: particleSize, height: particleSize)),
                            with: .color(Color.brandPrimary.opacity(0.6))
                        )
                    }
                }
                
                // Runner motion trails (adaptive)
                if showContent {
                    let centerX = size.width / 2
                    let centerY = size.height / 2
                    
                    for i in 0..<6 {
                        let angle = Double(i) * (.pi / 3)
                        let length = WatchAdaptiveSizing.spacing * 3
                        let endX = centerX + cos(angle) * length
                        let endY = centerY + sin(angle) * length
                        
                        var path = Path()
                        path.move(to: CGPoint(x: centerX, y: centerY))
                        path.addLine(to: CGPoint(x: endX, y: endY))
                        
                        context.stroke(path, with: .color(Color.brandPrimary.opacity(0.3)), lineWidth: WatchAdaptiveSizing.spacing / 4)
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: WatchAdaptiveSizing.spacing * 2) {
                Spacer()
                
                // Animated logo with energy effect (adaptive sizing)
                ZStack {
                    // Energy ring (adaptive)
                    if showContent {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.brandPrimary.opacity(0.8),
                                        Color.brandAccent.opacity(0.4),
                                        Color.brandPrimary.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: WatchAdaptiveSizing.spacing / 2
                            )
                            .frame(width: WatchAdaptiveSizing.spacing * 10, height: WatchAdaptiveSizing.spacing * 10)
                            .rotationEffect(.degrees(particleAnimation ? 360 : 0))
                            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: particleAnimation)
                    }
                    
                    // Main logo circle (adaptive)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.brandPrimary,
                                    Color.brandPrimary.opacity(0.8),
                                    Color.brandAccent.opacity(0.6)
                                ]),
                                center: .topLeading,
                                startRadius: WatchAdaptiveSizing.spacing / 2,
                                endRadius: WatchAdaptiveSizing.spacing * 4.5
                            )
                        )
                        .frame(width: WatchAdaptiveSizing.spacing * 9, height: WatchAdaptiveSizing.spacing * 9)
                        .shadow(color: Color.brandPrimary.opacity(0.6), radius: WatchAdaptiveSizing.spacing * 2)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // Runner icon (adaptive)
                    Image(systemName: "figure.run")
                        .font(.system(size: WatchAdaptiveSizing.spacing * 4, weight: .bold))
                        .foregroundColor(Color.brandBackground)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: Color.brandBackground.opacity(0.3), radius: WatchAdaptiveSizing.spacing / 4)
                }
                
                // App title with premium styling (adaptive)
                VStack(spacing: WatchAdaptiveSizing.spacing) {
                    HStack(spacing: WatchAdaptiveSizing.spacing / 2) {
                        Text("SPRINT")
                            .font(.system(size: WatchAdaptiveSizing.spacing * 2.25, weight: .black, design: .rounded))
                            .tracking(WatchAdaptiveSizing.spacing / 2)
                        Text("COACH")
                            .font(.system(size: WatchAdaptiveSizing.spacing * 2.25, weight: .black, design: .rounded))
                            .tracking(WatchAdaptiveSizing.spacing / 2)
                    }
                    .foregroundColor(Color.brandPrimary)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: WatchAdaptiveSizing.spacing / 2)
                    
                    Text("40")
                        .font(.system(size: WatchAdaptiveSizing.spacing * 4, weight: .black, design: .rounded))
                        .tracking(WatchAdaptiveSizing.spacing / 2)
                        .foregroundColor(Color.brandSecondary)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                        .shadow(color: Color.brandSecondary.opacity(0.2), radius: WatchAdaptiveSizing.spacing / 4)
                }
                
                // Premium tagline (adaptive)
                Text("Elite Sprint Training")
                    .font(.system(size: WatchAdaptiveSizing.spacing * 1.5, weight: .semibold, design: .rounded))
                    .tracking(WatchAdaptiveSizing.spacing / 4)
                    .foregroundColor(Color.brandAccent)
                    .opacity(taglineOpacity)
                
                Spacer()
                
                // Loading indicator (adaptive)
                if showContent {
                    VStack(spacing: WatchAdaptiveSizing.spacing) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.brandPrimary))
                            .scaleEffect(WatchAdaptiveSizing.spacing / 10)
                        
                        Text("Initializing...")
                            .font(.system(size: WatchAdaptiveSizing.spacing * 1.25, weight: .medium, design: .rounded))
                            .foregroundColor(Color.brandSecondary.opacity(0.7))
                    }
                    .opacity(taglineOpacity)
                }
                
                Spacer()
            }
            .adaptivePadding()
        }
        .onAppear {
            startSplashAnimation()
        }
    }
    
    private func startSplashAnimation() {
        // Play startup haptic
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
        
        // Stage 1: Logo appears (0.0s - 0.8s)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Stage 2: Title slides in (0.3s - 1.1s)
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Stage 3: Tagline fades in (0.6s - 1.4s)
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            taglineOpacity = 1.0
        }
        
        // Stage 4: Energy effects start (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showContent = true
            }
            
            // Start particle animation
            withAnimation(.linear(duration: 0.1)) {
                particleAnimation = true
            }
        }
        
        // Stage 5: Success haptic (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        }
        
        // Stage 6: Complete splash (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                logoScale = 1.2
                logoOpacity = 0.0
                titleOpacity = 0.0
                taglineOpacity = 0.0
            }
            
            // Call completion after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

#Preview("SC40 Splash") {
    SC40SplashView(onComplete: {})
        .preferredColorScheme(.dark)
}
