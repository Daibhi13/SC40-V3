import SwiftUI

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

struct LiveWatchConnectivityTestView: View {
    @StateObject private var liveManager = LiveWatchConnectivityManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isRunningFullTest = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Connection Status
                        connectionStatusSection
                        
                        // Quick Test Buttons
                        quickTestSection
                        
                        // Statistics
                        statisticsSection
                        
                        // Test Results
                        if !liveManager.testResults.isEmpty {
                            testResultsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Live Watch Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        liveManager.clearTestResults()
                    }
                    .foregroundColor(.yellow)
                    .disabled(liveManager.testResults.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .symbolEffect(.pulse, isActive: liveManager.isReachable)
            
            Text("Live Watch Connectivity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Real-time testing between iPhone and Apple Watch")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
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
    
    // MARK: - Connection Status Section
    
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            Text("Connection Status")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Circle()
                    .fill(liveManager.isReachable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(liveManager.connectionStatus)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
            
            // Detailed Status
            VStack(spacing: 8) {
                StatusRow(title: "Watch Paired", status: WCSession.default.isPaired, icon: "applewatch")
                StatusRow(title: "App Installed", status: WCSession.default.isWatchAppInstalled, icon: "app.badge")
                StatusRow(title: "Reachable", status: liveManager.isReachable, icon: "wifi")
                StatusRow(title: "Session Active", status: WCSession.default.activationState == .activated, icon: "checkmark.circle")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Quick Test Section
    
    private var quickTestSection: some View {
        VStack(spacing: 16) {
            Text("Live Tests")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                TestButton(title: "Ping Test", icon: "wifi", color: .blue, isRunning: false) {
                    Task {
                        await liveManager.sendTestPing()
                    }
                }
                
                TestButton(title: "Workout Data", icon: "message", color: .green, isRunning: false) {
                    Task {
                        await liveManager.sendTestWorkoutData()
                    }
                }
                
                TestButton(title: "Profile Sync", icon: "person.crop.circle", color: .orange, isRunning: false) {
                    Task {
                        await liveManager.sendTestUserProfile()
                    }
                }
                
                TestButton(title: "Reachability", icon: "antenna.radiowaves.left.and.right", color: .purple, isRunning: false) {
                    liveManager.testWatchReachability()
                }
            }
            
            // Full Test Button
            Button(action: {
                Task {
                    isRunningFullTest = true
                    await liveManager.runFullConnectivityTest()
                    isRunningFullTest = false
                }
            }) {
                HStack {
                    if isRunningFullTest {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    
                    Text(isRunningFullTest ? "Running Full Test..." : "Run Full Test Suite")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .disabled(isRunningFullTest || !liveManager.isReachable)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                StatCard(title: "Sent", value: "\(liveManager.messagesSent)", icon: "arrow.up.circle", color: .blue)
                StatCard(title: "Received", value: "\(liveManager.messagesReceived)", icon: "arrow.down.circle", color: .green)
                StatCard(title: "Tests", value: "\(liveManager.testResults.count)", icon: "list.bullet", color: .orange)
                StatCard(title: "Success Rate", value: successRate, icon: "percent", color: .purple)
            }
            
            // Last Messages
            VStack(spacing: 8) {
                if let lastSent = liveManager.lastMessageSent {
                    MessageRow(title: "Last Sent", message: lastSent, color: .blue)
                }
                
                if let lastReceived = liveManager.lastMessageReceived {
                    MessageRow(title: "Last Received", message: lastReceived, color: .green)
                }
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
            HStack {
                Text("Test Results")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(successfulTests)/\(liveManager.testResults.count) Passed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVStack(spacing: 8) {
                ForEach(liveManager.testResults.reversed()) { result in
                    TestResultRow(result: TestResult(id: UUID(), testName: result.testName, success: result.success, duration: 0.0, details: result.message, timestamp: result.timestamp))
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
    
    private var successRate: String {
        guard !liveManager.testResults.isEmpty else { return "0%" }
        let successCount = liveManager.testResults.filter { $0.success }.count
        let percentage = (Double(successCount) / Double(liveManager.testResults.count)) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    private var successfulTests: Int {
        liveManager.testResults.filter { $0.success }.count
    }
}

// MARK: - Supporting Views

struct MessageRow: View {
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

#else

// Fallback for non-iOS platforms
struct LiveWatchConnectivityTestView: View {
    var body: some View {
        Text("Watch Connectivity not available on this platform")
            .foregroundColor(.white)
    }
}

#endif
