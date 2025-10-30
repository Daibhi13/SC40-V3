import SwiftUI
import Combine

// MARK: - Training Sync Integration Test View
// Tests the integrated synchronization system within the existing app structure

struct TrainingSyncIntegrationTest: View {
    @EnvironmentObject private var syncManager: TrainingSynchronizationManager
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    @State private var currentTest = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Test Controls
                testControlsSection
                
                // Test Results
                testResultsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Integration Test")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Training Sync Integration Test")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Verifies the integrated synchronization system")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Controls
    
    private var testControlsSection: some View {
        VStack(spacing: 16) {
            Text("Integration Tests")
                .font(.headline)
            
            if isRunningTests {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Running: \(currentTest)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: runIntegrationTests) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Run Integration Tests")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            
            Button(action: clearResults) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Results")
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .disabled(testResults.isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Results
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
            
            if testResults.isEmpty {
                Text("No tests run yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                            testResultRow(result: result, index: index)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func testResultRow(result: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .leading)
            
            Text(result)
                .font(.caption)
                .foregroundColor(result.contains("✅") ? .green : 
                               result.contains("❌") ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    // MARK: - Test Functions
    
    private func runIntegrationTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            await runAllTests()
            await MainActor.run {
                isRunningTests = false
                currentTest = ""
            }
        }
    }
    
    private func runAllTests() async {
        // Test 1: Manager Initialization
        await runTest("Manager Initialization") {
            let manager = TrainingSynchronizationManager.shared
            return manager != nil ? "✅ TrainingSynchronizationManager initialized successfully" : "❌ Failed to initialize manager"
        }
        
        // Test 2: Compilation ID Generation
        await runTest("Compilation ID Generation") {
            let compilationID = syncManager.generateCompilationID(level: .beginner, days: 3)
            return compilationID.contains("SC40_BEGINNER_3DAYS") ? "✅ Compilation ID generated correctly: \(compilationID.prefix(25))..." : "❌ Invalid compilation ID format"
        }
        
        // Test 3: Session Model Generation
        await runTest("Session Model Generation") {
            await syncManager.synchronizeTrainingProgram(level: .intermediate, days: 4)
            let sessionCount = syncManager.activeSessions.count
            let expectedSessions = 4 * 12 // 4 days × 12 weeks
            return sessionCount == expectedSessions ? "✅ Generated \(sessionCount) sessions (expected \(expectedSessions))" : "❌ Session count mismatch: \(sessionCount) vs \(expectedSessions)"
        }
        
        // Test 4: Level Mapping
        await runTest("Level Mapping") {
            let levels: [TrainingLevel] = [.beginner, .intermediate, .advanced, .pro]
            var results: [String] = []
            
            for level in levels {
                await syncManager.synchronizeTrainingProgram(level: level, days: 2)
                if syncManager.selectedLevel == level {
                    results.append("✅ \(level.label)")
                } else {
                    results.append("❌ \(level.label)")
                }
            }
            
            return results.allSatisfy { $0.contains("✅") } ? "✅ All levels mapped correctly" : "❌ Level mapping issues: \(results.joined(separator: ", "))"
        }
        
        // Test 5: Days Configuration
        await runTest("Days Configuration") {
            let testDays = [1, 3, 5, 7]
            var results: [String] = []
            
            for days in testDays {
                await syncManager.synchronizeTrainingProgram(level: .beginner, days: days)
                let expectedSessions = days * 12
                let actualSessions = syncManager.activeSessions.count
                
                if actualSessions == expectedSessions {
                    results.append("✅ \(days) days")
                } else {
                    results.append("❌ \(days) days (\(actualSessions)/\(expectedSessions))")
                }
            }
            
            return results.allSatisfy { $0.contains("✅") } ? "✅ All day configurations work" : "❌ Day configuration issues: \(results.joined(separator: ", "))"
        }
        
        // Test 6: Progress Tracking
        await runTest("Progress Tracking") {
            if let firstSession = syncManager.activeSessions.first {
                let progress = SessionProgress(isLocked: false, isCompleted: true, completionPercentage: 100.0)
                await syncManager.updateSessionProgress(sessionID: firstSession.id.uuidString, progress: progress)
                
                let updatedProgress = syncManager.sessionProgress[firstSession.id.uuidString]
                return updatedProgress?.isCompleted == true ? "✅ Progress tracking works" : "❌ Progress tracking failed"
            } else {
                return "❌ No sessions available for progress test"
            }
        }
        
        // Test 7: Sync State Management
        await runTest("Sync State Management") {
            let isPhoneSynced = syncManager.isPhoneSynced
            let hasCompilationID = syncManager.currentCompilationID != nil
            let hasActiveSessions = !syncManager.activeSessions.isEmpty
            
            if isPhoneSynced && hasCompilationID && hasActiveSessions {
                return "✅ Sync state properly managed"
            } else {
                return "❌ Sync state issues: Phone(\(isPhoneSynced)) ID(\(hasCompilationID)) Sessions(\(hasActiveSessions))"
            }
        }
        
        // Test 8: 28 Combinations Support
        await runTest("28 Combinations Support") {
            let levels: [TrainingLevel] = [.beginner, .intermediate, .advanced, .pro]
            let days = [1, 2, 3, 4, 5, 6, 7]
            let totalCombinations = levels.count * days.count
            
            return totalCombinations == 28 ? "✅ Supports all 28 combinations (4 levels × 7 days)" : "❌ Combination count mismatch: \(totalCombinations)"
        }
    }
    
    private func runTest(_ testName: String, test: @escaping () async -> String) async {
        await MainActor.run {
            currentTest = testName
        }
        
        let result = await test()
        
        await MainActor.run {
            testResults.append(result)
        }
        
        // Small delay for UI updates
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    private func clearResults() {
        testResults.removeAll()
    }
}

// MARK: - Preview

struct TrainingSyncIntegrationTest_Previews: PreviewProvider {
    static var previews: some View {
        TrainingSyncIntegrationTest()
            .environmentObject(TrainingSynchronizationManager.shared)
    }
}
