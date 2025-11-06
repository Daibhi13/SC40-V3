import Foundation
import CoreLocation
import Combine
import os.log

/// GPS-based form feedback engine for real-time sprint analysis
/// Provides acceleration, pace, and form coaching during sprints
@MainActor
class GPSFormFeedbackEngine: NSObject, ObservableObject {
    static let shared = GPSFormFeedbackEngine()
    
    // MARK: - Published Properties
    @Published var isTracking = false
    @Published var currentSpeed: Double = 0.0 // m/s
    @Published var currentPace: Double = 0.0 // min/mile
    @Published var acceleration: Double = 0.0 // m/s²
    @Published var sprintMetrics: SprintMetrics?
    @Published var formFeedback: [FormFeedback] = []
    
    // MARK: - Core Location
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "GPSFormFeedback")
    
    // MARK: - Tracking Data
    private var locationHistory: [CLLocation] = []
    private var sprintStartTime: Date?
    private var sprintStartLocation: CLLocation?
    private var targetDistance: Double = 40.0 // yards
    
    // MARK: - Data Structures
    
    struct SprintMetrics {
        let distance: Double // meters
        let duration: TimeInterval
        let averageSpeed: Double // m/s
        let maxSpeed: Double // m/s
        let accelerationPhase: AccelerationPhase
        let topSpeedPhase: TopSpeedPhase
        let formScore: Double // 0-100
        
        struct AccelerationPhase {
            let duration: TimeInterval
            let peakAcceleration: Double
            let averageAcceleration: Double
            let efficiency: Double // 0-1
        }
        
        struct TopSpeedPhase {
            let duration: TimeInterval
            let maxSpeed: Double
            let speedMaintenance: Double // 0-1
            let consistency: Double // 0-1
        }
    }
    
    struct FormFeedback {
        let id = UUID()
        let category: FeedbackCategory
        let message: String
        let recommendation: String
        let severity: Severity
        let timestamp: Date
        let location: CLLocation?
        
        enum FeedbackCategory {
            case acceleration, topSpeed, pacing, efficiency, technique
        }
        
        enum Severity {
            case info, warning, critical
        }
    }
    
    private override init() {
        super.init()
        setupLocationTracking()
    }
    
    // MARK: - Setup
    
    private func setupLocationTracking() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0.1
        
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            logger.error("Location permission denied")
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location permission granted")
        @unknown default:
            break
        }
    }
    
    // MARK: - Sprint Tracking
    
    func startSprintTracking(targetDistance: Double = 40.0) {
        guard !isTracking else { return }
        
        self.targetDistance = targetDistance * 0.9144 // Convert yards to meters
        
        isTracking = true
        sprintStartTime = Date()
        locationHistory.removeAll()
        formFeedback.removeAll()
        
        locationManager.startUpdatingLocation()
        
        logger.info("Started GPS sprint tracking for \(targetDistance) yards")
    }
    
    func stopSprintTracking() -> SprintMetrics? {
        guard isTracking else { return nil }
        
        isTracking = false
        locationManager.stopUpdatingLocation()
        
        let metrics = calculateSprintMetrics()
        
        logger.info("Stopped GPS sprint tracking")
        return metrics
    }
    
    // MARK: - Real-Time Analysis
    
    private func analyzeRealTimePerformance(_ location: CLLocation) {
        guard let startTime = sprintStartTime,
              let startLocation = sprintStartLocation else { return }
        
        let elapsed = location.timestamp.timeIntervalSince(startTime)
        let distance = location.distance(from: startLocation)
        
        // Calculate current metrics
        updateCurrentMetrics(location, elapsed, distance)
        
        // Generate form feedback
        generateFormFeedback(location, elapsed, distance)
        
        // Check if sprint is complete
        if distance >= targetDistance {
            completeSprintAutomatically()
        }
    }
    
    private func updateCurrentMetrics(_ location: CLLocation, _ elapsed: TimeInterval, _ distance: Double) {
        currentSpeed = location.speed >= 0 ? location.speed : 0
        
        if elapsed > 0 {
            let avgSpeed = distance / elapsed
            currentPace = avgSpeed > 0 ? (1609.34 / avgSpeed) / 60 : 0 // min/mile
        }
        
        // Calculate acceleration from recent locations
        if locationHistory.count >= 2 {
            let recent = Array(locationHistory.suffix(3))
            acceleration = calculateAcceleration(from: recent)
        }
    }
    
    private func generateFormFeedback(_ location: CLLocation, _ elapsed: TimeInterval, _ distance: Double) {
        var newFeedback: [FormFeedback] = []
        
        // Acceleration phase feedback (0-3 seconds)
        if elapsed <= 3.0 {
            if acceleration < 2.0 && elapsed > 1.0 {
                newFeedback.append(FormFeedback(
                    category: .acceleration,
                    message: "Acceleration could be stronger",
                    recommendation: "Drive harder with your first few steps",
                    severity: .warning,
                    timestamp: Date(),
                    location: location
                ))
            }
        }
        
        // Top speed phase feedback (3-6 seconds)
        else if elapsed > 3.0 && elapsed <= 6.0 {
            if currentSpeed < 8.0 { // Below ~18 mph
                newFeedback.append(FormFeedback(
                    category: .topSpeed,
                    message: "Top speed below target",
                    recommendation: "Relax and let your speed flow naturally",
                    severity: .info,
                    timestamp: Date(),
                    location: location
                ))
            }
        }
        
        // Pacing feedback
        if distance > targetDistance * 0.5 {
            let expectedTime = estimateOptimalTime(for: targetDistance)
            let currentProjection = (elapsed / distance) * targetDistance
            
            if currentProjection > expectedTime * 1.1 {
                newFeedback.append(FormFeedback(
                    category: .pacing,
                    message: "Pace is slower than target",
                    recommendation: "Increase intensity while maintaining form",
                    severity: .warning,
                    timestamp: Date(),
                    location: location
                ))
            }
        }
        
        // Add new feedback (limit to prevent spam)
        if !newFeedback.isEmpty && formFeedback.count < 10 {
            formFeedback.append(contentsOf: newFeedback)
        }
    }
    
    private func completeSprintAutomatically() {
        let metrics = stopSprintTracking()
        
        // Broadcast completion event
        NotificationCenter.default.post(
            name: NSNotification.Name("GPSSprintCompleted"),
            object: metrics
        )
    }
    
    // MARK: - Calculations
    
    private func calculateAcceleration(from locations: [CLLocation]) -> Double {
        guard locations.count >= 2 else { return 0 }
        
        let recent = locations.suffix(2)
        let loc1 = recent.first!
        let loc2 = recent.last!
        
        let deltaTime = loc2.timestamp.timeIntervalSince(loc1.timestamp)
        guard deltaTime > 0 else { return 0 }
        
        let speed1 = max(0, loc1.speed)
        let speed2 = max(0, loc2.speed)
        
        return (speed2 - speed1) / deltaTime
    }
    
    private func calculateSprintMetrics() -> SprintMetrics? {
        guard let startTime = sprintStartTime,
              let startLocation = sprintStartLocation,
              !locationHistory.isEmpty else { return nil }
        
        let endLocation = locationHistory.last!
        let totalDistance = endLocation.distance(from: startLocation)
        let totalDuration = endLocation.timestamp.timeIntervalSince(startTime)
        
        let speeds = locationHistory.compactMap { $0.speed >= 0 ? $0.speed : nil }
        let averageSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        let maxSpeed = speeds.max() ?? 0
        
        // Analyze acceleration phase (first 3 seconds)
        let accelPhase = analyzeAccelerationPhase()
        
        // Analyze top speed phase (3-6 seconds)
        let topSpeedPhase = analyzeTopSpeedPhase()
        
        // Calculate overall form score
        let formScore = calculateOverallFormScore(accelPhase, topSpeedPhase)
        
        return SprintMetrics(
            distance: totalDistance,
            duration: totalDuration,
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            accelerationPhase: accelPhase,
            topSpeedPhase: topSpeedPhase,
            formScore: formScore
        )
    }
    
    private func analyzeAccelerationPhase() -> SprintMetrics.AccelerationPhase {
        guard let startTime = sprintStartTime else {
            return SprintMetrics.AccelerationPhase(duration: 0, peakAcceleration: 0, averageAcceleration: 0, efficiency: 0)
        }
        
        let accelLocations = locationHistory.filter { 
            $0.timestamp.timeIntervalSince(startTime) <= 3.0 
        }
        
        let accelerations = calculateAccelerationsFromLocations(accelLocations)
        let peakAccel = accelerations.max() ?? 0
        let avgAccel = accelerations.isEmpty ? 0 : accelerations.reduce(0, +) / Double(accelerations.count)
        let efficiency = calculateAccelerationEfficiency(accelerations)
        
        return SprintMetrics.AccelerationPhase(
            duration: min(3.0, accelLocations.last?.timestamp.timeIntervalSince(startTime) ?? 0),
            peakAcceleration: peakAccel,
            averageAcceleration: avgAccel,
            efficiency: efficiency
        )
    }
    
    private func analyzeTopSpeedPhase() -> SprintMetrics.TopSpeedPhase {
        guard let startTime = sprintStartTime else {
            return SprintMetrics.TopSpeedPhase(duration: 0, maxSpeed: 0, speedMaintenance: 0, consistency: 0)
        }
        
        let topSpeedLocations = locationHistory.filter { 
            let elapsed = $0.timestamp.timeIntervalSince(startTime)
            return elapsed > 3.0 && elapsed <= 6.0
        }
        
        let speeds = topSpeedLocations.compactMap { $0.speed >= 0 ? $0.speed : nil }
        let maxSpeed = speeds.max() ?? 0
        let speedMaintenance = calculateSpeedMaintenance(speeds)
        let consistency = calculateSpeedConsistency(speeds)
        
        return SprintMetrics.TopSpeedPhase(
            duration: topSpeedLocations.isEmpty ? 0 : 3.0,
            maxSpeed: maxSpeed,
            speedMaintenance: speedMaintenance,
            consistency: consistency
        )
    }
    
    private func calculateAccelerationsFromLocations(_ locations: [CLLocation]) -> [Double] {
        guard locations.count >= 2 else { return [] }
        
        var accelerations: [Double] = []
        
        for i in 1..<locations.count {
            let loc1 = locations[i-1]
            let loc2 = locations[i]
            
            let deltaTime = loc2.timestamp.timeIntervalSince(loc1.timestamp)
            guard deltaTime > 0 else { continue }
            
            let speed1 = max(0, loc1.speed)
            let speed2 = max(0, loc2.speed)
            
            let accel = (speed2 - speed1) / deltaTime
            accelerations.append(accel)
        }
        
        return accelerations
    }
    
    private func calculateAccelerationEfficiency(_ accelerations: [Double]) -> Double {
        guard !accelerations.isEmpty else { return 0 }
        
        // Efficiency based on consistency of acceleration
        let mean = accelerations.reduce(0, +) / Double(accelerations.count)
        let variance = accelerations.map { pow($0 - mean, 2) }.reduce(0, +) / Double(accelerations.count)
        let cv = variance > 0 ? sqrt(variance) / mean : 0
        
        return max(0, 1.0 - min(1.0, cv))
    }
    
    private func calculateSpeedMaintenance(_ speeds: [Double]) -> Double {
        guard speeds.count >= 2 else { return 0 }
        
        let maxSpeed = speeds.max() ?? 0
        let avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
        
        return maxSpeed > 0 ? avgSpeed / maxSpeed : 0
    }
    
    private func calculateSpeedConsistency(_ speeds: [Double]) -> Double {
        guard speeds.count >= 2 else { return 0 }
        
        let mean = speeds.reduce(0, +) / Double(speeds.count)
        let variance = speeds.map { pow($0 - mean, 2) }.reduce(0, +) / Double(speeds.count)
        let cv = variance > 0 ? sqrt(variance) / mean : 0
        
        return max(0, 1.0 - min(1.0, cv))
    }
    
    private func calculateOverallFormScore(_ accelPhase: SprintMetrics.AccelerationPhase, 
                                         _ topSpeedPhase: SprintMetrics.TopSpeedPhase) -> Double {
        let accelScore = accelPhase.efficiency * 40 // 40% weight
        let topSpeedScore = (topSpeedPhase.speedMaintenance + topSpeedPhase.consistency) * 30 // 60% weight
        
        return min(100, accelScore + topSpeedScore)
    }
    
    private func estimateOptimalTime(for distance: Double) -> Double {
        // Rough estimate for optimal sprint time based on distance
        // This would be refined with more sophisticated modeling
        return distance / 9.0 // Assumes ~9 m/s average speed
    }
}

// MARK: - CLLocationManagerDelegate

extension GPSFormFeedbackEngine: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        
        for location in locations {
            // Filter out inaccurate readings
            guard location.horizontalAccuracy <= 10.0 else { continue }
            
            locationHistory.append(location)
            
            // Set start location if not set
            if sprintStartLocation == nil {
                sprintStartLocation = location
            }
            
            // Perform real-time analysis
            analyzeRealTimePerformance(location)
        }
        
        // Keep location history manageable
        if locationHistory.count > 100 {
            locationHistory.removeFirst(50)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("GPS tracking failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.info("Location permission granted")
        case .denied, .restricted:
            logger.error("Location permission denied")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
