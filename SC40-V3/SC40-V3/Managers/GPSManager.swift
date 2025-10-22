import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - GPS Manager for Sprint Timing
@MainActor
class GPSManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var isTracking: Bool = false
    @Published var currentSpeed: Double = 0.0 // m/s
    @Published var currentPace: String = "0:00" // min/mile
    @Published var accuracy: Double = 0.0 // meters
    @Published var distance: Double = 0.0 // meters
    @Published var elapsedTime: TimeInterval = 0.0
    @Published var gpsStatus: GPSStatus = .unavailable
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var startLocation: CLLocation?
    private var lastLocation: CLLocation?
    private var startTime: Date?
    private var locations: [CLLocation] = []
    private var timer: Timer?
    
    // MARK: - Sprint-Specific Properties
    @Published var sprintStarted: Bool = false
    @Published var sprintDistance: Double = 40.0 // Default 40 yards
    @Published var targetDistanceMeters: Double = 36.58 // 40 yards in meters
    @Published var hasReachedTarget: Bool = false
    @Published var finalTime: Double?
    @Published var maxSpeed: Double = 0.0
    @Published var averageSpeed: Double = 0.0
    
    // MARK: - Callbacks
    var onSprintCompleted: ((SprintResult) -> Void)?
    var onDistanceUpdate: ((Double, TimeInterval) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        checkAuthorizationStatus()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0.5 // Update every 0.5 meters
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    private func checkAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            gpsStatus = .ready
        case .denied, .restricted:
            isAuthorized = false
            gpsStatus = .denied
        case .notDetermined:
            isAuthorized = false
            gpsStatus = .requesting
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            isAuthorized = false
            gpsStatus = .unavailable
        }
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Set the target sprint distance in yards
    func setSprintDistance(yards: Double) {
        sprintDistance = yards
        targetDistanceMeters = yards * 0.9144 // Convert yards to meters
        print("🎯 Sprint distance set to \(yards) yards (\(String(format: "%.2f", targetDistanceMeters))m)")
    }
    
    /// Start GPS tracking for sprint
    func startSprint() {
        guard isAuthorized else {
            print("❌ GPS not authorized")
            return
        }
        
        // Reset sprint data
        resetSprintData()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        isTracking = true
        sprintStarted = true
        startTime = Date()
        
        // Start timer for elapsed time updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if let startTime = self.startTime {
                    self.elapsedTime = Date().timeIntervalSince(startTime)
                }
            }
        }
        
        gpsStatus = .tracking
        print("🏃‍♂️ Sprint started! Target: \(sprintDistance) yards")
    }
    
    /// Stop GPS tracking
    func stopSprint() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        isTracking = false
        sprintStarted = false
        gpsStatus = .ready
        
        // Calculate final results if we have data
        if !locations.isEmpty {
            calculateFinalResults()
        }
        
        print("⏹️ Sprint stopped")
    }
    
    /// Reset sprint data for new sprint
    private func resetSprintData() {
        startLocation = nil
        lastLocation = nil
        locations.removeAll()
        distance = 0.0
        elapsedTime = 0.0
        currentSpeed = 0.0
        maxSpeed = 0.0
        averageSpeed = 0.0
        hasReachedTarget = false
        finalTime = nil
    }
    
    /// Manual sprint completion (fallback if GPS fails)
    func completeSprintManually(time: Double) {
        let result = SprintResult(
            distance: targetDistanceMeters,
            time: time,
            maxSpeed: 0.0,
            averageSpeed: targetDistanceMeters / time,
            accuracy: 999.0, // Indicate manual timing
            isGPSBased: false
        )
        
        finalTime = time
        onSprintCompleted?(result)
        stopSprint()
    }
    
    // MARK: - Private Methods
    
    private func calculateFinalResults() {
        guard let startLoc = startLocation,
              let endLoc = locations.last,
              let startTime = startTime else { return }
        
        let totalDistance = distance
        let totalTime = elapsedTime
        
        // Calculate speeds
        let speeds = locations.compactMap { location in
            location.speed >= 0 ? location.speed : nil
        }
        
        maxSpeed = speeds.max() ?? 0.0
        averageSpeed = totalDistance / totalTime
        
        // Create sprint result
        let result = SprintResult(
            distance: totalDistance,
            time: totalTime,
            maxSpeed: maxSpeed,
            averageSpeed: averageSpeed,
            accuracy: accuracy,
            isGPSBased: true
        )
        
        finalTime = totalTime
        onSprintCompleted?(result)
        
        print("🏁 Sprint completed!")
        print("   Distance: \(String(format: "%.2f", totalDistance))m")
        print("   Time: \(String(format: "%.2f", totalTime))s")
        print("   Max Speed: \(String(format: "%.2f", maxSpeed * 2.237)) mph")
        print("   Avg Speed: \(String(format: "%.2f", averageSpeed * 2.237)) mph")
    }
    
    private func updateCurrentSpeed(_ location: CLLocation) {
        if location.speed >= 0 {
            currentSpeed = location.speed // m/s
            
            // Update max speed
            if currentSpeed > maxSpeed {
                maxSpeed = currentSpeed
            }
            
            // Calculate pace (min/mile)
            if currentSpeed > 0 {
                let paceSeconds = 1609.34 / currentSpeed // seconds per mile
                let minutes = Int(paceSeconds / 60)
                let seconds = Int(paceSeconds.truncatingRemainder(dividingBy: 60))
                currentPace = String(format: "%d:%02d", minutes, seconds)
            } else {
                currentPace = "0:00"
            }
        }
    }
    
    private func checkTargetDistance() {
        if distance >= targetDistanceMeters && !hasReachedTarget {
            hasReachedTarget = true
            stopSprint()
            print("🎯 Target distance reached!")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension GPSManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out inaccurate readings
        guard location.horizontalAccuracy < 10 else { return }
        
        Task { @MainActor in
            self.accuracy = location.horizontalAccuracy
            
            if self.sprintStarted {
                if self.startLocation == nil {
                    // First location - set as start point
                    self.startLocation = location
                    print("📍 Sprint start location set")
                } else {
                    // Calculate distance from start
                    if let startLoc = self.startLocation {
                        self.distance = startLoc.distance(from: location)
                        
                        // Update speed
                        self.updateCurrentSpeed(location)
                        
                        // Check if we've reached target distance
                        self.checkTargetDistance()
                        
                        // Notify about distance update
                        self.onDistanceUpdate?(self.distance, self.elapsedTime)
                    }
                }
                
                // Store location for analysis
                self.locations.append(location)
                self.lastLocation = location
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ GPS Error: \(error.localizedDescription)")
            self.gpsStatus = .error
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                self.gpsStatus = .ready
                print("✅ GPS authorized")
            case .denied, .restricted:
                self.isAuthorized = false
                self.gpsStatus = .denied
                print("❌ GPS denied")
            case .notDetermined:
                self.isAuthorized = false
                self.gpsStatus = .requesting
            @unknown default:
                self.isAuthorized = false
                self.gpsStatus = .unavailable
            }
        }
    }
}

// MARK: - Supporting Types

enum GPSStatus {
    case unavailable
    case requesting
    case denied
    case ready
    case tracking
    case error
    
    var displayText: String {
        switch self {
        case .unavailable: return "GPS Unavailable"
        case .requesting: return "Requesting Permission"
        case .denied: return "GPS Access Denied"
        case .ready: return "GPS Ready"
        case .tracking: return "Tracking Sprint"
        case .error: return "GPS Error"
        }
    }
    
    var color: Color {
        switch self {
        case .unavailable, .denied, .error: return .red
        case .requesting: return .orange
        case .ready: return .green
        case .tracking: return .blue
        }
    }
}

struct SprintResult {
    let distance: Double // meters
    let time: Double // seconds
    let maxSpeed: Double // m/s
    let averageSpeed: Double // m/s
    let accuracy: Double // meters
    let isGPSBased: Bool
    
    // Convenience properties
    var distanceYards: Double { distance / 0.9144 }
    var maxSpeedMPH: Double { maxSpeed * 2.237 }
    var averageSpeedMPH: Double { averageSpeed * 2.237 }
    var isAccurate: Bool { accuracy < 5.0 }
}

// MARK: - Extensions for Convenience
extension GPSManager {
    
    /// Get current speed in MPH
    var currentSpeedMPH: Double {
        currentSpeed * 2.237
    }
    
    /// Get distance in yards
    var distanceYards: Double {
        distance / 0.9144
    }
    
    /// Get formatted distance string
    var distanceString: String {
        String(format: "%.1f yd", distanceYards)
    }
    
    /// Get formatted time string
    var timeString: String {
        String(format: "%.2f s", elapsedTime)
    }
    
    /// Get formatted speed string
    var speedString: String {
        String(format: "%.1f mph", currentSpeedMPH)
    }
    
    /// Check if GPS is ready for sprint
    var isReadyForSprint: Bool {
        isAuthorized && !isTracking && gpsStatus == .ready
    }
}
