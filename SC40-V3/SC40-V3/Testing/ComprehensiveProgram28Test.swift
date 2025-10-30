import Foundation
import SwiftUI
import Combine

// MARK: - Comprehensive 28 Combination Program Test

/// Tests all 28 combinations (4 levels × 7 days) to ensure unique 12-week program formats
class ComprehensiveProgram28Test: ObservableObject {
    
    // MARK: - Test Results
    @Published var testResults: [CombinationTestResult] = []
    @Published var isRunning = false
    @Published var currentTest = 0
    @Published var totalTests = 28
    
    // MARK: - Test Data Storage
    private var programFingerprints: [String: ProgramFingerprint] = [:]
    private var sessionCounts: [String: Int] = [:]
    private var uniquePrograms: Set<String> = []
    
    // MARK: - Test Configuration
    private let levels: [TrainingLevel] = [.beginner, .intermediate, .advanced, .pro]
    private let dayOptions: [Int] = [1, 2, 3, 4, 5, 6, 7]
    
    // MARK: - Main Test Function
    
    /// Run comprehensive test of all 28 combinations
    func runComprehensiveTest() async {
        await MainActor.run {
            isRunning = true
            currentTest = 0
            testResults.removeAll()
            programFingerprints.removeAll()
            sessionCounts.removeAll()
            uniquePrograms.removeAll()
        }
        
        print("🧪 Starting Comprehensive 28 Combination Test")
        print("📊 Testing 4 levels × 7 days = 28 unique program formats")
        
        var testIndex = 0
        
        for level in levels {
            for days in dayOptions {
                testIndex += 1
                
                await MainActor.run {
                    currentTest = testIndex
                }
                
                print("\n🔍 Test \(testIndex)/28: \(level.rawValue.capitalized) × \(days) days")
                
                let result = await testSingleCombination(
                    level: level,
                    days: days,
                    testNumber: testIndex
                )
                
                await MainActor.run {
                    testResults.append(result)
                }
                
                // Small delay to prevent overwhelming the system
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        // Analyze results
        await analyzeTestResults()
        
        await MainActor.run {
            isRunning = false
        }
        
        print("\n✅ Comprehensive 28 Combination Test Complete!")
    }
    
    // MARK: - Single Combination Test
    
    private func testSingleCombination(level: TrainingLevel, days: Int, testNumber: Int) async -> CombinationTestResult {
        let startTime = Date()
        let combinationKey = "\(level.rawValue)_\(days)days"
        
        do {
            // Create temporary UserProfileViewModel for testing
            let tempUserProfile = UserProfileViewModel()
            tempUserProfile.profile.level = level.rawValue.capitalized
            tempUserProfile.profile.frequency = days
            
            // Generate the 12-week program
            tempUserProfile.refreshAdaptiveProgram()
            let allSessions = tempUserProfile.getAllStoredSessions()
            
            // Create program fingerprint for uniqueness testing
            let fingerprint = createProgramFingerprint(sessions: allSessions, level: level, days: days)
            programFingerprints[combinationKey] = fingerprint
            sessionCounts[combinationKey] = allSessions.count
            
            // Check for uniqueness
            let fingerprintString = fingerprint.toString()
            let isUnique = !uniquePrograms.contains(fingerprintString)
            uniquePrograms.insert(fingerprintString)
            
            // Validate program structure
            let validation = validateProgramStructure(sessions: allSessions, level: level, days: days)
            
            let duration = Date().timeIntervalSince(startTime)
            
            print("   📈 Generated \(allSessions.count) sessions")
            print("   🎯 Weeks: \(fingerprint.weekCount), Session Types: \(fingerprint.sessionTypes.count)")
            print("   ✅ Unique: \(isUnique ? "Yes" : "No")")
            print("   ⏱️ Duration: \(String(format: "%.2f", duration))s")
            
            return CombinationTestResult(
                level: level,
                days: days,
                testNumber: testNumber,
                sessionCount: allSessions.count,
                fingerprint: fingerprint,
                isUnique: isUnique,
                validation: validation,
                duration: duration,
                status: validation.isValid ? .passed : .failed,
                errorMessage: validation.isValid ? nil : validation.issues.joined(separator: ", ")
            )
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("   ❌ Error: \(error.localizedDescription)")
            
            return CombinationTestResult(
                level: level,
                days: days,
                testNumber: testNumber,
                sessionCount: 0,
                fingerprint: ProgramFingerprint.empty(),
                isUnique: false,
                validation: ProgramValidation(isValid: false, issues: [error.localizedDescription], recommendations: []),
                duration: duration,
                status: .failed,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    // MARK: - Program Fingerprinting
    
    private func createProgramFingerprint(sessions: [TrainingSession], level: TrainingLevel, days: Int) -> ProgramFingerprint {
        let weekCount = sessions.map { $0.week }.max() ?? 0
        let sessionTypes = Set(sessions.map { $0.type })
        let focusAreas = Set(sessions.map { $0.focus })
        let weeklyDistribution = Dictionary(grouping: sessions, by: { $0.week })
            .mapValues { $0.count }
        
        // Calculate complexity metrics
        let avgSessionsPerWeek = Double(sessions.count) / Double(weekCount)
        let sessionVariety = Double(sessionTypes.count)
        let focusVariety = Double(focusAreas.count)
        
        // Create unique pattern signature
        let patternSignature = sessions.prefix(12).map { session in
            "\(session.week).\(session.day):\(session.type.prefix(3))"
        }.joined(separator: "|")
        
        return ProgramFingerprint(
            level: level,
            days: days,
            sessionCount: sessions.count,
            weekCount: weekCount,
            sessionTypes: sessionTypes,
            focusAreas: focusAreas,
            weeklyDistribution: weeklyDistribution,
            avgSessionsPerWeek: avgSessionsPerWeek,
            sessionVariety: sessionVariety,
            focusVariety: focusVariety,
            patternSignature: patternSignature
        )
    }
    
    // MARK: - Program Validation
    
    private func validateProgramStructure(sessions: [TrainingSession], level: TrainingLevel, days: Int) -> ProgramValidation {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Validate session count expectations
        let expectedMinSessions = days * 10 // At least 10 weeks worth
        let expectedMaxSessions = days * 14 // At most 14 weeks worth
        
        if sessions.count < expectedMinSessions {
            issues.append("Too few sessions: \(sessions.count) < \(expectedMinSessions)")
        }
        if sessions.count > expectedMaxSessions {
            issues.append("Too many sessions: \(sessions.count) > \(expectedMaxSessions)")
        }
        
        // Validate week progression
        let weeks = Set(sessions.map { $0.week })
        if weeks.count < 10 {
            issues.append("Program too short: only \(weeks.count) weeks")
        }
        if weeks.count > 15 {
            issues.append("Program too long: \(weeks.count) weeks")
        }
        
        // Validate daily frequency adherence
        let weeklySessionCounts = Dictionary(grouping: sessions, by: { $0.week })
            .mapValues { $0.count }
        
        let invalidWeeks = weeklySessionCounts.filter { $0.value > days }
        if !invalidWeeks.isEmpty {
            issues.append("Weeks exceed daily limit: \(invalidWeeks.keys.sorted())")
        }
        
        // Validate session variety based on level
        let sessionTypes = Set(sessions.map { $0.type })
        let expectedMinVariety = min(days + 2, 8) // More days should have more variety
        
        if sessionTypes.count < expectedMinVariety {
            recommendations.append("Consider more session variety for \(level.rawValue) level")
        }
        
        // Level-specific validations
        switch level {
        case .beginner:
            if sessions.contains(where: { $0.type.lowercased().contains("advanced") }) {
                issues.append("Advanced sessions found in Beginner program")
            }
        case .pro:
            if !sessions.contains(where: { $0.type.lowercased().contains("elite") || $0.type.lowercased().contains("pro") }) {
                recommendations.append("Pro level should include elite/pro sessions")
            }
        default:
            break
        }
        
        return ProgramValidation(
            isValid: issues.isEmpty,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    // MARK: - Results Analysis
    
    private func analyzeTestResults() async {
        await MainActor.run {
            print("\n📊 COMPREHENSIVE TEST ANALYSIS")
            print("=" * 50)
            
            let passedTests = testResults.filter { $0.status == .passed }
            let failedTests = testResults.filter { $0.status == .failed }
            let uniquePrograms = Set(testResults.map { $0.fingerprint.toString() })
            
            print("✅ Passed: \(passedTests.count)/28")
            print("❌ Failed: \(failedTests.count)/28")
            print("🎯 Unique Programs: \(uniquePrograms.count)/28")
            print("📈 Total Sessions Generated: \(testResults.map { $0.sessionCount }.reduce(0, +))")
            
            // Session count analysis by level
            print("\n📊 SESSION COUNTS BY LEVEL:")
            for level in levels {
                let levelResults = testResults.filter { $0.level == level }
                let sessionCounts = levelResults.map { $0.sessionCount }
                let minSessions = sessionCounts.min() ?? 0
                let maxSessions = sessionCounts.max() ?? 0
                let avgSessions = sessionCounts.isEmpty ? 0 : sessionCounts.reduce(0, +) / sessionCounts.count
                
                print("   \(level.rawValue.capitalized): \(minSessions)-\(maxSessions) sessions (avg: \(avgSessions))")
            }
            
            // Session count analysis by days
            print("\n📊 SESSION COUNTS BY DAYS:")
            for days in dayOptions {
                let dayResults = testResults.filter { $0.days == days }
                let sessionCounts = dayResults.map { $0.sessionCount }
                let minSessions = sessionCounts.min() ?? 0
                let maxSessions = sessionCounts.max() ?? 0
                let avgSessions = sessionCounts.isEmpty ? 0 : sessionCounts.reduce(0, +) / sessionCounts.count
                
                print("   \(days) days/week: \(minSessions)-\(maxSessions) sessions (avg: \(avgSessions))")
            }
            
            // Uniqueness analysis
            print("\n🎯 PROGRAM UNIQUENESS ANALYSIS:")
            let duplicateFingerprints = Dictionary(grouping: testResults, by: { $0.fingerprint.toString() })
                .filter { $0.value.count > 1 }
            
            if duplicateFingerprints.isEmpty {
                print("   ✅ All 28 combinations produce unique programs!")
            } else {
                print("   ⚠️ Found \(duplicateFingerprints.count) duplicate program patterns:")
                for (fingerprint, results) in duplicateFingerprints {
                    let combinations = results.map { "\($0.level.rawValue)×\($0.days)" }.joined(separator: ", ")
                    print("     - \(combinations)")
                }
            }
            
            // Performance analysis
            let totalDuration = testResults.map { $0.duration }.reduce(0, +)
            let avgDuration = totalDuration / Double(testResults.count)
            print("\n⏱️ PERFORMANCE:")
            print("   Total Time: \(String(format: "%.2f", totalDuration))s")
            print("   Average per Test: \(String(format: "%.3f", avgDuration))s")
            
            // Failed test details
            if !failedTests.isEmpty {
                print("\n❌ FAILED TESTS:")
                for test in failedTests {
                    print("   \(test.level.rawValue.capitalized) × \(test.days) days: \(test.errorMessage ?? "Unknown error")")
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct CombinationTestResult {
    let level: TrainingLevel
    let days: Int
    let testNumber: Int
    let sessionCount: Int
    let fingerprint: ProgramFingerprint
    let isUnique: Bool
    let validation: ProgramValidation
    let duration: TimeInterval
    let status: TestStatus
    let errorMessage: String?
}

struct ProgramFingerprint {
    let level: TrainingLevel
    let days: Int
    let sessionCount: Int
    let weekCount: Int
    let sessionTypes: Set<String>
    let focusAreas: Set<String>
    let weeklyDistribution: [Int: Int]
    let avgSessionsPerWeek: Double
    let sessionVariety: Double
    let focusVariety: Double
    let patternSignature: String
    
    func toString() -> String {
        return "\(level.rawValue)_\(days)d_\(sessionCount)s_\(weekCount)w_\(sessionTypes.count)t_\(patternSignature.hashValue)"
    }
    
    static func empty() -> ProgramFingerprint {
        return ProgramFingerprint(
            level: .beginner,
            days: 1,
            sessionCount: 0,
            weekCount: 0,
            sessionTypes: [],
            focusAreas: [],
            weeklyDistribution: [:],
            avgSessionsPerWeek: 0,
            sessionVariety: 0,
            focusVariety: 0,
            patternSignature: ""
        )
    }
}

struct ProgramValidation {
    let isValid: Bool
    let issues: [String]
    let recommendations: [String]
}

enum TestStatus {
    case passed
    case failed
    case running
    case pending
}

// MARK: - TrainingLevel Extension

extension TrainingLevel {
    static let allCases: [TrainingLevel] = [.beginner, .intermediate, .advanced, .pro]
}

// MARK: - String Extension

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
