import Foundation
import CoreLocation
import Combine
import WatchKit

/// Enhanced GPS manager for autonomous watch workout tracking
/// Provides real-time pace calculation, distance tracking, and speed milestone detection
class WatchGPSManager: NSObject, ObservableObject {
    static let shared = WatchGPSManager()
    
    // MARK: - Published Properties
    @Published var currentSpeed: Double = 0.0 // mph
    @Published var currentPace: Double = 0.0 // minutes per mile
    @Published var currentDistance: Double = 0.0 // yards
    @Published var totalDistance: Double = 0.0 // yards
    @Published var isTracking = false
    @Published var gpsAccuracy: CLLocationAccuracy = 0
    @Published var gpsStatus: GPSStatus = .unknown
    @Published var speedMilestone: SpeedMilestone?
    
    // Sprint-specific tracking
    @Published var sprintDistance: Double = 0.0 // Current sprint distance
    @Published var sprintSpeed: Double = 0.0 // Current sprint speed
    @Published var maxSprintSpeed: Double = 0.0 // Max speed in current sprint
    @Published var sprintSplits: [SprintSplit] = [] // 10yd, 20yd, 30yd, 40yd splits
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var sprintStartLocation: CLLocation?
    private var sprintStartTime: Date?
    private var locations: [CLLocation] = []
    private var speedReadings: [SpeedReading] = []
    
    // Distance tracking
    private let yardsPerMeter = 1.09361
    private let metersPerMile = 1609.34
    private let secondsPerHour = 3600.0
    
    // Sprint split distances (in yards)
    private let splitDistances: [Double] = [10, 20, 30, 40]
    private var recordedSplits: Set<Double> = []
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every meter
        
        requestLocationPermissions()
    }
    
    private func requestLocationPermissions() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ GPS permissions already granted")
        case .denied, .restricted:
            print("❌ GPS permissions denied")
            gpsStatus = .denied
        @unknown default:
            print("⚠️ Unknown GPS permission status")
        }
    }
    
    // MARK: - Tracking Control
    
    func startTracking() {
        guard !isTracking else {
            print("⚠️ GPS tracking already active")
            return
        }
        
        print("📍 Starting GPS tracking...")
        
        // Reset tracking data
        resetTrackingData()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        isTracking = true
        gpsStatus = .searching
        
        print("📍 GPS tracking started")
    }
    
    func stopTracking() {
        guard isTracking else { return }
        
        print("📍 Stopping GPS tracking...")
        
        locationManager.stopUpdatingLocation()
        isTracking = false
        gpsStatus = .stopped
        
        print("📍 GPS tracking stopped")
    }
    
    func startSprint() {
        print("🏃‍♂️ Starting sprint tracking...")
        
        sprintStartLocation = lastLocation
        sprintStartTime = Date()
        sprintDistance = 0.0
        sprintSpeed = 0.0
        maxSprintSpeed = 0.0
        recordedSplits.removeAll()
        sprintSplits.removeAll()
        
        print("🏃‍♂️ Sprint tracking started")
    }
    
    func endSprint() -> SprintResult? {
        guard let startLocation = sprintStartLocation,
              let startTime = sprintStartTime,
              let endLocation = lastLocation else {
            print("⚠️ Cannot end sprint - missing start data")
            return nil
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        let totalDistance = sprintDistance
        let avgSpeed = totalDistance > 0 ? (totalDistance / totalTime) * 2.045 : 0 // Convert to mph
        
        let result = SprintResult(
            distance: totalDistance,
            time: totalTime,
            averageSpeed: avgSpeed,
            maxSpeed: maxSprintSpeed,
            splits: sprintSplits
        )
        
        print("🏁 Sprint completed: \(String(format: "%.1f", totalDistance))yd in \(String(format: "%.2f", totalTime))s")
        print("🏁 Average speed: \(String(format: "%.1f", avgSpeed)) mph, Max: \(String(format: "%.1f", maxSprintSpeed)) mph")
        
        // Reset sprint tracking
        sprintStartLocation = nil
        sprintStartTime = nil
        
        return result
    }
    
    // MARK: - Data Reset
    
    private func resetTrackingData() {
        currentSpeed = 0.0
        currentPace = 0.0
        currentDistance = 0.0
        totalDistance = 0.0
        sprintDistance = 0.0
        sprintSpeed = 0.0
        maxSprintSpeed = 0.0
        gpsAccuracy = 0
        speedMilestone = nil
        
        lastLocation = nil
        sprintStartLocation = nil
        sprintStartTime = nil
        locations.removeAll()
        speedReadings.removeAll()
        sprintSplits.removeAll()
        recordedSplits.removeAll()
    }
    
    // MARK: - Location Processing
    
    private func processLocation(_ location: CLLocation) {
        // Update GPS accuracy
        gpsAccuracy = location.horizontalAccuracy
        
        // Check GPS quality
        guard location.horizontalAccuracy <= 10.0 else {
            gpsStatus = .poor
            return
        }
        
        gpsStatus = .good
        
        // Calculate distance and speed
        if let previousLocation = lastLocation {
            let distance = location.distance(from: previousLocation)
            let timeInterval = location.timestamp.timeIntervalSince(previousLocation.timestamp)
            
            // Update total distance
            let distanceInYards = distance * yardsPerMeter
            totalDistance += distanceInYards
            currentDistance = totalDistance
            
            // Calculate speed (mph)
            if timeInterval > 0 {
                let speedMPS = distance / timeInterval // meters per second
                let speedMPH = speedMPS * 2.237 // convert to mph
                currentSpeed = speedMPH
                
                // Calculate pace (minutes per mile)
                if speedMPH > 0 {
                    currentPace = 60.0 / speedMPH
                }
                
                // Record speed reading
                let reading = SpeedReading(
                    speed: speedMPH,
                    timestamp: location.timestamp,
                    location: location
                )
                speedReadings.append(reading)
                
                // Check for speed milestones
                checkSpeedMilestones(speedMPH)
                
                // Update sprint tracking if active
                updateSprintTracking(location, distance: distanceInYards, speed: speedMPH)
            }
        }
        
        lastLocation = location
        locations.append(location)
        
        print("📍 GPS: \(String(format: "%.1f", currentSpeed)) mph, \(String(format: "%.1f", totalDistance)) yds, Accuracy: \(String(format: "%.1f", gpsAccuracy))m")
    }
    
    private func updateSprintTracking(_ location: CLLocation, distance: Double, speed: Double) {
        guard let sprintStart = sprintStartLocation,
              let startTime = sprintStartTime else { return }
        
        // Update sprint distance
        sprintDistance += distance
        sprintSpeed = speed
        
        // Track max speed
        if speed > maxSprintSpeed {
            maxSprintSpeed = speed
        }
        
        // Check for split times
        for splitDistance in splitDistances {
            if sprintDistance >= splitDistance && !recordedSplits.contains(splitDistance) {
                let splitTime = Date().timeIntervalSince(startTime)
                let split = SprintSplit(
                    distance: splitDistance,
                    time: splitTime,
                    speed: speed
                )
                sprintSplits.append(split)
                recordedSplits.insert(splitDistance)
                
                print("⚡ Split: \(Int(splitDistance))yd in \(String(format: "%.2f", splitTime))s at \(String(format: "%.1f", speed)) mph")
                
                // Haptic feedback for splits
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
    
    private func checkSpeedMilestones(_ speed: Double) {
        let milestone: SpeedMilestone?
        
        switch speed {
        case 20...:
            milestone = .elite(speed)
        case 18..<20:
            milestone = .fast(speed)
        case 15..<18:
            milestone = .good(speed)
        default:
            milestone = nil
        }
        
        if let newMilestone = milestone, newMilestone != speedMilestone {
            speedMilestone = newMilestone
            
            // Haptic feedback for milestones
            WKInterfaceDevice.current().play(.success)
            
            print("🎯 Speed milestone: \(newMilestone.description)")
        }
    }
    
    // MARK: - Data Access
    
    func getCurrentMetrics() -> GPSMetrics {
        return GPSMetrics(
            speed: currentSpeed,
            pace: currentPace,
            distance: currentDistance,
            totalDistance: totalDistance,
            accuracy: gpsAccuracy,
            status: gpsStatus
        )
    }
    
    func getSprintMetrics() -> SprintMetrics? {
        guard sprintStartLocation != nil else { return nil }
        
        return SprintMetrics(
            distance: sprintDistance,
            speed: sprintSpeed,
            maxSpeed: maxSprintSpeed,
            splits: sprintSplits
        )
    }
    
    func getSpeedHistory() -> [SpeedReading] {
        return speedReadings
    }
    
    func getLocationHistory() -> [CLLocation] {
        return locations
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchGPSManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.processLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ GPS error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.gpsStatus = .error
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ GPS permissions granted")
                self?.gpsStatus = .ready
            case .denied, .restricted:
                print("❌ GPS permissions denied")
                self?.gpsStatus = .denied
            case .notDetermined:
                print("⚠️ GPS permissions not determined")
                self?.gpsStatus = .unknown
            @unknown default:
                print("⚠️ Unknown GPS permission status")
                self?.gpsStatus = .unknown
            }
        }
    }
}

// MARK: - Supporting Data Models

enum GPSStatus {
    case unknown
    case denied
    case ready
    case searching
    case poor
    case good
    case error
    case stopped
    
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .denied: return "Denied"
        case .ready: return "Ready"
        case .searching: return "Searching"
        case .poor: return "Poor Signal"
        case .good: return "Good Signal"
        case .error: return "Error"
        case .stopped: return "Stopped"
        }
    }
}

enum SpeedMilestone: Equatable {
    case good(Double)
    case fast(Double)
    case elite(Double)
    
    var description: String {
        switch self {
        case .good(let speed):
            return "Good Speed: \(String(format: "%.1f", speed)) mph"
        case .fast(let speed):
            return "Fast Speed: \(String(format: "%.1f", speed)) mph"
        case .elite(let speed):
            return "Elite Speed: \(String(format: "%.1f", speed)) mph"
        }
    }
}

struct SpeedReading {
    let speed: Double
    let timestamp: Date
    let location: CLLocation
}

struct SprintSplit {
    let distance: Double
    let time: TimeInterval
    let speed: Double
}

struct SprintResult {
    let distance: Double
    let time: TimeInterval
    let averageSpeed: Double
    let maxSpeed: Double
    let splits: [SprintSplit]
}

struct GPSMetrics {
    let speed: Double
    let pace: Double
    let distance: Double
    let totalDistance: Double
    let accuracy: CLLocationAccuracy
    let status: GPSStatus
}

struct SprintMetrics {
    let distance: Double
    let speed: Double
    let maxSpeed: Double
    let splits: [SprintSplit]
}
