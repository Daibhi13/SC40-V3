import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// SC40 Watch Onboarding View - Professional Style
struct WatchOnboardingView: View {
    @ObservedObject private var authManager = WatchAuthManager.shared
    @State private var currentStep = 0
    @State private var selectedLevel = "Intermediate"
    @State private var targetTime: Double = 5.0
    @State private var onboardingScale: CGFloat = 0.8
    @State private var onboardingOpacity: Double = 0.0
    
    private let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
    private let timeRanges: [String: (min: Double, max: Double, default: Double)] = [
        "Beginner": (6.0, 8.0, 7.0),
        "Intermediate": (4.5, 6.0, 5.0),
        "Advanced": (3.8, 4.5, 4.2),
        "Elite": (3.0, 3.8, 3.5)
    ]
    
    var body: some View {
        ZStack {
            // Premium gradient background
            Canvas { context, size in
                let gradient = Gradient(colors: [
                    Color.brandBackground,
                    Color.brandTertiary.opacity(0.6),
                    Color.brandAccent.opacity(0.1)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
            }
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.brandPrimary : Color.brandTertiary.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 8)
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        levelSelectionStep
                    case 2:
                        timeTargetStep
                    default:
                        welcomeStep
                    }
                }
                .scaleEffect(onboardingScale)
                .opacity(onboardingOpacity)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                            #if os(watchOS)
                            WKInterfaceDevice.current().play(.click)
                            #endif
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.brandSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.brandTertiary.opacity(0.2))
                        )
                        .buttonStyle(.plain)
                    }
                    
                    Button(currentStep == 2 ? "Complete" : "Next") {
                        if currentStep == 2 {
                            // Complete onboarding
                            authManager.completeOnboarding(userLevel: selectedLevel, targetTime: targetTime)
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep += 1
                                updateTargetTimeForLevel()
                            }
                        }
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.brandBackground)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.brandPrimary)
                    )
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            // Animate onboarding appearance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                onboardingScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                onboardingOpacity = 1.0
            }
            
            // Play welcome haptic
            #if os(watchOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.start)
            }
            #endif
        }
    }
    
    // MARK: - Onboarding Steps
    
    private var welcomeStep: some View {
        VStack(spacing: 16) {
            // Welcome icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.brandPrimary.opacity(0.8),
                                Color.brandPrimary.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.brandBackground)
            }
            
            VStack(spacing: 8) {
                Text("Welcome to SC40!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Let's set up your personalized sprint training program")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.brandSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var levelSelectionStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Your Level")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandPrimary)
                
                Text("Choose your current sprint level")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.brandSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Level selection
            VStack(spacing: 8) {
                ForEach(levels, id: \.self) { level in
                    Button(action: {
                        selectedLevel = level
                        updateTargetTimeForLevel()
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                    }) {
                        HStack(spacing: 8) {
                            Text(levelEmoji(for: level))
                                .font(.system(size: 14))
                            
                            Text(level)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                            
                            Spacer()
                            
                            if selectedLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.brandPrimary)
                            }
                        }
                        .foregroundColor(selectedLevel == level ? Color.brandPrimary : Color.brandSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedLevel == level ? Color.brandPrimary.opacity(0.1) : Color.brandTertiary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selectedLevel == level ? Color.brandPrimary.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var timeTargetStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("40-Yard Target")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandPrimary)
                
                Text("Set your current 40-yard dash time")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.brandSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Time picker
            VStack(spacing: 12) {
                // Current time display
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", targetTime))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandPrimary)
                    
                    Text("seconds")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color.brandSecondary.opacity(0.8))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.brandTertiary.opacity(0.1))
                )
                
                // Time adjustment buttons
                HStack(spacing: 16) {
                    Button(action: {
                        if targetTime > timeRanges[selectedLevel]?.min ?? 3.0 {
                            targetTime -= 0.1
                        }
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.brandAccent)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if targetTime < timeRanges[selectedLevel]?.max ?? 8.0 {
                            targetTime += 0.1
                        }
                        #if os(watchOS)
                        WKInterfaceDevice.current().play(.click)
                        #endif
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.brandAccent)
                    }
                    .buttonStyle(.plain)
                }
                
                // Level indicator
                Text("\(selectedLevel) Level")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(Color.brandSecondary.opacity(0.6))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func levelEmoji(for level: String) -> String {
        switch level.lowercased() {
        case "beginner":
            return "🟠"
        case "intermediate":
            return "🟢"
        case "advanced":
            return "🔵"
        case "elite":
            return "🟣"
        default:
            return "🟢"
        }
    }
    
    private func updateTargetTimeForLevel() {
        if let range = timeRanges[selectedLevel] {
            targetTime = range.default
        }
    }
}

#Preview("Watch Onboarding") {
    WatchOnboardingView()
        .preferredColorScheme(.dark)
}
