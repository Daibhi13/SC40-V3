import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let profileDataUpdated = Notification.Name("profileDataUpdated")
}

struct ContentView: View {
    var body: some View {
        WatchMainView()
    }
}

struct WatchMainView: View {
    var body: some View {
        SessionCardsView()
    }
}


struct SessionCardsView: View {
    @State private var selectedCard = 0
    @State private var showSprintTimerPro = false
    @State private var showWorkout = false
    @State private var selectedSession: TrainingSession?
    @State private var showSyncTesting = false
    @State private var showTestingDashboard = false
    
    // Connect to live session data
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var connectivityHandler = LiveWatchConnectivityHandler.shared
    
    var body: some View {
        NavigationView {
            mainTabView
                .background(backgroundGradient)
                .navigationTitle("")
                .navigationBarHidden(false)
                .toolbar {
                    toolbarContent
                }
        }
        .modifier(SheetModifiers(showSprintTimerPro: $showSprintTimerPro, showWorkout: $showWorkout, showSyncTesting: $showSyncTesting, showTestingDashboard: $showTestingDashboard, selectedSession: $selectedSession, sessionManager: sessionManager))
        .onAppear {
            // WATCH APP STARTUP: Ensure profile data is current
            print("🔄 Watch: SessionCardsView appeared - checking for profile updates")
            
            // Request fresh session data from iPhone
            sessionManager.requestTrainingSessionsFromPhone()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("trainingSessionsUpdated"))) { _ in
            // REAL-TIME SESSION UPDATES: Refresh UI when sessions arrive from iPhone
            print("⚡ Watch: Training sessions updated - UI will refresh automatically via @StateObject")
            // No manual refresh needed - @StateObject sessionManager will trigger UI update
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("profileDataUpdated"))) { _ in
            // REAL-TIME PROFILE UPDATES: Refresh sessions when profile changes
            print("⚡ Watch: Profile updated - requesting fresh sessions to match new profile")
            sessionManager.requestTrainingSessionsFromPhone()
        }
        .onReceive(sessionManager.$trainingSessions) { sessions in
            // SESSION COUNT MONITORING: Log session changes for debugging
            print("📊 Watch: Session count updated - now showing \(sessions.count) sessions")
            
            // Validate session data matches phone expectations
            if !sessions.isEmpty {
                let firstSession = sessions[0]
                print("📋 Watch: First session - W\(firstSession.week)D\(firstSession.day): \(firstSession.type)")
                print("📋 Watch: Session focus: \(firstSession.focus)")
                print("📋 Watch: Sprint data: \(firstSession.sprints.count) sprint sets")
            }
        }
    }
    
    // MARK: - Computed Properties
    private var mainTabView: some View {
        TabView(selection: $selectedCard) {
            // Card -1: Sprint Timer Pro (LEFT of Profile)
            SprintTimerProCard()
                .tag(-1)
                .onTapGesture {
                    showSprintTimerPro = true
                }
            
            // Card 0: User Profile - CENTRAL ENTRY POINT
            UserProfileCard()
                .tag(0)
                .onTapGesture {
                    // Navigate to profile settings or onboarding
                }
            
            // Dynamic Training Sessions from Live Data
            ForEach(Array(sessionManager.trainingSessions.prefix(2).enumerated()), id: \.element.id) { index, session in
                LiveSessionCard(session: session)
                    .tag(index + 1)
                    .onTapGesture {
                        print("🏃‍♂️ Session tapped: \(session.type) - W\(session.week)D\(session.day)")
                        print("🏃‍♂️ Sprint sets: \(session.sprints.count)")
                        
                        // Ensure only workout sheet is shown
                        showSprintTimerPro = false
                        
                        // Capture session immediately and show workout
                        selectedSession = session
                        showWorkout = true
                        print("✅ Selected session set and presenting: \(session.id)")
                        print("🔍 Debug: showWorkout=\(showWorkout), showSprintTimerPro=\(showSprintTimerPro)")
                    }
            }
        }
        #if os(watchOS)
        .tabViewStyle(.page)
        #else
        .tabViewStyle(PageTabViewStyle())
        #endif
    }
    
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),  // Dark blue top
                    Color(red: 0.2, green: 0.1, blue: 0.3),  // Purple middle
                    Color(red: 0.1, green: 0.05, blue: 0.2)  // Dark purple bottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass effect overlay like phone app
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear,
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .ignoresSafeArea()
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                showTestingDashboard = true
            }) {
                Image(systemName: "testtube.2")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(action: {
                showSyncTesting = true
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }
}

// MARK: - Sheet Modifiers
struct SheetModifiers: ViewModifier {
    @Binding var showSprintTimerPro: Bool
    @Binding var showWorkout: Bool
    @Binding var showSyncTesting: Bool
    @Binding var showTestingDashboard: Bool
    @Binding var selectedSession: TrainingSession?
    let sessionManager: WatchSessionManager
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showSprintTimerPro) {
                SprintTimerProWatchView()
            }
            .sheet(isPresented: $showWorkout) {
                Group {
                    if let session = selectedSession {
                        MainProgramWorkoutWatchView(session: session)
                            .onAppear {
                                print("🏃‍♂️ Presenting workout for: \(session.type)")
                            }
                            .onDisappear {
                                // Clear selection when sheet is dismissed
                                selectedSession = nil
                            }
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                .scaleEffect(1.5)
                            
                            Text("Loading Workout...")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            Text("Preparing your training session...")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            
                            Button("Cancel") {
                                showWorkout = false
                                selectedSession = nil
                            }
                            .foregroundColor(.yellow)
                            .padding(.top)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .onAppear {
                            print("⚠️ No session selected - showing loading state")
                            print("🔍 Debug: selectedSession is nil when sheet appears")
                            print("🔍 Debug: showWorkout = \(showWorkout)")
                        }
                    }
                }
                .onAppear {
                    print("🔍 Sheet appeared - selectedSession: \(selectedSession?.id.uuidString ?? "nil")")
                }
            }
            .sheet(isPresented: $showSyncTesting) {
                SyncTestingView()
            }
            .sheet(isPresented: $showTestingDashboard) {
                TestingDashboardView()
                    .onAppear {
                        // WATCH APP STARTUP: Ensure profile data is current
                        print("🔄 Watch: SessionCardsView appeared - checking for profile updates")
                        
                        // Request fresh session data from iPhone
                        sessionManager.requestTrainingSessionsFromPhone()
                    }
            }
    }
}

// Card 1: Sprint Timer Pro (PREMIUM)
struct SprintTimerProCard: View {
    var body: some View {
        VStack(spacing: 8) {
            // Premium crown icon
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.yellow)
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                Spacer()
            }
            
            Spacer()
            
            // Main content
            VStack(spacing: 6) {
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow, radius: 8)
                
                Text("SPRINT TIMER PRO")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Custom Sprint Workouts")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Feature badges
            HStack(spacing: 6) {
                FeatureBadge(text: "GPS")
                FeatureBadge(text: "40YD")
                FeatureBadge(text: "PRO")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.15),
                            Color.orange.opacity(0.1),
                            Color.red.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow.opacity(0.6), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 4)
    }
}

// Card 0: User Profile - ENTRY POINT
struct UserProfileCard: View {
    @State private var userName: String = "User"
    @State private var personalBest: Double = 0.0
    @State private var currentWeek: Int = 1
    // Note: Level and frequency no longer displayed on welcome card
    
    var body: some View {
        VStack(spacing: 8) {
            // Welcome header
            HStack {
                Text("Welcome Back")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.cyan)
                Spacer()
                Image(systemName: "figure.run")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
            }
            
            Spacer()
            
            // Main profile content - No level/day info shown
            VStack(spacing: 8) {
                Text(userName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Ready to Train")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.cyan)
                    .lineLimit(1)
                
                Text("Program Synced")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Enhanced stats with progress
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    StatBadge(label: "Personal Best", value: personalBest > 0 ? String(format: "%.1fs", personalBest) : "N/A", color: .yellow)
                    StatBadge(label: "Current Week", value: "\(currentWeek)", color: .cyan)
                }
                
                HStack(spacing: 4) {
                    Text("← Timer Pro")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("•")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Sessions →")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.15),
                            Color.blue.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 4)
        .onAppear {
            // DYNAMIC PROFILE REFRESH: Load current profile from UserDefaults
            refreshProfileData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            // REAL-TIME UPDATES: Refresh profile when UserDefaults change (from iPhone sync)
            DispatchQueue.main.async {
                refreshProfileData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDataUpdated)) { _ in
            // IMMEDIATE UPDATES: Refresh profile when specifically notified by connectivity handler
            DispatchQueue.main.async {
                refreshProfileData()
                print("⚡ Watch: Profile UI updated immediately from iPhone sync")
            }
        }
    }
    
    private func refreshProfileData() {
        // Read from UserDefaults (synced from iPhone onboarding)
        // Only load data that's actually displayed on welcome card
        userName = UserDefaults.standard.string(forKey: "SC40_UserName") ?? 
                  UserDefaults.standard.string(forKey: "user_name") ?? "SC40 Athlete"
        personalBest = UserDefaults.standard.double(forKey: "SC40_TargetTime") > 0 ?
                      UserDefaults.standard.double(forKey: "SC40_TargetTime") :
                      UserDefaults.standard.double(forKey: "personalBest40yd")
        currentWeek = UserDefaults.standard.integer(forKey: "SC40_CurrentWeek") > 0 ?
                     UserDefaults.standard.integer(forKey: "SC40_CurrentWeek") : 1
        
        print("🔄 Watch: Profile refreshed - Name: \(userName), PB: \(personalBest)s, Week: \(currentWeek)")
        print("📝 Note: Level and frequency not displayed on welcome card")
    }
}

// MARK: - Live Session Card (Dynamic Data)
struct LiveSessionCard: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with live session data
            HStack {
                Text("W\(session.week)/D\(session.day)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .cornerRadius(6)
                
                Spacer()
                
                Text("MAX")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Main content with live session data - SAFE PROPERTIES
            VStack(spacing: 4) {
                Text(session.safeType)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                
                Text(session.safeFocus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Bottom info - LIVE SESSION DATA
            Text(formatSessionSprints(session.sprints))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.25).opacity(0.9),
                            Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 4)
    }
    
    // Format sprint information dynamically - SAFE VERSION
    private func formatSessionSprints(_ sprints: [SprintSet]) -> String {
        guard !sprints.isEmpty else { return "No Sprints" }
        
        // Safe distance extraction
        let distances = sprints.compactMap { sprint in
            sprint.distanceYards > 0 ? sprint.distanceYards : nil
        }
        
        guard !distances.isEmpty else { return "Invalid Sprints" }
        
        // Check if this is the pyramid workout (10, 20, 30, 40, 30, 20, 10)
        let sortedDistances = distances.sorted()
        let pyramidPattern = [10, 20, 30, 40, 30, 20, 10].sorted()
        
        if sortedDistances == pyramidPattern {
            // Display pyramid pattern
            let pyramidDistances = sprints.compactMap { sprint in
                sprint.distanceYards > 0 ? sprint.distanceYards : nil
            }
            return pyramidDistances.map { "\($0)" }.joined(separator: "-") + "yd"
        }
        
        // For other workouts, show total sets and distance range
        if sprints.count > 3 {
            let minDistance = distances.min() ?? 0
            let maxDistance = distances.max() ?? 0
            return "\(sprints.count) sets: \(minDistance)-\(maxDistance)yd"
        }
        
        // For simple workouts, show traditional format
        let validSprints = sprints.filter { $0.distanceYards > 0 && $0.reps > 0 }
        guard let mainSprint = validSprints.max(by: { first, second in
            if first.distanceYards != second.distanceYards {
                return first.distanceYards < second.distanceYards
            }
            return first.reps < second.reps
        }) else {
            return "Mixed Sprints"
        }
        
        return "\(mainSprint.reps)x\(mainSprint.distanceYards)yd"
    }
}

// MARK: - Legacy Session Card (Static Data)
struct SessionCard: View {
    let week: Int
    let day: Int
    let type: String
    let focus: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with better spacing
            HStack {
                Text("W\(week)/D\(day)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow)
                    .cornerRadius(6)
                
                Spacer()
                
                Text("MAX")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Main content - better proportioned
            VStack(spacing: 4) {
                Text(type)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                
                Text(focus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Bottom info - HARDCODED (Legacy)
            Text("5x40yd")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.25).opacity(0.9),
                            Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 4)
    }
}

// Helper components
struct FeatureBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.yellow)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.yellow.opacity(0.2))
            .cornerRadius(4)
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

#if DEBUG
#Preview("ContentView") {
    ContentView()
        .preferredColorScheme(.dark)
}
#endif
