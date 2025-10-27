import SwiftUI
import Algorithms

/// View displaying algorithmic insights and optimizations for user workouts
struct AlgorithmicInsightsView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @StateObject private var optimizer = AlgorithmicWorkoutOptimizer.shared
    @StateObject private var analytics = AlgorithmicAnalytics.shared
    
    @State private var performanceAnalysis: ProgressionAnalysis?
    @State private var optimizedSchedule: OptimizedSchedule?
    @State private var trainingGaps: [TrainingGap] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("🧮 AI Insights")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Powered by Swift Algorithms")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top)
                
                // Performance Trend Analysis
                if let analysis = performanceAnalysis {
                    PerformanceTrendCard(analysis: analysis)
                }
                
                // Optimized Schedule
                if let schedule = optimizedSchedule {
                    OptimizedScheduleCard(schedule: schedule)
                }
                
                // Training Gaps
                if !trainingGaps.isEmpty {
                    TrainingGapsCard(gaps: trainingGaps)
                }
                
                // Algorithm Features Demo
                AlgorithmFeaturesCard()
            }
            .padding()
        }
        .background(
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
        )
        .onAppear {
            generateInsights()
        }
    }
    
    private func generateInsights() {
        // Generate mock data for demonstration
        let mockSprintTimes = [5.2, 5.1, 5.0, 4.95, 4.9, 5.0, 4.85, 4.8, 4.82, 4.75]
        
        // Analyze performance trends
        performanceAnalysis = analytics.analyzeSprintProgression(mockSprintTimes)
        
        // Generate optimized schedule
        let availableDays = [1, 2, 4, 6] // Mon, Tue, Thu, Sat
        let sessionTypes = ["Sprint", "Speed Endurance", "Recovery", "Acceleration"]
        let constraints = ScheduleConstraints(
            maxConsecutiveDays: 2,
            minRestDays: 2,
            preferredIntensityDistribution: ["Sprint": 2, "Recovery": 1]
        )
        
        optimizedSchedule = analytics.optimizeTrainingSchedule(
            availableDays: availableDays,
            sessionTypes: sessionTypes,
            constraints: constraints
        )
        
        // Identify training gaps (mock data)
        trainingGaps = [
            TrainingGap(
                type: "Max Velocity",
                severity: .moderate,
                recommendedSessions: []
            )
        ]
    }
}

// MARK: - Supporting Views

struct PerformanceTrendCard: View {
    let analysis: ProgressionAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: trendIcon)
                    .foregroundColor(trendColor)
                Text("Performance Trend")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(analysis.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(trendDescription)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            if !analysis.predictions.isEmpty {
                Text("Predicted next times: \(analysis.predictions.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var trendIcon: String {
        switch analysis.trend {
        case .improving: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.up.circle.fill"
        case .inconsistent: return "questionmark.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch analysis.trend {
        case .improving: return .green
        case .stable: return .yellow
        case .declining: return .red
        case .inconsistent: return .gray
        }
    }
    
    private var trendDescription: String {
        switch analysis.trend {
        case .improving: return "Your sprint times are improving! Keep up the great work."
        case .stable: return "Your performance is consistent. Consider increasing intensity."
        case .declining: return "Performance is declining. Consider more recovery time."
        case .inconsistent: return "Need more data to analyze trends."
        }
    }
}

struct OptimizedScheduleCard: View {
    let schedule: OptimizedSchedule
    
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("Optimized Schedule")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("Score: \(Int(schedule.score))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<7) { day in
                    VStack(spacing: 4) {
                        Text(dayNames[day])
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let session = schedule.sessions.first(where: { $0.day == day }) {
                            Text(session.session)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(4)
                        } else if schedule.restDays.contains(day) {
                            Text("Rest")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(4)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(4)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TrainingGapsCard: View {
    let gaps: [TrainingGap]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Training Gaps")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(gaps.indices, id: \.self) { index in
                let gap = gaps[index]
                HStack {
                    Circle()
                        .fill(severityColor(gap.severity))
                        .frame(width: 8, height: 8)
                    
                    Text("Missing: \(gap.type)")
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(gap.severity == .critical ? "Critical" : "Moderate")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func severityColor(_ severity: GapSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .moderate: return .orange
        case .minor: return .yellow
        }
    }
}

struct AlgorithmFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu.fill")
                    .foregroundColor(.purple)
                Text("Algorithm Features")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                AlgorithmicFeatureRow(icon: "brain.head.profile", title: "Adaptive AI", description: "Uses chunked() for pattern recognition")
                AlgorithmicFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Performance Analysis", description: "Uses windows() for trend analysis")
                AlgorithmicFeatureRow(icon: "music.note", title: "Music Synchronization", description: "Uses adjacentPairs() for crossfades")
                AlgorithmicFeatureRow(icon: "calendar.badge.plus", title: "Schedule Optimization", description: "Uses permutations() for best fit")
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AlgorithmicFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

#Preview {
    AlgorithmicInsightsView(userProfileVM: UserProfileViewModel())
        .preferredColorScheme(.dark)
}
