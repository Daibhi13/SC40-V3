import SwiftUI
import Charts

// MARK: - Rep Log Live View - Real-time Workout Analysis
struct RepLogLiveView: View {
    @Binding var completedReps: [RepData]
    @Binding var currentRep: Int
    @Binding var totalReps: Int
    @Binding var currentPhase: MainProgramWorkoutView.WorkoutPhase
    @State private var selectedRep: RepData?
    @State private var showDetailedAnalysis = false
    @State private var animateChart = false
    
    var body: some View {
        ZStack {
            // Background matching workout views
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.3, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    repLogHeaderView
                    
                    // Live Performance Chart
                    livePerformanceChart
                    
                    // Current Rep Analysis
                    currentRepAnalysis
                    
                    // Rep History List
                    repHistorySection
                    
                    // Performance Insights
                    performanceInsights
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
        .sheet(isPresented: $showDetailedAnalysis) {
            DetailedAnalysisView(
                completedReps: completedReps,
                onDismiss: { showDetailedAnalysis = false }
            )
        }
    }
    
    // MARK: - Header Section
    private var repLogHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REP LOG")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    Text("Live Analysis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateChart ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateChart)
                    
                    Text("LIVE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(0.5)
                }
            }
            
            // Progress Summary
            HStack {
                Text("Rep \(currentRep) of \(totalReps)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(currentPhase.title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(currentPhase.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(currentPhase.color.opacity(0.2))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Live Performance Chart
    private var livePerformanceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Trend")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showDetailedAnalysis = true
                }) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if !completedReps.isEmpty {
                // Performance Chart
                Chart(completedReps.indices, id: \.self) { index in
                    let rep = completedReps[index]
                    
                    LineMark(
                        x: .value("Rep", index + 1),
                        y: .value("Time", rep.time ?? 0)
                    )
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Rep", index + 1),
                        y: .value("Time", rep.time ?? 0)
                    )
                    .foregroundStyle(Color.green)
                    .symbolSize(60)
                    
                    if let selectedRep = selectedRep, selectedRep.id == rep.id {
                        RuleMark(x: .value("Rep", index + 1))
                            .foregroundStyle(Color.yellow)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisTick()
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisTick()
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .chartBackground { chartProxy in
                    Color.clear
                }
                .opacity(animateChart ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0), value: animateChart)
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Start your workout to see live performance data")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Current Rep Analysis
    private var currentRepAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Rep Analysis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if let lastRep = completedReps.last {
                HStack(spacing: 20) {
                    // Time
                    AnalysisMetric(
                        title: "Time",
                        value: String(format: "%.2fs", lastRep.time ?? 0),
                        trend: getTrend(for: "time"),
                        color: .green
                    )
                    
                    // Speed
                    AnalysisMetric(
                        title: "Speed",
                        value: String(format: "%.1f mph", lastRep.speed ?? 0),
                        trend: getTrend(for: "speed"),
                        color: .blue
                    )
                    
                    // Consistency
                    AnalysisMetric(
                        title: "Consistency",
                        value: "\(getConsistencyScore())%",
                        trend: getTrend(for: "consistency"),
                        color: .purple
                    )
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Complete your first rep to see analysis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Rep History Section
    private var repHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rep History")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if !completedReps.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(Array(completedReps.enumerated().reversed()), id: \.offset) { index, rep in
                        RepHistoryRow(
                            repNumber: completedReps.count - index,
                            rep: rep,
                            isSelected: selectedRep?.id == rep.id,
                            onTap: {
                                selectedRep = selectedRep?.id == rep.id ? nil : rep
                            }
                        )
                    }
                }
            } else {
                Text("No reps completed yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Performance Insights
    private var performanceInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend Analysis",
                    description: getPerformanceTrend(),
                    color: .green
                )
                
                InsightCard(
                    icon: "target",
                    title: "Consistency",
                    description: getConsistencyInsight(),
                    color: .blue
                )
                
                InsightCard(
                    icon: "lightbulb.fill",
                    title: "Recommendation",
                    description: getRecommendation(),
                    color: .yellow
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func getTrend(for metric: String) -> RepLogTrendDirection {
        guard completedReps.count >= 2 else { return .neutral }
        
        let recent = completedReps.suffix(3)
        switch metric {
        case "time":
            let times = recent.compactMap { $0.time }
            if times.count >= 2 {
                return times.last! < times.first! ? .improving : .declining
            }
        case "speed":
            let speeds = recent.compactMap { $0.speed }
            if speeds.count >= 2 {
                return speeds.last! > speeds.first! ? .improving : .declining
            }
        case "consistency":
            return getConsistencyScore() > 80 ? .improving : .declining
        default:
            break
        }
        return .neutral
    }
    
    private func getConsistencyScore() -> Int {
        guard completedReps.count >= 2 else { return 100 }
        
        let times = completedReps.compactMap { $0.time }
        guard times.count >= 2 else { return 100 }
        
        let average = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - average, 2) }.reduce(0, +) / Double(times.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = standardDeviation / average
        
        return max(0, min(100, Int((1 - coefficientOfVariation) * 100)))
    }
    
    private func getPerformanceTrend() -> String {
        guard completedReps.count >= 2 else {
            return "Complete more reps to see performance trends"
        }
        
        let times = completedReps.compactMap { $0.time }
        if times.count >= 2 {
            let improvement = times.first! - times.last!
            if improvement > 0.1 {
                return "Great improvement! You're getting faster with each rep."
            } else if improvement < -0.1 {
                return "Times are increasing. Consider adjusting rest periods."
            } else {
                return "Consistent performance. Maintaining good pace."
            }
        }
        
        return "Keep pushing! Your performance data is building."
    }
    
    private func getConsistencyInsight() -> String {
        let score = getConsistencyScore()
        if score >= 90 {
            return "Excellent consistency! Your technique is very stable."
        } else if score >= 70 {
            return "Good consistency. Minor variations in performance."
        } else {
            return "Focus on maintaining consistent form and pacing."
        }
    }
    
    private func getRecommendation() -> String {
        guard !completedReps.isEmpty else {
            return "Start your workout to receive personalized recommendations."
        }
        
        let consistency = getConsistencyScore()
        if consistency < 70 {
            return "Focus on consistent pacing rather than maximum speed."
        } else if completedReps.count >= 3 {
            let times = completedReps.suffix(3).compactMap { $0.time }
            if times.count >= 2 && times.last! > times.first! {
                return "Consider longer rest periods to maintain performance."
            }
        }
        
        return "Excellent work! Maintain this pace and form."
    }
}

// MARK: - Supporting Views

struct AnalysisMetric: View {
    let title: String
    let value: String
    let trend: RepLogTrendDirection
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Image(systemName: trend.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(trend.color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct RepHistoryRow: View {
    let repNumber: Int
    let rep: RepData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Rep number
                Text("#\(repNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .leading)
                
                // Time
                Text(String(format: "%.2fs", rep.time ?? 0))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .frame(width: 60, alignment: .leading)
                
                // Speed
                Text(String(format: "%.1f mph", rep.speed ?? 0))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 80, alignment: .leading)
                
                Spacer()
                
                // Status
                Image(systemName: rep.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(rep.isCompleted ? .green : .white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Detailed Analysis Sheet
struct DetailedAnalysisView: View {
    let completedReps: [RepData]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.2, blue: 0.35),
                        Color(red: 0.2, green: 0.25, blue: 0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Detailed charts and analysis would go here
                        Text("Detailed Analysis")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Advanced performance metrics and trends")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            }
            .navigationTitle("Performance Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum RepLogTrendDirection {
    case improving, declining, neutral
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up"
        case .declining: return "arrow.down"
        case .neutral: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .neutral: return .gray
        }
    }
}

// RepData extension removed - speed property now defined in RepData.swift

#Preview {
    RepLogLiveView(
        completedReps: .constant([
            RepData(rep: 1, time: 5.2, isCompleted: true, repType: .sprint, distance: 40, timestamp: Date()),
            RepData(rep: 2, time: 5.1, isCompleted: true, repType: .sprint, distance: 40, timestamp: Date()),
            RepData(rep: 3, time: 5.3, isCompleted: true, repType: .sprint, distance: 40, timestamp: Date())
        ]),
        currentRep: .constant(4),
        totalReps: .constant(6),
        currentPhase: .constant(.sprints)
    )
}
