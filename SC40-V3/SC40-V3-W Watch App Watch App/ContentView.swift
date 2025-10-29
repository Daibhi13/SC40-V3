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
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                SessionCardsView()
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "figure.run")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(.yellow)
                    .scaleEffect(animate ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
                
                VStack(spacing: 4) {
                    Text("Sprint Coach 40")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text("Apple Watch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            animate = true
        }
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
            // Remove START button - use tap-to-start
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
                            selectedSession = session
                            showWorkout = true
                        }
                }
            }
            #if os(watchOS)
            .tabViewStyle(.page)
            #else
            .tabViewStyle(PageTabViewStyle())
            #endif
            .background(
                // Match phone app TrainingView gradient exactly
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
            )
            .navigationTitle("") // Remove title to fix overlap
            .navigationBarHidden(false) // Show navigation bar for sync testing button
            .toolbar {
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
        .sheet(isPresented: $showSprintTimerPro) {
            SprintTimerProWatchView()
        }
        .sheet(isPresented: $showWorkout) {
            if let session = selectedSession {
                MainProgramWorkoutWatchView(session: session)
            } else {
                Text("Loading Workout...")
                    .foregroundColor(.white)
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
        .onAppear {
            // WATCH APP STARTUP: Ensure profile data is current
            print("🔄 Watch: SessionCardsView appeared - checking for profile updates")
            
            // Request fresh session data from iPhone
            sessionManager.requestTrainingSessionsFromPhone()
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
    @State private var userLevel: String = "Intermediate"
    @State private var userName: String = "User"
    @State private var frequency: Int = 3
    @State private var personalBest: Double = 0.0
    @State private var currentWeek: Int = 1
    
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
            
            // Main profile content - DYNAMIC from UserDefaults
            VStack(spacing: 8) {
                Text(userName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(userLevel.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.cyan)
                    .lineLimit(1)
                
                Text("\(frequency) days/week")
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
        userLevel = UserDefaults.standard.string(forKey: "SC40_UserLevel") ?? 
                   UserDefaults.standard.string(forKey: "userLevel") ?? "Intermediate"
        userName = UserDefaults.standard.string(forKey: "SC40_UserName") ?? 
                  UserDefaults.standard.string(forKey: "user_name") ?? "SC40 Athlete"
        frequency = UserDefaults.standard.integer(forKey: "SC40_UserFrequency") > 0 ? 
                   UserDefaults.standard.integer(forKey: "SC40_UserFrequency") : 
                   (UserDefaults.standard.integer(forKey: "trainingFrequency") > 0 ? 
                    UserDefaults.standard.integer(forKey: "trainingFrequency") : 3)
        personalBest = UserDefaults.standard.double(forKey: "SC40_TargetTime") > 0 ?
                      UserDefaults.standard.double(forKey: "SC40_TargetTime") :
                      UserDefaults.standard.double(forKey: "personalBest40yd")
        currentWeek = UserDefaults.standard.integer(forKey: "SC40_CurrentWeek") > 0 ?
                     UserDefaults.standard.integer(forKey: "SC40_CurrentWeek") : 1
        
        print("🔄 Watch: Profile refreshed - Name: \(userName), Level: \(userLevel), Frequency: \(frequency) days, PB: \(personalBest)s, Week: \(currentWeek)")
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
            
            // Main content with live session data
            VStack(spacing: 4) {
                Text(session.type)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                
                Text(session.focus)
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
    
    // Format sprint information dynamically
    private func formatSessionSprints(_ sprints: [SprintSet]) -> String {
        guard !sprints.isEmpty else { return "No Sprints" }
        
        // Get the main sprint set (usually the longest distance or highest reps)
        let mainSprint = sprints.max { first, second in
            // Prioritize by distance first, then by reps
            if first.distanceYards != second.distanceYards {
                return first.distanceYards < second.distanceYards
            }
            return first.reps < second.reps
        }
        
        if let sprint = mainSprint {
            return "\(sprint.reps)x\(sprint.distanceYards)yd"
        }
        
        return "Mixed Sprints"
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
