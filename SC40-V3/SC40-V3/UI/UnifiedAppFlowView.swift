import SwiftUI

/// Single unified entry point for the entire app
/// Manages: Splash → Authentication → Onboarding → Main App
struct UnifiedAppFlowView: View {
    @StateObject private var userProfileVM = UserProfileViewModel()
    @StateObject private var authManager = AuthenticationManager.shared
    @EnvironmentObject private var syncManager: TrainingSynchronizationManager
    
    // MARK: - App Flow State
    // NUCLEAR BYPASS: Skip directly to training to avoid navigation crashes
    @State private var currentFlow: AppFlow = .training  // CHANGED FROM .splash
    @State private var userName: String = ""
    @State private var userEmail: String? = nil
    
    // MARK: - Animation State
    @State private var animateLogo = false
    @State private var animateNumber = false
    @State private var animateSubtitle = false
    @State private var animateTapPrompt = false
    
    enum AppFlow {
        case splash
        case authentication
        case onboarding
        case training
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background (consistent across all views)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.15, green: 0.05, blue: 0.25),
                    Color(red: 0.05, green: 0.02, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content based on current flow
            Group {
                switch currentFlow {
                case .splash:
                    splashView
                case .authentication:
                    authenticationView
                case .onboarding:
                    onboardingView
                case .training:
                    trainingView
                }
            }
        }
        .onAppear {
            checkAppState()
        }
    }
    
    // MARK: - Splash View
    private var splashView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Sprint Coach 40 Logo Section
            VStack(spacing: 16) {
                // Premium runner icon
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.0))
                        .shadow(color: Color(red: 1.0, green: 0.9, blue: 0.0).opacity(0.6), radius: 25)
                        .scaleEffect(animateLogo ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateLogo)
                }
                
                Text("SPRINT COACH")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.3), radius: 8)
                    .opacity(animateLogo ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 1.5).delay(0.5).repeatForever(autoreverses: true), value: animateLogo)
            }
            
            // Large "40" number
            Text("40")
                .font(.system(size: 140, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.8, green: 1.0, blue: 0.7))
                .shadow(color: Color(red: 0.8, green: 1.0, blue: 0.7).opacity(0.4), radius: 30)
                .scaleEffect(animateNumber ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.5).delay(1.0).repeatForever(autoreverses: true), value: animateNumber)
            
            Text("Elite Sprint Training")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .tracking(1)
                .shadow(color: .black.opacity(0.2), radius: 4)
                .opacity(animateSubtitle ? 1.0 : 0.7)
                .animation(.easeInOut(duration: 2.0).delay(1.5).repeatForever(autoreverses: true), value: animateSubtitle)
            
            Spacer()
            
            // Tap to continue
            VStack(spacing: 8) {
                Text("Tap to continue")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1)
                    .opacity(animateTapPrompt ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 1.8).delay(2.0).repeatForever(autoreverses: true), value: animateTapPrompt)
                
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
        .onTapGesture {
            proceedToNextFlow()
        }
        .onAppear {
            startSplashAnimations()
            
            // Auto-advance after 3 seconds
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if currentFlow == .splash {
                    proceedToNextFlow()
                }
            }
        }
    }
    
    // MARK: - Authentication View
    private var authenticationView: some View {
        WelcomeView { name, email in
            print("✅ UnifiedAppFlow: Authentication completed - name: \(name), email: \(email ?? "nil")")
            userName = name
            userEmail = email
            userProfileVM.profile.name = name
            if let email = email {
                userProfileVM.profile.email = email
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                currentFlow = .onboarding
            }
        }
    }
    
    // MARK: - Onboarding View
    private var onboardingView: some View {
        OnboardingView(userName: userName, userProfileVM: userProfileVM) {
            print("🔥 NUCLEAR DEBUG: UnifiedAppFlow onComplete called")
            print("🔥 NUCLEAR DEBUG: Current thread: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
            print("🔥 NUCLEAR DEBUG: About to change currentFlow to .training")
            
            // NUCLEAR FIX: Ensure main thread and immediate navigation
            DispatchQueue.main.async {
                print("🔥 NUCLEAR DEBUG: On main thread, setting currentFlow = .training")
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentFlow = .training
                }
                print("✅ NUCLEAR DEBUG: Navigation completed successfully")
            }
        }
    }
    
    // MARK: - Training View
    private var trainingView: some View {
        TrainingView(userProfileVM: userProfileVM)
            .environmentObject(syncManager)
            .onAppear {
                // NUCLEAR BYPASS: Setup minimal profile data for TrainingView
                setupNuclearProfile()
            }
    }
    
    private func setupNuclearProfile() {
        print("🔥 NUCLEAR BYPASS: Setting up profile for TrainingView")
        
        // Set UserDefaults
        UserDefaults.standard.set("Beginner", forKey: "userLevel")
        UserDefaults.standard.set(1, forKey: "trainingFrequency")
        UserDefaults.standard.set(6.25, forKey: "personalBest40yd")
        UserDefaults.standard.set("David", forKey: "userName")
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        UserDefaults.standard.synchronize()
        
        // Update ViewModel
        userProfileVM.profile.level = "Beginner"
        userProfileVM.profile.frequency = 1
        userProfileVM.profile.personalBests["40yd"] = 6.25
        userProfileVM.profile.baselineTime = 6.25
        userProfileVM.profile.name = "David"
        
        print("✅ NUCLEAR BYPASS: Profile setup complete for TrainingView")
    }
    
    // MARK: - Helper Methods
    
    private func checkAppState() {
        print("🔍 UnifiedAppFlow: Checking app state...")
        
        // Initialize watch connectivity with basic app state
        Task {
            await initializeWatchConnectivity()
        }
        
        // Check if onboarding is completed
        let onboardingCompleted = UserDefaultsManager.shared.getBool(forKey: "onboardingCompleted")
        
        if onboardingCompleted {
            print("✅ UnifiedAppFlow: Onboarding completed - going directly to training")
            currentFlow = .training
            return
        }
        
        // Check if user has been authenticated before
        if let storedName = UserDefaultsManager.shared.getString(forKey: "welcomeUserName") {
            print("👤 UnifiedAppFlow: Found stored user - going to onboarding")
            userName = storedName
            userProfileVM.profile.name = storedName
            
            if let storedEmail = UserDefaultsManager.shared.getString(forKey: "welcomeUserEmail") {
                userEmail = storedEmail
                userProfileVM.profile.email = storedEmail
            }
            
            // Clear stored data
            UserDefaultsManager.shared.removeValue(forKey: "welcomeUserName")
            UserDefaultsManager.shared.removeValue(forKey: "welcomeUserEmail")
            
            currentFlow = .onboarding
            return
        }
        
        print("🆕 UnifiedAppFlow: New user - starting with splash")
        currentFlow = .splash
    }
    
    private func initializeWatchConnectivity() async {
        // Send initial app state to watch to prevent "nil context" messages
        let initialContext: [String: Any] = [
            "type": "app_state",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "appLaunched": Date(),
            "onboardingCompleted": UserDefaultsManager.shared.getBool(forKey: "onboardingCompleted"),
            "userExists": UserDefaultsManager.shared.getString(forKey: "welcomeUserName") != nil
        ]
        
        // Send context to watch connectivity manager
        let watchManager = WatchConnectivityManager.shared
        watchManager.sendApplicationContext(initialContext)
    }
    
    private func proceedToNextFlow() {
        withAnimation(.easeInOut(duration: 0.6)) {
            currentFlow = .authentication
        }
    }
    
    private func startSplashAnimations() {
        withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
            animateLogo = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).delay(0.8)) {
            animateNumber = true
        }
        
        withAnimation(.easeInOut(duration: 1.8).delay(1.8)) {
            animateSubtitle = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).delay(2.2)) {
            animateTapPrompt = true
        }
    }
}

#Preview {
    UnifiedAppFlowView()
        .environmentObject(TrainingSynchronizationManager.shared)
}
