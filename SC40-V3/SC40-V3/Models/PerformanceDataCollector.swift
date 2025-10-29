import Foundation
import Combine

// MARK: - Performance Data Collector
// Collects and analyzes performance data to feed into algorithmic session generation

@MainActor
class PerformanceDataCollector: ObservableObject {
    
    static let shared = PerformanceDataCollector()
    
    @Published var currentPerformanceData: AlgorithmicSessionGenerator.PerformanceData?
    @Published var performanceHistory: [PerformanceSnapshot] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    struct PerformanceSnapshot {
        let date: Date
        let weekNumber: Int
        let averageTime: Double
        let bestTime: Double
        let sessionCount: Int
        let fatigueScore: Double
        let consistencyScore: Double
        let improvementRate: Double
    }
    
    init() {
        // Start collecting performance data
        startPerformanceTracking()
    }
    
    // MARK: - Performance Data Collection
    
    func collectSessionPerformance(from session: TrainingSession) {
        // Extract timing data from completed session
        let sessionTimes = extractTimingData(from: session)
        
        // Update performance metrics
        updatePerformanceMetrics(with: sessionTimes, session: session)
        
        // Trigger algorithmic optimization
        optimizeSessionGeneration()
    }
    
    private func extractTimingData(from session: TrainingSession) -> [Double] {
        // Extract actual sprint times from session
        // This would integrate with the actual timing system
        var times: [Double] = []
        
        for _ in session.sprints {
            // Simulate extracting times - in real implementation would get from GPS/timing data
            let baseTime = 5.0 // Base 40-yard time
            let variance = Double.random(in: -0.3...0.3)
            let sprintTime = baseTime + variance
            times.append(sprintTime)
        }
        
        return times
    }
    
    private func updatePerformanceMetrics(with times: [Double], session: TrainingSession) {
        guard !times.isEmpty else { return }
        
        let averageTime = times.reduce(0, +) / Double(times.count)
        let bestTime = times.min() ?? averageTime
        
        // Calculate consistency (lower variance = higher consistency)
        let variance = calculateVariance(times)
        let consistencyScore = max(0, 1.0 - (variance / 0.5)) // Normalize to 0-1
        
        // Calculate fatigue (performance degradation within session)
        let fatigueScore = calculateFatigueScore(times)
        
        // Calculate improvement rate (compare to historical data)
        let improvementRate = calculateImprovementRate(currentAverage: averageTime)
        
        // Create performance snapshot
        let snapshot = PerformanceSnapshot(
            date: Date(),
            weekNumber: session.week,
            averageTime: averageTime,
            bestTime: bestTime,
            sessionCount: session.sprints.count,
            fatigueScore: fatigueScore,
            consistencyScore: consistencyScore,
            improvementRate: improvementRate
        )
        
        // Add to history
        performanceHistory.append(snapshot)
        
        // Update current performance data for algorithmic use
        currentPerformanceData = AlgorithmicSessionGenerator.PerformanceData(
            averageTime: averageTime,
            improvementRate: improvementRate,
            fatigueLevel: fatigueScore,
            consistencyScore: consistencyScore,
            strengthLevel: calculateStrengthLevel(times)
        )
        
        // Keep only last 50 snapshots for performance
        if performanceHistory.count > 50 {
            performanceHistory.removeFirst(performanceHistory.count - 50)
        }
    }
    
    // MARK: - Performance Calculations
    
    private func calculateVariance(_ times: [Double]) -> Double {
        guard times.count > 1 else { return 0 }
        
        let mean = times.reduce(0, +) / Double(times.count)
        let squaredDifferences = times.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(times.count - 1)
    }
    
    private func calculateFatigueScore(_ times: [Double]) -> Double {
        guard times.count > 2 else { return 0 }
        
        // Compare first half vs second half of session
        let midPoint = times.count / 2
        let firstHalf = Array(times[0..<midPoint])
        let secondHalf = Array(times[midPoint..<times.count])
        
        let firstHalfAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondHalfAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        // Fatigue = performance degradation (higher time = more fatigue)
        let degradation = secondHalfAverage - firstHalfAverage
        return max(0, min(1.0, degradation / 0.5)) // Normalize to 0-1
    }
    
    private func calculateImprovementRate(currentAverage: Double) -> Double {
        guard performanceHistory.count >= 5 else { return 0.05 } // Default improvement rate
        
        // Compare current average to average from 5 sessions ago
        let recentSnapshots = performanceHistory.suffix(5)
        let oldAverage = recentSnapshots.first?.averageTime ?? currentAverage
        
        // Improvement rate = (old time - new time) / old time
        // Positive = improvement, negative = decline
        let improvement = (oldAverage - currentAverage) / oldAverage
        return max(-0.1, min(0.2, improvement)) // Clamp to reasonable range
    }
    
    private func calculateStrengthLevel(_ times: [Double]) -> Double {
        // Estimate strength level based on sprint performance consistency and speed
        guard !times.isEmpty else { return 0.5 }
        
        let bestTime = times.min() ?? 5.0
        let consistency = 1.0 - calculateVariance(times)
        
        // Strength correlates with speed and consistency
        let speedScore = max(0, (6.0 - bestTime) / 2.0) // Normalize 4.0-6.0s to 0-1
        let strengthLevel = (speedScore * 0.7) + (consistency * 0.3)
        
        return max(0, min(1.0, strengthLevel))
    }
    
    // MARK: - Algorithmic Optimization
    
    private func optimizeSessionGeneration() {
        // Trigger session library evolution based on performance data
        guard let performanceData = currentPerformanceData else { return }
        
        // Analyze performance trends
        let trends = analyzePerformanceTrends()
        
        // Generate optimization recommendations
        let recommendations = generateOptimizationRecommendations(
            performanceData: performanceData,
            trends: trends
        )
        
        // Log recommendations for science-based evolution
        logOptimizationRecommendations(recommendations)
    }
    
    func analyzePerformanceTrends() -> PerformanceTrends {
        guard performanceHistory.count >= 10 else {
            return PerformanceTrends(
                improvementTrend: .stable,
                consistencyTrend: .stable,
                fatigueTrend: .stable,
                strengthTrend: .stable
            )
        }
        
        let recent = performanceHistory.suffix(5)
        let older = performanceHistory.suffix(10).prefix(5)
        
        let recentImprovement = recent.map(\.improvementRate).reduce(0, +) / Double(recent.count)
        let olderImprovement = older.map(\.improvementRate).reduce(0, +) / Double(older.count)
        
        let recentConsistency = recent.map(\.consistencyScore).reduce(0, +) / Double(recent.count)
        let olderConsistency = older.map(\.consistencyScore).reduce(0, +) / Double(older.count)
        
        let recentFatigue = recent.map(\.fatigueScore).reduce(0, +) / Double(recent.count)
        let olderFatigue = older.map(\.fatigueScore).reduce(0, +) / Double(older.count)
        
        return PerformanceTrends(
            improvementTrend: determineTrend(recentImprovement, olderImprovement),
            consistencyTrend: determineTrend(recentConsistency, olderConsistency),
            fatigueTrend: determineTrend(recentFatigue, olderFatigue),
            strengthTrend: .stable // Simplified for now
        )
    }
    
    private func determineTrend(_ recent: Double, _ older: Double) -> PerformanceTrendDirection {
        let difference = recent - older
        if difference > 0.05 { return .improving }
        if difference < -0.05 { return .declining }
        return .stable
    }
    
    func generateOptimizationRecommendations(
        performanceData: AlgorithmicSessionGenerator.PerformanceData,
        trends: PerformanceTrends
    ) -> [OptimizationRecommendation] {
        
        var recommendations: [OptimizationRecommendation] = []
        
        // High fatigue recommendations
        if performanceData.fatigueLevel > 0.7 {
            recommendations.append(OptimizationRecommendation(
                type: .increaseRecovery,
                priority: .high,
                description: "Increase recovery sessions due to high fatigue",
                sessionTypeAdjustment: [.activeRecovery: 1.5, .recovery: 1.3]
            ))
        }
        
        // Low improvement recommendations
        if performanceData.improvementRate < 0.02 {
            recommendations.append(OptimizationRecommendation(
                type: .increaseVariety,
                priority: .medium,
                description: "Add variety to break performance plateau",
                sessionTypeAdjustment: [.plyometrics: 1.8, .comprehensive: 2.0]
            ))
        }
        
        // Low consistency recommendations
        if performanceData.consistencyScore < 0.6 {
            recommendations.append(OptimizationRecommendation(
                type: .focusFundamentals,
                priority: .high,
                description: "Focus on fundamentals to improve consistency",
                sessionTypeAdjustment: [.speed: 1.3, .tempo: 1.2]
            ))
        }
        
        // High strength recommendations
        if performanceData.strengthLevel > 0.8 {
            recommendations.append(OptimizationRecommendation(
                type: .increasePower,
                priority: .medium,
                description: "Leverage high strength with power sessions",
                sessionTypeAdjustment: [.plyometrics: 1.6, .flying: 1.3]
            ))
        }
        
        return recommendations
    }
    
    private func logOptimizationRecommendations(_ recommendations: [OptimizationRecommendation]) {
        for recommendation in recommendations {
            print("🧠 Performance Optimization: \(recommendation.description)")
            print("   Session Type Adjustments: \(recommendation.sessionTypeAdjustment)")
        }
    }
    
    // MARK: - Performance Tracking
    
    private func startPerformanceTracking() {
        // Set up periodic performance analysis
        Timer.publish(every: 86400, on: .main, in: .common) // Daily
            .autoconnect()
            .sink { [weak self] _ in
                self?.performDailyAnalysis()
            }
            .store(in: &cancellables)
    }
    
    private func performDailyAnalysis() {
        // Perform daily performance analysis and optimization
        guard !performanceHistory.isEmpty else { return }
        
        let trends = analyzePerformanceTrends()
        print("📊 Daily Performance Analysis:")
        print("   Improvement Trend: \(trends.improvementTrend)")
        print("   Consistency Trend: \(trends.consistencyTrend)")
        print("   Fatigue Trend: \(trends.fatigueTrend)")
        
        // Trigger session library evolution if needed
        if shouldEvolveSessionLibrary(trends: trends) {
            evolveSessionLibrary(trends: trends)
        }
    }
    
    private func shouldEvolveSessionLibrary(trends: PerformanceTrends) -> Bool {
        // Evolve library if performance is declining or stagnating
        return trends.improvementTrend == .declining || 
               (trends.improvementTrend == .stable && performanceHistory.count > 20)
    }
    
    private func evolveSessionLibrary(trends: PerformanceTrends) {
        print("🧬 Evolving session library based on performance data...")
        
        // This would trigger creation of new session types or modifications
        // Based on scientific principles and performance data
        
        // For now, log the evolution trigger
        print("   Triggered by trends: \(trends)")
        
        // Future implementation would:
        // 1. Analyze which session types are most/least effective
        // 2. Generate new session variations
        // 3. A/B test new sessions against existing ones
        // 4. Incorporate successful variations into the library
    }
}

// MARK: - Supporting Data Structures

struct PerformanceTrends {
    let improvementTrend: PerformanceTrendDirection
    let consistencyTrend: PerformanceTrendDirection
    let fatigueTrend: PerformanceTrendDirection
    let strengthTrend: PerformanceTrendDirection
}

enum PerformanceTrendDirection {
    case improving
    case stable
    case declining
}

struct OptimizationRecommendation {
    let type: OptimizationType
    let priority: Priority
    let description: String
    let sessionTypeAdjustment: [AlgorithmicSessionGenerator.AlgorithmicSessionType: Double]
    
    enum OptimizationType {
        case increaseRecovery
        case increaseVariety
        case focusFundamentals
        case increasePower
    }
    
    enum Priority {
        case high
        case medium
        case low
    }
}
