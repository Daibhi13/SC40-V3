import Foundation
import CoreMotion
import CoreLocation
import Combine
import os.log

/// Advanced biomechanics analysis engine for real-time sprint form feedback
/// Provides sophisticated movement analysis, form scoring, and coaching recommendations
@MainActor
class BiomechanicsAnalysisEngine: NSObject, ObservableObject {
    static let shared = BiomechanicsAnalysisEngine()
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var currentFormScore: Double = 0.0 // 0-100 scale
    @Published var realtimeInsights: [BiomechanicsInsight] = []
    @Published var sprintPhaseAnalysis: SprintPhaseAnalysis?
    @Published var movementEfficiency: MovementEfficiency?
    @Published var injuryRiskAssessment: InjuryRiskAssessment?
    
    // MARK: - Core Motion and Location
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "BiomechanicsAnalysis")
    
    // MARK: - Analysis Data
    private var accelerometerData: [CMAccelerometerData] = []
    private var gyroscopeData: [CMGyroData] = []
    private var locationData: [CLLocation] = []
    private var analysisStartTime: Date?
    private var currentSprintPhase: SprintPhaseAnalysis.SprintPhase = .preparation
    
    // MARK: - ML and Analysis Models
    private let formAnalysisModel = FormAnalysisModel()
    private let injuryPreventionModel = InjuryPreventionModel()
    private let efficiencyCalculator = MovementEfficiencyCalculator()
    
    // MARK: - Data Structures
    
    struct BiomechanicsInsight {
        let id = UUID()
        let category: InsightCategory
        let severity: Severity
        let message: String
        let recommendation: String
        let confidence: Double
        let timestamp: Date
        
        enum InsightCategory {
            case posture, cadence, groundContact, armAction, breathing, efficiency
        }
        
        enum Severity {
            case info, warning, critical
            
            var color: String {
                switch self {
                case .info: return "blue"
                case .warning: return "orange"
                case .critical: return "red"
                }
            }
        }
    }
    
    struct SprintPhaseAnalysis {
        let phase: SprintPhase
        let duration: TimeInterval
        let peakAcceleration: Double
        let averageAcceleration: Double
        let cadence: Double // steps per minute
        let groundContactTime: Double // milliseconds
        let flightTime: Double // milliseconds
        let verticalOscillation: Double // cm
        let formScore: Double // 0-100
        let phaseEfficiency: Double // 0-1
        
        enum SprintPhase {
            case preparation, reaction, acceleration, transition, maxVelocity, deceleration
            
            var description: String {
                switch self {
                case .preparation: return "Starting Position"
                case .reaction: return "Reaction Time"
                case .acceleration: return "Acceleration Phase"
                case .transition: return "Transition Phase"
                case .maxVelocity: return "Max Velocity Phase"
                case .deceleration: return "Deceleration Phase"
                }
            }
            
            var optimalDuration: ClosedRange<Double> {
                switch self {
                case .preparation: return 0.0...2.0
                case .reaction: return 0.1...0.3
                case .acceleration: return 1.5...3.0
                case .transition: return 0.5...1.0
                case .maxVelocity: return 2.0...4.0
                case .deceleration: return 1.0...2.0
                }
            }
        }
    }
    
    struct MovementEfficiency {
        let overallScore: Double // 0-100
        let energyWaste: Double // percentage
        let mechanicalAdvantage: Double // 0-1
        let rhythmConsistency: Double // 0-1
        let powerTransfer: Double // 0-1
        let recommendations: [String]
        
        var grade: String {
            switch overallScore {
            case 90...100: return "Elite"
            case 80..<90: return "Excellent"
            case 70..<80: return "Good"
            case 60..<70: return "Fair"
            default: return "Needs Improvement"
            }
        }
    }
    
    struct InjuryRiskAssessment {
        let overallRisk: RiskLevel
        let specificRisks: [SpecificRisk]
        let preventionRecommendations: [String]
        let confidenceLevel: Double
        
        enum RiskLevel {
            case low, moderate, high, critical
            
            var description: String {
                switch self {
                case .low: return "Low Risk"
                case .moderate: return "Moderate Risk"
                case .high: return "High Risk"
                case .critical: return "Critical Risk"
                }
            }
            
            var color: String {
                switch self {
                case .low: return "green"
                case .moderate: return "yellow"
                case .high: return "orange"
                case .critical: return "red"
                }
            }
        }
        
        struct SpecificRisk {
            let bodyPart: String
            let riskType: String
            let probability: Double
            let severity: String
            let prevention: [String]
        }
    }
    
    private override init() {
        super.init()
        setupMotionTracking()
        setupLocationTracking()
    }
    
    // MARK: - Setup Methods
    
    private func setupMotionTracking() {
        guard motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable else {
            logger.error("Motion sensors not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.01 // 100Hz
        motionManager.gyroUpdateInterval = 0.01 // 100Hz
        
        logger.info("Motion tracking configured for biomechanics analysis")
    }
    
    private func setupLocationTracking() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0.1 // 10cm precision
        
        logger.info("Location tracking configured for GPS-based form analysis")
    }
    
    // MARK: - Analysis Control
    
    func startBiomechanicsAnalysis() {
        guard !isAnalyzing else { return }
        
        logger.info("Starting real-time biomechanics analysis")
        
        isAnalyzing = true
        analysisStartTime = Date()
        currentSprintPhase = .preparation
        
        // Clear previous data
        accelerometerData.removeAll()
        gyroscopeData.removeAll()
        locationData.removeAll()
        realtimeInsights.removeAll()
        
        // Start motion tracking
        startMotionCollection()
        
        // Start location tracking
        locationManager.startUpdatingLocation()
        
        // Begin real-time analysis
        startRealtimeAnalysis()
    }
    
    func stopBiomechanicsAnalysis() -> BiomechanicsReport {
        guard isAnalyzing else { 
            return BiomechanicsReport.empty 
        }
        
        logger.info("Stopping biomechanics analysis and generating report")
        
        isAnalyzing = false
        
        // Stop data collection
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        locationManager.stopUpdatingLocation()
        
        // Generate comprehensive report
        let report = generateBiomechanicsReport()
        
        return report
    }
    
    private func startMotionCollection() {
        // Start accelerometer updates
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            self.accelerometerData.append(data)
            
            // Keep only last 10 seconds of data for real-time analysis
            let cutoffTime = Date().timeIntervalSince1970 - 10.0
            self.accelerometerData.removeAll { $0.timestamp < cutoffTime }
        }
        
        // Start gyroscope updates
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            self.gyroscopeData.append(data)
            
            // Keep only last 10 seconds of data
            let cutoffTime = Date().timeIntervalSince1970 - 10.0
            self.gyroscopeData.removeAll { $0.timestamp < cutoffTime }
        }
    }
    
    private func startRealtimeAnalysis() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, self.isAnalyzing else {
                timer.invalidate()
                return
            }
            
            self.performRealtimeAnalysis()
        }
    }
    
    // MARK: - Real-Time Analysis
    
    private func performRealtimeAnalysis() {
        guard !accelerometerData.isEmpty && !gyroscopeData.isEmpty else { return }
        
        // Analyze current sprint phase
        analyzeSprintPhase()
        
        // Calculate form score
        calculateFormScore()
        
        // Assess movement efficiency
        assessMovementEfficiency()
        
        // Check for injury risks
        assessInjuryRisk()
        
        // Generate real-time insights
        generateRealtimeInsights()
    }
    
    private func analyzeSprintPhase() {
        let recentAccelData = Array(accelerometerData.suffix(50)) // Last 0.5 seconds
        guard !recentAccelData.isEmpty else { return }
        
        let avgAcceleration = recentAccelData.map { sqrt($0.acceleration.x * $0.acceleration.x + 
                                                         $0.acceleration.y * $0.acceleration.y + 
                                                         $0.acceleration.z * $0.acceleration.z) }
                                            .reduce(0, +) / Double(recentAccelData.count)
        
        let peakAcceleration = recentAccelData.map { sqrt($0.acceleration.x * $0.acceleration.x + 
                                                         $0.acceleration.y * $0.acceleration.y + 
                                                         $0.acceleration.z * $0.acceleration.z) }.max() ?? 0
        
        // Determine sprint phase based on acceleration patterns
        let newPhase = determineSprintPhase(avgAccel: avgAcceleration, peakAccel: peakAcceleration)
        
        if newPhase != currentSprintPhase {
            currentSprintPhase = newPhase
            logger.info("Sprint phase changed to: \(newPhase.description)")
        }
        
        // Create phase analysis
        sprintPhaseAnalysis = SprintPhaseAnalysis(
            phase: currentSprintPhase,
            duration: Date().timeIntervalSince(analysisStartTime ?? Date()),
            peakAcceleration: peakAcceleration,
            averageAcceleration: avgAcceleration,
            cadence: calculateCadence(),
            groundContactTime: calculateGroundContactTime(),
            flightTime: calculateFlightTime(),
            verticalOscillation: calculateVerticalOscillation(),
            formScore: currentFormScore,
            phaseEfficiency: calculatePhaseEfficiency()
        )
    }
    
    private func determineSprintPhase(avgAccel: Double, peakAccel: Double) -> SprintPhaseAnalysis.SprintPhase {
        guard let startTime = analysisStartTime else { return .preparation }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Phase determination logic based on time and acceleration patterns
        switch elapsed {
        case 0..<1.0:
            return avgAccel > 1.5 ? .reaction : .preparation
        case 1.0..<4.0:
            return .acceleration
        case 4.0..<5.0:
            return .transition
        case 5.0..<8.0:
            return .maxVelocity
        default:
            return .deceleration
        }
    }
    
    private func calculateFormScore() {
        let formMetrics = FormMetrics(
            accelerometerData: Array(accelerometerData.suffix(100)),
            gyroscopeData: Array(gyroscopeData.suffix(100)),
            locationData: Array(locationData.suffix(20))
        )
        
        currentFormScore = formAnalysisModel.calculateFormScore(metrics: formMetrics)
    }
    
    private func assessMovementEfficiency() {
        let efficiency = efficiencyCalculator.calculate(
            accelerometerData: accelerometerData,
            gyroscopeData: gyroscopeData,
            sprintPhase: currentSprintPhase
        )
        
        movementEfficiency = efficiency
    }
    
    private func assessInjuryRisk() {
        let assessment = injuryPreventionModel.assessRisk(
            movementData: accelerometerData,
            rotationData: gyroscopeData,
            currentPhase: currentSprintPhase
        )
        
        injuryRiskAssessment = assessment
    }
    
    private func generateRealtimeInsights() {
        var newInsights: [BiomechanicsInsight] = []
        
        // Form-based insights
        if currentFormScore < 60 {
            newInsights.append(BiomechanicsInsight(
                category: .posture,
                severity: .warning,
                message: "Form efficiency below optimal",
                recommendation: "Focus on maintaining upright posture and relaxed shoulders",
                confidence: 0.85,
                timestamp: Date()
            ))
        }
        
        // Phase-specific insights
        if let phaseAnalysis = sprintPhaseAnalysis {
            let phaseInsights = generatePhaseSpecificInsights(phaseAnalysis)
            newInsights.append(contentsOf: phaseInsights)
        }
        
        // Injury risk insights
        if let riskAssessment = injuryRiskAssessment, riskAssessment.overallRisk != .low {
            newInsights.append(BiomechanicsInsight(
                category: .efficiency,
                severity: .critical,
                message: "Elevated injury risk detected",
                recommendation: riskAssessment.preventionRecommendations.first ?? "Reduce intensity and focus on form",
                confidence: riskAssessment.confidenceLevel,
                timestamp: Date()
            ))
        }
        
        // Update insights (keep only recent ones)
        realtimeInsights.append(contentsOf: newInsights)
        realtimeInsights = Array(realtimeInsights.suffix(10))
    }
    
    private func generatePhaseSpecificInsights(_ analysis: SprintPhaseAnalysis) -> [BiomechanicsInsight] {
        var insights: [BiomechanicsInsight] = []
        
        switch analysis.phase {
        case .acceleration:
            if analysis.cadence < 160 {
                insights.append(BiomechanicsInsight(
                    category: .cadence,
                    severity: .info,
                    message: "Cadence below optimal for acceleration phase",
                    recommendation: "Increase step frequency while maintaining power",
                    confidence: 0.8,
                    timestamp: Date()
                ))
            }
            
        case .maxVelocity:
            if analysis.groundContactTime > 120 {
                insights.append(BiomechanicsInsight(
                    category: .groundContact,
                    severity: .warning,
                    message: "Ground contact time elevated",
                    recommendation: "Focus on quick, light foot strikes",
                    confidence: 0.9,
                    timestamp: Date()
                ))
            }
            
        default:
            break
        }
        
        return insights
    }
    
    // MARK: - Calculation Methods
    
    private func calculateCadence() -> Double {
        // Analyze accelerometer data to detect step frequency
        guard accelerometerData.count > 50 else { return 0 }
        
        let recentData = Array(accelerometerData.suffix(100))
        let stepDetector = StepDetector()
        let steps = stepDetector.detectSteps(from: recentData)
        
        let timeWindow = 1.0 // 1 second
        let stepsPerSecond = Double(steps.count) / timeWindow
        let stepsPerMinute = stepsPerSecond * 60
        
        return stepsPerMinute
    }
    
    private func calculateGroundContactTime() -> Double {
        // Analyze vertical acceleration patterns to estimate ground contact time
        guard accelerometerData.count > 20 else { return 0 }
        
        let recentData = Array(accelerometerData.suffix(50))
        let contactAnalyzer = GroundContactAnalyzer()
        
        return contactAnalyzer.calculateContactTime(from: recentData)
    }
    
    private func calculateFlightTime() -> Double {
        // Calculate time between ground contacts
        guard accelerometerData.count > 20 else { return 0 }
        
        let recentData = Array(accelerometerData.suffix(50))
        let flightAnalyzer = FlightTimeAnalyzer()
        
        return flightAnalyzer.calculateFlightTime(from: recentData)
    }
    
    private func calculateVerticalOscillation() -> Double {
        // Analyze vertical movement patterns
        guard accelerometerData.count > 20 else { return 0 }
        
        let recentData = Array(accelerometerData.suffix(50))
        let verticalData = recentData.map { $0.acceleration.z }
        
        let maxZ = verticalData.max() ?? 0
        let minZ = verticalData.min() ?? 0
        
        return abs(maxZ - minZ) * 100 // Convert to cm
    }
    
    private func calculatePhaseEfficiency() -> Double {
        guard let phaseAnalysis = sprintPhaseAnalysis else { return 0 }
        
        let optimalRange = phaseAnalysis.phase.optimalDuration
        let actualDuration = phaseAnalysis.duration
        
        if optimalRange.contains(actualDuration) {
            return 1.0
        } else {
            let deviation = min(abs(actualDuration - optimalRange.lowerBound), 
                              abs(actualDuration - optimalRange.upperBound))
            return max(0, 1.0 - (deviation / optimalRange.upperBound))
        }
    }
    
    // MARK: - Report Generation
    
    private func generateBiomechanicsReport() -> BiomechanicsReport {
        return BiomechanicsReport(
            sessionDuration: Date().timeIntervalSince(analysisStartTime ?? Date()),
            overallFormScore: currentFormScore,
            phaseAnalyses: sprintPhaseAnalysis.map { [$0] } ?? [],
            movementEfficiency: movementEfficiency,
            injuryRiskAssessment: injuryRiskAssessment,
            insights: realtimeInsights,
            recommendations: generateFinalRecommendations()
        )
    }
    
    private func generateFinalRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if currentFormScore < 70 {
            recommendations.append("Focus on form drills to improve running mechanics")
        }
        
        if let efficiency = movementEfficiency, efficiency.overallScore < 75 {
            recommendations.append(contentsOf: efficiency.recommendations)
        }
        
        if let riskAssessment = injuryRiskAssessment, riskAssessment.overallRisk != .low {
            recommendations.append(contentsOf: riskAssessment.preventionRecommendations)
        }
        
        return recommendations
    }
}

// MARK: - Supporting Models and Classes

struct FormMetrics {
    let accelerometerData: [CMAccelerometerData]
    let gyroscopeData: [CMGyroData]
    let locationData: [CLLocation]
}

class FormAnalysisModel {
    func calculateFormScore(metrics: FormMetrics) -> Double {
        // Sophisticated form analysis algorithm
        var score = 100.0
        
        // Analyze acceleration patterns for smoothness
        if !metrics.accelerometerData.isEmpty {
            let smoothnessScore = analyzeSmoothness(metrics.accelerometerData)
            score *= smoothnessScore
        }
        
        // Analyze rotational stability
        if !metrics.gyroscopeData.isEmpty {
            let stabilityScore = analyzeStability(metrics.gyroscopeData)
            score *= stabilityScore
        }
        
        return max(0, min(100, score))
    }
    
    private func analyzeSmoothness(_ data: [CMAccelerometerData]) -> Double {
        // Calculate coefficient of variation for smoothness
        let magnitudes = data.map { sqrt($0.acceleration.x * $0.acceleration.x + 
                                        $0.acceleration.y * $0.acceleration.y + 
                                        $0.acceleration.z * $0.acceleration.z) }
        
        guard magnitudes.count > 1 else { return 1.0 }
        
        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let variance = magnitudes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(magnitudes.count)
        let standardDeviation = sqrt(variance)
        
        let coefficientOfVariation = standardDeviation / mean
        
        // Lower CV indicates smoother movement
        return max(0.5, 1.0 - coefficientOfVariation)
    }
    
    private func analyzeStability(_ data: [CMGyroData]) -> Double {
        // Analyze rotational stability
        let rotationMagnitudes = data.map { sqrt($0.rotationRate.x * $0.rotationRate.x + 
                                                $0.rotationRate.y * $0.rotationRate.y + 
                                                $0.rotationRate.z * $0.rotationRate.z) }
        
        let avgRotation = rotationMagnitudes.reduce(0, +) / Double(rotationMagnitudes.count)
        
        // Lower rotation indicates better stability
        return max(0.6, 1.0 - min(1.0, avgRotation / 2.0))
    }
}

class InjuryPreventionModel {
    func assessRisk(movementData: [CMAccelerometerData], 
                   rotationData: [CMGyroData], 
                   currentPhase: BiomechanicsAnalysisEngine.SprintPhaseAnalysis.SprintPhase) -> BiomechanicsAnalysisEngine.InjuryRiskAssessment {
        
        var specificRisks: [BiomechanicsAnalysisEngine.InjuryRiskAssessment.SpecificRisk] = []
        var overallRisk: BiomechanicsAnalysisEngine.InjuryRiskAssessment.RiskLevel = .low
        
        // Analyze impact forces
        let impactRisk = analyzeImpactForces(movementData)
        if impactRisk > 0.7 {
            specificRisks.append(BiomechanicsAnalysisEngine.InjuryRiskAssessment.SpecificRisk(
                bodyPart: "Lower Leg",
                riskType: "Impact Injury",
                probability: impactRisk,
                severity: "Moderate",
                prevention: ["Reduce stride length", "Focus on midfoot landing"]
            ))
            overallRisk = .moderate
        }
        
        // Analyze asymmetry
        let asymmetryRisk = analyzeMovementAsymmetry(movementData)
        if asymmetryRisk > 0.6 {
            specificRisks.append(BiomechanicsAnalysisEngine.InjuryRiskAssessment.SpecificRisk(
                bodyPart: "Hip/Knee",
                riskType: "Asymmetry",
                probability: asymmetryRisk,
                severity: "High",
                prevention: ["Single-leg strengthening", "Form correction drills"]
            ))
            overallRisk = .high
        }
        
        return BiomechanicsAnalysisEngine.InjuryRiskAssessment(
            overallRisk: overallRisk,
            specificRisks: specificRisks,
            preventionRecommendations: specificRisks.flatMap { $0.prevention },
            confidenceLevel: 0.8
        )
    }
    
    private func analyzeImpactForces(_ data: [CMAccelerometerData]) -> Double {
        let verticalForces = data.map { abs($0.acceleration.z) }
        let maxForce = verticalForces.max() ?? 0
        
        // High vertical forces indicate higher impact risk
        return min(1.0, maxForce / 3.0) // Normalize to 0-1 scale
    }
    
    private func analyzeMovementAsymmetry(_ data: [CMAccelerometerData]) -> Double {
        // Simplified asymmetry analysis
        let leftRightForces = data.map { $0.acceleration.x }
        let avgLateral = leftRightForces.reduce(0, +) / Double(leftRightForces.count)
        
        return min(1.0, abs(avgLateral) * 2.0)
    }
}

class MovementEfficiencyCalculator {
    func calculate(accelerometerData: [CMAccelerometerData], 
                  gyroscopeData: [CMGyroData], 
                  sprintPhase: BiomechanicsAnalysisEngine.SprintPhaseAnalysis.SprintPhase) -> BiomechanicsAnalysisEngine.MovementEfficiency {
        
        let energyEfficiency = calculateEnergyEfficiency(accelerometerData)
        let mechanicalAdvantage = calculateMechanicalAdvantage(accelerometerData, gyroscopeData)
        let rhythmConsistency = calculateRhythmConsistency(accelerometerData)
        let powerTransfer = calculatePowerTransfer(accelerometerData)
        
        let overallScore = (energyEfficiency + mechanicalAdvantage + rhythmConsistency + powerTransfer) * 25
        
        var recommendations: [String] = []
        if energyEfficiency < 0.7 { recommendations.append("Focus on reducing unnecessary movements") }
        if mechanicalAdvantage < 0.7 { recommendations.append("Improve body alignment and posture") }
        if rhythmConsistency < 0.7 { recommendations.append("Work on consistent step rhythm") }
        if powerTransfer < 0.7 { recommendations.append("Enhance ground contact efficiency") }
        
        return BiomechanicsAnalysisEngine.MovementEfficiency(
            overallScore: overallScore,
            energyWaste: (1.0 - energyEfficiency) * 100,
            mechanicalAdvantage: mechanicalAdvantage,
            rhythmConsistency: rhythmConsistency,
            powerTransfer: powerTransfer,
            recommendations: recommendations
        )
    }
    
    private func calculateEnergyEfficiency(_ data: [CMAccelerometerData]) -> Double {
        // Calculate energy efficiency based on movement smoothness
        guard data.count > 10 else { return 0.5 }
        
        let magnitudes = data.map { sqrt($0.acceleration.x * $0.acceleration.x + 
                                        $0.acceleration.y * $0.acceleration.y + 
                                        $0.acceleration.z * $0.acceleration.z) }
        
        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let variance = magnitudes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(magnitudes.count)
        
        // Lower variance indicates higher efficiency
        return max(0.3, 1.0 - min(1.0, variance / mean))
    }
    
    private func calculateMechanicalAdvantage(_ accelData: [CMAccelerometerData], _ gyroData: [CMGyroData]) -> Double {
        // Simplified mechanical advantage calculation
        return 0.75 // Placeholder - would implement sophisticated biomechanical analysis
    }
    
    private func calculateRhythmConsistency(_ data: [CMAccelerometerData]) -> Double {
        // Analyze step timing consistency
        return 0.8 // Placeholder - would implement step detection and timing analysis
    }
    
    private func calculatePowerTransfer(_ data: [CMAccelerometerData]) -> Double {
        // Analyze power transfer efficiency
        return 0.7 // Placeholder - would implement force vector analysis
    }
}

// MARK: - Supporting Analysis Classes

class StepDetector {
    func detectSteps(from data: [CMAccelerometerData]) -> [Date] {
        // Implement step detection algorithm
        return [] // Placeholder
    }
}

class GroundContactAnalyzer {
    func calculateContactTime(from data: [CMAccelerometerData]) -> Double {
        // Analyze ground contact patterns
        return 100.0 // milliseconds - placeholder
    }
}

class FlightTimeAnalyzer {
    func calculateFlightTime(from data: [CMAccelerometerData]) -> Double {
        // Analyze flight time between contacts
        return 80.0 // milliseconds - placeholder
    }
}

struct BiomechanicsReport {
    let sessionDuration: TimeInterval
    let overallFormScore: Double
    let phaseAnalyses: [BiomechanicsAnalysisEngine.SprintPhaseAnalysis]
    let movementEfficiency: BiomechanicsAnalysisEngine.MovementEfficiency?
    let injuryRiskAssessment: BiomechanicsAnalysisEngine.InjuryRiskAssessment?
    let insights: [BiomechanicsAnalysisEngine.BiomechanicsInsight]
    let recommendations: [String]
    
    static let empty = BiomechanicsReport(
        sessionDuration: 0,
        overallFormScore: 0,
        phaseAnalyses: [],
        movementEfficiency: nil,
        injuryRiskAssessment: nil,
        insights: [],
        recommendations: []
    )
}

// MARK: - CLLocationManagerDelegate

extension BiomechanicsAnalysisEngine: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationData.append(contentsOf: locations)
        
        // Keep only recent location data
        let cutoffTime = Date().timeIntervalSince1970 - 30.0
        locationData.removeAll { $0.timestamp.timeIntervalSince1970 < cutoffTime }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location tracking failed: \(error.localizedDescription)")
    }
}
