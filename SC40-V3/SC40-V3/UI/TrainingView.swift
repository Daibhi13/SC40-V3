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

struct TrainingView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showMenu = false
    @State private var selectedMenu: MenuSelection = .main
    @State private var showPaywall = false
    @State private var showSixPartWorkout = false
    @State private var selectedSession: TrainingSession?
    @State private var showMainProgramWorkout = false

    enum MenuSelection {
        case main
        case history
        case leaderboard
        case smartHub
        case settings
        case helpInfo
        case news
        case shareWithTeammates
        case sharePerformance
        case proFeatures
        case performanceTrends
    }

    var body: some View {
        let profile = userProfileVM.profile
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
            
            NavigationView {
                ZStack {
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
                        AnyView(SharePerformanceView())
                    case .proFeatures:
                        AnyView(Text("Pro Features").foregroundColor(.white).navigationTitle("Pro Features"))
                    case .performanceTrends:
                        AnyView(AdvancedAnalyticsView())
                    }
                }
                .background(Color.clear)
                .navigationTitle("Sprint Coach 40")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { 
                            withAnimation { showMenu.toggle() }
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                                .foregroundColor(.yellow)
                        }
                        .accessibilityLabel("Open menu")
                        .accessibilityHint("Opens the navigation menu")
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Image(systemName: "applewatch")
                                .foregroundColor(.yellow)
                            Image(systemName: "bell.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            if showMenu {
                // Professional hamburger menu - exact match to screenshot
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    }
                
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header with close button
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.yellow)
                                Text("Sprint Coach 40")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 32)
                        
                        // Menu items
                        VStack(alignment: .leading, spacing: 0) {
                            MenuItemRow(icon: "bolt.fill", title: "Sprint 40 Yards", selection: .main, currentSelection: $selectedMenu, showMenu: $showMenu)
                            MenuItemRow(icon: "clock.arrow.circlepath", title: "History", selection: .history, currentSelection: $selectedMenu, showMenu: $showMenu)
                            MenuItemRow(icon: "chart.bar.xaxis", title: "Leaderboard", selection: .leaderboard, currentSelection: $selectedMenu, showMenu: $showMenu)
                            MenuItemRow(icon: "square.and.arrow.up", title: "Share Performance", selection: .sharePerformance, currentSelection: $selectedMenu, showMenu: $showMenu)
                            MenuItemRow(icon: "lightbulb", title: "40 Yard Smart", selection: .smartHub, currentSelection: $selectedMenu, showMenu: $showMenu)
                            
                            // Advanced Analytics with PRO badge
                            MenuItemRowPremium(icon: "chart.line.uptrend.xyaxis", title: "Advanced\nAnalytics", selection: .performanceTrends, currentSelection: $selectedMenu, showMenu: $showMenu, showBadge: !isProUser, badgeColor: .yellow)
                            
                            MenuItemRow(icon: "gearshape", title: "Settings", selection: .settings, currentSelection: $selectedMenu, showMenu: $showMenu)
                            MenuItemRow(icon: "questionmark.circle", title: "Help & Info", selection: .helpInfo, currentSelection: $selectedMenu, showMenu: $showMenu)
                            MenuItemRow(icon: "newspaper", title: "News", selection: .news, currentSelection: $selectedMenu, showMenu: $showMenu)
                        }
                        
                        Spacer()
                        
                        // Share with Teammates
                        MenuItemRow(icon: "person.3.fill", title: "Share with Teammates", selection: .shareWithTeammates, currentSelection: $selectedMenu, showMenu: $showMenu)
                            .padding(.bottom, 24)
                        
                        // Pro Features button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) { 
                                showMenu = false
                                selectedMenu = .proFeatures
                            }
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Pro Features")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.yellow)
                            .cornerRadius(22)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        
                        // Accelerate
                        HStack {
                            Image(systemName: "hare.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Accelerate")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        
                        // Social icons
                        HStack(spacing: 20) {
                            Image(systemName: "f.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.7))
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 32)
                    }
                    .frame(width: 280)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.4, blue: 0.8),
                                Color(red: 0.4, green: 0.2, blue: 0.8),
                                Color(red: 0.6, green: 0.2, blue: 0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
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
                        }
                    }
            }
        }
        .sheet(isPresented: $showMainProgramWorkout) {
            NavigationView {
                MainProgramWorkoutView()
                    .navigationTitle("Sprint Training")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showMainProgramWorkout = false
                            }
                        }
                    }
            }
        }
    }
    
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

    // Static mock sessions to prevent recreation on every view update
    // Static mock sessions for demo - representative of SessionLibrary quality
    static let staticMockSessions: [TrainingSession] = [
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            week: 1,
            day: 1,
            type: "Speed",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 25, reps: 3, intensity: "max")],
            accessoryWork: ["Dynamic warm-up", "A-skips", "Cool-down stretching"],
            notes: "Focus on explosive starts"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            week: 1,
            day: 2,
            type: "Speed",
            focus: "Drive Phase",
            sprints: [SprintSet(distanceYards: 30, reps: 4, intensity: "max")],
            accessoryWork: ["Dynamic warm-up", "High knees", "Cool-down stretching"],
            notes: "Maintain low body position"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            week: 1,
            day: 3,
            type: "Plyometrics",
            focus: "Power",
            sprints: [SprintSet(distanceYards: 20, reps: 5, intensity: "explosive")],
            accessoryWork: ["Jump training", "Reactive drills", "Recovery"],
            notes: "Focus on explosive power"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            week: 2,
            day: 1,
            type: "Speed",
            focus: "Max Velocity",
            sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "max")],
            accessoryWork: ["Flying starts", "Wicket runs", "Cool-down"],
            notes: "Build top-end speed"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            week: 2,
            day: 2,
            type: "Tempo",
            focus: "Endurance",
            sprints: [SprintSet(distanceYards: 60, reps: 4, intensity: "tempo")],
            accessoryWork: ["Extended warm-up", "Tempo runs", "Recovery"],
            notes: "Build speed endurance"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            week: 2,
            day: 3,
            type: "Active Recovery",
            focus: "Recovery",
            sprints: [],
            accessoryWork: ["20-30 min easy jog", "Dynamic stretching", "Foam rolling"],
            notes: "Active recovery day"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            week: 3,
            day: 1,
            type: "Speed",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 35, reps: 4, intensity: "max")],
            accessoryWork: ["Block starts", "Drive phase", "Cool-down"],
            notes: "Perfect your start technique"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
            week: 3,
            day: 2,
            type: "Flying Runs",
            focus: "Top Speed",
            sprints: [SprintSet(distanceYards: 50, reps: 3, intensity: "max")],
            accessoryWork: ["Build-up runs", "Flying starts", "Recovery"],
            notes: "Reach maximum velocity"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
            week: 3,
            day: 3,
            type: "Plyometrics",
            focus: "Reactive Power",
            sprints: [SprintSet(distanceYards: 25, reps: 4, intensity: "explosive")],
            accessoryWork: ["Depth jumps", "Bounding", "Recovery"],
            notes: "Develop reactive strength"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            week: 4,
            day: 1,
            type: "Benchmark",
            focus: "Assessment",
            sprints: [SprintSet(distanceYards: 40, reps: 1, intensity: "test")],
            accessoryWork: ["Extended warm-up", "Mental preparation", "Cool-down protocol"],
            notes: "40-yard time trial - Week 4 assessment"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            week: 4,
            day: 2,
            type: "Speed",
            focus: "Competition Prep",
            sprints: [SprintSet(distanceYards: 40, reps: 2, intensity: "race pace")],
            accessoryWork: ["Race simulation", "Mental prep", "Recovery"],
            notes: "Practice race conditions"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            week: 4,
            day: 3,
            type: "Recovery",
            focus: "Regeneration",
            sprints: [],
            accessoryWork: ["Light movement", "Massage", "Stretching"],
            notes: "Full recovery session"
        )
    ]

    // Main dashboard matching the exact screenshot design
    func mainDashboard(profile: UserProfile, userProfileVM: UserProfileViewModel) -> some View {
        let sessionsToShow: [TrainingSession]
        if !profile.sessionIDs.isEmpty {
            sessionsToShow = TrainingView.staticMockSessions
        } else {
            sessionsToShow = TrainingView.staticMockSessions
        }
        
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Welcome Header - Exact match to screenshot
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome, David!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR PERSONAL BEST")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.2)
                        
                        Text("5.25s")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("40-Yard Dash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    
                    // Horizontal Scrolling Training Cards - Nike Style
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(sessionsToShow.prefix(12), id: \.id) { session in
                                TrainingSessionCard(session: session)
                                    .onTapGesture {
                                        showMainProgramWorkout = true
                                        #if os(iOS)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        #endif
                                    }
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
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
// Close TrainingView struct here

// MARK: - TrainingSessionCard Component - Nike Style
struct TrainingSessionCard: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section - Nike Style
            VStack(alignment: .leading, spacing: 8) {
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
                    
                    // Session Type Badge
                    Text(session.type.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(0.5)
                }
                
                // Day and Focus
                Text("DAY \(session.day)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                
                Text(session.focus.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .tracking(1.0)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Workout Details - Nike Style
            VStack(alignment: .leading, spacing: 6) {
                if let firstSprint = session.sprints.first {
                    HStack {
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
                        Text(firstSprint.intensity.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                } else {
                    HStack {
                        Text("RECOVERY")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                        Spacer()
                        Text("ACTIVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyan)
                            .cornerRadius(8)
                    }
                }
                
                // Motivational tagline - Nike style
                Text("PUSH YOUR LIMITS")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 340, height: 160) // Wider cards as requested
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color(red: 0.1, green: 0.1, blue: 0.1),
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Menu Item Components
struct MenuItemRow: View {
    let icon: String
    let title: String
    let selection: TrainingView.MenuSelection
    @Binding var currentSelection: TrainingView.MenuSelection
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
    let selection: TrainingView.MenuSelection
    @Binding var currentSelection: TrainingView.MenuSelection
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
                    Button(action: { onSelect(TrainingView.MenuSelection.main as! MenuType) }) {
                        SideMenuRow(icon: "bolt.fill", label: "Sprint 40 yards")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(TrainingView.MenuSelection.history as! MenuType) }) {
                        SideMenuRow(icon: "clock.arrow.circlepath", label: "History")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(TrainingView.MenuSelection.leaderboard as! MenuType) }) {
                        SideMenuRow(icon: "chart.bar.xaxis", label: "Leaderboard")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(TrainingView.MenuSelection.smartHub as! MenuType) }) {
                        SideMenuRow(icon: "lightbulb", label: "40 Yard Smart")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(TrainingView.MenuSelection.settings as! MenuType) }) {
                        SideMenuRow(icon: "gearshape", label: "Settings")
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { onSelect(TrainingView.MenuSelection.helpInfo as! MenuType) }) {
                        SideMenuRow(icon: "questionmark.circle", label: "Help & info")
                    }
                    .buttonStyle(PlainButtonStyle())
                Divider().background(Color.white.opacity(0.2))
                if let _ = MenuType.self as? TrainingView.MenuSelection.Type {
                    Button(action: { onSelect(TrainingView.MenuSelection.shareWithTeammates as! MenuType) }) {
                        SideMenuRow(icon: "person.3.fill", label: "Share with Team Mates")
                    }
                    .buttonStyle(PlainButtonStyle())
                    // Pro Features button dead centre between Share With Team Mates and Accelerate
                    Spacer(minLength: 24)
                    HStack {
                        Spacer()
                        Button(action: { onSelect(TrainingView.MenuSelection.proFeatures as! MenuType) }) {
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

        HamburgerSideMenu(showMenu: .constant(true), onSelect: { (_: TrainingView.MenuSelection) in })
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
