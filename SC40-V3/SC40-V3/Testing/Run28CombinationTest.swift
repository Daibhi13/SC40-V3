import Foundation

// MARK: - Command Line 28 Combination Test Runner

/// Simple command-line test runner for the 28 combination program test
class Run28CombinationTest {
    
    static func main() async {
        print("🚀 SC40-V3: 28 Combination Program Test")
        print("=" * 50)
        print("Testing all combinations: 4 levels × 7 days = 28 unique programs")
        print("Expected: Each combination should generate a different 12-week program format\n")
        
        let testRunner = ComprehensiveProgram28Test()
        
        // Run the comprehensive test
        await testRunner.runComprehensiveTest()
        
        // Print final summary
        printFinalSummary(testRunner.testResults)
    }
    
    private static func printFinalSummary(_ results: [CombinationTestResult]) {
        print("\n🎯 FINAL TEST SUMMARY")
        print("=" * 50)
        
        let passedTests = results.filter { $0.status == .passed }
        let failedTests = results.filter { $0.status == .failed }
        let uniquePrograms = Set(results.map { $0.fingerprint.toString() })
        
        // Overall results
        print("📊 OVERALL RESULTS:")
        print("   ✅ Passed: \(passedTests.count)/28 (\(Int(Double(passedTests.count)/28.0 * 100))%)")
        print("   ❌ Failed: \(failedTests.count)/28 (\(Int(Double(failedTests.count)/28.0 * 100))%)")
        print("   🎯 Unique Programs: \(uniquePrograms.count)/28 (\(Int(Double(uniquePrograms.count)/28.0 * 100))%)")
        
        // Success criteria
        print("\n🎯 SUCCESS CRITERIA:")
        let allPassed = failedTests.isEmpty
        let allUnique = uniquePrograms.count == 28
        let validSessionCounts = results.allSatisfy { $0.sessionCount > 0 }
        
        print("   \(allPassed ? "✅" : "❌") All tests pass")
        print("   \(allUnique ? "✅" : "❌") All programs are unique")
        print("   \(validSessionCounts ? "✅" : "❌") All programs generate sessions")
        
        let overallSuccess = allPassed && allUnique && validSessionCounts
        print("\n🏆 OVERALL: \(overallSuccess ? "✅ SUCCESS" : "❌ NEEDS ATTENTION")")
        
        if overallSuccess {
            print("🎉 All 28 combinations generate unique 12-week program formats!")
        } else {
            print("⚠️ Some combinations need attention. Check the detailed results above.")
        }
        
        // Performance summary
        let totalDuration = results.map { $0.duration }.reduce(0, +)
        let avgDuration = totalDuration / Double(results.count)
        print("\n⏱️ PERFORMANCE:")
        print("   Total Time: \(String(format: "%.2f", totalDuration))s")
        print("   Average per Test: \(String(format: "%.3f", avgDuration))s")
        print("   Tests per Second: \(String(format: "%.1f", Double(results.count) / totalDuration))")
        
        // Session statistics
        let sessionCounts = results.map { $0.sessionCount }
        let minSessions = sessionCounts.min() ?? 0
        let maxSessions = sessionCounts.max() ?? 0
        let totalSessions = sessionCounts.reduce(0, +)
        let avgSessions = Double(totalSessions) / Double(sessionCounts.count)
        
        print("\n📈 SESSION STATISTICS:")
        print("   Total Sessions Generated: \(totalSessions)")
        print("   Range: \(minSessions) - \(maxSessions) sessions")
        print("   Average: \(String(format: "%.1f", avgSessions)) sessions per program")
        
        // Level breakdown
        print("\n📊 BREAKDOWN BY LEVEL:")
        for level in [TrainingLevel.beginner, .intermediate, .advanced, .pro] {
            let levelResults = results.filter { $0.level == level }
            let levelPassed = levelResults.filter { $0.status == .passed }.count
            let levelSessions = levelResults.map { $0.sessionCount }
            let levelAvg = levelSessions.isEmpty ? 0 : levelSessions.reduce(0, +) / levelSessions.count
            
            print("   \(level.rawValue.capitalized): \(levelPassed)/7 passed, avg \(levelAvg) sessions")
        }
        
        // Days breakdown
        print("\n📊 BREAKDOWN BY DAYS:")
        for days in 1...7 {
            let dayResults = results.filter { $0.days == days }
            let dayPassed = dayResults.filter { $0.status == .passed }.count
            let daySessions = dayResults.map { $0.sessionCount }
            let dayAvg = daySessions.isEmpty ? 0 : daySessions.reduce(0, +) / daySessions.count
            
            print("   \(days) days/week: \(dayPassed)/4 passed, avg \(dayAvg) sessions")
        }
        
        // Failed tests detail
        if !failedTests.isEmpty {
            print("\n❌ FAILED TESTS DETAIL:")
            for test in failedTests {
                print("   \(test.level.rawValue.capitalized) × \(test.days) days: \(test.errorMessage ?? "Unknown error")")
            }
        }
        
        print("\n" + "=" * 50)
        print("🏁 Test Complete!")
    }
}

// Note: String * operator extension moved to ComprehensiveProgram28Test.swift to avoid duplication

// MARK: - Entry Point

// Uncomment to run as standalone test
// Task {
//     await Run28CombinationTest.main()
// }
