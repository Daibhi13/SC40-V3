import Foundation
import CoreLocation
import Combine

// MARK: - Workout GPS Manager
// Tracks real-time position and distance with automatic sprint detection

class WorkoutGPSManager: NSObject, ObservableObject {
    static let shared = WorkoutGPSManager()
    
    // MARK: - Published Properties
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentLocation: CLLocation?
    @Published var currentDistance: Double = 0.0 // in yards
    @Published var currentSpeed: Double = 0.0 // in mph
    @Published var accuracy: Double = 0.0
    @Published var isMoving: Bool = false
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var startLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var trackingStartTime: Date?
    private var locations: [CLLocation] = []
    
    // MARK: - Tracking Configuration
    private var targetDistance: Double = 0.0 // in yards
    private var onProgressCallback: ((Double, Double) -> Void)?
    private var onCompleteCallback: ((Double, TimeInterval) -> Void)?
    
    // MARK: - Movement Detection
    private let movementThreshold: Double = 1.0 // m/s (about 2.2 mph)
    private let accuracyThreshold: Double = 10.0 // meters
    private let minDistanceForMovement: Double = 2.0 // meters
    
    // MARK: - Distance Conversion
    private let yardsToMeters: Double = 0.9144
    private let metersToYards: Double = 1.0936
    private let mpsToMph: Double = 2.237
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every meter
        
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("❌ Location permission denied")
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted")
        @unknown default:
            break
        }
    }
    
    // MARK: - Distance Tracking
    func startDistanceTracking(
        targetDistance: Double, // in yards
        onProgress: @escaping (Double, Double) -> Void, // (distance, progress)
        onComplete: @escaping (Double, TimeInterval) -> Void // (finalDistance, time)
    ) {
        guard !isTracking else { return }
        
        print("📍 Starting GPS distance tracking for \(targetDistance) yards")
        
        self.targetDistance = targetDistance
        self.onProgressCallback = onProgress
        self.onCompleteCallback = onComplete
        
        // Reset tracking state
        currentDistance = 0.0
        currentSpeed = 0.0
        isMoving = false
        locations.removeAll()
        startLocation = nil
        lastLocation = nil
        trackingStartTime = nil
        
        isTracking = true
        isPaused = false
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        print("🎯 Target: \(targetDistance) yards (\(targetDistance * yardsToMeters) meters)")
    }
    
    func pauseTracking() {
        guard isTracking && !isPaused else { return }
        
        print("⏸️ GPS tracking paused")
        isPaused = true
        locationManager.stopUpdatingLocation()
    }
    
    func resumeTracking() {
        guard isTracking && isPaused else { return }
        
        print("▶️ GPS tracking resumed")
        isPaused = false
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        print("⏹️ GPS tracking stopped")
        
        locationManager.stopUpdatingLocation()
        isTracking = false
        isPaused = false
        isMoving = false
        
        onProgressCallback = nil
        onCompleteCallback = nil
    }
    
    // MARK: - Distance Calculation
    private func updateDistance(with location: CLLocation) {
        guard isTracking && !isPaused else { return }
        
        // Check location accuracy
        guard location.horizontalAccuracy <= accuracyThreshold else {
            print("⚠️ Poor GPS accuracy: \(location.horizontalAccuracy)m")
            return
        }
        
        accuracy = location.horizontalAccuracy
        currentLocation = location
        locations.append(location)
        
        // Detect movement start
        if startLocation == nil {
            detectMovementStart(location)
            return
        }
        
        // Calculate distance from start
        guard let startLoc = startLocation else { return }
        
        let distanceMeters = location.distance(from: startLoc)
        currentDistance = distanceMeters * metersToYards
        
        // Calculate speed
        if let lastLoc = lastLocation {
            let timeDiff = location.timestamp.timeIntervalSince(lastLoc.timestamp)
            if timeDiff > 0 {
                let speedMps = location.distance(from: lastLoc) / timeDiff
                currentSpeed = speedMps * mpsToMph
            }
        }
        
        lastLocation = location
        
        // Update progress
        let progress = min(1.0, currentDistance / targetDistance)
        onProgressCallback?(currentDistance, progress)
        
        print("📏 Distance: \(String(format: "%.1f", currentDistance)) yards, Speed: \(String(format: "%.1f", currentSpeed)) mph")
        
        // Check completion
        if currentDistance >= targetDistance {
            completeTracking()
        }
    }
    
    private func detectMovementStart(_ location: CLLocation) {
        // Wait for significant movement to start timing
        if let lastLoc = lastLocation {
            let distance = location.distance(from: lastLoc)
            let timeDiff = location.timestamp.timeIntervalSince(lastLoc.timestamp)
            
            if distance >= minDistanceForMovement && timeDiff > 0 {
                let speed = distance / timeDiff
                
                if speed >= movementThreshold {
                    // Movement detected - set start location
                    startLocation = location
                    trackingStartTime = location.timestamp
                    isMoving = true
                    
                    print("🏃‍♂️ Movement detected! Starting distance tracking from current position")
                    VoiceHapticsManager.shared.movementDetected()
                }
            }
        }
        
        lastLocation = location
    }
    
    private func completeTracking() {
        guard let startTime = trackingStartTime else { return }
        
        let totalTime = Date().timeIntervalSince(startTime)
        let finalDistance = currentDistance
        
        print("✅ Distance tracking complete: \(String(format: "%.1f", finalDistance)) yards in \(String(format: "%.2f", totalTime))s")
        
        let callback = onCompleteCallback
        stopTracking()
        callback?(finalDistance, totalTime)
    }
    
    // MARK: - Sprint Detection
    func startSprintDetection(
        onSprintStart: @escaping () -> Void,
        onSprintComplete: @escaping (Double, TimeInterval) -> Void
    ) {
        var sprintStarted = false
        var sprintStartTime: Date?
        var sprintStartLocation: CLLocation?
        
        startDistanceTracking(
            targetDistance: 40.0, // Default 40-yard sprint
            onProgress: { distance, progress in
                // Detect sprint start based on speed
                if !sprintStarted && self.currentSpeed > 8.0 { // 8+ mph indicates sprint
                    sprintStarted = true
                    sprintStartTime = Date()
                    sprintStartLocation = self.currentLocation
                    onSprintStart()
                    
                    print("🏃‍♂️💨 Sprint detected! Speed: \(String(format: "%.1f", self.currentSpeed)) mph")
                }
            },
            onComplete: { finalDistance, totalTime in
                if let sprintStart = sprintStartTime {
                    let sprintTime = Date().timeIntervalSince(sprintStart)
                    onSprintComplete(finalDistance, sprintTime)
                } else {
                    onSprintComplete(finalDistance, totalTime)
                }
            }
        )
    }
    
    // MARK: - Utility Methods
    func yardsToMeters(_ yards: Double) -> Double {
        return yards * yardsToMeters
    }
    
    func metersToYards(_ meters: Double) -> Double {
        return meters * metersToYards
    }
    
    func mpsToMph(_ mps: Double) -> Double {
        return mps * mpsToMph
    }
    
    // MARK: - Location Status
    var hasLocationPermission: Bool {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    var locationStatus: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Permission not requested"
        case .denied:
            return "Permission denied"
        case .restricted:
            return "Location restricted"
        case .authorizedWhenInUse:
            return "Authorized when in use"
        case .authorizedAlways:
            return "Always authorized"
        @unknown default:
            return "Unknown status"
        }
    }
    
    var accuracyStatus: String {
        guard let location = currentLocation else { return "No location" }
        
        if location.horizontalAccuracy < 5 {
            return "Excellent"
        } else if location.horizontalAccuracy < 10 {
            return "Good"
        } else if location.horizontalAccuracy < 20 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WorkoutGPSManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        updateDistance(with: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied")
            case .locationUnknown:
                print("Location unknown")
            case .network:
                print("Network error")
            default:
                print("Other location error: \(clError.localizedDescription)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 Location authorization changed: \(locationStatus)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted")
        case .denied, .restricted:
            print("❌ Location permission denied")
        case .notDetermined:
            print("⏳ Location permission pending")
        @unknown default:
            break
        }
    }
}

// MARK: - GPS Tracking State
extension WorkoutGPSManager {
    
    var isReady: Bool {
        hasLocationPermission && !isTracking
    }
    
    var canStart: Bool {
        hasLocationPermission && !isTracking
    }
    
    var canPause: Bool {
        isTracking && !isPaused
    }
    
    var canResume: Bool {
        isTracking && isPaused
    }
    
    var distanceRemaining: Double {
        max(0, targetDistance - currentDistance)
    }
    
    var progressPercentage: Int {
        guard targetDistance > 0 else { return 0 }
        return Int((currentDistance / targetDistance) * 100)
    }
}
