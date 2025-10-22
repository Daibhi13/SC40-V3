import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Imports for existing types
// Using existing types from the project:
// - UserProfile from Models/UserProfile.swift
// - UserProfileViewModel from Models/UserProfileViewModel.swift  
// - TrainingSession from Models/SprintSetAndTrainingSession.swift
// - SprintSet from Models/SprintSetAndTrainingSession.swift

// MARK: - TrainingView
// - Uses TrainingSession from Models/SprintSetAndTrainingSession.swift
// - Uses SprintSet from Models/SprintSetAndTrainingSession.swift

struct TrainingView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showMenu = false
    @State private var selectedMenu: MenuSelection = .main
    @State private var showPaywall = false
    @State private var showSixPartWorkout = false
    @State private var selectedSession: TrainingSession?
    @State private var showMainProgramWorkout = false
    @State private var showSprintTimerPro = false
    @State private var selectedSessionForWorkout: TrainingSession?
    @State private var dynamicSessions: [TrainingSession] = []

    var body: some View {
        let profile = userProfileVM.profile
        ZStack {
            // WelcomeView-style gradient background with glass effect
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
            
            // Glass effect overlay
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
                .ignoresSafeArea()
            
            NavigationView {
                ZStack {
                    // Ensure background transparency for NavigationView content
                    Color.clear
                        .ignoresSafeArea()
                        .background(.clear)
                    
                    switch selectedMenu {
                    case .main:
                        AnyView(mainDashboard(profile: profile, userProfileVM: userProfileVM))
                    case .history:
                        AnyView(HistoryView())
                    case .leaderboard:
                        AnyView(EnhancedLeaderboardView(currentUser: profile))
                    case .smartHub:
                        AnyView(Enhanced40YardSmartView())
                    case .settings:
                        AnyView(SettingsView())
                    case .helpInfo:
                        AnyView(HelpInfoView())
                    case .news:
                        AnyView(SprintNewsView())
                    case .shareWithTeammates:
                        AnyView(ShareWithTeammatesView())
                    case .sharePerformance:
                        AnyView(SharePerformanceView(userProfileVM: userProfileVM))
                    case .proFeatures:
                        AnyView(ProFeaturesView())
                    case .performanceTrends:
                        AnyView(AdvancedAnalyticsView(userProfileVM: userProfileVM))
                    }
                }
                .navigationTitle("Sprint Coach 40")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(false)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) { 
                                showMenu.toggle() 
                            }
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "line.horizontal.3")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .accessibilityLabel("Open menu")
                        .accessibilityHint("Opens the navigation menu")
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Image(systemName: "applewatch")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.clear, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Configure NavigationView to use transparent background - TrainingView specific
                    #if os(iOS)
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithTransparentBackground()
                    appearance.backgroundColor = UIColor.clear
                    appearance.shadowColor = UIColor.clear
                    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                    
                    // Apply only to this navigation controller instance
                    if let navigationController = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
                        navigationController.navigationBar.standardAppearance = appearance
                        navigationController.navigationBar.compactAppearance = appearance
                        navigationController.navigationBar.scrollEdgeAppearance = appearance
                        navigationController.navigationBar.tintColor = UIColor.white
                    }
                    #endif
                }
            }
            
            // Hamburger Menu Overlay - ensure it appears on top
            if showMenu {
                HamburgerSideMenu(showMenu: $showMenu, onSelect: { (selection: MenuSelection) in
                    // Direct assignment since both use the same MenuSelection type
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedMenu = selection
                    }
                })
                .zIndex(1000) // Ensure menu appears above all content
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .sheet(item: $selectedSession) { session in
            NavigationView {
                Text("6-Part Workout for W\(session.week)/D\(session.day)")
                    .foregroundColor(.white)
                    .navigationTitle("Workout")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedSession = nil
                            }
                            .foregroundColor(.white)
                        }
                    }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showMainProgramWorkout) {
            NavigationView {
                MainProgramWorkoutView(sessionData: nil)
                    .navigationTitle("Sprint Training")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showMainProgramWorkout = false
                            }
                            .foregroundColor(.white)
                        }
                    }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showSprintTimerPro) {
            SprintTimerProView()
        }
    }
}

// MARK: - TrainingView Extensions

extension TrainingView {
    static func stableSessionID(week: Int, day: Int) -> UUID {
        // Create a deterministic UUID string based on week and day, padded to fixed length
        // Format: "0001-0002-000000000000"
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        if let uuid = UUID(uuidString: baseString) {
            return uuid
        }
        // fallback if not valid UUID string
        return UUID()
    }
    
    // Cache for user sessions to prevent recreation on view updates
    private static var sessionCache: [String: TrainingSession] = [:]
    
    // Clear the cache when user's program changes (call this when new sessions are generated)
    static func clearSessionCache() {
        sessionCache.removeAll()
    }
    
    static func cachedUserSessions(from sessions: [TrainingSession]) -> [TrainingSession] {
        var cachedSessions: [TrainingSession] = []
        
        for session in sessions {
            let cacheKey = "W\(session.week)D\(session.day)"
            
            // Check if we already have this session cached
            if let cachedSession = sessionCache[cacheKey] {
                cachedSessions.append(cachedSession)
            } else {
                // Create a new session with stable ID and cache it
                let stableSession = TrainingSession(
                    id: stableSessionID(week: session.week, day: session.day),
                    week: session.week,
                    day: session.day,
                    type: session.type,
                    focus: session.focus,
                    sprints: session.sprints,
                    accessoryWork: session.accessoryWork,
                    notes: session.notes
                )
                sessionCache[cacheKey] = stableSession
                cachedSessions.append(stableSession)
            }
        }
        
        return cachedSessions
    }

    // Dynamic sessions generated based on user profile and SessionLibrary
    private func generateDynamicSessions() -> [TrainingSession] {
        let userLevel = userProfileVM.profile.level.lowercased()
        let currentWeek = userProfileVM.profile.currentWeek
        let frequency = userProfileVM.profile.frequency
        
        print("🏃‍♂️ TrainingView: Generating sessions for \(userProfileVM.profile.level) level, \(frequency) days/week across 12 weeks")
        
        var sessions: [TrainingSession] = []
        
        // Generate sessions for entire 12-week program (up to 85 sessions)
        for week in 1...12 {
            for day in 1...frequency {
                let session = generateSessionForDay(
                    week: week,
                    day: day,
                    level: userLevel
                )
                sessions.append(session)
                
                // Safety limit to prevent excessive sessions
                if sessions.count >= 85 {
                    break
                }
            }
            if sessions.count >= 85 {
                break
            }
        }
        
        print("🏃‍♂️ TrainingView: Generated \(sessions.count) total sessions for carousel")
        return sessions
    }
    
    private func generateSessionForDay(week: Int, day: Int, level: String) -> TrainingSession {
        // Session patterns based on level
        let sessionData = getSessionDataForLevel(level: level, week: week, day: day)
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: week, day: day),
            week: week,
            day: day,
            type: sessionData.type,
            focus: sessionData.focus,
            sprints: sessionData.sprints,
            accessoryWork: sessionData.accessoryWork,
            notes: sessionData.notes
        )
    }
    
    private func getSessionDataForLevel(level: String, week: Int, day: Int) -> (type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String) {
        switch level {
        case "beginner":
            return generateBeginnerSession(week: week, day: day)
        case "intermediate":
            return generateIntermediateSession(week: week, day: day)
        case "advanced":
            return generateAdvancedSession(week: week, day: day)
        case "elite":
            return generateEliteSession(week: week, day: day)
        default:
            return generateBeginnerSession(week: week, day: day)
        }
    }
    
    private func generateBeginnerSession(week: Int, day: Int) -> (type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String) {
        let dayPattern = (day - 1) % 3
        switch dayPattern {
        case 0: // Day 1 - Acceleration
            return (
                type: "Acceleration",
                focus: "First Step",
                sprints: [SprintSet(distanceYards: 20, reps: 6, intensity: "moderate")],
                accessoryWork: ["Dynamic warm-up", "A-Skip drill", "Wall drives", "Cool-down"],
                notes: "Focus on explosive first step and low body position"
            )
        case 1: // Day 2 - Speed Development
            return (
                type: "Speed",
                focus: "Drive Phase",
                sprints: [SprintSet(distanceYards: 30, reps: 4, intensity: "high")],
                accessoryWork: ["Dynamic warm-up", "High knees", "Butt kicks", "Cool-down"],
                notes: "Maintain forward lean and powerful arm drive"
            )
        default: // Day 3 - Recovery/Technique
            return (
                type: "Technique",
                focus: "Form Work",
                sprints: [SprintSet(distanceYards: 25, reps: 3, intensity: "moderate")],
                accessoryWork: ["Light warm-up", "Technique drills", "Flexibility", "Recovery"],
                notes: "Focus on proper running form and technique"
            )
        }
    }
    
    private func generateIntermediateSession(week: Int, day: Int) -> (type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String) {
        let dayPattern = (day - 1) % 3
        switch dayPattern {
        case 0: // Day 1 - Acceleration
            return (
                type: "Acceleration",
                focus: "Drive Phase",
                sprints: [SprintSet(distanceYards: 25, reps: 5, intensity: "high")],
                accessoryWork: ["Dynamic warm-up", "Block starts", "Drive drills", "Strength", "Cool-down"],
                notes: "Perfect your acceleration technique"
            )
        case 1: // Day 2 - Max Velocity
            return (
                type: "Speed",
                focus: "Max Velocity",
                sprints: [SprintSet(distanceYards: 40, reps: 4, intensity: "max")],
                accessoryWork: ["Extended warm-up", "Flying starts", "Wicket runs", "Cool-down"],
                notes: "Build to maximum velocity"
            )
        default: // Day 3 - Speed Endurance
            return (
                type: "Speed Endurance",
                focus: "Conditioning",
                sprints: [SprintSet(distanceYards: 50, reps: 3, intensity: "high")],
                accessoryWork: ["Warm-up", "Tempo runs", "Recovery work", "Stretching"],
                notes: "Maintain speed over longer distances"
            )
        }
    }
    
    private func generateAdvancedSession(week: Int, day: Int) -> (type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String) {
        let dayPattern = (day - 1) % 4
        switch dayPattern {
        case 0: // Day 1 - Power/Acceleration
            return (
                type: "Power",
                focus: "Explosive Starts",
                sprints: [SprintSet(distanceYards: 30, reps: 6, intensity: "max")],
                accessoryWork: ["Dynamic warm-up", "Block starts", "Power training", "Recovery"],
                notes: "Maximum explosive power development"
            )
        case 1: // Day 2 - Max Velocity
            return (
                type: "Speed",
                focus: "Top Speed",
                sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
                accessoryWork: ["Competition warm-up", "Flying runs", "Speed mechanics", "Cool-down"],
                notes: "Reach and maintain maximum velocity"
            )
        case 2: // Day 3 - Speed Endurance
            return (
                type: "Speed Endurance",
                focus: "Lactate Tolerance",
                sprints: [SprintSet(distanceYards: 60, reps: 4, intensity: "high")],
                accessoryWork: ["Extended warm-up", "Tempo work", "Recovery protocols"],
                notes: "Maintain speed under fatigue"
            )
        default: // Day 4 - Recovery/Technique
            return (
                type: "Active Recovery",
                focus: "Regeneration",
                sprints: [SprintSet(distanceYards: 20, reps: 2, intensity: "easy")],
                accessoryWork: ["Light movement", "Mobility work", "Massage", "Stretching"],
                notes: "Active recovery and regeneration"
            )
        }
    }
    
    private func generateEliteSession(week: Int, day: Int) -> (type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String) {
        let dayPattern = (day - 1) % 5
        switch dayPattern {
        case 0: // Day 1 - Power Development
            return (
                type: "Power",
                focus: "Maximum Power",
                sprints: [SprintSet(distanceYards: 35, reps: 6, intensity: "max")],
                accessoryWork: ["Elite warm-up", "Block work", "Power training", "Recovery protocols"],
                notes: "Elite-level power development"
            )
        case 1: // Day 2 - Speed/Velocity
            return (
                type: "Speed",
                focus: "Peak Velocity",
                sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
                accessoryWork: ["Competition prep", "Flying starts", "Video analysis", "Recovery"],
                notes: "Peak velocity development"
            )
        case 2: // Day 3 - Competition Simulation
            return (
                type: "Competition",
                focus: "Race Preparation",
                sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "race")],
                accessoryWork: ["Race warm-up", "Mental prep", "Competition protocols"],
                notes: "Simulate competition conditions"
            )
        case 3: // Day 4 - Speed Endurance
            return (
                type: "Speed Endurance",
                focus: "Elite Conditioning",
                sprints: [SprintSet(distanceYards: 75, reps: 3, intensity: "high")],
                accessoryWork: ["Extended prep", "Lactate work", "Advanced recovery"],
                notes: "Elite-level speed endurance"
            )
        default: // Day 5 - Recovery
            return (
                type: "Recovery",
                focus: "Elite Recovery",
                sprints: [SprintSet(distanceYards: 25, reps: 2, intensity: "easy")],
                accessoryWork: ["Professional recovery", "Therapy", "Regeneration protocols"],
                notes: "Professional recovery protocols"
            )
        }
    }
}

// MARK: - TrainingView Methods

extension TrainingView {
    // Main dashboard matching the exact screenshot design
    func mainDashboard(profile: UserProfile, userProfileVM: UserProfileViewModel) -> some View {
        let sessionsToShow: [TrainingSession] = generateDynamicSessions()
        
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Welcome Header - Centered to match UI
                VStack(alignment: .center, spacing: 16) {
                    Text("Welcome, David!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text("YOUR PERSONAL BEST")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.2)
                        
                        Text("5.25s")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.9, blue: 0.7),  // Light cream
                                        Color(red: 1.0, green: 0.8, blue: 0.4),  // Golden yellow
                                        Color(red: 0.9, green: 0.7, blue: 0.3)   // Darker gold
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("40-Yard Dash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)

                // 40 Yards Program Section - Exact match
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("40 YARDS PROGRAM")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .tracking(1.2)
                        
                        Text("12-Week Training Program")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    
                    // Training Program Carousel - One card visible with scroll capability
                    VStack(spacing: 16) {
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 20) {
                                    ForEach(sessionsToShow.indices, id: \.self) { index in
                                        let session = sessionsToShow[index]
                                        TrainingSessionCard(session: session)
                                            .frame(width: geometry.size.width - 60) // Full width minus padding for one card
                                            .onTapGesture {
                                                selectedSessionForWorkout = session
                                                showMainProgramWorkout = true
                                                #if os(iOS)
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                #endif
                                            }
                                    }
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                        .frame(height: 200) // Fixed height for carousel
                        
                        // Page indicator dots - showing first 10 sessions
                        HStack(spacing: 8) {
                            ForEach(0..<min(10, sessionsToShow.count), id: \.self) { index in
                                Circle()
                                    .fill(index == 0 ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)

                // Start Sprint Training Button - Navigate to MainProgramWorkoutView
                Button(action: {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    // Use the first session as default when using Start button
                    selectedSessionForWorkout = sessionsToShow.first
                    showMainProgramWorkout = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Start Sprint Training")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.8, blue: 0.0),
                                Color(red: 1.0, green: 0.6, blue: 0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // Sprint Timer Pro Access Point
                SprintTimerProAccessCard(isProUser: isProUser) {
                    if isProUser {
                        // Navigate to Sprint Timer Pro
                        showSprintTimerPro = true
                    } else {
                        // Navigate to Pro Features for purchase
                        selectedMenu = .proFeatures
                        showMenu = false
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Demo: Tap to toggle Pro status (for testing)
                #if DEBUG
                Button(action: {
                    isProUser.toggle()
                }) {
                    Text("Demo: Toggle Pro Status (Currently: \(isProUser ? "PRO" : "FREE"))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                #endif


                // Up Next Section - Exact match
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                        Text("Up Next: Week 1, Day 1")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Accel → Drive")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            Text("3×25yd")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            Text("Max")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Scheduled for tomorrow")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}
// Close TrainingView extension here

// MARK: - TrainingSessionCard Component - Screenshot Style
struct TrainingSessionCard: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Section - Matching screenshot
            HStack {
                // Week/Day Badge
                Text("WEEK \(session.week)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(12)
                
                Spacer()
                
                // Session Type Badge - Matching screenshot
                Text(session.type.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(12)
            }
            
            // Day and Focus - Matching screenshot layout
            VStack(alignment: .leading, spacing: 4) {
                Text("DAY \(session.day)")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                
                Text(session.focus.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1.0)
            }
            
            // Workout Details - Matching screenshot
            HStack {
                if let firstSprint = session.sprints.first {
                    Text("\(firstSprint.reps)")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Text("×")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(firstSprint.distanceYards) YD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Intensity Badge - Matching screenshot
                    Text(firstSprint.intensity.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(12)
                } else {
                    Text("RECOVERY")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("ACTIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.cyan)
                        .cornerRadius(12)
                }
            }
            
            // Motivational tagline
            Text("PUSH YOUR LIMITS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(0.8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.25).opacity(0.9),  // Dark purple
                            Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.95),  // Darker purple
                            Color(red: 0.05, green: 0.05, blue: 0.15).opacity(0.9)  // Very dark purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            // Double frame outline - outer frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .overlay(
            // Double frame outline - inner frame
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .padding(2)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Placeholder Training Card
struct PlaceholderTrainingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WEEK 1")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(12)
                
                Spacer()
                
                Text("ACCELERATION")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("DAY 1")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                
                Text("DRIVE PHASE")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1.0)
            }
            
            HStack {
                Text("5")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                Text("×")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Text("25 YD")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("HIGH")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            
            Text("PUSH YOUR LIMITS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(0.8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Menu Item Components
struct MenuItemRow: View {
    let icon: String
    let title: String
    let selection: MenuSelection
    @Binding var currentSelection: MenuSelection
    @Binding var showMenu: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMenu = false
                currentSelection = selection
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.yellow)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MenuItemRowPremium: View {
    let icon: String
    let title: String
    let selection: MenuSelection
    @Binding var currentSelection: MenuSelection
    @Binding var showMenu: Bool
    let showBadge: Bool
    let badgeColor: Color
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMenu = false
                currentSelection = selection
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.yellow)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showBadge {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("PRO")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Training Program Carousel
struct TrainingProgramCarousel: View {
    let sessions: [TrainingSession]
    @State private var selectedSession: TrainingSession?
    
    // Pre-sort sessions to ensure stability
    private let sortedSessions: [TrainingSession]
    
    init(sessions: [TrainingSession]) {
        self.sessions = sessions
        // Pre-sort sessions to avoid any dynamic sorting in the view body
        self.sortedSessions = sessions.sorted { (a, b) in
            if a.week == b.week {
                return a.day < b.day
            } else {
                return a.week < b.week
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("40 Yards Program")
                .font(.headline)
                .foregroundColor(.brandPrimary)
                .padding(.horizontal)
            Text("12-Week Training Program")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.brandSecondary)
                .padding(.horizontal)
            
            // --- Always show a preview card, even if sessions is empty ---
            Group {
                if sortedSessions.isEmpty {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.brandAccent.opacity(0.85))
                        .frame(width: 360, height: 180)
                        .overlay(
                            Text("No sessions available")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        )
                        .padding(.horizontal)
                }
            }
            // --- End preview card logic ---
            
            // --- Horizontal Scrolling 12-Week Program Cards ---
            if !sortedSessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("12-Week Program")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(sortedSessions.prefix(84).count) Sessions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(sortedSessions.prefix(84), id: \.id) { session in
                                SessionCardDashboardView(session: session)
                                    .frame(width: 280, height: 180)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
                                    .onTapGesture {
                                        selectedSession = session
                                        // --- Haptic feedback on tap ---
                                        #if os(iOS)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        #endif
                                    }
                                    .id(session.id)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .frame(height: 220)
            }
        }
        .sheet(item: $selectedSession) { session in
            NavigationView {
                Text("Training Session W\(session.week)/D\(session.day)")
                    .foregroundColor(.white)
                    .navigationTitle("Session")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                selectedSession = nil
                            }
                        }
                    }
            }
        }
    }
}
// Close TrainingProgramCarousel struct here

// MARK: - Helper Views (file scope)

struct DashboardMotivationText: View {
    var body: some View {
        Text("Every split matters. Chase the 40.")
            .font(.subheadline)
            .foregroundColor(.brandSecondary.opacity(0.7))
            .padding(.horizontal)
    }
}

struct StartSessionButton: View {
    var body: some View {
        NavigationLink(destination: AdaptiveWorkoutHub()) {
            Text("Start Sprint Training")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .accessibilityLabel("Start Sprint Training")
        .accessibilityHint("Opens the adaptive workout hub to choose between iPhone and Apple Watch workouts.")
    }
}

// MARK: - MiniSessionChartView
/*
struct MiniSessionChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Splits")
                .font(.caption2)
                .foregroundColor(.brandTertiary)
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 2) {
                    Capsule().fill(Color.brandPrimary).frame(width: 10, height: 30)
                    Capsule().fill(Color.brandSecondary).frame(width: 10, height: 50)
                    Capsule().fill(Color.brandAccent).frame(width: 10, height: 40)
                    Capsule().fill(Color.brandTertiary).frame(width: 10, height: 35)
                }
            }
            .frame(height: 55)
        }
        .padding(.top, 4)
    }
}
*/


// MARK: - SessionCardDashboardView (renamed from SessionCardView)
struct SessionCardDashboardView: View {
    let session: TrainingSession
    
    // Completely static, pre-rendered content to eliminate any dynamic calculations
    private let cardContent: CardContent
    
    private struct CardContent {
        let weekDay: String
        let warmupText: String
        let sprintText: String?
        let sprintDetails: [String]
        let accessoryText: String?
        let accessoryDetails: [String]
        let notesText: String?
        let additionalSetsText: String?
    }
    
    init(session: TrainingSession) {
        self.session = session
        
        // Pre-render ALL content to ensure zero dynamic calculations in body
        let weekDay = "W\(session.week)/D\(session.day)"
        let warmup = "Warm-up: Jog + A-skips"
        
        var sprintText: String?
        var sprintDetails: [String] = []
        var additionalSets: String?
        
        if !session.sprints.isEmpty {
            sprintText = "Sprints:"
            
            // Pre-compute the first sprint with all validation
            let firstSprint = session.sprints[0]
            let minReps = 1, maxReps = 20, minDistance = 5, maxDistance = 100
            let validReps = (minReps...maxReps).contains(firstSprint.reps) ? firstSprint.reps : minReps
            let validDistance = (minDistance...maxDistance).contains(firstSprint.distanceYards) ? firstSprint.distanceYards : 40
            
            var detailText = "Set 1: \(validReps) x \(validDistance) yd @ \(firstSprint.intensity.capitalized)"
            
            // Add warning if values were clamped
            if firstSprint.reps != validReps || firstSprint.distanceYards != validDistance {
                detailText += " ⚠️"
            }
            
            sprintDetails.append(detailText)
            
            if session.sprints.count > 1 {
                additionalSets = "+\(session.sprints.count - 1) more set(s)"
            }
        }
        
        var accessoryText: String?
        var accessoryDetails: [String] = []
        
        if session.sprints.isEmpty && !session.accessoryWork.isEmpty {
            accessoryText = "Accessory Work:"
            if let firstAccessory = session.accessoryWork.first {
                accessoryDetails.append(firstAccessory)
            }
        }
        
        self.cardContent = CardContent(
            weekDay: weekDay,
            warmupText: warmup,
            sprintText: sprintText,
            sprintDetails: sprintDetails,
            accessoryText: accessoryText,
            accessoryDetails: accessoryDetails,
            notesText: session.notes,
            additionalSetsText: additionalSets
        )
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.brandAccent.opacity(0.85))
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(cardContent.weekDay)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.yellow)
                    Spacer()
                }
                Text(cardContent.warmupText)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.brandPrimary)
                
                if let sprintText = cardContent.sprintText {
                    Text(sprintText)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.brandSecondary)
                    
                    ForEach(cardContent.sprintDetails, id: \.self) { detail in
                        Text(detail)
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    if let additionalText = cardContent.additionalSetsText {
                        Text(additionalText)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else if let accessoryText = cardContent.accessoryText {
                    Text(accessoryText)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.brandSecondary)
                    
                    ForEach(cardContent.accessoryDetails, id: \.self) { detail in
                        Text(detail)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                if let notes = cardContent.notesText, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                
                Spacer(minLength: 0)
            }
            .padding(10)
        }
        .frame(width: 360, height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.18), lineWidth: 2)
        )
    }
}

// MARK: - DayDetailView
/*
struct DayDetailView: View {
    var session: TrainingSession
    @State private var userNotes: String = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Session Detail Section
                Group {
                    Text("W\(session.week)/D\(session.day)")
                        .font(.largeTitle.bold())
                        .foregroundColor(.brandTertiary)
                    if let type = session.sessionType {
                        Text(type)
                            .font(.headline)
                            .foregroundColor(.brandPrimary)
                    }
                    if let goal = session.goal {
                        Text("Goal: \(goal)")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                    if let summary = session.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.brandSecondary)
                    }
                    Divider().padding(.vertical, 4)
                    // Warm-up (mocked)
                    Text("Warm-up: Jog + A-skips")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.brandTertiary)
                    // Main sprint set summary
                    if let firstDrill = session.drills.first {
                        Text("Main Set: \(session.sprints) × " + extractDistance(from: firstDrill) + " yd sprints, " + extractRest(from: firstDrill))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    // All drills with targets/rest
                    Text("Drills:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.brandTertiary)
                    ForEach(session.drills, id: \.self) { drill in
                        Text(drill)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    if session.contrast {
                        Text("Contrast: Yes")
                            .foregroundColor(.brandPrimary)
                    }
                }
                // Show splits chart here
                MiniSessionChartView()
                Divider().padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Notes & Feedback")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                    TextEditor(text: $userNotes)
                        .frame(height: 80)
                        .background(Color.brandAccent.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.bottom, 8)
                    Button(action: { /* Save notes/feedback action */ }) {
                        Text("Save Feedback")
                            .font(.subheadline.bold())
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.brandPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
    // Helper to extract distance from drill string
    private func extractDistance(from drill: String) -> String {
        let pattern = #"(\\d{2,3}) yd"#
        if let match = drill.range(of: pattern, options: .regularExpression) {
            return String(drill[match]).replacingOccurrences(of: " yd", with: "")
        }
        return "--"
    }
    // Helper to extract rest from drill string
    private func extractRest(from drill: String) -> String {
        let pattern = #"Rest: (\\d+)s"#
        if let match = drill.range(of: pattern, options: .regularExpression) {
            return String(drill[match])
        }
        return "Rest: --"
    }
}
*/

// MARK: - Hamburger Side Menu
/*
struct HamburgerSideMenu<MenuType>: View {
    @Binding var showMenu: Bool
    var onSelect: (MenuType) -> Void
    var body: some View {
        ZStack(alignment: .leading) {
            Color.brandBackground.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showMenu = false } }
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 60)
                Group {
                    Button(action: { onSelect(MenuSelection.main as! MenuType) }) {
                        SideMenuRow(icon: "bolt.fill", label: "Sprint 40 yards")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(MenuSelection.history as! MenuType) }) {
                        SideMenuRow(icon: "clock.arrow.circlepath", label: "History")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(MenuSelection.leaderboard as! MenuType) }) {
                        SideMenuRow(icon: "chart.bar.xaxis", label: "Leaderboard")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(MenuSelection.smartHub as! MenuType) }) {
                        SideMenuRow(icon: "lightbulb", label: "40 Yard Smart")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(MenuSelection.settings as! MenuType) }) {
                        SideMenuRow(icon: "gearshape", label: "Settings")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(MenuSelection.helpInfo as! MenuType) }) {
                        SideMenuRow(icon: "questionmark.circle", label: "Help & info")
                    }
                    .buttonStyle(PlainButtonStyle())
                Divider().background(Color.white.opacity(0.2))
                if let _ = MenuType.self as? MenuSelection.Type {
                    Button(action: { onSelect(MenuSelection.shareWithTeammates as! MenuType) }) {
                        SideMenuRow(icon: "person.3.fill", label: "Share with Team Mates")
                    }
                    .buttonStyle(PlainButtonStyle())
                    // Pro Features button dead centre between Share With Team Mates and Accelerate
                    Spacer(minLength: 24)
                    HStack {
                        Spacer()
                        Button(action: { onSelect(MenuSelection.proFeatures as! MenuType) }) {
                            SideMenuRow(icon: "lock.shield", label: "Pro Features", color: .yellow)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                }
                Spacer()
                // Accelerate row
                HStack {
                    SideMenuRow(icon: "hare.fill", label: "Accelerate")
                }
                .padding(.horizontal, 24)
                // Social icons centered below Accelerate
                HStack(spacing: 24) {
                    Image(systemName: "f.circle.fill").foregroundColor(.white)
                    Image(systemName: "camera.circle.fill").foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 32)
                .padding(.top, 4)
                .alignmentGuide(.leading) { d in d[.leading] }
            }
            .frame(width: 280)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.brandAccent, Color.brandTertiary]), startPoint: .top, endPoint: .bottom)
                    .opacity(0.98)
            )
            .edgesIgnoringSafeArea(.vertical)
        }
    }
}
*/

// MARK: - SideMenuRow (for HamburgerSideMenu)
// SideMenuRow struct removed; now imported from SideMenuRow.swift

#if DEBUG
struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TrainingView(userProfileVM: UserProfileViewModel())
        }
    }
}
#endif

// MARK: - TrainingProgramCarousel Previews
#if DEBUG
struct TrainingProgramCarousel_Previews: PreviewProvider {
    static var previews: some View {
        let mockSessions: [TrainingSession] = [
            TrainingSession(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
                week: 1,
                day: 1,
                type: "Speed",
                focus: "Block Starts",
                sprints: [SprintSet(distanceYards: 40, reps: 4, intensity: "max")],
                accessoryWork: ["Plank 3x30s"],
                notes: "Focus on drive phase."
            ),
            TrainingSession(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
                week: 1,
                day: 2,
                type: "Acceleration",
                focus: "Explosive Start",
                sprints: [SprintSet(distanceYards: 30, reps: 3, intensity: "fast")],
                accessoryWork: ["Pushups 3x10"],
                notes: "Keep hips tall."
            ),
            TrainingSession(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
                week: 1,
                day: 3,
                type: "Recovery",
                focus: "Mobility routine",
                sprints: [],
                accessoryWork: ["Mobility routine"],
                notes: "Recovery day."
            )
        ]
        TrainingProgramCarousel(sessions: mockSessions)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
#endif

// MARK: - Canvas Previews

#if DEBUG
#Preview("5. Hamburger Menu") {
    ZStack {
        Rectangle()
            .fill(Color(red: 0.1, green: 0.2, blue: 0.4))
            .ignoresSafeArea()

        HamburgerSideMenu(showMenu: .constant(true), onSelect: { (_: MenuSelection) in })
            .preferredColorScheme(.dark)
    }
}

#Preview("2. Welcome Header Card") {
    VStack(alignment: .leading, spacing: 20) {
        Text("Welcome, David!")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)

        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR PERSONAL BEST")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1)

            Text("5.25s")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow

            Text("40-Yard Dash")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    )
    .shadow(color: .black.opacity(0.3), radius: 8)
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}

#Preview("3. 40 Yards Program Section") {
    VStack(alignment: .leading, spacing: 16) {
        Text("40 YARDS PROGRAM")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .tracking(1)

        Text("12-Week Training Program")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.white)

        Text("Up Next")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
            .padding(.top, 8)
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    )
    .shadow(color: .black.opacity(0.3), radius: 8)
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}

#Preview("4. Start Training Button") {
    NavigationLink(destination: Text("Workout Hub")) {
        Text("Start Sprint Training")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
            .cornerRadius(30)
            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 15)
    }
    .padding(.horizontal, 20)
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}
#endif

// MARK: - Preview
#Preview("TrainingView - Professional UI") {
    TrainingView(userProfileVM: UserProfileViewModel())
        .preferredColorScheme(.dark)
}

// MARK: - Sprint Timer Pro Access Card
struct SprintTimerProAccessCard: View {
    let isProUser: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            onTap()
        }) {
            VStack(spacing: 16) {
                // Header with icon and title
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Sprint Timer Pro")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            if isProUser {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Text(isProUser ? "Create custom sprint workouts" : "Professional timing & training app")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if !isProUser {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$4.99")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            Text("one-time")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        // Pro user - show action button
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text("OPEN PRO")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.yellow.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.yellow, lineWidth: 1)
                                )
                        )
                    }
                }
                
                if !isProUser {
                    // Features preview for non-pro users
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            FeatureTag(text: "10-100 yards")
                            FeatureTag(text: "GPS Timing")
                            FeatureTag(text: "Custom Reps")
                        }
                        
                        HStack(spacing: 12) {
                            FeatureTag(text: "Rest Periods")
                            FeatureTag(text: "Pro Starter")
                            Spacer()
                        }
                    }
                    
                    // Call to action
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("Unlock Sprint Timer Pro")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Spacer()
                    }
                } else {
                    // Pro user - show access button
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Open Sprint Timer Pro")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isProUser ? Color.green.opacity(0.1) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isProUser ? Color.green.opacity(0.3) : Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), lineWidth: isProUser ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feature Tag Component
struct FeatureTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Helper Methods

extension TrainingView {
    private func getCurrentTrainingSession() -> TrainingSession? {
        return generateDynamicSessions().first
    }
}

// MARK: - MenuItemButton Component

struct MenuItemButton: View {
    let icon: String
    let title: String
    let selection: MenuSelection
    @Binding var currentSelection: MenuSelection
    @Binding var showMenu: Bool
    var isPremium: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSelection = selection
                showMenu = false
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isPremium {
                    Text("PRO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
                
                if currentSelection == selection {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                currentSelection == selection ? 
                Color.white.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
