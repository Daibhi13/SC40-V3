import Foundation
import Vision
import CoreML
import AVFoundation
import Combine

/// AI-powered biomechanics analysis system for sprint technique optimization
/// Provides real-time feedback and performance insights using computer vision
class BiomechanicsAI: ObservableObject {
    static let shared = BiomechanicsAI()
    
    // MARK: - Published Properties
    @Published var analysisResults: BiomechanicsAnalysis?
    @Published var isAnalyzing = false
    @Published var realTimeFeedback: [TechniqueFeedback] = []
    @Published var performanceScore: Double = 0.0
    
    // MARK: - Core ML Models
    private var poseEstimationModel: VNCoreMLModel?
    private var techniqueAnalysisModel: VNCoreMLModel?
    private var performancePredictionModel: VNCoreMLModel?
    
    // MARK: - Analysis Configuration
    private let analysisQueue = DispatchQueue(label: "biomechanics.analysis", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMLModels()
    }
    
    // MARK: - Model Loading
    
    private func loadMLModels() {
        Task {
            do {
                // Load pose estimation model
                if let poseModelURL = Bundle.main.url(forResource: "SprintPoseEstimation", withExtension: "mlmodelc") {
                    let poseModel = try MLModel(contentsOf: poseModelURL)
                    poseEstimationModel = try VNCoreMLModel(for: poseModel)
                }
                
                // Load technique analysis model
                if let techniqueModelURL = Bundle.main.url(forResource: "SprintTechniqueAnalysis", withExtension: "mlmodelc") {
                    let techniqueModel = try MLModel(contentsOf: techniqueModelURL)
                    techniqueAnalysisModel = try VNCoreMLModel(for: techniqueModel)
                }
                
                // Load performance prediction model
                if let performanceModelURL = Bundle.main.url(forResource: "PerformancePrediction", withExtension: "mlmodelc") {
                    let performanceModel = try MLModel(contentsOf: performanceModelURL)
                    performancePredictionModel = try VNCoreMLModel(for: performanceModel)
                }
                
                print("✅ AI models loaded successfully")
            } catch {
                print("❌ Failed to load AI models: \(error)")
            }
        }
    }
    
    // MARK: - Video Analysis
    
    func analyzeSprintVideo(_ videoURL: URL, completion: @escaping (BiomechanicsAnalysis?) -> Void) {
        isAnalyzing = true
        
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            var keyFrames: [KeyFrame] = []
            let frameTimes = self.generateFrameTimes(for: asset)
            
            for (index, time) in frameTimes.enumerated() {
                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    
                    if let keyFrame = self.analyzeFrame(cgImage, frameIndex: index, timestamp: time) {
                        keyFrames.append(keyFrame)
                    }
                } catch {
                    print("Failed to generate frame at time \(time): \(error)")
                }
            }
            
            let analysis = self.generateBiomechanicsAnalysis(from: keyFrames)
            
            DispatchQueue.main.async {
                self.analysisResults = analysis
                self.isAnalyzing = false
                completion(analysis)
            }
        }
    }
    
    func analyzeRealTimeFrame(_ pixelBuffer: CVPixelBuffer) -> TechniqueFeedback? {
        guard let poseModel = poseEstimationModel else { return nil }
        
        let request = VNCoreMLRequest(model: poseModel) { [weak self] request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
            
            let feedback = self?.processPoseResults(results)
            
            DispatchQueue.main.async {
                if let feedback = feedback {
                    self?.realTimeFeedback.append(feedback)
                    
                    // Keep only recent feedback (last 10 items)
                    if self?.realTimeFeedback.count ?? 0 > 10 {
                        self?.realTimeFeedback.removeFirst()
                    }
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform pose estimation: \(error)")
        }
        
        return realTimeFeedback.last
    }
    
    // MARK: - Frame Analysis
    
    private func analyzeFrame(_ image: CGImage, frameIndex: Int, timestamp: CMTime) -> KeyFrame? {
        guard let poseModel = poseEstimationModel else { return nil }
        
        var keyPoints: [KeyPoint] = []
        
        let request = VNCoreMLRequest(model: poseModel) { request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
            
            keyPoints = self.extractKeyPoints(from: results)
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            return KeyFrame(
                index: frameIndex,
                timestamp: timestamp,
                keyPoints: keyPoints,
                biomechanics: calculateBiomechanics(from: keyPoints)
            )
        } catch {
            print("Failed to analyze frame \(frameIndex): \(error)")
            return nil
        }
    }
    
    // MARK: - Biomechanics Calculations
    
    private func calculateBiomechanics(from keyPoints: [KeyPoint]) -> FrameBiomechanics {
        // Extract key body landmarks
        let head = keyPoints.first { $0.type == .head }
        let shoulders = keyPoints.filter { $0.type == .shoulder }
        let hips = keyPoints.filter { $0.type == .hip }
        let knees = keyPoints.filter { $0.type == .knee }
        let ankles = keyPoints.filter { $0.type == .ankle }
        let feet = keyPoints.filter { $0.type == .foot }
        
        // Calculate biomechanical metrics
        let postureAngle = calculatePostureAngle(head: head, hips: hips)
        let kneeAngle = calculateKneeAngle(knees: knees, hips: hips, ankles: ankles)
        let armSwingAngle = calculateArmSwingAngle(shoulders: shoulders, keyPoints: keyPoints)
        let strideLength = calculateStrideLength(feet: feet)
        let groundContactAngle = calculateGroundContactAngle(ankles: ankles, feet: feet)
        
        return FrameBiomechanics(
            postureAngle: postureAngle,
            kneeAngle: kneeAngle,
            armSwingAngle: armSwingAngle,
            strideLength: strideLength,
            groundContactAngle: groundContactAngle,
            centerOfMass: calculateCenterOfMass(keyPoints: keyPoints)
        )
    }
    
    private func generateBiomechanicsAnalysis(from keyFrames: [KeyFrame]) -> BiomechanicsAnalysis {
        let phaseAnalysis = analyzeSprintPhases(keyFrames)
        let techniqueScores = calculateTechniqueScores(keyFrames)
        let recommendations = generateRecommendations(from: keyFrames, scores: techniqueScores)
        let comparison = compareToEliteAthletes(keyFrames)
        
        return BiomechanicsAnalysis(
            overallScore: techniqueScores.overall,
            phaseBreakdown: phaseAnalysis,
            techniqueScores: techniqueScores,
            recommendations: recommendations,
            eliteComparison: comparison,
            detailedMetrics: calculateDetailedMetrics(keyFrames),
            timestamp: Date()
        )
    }
    
    // MARK: - Sprint Phase Analysis
    
    private func analyzeSprintPhases(_ keyFrames: [KeyFrame]) -> SprintPhaseAnalysis {
        let phases = identifySprintPhases(keyFrames)
        
        return SprintPhaseAnalysis(
            startPhase: analyzeStartPhase(phases.start),
            accelerationPhase: analyzeAccelerationPhase(phases.acceleration),
            maxVelocityPhase: analyzeMaxVelocityPhase(phases.maxVelocity),
            transitionQuality: calculateTransitionQuality(phases)
        )
    }
    
    private func identifySprintPhases(_ keyFrames: [KeyFrame]) -> (start: [KeyFrame], acceleration: [KeyFrame], maxVelocity: [KeyFrame]) {
        // Analyze velocity changes to identify phases
        let velocities = calculateFrameVelocities(keyFrames)
        
        // Start phase: First 10-15 frames (first 10-15 meters)
        let startFrames = Array(keyFrames.prefix(15))
        
        // Acceleration phase: Frames where velocity is increasing
        var accelerationFrames: [KeyFrame] = []
        var maxVelocityFrames: [KeyFrame] = []
        
        for i in 15..<keyFrames.count {
            if i < velocities.count - 1 && velocities[i + 1] > velocities[i] {
                accelerationFrames.append(keyFrames[i])
            } else {
                maxVelocityFrames.append(keyFrames[i])
            }
        }
        
        return (startFrames, accelerationFrames, maxVelocityFrames)
    }
    
    // MARK: - Technique Scoring
    
    private func calculateTechniqueScores(_ keyFrames: [KeyFrame]) -> TechniqueScores {
        let postureScore = evaluatePosture(keyFrames)
        let armMechanicsScore = evaluateArmMechanics(keyFrames)
        let legMechanicsScore = evaluateLegMechanics(keyFrames)
        let rhythmScore = evaluateRhythm(keyFrames)
        let efficiencyScore = evaluateEfficiency(keyFrames)
        
        let overall = (postureScore + armMechanicsScore + legMechanicsScore + rhythmScore + efficiencyScore) / 5.0
        
        return TechniqueScores(
            overall: overall,
            posture: postureScore,
            armMechanics: armMechanicsScore,
            legMechanics: legMechanicsScore,
            rhythm: rhythmScore,
            efficiency: efficiencyScore
        )
    }
    
    // MARK: - Recommendations Generation
    
    private func generateRecommendations(from keyFrames: [KeyFrame], scores: TechniqueScores) -> [TechniqueRecommendation] {
        var recommendations: [TechniqueRecommendation] = []
        
        // Posture recommendations
        if scores.posture < 0.7 {
            recommendations.append(TechniqueRecommendation(
                category: .posture,
                priority: .high,
                title: "Improve Forward Lean",
                description: "Maintain a slight forward lean throughout the sprint. Focus on driving from the hips.",
                drills: ["Wall Lean Drills", "A-Skip with Forward Lean", "Acceleration Runs"],
                videoReference: "posture_improvement_drill"
            ))
        }
        
        // Arm mechanics recommendations
        if scores.armMechanics < 0.7 {
            recommendations.append(TechniqueRecommendation(
                category: .armMechanics,
                priority: .medium,
                title: "Optimize Arm Swing",
                description: "Drive arms straight back and forth, avoiding cross-body movement.",
                drills: ["Arm Swing Drills", "Standing Arm Pumps", "Mirror Work"],
                videoReference: "arm_mechanics_drill"
            ))
        }
        
        // Leg mechanics recommendations
        if scores.legMechanics < 0.7 {
            recommendations.append(TechniqueRecommendation(
                category: .legMechanics,
                priority: .high,
                title: "Improve Knee Drive",
                description: "Focus on driving knees up and forward, maintaining high knee lift.",
                drills: ["High Knees", "Butt Kicks", "A-Skips", "B-Skips"],
                videoReference: "knee_drive_drill"
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Elite Athlete Comparison
    
    private func compareToEliteAthletes(_ keyFrames: [KeyFrame]) -> EliteComparison {
        // Load elite athlete biomechanics database
        let eliteDatabase = EliteAthleteDatabase.shared
        let userMetrics = calculateAverageMetrics(keyFrames)
        
        let comparisons = eliteDatabase.compareMetrics(userMetrics)
        
        return EliteComparison(
            overallSimilarity: comparisons.overall,
            postureComparison: comparisons.posture,
            armMechanicsComparison: comparisons.armMechanics,
            legMechanicsComparison: comparisons.legMechanics,
            closestEliteMatch: comparisons.closestMatch,
            improvementAreas: comparisons.improvementAreas
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateFrameTimes(for asset: AVAsset) -> [CMTime] {
        let duration = asset.duration
        let frameRate: Double = 30 // Analyze at 30 FPS
        let totalFrames = Int(duration.seconds * frameRate)
        
        return (0..<totalFrames).map { frameIndex in
            CMTime(seconds: Double(frameIndex) / frameRate, preferredTimescale: 600)
        }
    }
    
    private func calculateFrameVelocities(_ keyFrames: [KeyFrame]) -> [Double] {
        guard keyFrames.count > 1 else { return [] }
        
        var velocities: [Double] = []
        
        for i in 1..<keyFrames.count {
            let previousFrame = keyFrames[i - 1]
            let currentFrame = keyFrames[i]
            
            let distance = calculateDistance(
                from: previousFrame.biomechanics.centerOfMass,
                to: currentFrame.biomechanics.centerOfMass
            )
            
            let timeInterval = currentFrame.timestamp.seconds - previousFrame.timestamp.seconds
            let velocity = distance / timeInterval
            
            velocities.append(velocity)
        }
        
        return velocities
    }
    
    // MARK: - Geometric Calculations
    
    private func calculatePostureAngle(head: KeyPoint?, hips: [KeyPoint]) -> Double {
        guard let head = head, let hip = hips.first else { return 0 }
        
        let deltaX = head.position.x - hip.position.x
        let deltaY = head.position.y - hip.position.y
        
        return atan2(deltaY, deltaX) * 180 / .pi
    }
    
    private func calculateKneeAngle(knees: [KeyPoint], hips: [KeyPoint], ankles: [KeyPoint]) -> Double {
        // Calculate angle between hip-knee-ankle for both legs
        guard knees.count >= 2, hips.count >= 2, ankles.count >= 2 else { return 0 }
        
        // Use right leg for calculation (index 0 = right, 1 = left)
        let hip = hips[0]
        let knee = knees[0]
        let ankle = ankles[0]
        
        return calculateAngle(point1: hip.position, vertex: knee.position, point2: ankle.position)
    }
    
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point2: CGPoint) -> Double {
        let vector1 = CGPoint(x: point1.x - vertex.x, y: point1.y - vertex.y)
        let vector2 = CGPoint(x: point2.x - vertex.x, y: point2.y - vertex.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        return acos(max(-1, min(1, cosAngle))) * 180 / .pi
    }
    
    private func calculateDistance(from point1: CGPoint, to point2: CGPoint) -> Double {
        let deltaX = point2.x - point1.x
        let deltaY = point2.y - point1.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
}

// MARK: - Supporting Data Models

struct BiomechanicsAnalysis {
    let overallScore: Double
    let phaseBreakdown: SprintPhaseAnalysis
    let techniqueScores: TechniqueScores
    let recommendations: [TechniqueRecommendation]
    let eliteComparison: EliteComparison
    let detailedMetrics: DetailedMetrics
    let timestamp: Date
}

struct KeyFrame {
    let index: Int
    let timestamp: CMTime
    let keyPoints: [KeyPoint]
    let biomechanics: FrameBiomechanics
}

struct KeyPoint {
    let type: KeyPointType
    let position: CGPoint
    let confidence: Float
}

enum KeyPointType {
    case head, shoulder, elbow, wrist, hip, knee, ankle, foot
}

struct FrameBiomechanics {
    let postureAngle: Double
    let kneeAngle: Double
    let armSwingAngle: Double
    let strideLength: Double
    let groundContactAngle: Double
    let centerOfMass: CGPoint
}

struct SprintPhaseAnalysis {
    let startPhase: PhaseMetrics
    let accelerationPhase: PhaseMetrics
    let maxVelocityPhase: PhaseMetrics
    let transitionQuality: Double
}

struct PhaseMetrics {
    let duration: TimeInterval
    let averageVelocity: Double
    let techniqueScore: Double
    let keyCharacteristics: [String]
}

struct TechniqueScores {
    let overall: Double
    let posture: Double
    let armMechanics: Double
    let legMechanics: Double
    let rhythm: Double
    let efficiency: Double
}

struct TechniqueRecommendation {
    let category: TechniqueCategory
    let priority: Priority
    let title: String
    let description: String
    let drills: [String]
    let videoReference: String
    
    enum TechniqueCategory {
        case posture, armMechanics, legMechanics, rhythm, efficiency
    }
    
    enum Priority: Int {
        case low = 1, medium = 2, high = 3
    }
}

struct TechniqueFeedback {
    let message: String
    let type: FeedbackType
    let timestamp: Date
    let confidence: Float
    
    enum FeedbackType {
        case positive, corrective, warning
    }
}

struct EliteComparison {
    let overallSimilarity: Double
    let postureComparison: Double
    let armMechanicsComparison: Double
    let legMechanicsComparison: Double
    let closestEliteMatch: String
    let improvementAreas: [String]
}

struct DetailedMetrics {
    let averageStrideLength: Double
    let strideFrequency: Double
    let groundContactTime: TimeInterval
    let flightTime: TimeInterval
    let velocityProfile: [Double]
    let accelerationProfile: [Double]
}

// MARK: - Elite Database (Placeholder)

class EliteAthleteDatabase {
    static let shared = EliteAthleteDatabase()
    
    func compareMetrics(_ userMetrics: DetailedMetrics) -> (overall: Double, posture: Double, armMechanics: Double, legMechanics: Double, closestMatch: String, improvementAreas: [String]) {
        // Compare user metrics against elite athlete database
        return (0.75, 0.8, 0.7, 0.85, "Usain Bolt", ["Arm swing consistency", "Ground contact time"])
    }
}
