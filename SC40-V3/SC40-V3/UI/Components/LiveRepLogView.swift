import SwiftUI
import Charts

// MARK: - Live Rep Log View for iPhone
// Shows real-time rep data from Apple Watch

struct LiveRepLogView: View {
    @StateObject private var liveRepLogManager = LiveRepLogManager.shared
    @State private var showDetailedAnalysis = false
    @State private var selectedRep: LiveRep?
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
                    liveRepLogHeader
                    
                    // Connection Status
                    connectionStatusSection
                    
                    // Live Performance Chart
                    if !liveRepLogManager.liveReps.isEmpty {
                        livePerformanceChart
                    }
                    
                    // Current Session Stats
                    currentSessionStats
                    
                    // Live Rep List
                    liveRepsList
                    
                    // Performance Analysis
                    if liveRepLogManager.liveReps.count >= 3 {
                        performanceAnalysis
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
        }
        .navigationTitle("Live RepLog")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var liveRepLogHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.green)
                    .symbolEffect(.pulse, isActive: liveRepLogManager.isReceivingData)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live RepLog")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let session = liveRepLogManager.currentSession {
                        Text("\(session.type) - Week \(session.week), Day \(session.day)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Waiting for Watch data...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Live indicator
                if liveRepLogManager.isReceivingData {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateChart ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateChart)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Connection Status
    
    private var connectionStatusSection: some View {
        HStack(spacing: 16) {
            StatusIndicator(
                title: "Watch Connected",
                isActive: liveRepLogManager.isReceivingData,
                icon: "applewatch"
            )
            
            StatusIndicator(
                title: "Data Sync",
                isActive: liveRepLogManager.lastRepReceived != nil,
                icon: "arrow.triangle.2.circlepath"
            )
            
            StatusIndicator(
                title: "Session Active",
                isActive: liveRepLogManager.currentSession != nil,
                icon: "play.circle"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: - Live Performance Chart
    
    private var livePerformanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart(liveRepLogManager.liveReps) { rep in
                LineMark(
                    x: .value("Rep", rep.repNumber),
                    y: .value("Time", rep.time)
                )
                .foregroundStyle(Color.cyan)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Rep", rep.repNumber),
                    y: .value("Time", rep.time)
                )
                .foregroundStyle(Color.cyan)
                .symbolSize(60)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: liveRepLogManager.liveReps.count)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Current Session Stats
    
    private var currentSessionStats: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            
            LiveRepStatCard(
                title: "Current Rep",
                value: "\(liveRepLogManager.currentRep)",
                subtitle: "of session",
                color: .blue
            )
            
            LiveRepStatCard(
                title: "Average Time",
                value: String(format: "%.2fs", liveRepLogManager.averageTime),
                subtitle: "per rep",
                color: .green
            )
            
            LiveRepStatCard(
                title: "Best Time",
                value: String(format: "%.2fs", liveRepLogManager.bestTime),
                subtitle: "personal best",
                color: .yellow
            )
        }
    }
    
    // MARK: - Live Reps List
    
    private var liveRepsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Reps")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let lastReceived = liveRepLogManager.lastRepReceived {
                    Text("Last: \(timeAgo(lastReceived))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(liveRepLogManager.liveReps.reversed()) { rep in
                    LiveRepRow(rep: rep, isLatest: rep.id == liveRepLogManager.liveReps.last?.id)
                        .onTapGesture {
                            selectedRep = rep
                            showDetailedAnalysis = true
                        }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
        .sheet(item: $selectedRep) { rep in
            RepDetailView(rep: rep)
        }
    }
    
    // MARK: - Performance Analysis
    
    private var performanceAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            let trend = liveRepLogManager.getRepTrend()
            let paceAnalysis = liveRepLogManager.getPaceAnalysis()
            
            VStack(spacing: 12) {
                AnalysisCard(
                    title: "Trend",
                    value: trend.description,
                    color: trend.color,
                    icon: trend.icon
                )
                
                AnalysisCard(
                    title: "Pace Variance",
                    value: String(format: "%.1f%%", paceAnalysis.variance * 100),
                    color: paceAnalysis.variance < 0.05 ? .green : .orange,
                    icon: "speedometer"
                )
                
                AnalysisCard(
                    title: "Consistency",
                    value: liveRepLogManager.sessionStats.consistency < 0.5 ? "Excellent" : "Good",
                    color: liveRepLogManager.sessionStats.consistency < 0.5 ? .green : .yellow,
                    icon: "target"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Helper Functions
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else {
            return "\(Int(interval / 60))m ago"
        }
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let title: String
    let isActive: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isActive ? .green : .gray)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LiveRepStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct LiveRepRow: View {
    let rep: LiveRep
    let isLatest: Bool
    
    var body: some View {
        HStack {
            // Rep number
            Text("\(rep.repNumber)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 30)
            
            // Distance
            Text("\(Int(rep.distance))yd")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 50, alignment: .leading)
            
            // Time
            Text(String(format: "%.2fs", rep.time))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(isLatest ? .green : .cyan)
            
            Spacer()
            
            // Timestamp
            Text(DateFormatter.timeOnly.string(from: rep.timestamp))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            if isLatest {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isLatest ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isLatest ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct AnalysisCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct RepDetailView: View {
    let rep: LiveRep
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Rep \(rep.repNumber) Details")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    DetailRow(title: "Distance", value: "\(Int(rep.distance)) yards")
                    DetailRow(title: "Time", value: String(format: "%.3f seconds", rep.time))
                    DetailRow(title: "Pace", value: String(format: "%.2f s/yd", rep.time / rep.distance))
                    DetailRow(title: "Completed", value: DateFormatter.full.string(from: rep.timestamp))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Rep Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Extensions

extension RepTrend {
    var description: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    LiveRepLogView()
}
