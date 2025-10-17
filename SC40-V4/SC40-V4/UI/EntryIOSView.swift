import SwiftUI

struct EntryIOSView: View {
    @State private var isActive = false
    @State private var animateSprinter = false
    @State private var showWelcome = false
    @State private var showContentView = false
    @State private var animateLogo = false
    @State private var animateNumber = false
    @State private var animateSubtitle = false
    @State private var animateTapPrompt = false

    var body: some View {
        if showContentView {
            ContentView()
        } else if showWelcome {
            WelcomeView(onContinue: { name, email in
                // Store user data and transition to ContentView (onboarding flow)
                UserDefaults.standard.set(name, forKey: "welcomeUserName")
                if let email = email {
                    UserDefaults.standard.set(email, forKey: "welcomeUserEmail")
                }
                withAnimation {
                    showContentView = true
                }
            })
        } else {
            ZStack {
                // Enhanced premium gradient background
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

                // Subtle animated background particles
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(Double(index) * 0.02 + 0.05))
                        .frame(width: CGFloat(index * 2 + 4), height: CGFloat(index * 2 + 4))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 3...6))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...2)),
                            value: UUID()
                        )
                }

                // Premium glass effect overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.1)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // Sprint Coach 40 Logo Section
                    VStack(spacing: 16) {
                        // Premium lightning bolt icon
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)

                            Image(systemName: "bolt.fill")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.0))
                                .shadow(color: Color(red: 1.0, green: 0.9, blue: 0.0).opacity(0.6), radius: 25)
                                .scaleEffect(animateLogo ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateLogo)
                        }

                        // Sprint Coach text with premium styling
                        Text("SPRINT COACH")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(4)
                            .shadow(color: .black.opacity(0.3), radius: 8)
                            .opacity(animateLogo ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 1.5).delay(0.5).repeatForever(autoreverses: true), value: animateLogo)
                    }

                    // Large premium "40" number
                    Text("40")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.8, green: 1.0, blue: 0.7)) // Premium green
                        .shadow(color: Color(red: 0.8, green: 1.0, blue: 0.7).opacity(0.4), radius: 30)
                        .scaleEffect(animateNumber ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 2.5).delay(1.0).repeatForever(autoreverses: true), value: animateNumber)

                    // Enhanced runner icon with premium styling
                    ZStack {
                        // Multiple gradient rings for premium effect
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 90, height: 90)
                            .blur(radius: 1)

                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 85, height: 85)

                        // Inner glow effect
                        Circle()
                            .fill(Color.cyan.opacity(0.1))
                            .frame(width: 75, height: 75)
                            .blur(radius: 8)

                        Image(systemName: "figure.run")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(Color.cyan)
                            .scaleEffect(animateSprinter ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateSprinter)
                    }
                    .shadow(color: Color.cyan.opacity(0.3), radius: 15)

                    // Premium subtitle with enhanced styling
                    Text("Elite Sprint Training")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(1)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                        .opacity(animateSubtitle ? 1.0 : 0.7)
                        .animation(.easeInOut(duration: 2.0).delay(1.5).repeatForever(autoreverses: true), value: animateSubtitle)

                    Spacer()

                    // Premium "Tap to continue" with enhanced styling
                    VStack(spacing: 8) {
                        Text("Tap to continue")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)
                            .opacity(animateTapPrompt ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 1.8).delay(2.0).repeatForever(autoreverses: true), value: animateTapPrompt)

                        // Subtle indicator dots
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 4, height: 4)
                                    .scaleEffect(animateTapPrompt ? 1.2 : 0.8)
                                    .animation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever()
                                        .delay(Double(index) * 0.3),
                                        value: animateTapPrompt
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .onTapGesture {
                // Enhanced haptic feedback for premium feel
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif

                withAnimation(.easeInOut(duration: 0.6)) {
                    showWelcome = true
                }
            }
            .onAppear {
                // Staggered animation sequence for premium reveal
                withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                    animateLogo = true
                }

                withAnimation(.easeInOut(duration: 1.5).delay(0.8)) {
                    animateNumber = true
                }

                withAnimation(.easeInOut(duration: 1.2).delay(1.2)) {
                    animateSprinter = true
                }

                withAnimation(.easeInOut(duration: 1.8).delay(1.8)) {
                    animateSubtitle = true
                }

                withAnimation(.easeInOut(duration: 1.5).delay(2.2)) {
                    animateTapPrompt = true
                }

                // Auto-advance after premium display time
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds for premium experience
                    if !showWelcome {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showWelcome = true
                        }
                    }
                }
            }
        }
    }
}

// Animated sprinter component (kept for compatibility)
struct SprinterAnimationView: View {
    @Binding var animate: Bool
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 80, height: 80)

            Image(systemName: "figure.run")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(Color.cyan)
                .scaleEffect(animate ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
        }
    }
}

#if DEBUG
#Preview("1. Premium Splash Screen") {
    EntryIOSView()
        .preferredColorScheme(.dark)
}

#Preview("2. WelcomeView") {
    WelcomeView(onContinue: { _, _ in })
        .preferredColorScheme(.dark)
}

#Preview("3. OnboardingView") {
    OnboardingView(userName: "David", userProfileVM: UserProfileViewModel(), onComplete: {})
        .preferredColorScheme(.dark)
}

// Temporary preview since RecordCardView is in ContentView.swift
#Preview("4. Quick Win Introduction") {
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
        Text("Record Card Preview")
            .foregroundColor(.white)
            .font(.headline)
    }
    .preferredColorScheme(.dark)
}

#Preview("5. TrainingView") {
    TrainingView(userProfileVM: UserProfileViewModel())
        .preferredColorScheme(.dark)
}
#endif
