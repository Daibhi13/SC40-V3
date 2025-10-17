import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// SC40 Premium Splash Screen - Professional Style with Adaptive Glass Effect
@available(watchOS 10.0, *)
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
                            Color(red: 0.05, green: 0.05, blue: 0.1).opacity(0.9),
                            Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.7),
                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.regularMaterial) // Glass effect for watchOS
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                // Animated logo with energy effect (adaptive sizing)
                ZStack {
                    // Energy ring (adaptive)
                    if showContent {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8),
                                        Color(red: 0.2, green: 0.8, blue: 1.0).opacity(0.4),
                                        Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(particleAnimation ? 360 : 0))
                            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: particleAnimation)
                    }
                    
                    // Main logo circle (adaptive)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0),
                                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8),
                                    Color(red: 0.2, green: 0.8, blue: 1.0).opacity(0.6)
                                ]),
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 36
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6), radius: 16)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // Lightning bolt icon (adaptive)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.05, blue: 0.1))
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: Color(red: 0.05, green: 0.05, blue: 0.1).opacity(0.3), radius: 2)
                }
                
                // App title with premium styling (adaptive)
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("SPRINT")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(1.5)
                        Text("COACH")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(1.5)
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 4)
                    
                    Text("40")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                        .shadow(color: Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.2), radius: 2)
                }
                
                // Premium tagline (adaptive)
                Text("Elite Sprint Training")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 1.0))
                    .opacity(taglineOpacity)
                
                Spacer()
                
                // Loading indicator (adaptive)
                if showContent {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.0)))
                            .scaleEffect(0.8)
                        
                        Text("Initializing...")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.7))
                    }
                    .opacity(taglineOpacity)
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
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
