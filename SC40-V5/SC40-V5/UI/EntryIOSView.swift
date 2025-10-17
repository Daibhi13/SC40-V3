//
//  EntryIOSView.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI

/// Premium splash screen with animations and branding
struct EntryIOSView: View {
    @State private var isAnimating = false
    @State private var showMainContent = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var taglineOffset: CGFloat = 50

    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackgroundView()

            VStack {
                Spacer()

                // Logo and branding
                VStack(spacing: 20) {
                    // Main logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple, .pink]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .opacity(isAnimating ? 1.0 : 0.7)

                        Image(systemName: "figure.run")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }

                    // App name
                    Text("SC40-V5")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: isAnimating)

                    // Tagline
                    Text("Sprint Coach Pro")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .offset(y: taglineOffset)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                }

                Spacer()

                // Version info
                Text("Version 5.0")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.9), value: isAnimating)
            }
            .padding()
        }
        .onAppear {
            startAnimationSequence()
        }
        .fullScreenCover(isPresented: $showMainContent) {
            ContentView()
        }
    }

    private func startAnimationSequence() {
        // Initial animation
        withAnimation(.easeOut(duration: 0.8)) {
            isAnimating = true
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Tagline animation
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            taglineOffset = 0
        }

        // Transition to main content
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                showMainContent = true
            }
        }
    }
}

// MARK: - Animated Background

struct AnimatedBackgroundView: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(gradient: Gradient(colors: [.blue, .purple, .pink]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)

            // Animated overlay gradients
            ForEach(0..<3) { index in
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.white.opacity(0.1), .clear]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing))
                    .frame(width: 200, height: 200)
                    .offset(x: animateGradient ? 100 : -100,
                           y: animateGradient ? 100 : -100)
                    .rotationEffect(.degrees(animateGradient ? 360 : 0))
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(Double(index) * 0.5),
                             value: animateGradient)
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Custom Components

struct PulsingCircle: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.3))
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

struct GradientText: View {
    let text: String
    let gradient: LinearGradient

    var body: some View {
        Text(text)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(gradient)
    }
}

// MARK: - Entry Animation Modifier

struct EntryAnimationModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.easeOut(duration: 0.6), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func withEntryAnimation() -> some View {
        modifier(EntryAnimationModifier())
    }
}

// MARK: - Preview

struct EntryIOSView_Previews: PreviewProvider {
    static var previews: some View {
        EntryIOSView()
    }
}
