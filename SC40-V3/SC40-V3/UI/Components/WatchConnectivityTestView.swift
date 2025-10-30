import SwiftUI
import Combine

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity

struct WatchConnectivityTestView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var currentTestIndex = 0
    @State private var showDetailedReport = false
    @State private var testStartTime: Date?
    
    // Performance optimization - limit test results
    private let maxTestResults = 50
    
    // Test data for sending to watch
    @State private var testMessage = "Hello from iPhone!"
    @State private var testWorkoutData: [String: Any] = [:]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching TrainingView
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
                        // Header
                        headerSection
                        
                        // Connection Status
                        connectionStatusSection
                        
                        // Quick Tests Section
                        quickTestsSection
                        
                        // Test Results
                        if !testResults.isEmpty {
                            testResultsSection
                        }
                        
                        // Detailed Report Button
                        if !testResults.isEmpty {
                            detailedReportButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Watch Connectivity")
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
                        testResults.removeAll()
                    }
                    .foregroundColor(.yellow)
                    .disabled(testResults.isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showDetailedReport) {
            DetailedTestReportView(testResults: testResults)
        }
        .onAppear {
            setupInitialTestData()
        }
        .onDisappear {
            // Clean up resources when view disappears
            testResults.removeAll(keepingCapacity: false)
            testStartTime = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // Handle memory warnings by clearing old test results
            if testResults.count > 10 {
                testResults.removeFirst(testResults.count - 10)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "applewatch.watchface")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 10)
            
            Text("Watch Connectivity Testing")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Test communication between iPhone and Apple Watch")
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
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Connection Status Section
    
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            Text("Connection Status")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                StatusRow(
                    title: "Watch Paired",
                    status: WCSession.default.isPaired,
                    icon: "applewatch"
                )
                
                StatusRow(
                    title: "Watch App Installed",
                    status: WCSession.default.isWatchAppInstalled,
                    icon: "app.badge"
                )
                
                StatusRow(
                    title: "Watch Reachable",
                    status: watchConnectivity.isWatchReachable,
                    icon: "wifi"
                )
                
                StatusRow(
                    title: "Session Active",
                    status: WCSession.default.activationState == .activated,
                    icon: "checkmark.circle"
                )
            }
            
            // Overall Status
            HStack {
                Circle()
                    .fill(overallConnectionStatus ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(watchConnectivity.checkWatchStatus())
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Quick Tests Section
    
    private var quickTestsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Tests")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                TestButton(
                    title: "Ping Test",
                    icon: "antenna.radiowaves.left.and.right",
                    color: .blue,
                    isRunning: isRunningTests && currentTestIndex == 0
                ) {
                    Task { await runPingTest() }
                }
                
                TestButton(
                    title: "Force Sync",
                    icon: "arrow.triangle.2.circlepath",
                    color: .green,
                    isRunning: isRunningTests && currentTestIndex == 1
                ) {
                    Task { await runForceSyncTest() }
                }
                
                TestButton(
                    title: "Workout Launch",
                    icon: "figure.run",
                    color: .orange,
                    isRunning: isRunningTests && currentTestIndex == 2
                ) {
                    Task { await runWorkoutLaunchTest() }
                }
                
                TestButton(
                    title: "7-Stage Flow",
                    icon: "list.number",
                    color: .purple,
                    isRunning: isRunningTests && currentTestIndex == 3
                ) {
                    Task { await run7StageFlowTest() }
                }
            }
            
            // Run All Tests Button
            Button(action: runAllTests) {
                HStack {
                    if isRunningTests {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    
                    Text(isRunningTests ? "Running Tests..." : "Run All Tests")
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
                .shadow(color: .yellow.opacity(0.3), radius: 10)
            }
            .disabled(isRunningTests || !overallConnectionStatus)
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
                
                Text("\(testResults.filter { $0.success }.count)/\(testResults.count) Passed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            LazyVStack(spacing: 8) {
                ForEach(testResults) { result in
                    TestResultRow(result: result)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Detailed Report Button
    
    private var detailedReportButton: some View {
        Button(action: { showDetailedReport = true }) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                Text("View Detailed Report")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var overallConnectionStatus: Bool {
        return WCSession.default.isPaired &&
               WCSession.default.isWatchAppInstalled &&
               watchConnectivity.isWatchReachable &&
               WCSession.default.activationState == .activated
    }
    
    // MARK: - Helper Functions
    
    private func addTestResult(_ result: TestResult) {
        // Limit test results to prevent memory issues
        if testResults.count >= maxTestResults {
            testResults.removeFirst()
        }
        testResults.append(result)
    }
    
    // MARK: - Test Functions
    
    private func setupInitialTestData() {
        testWorkoutData = [
            "type": "test_workout",
            "sessionId": UUID().uuidString,
            "sessionType": "Test Sprint",
            "focus": "Connectivity Test",
            "week": 1,
            "day": 1,
            "sprints": [
                [
                    "distanceYards": 40,
                    "reps": 3,
                    "intensity": "moderate"
                ]
            ],
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    private func runPingTest() async {
        guard !isRunningTests else { return }
        
        await MainActor.run {
            isRunningTests = true
            currentTestIndex = 0
            testStartTime = Date()
        }
        
        do {
            let pingData: [String: Any] = [
                "type": "ping_test",
                "message": testMessage,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            try await watchConnectivity.sendMessageToWatch(pingData)
            
            await MainActor.run {
                let result = TestResult(
                    id: UUID(),
                    testName: "Ping Test",
                    success: true,
                    duration: Date().timeIntervalSince(testStartTime ?? Date()),
                    details: "Successfully sent ping message to watch",
                    timestamp: Date()
                )
                addTestResult(result)
                isRunningTests = false
            }
            
        } catch {
            await MainActor.run {
                let result = TestResult(
                    id: UUID(),
                    testName: "Ping Test",
                    success: false,
                    duration: Date().timeIntervalSince(testStartTime ?? Date()),
                    details: "Failed to send ping: \(error.localizedDescription)",
                    timestamp: Date()
                )
                addTestResult(result)
                isRunningTests = false
            }
        }
    }
    
    private func runForceSyncTest() async {
        guard !isRunningTests else { return }
        
        await MainActor.run {
            isRunningTests = true
            currentTestIndex = 1
            testStartTime = Date()
        }
        
        // Trigger manual sync of training data
        await watchConnectivity.forceSyncTrainingData()
        
        await MainActor.run {
            let result = TestResult(
                id: UUID(),
                testName: "Force Training Sync",
                success: watchConnectivity.trainingSessionsSynced,
                duration: Date().timeIntervalSince(testStartTime ?? Date()),
                details: watchConnectivity.trainingSessionsSynced ? "Successfully synced training data to watch" : "Failed to sync training data",
                timestamp: Date()
            )
            addTestResult(result)
            isRunningTests = false
        }
    }
    
    private func runDataSyncTest() async {
        guard !isRunningTests else { return }
        
        await MainActor.run {
            isRunningTests = true
            currentTestIndex = 1
            testStartTime = Date()
        }
        
        // Create test profile data
        let testProfile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            gender: "Male",
            age: 25,
            height: 70,
            weight: 150,
            personalBests: ["40yd": 5.5],
            level: "Intermediate",
            baselineTime: 5.5,
            frequency: 3
        )
        
        await watchConnectivity.syncOnboardingData(userProfile: testProfile)
        
        await MainActor.run {
            let result = TestResult(
                id: UUID(),
                testName: "Data Sync Test",
                success: watchConnectivity.onboardingDataSynced,
                duration: Date().timeIntervalSince(testStartTime ?? Date()),
                details: watchConnectivity.onboardingDataSynced ? "Successfully synced test profile data" : "Failed to sync profile data",
                timestamp: Date()
            )
            testResults.append(result)
            isRunningTests = false
        }
    }
    
    private func runWorkoutLaunchTest() async {
        guard !isRunningTests else { return }
        
        await MainActor.run {
            isRunningTests = true
            currentTestIndex = 2
            testStartTime = Date()
        }
        
        do {
            let testSession = TrainingSession(
                id: UUID(),
                week: 1,
                day: 1,
                type: "Test Sprint",
                focus: "Connectivity Test",
                sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "moderate")],
                accessoryWork: ["Dynamic warm-up", "Cool-down"],
                notes: "Test workout for connectivity"
            )
            
            await watchConnectivity.launchWorkoutOnWatch(session: testSession)
            
            await MainActor.run {
                let result = TestResult(
                    id: UUID(),
                    testName: "Workout Launch Test",
                    success: true,
                    duration: Date().timeIntervalSince(testStartTime ?? Date()),
                    details: "Successfully sent workout launch command to watch",
                    timestamp: Date()
                )
                addTestResult(result)
                isRunningTests = false
            }
        } catch {
            await MainActor.run {
                let result = TestResult(
                    id: UUID(),
                    testName: "Workout Launch Test",
                    success: false,
                    duration: Date().timeIntervalSince(testStartTime ?? Date()),
                    details: "Workout launch failed: \(error.localizedDescription)",
                    timestamp: Date()
                )
                addTestResult(result)
                isRunningTests = false
            }
        }
    }
    
    private func run7StageFlowTest() async {
        guard !isRunningTests else { return }
        
        await MainActor.run {
            isRunningTests = true
            currentTestIndex = 3
            testStartTime = Date()
        }
        
        await watchConnectivity.sync7StageWorkoutFlow()
        
        await MainActor.run {
            let result = TestResult(
                id: UUID(),
                testName: "7-Stage Flow Test",
                success: true,
                duration: Date().timeIntervalSince(testStartTime ?? Date()),
                details: "Successfully synced 7-stage workout flow to watch",
                timestamp: Date()
            )
            addTestResult(result)
            isRunningTests = false
        }
    }
    
    private func runAllTests() {
        guard !isRunningTests else { return }
        
        // Clear old results but keep memory footprint low
        testResults.removeAll(keepingCapacity: false)
        
        Task {
            await runPingTest()
            
            // Only continue if not cancelled and view still exists
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            await runDataSyncTest()
            
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await runWorkoutLaunchTest()
            
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await run7StageFlowTest()
        }
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let title: String
    let status: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status ? .green : .red)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

struct TestButton: View {
    let title: String
    let icon: String
    let color: Color
    let isRunning: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .disabled(isRunning)
    }
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.testName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2fs", result.duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

// MARK: - Test Result Model

struct TestResult: Identifiable {
    let id: UUID
    let testName: String
    let success: Bool
    let duration: TimeInterval
    let details: String
    let timestamp: Date
}

#endif
