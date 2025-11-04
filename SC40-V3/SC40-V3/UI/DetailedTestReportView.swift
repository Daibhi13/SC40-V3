import SwiftUI

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

struct DetailedTestReportView: View {
    let testResults: [TestResult]
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var reportText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
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
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Summary Section
                        summarySection
                        
                        // System Information
                        systemInfoSection
                        
                        // Test Results Detail
                        testResultsSection
                        
                        // Recommendations
                        recommendationsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Test Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        generateReportText()
                        showShareSheet = true
                    }
                    .foregroundColor(.yellow)
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [reportText], applicationActivities: nil)
        }
        .onAppear {
            generateReportText()
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(spacing: 16) {
            Text("Test Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                SummaryCard(
                    title: "Total Tests",
                    value: "\(testResults.count)",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Passed",
                    value: "\(passedTests)",
                    color: .green
                )
                
                SummaryCard(
                    title: "Failed",
                    value: "\(failedTests)",
                    color: .red
                )
                
                SummaryCard(
                    title: "Success Rate",
                    value: "\(successRate)%",
                    color: successRate >= 75 ? .green : successRate >= 50 ? .orange : .red
                )
            }
            
            // Overall Status
            HStack {
                Image(systemName: overallStatus.icon)
                    .foregroundColor(overallStatus.color)
                
                Text(overallStatus.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(overallStatus.color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(overallStatus.color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - System Information Section
    
    private var systemInfoSection: some View {
        VStack(spacing: 16) {
            Text("System Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                InfoRow(title: "iOS Version", value: UIDevice.current.systemVersion)
                InfoRow(title: "Device Model", value: UIDevice.current.model)
                InfoRow(title: "WatchConnectivity Supported", value: WCSession.isSupported() ? "Yes" : "No")
                InfoRow(title: "Session State", value: sessionStateDescription)
                InfoRow(title: "Watch Paired", value: WCSession.default.isPaired ? "Yes" : "No")
                InfoRow(title: "Watch App Installed", value: WCSession.default.isWatchAppInstalled ? "Yes" : "No")
                InfoRow(title: "Watch Reachable", value: WCSession.default.isReachable ? "Yes" : "No")
                InfoRow(title: "Test Date", value: DateFormatter.fullDateTime.string(from: Date()))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Test Results Section
    
    private var testResultsSection: some View {
        VStack(spacing: 16) {
            Text("Test Results Detail")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(testResults) { result in
                    DetailedTestResultCard(result: result)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            Text("Recommendations")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(recommendations, id: \.self) { recommendation in
                    RecommendationCard(text: recommendation)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Computed Properties
    
    private var passedTests: Int {
        testResults.filter { $0.success }.count
    }
    
    private var failedTests: Int {
        testResults.filter { !$0.success }.count
    }
    
    private var successRate: Int {
        guard !testResults.isEmpty else { return 0 }
        return Int((Double(passedTests) / Double(testResults.count)) * 100)
    }
    
    private var overallStatus: (message: String, color: Color, icon: String) {
        if successRate == 100 {
            return ("All tests passed - Watch connectivity is excellent", .green, "checkmark.circle.fill")
        } else if successRate >= 75 {
            return ("Most tests passed - Watch connectivity is good", .green, "checkmark.circle")
        } else if successRate >= 50 {
            return ("Some tests failed - Watch connectivity needs attention", .orange, "exclamationmark.triangle.fill")
        } else {
            return ("Multiple tests failed - Watch connectivity has issues", .red, "xmark.circle.fill")
        }
    }
    
    private var sessionStateDescription: String {
        switch WCSession.default.activationState {
        case .activated:
            return "Activated"
        case .inactive:
            return "Inactive"
        case .notActivated:
            return "Not Activated"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var recommendations: [String] {
        var recs: [String] = []
        
        if !WCSession.default.isPaired {
            recs.append("Pair your Apple Watch with this iPhone in the Watch app")
        }
        
        if !WCSession.default.isWatchAppInstalled {
            recs.append("Install the SC40 Watch app from the App Store on your Apple Watch")
        }
        
        if !WCSession.default.isReachable {
            recs.append("Ensure your Apple Watch is nearby and connected to this iPhone")
        }
        
        if WCSession.default.activationState != .activated {
            recs.append("Restart both apps to reactivate the WatchConnectivity session")
        }
        
        if failedTests > 0 {
            recs.append("Check your network connection and try running the tests again")
        }
        
        if testResults.contains(where: { !$0.success && $0.testName.contains("Sync") }) {
            recs.append("Try force-quitting and restarting both the iPhone and Watch apps")
        }
        
        if recs.isEmpty {
            recs.append("Your Watch connectivity is working well! No action needed.")
        }
        
        return recs
    }
    
    // MARK: - Helper Functions
    
    private func generateReportText() {
        let formatter = DateFormatter.fullDateTime
        
        reportText = """
        SC40 Watch Connectivity Test Report
        Generated: \(formatter.string(from: Date()))
        
        SUMMARY:
        - Total Tests: \(testResults.count)
        - Passed: \(passedTests)
        - Failed: \(failedTests)
        - Success Rate: \(successRate)%
        
        SYSTEM INFORMATION:
        - iOS Version: \(UIDevice.current.systemVersion)
        - Device: \(UIDevice.current.model)
        - WatchConnectivity Supported: \(WCSession.isSupported() ? "Yes" : "No")
        - Session State: \(sessionStateDescription)
        - Watch Paired: \(WCSession.default.isPaired ? "Yes" : "No")
        - Watch App Installed: \(WCSession.default.isWatchAppInstalled ? "Yes" : "No")
        - Watch Reachable: \(WCSession.default.isReachable ? "Yes" : "No")
        
        TEST RESULTS:
        \(testResults.map { result in
            "- \(result.testName): \(result.success ? "PASS" : "FAIL") (\(String(format: "%.2fs", result.duration)))\n  \(result.details)"
        }.joined(separator: "\n"))
        
        RECOMMENDATIONS:
        \(recommendations.map { "- \($0)" }.joined(separator: "\n"))
        
        ---
        Sprint Coach 40 - Watch Connectivity Report
        """
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 2)
    }
}

struct DetailedTestResultCard: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.testName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: "%.2fs", result.duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(result.details)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Spacer()
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct RecommendationCard: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Activity View Controller
// Note: Using ActivityViewController from SharePerformanceView.swift to avoid duplication

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }()
}

#endif
