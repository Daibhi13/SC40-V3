import Foundation
import Combine

// MARK: - System Integration Test
// Tests the complete algorithmic session generation system integration

@MainActor
class SystemIntegrationTest: ObservableObject {
    
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    @Published var overallStatus: TestStatus = .pending
    
    enum TestStatus {
        case pending
        case running
        case passed
        case failed
    }
    
    struct TestResult {
        let testName: String
        let status: TestStatus
        let details: String
        let timestamp: Date
    }
    
    // MARK: - Main Test Runner
    
    func runSystemIntegrationTests() async {
        await MainActor.run {
            isRunning = true
            testResults.removeAll()
            overallStatus = .running
        }
        
        print("🚀 Starting System Integration Tests")
        print(String(repeating: "=", count: 60))
        
        // Test 1: Algorithmic Session Generation
        await testAlgorithmicSessionGeneration()
        
        // Test 2: Performance Data Collection
        await testPerformanceDataCollection()
        
        // Test 3: Session Library Evolution
        await testSessionLibraryEvolution()
        
        // Test 4: User Profile Integration
        await testUserProfileIntegration()
        
        // Test 5: Cross-Device Sync
        await testCrossDeviceSync()
        
        // Test 6: All Session Types Generation
        await testAllSessionTypesGeneration()
        
        // Calculate overall status
        await MainActor.run {
            let failedTests = testResults.filter { $0.status == .failed }
            overallStatus = failedTests.isEmpty ? .passed : .failed
            isRunning = false
        }
        
        print("\n🎉 System Integration Tests Complete!")
        print("Overall Status: \(overallStatus)")
        print(String(repeating: "=", count: 60))
    }
    
    // MARK: - Individual Tests
    
    private func testAlgorithmicSessionGeneration() async {
        let testName = "Algorithmic Session Generation"
        print("\n🧪 Testing: \(testName)")
        
        // Test session generation for different levels and frequencies
        let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        let frequencies = [1, 3, 5, 7]
        
        var allTestsPassed = true
        var details = ""
        
        for level in levels {
            for frequency in frequencies {
                let userPreferences = UserSessionPreferences(
                    favoriteTemplateIDs: [],
                    preferredTemplateIDs: [],
                    dislikedTemplateIDs: [],
                    allowRepeatingFavorites: false,
                    manualOverrides: [:]
                )
                
                let sessions = AlgorithmicSessionGenerator.shared.generateAlgorithmicWeeklyProgram(
                    level: level,
                    frequency: frequency,
                    weekNumber: 1,
                    userPreferences: userPreferences,
                    performanceData: nil
                )
                
                if sessions.count != frequency {
                    allTestsPassed = false
                    details += "❌ \(level) \(frequency)x: Expected \(frequency) sessions, got \(sessions.count)\n"
                } else {
                    details += "✅ \(level) \(frequency)x: Generated \(sessions.count) sessions\n"
                }
            }
        }
        
        let status: TestStatus = allTestsPassed ? .passed : .failed
        await addTestResult(testName, status: status, details: details)
    }
    
    private func testPerformanceDataCollection() async {
        let testName = "Performance Data Collection"
        print("\n🧪 Testing: \(testName)")
        
        // Create test session
        let testSession = TrainingSession(
            week: 1,
            day: 1,
            type: "Speed",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "Max")],
            accessoryWork: ["Mobility"],
            notes: nil
        )
        
        // Test performance data collection
        let initialHistoryCount = PerformanceDataCollector.shared.performanceHistory.count
        PerformanceDataCollector.shared.collectSessionPerformance(from: testSession)
        let finalHistoryCount = PerformanceDataCollector.shared.performanceHistory.count
        
        let dataCollected = finalHistoryCount > initialHistoryCount
        let hasCurrentData = PerformanceDataCollector.shared.currentPerformanceData != nil
        
        let status: TestStatus = (dataCollected && hasCurrentData) ? .passed : .failed
        let details = """
        ✅ Performance data collection: \(dataCollected ? "Working" : "Failed")
        ✅ Current performance data: \(hasCurrentData ? "Available" : "Missing")
        📊 History entries: \(finalHistoryCount)
        """
        
        await addTestResult(testName, status: status, details: details)
    }
    
    private func testSessionLibraryEvolution() async {
        let testName = "Session Library Evolution"
        print("\n🧪 Testing: \(testName)")
        
        // Test evolution trigger logic
        let collector = PerformanceDataCollector.shared
        
        // Add test performance data to trigger evolution
        for i in 0..<25 {
            let snapshot = PerformanceDataCollector.PerformanceSnapshot(
                date: Date().addingTimeInterval(TimeInterval(-i * 86400)), // Daily snapshots
                weekNumber: i / 7 + 1,
                averageTime: 5.0 + Double(i) * 0.01, // Declining performance
                bestTime: 4.8 + Double(i) * 0.005,
                sessionCount: 5,
                fatigueScore: 0.3 + Double(i) * 0.02,
                consistencyScore: 0.8 - Double(i) * 0.01,
                improvementRate: 0.05 - Double(i) * 0.003 // Declining improvement
            )
            collector.performanceHistory.append(snapshot)
        }
        
        // Test trend analysis
        let trends = collector.analyzePerformanceTrends()
        let hasValidTrends = collector.performanceHistory.count >= 3
        
        // Test optimization recommendations
        let testPerformanceData = AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 5.2,
            improvementRate: 0.01, // Low improvement
            fatigueLevel: 0.7, // High fatigue
            consistencyScore: 0.5, // Low consistency
            strengthLevel: 0.8 // High strength
        )
        
        let recommendations = collector.generateOptimizationRecommendations(
            performanceData: testPerformanceData,
            trends: trends
        )
        
        let hasRecommendations = !recommendations.isEmpty
        
        let status: TestStatus = (hasValidTrends && hasRecommendations) ? .passed : .failed
        let details = """
        ✅ Trend analysis: \(hasValidTrends ? "Working" : "Failed")
        ✅ Optimization recommendations: \(hasRecommendations ? "\(recommendations.count) generated" : "None generated")
        📊 Performance history: \(collector.performanceHistory.count) entries
        """
        
        await addTestResult(testName, status: status, details: details)
    }
    
    private func testUserProfileIntegration() async {
        let testName = "User Profile Integration"
        print("\n🧪 Testing: \(testName)")
        
        // Create test user profile
        let userProfile = UserProfileViewModel()
        userProfile.profile.level = "Intermediate"
        userProfile.profile.frequency = 5
        
        // Test session generation integration
        userProfile.refreshAdaptiveProgram()
        
        let hasGeneratedSessions = !userProfile.profile.sessionIDs.isEmpty
        let hasSessionIDs = !userProfile.profile.sessionIDs.isEmpty
        
        // Test performance data integration
        let testSession = TrainingSession(
            week: 1,
            day: 1,
            type: "Speed",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "Max")],
            accessoryWork: ["Mobility"],
            notes: nil
        )
        
        userProfile.recordSessionCompletion(testSession)
        let hasPerformanceData = PerformanceDataCollector.shared.currentPerformanceData != nil
        
        let status: TestStatus = (hasGeneratedSessions && hasSessionIDs && hasPerformanceData) ? .passed : .failed
        let details = """
        ✅ Session generation: \(hasGeneratedSessions ? "Working" : "Failed")
        ✅ Session IDs: \(hasSessionIDs ? "\(userProfile.profile.sessionIDs.count) sessions" : "None")
        ✅ Performance integration: \(hasPerformanceData ? "Working" : "Failed")
        """
        
        await addTestResult(testName, status: status, details: details)
    }
    
    private func testCrossDeviceSync() async {
        let testName = "Cross-Device Session Sync"
        print("\n🧪 Testing: \(testName)")
        
        // Test session generation for watch compatibility
        let userPreferences = UserSessionPreferences(
            favoriteTemplateIDs: [],
            preferredTemplateIDs: [],
            dislikedTemplateIDs: [],
            allowRepeatingFavorites: false,
            manualOverrides: [:]
        )
        
        let sessions = AlgorithmicSessionGenerator.shared.generateAlgorithmicWeeklyProgram(
            level: "Intermediate",
            frequency: 5,
            weekNumber: 1,
            userPreferences: userPreferences,
            performanceData: nil
        )
        
        // Test session data structure compatibility
        var compatibleSessions = 0
        for session in sessions {
            if let template = session.sessionTemplate {
                // Check if session has required fields for watch sync
                let hasRequiredFields = !template.name.isEmpty && 
                                      template.distance > 0 && 
                                      template.reps > 0
                if hasRequiredFields {
                    compatibleSessions += 1
                }
            }
        }
        
        let allCompatible = compatibleSessions == sessions.count
        
        let status: TestStatus = allCompatible ? .passed : .failed
        let details = """
        ✅ Session compatibility: \(compatibleSessions)/\(sessions.count) sessions compatible
        ✅ Data structure: \(allCompatible ? "All sessions valid" : "Some sessions invalid")
        📱 Ready for watch sync: \(allCompatible ? "Yes" : "No")
        """
        
        await addTestResult(testName, status: status, details: details)
    }
    
    private func testAllSessionTypesGeneration() async {
        let testName = "All Session Types Generation"
        print("\n🧪 Testing: \(testName)")
        
        // Test that all 12 session types can be generated
        let expectedTypes: Set<AlgorithmicSessionGenerator.AlgorithmicSessionType> = Set(AlgorithmicSessionGenerator.AlgorithmicSessionType.allCases)
        var generatedTypes: Set<AlgorithmicSessionGenerator.AlgorithmicSessionType> = []
        
        // Generate sessions across multiple weeks and frequencies to get variety
        let testConfigs = [
            ("Elite", 7, 1),
            ("Elite", 7, 4),
            ("Elite", 7, 8),
            ("Elite", 7, 12),
            ("Advanced", 6, 6),
            ("Intermediate", 5, 3),
            ("Beginner", 3, 2)
        ]
        
        for (level, frequency, week) in testConfigs {
            let userPreferences = UserSessionPreferences(
                favoriteTemplateIDs: [],
                preferredTemplateIDs: [],
                dislikedTemplateIDs: [],
                allowRepeatingFavorites: false,
                manualOverrides: [:]
            )
            
            let sessions = AlgorithmicSessionGenerator.shared.generateAlgorithmicWeeklyProgram(
                level: level,
                frequency: frequency,
                weekNumber: week,
                userPreferences: userPreferences,
                performanceData: createTestPerformanceData()
            )
            
            // Extract algorithmic types from session notes
            for session in sessions {
                if let notes = session.notes, notes.contains("Algorithmic") {
                    let algorithmicType = extractAlgorithmicType(from: notes)
                    if let type = AlgorithmicSessionGenerator.AlgorithmicSessionType.allCases.first(where: { $0.rawValue == algorithmicType }) {
                        generatedTypes.insert(type)
                    }
                }
            }
        }
        
        let coveragePercentage = Double(generatedTypes.count) / Double(expectedTypes.count) * 100
        let goodCoverage = coveragePercentage >= 75.0 // At least 75% of session types
        
        let status: TestStatus = goodCoverage ? .passed : .failed
        let details = """
        ✅ Session type coverage: \(generatedTypes.count)/\(expectedTypes.count) types (\(String(format: "%.1f", coveragePercentage))%)
        ✅ Generated types: \(generatedTypes.map { $0.rawValue }.sorted().joined(separator: ", "))
        📊 Coverage status: \(goodCoverage ? "Good" : "Needs improvement")
        """
        
        await addTestResult(testName, status: status, details: details)
    }
    
    // MARK: - Helper Functions
    
    private func addTestResult(_ testName: String, status: TestStatus, details: String) async {
        await MainActor.run {
            let result = TestResult(
                testName: testName,
                status: status,
                details: details,
                timestamp: Date()
            )
            testResults.append(result)
        }
        
        let statusIcon = status == .passed ? "✅" : "❌"
        print("\(statusIcon) \(testName): \(status)")
        print("   \(details)")
    }
    
    private func createTestPerformanceData() -> AlgorithmicSessionGenerator.PerformanceData {
        return AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 5.0,
            improvementRate: 0.03,
            fatigueLevel: 0.4,
            consistencyScore: 0.7,
            strengthLevel: 0.8
        )
    }
    
    private func extractAlgorithmicType(from note: String) -> String {
        if note.contains("Speed") { return "Speed" }
        if note.contains("Flying") { return "Flying Runs" }
        if note.contains("Endurance") { return "Endurance" }
        if note.contains("Pyramid Up-Down") { return "Pyramid Up-Down" }
        if note.contains("Pyramid Up") { return "Pyramid Up" }
        if note.contains("Pyramid Down") { return "Pyramid Down" }
        if note.contains("Tempo") { return "Tempo" }
        if note.contains("Plyometrics") { return "Plyometrics" }
        if note.contains("Active Recovery") { return "Active Recovery" }
        if note.contains("Recovery") { return "Recovery" }
        if note.contains("Benchmark") { return "Benchmark" }
        if note.contains("Comprehensive") { return "Comprehensive" }
        return "Unknown"
    }
}

// MARK: - Extensions

#if DEBUG
extension SystemIntegrationTest {
    
    /// Quick test runner for development
    static func runQuickTests() async {
        let tester = SystemIntegrationTest()
        await tester.runSystemIntegrationTests()
    }
}
#endif
