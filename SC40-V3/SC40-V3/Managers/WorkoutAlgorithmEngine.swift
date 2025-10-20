import Foundation
import Combine

// MARK: - Workout Algorithm Engine
// Calculates target distances, predicted times, recovery periods, and adaptive difficulty

class WorkoutAlgorithmEngine: ObservableObject {
    static let shared = WorkoutAlgorithmEngine()
    
    // MARK: - Published Properties
    @Published var currentDifficulty: Int = 0 // -3 to +3 adjustment
    @Published var adaptiveLevel: String = "Intermediate"
    
    // MARK: - User Performance Data
    private var userProfile: UserPerformanceProfile
    private var recentPerformance: [PerformanceData] = []
    private let maxPerformanceHistory = 20
    
    // MARK: - Algorithm Constants
    private struct Constants {
        static let baseWarmupTime: TimeInterval = 300 // 5 minutes
        static let baseCooldownTime: TimeInterval = 300 // 5 minutes
        static let baseRecoveryMultiplier: Double = 3.0 // 3x sprint time
        static let difficultyAdjustmentThreshold: Double = 0.05 // 5%
        static let maxDifficultyAdjustment: Int = 3
        static let performanceWindowDays: Int = 7
    }
    
    private init() {
        userProfile = UserPerformanceProfile()
        loadUserProfile()
    }
    
    // MARK: - Stage Configuration Generation
    func generateStageConfigs(for session: TrainingSession) -> [WorkoutStageConfig] {
        var configs: [WorkoutStageConfig] = []
        
        // 1. Warm-up
        configs.append(generateWarmupConfig())
        
        // 2. Drills (if applicable)
        if shouldIncludeDrills(for: session) {
            configs.append(contentsOf: generateDrillConfigs(for: session))
        }
        
        // 3. Strides (if applicable)
        if shouldIncludeStrides(for: session) {
            configs.append(contentsOf: generateStrideConfigs(for: session))
        }
        
        // 4. Main sprints
        configs.append(contentsOf: generateSprintConfigs(for: session))
        
        // 5. Cooldown
        configs.append(generateCooldownConfig())
        
        return configs
    }
    
    private func generateWarmupConfig() -> WorkoutStageConfig {
        let adjustedTime = Constants.baseWarmupTime * getDifficultyMultiplier(for: .warmUp)
        
        return WorkoutStageConfig(
            stage: .warmUp,
            duration: adjustedTime,
            targetDistance: 0,
            predictedTime: adjustedTime,
            intensity: "Easy",
            instructions: "Light jogging and dynamic stretching to prepare your body."
        )
    }
    
    private func generateDrillConfigs(for session: TrainingSession) -> [WorkoutStageConfig] {
        let drillDistance: Double = 40 // yards
        let predictedTime = calculatePredictedTime(distance: drillDistance, intensity: 0.6)
        
        return [WorkoutStageConfig(
            stage: .drills,
            duration: 0, // Distance-based
            targetDistance: drillDistance,
            predictedTime: predictedTime,
            intensity: "60%",
            instructions: "A-skips for 40 yards. Focus on form and technique."
        )]
    }
    
    private func generateStrideConfigs(for session: TrainingSession) -> [WorkoutStageConfig] {
        let strideDistance: Double = 60 // yards
        let predictedTime = calculatePredictedTime(distance: strideDistance, intensity: 0.7)
        
        return [WorkoutStageConfig(
            stage: .strides,
            duration: 0, // Distance-based
            targetDistance: strideDistance,
            predictedTime: predictedTime,
            intensity: "70%",
            instructions: "Smooth acceleration to 70% effort. Focus on relaxed speed."
        )]
    }
    
    private func generateSprintConfigs(for session: TrainingSession) -> [WorkoutStageConfig] {
        var configs: [WorkoutStageConfig] = []
        
        for (index, sprint) in session.sprints.enumerated() {
            let distance = Double(sprint.distanceYards)
            let intensity = getIntensityValue(sprint.intensity)
            let predictedTime = calculatePredictedTime(distance: distance, intensity: intensity)
            
            // Sprint stage
            let sprintConfig = WorkoutStageConfig(
                stage: .sprints,
                duration: 0, // Distance-based
                targetDistance: distance,
                predictedTime: predictedTime,
                intensity: sprint.intensity,
                instructions: "Sprint \(Int(distance)) yards at \(sprint.intensity) effort."
            )
            configs.append(sprintConfig)
            
            // Recovery stage (except after last sprint)
            if index < session.sprints.count - 1 {
                let recoveryTime = calculateRecoveryTime(
                    sprintDistance: distance,
                    intensity: intensity,
                    sprintNumber: index + 1
                )
                
                let recoveryConfig = WorkoutStageConfig(
                    stage: .recovery,
                    duration: recoveryTime,
                    targetDistance: 0,
                    predictedTime: recoveryTime,
                    intensity: "Rest",
                    instructions: "Active recovery. Walk and breathe easy."
                )
                configs.append(recoveryConfig)
            }
        }
        
        return configs
    }
    
    private func generateCooldownConfig() -> WorkoutStageConfig {
        let adjustedTime = Constants.baseCooldownTime * getDifficultyMultiplier(for: .cooldown)
        
        return WorkoutStageConfig(
            stage: .cooldown,
            duration: adjustedTime,
            targetDistance: 0,
            predictedTime: adjustedTime,
            intensity: "Easy",
            instructions: "Easy walking and static stretching to help recovery."
        )
    }
    
    // MARK: - Time Predictions
    func calculatePredictedTime(distance: Double, intensity: Double) -> TimeInterval {
        // Base prediction on user's 40-yard personal best
        let base40Time = userProfile.personalBest40Yard
        
        // Scale based on distance
        let distanceRatio = distance / 40.0
        let baseTime = base40Time * distanceRatio
        
        // Adjust for intensity (higher intensity = faster time)
        let intensityFactor = 1.0 / intensity
        let adjustedTime = baseTime * intensityFactor
        
        // Apply difficulty adjustment
        let difficultyFactor = getDifficultyMultiplier(for: .sprints)
        let finalTime = adjustedTime * difficultyFactor
        
        return finalTime
    }
    
    func calculateRecoveryTime(for config: WorkoutStageConfig, lastSprintTime: TimeInterval) -> TimeInterval {
        return calculateRecoveryTime(
            sprintDistance: config.targetDistance,
            intensity: getIntensityValue(config.intensity),
            sprintNumber: 1,
            actualSprintTime: lastSprintTime
        )
    }
    
    private func calculateRecoveryTime(
        sprintDistance: Double,
        intensity: Double,
        sprintNumber: Int,
        actualSprintTime: TimeInterval? = nil
    ) -> TimeInterval {
        // Base recovery is 3x the sprint time
        let baseSprintTime = actualSprintTime ?? calculatePredictedTime(distance: sprintDistance, intensity: intensity)
        var recoveryTime = baseSprintTime * Constants.baseRecoveryMultiplier
        
        // Adjust for sprint number (later sprints need more recovery)
        let sprintFactor = 1.0 + (Double(sprintNumber - 1) * 0.1)
        recoveryTime *= sprintFactor
        
        // Adjust for intensity (higher intensity needs more recovery)
        let intensityFactor = 0.5 + (intensity * 0.5)
        recoveryTime *= intensityFactor
        
        // Apply user fitness level
        let fitnessMultiplier = getFitnessRecoveryMultiplier()
        recoveryTime *= fitnessMultiplier
        
        // Minimum 30 seconds, maximum 5 minutes
        return max(30, min(300, recoveryTime))
    }
    
    // MARK: - Performance Updates
    func updatePerformance(
        stage: WorkoutStage,
        actualTime: TimeInterval,
        targetTime: TimeInterval,
        distance: Double
    ) {
        let performance = PerformanceData(
            stage: stage,
            distance: distance,
            actualTime: actualTime,
            targetTime: targetTime,
            timestamp: Date()
        )
        
        recentPerformance.append(performance)
        
        // Keep only recent performance data
        if recentPerformance.count > maxPerformanceHistory {
            recentPerformance.removeFirst()
        }
        
        // Update difficulty based on performance
        updateDifficulty(performance: performance)
        
        // Update user profile
        updateUserProfile(performance: performance)
        
        print("📊 Performance updated: \(stage.rawValue) - Actual: \(String(format: "%.2f", actualTime))s, Target: \(String(format: "%.2f", targetTime))s")
    }
    
    private func updateDifficulty(performance: PerformanceData) {
        guard performance.stage == .sprints else { return }
        
        let performanceRatio = performance.actualTime / performance.targetTime
        
        // If significantly faster than predicted, increase difficulty
        if performanceRatio < (1.0 - Constants.difficultyAdjustmentThreshold) {
            currentDifficulty = min(Constants.maxDifficultyAdjustment, currentDifficulty + 1)
            print("📈 Difficulty increased to \(currentDifficulty)")
        }
        // If significantly slower than predicted, decrease difficulty
        else if performanceRatio > (1.0 + Constants.difficultyAdjustmentThreshold) {
            currentDifficulty = max(-Constants.maxDifficultyAdjustment, currentDifficulty - 1)
            print("📉 Difficulty decreased to \(currentDifficulty)")
        }
        
        updateAdaptiveLevel()
    }
    
    private func updateUserProfile(performance: PerformanceData) {
        // Update personal best for 40-yard sprints
        if performance.stage == .sprints && abs(performance.distance - 40.0) < 5.0 {
            if performance.actualTime < userProfile.personalBest40Yard {
                userProfile.personalBest40Yard = performance.actualTime
                print("🏆 New 40-yard personal best: \(String(format: "%.2f", performance.actualTime))s")
            }
        }
        
        // Update average performance
        updateAveragePerformance()
        
        // Save updated profile
        saveUserProfile()
    }
    
    private func updateAveragePerformance() {
        let recentSprints = recentPerformance.filter { $0.stage == .sprints }
        guard !recentSprints.isEmpty else { return }
        
        let totalTime = recentSprints.reduce(0) { $0 + $1.actualTime }
        userProfile.averageSprintTime = totalTime / Double(recentSprints.count)
        
        // Calculate consistency (lower standard deviation = more consistent)
        let mean = userProfile.averageSprintTime
        let variance = recentSprints.reduce(0) { $0 + pow($1.actualTime - mean, 2) } / Double(recentSprints.count)
        userProfile.consistency = 1.0 / (1.0 + sqrt(variance))
    }
    
    // MARK: - Difficulty Adjustments
    private func getDifficultyMultiplier(for stage: WorkoutStage) -> Double {
        let baseFactor = 1.0 + (Double(currentDifficulty) * 0.05) // 5% per difficulty level
        
        switch stage {
        case .warmUp, .cooldown:
            return max(0.8, min(1.2, baseFactor)) // Limited adjustment for warm-up/cooldown
        case .sprints:
            return max(0.85, min(1.15, baseFactor)) // Moderate adjustment for sprints
        case .recovery:
            return max(0.7, min(1.3, 1.0 / baseFactor)) // Inverse for recovery (harder = less recovery)
        default:
            return baseFactor
        }
    }
    
    private func getFitnessRecoveryMultiplier() -> Double {
        // Based on user's consistency and recent performance
        let fitnessLevel = userProfile.consistency
        
        if fitnessLevel > 0.8 {
            return 0.8 // Fit users recover faster
        } else if fitnessLevel > 0.6 {
            return 0.9
        } else if fitnessLevel > 0.4 {
            return 1.0
        } else {
            return 1.2 // Less fit users need more recovery
        }
    }
    
    private func updateAdaptiveLevel() {
        switch currentDifficulty {
        case -3...(-2):
            adaptiveLevel = "Beginner"
        case -1...0:
            adaptiveLevel = "Intermediate"
        case 1...2:
            adaptiveLevel = "Advanced"
        case 3:
            adaptiveLevel = "Elite"
        default:
            adaptiveLevel = "Intermediate"
        }
    }
    
    // MARK: - Session Analysis
    func shouldIncludeDrills(for session: TrainingSession) -> Bool {
        // Include drills for technique-focused sessions or beginners
        return session.type.contains("Speed") || currentDifficulty <= 0
    }
    
    func shouldIncludeStrides(for session: TrainingSession) -> Bool {
        // Include strides for most sessions except pure endurance
        return !session.type.contains("Endurance")
    }
    
    func suggestNextLevel() -> String {
        let recentPerformance = getRecentPerformanceScore()
        
        if recentPerformance > 0.9 {
            return "Excellent progress! Ready for advanced training."
        } else if recentPerformance > 0.8 {
            return "Good improvement! Continue current level."
        } else if recentPerformance > 0.6 {
            return "Steady progress. Focus on consistency."
        } else {
            return "Take time to build base fitness."
        }
    }
    
    private func getRecentPerformanceScore() -> Double {
        let recentSprints = recentPerformance.filter { 
            $0.stage == .sprints && 
            $0.timestamp.timeIntervalSinceNow > -TimeInterval(Constants.performanceWindowDays * 24 * 3600)
        }
        
        guard !recentSprints.isEmpty else { return 0.5 }
        
        let averageRatio = recentSprints.reduce(0) { $0 + ($1.targetTime / $1.actualTime) } / Double(recentSprints.count)
        return min(1.0, averageRatio)
    }
    
    // MARK: - Utility Methods
    private func getIntensityValue(_ intensity: String) -> Double {
        switch intensity.lowercased() {
        case "easy", "recovery":
            return 0.5
        case "moderate", "60%":
            return 0.6
        case "tempo", "70%":
            return 0.7
        case "threshold", "80%":
            return 0.8
        case "hard", "90%":
            return 0.9
        case "max", "100%", "maximum":
            return 1.0
        default:
            return 0.8 // Default to 80%
        }
    }
    
    // MARK: - Data Persistence
    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "WorkoutAlgorithmProfile"),
           let profile = try? JSONDecoder().decode(UserPerformanceProfile.self, from: data) {
            userProfile = profile
            updateAdaptiveLevel()
        }
    }
    
    private func saveUserProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: "WorkoutAlgorithmProfile")
        }
    }
}

// MARK: - Supporting Models
struct UserPerformanceProfile: Codable {
    var personalBest40Yard: TimeInterval = 6.0 // Default 6.0 seconds
    var averageSprintTime: TimeInterval = 6.5
    var consistency: Double = 0.7 // 0.0 to 1.0
    var totalSessions: Int = 0
    var lastSessionDate: Date = Date()
}

struct PerformanceData {
    let stage: WorkoutStage
    let distance: Double
    let actualTime: TimeInterval
    let targetTime: TimeInterval
    let timestamp: Date
}
