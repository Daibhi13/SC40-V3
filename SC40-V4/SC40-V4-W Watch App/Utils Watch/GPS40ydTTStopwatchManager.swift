import Foundation
import CoreLocation
import Combine

class GPS40ydTTStopwatchManager: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0 // meters
    @Published var isRunning: Bool = false
    @Published var lastLocation: CLLocation?
    @Published var didReachTargetDistance: Bool = false
    @Published var gpsStatus: String = "ok"

    private var timer: Timer?
    private var startTime: Date?
    private var locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let targetDistanceMeters: Double = 36.576 // 40 yards in meters

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func start() {
        elapsedTime = 0
        distance = 0
        startTime = Date()
        lastLocation = nil
        isRunning = true
        didReachTargetDistance = false
        locationManager.startUpdatingLocation()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { @Sendable [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        locationManager.stopUpdatingLocation()
        isRunning = false
    }

    func reset() {
        stop()
        elapsedTime = 0
        distance = 0
        lastLocation = nil
        didReachTargetDistance = false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRunning, let newLocation = locations.last else { return }
        gpsStatus = "ok"
        if let last = lastLocation {
            let delta = newLocation.distance(from: last)
            if delta > 0.5 { // ignore tiny jumps
                distance += delta
                if !didReachTargetDistance && distance >= targetDistanceMeters {
                    didReachTargetDistance = true
                    stop()
                }
            }
        }
        lastLocation = newLocation
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        gpsStatus = "lost"
    }
}
