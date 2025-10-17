import SwiftUI

#if os(iOS)
import UIKit
#endif

struct TrainingView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showMenu = false
    @State private var selectedMenu: MenuSelection = .main
    @State private var showPaywall = false

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
                        AnyView(HistoryView(sessions: [], userProfile: profile).navigationTitle("History")) // Using empty array until session management is restored
                    case .leaderboard:
                        AnyView(UserStatsView(currentUser: profile))
                    case .smartHub:
                        AnyView(SmartHubView())
                    case .settings:
                        AnyView(SettingsView())
                    case .helpInfo:
                        AnyView(HelpInfoView())
                    // case .news: // NewsView not defined, removed
                    case .shareWithTeammates:
                        AnyView(ShareWithTeammatesView())
                    case .sharePerformance:
                        AnyView(SharePerformanceView())
                    case .proFeatures:
                        AnyView(StarterProPurchaseView())
                    case .performanceTrends:
                        if isProUser {
                            AnyView(PerformanceTrendsView(weeks: [])) // TODO: Pass real data
                        } else {
                            AnyView(ProPaywall(showPaywall: $showPaywall, onUnlock: { isProUser = true; showPaywall = false }))
                        }
                    case .news:
                        AnyView(SprintNewsView()) // Add NewsView case
                    }
                }
                .background(Color.clear)
                .navigationTitle("Sprint Coach 40")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { withAnimation { showMenu.toggle() }; triggerHaptic(.medium) }) {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                                .foregroundColor(.brandPrimary)
                        }
                        .accessibilityLabel("Open menu")
                        .accessibilityHint("Opens the navigation menu")
                    }
                }
            }
            if showMenu {
                HamburgerSideMenu(
                    showMenu: $showMenu,
                    onSelect: { selection in
                        withAnimation { showMenu = false }
                        selectedMenu = selection
                    }
                )
                .transition(.move(edge: .leading))
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
    // Using fixed UUIDs to ensure stable identity for SwiftUI ForEach
    private static let staticMockSessions: [TrainingSession] = [
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            week: 1,
            day: 1,
            type: "Sprint",
            focus: "Accel → Max Speed",
            sprints: [SprintSet(distanceYards: 30, reps: 3, intensity: "Max")],
            accessoryWork: ["Dynamic warm-up", "Cool-down stretching"],
            notes: "Focus on drive phase."
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            week: 1,
            day: 2,
            type: "Sprint",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 25, reps: 3, intensity: "Max")],
            accessoryWork: ["Reaction drills", "Cool-down protocol"],
            notes: "Focus on first step quickness."
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            week: 2,
            day: 3,
            type: "Active Recovery",
            focus: "Recovery",
            sprints: [],
            accessoryWork: ["20-30 min easy jog", "Dynamic stretching", "Foam rolling"],
            notes: "Active recovery day"
        ),
        TrainingSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            week: 4,
            day: 1,
            type: "Benchmark",
            focus: "Benchmark",
            sprints: [SprintSet(distanceYards: 40, reps: 1, intensity: "test")],
            accessoryWork: ["Extended warm-up", "Mental preparation", "Cool-down protocol"],
            notes: "40-yard time trial - Week 4 assessment"
        )
    ]

    // Main dashboard with 12-week training program carousel
    func mainDashboard(profile: UserProfile, userProfileVM: UserProfileViewModel) -> some View {
        // Use user's actual sessions if they exist, otherwise show static mock data for demo
        // Cache the sessions to prevent recreation on every view update
        let sessionsToShow: [TrainingSession]
        if !profile.sessionIDs.isEmpty {
            // User has completed onboarding and has a generated program from SessionLibrary
            // Cache these sessions to prevent recreation and flashing
            // TODO: Implement session retrieval from UUID-based storage
            sessionsToShow = TrainingView.staticMockSessions // Using mock data temporarily
        } else {
            // Show static mock data for demo/onboarding incomplete - representative of SessionLibrary quality
            sessionsToShow = TrainingView.staticMockSessions
        }
        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // Welcome Header Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Welcome, \(profile.name)!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR PERSONAL BEST")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)
                        
                        Text("\(String(format: "%.2f", profile.personalBests["40yd"] ?? profile.baselineTime))s")
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

                // 40 Yards Program Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("40 YARDS PROGRAM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                    
                    Text("12-Week Training Program")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Session Card - Use pyramid session for Week 1, Day 1
                    let pyramidSession = TrainingSession(
                        week: 1,
                        day: 1,
                        type: "10-20-30-40-30-20-10 yd Pyramid",
                        focus: "Up-Down Pyramid",
                        sprints: [
                            SprintSet(distanceYards: 10, reps: 1, intensity: "100%"),
                            SprintSet(distanceYards: 20, reps: 1, intensity: "100%"),
                            SprintSet(distanceYards: 30, reps: 1, intensity: "100%"),
                            SprintSet(distanceYards: 40, reps: 1, intensity: "100%"),
                            SprintSet(distanceYards: 30, reps: 1, intensity: "100%"),
                            SprintSet(distanceYards: 20, reps: 1, intensity: "100%"),
                            SprintSet(distanceYards: 10, reps: 1, intensity: "100%")
                        ],
                        accessoryWork: ["Dynamic warm-up", "Cool-down stretching"]
                    )
                    SessionCardDashboardView(session: pyramidSession)
                        .frame(width: UIScreen.main.bounds.width * 0.9)
                    
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

                // Start Training Button
                NavigationLink(destination: AdaptiveWorkoutHub()) {
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
                .padding(.top, 16)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
    }
}
// Close TrainingView struct here

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
            
            // --- Snap-to-card carousel ---
            if !sortedSessions.isEmpty {
                TabView {
                    ForEach(sortedSessions.prefix(84), id: \.id) { session in
                        SessionCardDashboardView(session: session)
                            .frame(width: UIScreen.main.bounds.width * 0.9)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
                            .padding(.vertical, 8)
                            .onTapGesture {
                                selectedSession = session
                                // --- Haptic feedback on tap ---
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            }
                            .id(session.id) // Explicit id to ensure stability
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 200)
            }
        }
        .sheet(item: $selectedSession) { session in
            DayDetailView(session: session)
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

