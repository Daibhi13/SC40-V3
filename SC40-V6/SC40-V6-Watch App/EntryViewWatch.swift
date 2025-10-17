import SwiftUI

// MARK: - Local Type Definitions (required for file access)
struct WatchSprintSet: Codable, Sendable {
    let distanceYards: Int
    let reps: Int
    let intensity: String

    init(distanceYards: Int, reps: Int, intensity: String) {
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
}

struct WatchTrainingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let week: Int
    let day: Int
    let type: String
    let focus: String
    let sprints: [WatchSprintSet]
    let accessoryWork: [String]
    let notes: String?
    let isCompleted: Bool

    init(id: UUID = UUID(), week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = isCompleted
    }

    init(week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = false
    }
}

class WatchSessionManager: ObservableObject {
    static let shared = WatchSessionManager()
    @Published var trainingSessions: [WatchTrainingSession] = []
    @Published var isPhoneConnected = false
    @Published var isPhoneReachable = false

    func requestWatchTrainingSessions() {
        // Stub implementation
    }

    func generateFallbackSessions() {
        // Stub implementation
    }
}

struct iPhoneSetupInstructionsView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack {
            Text("iPhone Setup Instructions")
            Button("Complete") {
                onComplete()
            }
        }
    }
}

struct OnboardingRequiredView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack {
            Text("Onboarding Required")
            Button("Complete") {
                onComplete()
            }
        }
    }
}

struct DaySessionCardsWatchView: View {
    var body: some View {
        Text("Day Session Cards")
    }
}

struct WatchStarterProView: View {
    var body: some View {
        Text("Watch Starter Pro")
    }
}

struct EntryViewWatch: View {
    @State private var showSplash = false  // ZERO BUFFERING: Start with no splash
    @State private var showStarterPro = false
    @ObservedObject private var watchManager = WatchSessionManager.shared
    @State private var forceRefresh = false
    @State private var emergencyBypass = true  // FORCE BYPASS: Always show sessions
    @State private var showIPhoneInstructions = false
    @State private var syncCheckCompleted = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // EMERGENCY ZERO BUFFERING: Always ensure sessions exist
                Color.clear
                    .onAppear {
                        if watchManager.trainingSessions.isEmpty {
                            print("🆘 CREATING EMERGENCY SESSION - ZERO BUFFERING ENFORCED")
                            
                            let emergencySession = WatchTrainingSession(
                                week: 1,
                                day: 1,
                                type: "Sprint Training",
                                focus: "Ready to Train",
                                sprints: [
                                    WatchSprintSet(distanceYards: 20, reps: 3, intensity: "80%"),
                                    WatchSprintSet(distanceYards: 30, reps: 2, intensity: "85%")
                                ],
                                accessoryWork: [],
                                notes: "Emergency session - ready to train immediately"
                            )
                            
                            watchManager.trainingSessions = [emergencySession]
                            print("✅ EMERGENCY SESSION CREATED - ZERO BUFFERING ACHIEVED")
                        }
                    }
                
                if showSplash {
                    SimpleSplashView()
                        .onAppear {
                            // EMERGENCY ZERO BUFFERING: Force immediate session creation
                            print("🆘 EMERGENCY ZERO BUFFERING: Creating session immediately")
                            
                            let emergencySession = WatchTrainingSession(
                                week: 1,
                                day: 1,
                                type: "Sprint Training",
                                focus: "Ready to Train",
                                sprints: [
                                    WatchSprintSet(distanceYards: 20, reps: 3, intensity: "80%"),
                                    WatchSprintSet(distanceYards: 30, reps: 2, intensity: "85%")
                                ],
                                accessoryWork: [],
                                notes: "Emergency session - ready to train immediately"
                            )
                            
                            // FORCE SESSION CREATION - NO LOADING ALLOWED
                            watchManager.trainingSessions = [emergencySession]
                            print("🚀 EMERGENCY SESSION CREATED - SKIPPING ALL LOADING")
                            
                            // IMMEDIATE SPLASH REMOVAL - NO DELAYS
                            showSplash = false
                            print("✅ ZERO BUFFERING ENFORCED - NO LOADING SCREEN")
                            
                            // INSTANT EXIT: If sessions load during splash, exit immediately
                            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                Task { @MainActor in
                                    if !watchManager.trainingSessions.isEmpty && showSplash {
                                        print("🚀 SEAMLESS: Sessions loaded, instant transition")
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showSplash = false
                                        }
                                    }
                                }
                            }
                            
                            // Cleanup timer after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                timer.invalidate()
                            }
                            
                            // EMERGENCY BYPASS: If haptic was felt but still stuck, force exit after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if showSplash {
                                    print("🚨 EMERGENCY BYPASS: Haptic felt but still stuck, forcing exit")
                                    emergencyBypass = true
                                    showSplash = false
                                }
                            }
                        }
                } else if showIPhoneInstructions {
                    // Show iPhone setup instructions when sync fails
                    iPhoneSetupInstructionsView {
                        showIPhoneInstructions = false
                        syncCheckCompleted = true
                    }
                } else {
                    ZStack {
                        // DEBUG: Log current state
                        let _ = print("🔍 VIEW STATE: needsOnboarding=\(needsOnboarding), sessions=\(watchManager.trainingSessions.count), connected=\(watchManager.isPhoneConnected), reachable=\(watchManager.isPhoneReachable)")
                        
                        if needsOnboarding && !emergencyBypass {
                            let _ = print("📱 SHOWING: OnboardingRequiredView")
                            OnboardingRequiredView { }
                        } else {
                            let _ = print("🏃‍♂️ SHOWING: Session Cards or Debug View (emergencyBypass: \(emergencyBypass))")
                            // NUCLEAR: ALWAYS show sessions if we have them OR if emergency bypass is active
                            if !watchManager.trainingSessions.isEmpty || emergencyBypass {
                                let _ = print("✅ DISPLAYING: DaySessionCardsWatchView with \(watchManager.trainingSessions.count) sessions (bypass: \(emergencyBypass))")
                                DaySessionCardsWatchView()
                                    .gesture(
                                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                            .onEnded { value in
                                                if value.translation.width > 20 {
                                                    showStarterPro = true
                                                }
                                            }
                                    )
                            } else {
                                let _ = print("🚨 FALLBACK: Showing debug view - no sessions available")
                                // Debug view to show what's happening
                                VStack(spacing: 8) {
                                    Text("Loading Sessions...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Sessions: \(watchManager.trainingSessions.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("Connected: \(watchManager.isPhoneConnected ? "✅" : "❌")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("Reachable: \(watchManager.isPhoneReachable ? "✅" : "❌")")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Button("Force Load Sessions") {
                                        print("🚨 FORCE LOAD: User manually forcing session load")
                                        emergencyBypass = true
                                    }
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .onChange(of: watchManager.trainingSessions.count) { oldCount, newCount in
                print("🔄 SESSIONS CHANGED: \(String(oldCount)) → \(String(newCount)) sessions now available")
                if newCount > 0 && showSplash {
                    print("🚀 FORCE EXIT: Sessions loaded, exiting splash immediately")
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSplash = false
                    }
                    // Check if sessions are from iPhone or fallback
                    checkSyncSuccess()
                }
                // Force view refresh
                forceRefresh.toggle()
            }
            .id(forceRefresh) // Force view refresh when sessions change
            .onAppear {
                // AGGRESSIVE: Force immediate session availability
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Force session request if we have no sessions
                    if watchManager.trainingSessions.isEmpty {
                        print("🚨 AGGRESSIVE SYNC: No sessions, forcing immediate request")
                        watchManager.requestWatchTrainingSessions()
                        
                        // If still no sessions after 2 seconds, force fallback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if watchManager.trainingSessions.isEmpty {
                                print("🚨 EMERGENCY FALLBACK: Generating sessions immediately")
                                watchManager.generateFallbackSessions()
                            }
                        }
                    }
                }
                
                // Original sync check timer (backup)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if !syncCheckCompleted {
                        checkSyncSuccess()
                    }
                }
            }
            .navigationDestination(isPresented: $showStarterPro) {
                WatchStarterProView()
            }
        }
    }
    
    /// Check if iPhone sync was successful or if we need to show instructions
    func checkSyncSuccess() {
        guard !syncCheckCompleted else { return }
        
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        let hasSession = !watchManager.trainingSessions.isEmpty
        
        print("🔍 SYNC CHECK: Source=\(sessionSource), HasSessions=\(hasSession), Connected=\(watchManager.isPhoneConnected)")
        
        if hasSession && sessionSource == "iPhone" {
            // Perfect! iPhone sync worked
            print("✅ SYNC SUCCESS: iPhone sessions received, skipping instructions")
            syncCheckCompleted = true
        } else if hasSession && sessionSource == "Fallback" {
            // Using fallback sessions - show instructions to get iPhone sync
            print("⚠️ SYNC PARTIAL: Using fallback sessions, showing iPhone instructions")
            DispatchQueue.main.async {
                self.showIPhoneInstructions = true
                self.forceRefresh.toggle() // Force UI refresh
                print("📱 FORCE UI UPDATE: showIPhoneInstructions = \(self.showIPhoneInstructions)")
            }
        } else if !hasSession {
            // No sessions at all - show instructions
            print("❌ SYNC FAILED: No sessions available, showing iPhone instructions")
            DispatchQueue.main.async {
                self.showIPhoneInstructions = true
                self.forceRefresh.toggle()
            }
        } else {
            // Unknown state - default to showing instructions
            print("❓ SYNC UNKNOWN: Unknown state, showing iPhone instructions")
            DispatchQueue.main.async {
                self.showIPhoneInstructions = true
                self.forceRefresh.toggle()
            }
        }
    }
    
    var needsOnboarding: Bool {
        // ZERO BUFFERING: NEVER show onboarding - always show sessions
        print("🚀 ZERO BUFFERING: Skipping all onboarding - direct to sessions")
        return false
    }
}

struct SimpleSplashView: View {
    @State private var splashScale: CGFloat = 0.8
    @State private var splashOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .scaleEffect(splashScale)
                    .opacity(splashOpacity)
                
                Text("SPRINT COACH 40")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .opacity(splashOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                splashScale = 1.0
                splashOpacity = 1.0
            }
        }
    }
}

// MARK: - Stub Views

#if DEBUG
#Preview("1. Watch Entry - Main Flow") {
    EntryViewWatch()
        .preferredColorScheme(.dark)
}

#Preview("2. Watch Entry - Session Cards") {
    EntryViewWatch()
        .preferredColorScheme(.dark)
}

#Preview("3. Simple Splash Screen") {
    SimpleSplashView()
        .preferredColorScheme(.dark)
}

#Preview("4. Watch Entry States") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Watch Entry Flow")
            .font(.adaptiveTitle)
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
        
        VStack(alignment: .leading, spacing: 4) {
            Text("• Zero Buffering System")
                .font(.adaptiveBody)
            Text("• Emergency Session Creation")
                .font(.adaptiveBody)
            Text("• Seamless Transition")
                .font(.adaptiveBody)
            Text("• iPhone Setup Detection")
                .font(.adaptiveBody)
        }
        .foregroundColor(.secondary)
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("5. Lightning Bolt Animation") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Image(systemName: "bolt.fill")
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
        
        Text("SPRINT COACH 40")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("6. Watch Connection Status") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Connection Status")
            .font(.adaptiveTitle)
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
        
        HStack(spacing: WatchAdaptiveSizing.smallPadding) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("Connected")
                .font(.adaptiveBody)
                .foregroundColor(.green)
        }
        
        Text("Sessions: Ready")
            .font(.adaptiveCaption)
            .foregroundColor(.secondary)
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif
