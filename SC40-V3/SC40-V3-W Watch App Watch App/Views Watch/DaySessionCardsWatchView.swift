import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// Shows available day/session cards.
struct DaySessionCardsWatchView: View {
    var onStart: (() -> Void)? = nil
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    @State private var showStarterPro = false
    @State private var showEnhanced7StageWorkout = false
    @State private var selectedSession = 0
    @State private var currentWorkoutStep = 0 // 0: MainWorkout, 1: RepLog, 2: Sprint
    @State private var showRepLog = false
    @State private var showSprintView = false
    @State private var showTimeTrialView = false
    @State private var showSprintTimerProView = false
    @State private var hasShownWelcome = false
    @State private var forceRefresh = false
    
    // Get user's training level from stored user defaults
    private var userLevel: String {
        // Get level from UserDefaults (stored when sessions are received)
        if let level = UserDefaults.standard.string(forKey: "userLevel") {
            return level.capitalized
        }
        return "Intermediate" // Default fallback
    }
    
    // Get current week from user progress
    private var currentWeek: Int {
        // Get the earliest incomplete session's week, or week 1 if all complete
        if let firstIncomplete = sessionManager.trainingSessions.first(where: { !$0.isCompleted }) {
            return firstIncomplete.week
        }
        return 1
    }
    
    // Convert TrainingSession to SessionCard for display
    private var sessionCards: [SessionCard] {
        var cards: [SessionCard] = []
        
        // Add program status card as first card
        let totalSessions = sessionManager.trainingSessions.count
        let completedSessions = sessionManager.trainingSessions.filter { $0.isCompleted }.count
        let programProgress = totalSessions > 0 ? Int((Double(completedSessions) / Double(totalSessions)) * 100) : 0
        
        // DEBUG: Log session card generation
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        print("🎯 DaySessionCardsWatchView: Generating session cards with \(totalSessions) total sessions")
        print("🎯 SESSION SOURCE: \(sessionSource)")
        
        // Show session source in UI for debugging
        if totalSessions > 0 {
            print("🎯 First session details: W\(sessionManager.trainingSessions.first?.week ?? 0)/D\(sessionManager.trainingSessions.first?.day ?? 0)")
            if let firstSession = sessionManager.trainingSessions.first {
                print("🎯 First session sprints: \(firstSession.sprints)")
            }
        }
        
        let sourceIndicator = sessionSource == "iPhone" ? "📱 iPhone" : sessionSource == "Fallback" ? "⚠️ Offline" : "❓ Unknown"
        
        let welcomeCard = SessionCard(
            title: "\(userLevel) Program",
            subtitle: "\(completedSessions)/\(totalSessions) Complete (\(programProgress)%) • \(sourceIndicator)",
            weekDay: "Week \(currentWeek)",
            type: "📊 PROGRESS"
        )
        cards.append(welcomeCard)
        
        // Always try to show user's actual training sessions first
        let availableSessions = sessionManager.trainingSessions
        
        if !availableSessions.isEmpty {
            // Smart filtering: Show sessions sequentially from current week
            // Start from current week and show next available sessions
            let upcomingSessions = availableSessions
                .filter { !$0.isCompleted }
                .sorted { ($0.week, $0.day) < ($1.week, $1.day) }
                .prefix(12) // Show next 12 sessions for better progression visibility
            
            print("🎯 Found \(upcomingSessions.count) upcoming sessions from \(availableSessions.count) total sessions")
            
            let sessionCards = upcomingSessions.map { session in
                let subtitle = createSubtitle(from: session)
                let weekDay = "W\(session.week)/D\(session.day)"
                let type = getSessionTypeIndicator(for: session)
                print("🎯 Creating card: \(weekDay) - \(session.type)")
                return SessionCard(
                    title: session.type,
                    subtitle: subtitle,
                    weekDay: weekDay,
                    type: type
                )
            }
            cards.append(contentsOf: sessionCards)
            
            print("🎯 Final session cards count: \(cards.count)")
            return cards
        } else {
            // Fallback to representative sessions from SessionLibrary while waiting for onboarding data
            let demoCards = [
                SessionCard(title: "10 yd Starts", subtitle: "8x10yd starts", weekDay: "W1/D1", type: "⚡ ACCEL"),
                SessionCard(title: "20 yd Accel", subtitle: "6x20yd accel", weekDay: "W1/D2", type: "💨 SPEED"),
                SessionCard(title: "40 yd Repeats", subtitle: "6x40yd repeats", weekDay: "W1/D3", type: "💨 SPEED"),
                SessionCard(title: "40 yd Time Trial", subtitle: "1x40yd time trial", weekDay: "W4/D1", type: "🏃‍♂️ TEST"),
                SessionCard(title: "Sprint Timer Pro", subtitle: "Custom Sprint Workouts", weekDay: "Premium", type: "👑 PRO")
            ]
            cards.append(contentsOf: demoCards)
            return cards
        }
    }
    
    // Helper function to create session subtitle from sprint sets and accessory work
    private func createSubtitle(from session: TrainingSession) -> String {
        if session.sprints.isEmpty {
            // For recovery/rest days, show accessory work
            if !session.accessoryWork.isEmpty {
                return session.accessoryWork.prefix(2).joined(separator: ", ")
            } else {
                return session.type.contains("Rest") ? "Complete rest" : "Recovery session"
            }
        }
        
        // For sprint sessions, show sprint work
        let sprintDescriptions = session.sprints.map { sprint in
            if sprint.reps == 1 {
                return "\(sprint.reps)x\(sprint.distanceYards)yd (\(sprint.intensity))"
            } else {
                return "\(sprint.reps)x\(sprint.distanceYards)yd"
            }
        }
        return sprintDescriptions.joined(separator: ", ")
    }
    
    // Helper function to get session type indicator for watch
    private func getSessionTypeIndicator(for session: TrainingSession) -> String {
        let type = session.type.lowercased()
        let focus = session.focus.lowercased()
        
        if type.contains("benchmark") || focus.contains("benchmark") || focus.contains("time trial") {
            return "🏃‍♂️ TEST"
        } else if type.contains("recovery") {
            return "🧘‍♂️ RECOVERY"
        } else if focus.contains("acceleration") || focus.contains("accel") {
            return "⚡ ACCEL"
        } else if focus.contains("max velocity") || focus.contains("top speed") {
            return "💨 SPEED"
        } else if focus.contains("speed endurance") {
            return "🔋 ENDURANCE"
        } else if session.sprints.isEmpty {
            return "🛌 REST"
        } else {
            return "🏃‍♂️ SPRINT"
        }
    }
    
    struct SessionCard: Identifiable { 
        let id = UUID()
        let title: String
        let subtitle: String
        let weekDay: String
        let type: String
    }
    
    // Create a WorkoutWatchViewModel configured with the selected session data
    private func createWorkoutViewModel() -> WorkoutWatchViewModel {
        let currentSession = sessionManager.currentWorkoutSession
        
        if let session = currentSession {
            print("✅ Creating WorkoutWatchViewModel from session: W\(session.week)/D\(session.day) - \(session.type)")
            
            // Extract distances from session sprint sets - FIXED: flatten properly
            let distances = session.sprints.flatMap { sprint in
                Array(repeating: sprint.distanceYards, count: sprint.reps)
            }
            let totalReps = distances.count
            
            print("📏 Session distances: \(distances) yards, Total reps: \(totalReps)")
            print("🔍 Session sprint sets: \(session.sprints.map { "\($0.reps)x\($0.distanceYards)yd" })")
            
            // Create workout viewmodel with real session data
            let workoutVM = WorkoutWatchViewModel(totalReps: max(1, totalReps), restTime: 120) // 2min rest default
            workoutVM.updateFromSession(distances: distances)
            
            print("🎯 Final WorkoutVM distances: \(workoutVM.repDistances)")
            return workoutVM
        } else {
            // Fallback to demo configuration
            print("ℹ️ Creating WorkoutWatchViewModel with demo configuration")
            let workoutVM = WorkoutWatchViewModel(totalReps: 5, restTime: 90) // 1.5min rest
            let demoDist = [40, 40, 30, 20, 40] // Demo distances
            workoutVM.updateFromSession(distances: demoDist) // Demo distances
            
            print("🎯 Demo WorkoutVM distances: \(workoutVM.repDistances)")
            return workoutVM
        }
    }
    
    // Create session data using SessionLibrary template data (hardcoded for watch app)
    private func createDemoSession(for index: Int) -> TrainingSession? {
        switch index {
        case 0: // "10 yd Starts" - Based on SessionLibrary ID 1: (distance: 10, reps: 8, rest: 60)
            return TrainingSession(
                id: UUID(),
                week: 1,
                day: 1,
                type: "10 yd Starts",
                focus: "Acceleration",
                sprints: [SprintSet(
                    distanceYards: 10,
                    reps: 8,
                    intensity: "95%"
                )], // Single sprint set: 8x10yd
                accessoryWork: ["Dynamic warm-up", "Cool-down stretching"]
            )
            
        case 1: // "20 yd Accel" - Based on SessionLibrary ID 3: (distance: 20, reps: 6, rest: 90)
            return TrainingSession(
                id: UUID(),
                week: 1,
                day: 2,
                type: "20 yd Accel",
                focus: "Early Acceleration",
                sprints: [SprintSet(
                    distanceYards: 20,
                    reps: 6,
                    intensity: "95%"
                )], // Single sprint set: 6x20yd
                accessoryWork: ["Flying starts", "Acceleration drills"]
            )
            
        case 2: // "40 yd Repeats" - Based on SessionLibrary ID 7: (distance: 40, reps: 6, rest: 150)
            return TrainingSession(
                id: UUID(),
                week: 1,
                day: 3,
                type: "40 yd Repeats",
                focus: "Max Speed",
                sprints: [SprintSet(
                    distanceYards: 40,
                    reps: 6,
                    intensity: "100%"
                )], // Single sprint set: 6x40yd
                accessoryWork: ["Thorough warm-up", "Speed drills"]
            )
            
        case 3: // "40 yd Time Trial" - Based on SessionLibrary ID 8: (distance: 40, reps: 1, rest: 600)
            return TrainingSession(
                id: UUID(),
                week: 4,
                day: 1,
                type: "40 yd Time Trial",
                focus: "Benchmark",
                sprints: [SprintSet(
                    distanceYards: 40,
                    reps: 1,
                    intensity: "100%"
                )], // Single sprint set: 1x40yd
                accessoryWork: ["Thorough warm-up", "Cool-down"]
            )
            
        default:
            return nil
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                mainContentView
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationDestination(isPresented: $showStarterPro) {
            StarterProWatchView()
        }
        .fullScreenCover(isPresented: $showEnhanced7StageWorkout) {
            if let currentSession = getCurrentSelectedSession() {
                Enhanced7StageWorkoutView(session: currentSession)
            } else {
                // Fallback view if no session is selected
                Text("No Session Selected")
                    .foregroundColor(.white)
                    .onAppear {
                        showEnhanced7StageWorkout = false
                    }
            }
        }
        .fullScreenCover(isPresented: $showSprintTimerProView) {
            SprintTimerProWatchView()
        }
        .focusable()
        .digitalCrownRotation(.constant(0.0), from: 0.0, through: Double(max(0, sessionCards.count - 1)), by: 1.0, sensitivity: .medium)
        .onTapGesture(count: 2) {
            handleDoubleTap()
        }
        .onAppear {
            handleViewAppear()
        }
        .onChange(of: sessionManager.trainingSessions.count) { oldCount, newCount in
            handleSessionsCountChange(oldCount: oldCount, newCount: newCount)
        }
        .onAppear {
            handleSecondAppear()
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Premium gradient background matching phone app
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.brandBackground,
                    Color.brandTertiary.opacity(0.4),
                    Color.brandAccent.opacity(0.3),
                    Color.brandBackground
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background particles for premium feel
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: CGFloat.random(in: 3...8))
                    .position(
                        x: CGFloat.random(in: 0...200),
                        y: CGFloat.random(in: 0...200)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.3),
                        value: selectedSession
                    )
            }
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ZStack(alignment: .top) {
            // Fixed positioned elements - no flexible spacing
            VStack(spacing: 0) {
                // Header section - fixed at top
                VStack(spacing: 12) {
                    headerView
                    progressIndicatorView
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                
                // Session cards - fixed position
                sessionCardsView
                    .padding(.top, 16)
                
                // Button section - fixed at bottom area
                VStack(spacing: 8) {
                    startButtonView
                    syncButtonView
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.5), radius: 2)
                
                Text("SPRINT COACH 40")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundColor(.white)
            }
            
            Text("Select Workout")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 4)
        }
    }
    
    // MARK: - Progress Indicator View
    @ViewBuilder
    private var progressIndicatorView: some View {
        if !sessionManager.trainingSessions.isEmpty {
            VStack(spacing: 6) {
                Text("Week \(currentWeek) of 12")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressGradient)
                            .frame(width: geometry.size.width * CGFloat(currentWeek) / 12.0, height: 6)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), radius: 2)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Session Cards View
    private var sessionCardsView: some View {
        let _ = print("🔍 SessionCardsView - sessionCards count: \(sessionCards.count)")
        let _ = print("🔍 SessionCardsView - sessionManager sessions: \(sessionManager.trainingSessions.count)")
        
        return Group {
            if sessionCards.isEmpty {
                // Show debug view when no cards available
                VStack(spacing: 8) {
                    Text("No Session Cards")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Sessions: \(sessionManager.trainingSessions.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Reload") {
                        // Force refresh
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, idealHeight: 110)
            } else {
                TabView(selection: $selectedSession) {
                    ForEach(sessionCards.indices, id: \.self) { idx in
                        let session = sessionCards[idx]
                        if idx == 0 {
                            WelcomeCardView(session: session, isSelected: selectedSession == idx)
                                .tag(idx)
                                .onTapGesture {
                                    handleWelcomeCardTap()
                                }
                        } else {
                            PremiumSessionCardView(session: session, isSelected: selectedSession == idx)
                                .tag(idx)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, idealHeight: 110)
                .clipped()
                .animation(.easeInOut(duration: 0.3), value: selectedSession)
            }
        }
    }
    
    // MARK: - Start Button View
    private var startButtonView: some View {
        Button(action: handleStartButtonTap) {
            HStack(spacing: 8) {
                Image(systemName: selectedSession == 0 ? "arrow.left" : "bolt.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(selectedSession == 0 ? "Swipe Left" : "Start Sprint")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(startButtonGradient)
            .cornerRadius(12)
            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sync Button View
    @ViewBuilder
    private var syncButtonView: some View {
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        if sessionSource == "Fallback" {
            Button(action: {
                print("🔄 USER FORCING IPHONE SYNC - Fallback sessions detected")
                sessionManager.forceIPhoneSessionSync()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                    Text("Sync iPhone Sessions")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Computed Properties
    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.8, blue: 0.0),
                Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var startButtonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.8, blue: 0.0),
                Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onEnded { value in
                handleSwipeGesture(value)
            }
    }
    
    // MARK: - Helper Functions
    private func getCurrentSelectedSession() -> TrainingSession? {
        let sessionIndex = selectedSession - 1
        if !sessionManager.trainingSessions.isEmpty && sessionIndex >= 0 && sessionIndex < sessionManager.trainingSessions.count {
            return sessionManager.trainingSessions[sessionIndex]
        } else {
            return createDemoSession(for: sessionIndex)
        }
    }
    
    private func handleWelcomeCardTap() {
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        if sessionSource == "Fallback" {
            print("🔄 User tapped offline indicator - forcing iPhone sync")
            sessionManager.forceIPhoneSessionSync()
        }
    }
    
    private func handleStartButtonTap() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        
        if selectedSession == 0 {
            print("➡️ Swipe Left button pressed - advancing to first session")
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedSession = 1
            }
            return
        }
        
        if selectedSession == 5 {
            print("👑 Sprint Timer Pro selected - opening custom workout creator")
            showSprintTimerProView = true
            return
        }
        
        print("🚀 Start button pressed for session: \(selectedSession)")
        
        let sessionIndex = selectedSession - 1
        let selectedSessionData: TrainingSession?
        if !sessionManager.trainingSessions.isEmpty && sessionIndex >= 0 && sessionIndex < sessionManager.trainingSessions.count {
            selectedSessionData = sessionManager.trainingSessions[sessionIndex]
            print("✅ Starting workout with real session: W\(selectedSessionData!.week)/D\(selectedSessionData!.day) - \(selectedSessionData!.type)")
        } else {
            selectedSessionData = createDemoSession(for: sessionIndex)
            print("ℹ️ Starting workout with demo session (index: \(selectedSession)): \(selectedSessionData?.type ?? "Unknown")")
        }
        
        if let session = selectedSessionData {
            WatchSessionManager.shared.setCurrentWorkoutSession(session)
        }
        
        showEnhanced7StageWorkout = true
    }
    
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        print("🔍 DaySessionCards gesture: x=\(value.translation.width), y=\(value.translation.height)")
        
        let horizontal = abs(value.translation.width) > abs(value.translation.height)
        
        if horizontal && abs(value.translation.width) > 20 {
            if value.translation.width > 20 {
                if selectedSession > 0 {
                    print("➡️ SWIPE RIGHT - previous session")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedSession -= 1
                    }
                } else {
                    print("➡️ SWIPE RIGHT - showing StarterPro")
                    showStarterPro = true
                }
            } else if value.translation.width < -20 {
                if selectedSession < sessionCards.count - 1 {
                    print("⬅️ SWIPE LEFT - next session")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedSession += 1
                    }
                } else {
                    print("⬅️ SWIPE LEFT - at last session")
                }
            }
        }
    }
    
    private func handleDoubleTap() {
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        print("🚨 EMERGENCY DOUBLE-TAP SYNC - Current source: \(sessionSource)")
        sessionManager.forceIPhoneSessionSync()
    }
    
    private func handleViewAppear() {
        print("🔍 DaySessionCardsWatchView appeared")
        print("📱 Current sessions count: \(sessionManager.trainingSessions.count)")
        
        let sessionSource = UserDefaults.standard.string(forKey: "sessionSource") ?? "Unknown"
        if sessionSource == "Fallback" {
            print("🚨 AUTO-SYNC: Detected fallback sessions on appear - forcing iPhone sync")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sessionManager.forceIPhoneSessionSync()
            }
        }
        
        if !hasShownWelcome && !sessionManager.trainingSessions.isEmpty {
            playProgramLoadedNotification()
            hasShownWelcome = true
        }
    }
    
    private func handleSessionsCountChange(oldCount: Int, newCount: Int) {
        print("🔄 Sessions count changed: \(oldCount) → \(newCount)")
        if newCount > 0 {
            print("🎯 Sessions available, UI will update automatically")
            
            if !hasShownWelcome {
                playProgramLoadedNotification()
                hasShownWelcome = true
            }
        }
    }
    
    private func handleSecondAppear() {
        if sessionManager.trainingSessions.isEmpty {
            print("🔄 No sessions available, requesting from iPhone...")
            sessionManager.forceSyncFromPhone()
        } else {
            print("✅ Sessions available (\(sessionManager.trainingSessions.count)), ready for use")
            if let lastSync = sessionManager.lastSyncTime,
               Date().timeIntervalSince(lastSync) > 300 {
                Task { @MainActor in
                    await sessionManager.requestTrainingSessions()
                }
            }
        }
        
        if sessionManager.trainingSessions.isEmpty {
            print("⚠️ No training sessions available - user may need to complete onboarding on iPhone")
        } else {
            print("✅ Using personalized sessions from SessionLibrary based on user's onboarding inputs")
            for (index, session) in sessionManager.trainingSessions.enumerated() {
                print("  Session \(index + 1): W\(session.week)/D\(session.day) - \(session.type) (\(session.focus))")
            }
        }
    }
    
    // Play notification sound and haptic when program loads on watch
    private func playProgramLoadedNotification() {
        #if os(watchOS)
        // Play haptic notification
        WKInterfaceDevice.current().play(.notification)
        print("🔔 Program loaded notification played")
        #endif
    }
}

// MARK: - Premium Session Card View

struct PremiumSessionCardView: View {
    let session: DaySessionCardsWatchView.SessionCard
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Section - Matching TrainingView phone style
            HStack {
                // Week Badge - Golden style from phone
                Text("WEEK \(extractWeek(from: session.weekDay))")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(8)
                
                Spacer()
                
                // Session Type Badge - Golden style from phone
                Text(session.type.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .cornerRadius(8)
            }
            
            // Day and Focus - Nike-inspired layout from phone
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("DAY")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1.0)
                    
                    Text("\(extractDay(from: session.weekDay))")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(session.title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            
            // Workout Details - Enhanced formatting from phone
            HStack(alignment: .center) {
                // Sprint details with phone styling
                HStack(alignment: .bottom, spacing: 3) {
                    if let reps = extractReps(from: session.subtitle) {
                        Text("\(reps)")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("×")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 1)
                        
                        if let distance = extractDistance(from: session.subtitle) {
                            Text("\(distance)")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text("YD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Intensity Badge - White style from phone
                Text("HIGH")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            // Nike-Inspired Motivational tagline
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8))
                
                Text("GREATNESS AWAITS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            // Dark purple gradient from phone TrainingView
            RoundedRectangle(cornerRadius: 12)
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
            // Halo border for selected card (golden from phone)
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? 
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
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .overlay(
            // Inner frame from phone design
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
                .padding(1)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
    
    // Helper functions to extract data from session strings
    private func extractWeek(from weekDay: String) -> String {
        if weekDay.hasPrefix("W") {
            let components = weekDay.components(separatedBy: "/")
            return String(components[0].dropFirst())
        }
        return "1"
    }
    
    private func extractDay(from weekDay: String) -> String {
        if weekDay.contains("/D") {
            let components = weekDay.components(separatedBy: "/D")
            return components.count > 1 ? components[1] : "1"
        }
        return "1"
    }
    
    private func extractReps(from subtitle: String) -> Int? {
        let pattern = #"(\d+)x"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: subtitle, range: NSRange(subtitle.startIndex..., in: subtitle)) {
            let repsString = String(subtitle[Range(match.range(at: 1), in: subtitle)!])
            return Int(repsString)
        }
        return nil
    }
    
    private func extractDistance(from subtitle: String) -> Int? {
        let pattern = #"x(\d+)yd"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: subtitle, range: NSRange(subtitle.startIndex..., in: subtitle)) {
            let distanceString = String(subtitle[Range(match.range(at: 1), in: subtitle)!])
            return Int(distanceString)
        }
        return nil
    }
}

// MARK: - Welcome Card View

struct WelcomeCardView: View {
    let session: DaySessionCardsWatchView.SessionCard
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Nike-inspired motivational header
            VStack(spacing: 4) {
                Text("YOUR JOURNEY")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1.5)
                
                Text("STARTS NOW")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Personal Best Achievement Card Style
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PROGRAM STATUS")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.0)
                        
                        Text(session.title)
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer()
                }
                
                // Progress info
                Text(session.subtitle)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
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
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            // Dark purple gradient matching phone TrainingView
            RoundedRectangle(cornerRadius: 12)
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
            // Golden halo border when selected
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? 
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
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .overlay(
            // Inner frame from phone design
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
                .padding(1)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Workout Flow View
struct WorkoutFlowView: View {
    @StateObject var workoutVM: WorkoutWatchViewModel
    @Binding var currentStep: Int
    var onComplete: () -> Void
    
    @State private var stepTimer: Timer?
    @State private var repProgressTimer: Timer?
    @State private var showMainWorkout = true
    @State private var showRepLog = false
    @State private var showSprintView = false
    @State private var currentRepIndex = 0
    
    var body: some View {
        ZStack {
            // Step 0: MainWorkoutWatchView - Show all reps progression
            if currentStep == 0 && showMainWorkout {
                MainWorkoutWatchView(workoutVM: workoutVM)
                    .onAppear {
                        // Start rep progression simulation
                        startRepProgressionSimulation()
                        
                        // Move to next view after showing all reps
                        let totalDuration = Double(workoutVM.totalReps) * 1.0 // 1 second per rep
                        startStepTimer(duration: totalDuration) {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    stopRepProgressTimer()
                                    showMainWorkout = false
                                    currentStep = 1
                                    showRepLog = true
                                }
                            }
                        }
                    }
            }
            
            // Step 1: RepLogWatchLiveView - Show rep logging
            if currentStep == 1 && showRepLog {
                RepLogWatchLiveView(workoutVM: workoutVM,
                                  horizontalTab: .constant(1),
                                  isModal: false,
                                  onDone: {})
                    .onAppear {
                        startStepTimer(duration: 4.0) {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showRepLog = false
                                    currentStep = 2
                                    showSprintView = true
                                }
                            }
                        }
                    }
            }
            
            // Step 2: SprintWatchView - Show GPS sprint tracking
            if currentStep == 2 && showSprintView {
                SprintWatchView(viewModel: workoutVM, onDismiss: {})
                    .onAppear {
                        // Simulate GPS sprint activity
                        simulateSprintActivity()
                        
                        startStepTimer(duration: 6.0) {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSprintView = false
                                    currentStep = 3
                                    // Complete the flow
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        onComplete()
                                    }
                                }
                            }
                        }
                    }
            }
        }
        .onDisappear {
            stopAllTimers()
        }
    }
    
    // Simulate progression through all reps
    private func startRepProgressionSimulation() {
        currentRepIndex = 1
        workoutVM.currentRep = 1
        
        repProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if currentRepIndex < workoutVM.totalReps {
                    currentRepIndex += 1
                    workoutVM.currentRep = currentRepIndex
                    print("📊 Progressing to rep \(currentRepIndex)/\(workoutVM.totalReps)")
                } else {
                    stopRepProgressTimer()
                    print("✅ Completed all \(workoutVM.totalReps) reps")
                }
            }
        }
    }
    
    // Simulate GPS sprint activity
    private func simulateSprintActivity() {
        // Start GPS tracking simulation
        DispatchQueue.main.async {
            workoutVM.startGPS()
            workoutVM.isRunning = true
        }
        
        // Simulate sprint completion after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            workoutVM.stopGPS()
            workoutVM.isRunning = false
            print("🏃‍♂️ GPS sprint simulation completed")
        }
    }
    
    private func startStepTimer(duration: Double, completion: @escaping @Sendable () -> Void) {
        stopStepTimer()
        stepTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            completion()
        }
    }
    
    private func stopStepTimer() {
        stepTimer?.invalidate()
        stepTimer = nil
    }
    
    private func stopRepProgressTimer() {
        repProgressTimer?.invalidate()
        repProgressTimer = nil
    }
    
    private func stopAllTimers() {
        stopStepTimer()
        stopRepProgressTimer()
    }
}

// MARK: - Preview
struct DaySessionCardsWatchView_Previews: PreviewProvider {
    static var previews: some View {
        DaySessionCardsWatchView()
    }
}

#Preview {
    DaySessionCardsWatchView()
}
