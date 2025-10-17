import SwiftUI
import Charts

// MARK: - DashboardView with Multi-Metric PerformanceView
struct DashboardView: View {
    @StateObject var userProfileVM = UserProfileViewModel()
    @State private var showMenu = false
    @State private var selectedMenu: MenuSelection = .main

    enum MenuSelection {
        case main, history, leaderboard, performanceTrends, smartHub, performance, settings, helpInfo
    }

    var body: some View {
        let profile = userProfileVM.profile
        ZStack {
            NavigationView {
                ZStack {
                    switch selectedMenu {
                    case .main:
                        AnyView(mainDashboard(profile: profile))
                    case .history:
                        AnyView(HistoryView(sessions: [], userProfile: profile)) // Using empty array until session management is resolved
                    case .leaderboard:
                        AnyView(UserStatsView(currentUser: profile))
                    case .performanceTrends:
                        AnyView(PerformanceTrendsView(weeks: [])) // TODO: Pass real data
                    case .smartHub:
                        AnyView(SmartHubView())
                    case .performance:
                        AnyView(DashboardPerformanceView(profile: profile))
                    case .settings:
                        AnyView(SettingsView())
                    case .helpInfo:
                        AnyView(HelpInfoView())
                    }
                }
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .navigationTitle("Sprint Coach 40")
                .navigationBarTitleDisplayMode(.inline)
            }
            
            if showMenu {
                HamburgerSideMenu(
                    showMenu: $showMenu,
                    onSelect: { (selection: DashboardView.MenuSelection) in
                        withAnimation { showMenu = false }
                        selectedMenu = selection
                    }
                )
                .transition(AnyTransition.move(edge: .leading))
            }
        }
    }

    // MARK: - Main Dashboard
    private func mainDashboard(profile: UserProfile) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                PersonalBestCard(
                    personalBest: profile.personalBests["40yd"] ?? profile.baselineTime,
                    date: DateFormatter.usShort.string(from: Date()),
                    competition: "Combine Trial",
                    rank: "#12 Regionally"
                )
                KeyMetricsStrip(profile: profile)
                PerformanceTrendsView(weeks: []) // Single metric chart still visible
                // TrainingProgramCarousel(sessions: profile.sessions) // Not in scope for test
                Button(action: { /* TODO: Trigger WatchConnectivity */ }) {
                    Text("Start Session on Watch")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                        .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Multi-Metric PerformanceView
struct DashboardPerformanceView: View {
    var profile: UserProfile
    @State private var isMenuOpen = false
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Hero stats
                    AnimatedHeaderView(
                        athleteName: profile.name,
                        level: "Athlete Level TBD",
                        personalRecord: 0,
                        latestTime: 0
                    )
                    // Multi-metric chart
                    MultiMetricChartView(sessions: []) // Using empty array until session management is resolved
                    Spacer(minLength: 60)
                }
            }
        }
    }
}

// MARK: - MultiMetricChartView
struct MultiMetricChartView: View {
    var sessions: [TrainingSession]
    
    struct ChartPoint: Identifiable {
        let id = UUID()
        let sessionIndex: Int
        let reaction: Double
        let acceleration: Double
        let maxVelocity: Double
        let endurance: Double
    }
    
    private var chartData: [ChartPoint] {
        sessions.suffix(10).enumerated().map { index, session in
            ChartPoint(
                sessionIndex: index + 1,
                reaction: 0,
                acceleration: 0,
                maxVelocity: 0,
                endurance: 0
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics (Last 10 Sessions)")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart {
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("Session", point.sessionIndex),
                        y: .value("Reaction", point.reaction)
                    )
                    .foregroundStyle(Color.green)
                    .symbol(Circle())
                    
                    LineMark(
                        x: .value("Session", point.sessionIndex),
                        y: .value("Acceleration", point.acceleration)
                    )
                    .foregroundStyle(Color.blue)
                    
                    LineMark(
                        x: .value("Session", point.sessionIndex),
                        y: .value("Max Velocity", point.maxVelocity)
                    )
                    .foregroundStyle(Color.yellow)
                    
                    LineMark(
                        x: .value("Session", point.sessionIndex),
                        y: .value("Endurance", point.endurance)
                    )
                    .foregroundStyle(Color.orange)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

// MARK: - AnimatedHeaderView
struct AnimatedHeaderView: View {
    let athleteName: String
    let level: String
    let personalRecord: Double
    let latestTime: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(athleteName).font(.title2).bold().foregroundColor(.white)
            Text(level).font(.subheadline).foregroundColor(.gray)
            HStack {
                Text("PR: \(String(format: "%.2f s", personalRecord))")
                    .font(.largeTitle).bold()
                    .foregroundColor(.green)
                Spacer()
                Text("Latest: \(String(format: "%.2f s", latestTime))")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.2)))
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
