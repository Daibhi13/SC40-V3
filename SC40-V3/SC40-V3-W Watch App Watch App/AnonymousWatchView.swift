import SwiftUI
import WatchConnectivity

struct AnonymousWatchView: View {
    @State private var currentGreeting = "Ready to Sprint?"
    @State private var showPulse = false
    @State private var greetingIndex = 0
    @State private var connectivityStatus: ConnectivityStatus = .waiting
    @State private var onboardingCheckTimer: Timer?
    @State private var testModeActive = false
    // TODO: Re-enable when managers are available
    // @StateObject private var watchConnectivity = LiveWatchConnectivityHandler.shared
    // @StateObject private var watchStateManager = WatchAppStateManager.shared
    
    enum ConnectivityStatus {
        case waiting, connecting, syncing, ready, failed
        
        var displayText: String {
            switch self {
            case .waiting: return "Waiting for iPhone..."
            case .connecting: return "Connecting..."
            case .syncing: return "Syncing data..."
            case .ready: return "Ready to train!"
            case .failed: return "Connection failed"
            }
        }
        
        var color: Color {
            switch self {
            case .waiting: return .orange
            case .connecting: return .blue
            case .syncing: return .purple
            case .ready: return .green
            case .failed: return .red
            }
        }
    }
    
    private let greetings = [
        "Ready to Sprint?",
        "Let's Get Faster",
        "Time to Train", 
        "Sprint Mode On",
        "Ready, Champion?"
    ]
    
    private let identities = [
        "Champion",
        "Sprinter",
        "Athlete", 
        "Runner",
        "Speedster"
    ]
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.3, blue: 0.5),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // App branding
                VStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.yellow)
                        .scaleEffect(showPulse ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showPulse)
                    
                    Text("SC40-V3")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("Sprint Training")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer().frame(height: 4)
                
                // Dynamic greeting (no name needed)
                Text(currentGreeting)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.5), value: currentGreeting)
                
                // Connectivity status
                VStack(spacing: 4) {
                    Text(connectivityStatus.displayText)
                        .font(.caption.bold())
                        .foregroundColor(connectivityStatus.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(connectivityStatus.color.opacity(0.2))
                        .cornerRadius(8)
                    
                    if testModeActive {
                        Text("TEST MODE")
                            .font(.caption2.bold())
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                
                Spacer().frame(height: 8)
                
                // Immediate action buttons
                VStack(spacing: 6) {
                    // Primary action - context-aware
                    Button(action: {
                        handlePrimaryAction()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.subheadline)
                            Text("Start Training")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    
                    // Secondary actions
                    HStack(spacing: 6) {
                        Button(action: {
                            // Quick time trial
                        }) {
                            HStack {
                                Image(systemName: "stopwatch")
                                    .font(.caption)
                                Text("Time Trial")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // Basic exercises
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.caption)
                                Text("Exercises")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer().frame(height: 6)
                
                // Setup enhancement (not requirement)
                VStack(spacing: 3) {
                    HStack {
                        Image(systemName: "arrow.up.circle")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Enhance on iPhone")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Text("for personalized programs")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 4)
            }
            .padding()
        }
        .onAppear {
            showPulse = true
            startGreetingRotation()
            startConnectivityMonitoring()
            startAutomatedTesting()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func startGreetingRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                greetingIndex = (greetingIndex + 1) % greetings.count
                currentGreeting = greetings[greetingIndex]
            }
        }
    }
    
    // MARK: - Automated Testing & Connectivity
    
    private func startConnectivityMonitoring() {
        print("🔄 AnonymousWatchView: Starting connectivity monitoring")
        
        // Monitor watch connectivity status
        onboardingCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkConnectivityStatus()
        }
        
        // Initial status check
        checkConnectivityStatus()
    }
    
    private func checkConnectivityStatus() {
        // Check if onboarding is complete on iPhone
        // TODO: Re-enable when WatchAppStateManager is available
        if UserDefaults.standard.bool(forKey: "onboardingComplete") {
            updateConnectivityStatus(.ready)
            stopOnboardingCheck()
            return
        }
        
        // Check WatchConnectivity status
        // TODO: Re-enable when LiveWatchConnectivityHandler is available
        if WCSession.default.isReachable {
            if connectivityStatus == .waiting {
                updateConnectivityStatus(.connecting)
                
                // Simulate sync process
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.updateConnectivityStatus(.syncing)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.checkForOnboardingData()
                    }
                }
            }
        } else {
            if connectivityStatus != .waiting && connectivityStatus != .failed {
                updateConnectivityStatus(.waiting)
            }
        }
    }
    
    private func checkForOnboardingData() {
        // Check if we have received onboarding data
        let hasUserName = UserDefaults.standard.string(forKey: "userName") != nil
        let hasUserLevel = UserDefaults.standard.string(forKey: "userLevel") != nil
        
        if hasUserName && hasUserLevel {
            updateConnectivityStatus(.ready)
            print("✅ AnonymousWatchView: Onboarding data received, transitioning to ready state")
        } else {
            // Continue waiting or retry
            updateConnectivityStatus(.waiting)
        }
    }
    
    private func updateConnectivityStatus(_ newStatus: ConnectivityStatus) {
        withAnimation(.easeInOut(duration: 0.3)) {
            connectivityStatus = newStatus
        }
        
        print("📱 AnonymousWatchView: Connectivity status updated to \(newStatus)")
        
        // Update greeting based on status
        updateGreetingForStatus(newStatus)
    }
    
    private func updateGreetingForStatus(_ status: ConnectivityStatus) {
        let statusGreetings: [String]
        
        switch status {
        case .waiting:
            statusGreetings = ["Waiting for setup...", "Connect your iPhone", "Setup in progress"]
        case .connecting:
            statusGreetings = ["Connecting...", "Almost ready", "Setting up"]
        case .syncing:
            statusGreetings = ["Syncing data...", "Getting your profile", "Loading settings"]
        case .ready:
            statusGreetings = ["Ready to sprint!", "Let's train!", "All set!"]
        case .failed:
            statusGreetings = ["Connection failed", "Try again", "Check iPhone"]
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentGreeting = statusGreetings.randomElement() ?? currentGreeting
        }
    }
    
    private func startAutomatedTesting() {
        // Enable test mode for development
        #if DEBUG
        testModeActive = true
        
        // Automated test sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.runAutomatedTests()
        }
        #endif
    }
    
    private func runAutomatedTests() {
        print("🧪 AnonymousWatchView: Running automated tests")
        
        // Test 1: Connectivity status transitions
        testConnectivityTransitions()
        
        // Test 2: Onboarding data simulation
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.simulateOnboardingCompletion()
        }
        
        // Test 3: UI responsiveness
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            self.testUIResponsiveness()
        }
    }
    
    private func testConnectivityTransitions() {
        print("🔄 Testing connectivity status transitions")
        
        let testSequence: [ConnectivityStatus] = [.connecting, .syncing, .ready, .waiting]
        
        for (index, status) in testSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index + 1) * 1.5) {
                self.updateConnectivityStatus(status)
            }
        }
    }
    
    private func simulateOnboardingCompletion() {
        print("📱 Simulating onboarding completion")
        
        // Simulate receiving onboarding data
        UserDefaults.standard.set("Test User", forKey: "userName")
        UserDefaults.standard.set("Beginner", forKey: "userLevel")
        UserDefaults.standard.set(3, forKey: "trainingFrequency")
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        
        updateConnectivityStatus(.ready)
        
        // Update greeting to reflect completion
        withAnimation(.easeInOut(duration: 0.5)) {
            currentGreeting = "Welcome, Test User!"
        }
    }
    
    private func testUIResponsiveness() {
        print("🎨 Testing UI responsiveness")
        
        // Test pulse animation
        withAnimation(.easeInOut(duration: 0.5)) {
            showPulse.toggle()
        }
        
        // Test greeting changes
        let testGreetings = ["UI Test 1", "UI Test 2", "UI Test 3"]
        for (index, greeting) in testGreetings.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentGreeting = greeting
                }
            }
        }
        
        // Reset to normal after tests
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.currentGreeting = "Tests complete!"
            self.testModeActive = false
        }
    }
    
    private func handlePrimaryAction() {
        switch connectivityStatus {
        case .waiting, .connecting, .syncing:
            // Show connection status or retry
            print("⏳ Waiting for iPhone connection...")
            
        case .ready:
            // Start training session
            print("🏃‍♂️ Starting training session")
            // Navigate to training view or start workout
            
        case .failed:
            // Retry connection
            print("🔄 Retrying connection...")
            updateConnectivityStatus(.waiting)
            startConnectivityMonitoring()
        }
    }
    
    private func stopOnboardingCheck() {
        onboardingCheckTimer?.invalidate()
        onboardingCheckTimer = nil
    }
    
    private func stopMonitoring() {
        onboardingCheckTimer?.invalidate()
        onboardingCheckTimer = nil
    }
}

// MARK: - Alternative: Identity-Based Anonymous View

struct IdentityAnonymousView: View {
    @State private var currentIdentity = "Champion"
    @State private var identityIndex = 0
    
    private let identities = [
        "Champion",
        "Sprinter", 
        "Athlete",
        "Runner",
        "Speedster"
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.2, green: 0.1, blue: 0.3), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Large 40 branding
                Text("40")
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                // Rotating anonymous identity
                Text("Hello, \(currentIdentity)")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .animation(.easeInOut(duration: 0.5), value: currentIdentity)
                
                Text("Universal Training")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                
                Spacer().frame(height: 10)
                
                // Immediate value proposition
                VStack(spacing: 8) {
                    Button(action: {}) {
                        Text("Start Sprint Training")
                            .font(.subheadline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    
                    Text("No setup required")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                
                Spacer().frame(height: 8)
                
                // Enhancement offer
                VStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Want personalized training?")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    
                    Text("Set up your profile on iPhone")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .onAppear {
            startIdentityRotation()
        }
    }
    
    private func startIdentityRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                identityIndex = (identityIndex + 1) % identities.count
                currentIdentity = identities[identityIndex]
            }
        }
    }
}

#Preview("Anonymous Action-Focused") {
    AnonymousWatchView()
}

#Preview("Anonymous Identity-Based") {
    IdentityAnonymousView()
}
