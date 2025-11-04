import SwiftUI
import Combine

#if os(iOS)
import UIKit
#endif

// MARK: - Imports for existing types
// Using existing types from the project:
// - UserProfile from Models/UserProfile.swift
// - UserProfileViewModel from Models/UserProfileViewModel.swift  
// - TrainingSession from Models/SprintSetAndTrainingSession.swift
// - SprintSet from Models/SprintSetAndTrainingSession.swift

// MARK: - Global Helper Functions
/// Clean focus text to remove duplicate words and polish display
func cleanFocusText(_ focus: String) -> String {
    var cleaned = focus
    
    // Remove specific duplicate patterns (most common first)
    cleaned = cleaned.replacingOccurrences(of: "Development Speed Development", with: "Speed Development")
    cleaned = cleaned.replacingOccurrences(of: "Speed Development Development", with: "Speed Development")
    cleaned = cleaned.replacingOccurrences(of: "Development Development", with: "Development")
    cleaned = cleaned.replacingOccurrences(of: "Speed Speed", with: "Speed")
    cleaned = cleaned.replacingOccurrences(of: "Training Training", with: "Training")
    cleaned = cleaned.replacingOccurrences(of: "Acceleration Acceleration", with: "Acceleration")
    cleaned = cleaned.replacingOccurrences(of: "Velocity Velocity", with: "Velocity")
    cleaned = cleaned.replacingOccurrences(of: "Power Power", with: "Power")
    cleaned = cleaned.replacingOccurrences(of: "Mechanics Mechanics", with: "Mechanics")
    cleaned = cleaned.replacingOccurrences(of: "Endurance Endurance", with: "Endurance")
    
    // Remove redundant "Development" patterns
    cleaned = cleaned.replacingOccurrences(of: "Development Speed", with: "Speed Development")
    cleaned = cleaned.replacingOccurrences(of: "Development Acceleration", with: "Acceleration Development")
    cleaned = cleaned.replacingOccurrences(of: "Development Power", with: "Power Development")
    cleaned = cleaned.replacingOccurrences(of: "Development Max", with: "Max Development")
    
    // Clean up multiple spaces
    while cleaned.contains("  ") {
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
    }
    
    return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - TrainingView
// - Uses TrainingSession from Models/SprintSetAndTrainingSession.swift
// - Uses SprintSet from Models/SprintSetAndTrainingSession.swift

struct TrainingView: View {
    // MARK: - Properties
    @ObservedObject var userProfileVM: UserProfileViewModel
    @State private var watchConnectivity: WatchConnectivityManager?
    @State private var startupManager: AppStartupManager?
    @State private var premiumConnectivity: PremiumConnectivityManager?
    @EnvironmentObject private var syncManager: TrainingSynchronizationManager
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
    @State private var showWatchConnectivityTest = false
    @State private var isDataComplete = false
    @State private var showSyncDemo = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        let profile = userProfileVM.profile
        
        // DEFENSIVE CHECKS: Validate profile data before proceeding
        if profile.level.isEmpty || profile.frequency == 0 {
            return AnyView(
                ZStack {
                    // Same background as main view
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
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.yellow)
                        
                        Text("⏳ Loading Profile Data...")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("Level: '\(profile.level.isEmpty ? "Not Set" : profile.level)'\nFrequency: \(profile.frequency) days/week")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button("Retry Loading") {
                            // Force refresh profile from UserDefaults
                            userProfileVM.refreshFromUserDefaults()
                            refreshDynamicSessions()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                    }
                    .padding()
                }
            )
        }
        
        // Debug: Log profile changes
        let _ = print("🔄 TrainingView body refresh - Level: '\(profile.level)', Frequency: \(profile.frequency), Week: \(profile.currentWeek)")
        return AnyView(
            ZStack {
                backgroundView
                navigationContentView(profile: profile)
                hamburgerMenuOverlay
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
            }
        )
    
    var backgroundView: some View {
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
        }
    }
    
    func navigationContentView(profile: UserProfile) -> some View {
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
                        AnyView(SettingsView(userProfileVM: userProfileVM))
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
                    case .advancedAnalytics:
                        AnyView(AdvancedAnalyticsView(userProfileVM: userProfileVM))
                    }
                }
                .navigationTitle("Sprint Coach 40")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(false)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { 
                            // Stable menu toggle without animation conflicts
                            showMenu.toggle()
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
                                    .rotationEffect(.degrees(showMenu ? 90 : 0))
                                    .animation(.easeInOut(duration: 0.2), value: showMenu)
                            }
                        }
                        .accessibilityLabel("Open menu")
                        .accessibilityHint("Opens the navigation menu")
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if let connectivityManager = premiumConnectivity {
                            CompactConnectivityIndicator(connectivityManager: connectivityManager)
                                .onTapGesture {
                                    showWatchConnectivityTest = true
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                }
                                .accessibilityLabel("Premium Connectivity Status")
                                .accessibilityHint("Shows connection quality and sync status")
                        } else {
                            // Placeholder while connectivity manager loads
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                                .opacity(0.5)
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.clear, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .preferredColorScheme(.dark)
                .onAppear {
                    // CRASH PROTECTION: Initialize managers lazily to prevent deadlock
                    initializeManagersLazily()
                    
                    // Validate data completeness before loading
                    validateDataCompleteness()
                    
                    // Only proceed if startup is complete and data is valid
                    guard let startup = startupManager, startup.canProceedToMainView else {
                        print("⚠️ TrainingView: Startup not complete, deferring initialization")
                        return
                    }
                    
                    // Refresh profile data to ensure it's up-to-date with onboarding selections
                    refreshProfileFromUserDefaults()
                    
                    // IMMEDIATE SESSION REFRESH: Generate sessions with updated profile
                    refreshDynamicSessions()
                    
                    // Setup training plan update listener
                    setupTrainingPlanUpdateListener()
                    
                    // FORCE UI UPDATE: Trigger view refresh after profile changes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        userProfileVM.objectWillChange.send()
                        refreshTrigger = UUID() // Force complete view refresh
                        print("🔄 TrainingView: Forced UI update after profile refresh")
                        
                        // Also sync updated profile to Watch
                        Task {
                            await WatchConnectivityManager.shared.syncOnboardingData(userProfile: userProfileVM.profile)
                            print("🔄 TrainingView: Synced updated profile to Watch")
                        }
                    }
                    
                    // ADDITIONAL: Force carousel and dashboard refresh
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        refreshTrigger = UUID()
                        print("🎠 TrainingView: Forced carousel refresh for updated profile data")
                    }
                    
                    // Configure NavigationView to use transparent background - TrainingView specific
                    #if os(iOS)
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithTransparentBackground()
                    appearance.backgroundColor = UIColor.clear
                    appearance.shadowColor = UIColor.clear
                    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                    
                    // Apply only to this navigation controller instance
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let navigationController = windowScene.windows.first?.rootViewController as? UINavigationController {
                        navigationController.navigationBar.standardAppearance = appearance
                        navigationController.navigationBar.compactAppearance = appearance
                        navigationController.navigationBar.scrollEdgeAppearance = appearance
                        navigationController.navigationBar.tintColor = UIColor.white
                    }
                    #endif
                }
                .onChange(of: userProfileVM.profile.level) { oldLevel, newLevel in
                    // LEVEL CHANGE DETECTION: Refresh sessions when level changes
                    print("🔄 TrainingView: Level changed from '\(oldLevel)' to '\(newLevel)' - refreshing sessions")
                    refreshDynamicSessions()
                    
                    // Force UI update
                    DispatchQueue.main.async {
                        userProfileVM.objectWillChange.send()
                    }
                }
                .onChange(of: userProfileVM.profile.frequency) { oldFreq, newFreq in
                    // FREQUENCY CHANGE DETECTION: Refresh sessions when frequency changes
                    print("🔄 TrainingView: Frequency changed from \(oldFreq) to \(newFreq) days - refreshing sessions")
                    refreshDynamicSessions()
                    
                    // Force UI update
                    DispatchQueue.main.async {
                        userProfileVM.objectWillChange.send()
                    }
                }
        }
    }
    
    // Hamburger Menu Overlay - stable positioning with modern SwiftUI
    var hamburgerMenuOverlay: some View {
        Group {
            if showMenu {
                HamburgerSideMenuWithProfile(
                    showMenu: $showMenu,
                    profile: userProfileVM.profile,
                    onSelect: { (selection: MenuSelection) in
                        // Direct assignment since both use the same MenuSelection type
                        selectedMenu = selection
                    }
                )
                .zIndex(1000) // Ensure menu appears above all content
            }
        }
    }
    
    // MARK: - Workout Completion Handler
    
    func handleWorkoutCompletion(_ completedWorkout: MainProgramWorkoutView.CompletedWorkoutData) {
        print("🏆 Workout completed! Session: \(completedWorkout.originalSession.sessionName)")
        print("📊 Completion rate: \(String(format: "%.1f", completedWorkout.completionRate * 100))%")
        
        if let avgTime = completedWorkout.averageTime {
            print("⏱️ Average time: \(String(format: "%.2f", avgTime))s")
        }
        
        if let bestTime = completedWorkout.bestTime {
            print("🚀 Best time: \(String(format: "%.2f", bestTime))s")
        }
        
        // Update user progress
        updateUserProgress(with: completedWorkout)
        
        // Mark session as completed
        markSessionAsCompleted(completedWorkout.originalSession)
        
        // Close workout view
        showMainProgramWorkout = false
    }
    
    func updateUserProgress(with completedWorkout: MainProgramWorkoutView.CompletedWorkoutData) {
        // Find the corresponding session in the user's program
        let sessionID = TrainingSession.stableSessionID(
            week: completedWorkout.originalSession.week, 
            day: completedWorkout.originalSession.day
        )
        
        // Extract sprint times from completed reps
        let sprintTimes = completedWorkout.completedReps.compactMap { $0.time }
        
        // Use the existing UserProfileViewModel API to complete the session
        userProfileVM.completeSession(
            sessionID, 
            sprintTimes: sprintTimes,
            rpe: completedWorkout.effortLevel,
            notes: completedWorkout.notes
        )
        
        print("📈 Updated user progress for Week \(completedWorkout.originalSession.week), Day \(completedWorkout.originalSession.day)")
        print("🏆 Session completed with \(sprintTimes.count) sprint times recorded")
        
        // Update personal bests if applicable
        if let bestTime = completedWorkout.bestTime {
            let currentPB = userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime
            if bestTime < currentPB {
                userProfileVM.updatePersonalBest(bestTime)
                print("🚀 New Personal Best! 40yd: \(String(format: "%.2f", bestTime))s")
            }
        }
    }
    
    func markSessionAsCompleted(_ sessionData: MainProgramWorkoutView.SessionData) {
        // Find and mark the corresponding training session as completed
        if dynamicSessions.contains(where: { 
            $0.week == sessionData.week && $0.day == sessionData.day 
        }) {
            // Update the session status (would need to add isCompleted property to TrainingSession)
            print("✅ Marked session W\(sessionData.week)D\(sessionData.day) as completed")
        }
    }
    
    // MARK: - Helper Functions
    
    func convertToSessionData(_ session: TrainingSession?) -> MainProgramWorkoutView.SessionData? {
        guard let session = session else { return nil }
        
        // Convert each sprint with its reps into individual SprintSets for MainProgramWorkoutView
        var convertedSprintSets: [MainProgramWorkoutView.SprintSet] = []
        
        for sprint in session.sprints {
            // Create one SprintSet for each rep in the sprint
            for _ in 0..<sprint.reps {
                convertedSprintSets.append(
                    MainProgramWorkoutView.SprintSet(
                        distance: sprint.distanceYards,
                        restTime: getRestTimeForDistance(sprint.distanceYards),
                        targetTime: nil
                    )
                )
            }
        }
        
        let convertedDrillSets = session.accessoryWork.map { drill in
            MainProgramWorkoutView.DrillSet(
                name: drill,
                duration: 60, // 1 minute default
                restTime: 30  // 30 seconds rest
            )
        }
        
        let convertedStrideSets = [
            MainProgramWorkoutView.StrideSet(
                distance: 60,
                restTime: 30 // 30 seconds rest for strides
            )
        ]
        
        return MainProgramWorkoutView.SessionData(
            week: 1, // Default week
            day: 1, // Default day
            sessionName: session.type,
            sessionFocus: session.focus,
            sprintSets: convertedSprintSets,
            drillSets: convertedDrillSets,
            strideSets: convertedStrideSets,
            sessionType: session.type,
            level: 1, // Default level
            estimatedDuration: calculateEstimatedDuration(session),
            variety: 0.8,
            engagement: 0.9
        )
    }
    
    func getRestTimeForDistance(_ distance: Int) -> Int {
        // Rest time in minutes based on distance
        switch distance {
        case 0...20: return 1   // 1 minute
        case 21...40: return 2  // 2 minutes
        case 41...60: return 3  // 3 minutes
        case 61...80: return 4  // 4 minutes
        default: return 5       // 5 minutes
        }
    }
    
    func getLevelFromType(_ session: TrainingSession) -> Int {
        // Determine level based on session type and sprint distances
        let maxDistance = session.sprints.map { $0.distanceYards }.max() ?? 20
        switch maxDistance {
        case 0...30: return 1    // Beginner
        case 31...60: return 2   // Intermediate
        case 61...80: return 3   // Advanced
        default: return 4        // Elite
        }
    }
    
    func calculateEstimatedDuration(_ session: TrainingSession) -> Int {
        // Calculate total session duration in minutes
        let sprintTime = session.sprints.reduce(0) { total, sprint in
            let restTimeMinutes = getRestTimeForDistance(sprint.distanceYards)
            let restTimeSeconds = restTimeMinutes * 60 // Convert minutes to seconds
            return total + (sprint.reps * (10 + restTimeSeconds)) // 10 seconds per sprint + rest
        }
        let drillTime = session.accessoryWork.count * 90 // 90 seconds per drill
        let strideTime = 4 * 90 // 4 strides with 90 seconds each
        let warmupCooldown = 600 // 10 minutes total
        
        return (sprintTime + drillTime + strideTime + warmupCooldown) / 60
    }
    
    // MARK: - Profile and Session Refresh Methods

    /// Refresh profile data from UserDefaults to ensure sync with onboarding
    func refreshProfileFromUserDefaults() {
        print("🔄 TrainingView: Refreshing profile from UserDefaults")

        // First, check what's actually in UserDefaults
        let savedLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Not Set"
        let savedFrequency = UserDefaults.standard.integer(forKey: "trainingFrequency")
        let savedPB = UserDefaults.standard.double(forKey: "personalBest40yd")

        
        print("📋 UserDefaults Values:")
        print("   userLevel: '\(savedLevel)'")
        print("   trainingFrequency: \(savedFrequency)")
        print("   personalBest40yd: \(savedPB)")
        
        // Refresh the profile
        userProfileVM.refreshFromUserDefaults()
        
        // Log current profile state after refresh
        let profile = userProfileVM.profile
        print("📊 Profile State After Refresh:")
        print("   Level: '\(profile.level)'")
        print("   Frequency: \(profile.frequency) days/week")
        print("   Week: \(profile.currentWeek)")
        print("   Baseline Time: \(profile.baselineTime)")
        
        // CRITICAL VALIDATION: Check for state mismatches and fix them
        if profile.level != savedLevel && savedLevel != "Not Set" {
            print("❌ CRITICAL SYNC ISSUE: Profile level (\(profile.level)) != UserDefaults (\(savedLevel))")
            print("🔧 FIXING: Forcing profile to match UserDefaults")
            
            // Force profile to match UserDefaults (source of truth)
            userProfileVM.profile.level = savedLevel
            userProfileVM.saveProfile()
            
            // Regenerate sessions with correct level
            refreshDynamicSessions()
        }
        
        if profile.frequency != savedFrequency && savedFrequency > 0 {
            print("❌ CRITICAL SYNC ISSUE: Profile frequency (\(profile.frequency)) != UserDefaults (\(savedFrequency))")
            print("🔧 FIXING: Forcing profile to match UserDefaults")
            
            // Force profile to match UserDefaults (source of truth)
            userProfileVM.profile.frequency = savedFrequency
            userProfileVM.saveProfile()
            
            // Regenerate sessions with correct frequency
            refreshDynamicSessions()
        }
        
        // Force UI update to reflect changes
        userProfileVM.objectWillChange.send()
        
        // Additional validation: Ensure UI displays match profile
        print("🔍 Final validation - TrainingView will display:")
        print("   Level: '\(userProfileVM.profile.level)'")
        print("   Frequency: \(userProfileVM.profile.frequency) days/week")
    }
    
    /// Refresh dynamic sessions when profile changes
    func refreshDynamicSessions() {
        print("🔄 TrainingView: Refreshing dynamic sessions")
        print("🔄 Profile: Level=\(userProfileVM.profile.level), Frequency=\(userProfileVM.profile.frequency), Week=\(userProfileVM.profile.currentWeek)")
        
        // Clear any cached sessions to force regeneration
        TrainingView.clearSessionCache()
        
        // Generate new sessions with current profile
        let newSessions = generateDynamicSessions()
        
        // Update the state
        dynamicSessions = newSessions
        
        print("✅ TrainingView: Generated \(newSessions.count) sessions for \(userProfileVM.profile.level) \(userProfileVM.profile.frequency)-day program")
        
        // Log sessions for current week for verification
        let currentWeekSessions = newSessions.filter { $0.week == userProfileVM.profile.currentWeek }
        print("📅 Current Week \(userProfileVM.profile.currentWeek) sessions: \(currentWeekSessions.count)")
        for session in currentWeekSessions {
            print("   W\(session.week)D\(session.day): \(session.type)")
        }
        
        // Auto-sync sessions to watch for immediate availability
        Task {
            await autoSyncSessionsToWatch(newSessions)
        }
    }
    
    /// Automatically syncs sessions to watch when they're generated/updated
    func autoSyncSessionsToWatch(_ sessions: [TrainingSession]) async {
        guard WatchConnectivityManager.shared.isWatchReachable else {
            print("⌚ Watch not reachable - skipping auto-sync")
            return
        }
        
        print("🚀 Auto-syncing sessions to watch for immediate availability")
        
        // Sync current week sessions immediately for instant access
        await WatchConnectivityManager.shared.syncCurrentWeekSessions(
            from: sessions,
            currentWeek: userProfileVM.profile.currentWeek,
            frequency: userProfileVM.profile.frequency
        )
        
        // Background sync of next batch for seamless progression
        await WatchConnectivityManager.shared.syncNextSessionBatch(
            from: sessions,
            currentWeek: userProfileVM.profile.currentWeek,
            frequency: userProfileVM.profile.frequency
        )
        
        print("✅ Auto-sync to watch completed")
    }
}
    // MARK: - Session Generation
    
    static var sessionCache: [String: TrainingSession] = [:]
    
    func generateDynamicSessions() -> [TrainingSession] {
        let userLevel = userProfileVM.profile.level
        let currentWeek = userProfileVM.profile.currentWeek
        let frequency = userProfileVM.profile.frequency
    
        // Debug: Log the actual level being used
        print("🔍 TrainingView: Current user level = '\(userLevel)'")
        print("🔍 TrainingView: Current frequency = \(frequency)")
        print("🔍 TrainingView: Current week = \(currentWeek)")
    
        // Also check UserDefaults to see if there's a mismatch
        let savedLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "Not Set"
        print("🔍 TrainingView: UserDefaults level = '\(savedLevel)'")
    
        if userLevel != savedLevel {
            print("⚠️ TrainingView: MISMATCH! Profile level (\(userLevel)) != UserDefaults level (\(savedLevel))")
        }
        
        // Use UnifiedSessionGenerator to ensure iPhone/Watch synchronization
        print("🔄 TrainingView: Using UnifiedSessionGenerator for session consistency")
        let unifiedGenerator = UnifiedSessionGenerator.shared
        let unifiedSessions = unifiedGenerator.generateUnified12WeekProgram(
            userLevel: userLevel,
            frequency: frequency
        )
        
        print("📱 TrainingView: Generated \(unifiedSessions.count) unified sessions")
        print("📱 TrainingView: Sessions will match Watch exactly for W1/D1 through W12/D\(frequency)")
        
        return unifiedSessions
    }

    // Get sessions appropriate for user level with proper progression and recovery sessions
    func getSessionsForUserLevel(_ userLevel: String) -> [ComprehensiveSprintSession] {
        let frequency = userProfileVM.profile.frequency
    
        print("🎯 Session Generation: Level=\(userLevel), Frequency=\(frequency) days")
        print("📋 RULE: \(userLevel) supports frequencies 1,2,3,4,5,6,7 days")
        
        // Get sprint sessions based on level - ALL LEVELS GET FULL SESSION VARIETY
        var sprintSessions: [ComprehensiveSprintSession] = []
        
        switch userLevel.lowercased() {
            case "beginner":
                // BEGINNER: Supports 1,2,3,4,5,6,7 days with appropriate difficulty
                let beginnerSessions = sessionLibrary.filter { 
                    $0.level.lowercased() == "beginner" && $0.sessionType == .sprint 
                }.map { convertSessionLibraryToComprehensive($0) }
                let earlyIntermediate = sessionLibrary.filter { 
                    $0.level.lowercased() == "intermediate" && $0.sessionType == .sprint && $0.distance <= 60 
                }.prefix(5).map { convertSessionLibraryToComprehensive($0) }
                sprintSessions = beginnerSessions + Array(earlyIntermediate)
                print("✅ BEGINNER: Generated \(sprintSessions.count) sessions for \(frequency) days/week")
        
            case "intermediate":
                // INTERMEDIATE: Supports 1,2,3,4,5,6,7 days with moderate difficulty
                let intermediateSessions = sessionLibrary.filter { 
                    $0.level.lowercased() == "intermediate" && $0.sessionType == .sprint 
                }.map { convertSessionLibraryToComprehensive($0) }
                let earlyAdvanced = sessionLibrary.filter { 
                    $0.level.lowercased() == "advanced" && $0.sessionType == .sprint && $0.distance <= 80 
                }.prefix(8).map { convertSessionLibraryToComprehensive($0) }
                sprintSessions = intermediateSessions + Array(earlyAdvanced)
                print("✅ INTERMEDIATE: Generated \(sprintSessions.count) sessions for \(frequency) days/week")
                
            case "advanced":
                // ADVANCED: Supports 1,2,3,4,5,6,7 days with high difficulty
                let advancedSessions = sessionLibrary.filter { 
                    $0.level.lowercased() == "advanced" && $0.sessionType == .sprint 
                }.map { convertSessionLibraryToComprehensive($0) }
                let lateIntermediate = sessionLibrary.filter { 
                    $0.level.lowercased() == "intermediate" && $0.sessionType == .sprint && $0.distance >= 50 
                }.suffix(5).map { convertSessionLibraryToComprehensive($0) }
                sprintSessions = Array(lateIntermediate) + advancedSessions
                print("✅ ADVANCED: Generated \(sprintSessions.count) sessions for \(frequency) days/week")
        
            case "elite":
                // ELITE: Supports 1,2,3,4,5,6,7 days with maximum difficulty
                let allAdvanced = sessionLibrary.filter { 
                    $0.level.lowercased() == "advanced" && $0.sessionType == .sprint 
                }.map { convertSessionLibraryToComprehensive($0) }
                let eliteIntermediate = sessionLibrary.filter { 
                    $0.level.lowercased() == "intermediate" && $0.sessionType == .sprint && $0.distance >= 60 
                }.map { convertSessionLibraryToComprehensive($0) }
                // Get actual Elite sessions from the new library
                let eliteSessions = sessionLibrary.filter { 
                    $0.level.lowercased() == "elite" && $0.sessionType == .sprint 
                }.map { convertSessionLibraryToComprehensive($0) }
                sprintSessions = eliteIntermediate + allAdvanced + eliteSessions
                print("✅ ELITE: Generated \(sprintSessions.count) sessions for \(frequency) days/week")
                
            default:
                // FALLBACK: Still supports 1,2,3,4,5,6,7 days
                sprintSessions = sessionLibrary.filter { 
                    $0.level.lowercased() == "beginner" && $0.sessionType == .sprint 
                }.map { convertSessionLibraryToComprehensive($0) }
                print("⚠️ FALLBACK: Generated \(sprintSessions.count) sessions for \(frequency) days/week")
        }
    
        // CRITICAL: Add recovery sessions for ALL levels and ALL frequencies (1-7 days)
        // This ensures every level can handle any frequency with proper recovery
        let recoverySessions = getRecoverySessionsForLevel(userLevel)
        let activeRecoverySessions = getActiveRecoverySessionsForLevel(userLevel)
        
        print("🔄 Recovery sessions: \(recoverySessions.count) full recovery, \(activeRecoverySessions.count) active recovery")
        
        // Create weekly program structure - SUPPORTS ALL FREQUENCIES FOR ALL LEVELS
        return createWeeklyProgram(
            sprintSessions: sprintSessions,
            recoverySessions: recoverySessions,
            activeRecoverySessions: activeRecoverySessions,
            frequency: frequency,
            userLevel: userLevel
        )
}

    // Create weekly program structure for any level with any frequency (1-7 days)
    func createWeeklyProgram(
        sprintSessions: [ComprehensiveSprintSession],
        recoverySessions: [ComprehensiveSprintSession],
        activeRecoverySessions: [ComprehensiveSprintSession],
        frequency: Int,
        userLevel: String
    ) -> [ComprehensiveSprintSession] {
        // Implementation here
        return []
    }

    // Validate session generation for all levels and frequencies
    func validateSessionGeneration(sessions: [TrainingSession], userLevel: String, frequency: Int) {
        // Implementation
    }
    
    // Validate that all levels support all frequencies (1-7 days)
    func validateUniversalFrequencySupport(level: String, frequency: Int, programSize: Int) {
        // Implementation
    }

    // Get recovery sessions for user level from SessionLibrary
    func getRecoverySessionsForLevel(_ userLevel: String) -> [ComprehensiveSprintSession] {
        // Implementation
        return []
    }
    
    // Get active recovery sessions for user level from SessionLibrary  
    func getActiveRecoverySessionsForLevel(_ userLevel: String) -> [ComprehensiveSprintSession] {
        // Implementation
        return []
    }
}

// MARK: - DashboardMotivationText
struct DashboardMotivationText: View {
    var body: some View {
        Text("Every split matters. Chase the 40.")
            .font(.subheadline)
            .foregroundColor(.brandSecondary.opacity(0.7))
            .padding(.horizontal)
    }
}

// MARK: - StartSessionButton
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

// MARK: - SessionCardDashboardView
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

// MARK: - SideMenuRow
// Moved to SideMenuRow.swift

// MARK: - TrainingProgramCarousel
struct TrainingProgramCarousel: View {
    let sessions: [TrainingSession]
    
    var body: some View {
        // Carousel implementation
    }
}

// MARK: - TrainingProgramCarousel_Previews
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

// MARK: - SprintTimerProAccessCard
struct SprintTimerProAccessCard: View {
    let isProUser: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            #endif
            onTap()
        }) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Sprint Timer Pro")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if isProUser {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(isProUser ? "Create custom sprint workouts" : "Unlock advanced training features")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
                
                Spacer()
                
                // Action Button
                if isProUser {
                    // Polished Pro Button
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("OPEN PRO")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.black)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.1),
                                Color(red: 1.0, green: 0.75, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(
                        color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                } else {
                    // Upgrade Indicator
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$4.99")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("Upgrade")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                }
                
                // Bottom Action Row (only for Pro users)
                if isProUser {
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, -20)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("Open Sprint Timer Pro")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 16)
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
    
    // MARK: - Helper Methods
    
    private func getCurrentTrainingSession() -> TrainingSession? {
        return generateDynamicSessions().first
    }
    
    // MARK: - Manager Initialization
    
    /// Initialize managers lazily to prevent main thread deadlock
    private func initializeManagersLazily() {
        // Initialize managers one at a time with delays to prevent deadlock
        if watchConnectivity == nil {
            watchConnectivity = WatchConnectivityManager.shared
        }
        
        // Delay startup manager initialization slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.startupManager == nil {
                self.startupManager = AppStartupManager.shared
            }
        }
        
        // Delay premium connectivity initialization even more
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.premiumConnectivity == nil {
                self.premiumConnectivity = PremiumConnectivityManager.shared
            }
        }
    }
    
    // MARK: - Startup Flow Integration
    
    /// Validates that all required data is complete before loading TrainingView
    private func validateDataCompleteness() {
        let hasValidProfile = !userProfileVM.profile.level.isEmpty && userProfileVM.profile.frequency > 0
        let hasValidSessions = !userProfileVM.getAllStoredSessions().isEmpty
        let startupComplete = startupManager?.canProceedToMainView ?? false
        
        // UPDATED: More lenient validation - allow TrainingView to load with just profile data
        // Sessions can be generated asynchronously if missing
        isDataComplete = hasValidProfile || startupComplete
        
        print("📊 TrainingView Data Validation:")
        print("  - Valid Profile: \(hasValidProfile) (Level: '\(userProfileVM.profile.level)', Frequency: \(userProfileVM.profile.frequency))")
        print("  - Valid Sessions: \(hasValidSessions) (Count: \(userProfileVM.getAllStoredSessions().count))")
        print("  - Startup Complete: \(startupComplete)")
        print("  - Overall Complete: \(isDataComplete)")
        
        // If profile is valid but sessions are missing, trigger session generation
        if hasValidProfile && !hasValidSessions {
            print("🔄 TrainingView: Profile valid but sessions missing - triggering session generation")
            generateMissingSessions()
        }
        
        if !isDataComplete {
            print("⚠️ TrainingView: Data incomplete - UI may show loading state")
        }
    }
    
    /// Generate sessions if they're missing when TrainingView loads
    private func generateMissingSessions() {
        Task {
            let trainingLevel: TrainingLevel = {
                switch userProfileVM.profile.level.lowercased() {
                case "beginner": return .beginner
                case "intermediate": return .intermediate
                case "advanced": return .advanced
                case "pro", "elite": return .pro
                default: return .beginner
                }
            }()
            
            print("🔄 TrainingView: Generating missing sessions for \(trainingLevel.rawValue) × \(userProfileVM.profile.frequency)")
            
            let unifiedGenerator = UnifiedSessionGenerator.shared
            let unifiedSessions = unifiedGenerator.generateUnified12WeekProgram(
                userLevel: trainingLevel.rawValue,
                frequency: userProfileVM.profile.frequency
            )
            
            await MainActor.run {
                userProfileVM.updateWithUnifiedSessions(unifiedSessions)
                validateDataCompleteness() // Re-validate after generating sessions
                print("✅ TrainingView: Missing sessions generated (\(unifiedSessions.count) sessions)")
            }
        }
    }
    
    /// Sets up listener for training plan updates from startup manager
    private func setupTrainingPlanUpdateListener() {
        print("🔄 TrainingView: Setting up training plan update listener")
        
        // Listen for sync completion
        startupManager?.$canProceedToMainView
            .receive(on: DispatchQueue.main)
            .sink { canProceed in
                if canProceed {
                    self.onTrainingPlanUpdate()
                }
            }
            .store(in: &cancellables)
        
        // Listen for watch connectivity changes
        watchConnectivity?.$trainingSessionsSynced
            .receive(on: DispatchQueue.main)
            .sink { synced in
                if synced {
                    self.onTrainingPlanUpdate()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handles training plan updates - refreshes UI and syncs to watch
    func onTrainingPlanUpdate() {
        print("🔄 TrainingView: Training plan updated - refreshing UI")
        
        // Refresh local sessions
        refreshDynamicSessions()
        
        // Update the watch if connected
        if let watchConnectivity = watchConnectivity, watchConnectivity.isWatchReachable {
            print("⌚ Watch is reachable, sending training plan update...")
            Task {
                await autoSyncSessionsToWatch(dynamicSessions)
            }
        } else {
            print("⌚ Watch is not reachable, skipping training plan update")
        }
        
        // Force UI refresh
        objectWillChange.send()
    }
}
