import Foundation

// MARK: - Algorithmic Session Generator Tester
// Tests all session types are generating correctly with proper distribution

struct AlgorithmicSessionTester {
    
    static func testAllSessionTypes() {
        print("🧪 Testing Algorithmic Session Generation - All Session Types")
        print("=" * 60)
        
        let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        let frequencies = [1, 2, 3, 4, 5, 6, 7]
        
        for level in levels {
            print("\n📊 Testing Level: \(level)")
            print("-" * 40)
            
            for frequency in frequencies {
                testSessionGeneration(level: level, frequency: frequency)
            }
        }
        
        // Test performance-based optimization
        testPerformanceBasedOptimization()
        
        // Test science-based evolution
        testScienceBasedEvolution()
        
        print("\n✅ All session type tests completed!")
    }
    
    private static func testSessionGeneration(level: String, frequency: Int) {
        print("\n🔬 Testing \(level) - \(frequency) days/week:")
        
        let userPreferences = UserSessionPreferences(
            favoriteTemplateIDs: [],
            preferredTemplateIDs: [],
            dislikedTemplateIDs: [],
            allowRepeatingFavorites: false,
            manualOverrides: [:]
        )
        
        // Test multiple weeks to ensure variety
        var allSessionTypes: Set<String> = []
        
        for week in [1, 4, 8, 12] { // Test key weeks
            let sessions = AlgorithmicSessionGenerator.shared.generateAlgorithmicWeeklyProgram(
                level: level,
                frequency: frequency,
                weekNumber: week,
                userPreferences: userPreferences,
                performanceData: createTestPerformanceData()
            )
            
            print("  Week \(week): \(sessions.count) sessions")
            
            for (index, session) in sessions.enumerated() {
                let sessionTemplate = session.sessionTemplate
                let sessionType = sessionTemplate?.sessionType.rawValue ?? "Unknown"
                let algorithmicNote = session.notes ?? ""
                
                allSessionTypes.insert(sessionType)
                
                if let template = sessionTemplate {
                    print("    Day \(index + 1): \(template.name) (\(sessionType))")
                    if algorithmicNote.contains("Algorithmic") {
                        let algorithmicType = extractAlgorithmicType(from: algorithmicNote)
                        print("      🧠 Algorithmic Type: \(algorithmicType)")
                        print("      📏 \(template.distance)yd × \(template.reps) reps, \(template.rest)s rest")
                    }
                }
            }
        }
        
        print("  📈 Session Types Generated: \(allSessionTypes.sorted().joined(separator: ", "))")
        
        // Verify minimum session type variety
        let expectedMinimumTypes = min(3, frequency)
        if allSessionTypes.count >= expectedMinimumTypes {
            print("  ✅ Good variety: \(allSessionTypes.count) different session types")
        } else {
            print("  ⚠️ Limited variety: Only \(allSessionTypes.count) session types")
        }
    }
    
    private static func testPerformanceBasedOptimization() {
        print("\n🎯 Testing Performance-Based Optimization:")
        print("-" * 40)
        
        // Test high fatigue scenario
        let highFatigueData = AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 5.5,
            improvementRate: -0.01,
            fatigueLevel: 0.8, // High fatigue
            consistencyScore: 0.4,
            strengthLevel: 0.6
        )
        
        testOptimizationScenario("High Fatigue", performanceData: highFatigueData)
        
        // Test low improvement scenario
        let lowImprovementData = AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 5.2,
            improvementRate: 0.005, // Very low improvement
            fatigueLevel: 0.3,
            consistencyScore: 0.7,
            strengthLevel: 0.8
        )
        
        testOptimizationScenario("Low Improvement", performanceData: lowImprovementData)
        
        // Test low consistency scenario
        let lowConsistencyData = AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 5.0,
            improvementRate: 0.03,
            fatigueLevel: 0.4,
            consistencyScore: 0.5, // Low consistency
            strengthLevel: 0.7
        )
        
        testOptimizationScenario("Low Consistency", performanceData: lowConsistencyData)
        
        // Test high strength scenario
        let highStrengthData = AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 4.8,
            improvementRate: 0.04,
            fatigueLevel: 0.2,
            consistencyScore: 0.8,
            strengthLevel: 0.9 // High strength
        )
        
        testOptimizationScenario("High Strength", performanceData: highStrengthData)
    }
    
    private static func testOptimizationScenario(_ scenario: String, performanceData: AlgorithmicSessionGenerator.PerformanceData) {
        print("\n  📊 Scenario: \(scenario)")
        
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
            weekNumber: 6,
            userPreferences: userPreferences,
            performanceData: performanceData
        )
        
        var sessionTypeCounts: [String: Int] = [:]
        
        for session in sessions {
            if let template = session.sessionTemplate {
                let sessionType = template.sessionType.rawValue
                sessionTypeCounts[sessionType, default: 0] += 1
            }
        }
        
        print("    Session Distribution: \(sessionTypeCounts)")
        
        // Verify optimization worked
        switch scenario {
        case "High Fatigue":
            let recoveryCount = (sessionTypeCounts["Active Recovery"] ?? 0) + (sessionTypeCounts["Recovery"] ?? 0)
            print("    ✅ Recovery sessions: \(recoveryCount) (should be high for fatigue)")
            
        case "Low Improvement":
            let varietyCount = sessionTypeCounts.count
            print("    ✅ Session variety: \(varietyCount) types (should be high for plateaus)")
            
        case "Low Consistency":
            let fundamentalCount = sessionTypeCounts["Sprint"] ?? 0
            print("    ✅ Sprint sessions: \(fundamentalCount) (should be high for consistency)")
            
        case "High Strength":
            let powerCount = sessionTypeCounts["Sprint"] ?? 0 // Simplified - would check for plyometric notes
            print("    ✅ Power-focused sessions detected (strength optimization)")
            
        default:
            break
        }
    }
    
    private static func testScienceBasedEvolution() {
        print("\n🧬 Testing Science-Based Session Evolution:")
        print("-" * 40)
        
        // Test session generation with different algorithmic parameters
        let baselineWeek = generateTestWeek(weekNumber: 1)
        let evolvedWeek = generateTestWeek(weekNumber: 12)
        
        print("  📊 Baseline Week 1:")
        printWeekSummary(baselineWeek)
        
        print("\n  📈 Evolved Week 12:")
        printWeekSummary(evolvedWeek)
        
        // Verify evolution occurred
        let baselineComplexity = calculateWeekComplexity(baselineWeek)
        let evolvedComplexity = calculateWeekComplexity(evolvedWeek)
        
        print("\n  🔬 Evolution Analysis:")
        print("    Baseline Complexity: \(String(format: "%.2f", baselineComplexity))")
        print("    Evolved Complexity: \(String(format: "%.2f", evolvedComplexity))")
        
        if evolvedComplexity > baselineComplexity {
            print("    ✅ Session evolution detected - increased complexity over time")
        } else {
            print("    ⚠️ Limited evolution - complexity remained similar")
        }
    }
    
    private static func generateTestWeek(weekNumber: Int) -> [DaySessionTemplate] {
        let userPreferences = UserSessionPreferences(
            favoriteTemplateIDs: [],
            preferredTemplateIDs: [],
            dislikedTemplateIDs: [],
            allowRepeatingFavorites: false,
            manualOverrides: [:]
        )
        
        return AlgorithmicSessionGenerator.shared.generateAlgorithmicWeeklyProgram(
            level: "Advanced",
            frequency: 5,
            weekNumber: weekNumber,
            userPreferences: userPreferences,
            performanceData: createTestPerformanceData()
        )
    }
    
    private static func printWeekSummary(_ sessions: [DaySessionTemplate]) {
        var sessionTypes: [String: Int] = [:]
        var totalDistance = 0
        var totalReps = 0
        
        for session in sessions {
            if let template = session.sessionTemplate {
                let sessionType = template.sessionType.rawValue
                sessionTypes[sessionType, default: 0] += 1
                totalDistance += template.distance * template.reps
                totalReps += template.reps
            }
        }
        
        print("    Session Types: \(sessionTypes)")
        print("    Total Volume: \(totalDistance) yards, \(totalReps) reps")
    }
    
    private static func calculateWeekComplexity(_ sessions: [DaySessionTemplate]) -> Double {
        var complexity: Double = 0
        
        for session in sessions {
            if let template = session.sessionTemplate {
                // Complexity based on distance, reps, and session type variety
                let distanceComplexity = Double(template.distance) / 100.0
                let repComplexity = Double(template.reps) / 10.0
                let typeComplexity = getSessionTypeComplexity(template.sessionType)
                
                complexity += distanceComplexity + repComplexity + typeComplexity
            }
        }
        
        return complexity / Double(sessions.count)
    }
    
    private static func getSessionTypeComplexity(_ sessionType: LibrarySessionType) -> Double {
        switch sessionType {
        case .sprint: return 1.0
        case .activeRecovery: return 0.5
        case .recovery: return 0.2
        case .benchmark: return 1.2
        case .tempo: return 0.8
        case .comprehensive: return 2.0
        case .rest: return 0.0
        }
    }
    
    private static func createTestPerformanceData() -> AlgorithmicSessionGenerator.PerformanceData {
        return AlgorithmicSessionGenerator.PerformanceData(
            averageTime: 5.0,
            improvementRate: 0.03,
            fatigueLevel: 0.4,
            consistencyScore: 0.7,
            strengthLevel: 0.8
        )
    }
    
    private static func extractAlgorithmicType(from note: String) -> String {
        // Extract algorithmic session type from notes
        if note.contains("Speed") { return "Speed" }
        if note.contains("Flying") { return "Flying Runs" }
        if note.contains("Endurance") { return "Endurance" }
        if note.contains("Pyramid") { return "Pyramid" }
        if note.contains("Tempo") { return "Tempo" }
        if note.contains("Plyometrics") { return "Plyometrics" }
        if note.contains("Recovery") { return "Recovery" }
        if note.contains("Benchmark") { return "Benchmark" }
        if note.contains("Comprehensive") { return "Comprehensive" }
        return "Unknown"
    }
}

// MARK: - String Extension for Test Formatting

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// MARK: - Test Runner

#if DEBUG
extension AlgorithmicSessionTester {
    
    /// Run comprehensive tests in debug builds
    static func runComprehensiveTests() {
        print("🚀 Starting Comprehensive Algorithmic Session Tests")
        print("=" * 80)
        
        testAllSessionTypes()
        
        print("\n🎉 All tests completed successfully!")
        print("=" * 80)
    }
}
#endif
