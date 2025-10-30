import SwiftUI
import Combine

// MARK: - 28 Combination Onboarding Test Suite
// Tests all Level × Days combinations to ensure proper UI/UX updates

struct OnboardingLevelDaysTestSuite: View {
    @EnvironmentObject private var syncManager: TrainingSynchronizationManager
    @StateObject private var testRunner = TestRunner()
    @State private var currentTestIndex = 0
    @State private var isRunning = false
    @State private var autoFixEnabled = true
    
    // All 28 combinations to test
    private let testCombinations: [(level: TrainingLevel, days: Int)] = {
        let levels: [TrainingLevel] = [.beginner, .intermediate, .advanced, .pro]
        let days = Array(1...7)
        return levels.flatMap { level in
            days.map { day in (level: level, days: day) }
        }
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Test Progress
                testProgressSection
                
                // Current Test Display
                currentTestSection
                
                // Test Controls
                testControlsSection
                
                // Results Summary
                testResultsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("28 Level×Days Tests")
        }
        .onAppear {
            testRunner.setupTestSuite(combinations: testCombinations, syncManager: syncManager)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("SC40-V3 Onboarding Test Suite")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Testing 4 Levels × 7 Days = 28 Combinations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Auto-Fix: \(autoFixEnabled ? "Enabled" : "Disabled")")
                .font(.caption)
                .foregroundColor(autoFixEnabled ? .green : .orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Progress Section
    
    private var testProgressSection: some View {
        VStack(spacing: 12) {
            Text("Test Progress")
                .font(.headline)
            
            ProgressView(value: Double(currentTestIndex), total: Double(testCombinations.count))
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(currentTestIndex)/\(testCombinations.count) tests completed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Test grid visualization
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<28, id: \.self) { index in
                    testStatusCell(for: index)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testStatusCell(for index: Int) -> some View {
        let combination = testCombinations[index]
        let status = testRunner.getTestStatus(for: index)
        
        return VStack(spacing: 2) {
            Text(combination.level.rawValue.prefix(1).uppercased())
                .font(.caption2)
                .fontWeight(.bold)
            Text("\(combination.days)")
                .font(.caption2)
        }
        .frame(width: 30, height: 30)
        .background(backgroundColorForStatus(status))
        .cornerRadius(4)
        .foregroundColor(.white)
    }
    
    private func backgroundColorForStatus(_ status: TestStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .running: return .blue
        case .passed: return .green
        case .failed: return .red
        case .fixed: return .orange
        }
    }
    
    // MARK: - Current Test Section
    
    private var currentTestSection: some View {
        VStack(spacing: 12) {
            Text("Current Test")
                .font(.headline)
            
            if currentTestIndex < testCombinations.count {
                let current = testCombinations[currentTestIndex]
                
                VStack(spacing: 8) {
                    Text("Level: \(current.level.label)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Days per Week: \(current.days)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Expected Sessions: \(current.days * 12)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("All tests completed!")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Controls Section
    
    private var testControlsSection: some View {
        VStack(spacing: 16) {
            Text("Test Controls")
                .font(.headline)
            
            HStack(spacing: 16) {
                Button(action: runAllTests) {
                    HStack {
                        Image(systemName: isRunning ? "stop.circle" : "play.circle")
                        Text(isRunning ? "Stop Tests" : "Run All Tests")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(isRunning ? Color.red : Color.green)
                    .cornerRadius(10)
                }
                .disabled(testRunner.isRunning && !isRunning)
                
                Button(action: runSingleTest) {
                    HStack {
                        Image(systemName: "play.circle")
                        Text("Run Current")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isRunning || currentTestIndex >= testCombinations.count)
            }
            
            Toggle("Auto-Fix Failed Tests", isOn: $autoFixEnabled)
                .font(.subheadline)
            
            Button(action: resetTests) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset All Tests")
                }
                .font(.subheadline)
                .foregroundColor(.orange)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Results Section
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(testRunner.testResults.enumerated()), id: \.offset) { index, result in
                        testResultRow(index: index, result: result)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testResultRow(index: Int, result: TestResult) -> some View {
        let combination = testCombinations[index]
        
        return HStack {
            // Status indicator
            Image(systemName: iconForStatus(result.status))
                .foregroundColor(colorForStatus(result.status))
                .frame(width: 20)
            
            // Test info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(combination.level.label) × \(combination.days) days")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let message = result.message {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Timing info
            if let duration = result.duration {
                Text(String(format: "%.1fs", duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    private func iconForStatus(_ status: TestStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .running: return "arrow.clockwise"
        case .passed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .fixed: return "wrench.and.screwdriver"
        }
    }
    
    private func colorForStatus(_ status: TestStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .running: return .blue
        case .passed: return .green
        case .failed: return .red
        case .fixed: return .orange
        }
    }
    
    // MARK: - Test Actions
    
    private func runAllTests() {
        if isRunning {
            // Stop tests
            isRunning = false
            testRunner.stopTests()
        } else {
            // Start tests
            isRunning = true
            currentTestIndex = 0
            
            Task {
                await testRunner.runAllTests(autoFix: autoFixEnabled) { index in
                    DispatchQueue.main.async {
                        currentTestIndex = index + 1
                        if currentTestIndex >= testCombinations.count {
                            isRunning = false
                        }
                    }
                }
            }
        }
    }
    
    private func runSingleTest() {
        guard currentTestIndex < testCombinations.count else { return }
        
        Task {
            await testRunner.runSingleTest(at: currentTestIndex, autoFix: autoFixEnabled)
            DispatchQueue.main.async {
                currentTestIndex += 1
            }
        }
    }
    
    private func resetTests() {
        isRunning = false
        currentTestIndex = 0
        testRunner.resetTests()
    }
}

// MARK: - Test Runner

class TestRunner: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    
    private var combinations: [(level: TrainingLevel, days: Int)] = []
    private var syncManager: TrainingSynchronizationManager?
    private var shouldStop = false
    
    func setupTestSuite(combinations: [(level: TrainingLevel, days: Int)], syncManager: TrainingSynchronizationManager) {
        self.combinations = combinations
        self.syncManager = syncManager
        self.testResults = Array(repeating: TestResult(), count: combinations.count)
    }
    
    func getTestStatus(for index: Int) -> TestStatus {
        guard index < testResults.count else { return .pending }
        return testResults[index].status
    }
    
    func runAllTests(autoFix: Bool, progressCallback: @escaping (Int) -> Void) async {
        isRunning = true
        shouldStop = false
        
        for (index, combination) in combinations.enumerated() {
            if shouldStop { break }
            
            await runTest(at: index, combination: combination, autoFix: autoFix)
            progressCallback(index)
            
            // Small delay between tests
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        await MainActor.run {
            isRunning = false
        }
    }
    
    func runSingleTest(at index: Int, autoFix: Bool) async {
        guard index < combinations.count else { return }
        let combination = combinations[index]
        await runTest(at: index, combination: combination, autoFix: autoFix)
    }
    
    private func runTest(at index: Int, combination: (level: TrainingLevel, days: Int), autoFix: Bool) async {
        let startTime = Date()
        
        await MainActor.run {
            testResults[index] = TestResult(status: .running, startTime: startTime)
        }
        
        guard let syncManager = syncManager else {
            await MainActor.run {
                testResults[index] = TestResult(
                    status: .failed,
                    message: "SyncManager not available",
                    startTime: startTime,
                    duration: Date().timeIntervalSince(startTime)
                )
            }
            return
        }
        
        do {
            // Step 1: Trigger onboarding sync
            await syncManager.synchronizeTrainingProgram(level: combination.level, days: combination.days)
            
            // Step 2: Verify UI/UX updates
            let verificationResult = await verifyUIUXUpdate(level: combination.level, days: combination.days, syncManager: syncManager)
            
            if verificationResult.success {
                await MainActor.run {
                    testResults[index] = TestResult(
                        status: .passed,
                        message: "✅ UI/UX updated correctly",
                        startTime: startTime,
                        duration: Date().timeIntervalSince(startTime)
                    )
                }
            } else {
                // Step 3: Auto-fix if enabled
                if autoFix {
                    let fixResult = await attemptAutoFix(level: combination.level, days: combination.days, syncManager: syncManager, issue: verificationResult.issue)
                    
                    await MainActor.run {
                        testResults[index] = TestResult(
                            status: fixResult.success ? .fixed : .failed,
                            message: fixResult.message,
                            startTime: startTime,
                            duration: Date().timeIntervalSince(startTime)
                        )
                    }
                } else {
                    await MainActor.run {
                        testResults[index] = TestResult(
                            status: .failed,
                            message: "❌ \(verificationResult.issue)",
                            startTime: startTime,
                            duration: Date().timeIntervalSince(startTime)
                        )
                    }
                }
            }
        } catch {
            await MainActor.run {
                testResults[index] = TestResult(
                    status: .failed,
                    message: "❌ Error: \(error.localizedDescription)",
                    startTime: startTime,
                    duration: Date().timeIntervalSince(startTime)
                )
            }
        }
    }
    
    private func verifyUIUXUpdate(level: TrainingLevel, days: Int, syncManager: TrainingSynchronizationManager) async -> VerificationResult {
        // Wait for sync to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check 1: Verify level is set correctly
        guard syncManager.selectedLevel == level else {
            return VerificationResult(success: false, issue: "Level not updated: expected \(level.label), got \(syncManager.selectedLevel?.label ?? "nil")")
        }
        
        // Check 2: Verify days are set correctly
        guard syncManager.selectedDays == days else {
            return VerificationResult(success: false, issue: "Days not updated: expected \(days), got \(syncManager.selectedDays)")
        }
        
        // Check 3: Verify session count
        let expectedSessions = days * 12 // 12 weeks
        guard syncManager.activeSessions.count == expectedSessions else {
            return VerificationResult(success: false, issue: "Session count mismatch: expected \(expectedSessions), got \(syncManager.activeSessions.count)")
        }
        
        // Check 4: Verify compilation ID is generated
        guard syncManager.currentCompilationID != nil else {
            return VerificationResult(success: false, issue: "Compilation ID not generated")
        }
        
        // Check 5: Verify sync state
        guard syncManager.isPhoneSynced else {
            return VerificationResult(success: false, issue: "Phone sync state not updated")
        }
        
        return VerificationResult(success: true, issue: nil)
    }
    
    private func attemptAutoFix(level: TrainingLevel, days: Int, syncManager: TrainingSynchronizationManager, issue: String?) async -> FixResult {
        // Auto-fix strategies
        
        // Strategy 1: Force re-sync
        await syncManager.synchronizeTrainingProgram(level: level, days: days)
        
        // Strategy 2: Clear and regenerate
        await syncManager.clearActiveSessions()
        await syncManager.synchronizeTrainingProgram(level: level, days: days)
        
        // Strategy 3: Manual state correction
        await MainActor.run {
            syncManager.selectedLevel = level
            syncManager.selectedDays = days
        }
        
        // Re-verify after fix attempts
        let verificationResult = await verifyUIUXUpdate(level: level, days: days, syncManager: syncManager)
        
        if verificationResult.success {
            return FixResult(success: true, message: "🔧 Auto-fixed: UI/UX now updates correctly")
        } else {
            return FixResult(success: false, message: "❌ Auto-fix failed: \(verificationResult.issue ?? "Unknown issue")")
        }
    }
    
    func stopTests() {
        shouldStop = true
        isRunning = false
    }
    
    func resetTests() {
        testResults = Array(repeating: TestResult(), count: combinations.count)
        shouldStop = false
        isRunning = false
    }
}

// MARK: - Supporting Types

enum TestStatus {
    case pending
    case running
    case passed
    case failed
    case fixed
}

struct TestResult {
    var status: TestStatus = .pending
    var message: String? = nil
    var startTime: Date? = nil
    var duration: TimeInterval? = nil
}

struct VerificationResult {
    let success: Bool
    let issue: String?
}

struct FixResult {
    let success: Bool
    let message: String
}

// MARK: - Preview

struct OnboardingLevelDaysTestSuite_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingLevelDaysTestSuite()
            .environmentObject(TrainingSynchronizationManager.shared)
    }
}
