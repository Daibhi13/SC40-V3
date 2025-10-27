import Foundation
import Algorithms
import Combine

/// Advanced analytics using Swift Algorithms for performance insights
class AlgorithmicAnalytics: ObservableObject {
    static let shared = AlgorithmicAnalytics()
    
    // MARK: - Time Series Analysis
    
    /// Analyze sprint time progression using advanced algorithms
    func analyzeSprintProgression(_ times: [Double]) -> ProgressionAnalysis {
        guard times.count >= 3 else {
            return ProgressionAnalysis(trend: .inconsistent, confidence: 0.0, predictions: [])
        }
        
        // Use windows() for moving averages
        let windowSize = min(5, times.count / 2)
        let movingAverages = times
            .windows(ofCount: windowSize)
            .map { window in
                Array(window).reduce(0, +) / Double(window.count)
            }
        
        // Calculate trend using adjacent pairs
        let trendChanges = movingAverages
            .adjacentPairs()
            .map { prev, current in (current - prev) / prev }
        
        let avgTrendChange = trendChanges.reduce(0, +) / Double(trendChanges.count)
        
        // Determine trend direction and confidence
        let trend: AlgorithmicPerformanceTrend
        let confidence: Double
        
        switch avgTrendChange {
        case ..<(-0.01):
            trend = .improving
            confidence = min(1.0, abs(avgTrendChange) * 50)
        case -0.01...0.01:
            trend = .stable
            confidence = 1.0 - abs(avgTrendChange) * 50
        default:
            trend = .declining
            confidence = min(1.0, avgTrendChange * 50)
        }
        
        // Generate predictions using linear regression
        let predictions = generatePredictions(from: times, count: 3)
        
        return ProgressionAnalysis(
            trend: trend,
            confidence: confidence,
            predictions: predictions
        )
    }
    
    /// Find performance patterns using cycle detection
    func detectPerformancePatterns(_ data: [Double]) -> [PerformancePattern] {
        // Use chunked() to identify recurring patterns
        let chunkSize = 7 // Weekly patterns
        let chunks = data.chunks(ofCount: chunkSize)
        
        var patterns: [PerformancePattern] = []
        
        // Analyze each chunk for patterns
        for (index, chunk) in chunks.enumerated() {
            let chunkArray = Array(chunk)
            guard chunkArray.count == chunkSize else { continue }
            
            // Find peak and valley days
            let peakDay = chunkArray.enumerated().max { $0.element < $1.element }?.offset ?? 0
            let valleyDay = chunkArray.enumerated().min { $0.element < $1.element }?.offset ?? 0
            
            let pattern = PerformancePattern(
                weekIndex: index,
                peakDay: peakDay,
                valleyDay: valleyDay,
                averagePerformance: chunkArray.reduce(0, +) / Double(chunkArray.count),
                consistency: calculateConsistency(chunkArray)
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    // MARK: - Comparative Analysis
    
    /// Compare user performance against benchmarks using percentile algorithms
    func compareAgainstBenchmarks(userTimes: [Double], benchmarkData: [Double]) -> BenchmarkComparison {
        let userAverage = userTimes.reduce(0, +) / Double(userTimes.count)
        let sortedBenchmarks = benchmarkData.sorted()
        
        // Find percentile using partitioning
        let percentile = findPercentile(userAverage, in: sortedBenchmarks)
        
        // Find similar performers using clustering
        let similarPerformers = findSimilarPerformers(userAverage, in: sortedBenchmarks, tolerance: 0.1)
        
        return BenchmarkComparison(
            userAverage: userAverage,
            percentile: percentile,
            similarPerformersCount: similarPerformers.count,
            improvementPotential: calculateImprovementPotential(userAverage, benchmarks: sortedBenchmarks)
        )
    }
    
    /// Identify training gaps using set operations
    func identifyTrainingGaps(completedSessions: [TrainingSession], recommendedSessions: [TrainingSession]) -> [TrainingGap] {
        let completedTypes = Set(completedSessions.map { $0.type })
        let recommendedTypes = Set(recommendedSessions.map { $0.type })
        
        // Use set difference to find missing session types
        let missingTypes = recommendedTypes.subtracting(completedTypes)
        
        // Use frequency analysis to identify underrepresented areas
        let sessionFrequency = Dictionary(grouping: completedSessions) { $0.type }
            .mapValues { $0.count }
        
        let underrepresentedTypes = recommendedTypes.filter { type in
            let frequency = sessionFrequency[type] ?? 0
            let recommendedFrequency = recommendedSessions.filter { $0.type == type }.count
            return frequency < recommendedFrequency / 2
        }
        
        var gaps: [TrainingGap] = []
        
        // Add missing types
        for type in missingTypes {
            gaps.append(TrainingGap(
                type: type,
                severity: .critical,
                recommendedSessions: recommendedSessions.filter { $0.type == type }.prefix(2).map { $0 }
            ))
        }
        
        // Add underrepresented types
        for type in underrepresentedTypes {
            gaps.append(TrainingGap(
                type: type,
                severity: .moderate,
                recommendedSessions: recommendedSessions.filter { $0.type == type }.prefix(1).map { $0 }
            ))
        }
        
        return gaps
    }
    
    // MARK: - Optimization Algorithms
    
    /// Optimize training schedule using constraint satisfaction
    func optimizeTrainingSchedule(
        availableDays: [Int], // 0-6 (Sunday-Saturday)
        sessionTypes: [String],
        constraints: ScheduleConstraints
    ) -> OptimizedSchedule {
        
        // Generate all possible combinations
        let sessionCombinations = sessionTypes.combinations(ofCount: min(sessionTypes.count, availableDays.count))
        
        var bestSchedule: OptimizedSchedule?
        var bestScore: Double = 0
        
        for combination in sessionCombinations {
            let sessions = Array(combination)
            
            // Try different day assignments using permutations
            let dayPermutations = availableDays.prefix(sessions.count).permutations()
            
            for dayAssignment in dayPermutations {
                let schedule = createSchedule(sessions: sessions, days: Array(dayAssignment))
                let score = evaluateSchedule(schedule, constraints: constraints)
                
                if score > bestScore {
                    bestScore = score
                    bestSchedule = OptimizedSchedule(
                        sessions: schedule,
                        score: score,
                        restDays: availableDays.filter { !dayAssignment.contains($0) }
                    )
                }
            }
        }
        
        return bestSchedule ?? OptimizedSchedule(sessions: [], score: 0, restDays: availableDays)
    }
    
    // MARK: - Helper Methods
    
    private func generatePredictions(from data: [Double], count: Int) -> [Double] {
        guard data.count >= 2 else { return [] }
        
        // Simple linear regression for predictions
        let n = Double(data.count)
        let sumX = (0..<data.count).reduce(0, +)
        let sumY = data.reduce(0, +)
        let sumXY = data.enumerated().reduce(0) { $0 + Double($1.offset) * $1.element }
        let sumXX = (0..<data.count).reduce(0) { $0 + $1 * $1 }
        
        let slope = (n * sumXY - Double(sumX) * sumY) / (n * Double(sumXX) - Double(sumX * sumX))
        let intercept = (sumY - slope * Double(sumX)) / n
        
        return (data.count..<(data.count + count)).map { index in
            slope * Double(index) + intercept
        }
    }
    
    private func calculateConsistency(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let standardDeviation = sqrt(variance)
        return max(0, 1.0 - (standardDeviation / mean))
    }
    
    private func findPercentile(_ value: Double, in sortedData: [Double]) -> Double {
        let index = sortedData.firstIndex { $0 >= value } ?? sortedData.count
        return Double(index) / Double(sortedData.count) * 100
    }
    
    private func findSimilarPerformers(_ value: Double, in data: [Double], tolerance: Double) -> [Double] {
        return data.filter { abs($0 - value) <= tolerance }
    }
    
    private func calculateImprovementPotential(_ userAverage: Double, benchmarks: [Double]) -> Double {
        let top25Percentile = benchmarks[Int(Double(benchmarks.count) * 0.75)]
        return max(0, (userAverage - top25Percentile) / userAverage)
    }
    
    private func createSchedule(sessions: [String], days: [Int]) -> [(session: String, day: Int)] {
        return zip(sessions, days).map { ($0, $1) }
    }
    
    private func evaluateSchedule(_ schedule: [(session: String, day: Int)], constraints: ScheduleConstraints) -> Double {
        var score: Double = 100
        
        // Penalize consecutive high-intensity days
        let sortedByDay = schedule.sorted { $0.day < $1.day }
        for pair in sortedByDay.adjacentPairs() {
            if isHighIntensity(pair.0.session) && isHighIntensity(pair.1.session) && pair.1.day - pair.0.day == 1 {
                score -= 20
            }
        }
        
        // Reward proper rest distribution
        let restDays = (0...6).filter { day in !schedule.contains { $0.day == day } }
        if restDays.count >= 2 {
            score += 10
        }
        
        return max(0, score)
    }
    
    private func isHighIntensity(_ sessionType: String) -> Bool {
        return ["Sprint", "Speed Endurance", "Max Velocity"].contains(sessionType)
    }
}

// MARK: - Supporting Types

struct ProgressionAnalysis {
    let trend: AlgorithmicPerformanceTrend
    let confidence: Double
    let predictions: [Double]
}

struct PerformancePattern {
    let weekIndex: Int
    let peakDay: Int
    let valleyDay: Int
    let averagePerformance: Double
    let consistency: Double
}

struct BenchmarkComparison {
    let userAverage: Double
    let percentile: Double
    let similarPerformersCount: Int
    let improvementPotential: Double
}

struct TrainingGap {
    let type: String
    let severity: GapSeverity
    let recommendedSessions: [TrainingSession]
}

enum GapSeverity {
    case critical
    case moderate
    case minor
}

struct ScheduleConstraints {
    let maxConsecutiveDays: Int
    let minRestDays: Int
    let preferredIntensityDistribution: [String: Int]
}

struct OptimizedSchedule {
    let sessions: [(session: String, day: Int)]
    let score: Double
    let restDays: [Int]
}
