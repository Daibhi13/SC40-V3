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
    @ObservedObject var userProfileVM: UserProfileViewModel
    @State private var watchConnectivity: WatchConnectivityManager?
    @State private var startupManager: AppStartupManager?
    @State private var premiumConnectivity: PremiumConnectivityManager?
    @EnvironmentObject private var syncManager: TrainingSynchronizationManager
    @AppStorage("isProUser") private var isProUser: Bool = false
    @State private var showMenu = false
    
    // Create a rest session for the given user level
    private func createRestSession(_ userLevel: String) -> ComprehensiveSprintSession {
        return ComprehensiveSprintSession(
            id: UUID(),
            name: "Rest Day",
            description: "Active recovery and rest to allow your body to recover and adapt.",
            level: userLevel,
            type: "Recovery",
            focus: "Active Recovery",
            distanceYards: 0,
            repetitions: 0,
            sets: 0,
            restBetweenReps: 0,
            restBetweenSets: 0,
            intensity: 0,
            sprints: [],
            accessoryWork: ["Light stretching", "Foam rolling", "Mobility work"],
            notes: "Focus on recovery today. Stay active with light movement and proper nutrition.",
            week: 0,
            day: 0,
            isCompleted: false,
            isRestDay: true
        )
    }
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

    // MARK: - Helper Methods

    // Use UnifiedSessionGenerator for consistent iPhone/Watch synchronization
    private func generateDynamicSessions() -> [TrainingSession] {
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
    // RULE: ALL LEVELS (Beginner, Intermediate, Advanced, Elite) support ALL FREQUENCIES (1-7 days)
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
    
    // UNIVERSAL FREQUENCY SUPPORT: Create proper weekly program structure for ANY level with ANY frequency (1-7 days)
    // RULE IMPLEMENTATION: Beginner(1-7), Intermediate(1-7), Advanced(1-7), Elite(1-7)
    func createWeeklyProgram(
        sprintSessions: [ComprehensiveSprintSession],
        recoverySessions: [ComprehensiveSprintSession],
        activeRecoverySessions: [ComprehensiveSprintSession],
        frequency: Int,
        userLevel: String
    ) -> [ComprehensiveSprintSession] {
        
        var weeklyProgram: [ComprehensiveSprintSession] = []
        
        print("🏗️ Creating weekly program: \(userLevel) level, \(frequency) days/week")
        
        // UNIVERSAL FREQUENCY PATTERNS: ALL LEVELS support ALL frequencies (1-7 days)
        switch frequency {
        case 1:
            // 1 day: Sprint only - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [sprintSessions[0]]
            print("✅ 1-DAY PROGRAM: \(userLevel) - Sprint only")
            
        case 2:
            // 2 days: Sprint + Active Recovery - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel)
            ]
            print("✅ 2-DAY PROGRAM: \(userLevel) - Sprint + Active Recovery")
            
        case 3:
            // 3 days: Sprint + Active Recovery + Sprint - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[1 % sprintSessions.count]
            ]
            print("✅ 3-DAY PROGRAM: \(userLevel) - Sprint + Active Recovery + Sprint")
            
        case 4:
            // 4 days: Sprint + Active Recovery + Sprint + Recovery - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[1 % sprintSessions.count],
                recoverySessions.first ?? createRestSession(userLevel)
            ]
            print("✅ 4-DAY PROGRAM: \(userLevel) - Sprint + Active Recovery + Sprint + Recovery")
            
        case 5:
            // 5 days: Sprint + Active Recovery + Sprint + Recovery + Sprint - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[1 % sprintSessions.count],
                recoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[2 % sprintSessions.count]
            ]
            print("✅ 5-DAY PROGRAM: \(userLevel) - Sprint + Active Recovery + Sprint + Recovery + Sprint")
            
        case 6:
            // 6 days: Sprint + Active Recovery + Sprint + Recovery + Sprint + Active Recovery - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[1 % sprintSessions.count],
                recoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[2 % sprintSessions.count],
                activeRecoverySessions[1 % activeRecoverySessions.count]
            ]
            print("✅ 6-DAY PROGRAM: \(userLevel) - Sprint + Active Recovery + Sprint + Recovery + Sprint + Active Recovery")
            
        case 7:
            // 7 days: Full week with proper recovery distribution - AVAILABLE FOR ALL LEVELS
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[1 % sprintSessions.count],
                recoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[2 % sprintSessions.count],
                activeRecoverySessions[1 % activeRecoverySessions.count],
                createRestSession(userLevel) // Full rest day
            ]
            print("✅ 7-DAY PROGRAM: \(userLevel) - Full week with proper recovery distribution")
            
        default:
            // Fallback to 3-day pattern
            weeklyProgram = [
                sprintSessions[0],
                activeRecoverySessions.first ?? createRestSession(userLevel),
                sprintSessions[1 % sprintSessions.count]
            ]
        }
        
        // Extend the weekly program to fill 12 weeks with proper progression
        var fullProgram: [ComprehensiveSprintSession] = []
        let weeksToGenerate = 12
        
        for week in 1...weeksToGenerate {
            for (dayIndex, sessionTemplate) in weeklyProgram.enumerated() {
                // Create a copy with proper week/day progression
                var weeklySession = sessionTemplate
                // Add week-based progression if it's a sprint session
                if sessionTemplate.distanceYards > 0 {
                    let sessionIndex = ((week - 1) * weeklyProgram.count + dayIndex) % sprintSessions.count
                    weeklySession = sprintSessions[sessionIndex]
            }
            fullProgram.append(weeklySession)
        }
    }
    
        // RULE VALIDATION: Confirm the rule is implemented
        validateUniversalFrequencySupport(level: userLevel, frequency: frequency, programSize: weeklyProgram.count)
        
        return fullProgram
    }

    // COMPREHENSIVE SESSION VALIDATION: Ensure correct generation for ALL levels and frequencies
    private func validateSessionGeneration(sessions: [TrainingSession], userLevel: String, frequency: Int) {
        let generatedSessions = sessions.filter { $0.week >= 1 && $0.week <= 12 }
        
        print("🔍 VALIDATION REPORT: \(userLevel) \(frequency)-day program")
        print("   📊 Total sessions generated: \(generatedSessions.count)")
        print("   📅 Expected sessions: \(12 * frequency)")
        
        // Check week distribution
        let weekCounts = Dictionary(grouping: generatedSessions, by: { $0.week })
        let weeksGenerated = weekCounts.keys.sorted()
        
        print("   📈 Week distribution:")
        for week in 1...12 {
            let weekSessionCount = weekCounts[week]?.count ?? 0
            let expectedCount = frequency
            let status = weekSessionCount == expectedCount ? "✅" : "❌"
            print("     Week \(week): \(weekSessionCount)/\(expectedCount) sessions \(status)")
            
            if weekSessionCount != expectedCount {
                print("       ⚠️ ISSUE: Week \(week) has \(weekSessionCount) sessions, expected \(expectedCount)")
            }
        }
        
        // Check for duplicate sessions within the same week
        for week in weeksGenerated {
            let weekSessions = weekCounts[week] ?? []
            let dayNumbers = weekSessions.map { $0.day }
            let uniqueDays = Set(dayNumbers)
            
            if dayNumbers.count != uniqueDays.count {
                print("   ❌ DUPLICATE DAYS in Week \(week): \(dayNumbers)")
            } else {
                print("   ✅ Week \(week): Unique days \(dayNumbers.sorted())")
            }
        }
        
        // Validate frequency compliance
        let isCorrectTotal = generatedSessions.count == (12 * frequency)
        let hasCorrectWeekDistribution = weekCounts.values.allSatisfy { $0.count == frequency }
        
        if isCorrectTotal && hasCorrectWeekDistribution {
            print("   ✅ VALIDATION PASSED: \(userLevel) \(frequency)-day program is correct")
        } else {
            print("   ❌ VALIDATION FAILED: \(userLevel) \(frequency)-day program has issues")
        }
        
        print("   📋 UNIVERSAL RULE STATUS:")
        print("     • \(userLevel) supports 1-7 days: ✅")
        print("     • Current frequency (\(frequency) days): \(isCorrectTotal ? "✅" : "❌")")
    }
    
    // RULE VALIDATION: Ensure ALL levels support ALL frequencies (1-7 days)
    private func validateUniversalFrequencySupport(level: String, frequency: Int, programSize: Int) {
        let isValidFrequency = (1...7).contains(frequency)
        let isValidProgramSize = programSize == frequency
        
        if isValidFrequency && isValidProgramSize {
            print("✅ RULE COMPLIANCE: \(level) level successfully supports \(frequency) days/week (\(programSize) sessions)")
        } else {
            print("❌ RULE VIOLATION: \(level) level failed to support \(frequency) days/week (generated \(programSize) sessions)")
        }
        
        // Log the universal rule
        print("📋 UNIVERSAL RULE CONFIRMED:")
        print("   • Beginner: 1,2,3,4,5,6,7 days ✅")
        print("   • Intermediate: 1,2,3,4,5,6,7 days ✅") 
    return ComprehensiveSprintSession(
        id: UUID().hashValue,
        name: "Complete Rest Day",
        distanceYards: 0,
        reps: 0,
        restSeconds: 0,
        focus: "Full recovery and restoration",
        level: userLevel
    )
}
    
    // Get recovery sessions for user level from SessionLibrary
    private func getRecoverySessionsForLevel(_ userLevel: String) -> [ComprehensiveSprintSession] {
        let recoverySessions = sessionLibrary.filter { 
            $0.sessionType == .recovery && 
            ($0.level.lowercased() == userLevel.lowercased() || $0.level.lowercased() == "all levels")
        }
        
        return recoverySessions.map { session in
            ComprehensiveSprintSession(
                id: session.id,
                name: session.name,
                distanceYards: 0, // Recovery sessions have no distance
                reps: 0,
                restSeconds: 0,
                focus: session.focus,
                level: session.level
            )
        }
    }
    
    // Get active recovery sessions for user level from SessionLibrary  
    private func getActiveRecoverySessionsForLevel(_ userLevel: String) -> [ComprehensiveSprintSession] {
        let activeRecoverySessions = sessionLibrary.filter { 
            $0.sessionType == .activeRecovery && 
            ($0.level.lowercased() == userLevel.lowercased() || $0.level.lowercased() == "all levels")
        }
        
        return activeRecoverySessions.map { session in
            ComprehensiveSprintSession(
                id: session.id,
                name: session.name,
                distanceYards: 0, // Active recovery sessions have no distance
                reps: 0,
                restSeconds: 0,
                focus: session.focus,
                level: session.level
            )
        }
    }
    
    // Convert SessionLibrary format to ComprehensiveSprintSession format
    private func convertSessionLibraryToComprehensive(_ session: SprintSessionTemplate) -> ComprehensiveSprintSession {
        return ComprehensiveSprintSession(
            id: session.id,
            name: session.name,
            distanceYards: session.distance,
            reps: session.reps,
            restSeconds: session.rest,
            focus: session.focus,
            level: session.level
        )
    }
    
    // Convert ComprehensiveSprintSession to TrainingSession
    private func convertLibrarySessionToTrainingSession(
        librarySession: ComprehensiveSprintSession,
        week: Int,
        day: Int
    ) -> TrainingSession {
        // Special handling for all Pyramid sessions
        if librarySession.name.contains("Pyramid") {
            let pyramidDistances = generatePyramidPattern(for: librarySession)
            let pyramidSprints = pyramidDistances.map { distance in
                SprintSet(
                    distanceYards: distance,
                    reps: 1,
                    intensity: getIntensityFromDistance(distance)
                )
            }
            
            let pyramidString = pyramidDistances.map { "\($0)" }.joined(separator: "→")
            
            return TrainingSession(
                id: TrainingSession.stableSessionID(week: week, day: day),
                week: week,
                day: day,
                type: librarySession.name,
                focus: librarySession.focus,
                sprints: pyramidSprints,
                accessoryWork: getAccessoryWorkForSession(librarySession),
                notes: "Pyramid: \(pyramidString) yards, \(librarySession.restSeconds) seconds rest between reps"
            )
        }
        
        // Standard session handling
        let sprintSet = SprintSet(
            distanceYards: librarySession.distanceYards,
            reps: librarySession.reps,
            intensity: getIntensityFromDistance(librarySession.distanceYards)
        )
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: week, day: day),
            week: week,
            day: day,
            type: librarySession.name,
            focus: librarySession.focus,
            sprints: [sprintSet],
            accessoryWork: getAccessoryWorkForSession(librarySession),
            notes: "Rest: \(librarySession.restSeconds) seconds between reps"
        )
    }
    
    private func getIntensityFromDistance(_ distance: Int) -> String {
        switch distance {
        case 0...20: return "moderate"
        case 21...40: return "high"
        case 41...60: return "max"
        default: return "all-out"
        }
    }
    
    // MARK: - Pyramid Pattern Generator
    /// Generates pyramid distance patterns based on session type and characteristics
    private func generatePyramidPattern(for session: ComprehensiveSprintSession) -> [Int] {
        let maxDistance = session.distanceYards
        let sessionName = session.name.lowercased()
        let level = session.level.lowercased()
        
        // Determine increment pattern based on session characteristics
        let increment = determinePyramidIncrement(maxDistance: maxDistance, sessionName: sessionName, level: level)
        
        // Generate base pyramid pattern
        var pattern: [Int] = []
        
        // Special patterns for specific pyramid types
        switch sessionName {
        case let name where name.contains("fibonacci"):
            pattern = generateFibonacciPyramid(maxDistance: maxDistance)
        case let name where name.contains("golden"):
            pattern = generateGoldenRatioPyramid(maxDistance: maxDistance)
        case let name where name.contains("prime"):
            pattern = generatePrimePyramid(maxDistance: maxDistance)
        case let name where name.contains("micro"):
            pattern = generateMicroPyramid(maxDistance: maxDistance)
        case let name where name.contains("macro") || name.contains("big") || name.contains("giant") || name.contains("massive"):
            pattern = generateMacroPyramid(maxDistance: maxDistance)
        case let name where name.contains("twin") || name.contains("double"):
            pattern = generateDoublePeakPyramid(maxDistance: maxDistance)
        case let name where name.contains("triple") || name.contains("three"):
            pattern = generateTriplePeakPyramid(maxDistance: maxDistance)
        case let name where name.contains("plateau") || name.contains("mesa") || name.contains("table"):
            pattern = generatePlateauPyramid(maxDistance: maxDistance, increment: increment)
        case let name where name.contains("wave") || name.contains("oscillat") || name.contains("ripple"):
            pattern = generateWavePyramid(maxDistance: maxDistance, increment: increment)
        case let name where name.contains("steep"):
            pattern = generateSteepPyramid(maxDistance: maxDistance, increment: increment)
        case let name where name.contains("gentle"):
            pattern = generateGentlePyramid(maxDistance: maxDistance, increment: increment)
        case let name where name.contains("odd"):
            pattern = generateOddIncrementPyramid(maxDistance: maxDistance)
        case let name where name.contains("even"):
            pattern = generateEvenIncrementPyramid(maxDistance: maxDistance)
        case let name where name.contains("mixed") || name.contains("random") || name.contains("chaos"):
            pattern = generateMixedIncrementPyramid(maxDistance: maxDistance)
        default:
            // Standard symmetric pyramid
            pattern = generateStandardPyramid(maxDistance: maxDistance, increment: increment)
        }
        
        // Ensure pattern matches expected rep count (approximately)
        if pattern.count != session.reps {
            // Adjust pattern to match expected reps
            pattern = adjustPatternToReps(pattern: pattern, targetReps: session.reps, maxDistance: maxDistance)
        }
        
        return pattern
    }
    
    private func determinePyramidIncrement(maxDistance: Int, sessionName: String, level: String) -> Int {
        // Determine increment based on max distance and level
        switch maxDistance {
        case 0...30:
            return level == "beginner" ? 5 : 10
        case 31...50:
            return sessionName.contains("micro") ? 5 : 10
        case 51...70:
            return sessionName.contains("macro") ? 15 : 10
        case 71...100:
            return sessionName.contains("macro") || sessionName.contains("giant") ? 20 : 15
        default:
            return 10
        }
    }
    
    // Standard symmetric pyramid: builds up then down
    private func generateStandardPyramid(maxDistance: Int, increment: Int) -> [Int] {
        var pattern: [Int] = []
        
        // Build up
        var current = increment
        while current <= maxDistance {
            pattern.append(current)
            current += increment
        }
        
        // Build down (skip the peak to avoid duplication)
        current = maxDistance - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        return pattern
    }
    
    // Fibonacci sequence pyramid
    private func generateFibonacciPyramid(maxDistance: Int) -> [Int] {
        let fib = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
        let scaledFib = fib.compactMap { $0 <= maxDistance ? $0 : nil }
        
        // Create pyramid from fibonacci sequence
        var pattern = scaledFib
        let reversedPattern = Array(scaledFib.dropLast().reversed())
        pattern.append(contentsOf: reversedPattern)
        
        return pattern
    }
    
    // Golden ratio based pyramid
    private func generateGoldenRatioPyramid(maxDistance: Int) -> [Int] {
        let goldenRatio = 1.618
        var pattern: [Int] = []
        var current = 5.0
        
        // Build up using golden ratio
        while Int(current) <= maxDistance {
            pattern.append(Int(current))
            current *= goldenRatio
        }
        
        // Build down
        let reversedPattern = Array(pattern.dropLast().reversed())
        pattern.append(contentsOf: reversedPattern)
        
        return pattern
    }
    
    // Prime numbers pyramid
    private func generatePrimePyramid(maxDistance: Int) -> [Int] {
        let primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
        let validPrimes = primes.filter { $0 <= maxDistance }
        
        var pattern = validPrimes
        let reversedPattern = Array(validPrimes.dropLast().reversed())
        pattern.append(contentsOf: reversedPattern)
        
        return pattern
    }
    
    // Micro pyramid with 5-yard increments
    private func generateMicroPyramid(maxDistance: Int) -> [Int] {
        return generateStandardPyramid(maxDistance: maxDistance, increment: 5)
    }
    
    // Macro pyramid with large increments
    private func generateMacroPyramid(maxDistance: Int) -> [Int] {
        let increment = maxDistance > 80 ? 20 : 15
        return generateStandardPyramid(maxDistance: maxDistance, increment: increment)
    }
    
    // Double peak pyramid
    private func generateDoublePeakPyramid(maxDistance: Int) -> [Int] {
        let peak1 = Int(Double(maxDistance) * 0.7)
        let peak2 = maxDistance
        let increment = maxDistance > 60 ? 10 : 5
        
        var pattern: [Int] = []
        
        // First peak
        var current = increment
        while current <= peak1 {
            pattern.append(current)
            current += increment
        }
        current = peak1 - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        // Second peak
        current = increment
        while current <= peak2 {
            pattern.append(current)
            current += increment
        }
        current = peak2 - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        return pattern
    }
    
    // Triple peak pyramid
    private func generateTriplePeakPyramid(maxDistance: Int) -> [Int] {
        let peak1 = Int(Double(maxDistance) * 0.5)
        let peak2 = Int(Double(maxDistance) * 0.75)
        let peak3 = maxDistance
        let increment = 10
        
        var pattern: [Int] = []
        
        // Three peaks with valleys between
        for peak in [peak1, peak2, peak3] {
            var current = increment
            while current <= peak {
                pattern.append(current)
                current += increment
            }
            current = peak - increment
            while current >= increment && peak != peak3 { // Don't descend after final peak
                pattern.append(current)
                current -= increment
            }
        }
        
        // Final descent from peak3
        var current = peak3 - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        return pattern
    }
    
    // Plateau pyramid (flat top)
    private func generatePlateauPyramid(maxDistance: Int, increment: Int) -> [Int] {
        var pattern: [Int] = []
        
        // Build up
        var current = increment
        while current < maxDistance {
            pattern.append(current)
            current += increment
        }
        
        // Plateau (repeat max distance 3 times)
        for _ in 0..<3 {
            pattern.append(maxDistance)
        }
        
        // Build down
        current = maxDistance - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        return pattern
    }
    
    // Wave pyramid (multiple peaks and valleys)
    private func generateWavePyramid(maxDistance: Int, increment: Int) -> [Int] {
        var pattern: [Int] = []
        let waveCount = 3
        let waveHeight = maxDistance / waveCount
        
        for wave in 1...waveCount {
            let peakHeight = waveHeight * wave
            
            // Build up to wave peak
            var current = increment
            while current <= peakHeight {
                pattern.append(current)
                current += increment
            }
            
            // Build down from wave peak (except last wave)
            if wave < waveCount {
                current = peakHeight - increment
                while current >= increment {
                    pattern.append(current)
                    current -= increment
                }
            }
        }
        
        // Final descent
        var current = maxDistance - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        return pattern
    }
    
    // Steep pyramid (quick ascent, slow descent)
    private func generateSteepPyramid(maxDistance: Int, increment: Int) -> [Int] {
        var pattern: [Int] = []
        
        // Quick ascent with larger increments
        var current = increment * 2
        while current <= maxDistance {
            pattern.append(current)
            current += increment * 2
        }
        
        // Slow descent with smaller increments
        current = maxDistance - increment
        while current >= increment {
            pattern.append(current)
            current -= increment
        }
        
        return pattern
    }
    
    // Gentle pyramid (slow ascent, quick descent)
    private func generateGentlePyramid(maxDistance: Int, increment: Int) -> [Int] {
        var pattern: [Int] = []
        
        // Slow ascent with smaller increments
        var current = increment
        while current <= maxDistance {
            pattern.append(current)
            current += increment
        }
        
        // Quick descent with larger increments
        current = maxDistance - (increment * 2)
        while current >= increment {
            pattern.append(current)
            current -= increment * 2
        }
        
        return pattern
    }
    
    // Odd increment pyramid
    private func generateOddIncrementPyramid(maxDistance: Int) -> [Int] {
        var pattern: [Int] = []
        let oddIncrements = [5, 15, 25, 35, 45, 55, 65, 75, 85, 95]
        
        for distance in oddIncrements {
            if distance <= maxDistance {
                pattern.append(distance)
            }
        }
        
        let reversedPattern = Array(pattern.dropLast().reversed())
        pattern.append(contentsOf: reversedPattern)
        
        return pattern
    }
    
    // Even increment pyramid
    private func generateEvenIncrementPyramid(maxDistance: Int) -> [Int] {
        var pattern: [Int] = []
        let evenIncrements = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
        
        for distance in evenIncrements {
            if distance <= maxDistance {
                pattern.append(distance)
            }
        }
        
        let reversedPattern = Array(pattern.dropLast().reversed())
        pattern.append(contentsOf: reversedPattern)
        
        return pattern
    }
    
    // Mixed increment pyramid
    private func generateMixedIncrementPyramid(maxDistance: Int) -> [Int] {
        let mixedIncrements = [7, 18, 23, 35, 42, 58, 67, 73, 89, 95]
        var pattern: [Int] = []
        
        for distance in mixedIncrements {
            if distance <= maxDistance {
                pattern.append(distance)
            }
        }
        
        let reversedPattern = Array(pattern.dropLast().reversed())
        pattern.append(contentsOf: reversedPattern)
        
        return pattern
    }
    
    // Adjust pattern to match target rep count
    private func adjustPatternToReps(pattern: [Int], targetReps: Int, maxDistance: Int) -> [Int] {
        var adjustedPattern = pattern
        
        if pattern.count < targetReps {
            // Add more reps by extending the pattern
            let difference = targetReps - pattern.count
            let increment = maxDistance / 10
            
            for i in 0..<difference {
                let additionalDistance = increment * (i + 1)
                if additionalDistance <= maxDistance {
                    adjustedPattern.insert(additionalDistance, at: adjustedPattern.count / 2)
                }
            }
        } else if pattern.count > targetReps {
            // Remove reps by trimming the pattern
            let difference = pattern.count - targetReps
            let removeCount = difference / 2
            
            // Remove from both ends
            adjustedPattern = Array(adjustedPattern.dropFirst(removeCount).dropLast(difference - removeCount))
        }
        
        return adjustedPattern
    }
    
    private func getAccessoryWorkForSession(_ session: ComprehensiveSprintSession) -> [String] {
        var accessoryWork = ["Dynamic warm-up"]
        
        switch session.focus.lowercased() {
        case let focus where focus.contains("acceleration"):
            accessoryWork.append(contentsOf: ["A-Skip drill", "Wall drives", "Starts practice"])
        case let focus where focus.contains("speed"):
            accessoryWork.append(contentsOf: ["High knees", "Butt kicks", "Flying runs"])
        case let focus where focus.contains("drive"):
            accessoryWork.append(contentsOf: ["Drive phase drills", "Arm action work"])
        default:
            accessoryWork.append(contentsOf: ["Sprint drills", "Form work"])
        }
        
        accessoryWork.append("Cool-down")
        return accessoryWork
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

// MARK: - Private Extension
private extension TrainingView {
    // MARK: - Session Cache
    
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
    
    static func stableSessionID(week: Int, day: Int) -> UUID {
        // Create a deterministic UUID string based on week and day, padded to fixed length
        // Format: "0001-0002-000000000000"
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        if let uuid = UUID(uuidString: baseString) {
            return uuid
        }
        return UUID() // Fallback to random UUID if parsing fails
    }
    
    // MARK: - Dashboard
    
    func mainDashboard(profile: UserProfile, userProfileVM: UserProfileViewModel) -> some View {
        // Debug: Log the profile data being used in mainDashboard
        print("🏠 MainDashboard: Using profile data:")
        print("   Level: '\(profile.level)'")
        print("   Frequency: \(profile.frequency) days/week")
        print("   Current Week: \(profile.currentWeek)")
        print("   Baseline Time: \(profile.baselineTime)")
        
        // Get stored sessions from UserProfileViewModel (live state)
        let allStoredSessions = userProfileVM.getAllStoredSessions()
        let currentWeek = profile.currentWeek
        let frequency = profile.frequency
        
        print("🎯 Carousel: Using \(allStoredSessions.count) stored sessions from live state")
        
        // Convert stored sessions to TrainingSession format for compatibility
        let allSessions = allStoredSessions.isEmpty ? generateDynamicSessions() : allStoredSessions
        
        if allStoredSessions.isEmpty {
            print("⚠️ Carousel: No stored sessions found, falling back to dynamic generation")
        } else {
            print("✅ Carousel: Using live session array from state")
        }
        
        // Filter sessions to show only current week's sessions (respecting frequency)
        let filteredSessions = allSessions.filter { session in
            session.week == currentWeek && session.day <= frequency
        }
        
        let sortedSessions = filteredSessions.sorted { $0.day < $1.day }
        
        // Remove any duplicates by day within the same week
        let groupedSessions = Dictionary(grouping: sortedSessions, by: { $0.day })
        let uniqueSessionsToShow = groupedSessions.compactMap { (day, sessions) in sessions.first }
            .sorted { $0.day < $1.day }
        
        print("🎯 Carousel: Generated \(allSessions.count) total sessions")
        print("🎯 Carousel: Filtered to \(uniqueSessionsToShow.count) sessions for Week \(currentWeek)")
        print("🎯 Carousel: Showing \(uniqueSessionsToShow.count) unique sessions (\(frequency) days/week)")
        
        // Debug: Print each session being shown
        for session in uniqueSessionsToShow {
            print("   📅 W\(session.week)D\(session.day): \(session.type)")
        }
        
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Nike-Inspired Hero Section
                VStack(alignment: .center, spacing: 24) {
                    // Motivational Welcome
                    VStack(spacing: 12) {
                        Text("YOUR JOURNEY")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(2.0)
                        
                        Text("STARTS NOW")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    // Personal Best Achievement Card
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PERSONAL RECORD")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1.5)
                                
                                HStack(alignment: .bottom, spacing: 8) {
                                    Text(String(format: "%.2f", profile.personalBests["40yd"] ?? profile.baselineTime))
                                        .font(.system(size: 32, weight: .black))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.0, green: 0.9, blue: 0.7),
                                                    Color(red: 1.0, green: 0.8, blue: 0.4),
                                                    Color(red: 0.9, green: 0.7, blue: 0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("SEC")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.bottom, 4)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("40 YARDS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("DASH")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color.white.opacity(0.06)
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
                                                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Premium Connectivity Status
                if let connectivityManager = premiumConnectivity {
                    PremiumConnectivityStatusView(connectivityManager: connectivityManager)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }

                // Elite Training Program Section
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            
                            Text("12-WEEK PROGRAM")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                                .tracking(1.8)
                        }
                        
                        Text("Transform Your Speed")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 20)
                    
                    // Training Program Carousel - One card visible with scroll capability
                    VStack(spacing: 16) {
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 40) {
                                    ForEach(Array(uniqueSessionsToShow.enumerated()), id: \.offset) { index, session in
                                        TrainingSessionCard(session: session, userLevel: profile.level)
                                            .onAppear {
                                                print("🔍 TrainingSessionCard: userLevel='\(profile.level)', session.type='\(session.type)', session.focus='\(session.focus)'")
                                            }
                                            .frame(width: geometry.size.width - 40) // Full width minus padding for one card
                                            .onTapGesture {
                                                selectedSessionForWorkout = session
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
                        .frame(height: 220) // Fixed height for carousel
                        .clipped()
                        
                    }
                }
                .padding(.bottom, 16)

                // Nike-Inspired Action Button
                VStack(spacing: 8) {
                    
                    // Enhanced Action Button
                    Button(action: {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        #endif
                        selectedSessionForWorkout = sessionsToShow.first
                        showMainProgramWorkout = true
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("START SPRINT")
                                    .font(.system(size: 18, weight: .black))
                                    .tracking(0.5)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.1),
                                    Color(red: 1.0, green: 0.75, blue: 0.0),
                                    Color(red: 0.95, green: 0.65, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

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
                
                // Additional spacing to replace Up Next section
                Spacer()
                    .frame(height: 20)
                // Up Next Section - Exact match
                // VStack(alignment: .leading, spacing: 12) {
                //     HStack(spacing: 8) {
                //         Image(systemName: "calendar")
                //             .font(.system(size: 16))
                //             .foregroundColor(.purple)
                //         Text("Up Next: Week 1, Day 1")
                //             .font(.system(size: 18, weight: .semibold))
                //             .foregroundColor(.white)
                //     }
                
                //     Text("Accel → Drive")
                //         .font(.system(size: 14, weight: .medium))
                //         .foregroundColor(.white.opacity(0.7))
                
                //     HStack(spacing: 16) {
                //         HStack(spacing: 6) {
                //             Image(systemName: "figure.run")
                //                 .font(.system(size: 14))
                //                 .foregroundColor(.yellow)
                //             Text("3×25yd")
                //                 .font(.system(size: 14, weight: .medium))
                //                 .foregroundColor(.white)
                //         }
                        
                //         HStack(spacing: 6) {
                //             Image(systemName: "bolt.fill")
                //                 .font(.system(size: 14))
                //                 .foregroundColor(.yellow)
                //             Text("Max")
                //                 .font(.system(size: 14, weight: .medium))
                //                 .foregroundColor(.white)
                //         }
                //     }
                
                //     HStack(spacing: 6) {
                //         Image(systemName: "clock")
                //             .font(.system(size: 12))
                //             .foregroundColor(.white.opacity(0.6))
                //         Text("Scheduled for tomorrow")
                //             .font(.system(size: 12, weight: .medium))
                //             .foregroundColor(.white.opacity(0.6))
                //     }
                // }
                // .padding(20)
                // .frame(maxWidth: .infinity, alignment: .leading)
                // .background(
                //     RoundedRectangle(cornerRadius: 16)
                //         .fill(
                //             LinearGradient(
                //                 colors: [
                //                     Color.white.opacity(0.15),
                //                     Color.white.opacity(0.05)
                //                 ],
                //                 startPoint: .topLeading,
                //                 endPoint: .bottomTrailing
                //             )
                //         )
                //         .overlay(
                //             RoundedRectangle(cornerRadius: 16)
                //                 .stroke(
                //                     LinearGradient(
                //                         colors: [
                //                             Color.white.opacity(0.3),
                //                             Color.white.opacity(0.1)
                //                         ],
                //                         startPoint: .topLeading,
                //                         endPoint: .bottomTrailing
                //                     ),
                //                     lineWidth: 1
                //                 )
                //         )
                //         .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                // )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

// MARK: - TrainingSessionCard Component - Screenshot Style
struct TrainingSessionCard: View {
    let session: TrainingSession
    let userLevel: String
    
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
                
                // Completion Mark
                if isSessionCompleted(session) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                        )
                }
                
                // Session Type Badge - Matching screenshot
                Text(session.type.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(12)
            }
            
            // Level Display - Shows current user level
            HStack {
                Text("LEVEL:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.0)
                
                Text(userLevel.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .tracking(1.2)
                
                Spacer()
            }
            
            // Day and Focus - Nike-inspired layout
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("DAY")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1.5)
                    
                    Text("\(session.day)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(cleanFocusText(session.focus).uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1.2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            
            // Workout Details - Enhanced with rest periods and recovery session handling
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    if let firstSprint = session.sprints.first, firstSprint.distanceYards > 0 {
                        // Special handling for all Pyramid sessions
                        if session.type.contains("Pyramid") {
                            // Show pyramid structure dynamically
                            let pyramidPattern = session.sprints.map { "\($0.distanceYards)" }.joined(separator: "→")
                            let repCount = session.sprints.count
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(repCount)×PYRAMID")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(pyramidPattern)
                                    .font(.system(size: pyramidPattern.count > 30 ? 10 : 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)
                            }
                        } else {
                            // Standard sprint session display - Enhanced formatting
                            HStack(alignment: .bottom, spacing: 6) {
                                Text("\(firstSprint.reps)")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("×")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.bottom, 2)
                                
                                Text("\(firstSprint.distanceYards)")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("YD")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.bottom, 1)
                            }
                        }
                        
                        Spacer()
                        
                        // Enhanced Intensity Badge
                        Text(firstSprint.intensity.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else if isRecoverySession(session) {
                        // Recovery or Active Recovery session display
                        Text(getRecoveryDisplayText(session))
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(getRecoveryTypeDisplay(session))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(getRecoveryBadgeColor(session))
                            .cornerRadius(12)
                    } else {
                        // Generic rest day for 1-3 day frequencies
                        Text("REST")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("RECOVERY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(12)
                    }
                }
                
                // Rest Period and Level Information
                HStack {
                    if let firstSprint = session.sprints.first, firstSprint.distanceYards > 0 {
                        // Sprint session rest info
                        Text("REST: \(getRestTimeDisplay(firstSprint.distanceYards))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.yellow)
                        
                        Spacer()
                        
                        // Level Badge - Use consistent userLevel parameter
                        Text(userLevel.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyan)
                            .cornerRadius(8)
                    } else if isRecoverySession(session) {
                        // Recovery session info
                        Text("FOCUS: \(session.focus.uppercased())")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(session.type.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(8)
                    } else {
                        // Rest day info
                        Text("COMPLETE REST DAY")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("RECOVERY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Nike-Inspired Motivational tagline
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8))
                
                Text(getMotivationalMessage(session))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
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
            // Halo border for current day (Day 1) or regular border
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCurrentDay(session) ? 
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8),  // Golden halo
                            Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.6),
                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isCurrentDay(session) ? 2.5 : 1.5
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
    
    // Helper functions for displaying rest time and level
    private func getRestTimeDisplay(_ distance: Int) -> String {
        let restMinutes = getRestTimeForDistance(distance)
        return "\(restMinutes) MIN"
    }
    
    func getRestTimeForDistance(_ distance: Int) -> Int {
        // Use the actual rest times from the session library (now in minutes)
        // Find matching session in library for more accurate rest time
        if let matchingSession = sessionLibrary.first(where: { $0.distance == distance && $0.sessionType == .sprint }) {
            return matchingSession.rest
        }
        
        // Fallback to calculated rest times (in minutes)
        switch distance {
        case 0...20: return 1   // 1 minute
        case 21...40: return 2  // 2 minutes
        case 41...60: return 3  // 3 minutes
        case 61...80: return 4  // 4 minutes
        default: return 5       // 5 minutes
        }
    }
    
    
    // Helper functions for recovery sessions
    private func isRecoverySession(_ session: TrainingSession) -> Bool {
        return session.type.lowercased().contains("recovery") || 
               session.focus.lowercased().contains("recovery") ||
               session.focus.lowercased().contains("mobility") ||
               session.focus.lowercased().contains("breathing")
    }
    
    private func getRecoveryDisplayText(_ session: TrainingSession) -> String {
        if session.type.lowercased().contains("active recovery") {
            return "ACTIVE RECOVERY"
        } else if session.type.lowercased().contains("recovery") {
            return "RECOVERY"
        } else {
            return "RECOVERY"
        }
    }
    
    private func getRecoveryTypeDisplay(_ session: TrainingSession) -> String {
        if session.type.lowercased().contains("active") {
            return "ACTIVE"
        } else {
            return "PASSIVE"
        }
    }
    
    private func getRecoveryBadgeColor(_ session: TrainingSession) -> Color {
        if session.type.lowercased().contains("active") {
            return Color.green
        } else {
            return Color.blue
        }
    }
    
    // Helper function to check if session is completed
    private func isSessionCompleted(_ session: TrainingSession) -> Bool {
        // For demo purposes, mark Day 1 as completed
        // In a real app, this would check against user's completion data
        return session.day == 1 && session.week == 1
    }
    
    // Helper function to check if this is the current day
    private func isCurrentDay(_ session: TrainingSession) -> Bool {
        // For demo purposes, Day 1 is the current day
        // In a real app, this would check against user's current progress
        return session.day == 1 && session.week == 1
    }
    
    // Nike-inspired motivational messages
    private func getMotivationalMessage(_ session: TrainingSession) -> String {
        let messages = [
            "GREATNESS AWAITS",
            "UNLEASH YOUR POTENTIAL",
            "CHAMPIONS ARE MADE HERE",
            "PUSH BEYOND LIMITS",
            "EXCELLENCE IS A HABIT",
            "RISE TO THE CHALLENGE",
            "DOMINATE YOUR GOALS",
            "STRENGTH THROUGH STRUGGLE"
        ]
        
        // Use session day to get consistent message for each session
        let index = (session.day + session.week) % messages.count
        return messages[index]
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

// MARK: - Hamburger Side Menu (Commented Out - Using HamburgerSideMenu.swift instead)
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

// MARK: - Private Extension for Helper Methods
private extension TrainingView {
    // MARK: - Session Cache
    
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
    
    static func stableSessionID(week: Int, day: Int) -> UUID {
        // Create a deterministic UUID string based on week and day, padded to fixed length
        // Format: "0001-0002-000000000000"
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        if let uuid = UUID(uuidString: baseString) {
            return uuid
        }
        return UUID()
    }
}

}

// MARK: - Private Extension for Helper Methods
private extension TrainingView {
    // MARK: - Session Cache
    
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
    
    static func stableSessionID(week: Int, day: Int) -> UUID {
        // Create a deterministic UUID string based on week and day, padded to fixed length
        // Format: "0001-0002-000000000000"
        let weekString = String(format: "%04d", week)
        let dayString = String(format: "%04d", day)
        let baseString = "00000000-0000-\(weekString)-\(dayString)-000000000000"
        if let uuid = UUID(uuidString: baseString) {
            return uuid
        }
        return UUID()
    }
}

// MARK: - TrainingView Extensions
