
import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @State private var selectedTab: AnalyticsTab = .performance
    @State private var selectedSport: SportType = .soccer
    @State private var showContent = false
    @State private var completedSessions: [TrainingSession] = []
    
    // Computed property to get actual personal best from user profile
    private var personalBest: Double {
        userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime
    }
    @State private var averageTime: Double = 0.0
    @State private var totalSprints: Int = 0
    @State private var weeklyYards: Int = 0
    @State private var improvementRate: Double = 0.0
    @State private var consistencyScore: Double = 0.0
    @State private var maxVelocity: Double = 0.0
    
    enum AnalyticsTab: String, CaseIterable {
        case performance = "Performance"
        case biomechanics = "Biomechanics"
        case benchmarks = "Benchmarks"
        case aiInsights = "AI Insights"
    }
    
    enum SportType: String, CaseIterable {
        case soccer = "Soccer/Football"
        case rugby = "Rugby"
        case americanFootball = "American Football"
        case basketball = "Basketball"
        case tennis = "Tennis"
        case trackField = "Track & Field"
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background matching your design
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                    .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                    .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                    .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                    .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with Personal Best - matching your design exactly
                    VStack(spacing: 20) {
                        // Personal Best Section
                        VStack(spacing: 12) {
                            Text("PERSONAL BEST")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(2)
                            
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: "%.2fs", personalBest))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                    
                                    Text("40 Yard Dash")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text("Avg")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                        Text(averageTime > 0 ? String(format: "%.2f", averageTime) : "--")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text("Consistency")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                        Text(String(format: "%.1f%%", consistencyScore))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(consistencyScore >= 85 ? .green : consistencyScore >= 70 ? .orange : .red)
                                    }
                                }
                            }
                        }
                        
                        // Stats Grid - matching your design
                        HStack(spacing: 12) {
                            AnalyticsStatCard(
                                icon: "bolt.fill",
                                value: "\(totalSprints)",
                                label: "Total Sprints",
                                showContent: showContent
                            )
                            
                            AnalyticsStatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                value: "\(weeklyYards)",
                                label: "Weekly Yards",
                                showContent: showContent
                            )
                            
                            AnalyticsStatCard(
                                icon: improvementRate >= 0 ? "arrow.up.right" : "arrow.down.right",
                                value: String(format: "%.1f%%", abs(improvementRate)),
                                label: "Improvement",
                                showContent: showContent,
                                valueColor: improvementRate >= 0 ? .green : .red
                            )
                            
                            AnalyticsStatCard(
                                icon: "speedometer",
                                value: maxVelocity > 0 ? String(format: "%.1f", maxVelocity) : "--",
                                label: "Max Velocity",
                                showContent: showContent
                            )
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    
                    // Tab Selection - Fixed layout to prevent truncation
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TabButton(
                                title: "Performance",
                                icon: "chart.line.uptrend.xyaxis",
                                isSelected: selectedTab == .performance,
                                action: { 
                                    HapticManager.shared.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedTab = .performance 
                                    }
                                }
                            )
                            
                            TabButton(
                                title: "Biomechanics",
                                icon: "waveform.path.ecg",
                                isSelected: selectedTab == .biomechanics,
                                action: { 
                                    HapticManager.shared.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedTab = .biomechanics 
                                    }
                                }
                            )
                            
                            TabButton(
                                title: "Benchmarks",
                                icon: "target",
                                isSelected: selectedTab == .benchmarks,
                                action: { 
                                    HapticManager.shared.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedTab = .benchmarks 
                                    }
                                }
                            )
                            
                            TabButton(
                                title: "AI Insights",
                                icon: "brain.head.profile",
                                isSelected: selectedTab == .aiInsights,
                                action: { 
                                    HapticManager.shared.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedTab = .aiInsights 
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 30)
                    
                    // Content based on selected tab
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .performance:
                            PerformanceTabContent(showContent: showContent)
                        case .biomechanics:
                            BiomechanicsTabContent(showContent: showContent)
                        case .benchmarks:
                            BenchmarksTabContent(selectedSport: $selectedSport, showContent: showContent)
                        case .aiInsights:
                            AIInsightsTabContent(showContent: showContent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            loadAnalyticsData()
            showContent = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionCompleted)) { _ in
            loadAnalyticsData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchWorkoutReceived)) { _ in
            loadAnalyticsData()
        }
    }
    
    // MARK: - Data Loading Functions
    
    private func loadAnalyticsData() {
        // Load completed sessions from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "completedSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            completedSessions = sessions.filter { $0.isCompleted }
        }
        
        // Personal best is now loaded from user profile via computed property
        
        calculateAnalytics()
    }
    
    private func calculateAnalytics() {
        guard !completedSessions.isEmpty else {
            // Set default values when no data
            averageTime = personalBest
            totalSprints = 0
            weeklyYards = 0
            improvementRate = 0.0
            consistencyScore = personalBest > 0 ? 100.0 : 0.0
            maxVelocity = personalBest > 0 ? calculateVelocityFromTime(personalBest) : 0.0
            return
        }
        
        // Calculate total sprints
        totalSprints = completedSessions.reduce(0) { total, session in
            total + session.sprints.reduce(0) { $0 + $1.reps }
        }
        
        // Calculate weekly yards (last 7 days)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessions = completedSessions.filter { session in
            guard let completionDate = session.completionDate else { return false }
            return completionDate >= weekAgo
        }
        
        weeklyYards = recentSessions.reduce(0) { total, session in
            total + session.sprints.reduce(0) { $0 + ($1.distanceYards * $1.reps) }
        }
        
        // Calculate average time from all sprint times
        let allSprintTimes = completedSessions.flatMap { $0.sprintTimes }.filter { $0 > 0 }
        if !allSprintTimes.isEmpty {
            averageTime = allSprintTimes.reduce(0, +) / Double(allSprintTimes.count)
            
            // Calculate consistency score (inverse of coefficient of variation)
            let mean = averageTime
            let variance = allSprintTimes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(allSprintTimes.count)
            let standardDeviation = sqrt(variance)
            let coefficientOfVariation = standardDeviation / mean
            consistencyScore = max(0, (1 - coefficientOfVariation) * 100)
        } else {
            averageTime = personalBest
            consistencyScore = personalBest > 0 ? 100.0 : 0.0
        }
        
        // Calculate improvement rate (comparing first month to last month)
        if completedSessions.count >= 4 {
            let sortedSessions = completedSessions.sorted { 
                ($0.completionDate ?? Date.distantPast) < ($1.completionDate ?? Date.distantPast) 
            }
            
            let firstQuarter = Array(sortedSessions.prefix(sortedSessions.count / 4))
            let lastQuarter = Array(sortedSessions.suffix(sortedSessions.count / 4))
            
            let firstTimes = firstQuarter.flatMap { $0.sprintTimes }.filter { $0 > 0 }
            let lastTimes = lastQuarter.flatMap { $0.sprintTimes }.filter { $0 > 0 }
            
            let firstAvg = firstTimes.isEmpty ? 0 : firstTimes.reduce(0, +) / Double(firstTimes.count)
            let lastAvg = lastTimes.isEmpty ? 0 : lastTimes.reduce(0, +) / Double(lastTimes.count)
            
            if firstAvg > 0 && lastAvg > 0 {
                improvementRate = ((firstAvg - lastAvg) / firstAvg) * 100 // Negative time change is positive improvement
            }
        }
        
        // Calculate max velocity from personal best
        maxVelocity = personalBest > 0 ? calculateVelocityFromTime(personalBest) : 0.0
    }
    
    private func calculateVelocityFromTime(_ time: Double) -> Double {
        // 40 yards = 36.576 meters
        // Velocity = distance / time
        let distanceMeters = 36.576
        let velocityMPS = distanceMeters / time
        let velocityMPH = velocityMPS * 2.237 // Convert m/s to mph
        return velocityMPH
    }

}

// MARK: - Analytics Stat Card Component

struct AnalyticsStatCard: View {
    let icon: String
    let value: String
    let label: String
    let showContent: Bool
    let valueColor: Color?
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(valueColor ?? .white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(0.3), value: showContent)
    }
    
    init(icon: String, value: String, label: String, showContent: Bool, valueColor: Color? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.showContent = showContent
        self.valueColor = valueColor
    }
}

// MARK: - Performance Analytics View

struct PerformanceAnalyticsView: View {
    let showContent: Bool
    @State private var progressData: [VelocityPoint] = []
    @State private var distributionData: [PerformanceZone] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Performance Progression Card
            AnalyticsCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Performance Progression",
                iconColor: .green,
                showContent: showContent,
                delay: 0.7
            ) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Improvement Rate")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("0.0%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Sessions Tracked")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("0")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Interactive Performance Chart
                    if progressData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Complete more sessions to see your progress")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 120)
                    } else {
                        Chart(progressData) { point in
                            LineMark(
                                x: .value("Session", point.session),
                                y: .value("Time", point.time)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.4, blue: 0.4), .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Session", point.session),
                                y: .value("Time", point.time)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.2))
                                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel()
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.2))
                                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel(format: FloatingPointFormatStyle<Double>().precision(.fractionLength(2)))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .frame(height: 120)
                        .animation(.easeInOut(duration: 1.0), value: progressData)
                    }
                }
            }
            
            // Performance Distribution Card
            AnalyticsCard(
                icon: "chart.bar.fill",
                title: "Performance Distribution",
                iconColor: .purple,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 16) {
                    Text("Sprint Time Zones")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Interactive Distribution Chart
                    if distributionData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Complete more sprints to see distribution")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 100)
                    } else {
                        Chart(distributionData) { zone in
                            BarMark(
                                x: .value("Zone", zone.name),
                                y: .value("Count", zone.count)
                            )
                            .foregroundStyle(zone.color.gradient)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.2))
                                AxisValueLabel()
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .frame(height: 100)
                        .animation(.easeInOut(duration: 1.0), value: distributionData)
                    }
                }
            }
        }
        .onAppear {
            loadPerformanceData()
        }
    }
    
    private func loadPerformanceData() {
        // Load completed sessions for chart data
        if let data = UserDefaults.standard.data(forKey: "completedSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            
            let completedSessions = sessions.filter { $0.isCompleted && !$0.sprintTimes.isEmpty }
            
            // Generate progress data
            progressData = completedSessions.enumerated().compactMap { index, session in
                let bestTime = session.sprintTimes.filter { $0 > 0 }.min()
                return bestTime.map { VelocityPoint(session: index + 1, time: $0) }
            }
            
            // Generate distribution data
            let allTimes = completedSessions.flatMap { $0.sprintTimes }.filter { $0 > 0 }
            if !allTimes.isEmpty {
                let personalBest = allTimes.min() ?? 0
                let zones = [
                    PerformanceZone(name: "Elite", count: allTimes.filter { $0 <= personalBest + 0.1 }.count, color: .green),
                    PerformanceZone(name: "Advanced", count: allTimes.filter { $0 > personalBest + 0.1 && $0 <= personalBest + 0.2 }.count, color: .blue),
                    PerformanceZone(name: "Intermediate", count: allTimes.filter { $0 > personalBest + 0.2 && $0 <= personalBest + 0.3 }.count, color: .orange),
                    PerformanceZone(name: "Beginner", count: allTimes.filter { $0 > personalBest + 0.3 }.count, color: .red)
                ]
                distributionData = zones.filter { $0.count > 0 }
            }
        }
    }
}

// MARK: - Data Structures for Charts

struct VelocityPoint: Identifiable, Equatable {
    let id = UUID()
    let session: Int
    let time: Double
}

struct PerformanceZone: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let count: Int
    let color: Color
}

// MARK: - Biomechanics Analytics View

struct BiomechanicsAnalyticsView: View {
    let showContent: Bool
    @State private var velocityData: [VelocityPoint] = []
    @State private var peakVelocity: Double = 0.0
    @State private var avgVelocity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Velocity Profile Card
            AnalyticsCard(
                icon: "waveform.path.ecg",
                title: "Velocity Profile",
                iconColor: .purple,
                showContent: showContent,
                delay: 0.7
            ) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Peak Velocity")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text(peakVelocity > 0 ? String(format: "%.1f mph", peakVelocity) : "-- mph")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Avg Velocity")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text(avgVelocity > 0 ? String(format: "%.1f mph", avgVelocity) : "-- mph")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Interactive Velocity Profile
                    if velocityData.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Complete more sessions to see velocity profile")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 100)
                    } else {
                        Chart(velocityData) { point in
                            LineMark(
                                x: .value("Session", point.session),
                                y: .value("Velocity", point.time) // Using time field for velocity
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Session", point.session),
                                y: .value("Velocity", point.time)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.2))
                                AxisValueLabel()
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.white.opacity(0.2))
                                AxisValueLabel(format: FloatingPointFormatStyle<Double>().precision(.fractionLength(1)))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .frame(height: 100)
                        .animation(.easeInOut(duration: 1.0), value: velocityData)
                    }
                }
            }
            
            // Performance Metrics Card
            AnalyticsCard(
                icon: "speedometer",
                title: "Performance Metrics",
                iconColor: .orange,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 12) {
                    PerformanceMetricRow(
                        title: "Max Velocity",
                        value: peakVelocity > 0 ? String(format: "%.1f mph", peakVelocity) : "-- mph",
                        change: "--",
                        isPositive: true,
                        color: .purple
                    )
                    
                    PerformanceMetricRow(
                        title: "Consistency Score",
                        value: "100.0%",
                        change: "100%",
                        isPositive: true,
                        color: .green
                    )
                    
                    PerformanceMetricRow(
                        title: "Weekly Volume",
                        value: "\(calculateWeeklyVolume()) yards",
                        change: "--",
                        isPositive: true,
                        color: .orange
                    )
                }
            }
        }
        .onAppear {
            loadBiomechanicsData()
        }
    }
    
    private func loadBiomechanicsData() {
        // Load completed sessions for velocity calculations
        if let data = UserDefaults.standard.data(forKey: "completedSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            
            let completedSessions = sessions.filter { $0.isCompleted && !$0.sprintTimes.isEmpty }
            
            // Calculate velocities from sprint times
            let allTimes = completedSessions.flatMap { $0.sprintTimes }.filter { $0 > 0 }
            if !allTimes.isEmpty {
                let velocities = allTimes.map { calculateVelocityFromTime($0) }
                peakVelocity = velocities.max() ?? 0.0
                avgVelocity = velocities.reduce(0, +) / Double(velocities.count)
                
                // Generate velocity progression data
                velocityData = completedSessions.enumerated().compactMap { index, session in
                    let bestTime = session.sprintTimes.filter { $0 > 0 }.min()
                    return bestTime.map { VelocityPoint(session: index + 1, time: calculateVelocityFromTime($0)) }
                }
            }
        }
    }
    
    private func calculateVelocityFromTime(_ time: Double) -> Double {
        // 40 yards = 36.576 meters
        let distanceMeters = 36.576
        let velocityMPS = distanceMeters / time
        return velocityMPS * 2.237 // Convert m/s to mph
    }
    
    private func calculateWeeklyVolume() -> Int {
        guard let data = UserDefaults.standard.data(forKey: "completedSessions"),
              let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) else {
            return 0
        }
        
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessions = sessions.filter { session in
            guard let completionDate = session.completionDate else { return false }
            return completionDate >= weekAgo && session.isCompleted
        }
        
        return recentSessions.reduce(0) { total, session in
            total + session.sprints.reduce(0) { $0 + ($1.distanceYards * $1.reps) }
        }
    }
}

// MARK: - Benchmarks Analytics View

struct BenchmarksAnalyticsView: View {
    @Binding var selectedSport: AdvancedAnalyticsView.SportType
    let showContent: Bool
    @State private var userTime: Double = 0.0
    @State private var benchmarkData: [BenchmarkPosition] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Sport Selection Card
            AnalyticsCard(
                icon: "sportscourt.fill",
                title: "Select Your Sport",
                iconColor: .blue,
                showContent: showContent,
                delay: 0.7
            ) {
                HStack(spacing: 12) {
                    SportSelectionButton(
                        sport: .soccer,
                        selectedSport: $selectedSport,
                        icon: "⚽",
                        title: "Soccer/Football"
                    )
                    
                    SportSelectionButton(
                        sport: .rugby,
                        selectedSport: $selectedSport,
                        icon: "🏉",
                        title: "Rugby"
                    )
                    
                    SportSelectionButton(
                        sport: .americanFootball,
                        selectedSport: $selectedSport,
                        icon: "🏈",
                        title: "American Football"
                    )
                }
            }
            
            // Sport-Specific Benchmarks
            AnalyticsCard(
                icon: "figure.run",
                title: "\(selectedSport.rawValue) Benchmarks",
                iconColor: .green,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 12) {
                    ForEach(benchmarkData, id: \.position) { benchmark in
                        BenchmarkRow(
                            position: benchmark.position,
                            average: String(format: "%.2fs", benchmark.averageTime),
                            userTime: userTime > 0 ? String(format: "%.2fs", userTime) : "--",
                            percentile: benchmark.percentile
                        )
                    }
                }
            }
            
            // Performance Standards
            AnalyticsCard(
                icon: "star.fill",
                title: "Performance Standards",
                iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                showContent: showContent,
                delay: 1.1
            ) {
                VStack(spacing: 12) {
                    PerformanceStandardRow(
                        level: "Elite (Top 5%)",
                        time: "< 4.40s",
                        icon: "crown.fill",
                        color: Color(red: 1.0, green: 0.8, blue: 0.0)
                    )
                    
                    PerformanceStandardRow(
                        level: "Excellent (Top 15%)",
                        time: "4.40-4.55s",
                        icon: "star.fill",
                        color: .orange
                    )
                    
                    PerformanceStandardRow(
                        level: "Good (Top 30%)",
                        time: "4.55-4.70s",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    PerformanceStandardRow(
                        level: "Average (Top 50%)",
                        time: "4.70-4.85s",
                        icon: "minus.circle.fill",
                        color: .blue
                    )
                    
                    PerformanceStandardRow(
                        level: "Developing",
                        time: "> 4.85s",
                        icon: "arrow.up.circle.fill",
                        color: .gray
                    )
                }
            }
        }
        .onAppear {
            loadBenchmarkData()
        }
        .onChange(of: selectedSport) { _, _ in
            loadBenchmarkData()
        }
    }
    
    private func loadBenchmarkData() {
        // Load user's personal best
        userTime = UserDefaults.standard.double(forKey: "personalBest40Yard")
        if userTime == 0 {
            userTime = UserDefaults.standard.double(forKey: "personalBest")
        }
        
        // Generate benchmark data based on selected sport
        benchmarkData = getBenchmarksForSport(selectedSport)
    }
    
    private func getBenchmarksForSport(_ sport: AdvancedAnalyticsView.SportType) -> [BenchmarkPosition] {
        switch sport {
        case .soccer:
            return [
                BenchmarkPosition(position: "Winger/Forward", averageTime: 4.55, percentile: calculatePercentile(userTime: userTime, average: 4.55)),
                BenchmarkPosition(position: "Midfielder", averageTime: 4.65, percentile: calculatePercentile(userTime: userTime, average: 4.65)),
                BenchmarkPosition(position: "Defender", averageTime: 4.70, percentile: calculatePercentile(userTime: userTime, average: 4.70)),
                BenchmarkPosition(position: "Goalkeeper", averageTime: 4.80, percentile: calculatePercentile(userTime: userTime, average: 4.80))
            ]
        case .rugby:
            return [
                BenchmarkPosition(position: "Winger", averageTime: 4.45, percentile: calculatePercentile(userTime: userTime, average: 4.45)),
                BenchmarkPosition(position: "Fullback", averageTime: 4.50, percentile: calculatePercentile(userTime: userTime, average: 4.50)),
                BenchmarkPosition(position: "Centre", averageTime: 4.60, percentile: calculatePercentile(userTime: userTime, average: 4.60)),
                BenchmarkPosition(position: "Forward", averageTime: 4.85, percentile: calculatePercentile(userTime: userTime, average: 4.85))
            ]
        case .americanFootball:
            return [
                BenchmarkPosition(position: "Wide Receiver", averageTime: 4.40, percentile: calculatePercentile(userTime: userTime, average: 4.40)),
                BenchmarkPosition(position: "Running Back", averageTime: 4.45, percentile: calculatePercentile(userTime: userTime, average: 4.45)),
                BenchmarkPosition(position: "Linebacker", averageTime: 4.65, percentile: calculatePercentile(userTime: userTime, average: 4.65)),
                BenchmarkPosition(position: "Lineman", averageTime: 5.20, percentile: calculatePercentile(userTime: userTime, average: 5.20))
            ]
        default:
            return [
                BenchmarkPosition(position: "Elite", averageTime: 4.40, percentile: calculatePercentile(userTime: userTime, average: 4.40)),
                BenchmarkPosition(position: "Advanced", averageTime: 4.60, percentile: calculatePercentile(userTime: userTime, average: 4.60)),
                BenchmarkPosition(position: "Intermediate", averageTime: 4.80, percentile: calculatePercentile(userTime: userTime, average: 4.80)),
                BenchmarkPosition(position: "Beginner", averageTime: 5.20, percentile: calculatePercentile(userTime: userTime, average: 5.20))
            ]
        }
    }
    
    private func calculatePercentile(userTime: Double, average: Double) -> String {
        guard userTime > 0 else { return "--" }
        
        // Simple percentile calculation based on normal distribution
        let difference = userTime - average
        let standardDeviation = 0.3 // Approximate SD for 40-yard times
        let zScore = difference / standardDeviation
        
        // Convert z-score to percentile (simplified)
        let percentile: Int
        if zScore <= -2.0 {
            percentile = 95
        } else if zScore <= -1.5 {
            percentile = 85
        } else if zScore <= -1.0 {
            percentile = 75
        } else if zScore <= -0.5 {
            percentile = 65
        } else if zScore <= 0.0 {
            percentile = 50
        } else if zScore <= 0.5 {
            percentile = 35
        } else if zScore <= 1.0 {
            percentile = 25
        } else if zScore <= 1.5 {
            percentile = 15
        } else {
            percentile = 5
        }
        
        return "\(percentile)%"
    }
}

struct BenchmarkPosition {
    let position: String
    let averageTime: Double
    let percentile: String
}

// MARK: - AI Insights Analytics View

struct AIInsightsAnalyticsView: View {
    let showContent: Bool
    @State private var userTime: Double = 0.0
    @State private var totalSessions: Int = 0
    @State private var improvementRate: Double = 0.0
    @State private var strengths: [AIInsight] = []
    @State private var opportunities: [AIInsight] = []
    @State private var recommendations: [AIRecommendation] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Key Strengths Card
            AnalyticsCard(
                icon: "checkmark.circle.fill",
                title: "Key Strengths",
                iconColor: .green,
                showContent: showContent,
                delay: 0.7
            ) {
                VStack(spacing: 12) {
                    ForEach(strengths, id: \.text) { strength in
                        AIInsightRow(
                            icon: strength.icon,
                            text: strength.text,
                            color: strength.color
                        )
                    }
                }
            }
            
            // Growth Opportunities Card
            AnalyticsCard(
                icon: "exclamationmark.triangle.fill",
                title: "Growth Opportunities",
                iconColor: .orange,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 12) {
                    ForEach(opportunities, id: \.text) { opportunity in
                        AIInsightRow(
                            icon: opportunity.icon,
                            text: opportunity.text,
                            color: opportunity.color
                        )
                    }
                }
            }
            
            // AI Training Recommendations Card
            AnalyticsCard(
                icon: "brain.head.profile",
                title: "AI Training Recommendations",
                iconColor: .purple,
                showContent: showContent,
                delay: 1.1
            ) {
                VStack(spacing: 16) {
                    ForEach(recommendations, id: \.title) { recommendation in
                        VStack(spacing: 12) {
                            HStack {
                                Text(recommendation.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text(recommendation.priority.uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(recommendation.priorityColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(recommendation.priorityColor.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            
                            Text(recommendation.description)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadAIInsights()
        }
    }
    
    private func loadAIInsights() {
        // Load user data
        userTime = UserDefaults.standard.double(forKey: "personalBest40Yard")
        if userTime == 0 {
            userTime = UserDefaults.standard.double(forKey: "personalBest")
        }
        
        if let data = UserDefaults.standard.data(forKey: "completedSessions"),
           let sessions = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            totalSessions = sessions.filter { $0.isCompleted }.count
        }
        
        generateAIInsights()
    }
    
    private func generateAIInsights() {
        // Generate personalized strengths
        strengths = []
        
        if userTime > 0 {
            if userTime <= 4.5 {
                strengths.append(AIInsight(icon: "bolt.fill", text: "Exceptional speed - Top 10% of athletes", color: Color(red: 1.0, green: 0.8, blue: 0.0)))
            } else if userTime <= 5.0 {
                strengths.append(AIInsight(icon: "speedometer", text: "Above average speed for recreational athletes", color: .green))
            }
        }
        
        if totalSessions >= 5 {
            strengths.append(AIInsight(icon: "chart.line.uptrend.xyaxis", text: "Consistent training shows dedication to improvement", color: .blue))
        }
        
        if totalSessions >= 10 {
            strengths.append(AIInsight(icon: "target", text: "Strong training consistency builds solid foundation", color: .cyan))
        }
        
        // Generate growth opportunities
        opportunities = []
        
        if userTime > 5.0 {
            opportunities.append(AIInsight(icon: "figure.run", text: "Focus on acceleration technique for faster starts", color: .orange))
            opportunities.append(AIInsight(icon: "dumbbell.fill", text: "Strength training could significantly improve times", color: .purple))
        }
        
        if totalSessions < 5 {
            opportunities.append(AIInsight(icon: "calendar", text: "More consistent training will accelerate progress", color: .red))
        }
        
        opportunities.append(AIInsight(icon: "arrow.up.right", text: "Plyometric training will enhance explosive power", color: .pink))
        
        // Generate recommendations
        recommendations = []
        
        if userTime > 5.0 {
            recommendations.append(AIRecommendation(
                title: "Acceleration Focus",
                priority: "high",
                priorityColor: .red,
                description: "Add 3x weekly acceleration drills focusing on first 10 yards. Practice block starts and drive phase mechanics."
            ))
        }
        
        recommendations.append(AIRecommendation(
            title: "Plyometric Training",
            priority: totalSessions < 5 ? "medium" : "high",
            priorityColor: totalSessions < 5 ? .orange : .red,
            description: "Add 2x weekly box jumps, bounds, and reactive exercises to improve explosive power and sprint performance."
        ))
        
        if totalSessions >= 10 {
            recommendations.append(AIRecommendation(
                title: "Advanced Techniques",
                priority: "medium",
                priorityColor: .orange,
                description: "Focus on advanced sprint mechanics including arm swing optimization and stride frequency training."
            ))
        }
    }
}

struct AIInsight {
    let icon: String
    let text: String
    let color: Color
}

struct AIRecommendation {
    let title: String
    let priority: String
    let priorityColor: Color
    let description: String
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let sessionCompleted = Notification.Name("sessionCompleted")
    static let watchWorkoutReceived = Notification.Name("watchWorkoutReceived")
    static let personalBestFromWatch = Notification.Name("personalBestFromWatch")
}

// MARK: - Supporting Components

struct AnalyticsCard<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let showContent: Bool
    let delay: Double
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.12), location: 0.0),
                            .init(color: Color.white.opacity(0.06), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(delay), value: showContent)
    }
}

struct PerformanceMetricRow: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Text(change)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SportSelectionButton: View {
    let sport: AdvancedAnalyticsView.SportType
    @Binding var selectedSport: AdvancedAnalyticsView.SportType
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            selectedSport = sport
        }) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedSport == sport ? .blue : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedSport == sport ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedSport == sport ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct BenchmarkRow: View {
    let position: String
    let average: String
    let userTime: String
    let percentile: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(position)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(percentile)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
            }
            
            HStack {
                Text("Avg: \(average)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("•")
                    .foregroundColor(.white.opacity(0.5))
                
                Text("You: \(userTime)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
    }
}

struct PerformanceStandardRow: View {
    let level: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(level)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(time)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AIInsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Tab Button Component

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected 
                        ? LinearGradient(
                            colors: [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.5, blue: 0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.2), 
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected 
                ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.3) 
                : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Performance Tab Content

struct PerformanceTabContent: View {
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Split Analysis Card
            AnalyticsCard(
                icon: "timer",
                title: "Split Analysis",
                iconColor: Color(red: 1.0, green: 0.6, blue: 0.0),
                showContent: showContent,
                delay: 0.5
            ) {
                VStack(spacing: 12) {
                    SplitAnalysisRow(distance: "0-10yd", time: "1.84s", percentage: "95%")
                    SplitAnalysisRow(distance: "10-20yd", time: "1.21s", percentage: "95%")
                    SplitAnalysisRow(distance: "20-30yd", time: "1.31s", percentage: "95%")
                    SplitAnalysisRow(distance: "30-40yd", time: "0.89s", percentage: "95%")
                }
            }
            
            // Performance Progression Card
            AnalyticsCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Performance Progression",
                iconColor: .green,
                showContent: showContent,
                delay: 0.7
            ) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Improvement Rate")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("0.0%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Sessions Tracked")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("0")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Chart placeholder
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Complete more sessions to see\nyour progress")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 120)
                }
            }
            
            // Performance Distribution Card
            AnalyticsCard(
                icon: "chart.bar.fill",
                title: "Performance Distribution",
                iconColor: .purple,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 16) {
                    Text("Sprint Time Zones")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Chart placeholder
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Complete more sprints to see distribution")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 100)
                }
            }
            
            // Professional Reports Card - Enhanced
            AnalyticsCard(
                icon: "doc.text.fill",
                title: "Professional Reports",
                iconColor: Color(red: 1.0, green: 0.4, blue: 0.4),
                showContent: showContent,
                delay: 1.1
            ) {
                ProfessionalReportsCard()
                    .padding(.top, -10) // Adjust spacing within card
            }
        }
    }
}

// MARK: - Biomechanics Tab Content

struct BiomechanicsTabContent: View {
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Velocity Profile Card
            AnalyticsCard(
                icon: "waveform.path.ecg",
                title: "Velocity Profile",
                iconColor: .purple,
                showContent: showContent,
                delay: 0.7
            ) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Peak Velocity")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("-- mph")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Avg Velocity")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Text("-- mph")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Chart placeholder
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Complete more sessions to see\nvelocity profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 100)
                }
            }
            
            // Performance Metrics Card
            AnalyticsCard(
                icon: "speedometer",
                title: "Performance Metrics",
                iconColor: .orange,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 12) {
                    PerformanceMetricRow(
                        title: "Max Velocity",
                        value: "-- mph",
                        change: "--",
                        isPositive: true,
                        color: .purple
                    )
                    
                    PerformanceMetricRow(
                        title: "Consistency Score",
                        value: "100.0%",
                        change: "100%",
                        isPositive: true,
                        color: .green
                    )
                    
                    PerformanceMetricRow(
                        title: "Weekly Volume",
                        value: "0 yards",
                        change: "--",
                        isPositive: true,
                        color: .orange
                    )
                }
            }
        }
    }
}

// MARK: - Benchmarks Tab Content

struct BenchmarksTabContent: View {
    @Binding var selectedSport: AdvancedAnalyticsView.SportType
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Sport Selection Card
            AnalyticsCard(
                icon: "sportscourt.fill",
                title: "Select Your Sport",
                iconColor: .blue,
                showContent: showContent,
                delay: 0.7
            ) {
                HStack(spacing: 12) {
                    SportSelectionButton(
                        sport: .soccer,
                        selectedSport: $selectedSport,
                        icon: "⚽",
                        title: "Soccer/Football"
                    )
                    
                    SportSelectionButton(
                        sport: .rugby,
                        selectedSport: $selectedSport,
                        icon: "🏉",
                        title: "Rugby"
                    )
                    
                    SportSelectionButton(
                        sport: .americanFootball,
                        selectedSport: $selectedSport,
                        icon: "🏈",
                        title: "American Football"
                    )
                }
            }
            
            // Sport Benchmarks Card
            AnalyticsCard(
                icon: "figure.run",
                title: "\(selectedSport.rawValue) Benchmarks",
                iconColor: .green,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(spacing: 12) {
                    BenchmarkRow(
                        position: "Winger/Forward",
                        average: "4.55s",
                        userTime: "--",
                        percentile: "--"
                    )
                    
                    BenchmarkRow(
                        position: "Midfielder",
                        average: "4.65s",
                        userTime: "--",
                        percentile: "--"
                    )
                    
                    BenchmarkRow(
                        position: "Defender",
                        average: "4.70s",
                        userTime: "--",
                        percentile: "--"
                    )
                    
                    BenchmarkRow(
                        position: "Goalkeeper",
                        average: "4.80s",
                        userTime: "--",
                        percentile: "--"
                    )
                }
            }
            
            // Performance Standards Card
            AnalyticsCard(
                icon: "star.fill",
                title: "Performance Standards",
                iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                showContent: showContent,
                delay: 1.1
            ) {
                VStack(spacing: 12) {
                    PerformanceStandardRow(
                        level: "Elite (Top 5%)",
                        time: "< 4.40s",
                        icon: "crown.fill",
                        color: Color(red: 1.0, green: 0.8, blue: 0.0)
                    )
                    
                    PerformanceStandardRow(
                        level: "Excellent (Top 15%)",
                        time: "4.40-4.55s",
                        icon: "star.fill",
                        color: .orange
                    )
                    
                    PerformanceStandardRow(
                        level: "Good (Top 30%)",
                        time: "4.55-4.70s",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    PerformanceStandardRow(
                        level: "Average (Top 50%)",
                        time: "4.70-4.85s",
                        icon: "minus.circle.fill",
                        color: .blue
                    )
                    
                    PerformanceStandardRow(
                        level: "Developing",
                        time: "> 4.85s",
                        icon: "arrow.up.circle.fill",
                        color: .gray
                    )
                }
            }
        }
    }
}

// MARK: - AI Insights Tab Content

struct AIInsightsTabContent: View {
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Key Strengths Card
            AnalyticsCard(
                icon: "checkmark.circle.fill",
                title: "Key Strengths",
                iconColor: .green,
                showContent: showContent,
                delay: 0.7
            ) {
                VStack(spacing: 12) {
                    Text("Analysis will appear here after\ncompleting more training sessions")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(height: 60)
                }
            }
            
            // Growth Opportunities Card
            AnalyticsCard(
                icon: "exclamationmark.triangle.fill",
                title: "Growth Opportunities",
                iconColor: .orange,
                showContent: showContent,
                delay: 0.9
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    AIInsightRow(
                        icon: "arrow.up.circle.fill",
                        text: "More consistent training will\naccelerate progress",
                        color: .orange
                    )
                    
                    AIInsightRow(
                        icon: "flame.fill",
                        text: "Plyometric training will enhance\nexplosive power",
                        color: .red
                    )
                }
            }
            
            // AI Training Recommendations Card
            AnalyticsCard(
                icon: "brain.head.profile",
                title: "AI Training Recommendations",
                iconColor: .purple,
                showContent: showContent,
                delay: 1.1
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Plyometric Training")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("MEDIUM")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Text("Add 2x weekly box jumps, bounds, and reactive exercises to improve explosive power and sprint performance.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(2)
                }
            }
        }
    }
}

// MARK: - Split Analysis Row Component

struct SplitAnalysisRow: View {
    let distance: String
    let time: String
    let percentage: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(distance)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            Text(time)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            // Progress bar
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.6, blue: 0.0), Color(red: 1.0, green: 0.4, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            Text(percentage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    AdvancedAnalyticsView(userProfileVM: UserProfileViewModel())
}
