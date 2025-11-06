import Foundation
import Algorithms
import Combine

/// Advanced workout optimization using Swift Algorithms framework
/// Provides intelligent session sequencing, rest period optimization, and performance analysis
class AlgorithmicWorkoutOptimizer: ObservableObject {
    static let shared = AlgorithmicWorkoutOptimizer()
    
    // MARK: - Session Sequencing with Algorithms
    
    /// Optimize workout session order using advanced algorithms
    func optimizeSessionSequence(_ sessions: [TrainingSession]) -> [TrainingSession] {
        // Use chunked() to group sessions by intensity
        let groupedByIntensity = sessions
            .sorted { $0.intensity < $1.intensity }
            .chunked(by: { abs($0.intensity - $1.intensity) <= 0.2 })
        
        // Interleave high and low intensity sessions for optimal recovery
        let optimizedSequence = groupedByIntensity
            .enumerated()
            .sorted { $0.offset % 2 == 0 ? $0.element.first!.intensity < $1.element.first!.intensity : $0.element.first!.intensity > $1.element.first!.intensity }
            .flatMap { $0.element }
        
        return Array(optimizedSequence)
    }
    
    /// Generate optimal rest periods between sprint sets
    func calculateOptimalRestPeriods(sprintTimes: [Double], targetIntensity: Double) -> [TimeInterval] {
        // Use windows() to analyze performance trends
        let performanceWindows = sprintTimes.windows(ofCount: 2)
        
        return performanceWindows.map { window in
            let times = Array(window)
            let performanceDrop = (times[1] - times[0]) / times[0]
            
            // Adaptive rest based on performance decline
            let baseRest: TimeInterval = 90 // 90 seconds base
            let adaptiveMultiplier = 1.0 + (performanceDrop * 2.0) // Increase rest if performance drops
            
            return baseRest * max(0.5, min(3.0, adaptiveMultiplier))
        }
    }
    
    // MARK: - Performance Analysis with Algorithms
    
    /// Analyze sprint performance trends using sliding windows
    func analyzePerformanceTrends(times: [Double], windowSize: Int = 5) -> AlgorithmicPerformanceTrend {
        guard times.count >= windowSize else { return .inconsistent }
        
        // Use windows() for sliding window analysis
        let windows = times.windows(ofCount: windowSize)
        let trends = windows.map { window -> Double in
            let windowArray = Array(window)
            let firstHalf = windowArray.prefix(windowSize/2)
            let secondHalf = windowArray.suffix(windowSize/2)
            
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
            
            return (secondAvg - firstAvg) / firstAvg // Positive = getting slower, Negative = getting faster
        }
        
        let overallTrend = trends.reduce(0, +) / Double(trends.count)
        
        switch overallTrend {
        case ..<(-0.02): return .improving
        case -0.02...0.02: return .stable
        default: return .declining
        }
    }
    
    /// Find optimal training load using partitioning algorithms
    func findOptimalTrainingLoad(sessions: [TrainingSession], maxWeeklyLoad: Double) -> [TrainingSession] {
        // Use partition algorithms to balance weekly training load
        let sortedSessions = sessions.sorted { $0.trainingLoad < $1.trainingLoad }
        
        var selectedSessions: [TrainingSession] = []
        var currentLoad: Double = 0
        
        // Greedy algorithm with partitioning for optimal load distribution
        for session in sortedSessions {
            if currentLoad + session.trainingLoad <= maxWeeklyLoad {
                selectedSessions.append(session)
                currentLoad += session.trainingLoad
            }
        }
        
        return selectedSessions
    }
    
    // MARK: - Advanced Sprint Analysis
    
    /// Detect sprint phases using algorithm-based pattern recognition
    func detectSprintPhases(velocityData: [Double]) -> [AlgorithmicSprintPhase] {
        // Use chunked(by:) to identify acceleration, max velocity, and deceleration phases
        let phases = velocityData
            .enumerated()
            .chunked { current, next in
                let velocityChange = next.element - current.element
                return abs(velocityChange) < 0.5 // Group similar velocity changes
            }
        
        return phases.enumerated().compactMap { index, chunk in
            let velocities = chunk.map { $0.element }
            let avgVelocity = velocities.reduce(0, +) / Double(velocities.count)
            let startTime = Double(chunk.first?.offset ?? 0) * 0.1 // Assuming 10Hz sampling
            let duration = Double(chunk.count) * 0.1
            
            let phaseType: SprintPhaseType
            switch index {
            case 0: phaseType = .acceleration
            case phases.count - 1: phaseType = .deceleration
            default: phaseType = avgVelocity > 8.0 ? .maxVelocity : .acceleration
            }
            
            return AlgorithmicSprintPhase(
                type: phaseType,
                startTime: startTime,
                duration: duration,
                avgVelocity: avgVelocity,
                maxVelocity: velocities.max() ?? 0
            )
        }
    }
    
    /// Generate personalized workout recommendations using combinatorial algorithms
    func generatePersonalizedRecommendations(
        userProfile: UserProfile,
        recentSessions: [TrainingSession],
        availableExercises: [Exercise]
    ) -> [WorkoutRecommendation] {
        
        // Use combinations() to find optimal exercise pairings
        let exerciseCombinations = availableExercises.combinations(ofCount: 3)
        
        return exerciseCombinations.compactMap { exercises in
            let exerciseArray = Array(exercises)
            let totalDuration = exerciseArray.reduce(0) { $0 + $1.estimatedDuration }
            let totalIntensity = exerciseArray.reduce(0) { $0 + $1.intensity } / Double(exerciseArray.count)
            
            // Filter based on user constraints
            guard totalDuration <= userProfile.maxWorkoutDuration,
                  totalIntensity >= userProfile.minIntensity,
                  totalIntensity <= userProfile.maxIntensity else {
                return nil
            }
            
            let compatibility = calculateExerciseCompatibility(exerciseArray)
            
            return WorkoutRecommendation(
                exercises: exerciseArray,
                estimatedDuration: totalDuration,
                intensity: totalIntensity,
                compatibilityScore: compatibility,
                personalizedScore: calculatePersonalizationScore(exerciseArray, userProfile: userProfile)
            )
        }
        .sorted { $0.personalizedScore > $1.personalizedScore }
        .prefix(5)
        .map { $0 }
    }
    
    // MARK: - Helper Methods
    
    private func calculateExerciseCompatibility(_ exercises: [Exercise]) -> Double {
        // Algorithm to calculate how well exercises work together
        let allMuscleGroups = exercises.flatMap { $0.targetMuscleGroups }
        let uniqueGroups = Set(allMuscleGroups)
        let muscleGroupOverlap = Double(allMuscleGroups.count - uniqueGroups.count)
        
        return min(1.0, muscleGroupOverlap / Double(exercises.count))
    }
    
    private func calculatePersonalizationScore(_ exercises: [Exercise], userProfile: UserProfile) -> Double {
        // Personalization algorithm based on user preferences and history
        let preferenceScore = exercises.reduce(0.0) { score, exercise in
            score + (userProfile.preferredExercises.contains(exercise.id) ? 1.0 : 0.0)
        }
        
        let levelMatch = exercises.reduce(0.0) { score, exercise in
            let levelDiff = abs(exercise.difficultyLevel - userProfile.fitnessLevel)
            return score + max(0.0, 1.0 - (Double(levelDiff) / 5.0))
        }
        
        return (preferenceScore + levelMatch) / Double(exercises.count)
    }
}

// MARK: - Supporting Types

enum AlgorithmicPerformanceTrend {
    case improving
    case declining
    case stable
    case inconsistent
}

enum SprintPhaseType {
    case acceleration
    case maxVelocity
    case deceleration
}

struct AlgorithmicSprintPhase {
    let type: SprintPhaseType
    let startTime: TimeInterval
    let duration: TimeInterval
    let avgVelocity: Double
    let maxVelocity: Double
}

struct Exercise {
    let id: String
    let name: String
    let estimatedDuration: TimeInterval
    let intensity: Double
    let difficultyLevel: Int
    let targetMuscleGroups: [String]
}

struct WorkoutRecommendation {
    let exercises: [Exercise]
    let estimatedDuration: TimeInterval
    let intensity: Double
    let compatibilityScore: Double
    let personalizedScore: Double
}

// MARK: - Extensions for TrainingSession

extension TrainingSession {
    var intensity: Double {
        // Calculate intensity based on session type and parameters
        switch self.type {
        case "Sprint": return 0.9
        case "Speed Endurance": return 0.8
        case "Acceleration": return 0.85
        case "Max Velocity": return 0.9
        case "Recovery": return 0.3
        default: return 0.6
        }
    }
    
    var trainingLoad: Double {
        // Calculate training load (intensity × duration × volume)
        let baseDuration: Double = 45 // minutes
        let volumeMultiplier = Double(self.sprints.count)
        return intensity * baseDuration * volumeMultiplier * 0.1
    }
}

extension UserProfile {
    var maxWorkoutDuration: TimeInterval { 60 * 60 } // 60 minutes
    var minIntensity: Double { level == "Beginner" ? 0.3 : level == "Intermediate" ? 0.5 : 0.6 }
    var maxIntensity: Double { level == "Beginner" ? 0.7 : level == "Intermediate" ? 0.85 : 1.0 }
    var fitnessLevel: Int { level == "Beginner" ? 1 : level == "Intermediate" ? 3 : 5 }
    var preferredExercises: [String] { [] } // Could be populated from user preferences
}
