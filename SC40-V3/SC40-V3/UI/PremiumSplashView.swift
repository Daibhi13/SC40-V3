import SwiftUI

#if os(iOS)
import UIKit
#endif

struct PremiumSplashView: View {
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var lightningBoltScale: CGFloat = 0.8
    @State private var lightningBoltRotation: Double = 0
    @State private var particleAnimation = false
    @State private var glowIntensity: Double = 0.3
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Enhanced premium gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.02, green: 0.05, blue: 0.15), location: 0.0),
                    .init(color: Color(red: 0.08, green: 0.15, blue: 0.3), location: 0.2),
                    .init(color: Color(red: 0.12, green: 0.2, blue: 0.4), location: 0.4),
                    .init(color: Color(red: 0.15, green: 0.1, blue: 0.35), location: 0.6),
                    .init(color: Color(red: 0.1, green: 0.05, blue: 0.2), location: 0.8),
                    .init(color: Color(red: 0.05, green: 0.02, blue: 0.1), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            // Animated particle background
            GeometryReader { geometry in
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .scaleEffect(particleAnimation ? 1.2 : 0.8)
                        .opacity(particleAnimation ? 0.8 : 0.3)
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: particleAnimation
                        )
                }
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Enhanced content container
                VStack(spacing: 50) {
                    // Runner icon with glow effect
                    ZStack {
                        // Outer glow
                        Image(systemName: "figure.run")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.yellow.opacity(glowIntensity))
                            .blur(radius: 20)
                            .scaleEffect(lightningBoltScale * 1.2)
                        
                        // Main runner icon
                        Image(systemName: "figure.run")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.yellow)
                            .scaleEffect(lightningBoltScale)
                            .rotationEffect(.degrees(lightningBoltRotation))
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: showContent)
                    
                    // "SPRINT COACH" text with enhanced styling
                    VStack(spacing: 8) {
                        Text("SPRINT COACH")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(6)
                            .shadow(color: .white.opacity(0.3), radius: 5)
                        
                        // Underline accent
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.yellow, .orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: 120, height: 2)
                            .cornerRadius(1)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(0.6), value: showContent)
                    
                    // Large "40" numbers with enhanced styling
                    ZStack {
                        // Background glow
                        Text("40")
                            .font(.system(size: 200, weight: .black, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.3))
                            .blur(radius: 30)
                        
                        // Main number with gradient
                        Text("40")
                            .font(.system(size: 200, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .yellow.opacity(0.5), radius: 20)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.7)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 1.5, dampingFraction: 0.7).delay(0.9), value: showContent)
                    
                    // Enhanced subtitle with icon
                    HStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.cyan)
                        
                        Text("Elite Sprint Training")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(2)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.cyan)
                            .scaleEffect(x: -1, y: 1) // Mirror the icon
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(1.2), value: showContent)
                }
                
                Spacer()
                
                // Enhanced "Tap to continue" button
                VStack(spacing: 16) {
                    // Animated chevron
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Button(action: {
                        // Simple haptic feedback without HapticManager dependency
                        #if os(iOS)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        #endif
                        onContinue()
                    }) {
                        VStack(spacing: 8) {
                            Text("Tap to continue")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Subtle underline animation
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: pulseAnimation ? 140 : 120, height: 1)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                .padding(.bottom, 50)
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 1.0).delay(1.8), value: showContent)
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
            particleAnimation = true
            
            // Start lightning bolt animations
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                lightningBoltScale = 1.1
                glowIntensity = 0.8
            }
            
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                lightningBoltRotation = 360
            }
        }
        .onTapGesture {
            // Simple haptic feedback without HapticManager dependency
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            onContinue()
        }
    }
}

#Preview {
    PremiumSplashView(onContinue: {})
}
