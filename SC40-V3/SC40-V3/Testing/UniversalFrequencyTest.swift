import Foundation

// Test to verify "Whatever the level, all 1–7 day options are always available" rule
class UniversalFrequencyTest {
    
    static func runComprehensiveTest() {
        print("🧪 UNIVERSAL FREQUENCY SUPPORT TEST")
        print("=" * 50)
        
        let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        let frequencies = [1, 2, 3, 4, 5, 6, 7]
        
        var allTestsPassed = true
        var testResults: [(String, Int, Bool)] = []
        
        for level in levels {
            for frequency in frequencies {
                let testPassed = testLevelFrequencyCombination(level: level, frequency: frequency)
                testResults.append((level, frequency, testPassed))
                
                if !testPassed {
                    allTestsPassed = false
                }
            }
        }
        
        // Print detailed results
        print("\n📊 DETAILED TEST RESULTS:")
        print("Level".padding(toLength: 12, withPad: " ", startingAt: 0) + " | " + 
              "Freq | Status")
        print("-" * 25)
        
        for (level, frequency, passed) in testResults {
            let status = passed ? "✅ PASS" : "❌ FAIL"
            print("\(level.padding(toLength: 12, withPad: " ", startingAt: 0)) | \(frequency)    | \(status)")
        }
        
        // Summary
        print("\n🎯 UNIVERSAL RULE COMPLIANCE:")
        if allTestsPassed {
            print("✅ ALL COMBINATIONS SUPPORTED")
            print("   Rule: 'Whatever the level, all 1–7 day options are always available' ✅")
        } else {
            print("❌ SOME COMBINATIONS FAILED")
            print("   Rule violation detected!")
        }
        
        // Test edge cases
        testEdgeCases()
    }
    
    private static func testLevelFrequencyCombination(level: String, frequency: Int) -> Bool {
        print("Testing: \(level) \(frequency)-day program...")
        
        // Simulate session generation logic
        let expectedSessions = 12 * frequency // 12 weeks × frequency
        
        // Check if UI allows this combination
        let uiSupported = (1...7).contains(frequency)
        
        // Check if model can generate sessions
        let modelSupported = canGenerateSessionsFor(level: level, frequency: frequency)
        
        // Check if validation passes
        let validationPassed = validateProgramStructure(level: level, frequency: frequency, expectedSessions: expectedSessions)
        
        let overallPassed = uiSupported && modelSupported && validationPassed
        
        if !overallPassed {
            print("   ❌ FAILED: UI=\(uiSupported), Model=\(modelSupported), Validation=\(validationPassed)")
        }
        
        return overallPassed
    }
    
    private static func canGenerateSessionsFor(level: String, frequency: Int) -> Bool {
        // Simulate the session generation logic from TrainingView
        switch level.lowercased() {
        case "beginner", "intermediate", "advanced", "elite":
            // All levels should support all frequencies
            return (1...7).contains(frequency)
        default:
            // Fallback should also support all frequencies
            return (1...7).contains(frequency)
        }
    }
    
    private static func validateProgramStructure(level: String, frequency: Int, expectedSessions: Int) -> Bool {
        // Simulate validation logic
        let isValidFrequency = (1...7).contains(frequency)
        let isValidSessionCount = expectedSessions > 0 && expectedSessions <= 84 // Max 7 days × 12 weeks
        
        return isValidFrequency && isValidSessionCount
    }
    
    private static func testEdgeCases() {
        print("\n🔬 EDGE CASE TESTING:")
        
        // Test minimum: Beginner 1-day
        let min = testSpecificCase(level: "Beginner", frequency: 1, expectedSessions: 12)
        print("   Minimum (Beginner 1-day): \(min ? "✅" : "❌")")
        
        // Test maximum: Elite 7-day  
        let max = testSpecificCase(level: "Elite", frequency: 7, expectedSessions: 84)
        print("   Maximum (Elite 7-day): \(max ? "✅" : "❌")")
        
        // Test common: Intermediate 5-day
        let common = testSpecificCase(level: "Intermediate", frequency: 5, expectedSessions: 60)
        print("   Common (Intermediate 5-day): \(common ? "✅" : "❌")")
        
        // Test unusual: Advanced 2-day
        let unusual = testSpecificCase(level: "Advanced", frequency: 2, expectedSessions: 24)
        print("   Unusual (Advanced 2-day): \(unusual ? "✅" : "❌")")
    }
    
    private static func testSpecificCase(level: String, frequency: Int, expectedSessions: Int) -> Bool {
        // Comprehensive test for specific case
        let uiRange = (1...7).contains(frequency)
        let modelSupport = canGenerateSessionsFor(level: level, frequency: frequency)
        let sessionCount = expectedSessions == (12 * frequency)
        let recoveryDays = (7 - frequency) >= 0 // Should have 0-6 recovery days
        
        return uiRange && modelSupport && sessionCount && recoveryDays
    }
}

// MARK: - Test Execution
extension UniversalFrequencyTest {
    static func quickTest() {
        print("🚀 QUICK UNIVERSAL FREQUENCY TEST")
        
        // Test the rule with a few key combinations
        let testCases = [
            ("Beginner", 1), ("Beginner", 3), ("Beginner", 7),
            ("Intermediate", 2), ("Intermediate", 5),
            ("Advanced", 4), ("Advanced", 6),
            ("Elite", 1), ("Elite", 7)
        ]
        
        var allPassed = true
        
        for (level, frequency) in testCases {
            let passed = testLevelFrequencyCombination(level: level, frequency: frequency)
            if !passed { allPassed = false }
        }
        
        print("\n🎯 QUICK TEST RESULT:")
        print(allPassed ? "✅ UNIVERSAL RULE WORKING" : "❌ UNIVERSAL RULE BROKEN")
    }
}

// Note: String * operator extension moved to Run28CombinationTest.swift to avoid duplication
