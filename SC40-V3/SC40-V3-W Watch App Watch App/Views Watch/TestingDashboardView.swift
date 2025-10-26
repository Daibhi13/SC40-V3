import SwiftUI
import WatchKit

struct TestingDashboardView: View {
    @StateObject private var testingFramework = WorkoutTestingFramework.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTestType: TestType = .fullAutonomousWorkout
    @State private var showingTestResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    if testingFramework.isTestingActive {
                        // Active Testing View
                        activeTestingView
                    } else {
                        // Test Selection View
                        testSelectionView
                    }
                }
                .padding(16)
            }
            .background(Color.black)
            .navigationTitle("Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if testingFramework.isTestingActive {
                            testingFramework.endTestSession()
                        }
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
                
                if !testingFramework.isTestingActive {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("History") {
                            showingTestResults = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTestResults) {
            TestResultsHistoryView()
        }
    }
    
    // MARK: - Active Testing View
    
    private var activeTestingView: some View {
        VStack(spacing: 16) {
            // Test Status Header
            testStatusHeader
            
            // Real-time Metrics
            realTimeMetricsView
            
            // Recent Test Results
            recentResultsView
            
            // Stop Test Button
            Button(action: {
                testingFramework.endTestSession()
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Test")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
            }
        }
    }
    
    private var testStatusHeader: some View {
        VStack(spacing: 8) {
            if let session = testingFramework.currentTestSession {
                Text(session.type.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
                
                Text("Running...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.yellow)
                
                // Test Duration
                Text(formatDuration(Date().timeIntervalSince(session.startTime)))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var realTimeMetricsView: some View {
        VStack(spacing: 8) {
            Text("Real-Time Metrics")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                MetricCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(testingFramework.realTimeMetrics.currentHeartRate)",
                    unit: "BPM",
                    color: testingFramework.realTimeMetrics.isWorkoutActive ? .red : .gray
                )
                
                MetricCard(
                    icon: "location.fill",
                    title: "Speed",
                    value: String(format: "%.1f", testingFramework.realTimeMetrics.currentSpeed),
                    unit: "MPH",
                    color: testingFramework.realTimeMetrics.currentSpeed > 0 ? .green : .gray
                )
                
                MetricCard(
                    icon: "timer",
                    title: "Phase",
                    value: testingFramework.realTimeMetrics.currentPhase.prefix(4).uppercased(),
                    unit: "",
                    color: testingFramework.realTimeMetrics.isIntervalActive ? .blue : .gray
                )
                
                MetricCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "GPS",
                    value: String(format: "%.0f", testingFramework.realTimeMetrics.gpsAccuracy),
                    unit: "M",
                    color: testingFramework.realTimeMetrics.gpsAccuracy < 10 ? .green : .orange
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var recentResultsView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Recent Results")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(testingFramework.testResults.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.yellow)
            }
            
            if testingFramework.testResults.isEmpty {
                Text("No results yet...")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(testingFramework.testResults.suffix(3).reversed(), id: \.id) { result in
                        TestResultRow(result: result)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Test Selection View
    
    private var testSelectionView: some View {
        VStack(spacing: 16) {
            // Test Type Picker
            testTypePicker
            
            // Quick Test Buttons
            quickTestButtons
            
            // Test Description
            testDescriptionView
        }
    }
    
    private var testTypePicker: some View {
        VStack(spacing: 8) {
            Text("Select Test Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Picker("Test Type", selection: $selectedTestType) {
                ForEach(TestType.allCases, id: \.self) { testType in
                    Text(testType.rawValue)
                        .tag(testType)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
        }
    }
    
    private var quickTestButtons: some View {
        VStack(spacing: 8) {
            Button(action: {
                testingFramework.startTestSession(selectedTestType)
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Test")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(8)
            }
            
            Button(action: {
                testingFramework.startTestSession(.systemIntegration)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Full System Test")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
    }
    
    private var testDescriptionView: some View {
        VStack(spacing: 8) {
            Text("Test Description")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(getTestDescription(selectedTestType))
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getTestDescription(_ testType: TestType) -> String {
        switch testType {
        case .fullAutonomousWorkout:
            return "Tests complete autonomous workout execution including HealthKit, GPS, and interval management."
        case .gpsAccuracy:
            return "Validates GPS signal quality, accuracy, and speed tracking during movement."
        case .healthKitIntegration:
            return "Verifies HealthKit permissions, heart rate monitoring, and workout session management."
        case .batteryPerformance:
            return "Monitors battery drain rate during autonomous workout operations."
        case .syncReliability:
            return "Tests background sync functionality and phone connectivity."
        case .systemIntegration:
            return "Comprehensive test of all autonomous systems working together."
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack(spacing: 8) {
            // Status Icon
            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 12)
            
            // Test Name
            Text(result.test)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Timestamp
            Text(formatTime(result.timestamp))
                .font(.system(size: 8, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(statusColor.opacity(0.1))
        )
    }
    
    private var statusIcon: String {
        switch result.status {
        case .passed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .running:
            return "clock.fill"
        }
    }
    
    private var statusColor: Color {
        switch result.status {
        case .passed:
            return .green
        case .failed:
            return .red
        case .warning:
            return .orange
        case .running:
            return .blue
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Test Results History View

struct TestResultsHistoryView: View {
    @StateObject private var testingFramework = WorkoutTestingFramework.shared
    @Environment(\.dismiss) private var dismiss
    @State private var testHistory: [TestReport] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if testHistory.isEmpty {
                        Text("No test history available")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.vertical, 20)
                    } else {
                        ForEach(testHistory, id: \.session.id) { report in
                            TestReportCard(report: report)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.black)
            .navigationTitle("Test History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") {
                        testingFramework.clearTestHistory()
                        loadTestHistory()
                    }
                    .foregroundColor(.red)
                    .disabled(testHistory.isEmpty)
                }
            }
        }
        .onAppear {
            loadTestHistory()
        }
    }
    
    private func loadTestHistory() {
        testHistory = testingFramework.getTestHistory()
    }
}

struct TestReportCard: View {
    let report: TestReport
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(report.session.type.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatDate(report.session.startTime))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Summary
            HStack(spacing: 16) {
                SummaryItem(
                    title: "Total",
                    value: "\(report.summary.totalTests)",
                    color: .white
                )
                
                SummaryItem(
                    title: "Passed",
                    value: "\(report.summary.passedTests)",
                    color: .green
                )
                
                SummaryItem(
                    title: "Failed",
                    value: "\(report.summary.failedTests)",
                    color: .red
                )
                
                SummaryItem(
                    title: "Success",
                    value: "\(Int(report.summary.successRate * 100))%",
                    color: report.summary.successRate > 0.8 ? .green : .orange
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview("Testing Dashboard") {
    TestingDashboardView()
}
