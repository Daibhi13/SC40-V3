//
//  ContentView.swift
//  SC40
//
//  Created by David O'Connell on 17/08/2025.
//

import SwiftUI
import Combine

enum AppFlowStep {
    case welcome
    case onboarding(name: String)
    case stopwatchIntro
    case record
    case training
}

/// SIMPLIFIED: ContentView is now just a navigation container, not an entry point
/// Entry point is handled by UnifiedAppFlowView
struct ContentView: View {
    @State private var step: AppFlowStep = .welcome
    @StateObject private var userProfileVM = UserProfileViewModel()
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @EnvironmentObject private var syncManager: TrainingSynchronizationManager
    @State private var hasAppeared = false
    @State private var isOnboardingCompleting = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.brandBackground, Color.brandAccent]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
                .glassEffect(blurRadius: 24, opacity: 0.92)
            switch step {
            case .welcome:
                WelcomeView(onContinue: { name, email in
                    print("🧭 [CONTENTVIEW] [WELCOME]: onContinue called with name=\(name), email=\(email ?? "nil")")
                    
                    // CRASH PROTECTION: Ensure we're on main thread and add validation
                    Task { @MainActor in
                        // Validate inputs
                        let safeName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !safeName.isEmpty else {
                            print("❌ [CONTENTVIEW] [WELCOME]: Invalid name, using fallback")
                            return
                        }
                        
                        // Update profile safely
                        userProfileVM.profile.name = safeName
                        if let email = email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            userProfileVM.profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        print("✅ [CONTENTVIEW] [WELCOME]: Profile updated safely")
                        
                        // Navigate with crash protection
                        withAnimation(.easeInOut(duration: 0.3)) { 
                            step = .onboarding(name: safeName) 
                        }
                        print("✅ [CONTENTVIEW] [WELCOME]: Navigation to onboarding completed")
                    }
                })
            case .onboarding(let name):
                ErrorBoundary(context: "OnboardingView") {
                    OnboardingView(userName: name, userProfileVM: userProfileVM, onComplete: {
                    print("🧭 [CONTENTVIEW] [SIMPLE]: Onboarding completion requested")
                    
                    // CRASH PROTECTION: Prevent multiple completion calls
                    guard !isOnboardingCompleting else {
                        print("⚠️ [CONTENTVIEW] [DUPLICATE]: Already completing, ignoring")
                        return
                    }
                    
                    isOnboardingCompleting = true
                    
                    // CRASH PROTECTION: Immediate navigation on main thread
                    DispatchQueue.main.async {
                        print("🧭 [NAVIGATION]: Navigating to TrainingView immediately")
                        withAnimation(.easeInOut(duration: 0.3)) { 
                            step = .training 
                        }
                        isOnboardingCompleting = false
                        print("✅ [CONTENTVIEW] [COMPLETE]: Navigation completed")
                        
                        // CRASH PROTECTION: All heavy operations moved to background after navigation
                        DispatchQueue.global(qos: .background).async {
                            print("🔄 Starting background sync operations")
                            // Background sync can happen after successful navigation
                        }
                    }
                })
                }
            case .stopwatchIntro:
                ErrorBoundary(context: "RecordCardView") {
                    RecordCardView(userName: userProfileVM.profile.name, onContinue: {
                        withAnimation { step = .training }
                    })
                }
            case .record:
                ErrorBoundary(context: "RecordCardView") {
                    RecordCardView(userName: userProfileVM.profile.name, onContinue: { withAnimation { step = .training } })
                }
            case .training:
                ErrorBoundary(context: "TrainingView") {
                    TrainingView(userProfileVM: userProfileVM)
                        .environmentObject(syncManager)
                }
            }
        }
        .withLoadingOverlay()
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            
            print("📱 ContentView appeared as navigation container")
            // NOTE: Entry point logic is now handled by UnifiedAppFlowView
            // ContentView is just a navigation container for internal flows
        }
    }
    
    // MARK: - Level Validation Helpers
    
    @MainActor
    private func getUserLevel() -> String {
        // Check multiple possible keys for user level
        if let level = UserDefaultsManager.shared.getString(forKey: "SC40_UserLevel"), !level.isEmpty {
            return level
        }
        if let level = UserDefaultsManager.shared.getString(forKey: "userLevel"), !level.isEmpty {
            return level
        }
        if let level = UserDefaultsManager.shared.getString(forKey: "user_level"), !level.isEmpty {
            return level
        }
        
        // Preserve user selection - don't override with default
        print("⚠️ ContentView: No level found in UserDefaults, using Beginner as safe fallback")
        return "Beginner"
    }
    
    private static func stringToTrainingLevel(_ levelString: String) -> TrainingLevel {
        let normalizedLevel = levelString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch normalizedLevel {
        case "beginner":
            return .beginner
        case "intermediate":
            return .intermediate
        case "advanced":
            return .advanced
        case "elite", "pro":
            return .elite
        default:
            return .intermediate // Default fallback
        }
    }
}

struct RecordCardView: View {
    let userName: String
    var onContinue: () -> Void
    @State private var animateRunner = false
    @State private var showQuickWinSession = false
    
    var body: some View {
        ZStack {
            // Premium gradient background matching the design
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),  // Dark blue top
                    Color(red: 0.2, green: 0.1, blue: 0.3),  // Purple middle
                    Color(red: 0.1, green: 0.05, blue: 0.2)  // Dark purple bottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // "Welcome, [UserName]!" with wave emoji
                HStack {
                    Text("Welcome, \(userName)!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("👋")
                        .font(.system(size: 28))
                }
                
                // "Let's get your first win!" subtitle
                Text("Let's get your first win!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
                
                // Quick Win Card
                VStack(spacing: 20) {
                    // Runner icon
                    Image(systemName: "figure.run")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
                        .scaleEffect(animateRunner ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateRunner)
                    
                    Text("Quick 10-Minute Warm-Up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete a simple warm-up session to get started and unlock your first achievement")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Feature list
                    VStack(alignment: .leading, spacing: 8) {
                        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Easy to follow", color: .green)
                        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Only 10 minutes", color: .green)
                        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Unlock first badge", color: .green)
                        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Start tracking progress", color: .green)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showQuickWinSession = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Start Quick Win Session")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
                        .cornerRadius(25)
                    }
                    
                    Button(action: onContinue) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation {
                animateRunner = true
            }
        }
        .sheet(isPresented: $showQuickWinSession) {
            QuickWinWorkoutView(onComplete: {
                showQuickWinSession = false
                onContinue()
            })
        }
    }
}

// Helper view for quick win feature rows
// Note: This component is defined in QuickWinView.swift for consistency

struct CountdownView: View {
    let targetTime: Double
    @State private var counter: Double = 0.0
    @State private var timerActive = true
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        Text(String(format: "%.2f s", counter))
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(.brandPrimary)
            .onAppear {
                startCountdown()
            }
            .onDisappear {
                timerActive = false
                task?.cancel()
            }
    }
    
    private func startCountdown() {
        counter = 0.0
        timerActive = true
        task = Task { @MainActor in
            while counter < targetTime && timerActive {
                try? await Task.sleep(for: .milliseconds(50))
                if timerActive {
                    counter += 0.05
                }
            }
        }
    }
}

#if DEBUG
#Preview("1. Splash Screen") {
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

#Preview("4. Quick Win Introduction") {
    RecordCardView(userName: "David", onContinue: {})
        .preferredColorScheme(.dark)
}

#Preview("5. TrainingView") {
    TrainingView(userProfileVM: UserProfileViewModel())
        .preferredColorScheme(.dark)
}

#Preview("ContentView - Default") {
    ContentView()
}

#Preview("ContentView - Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
#endif
