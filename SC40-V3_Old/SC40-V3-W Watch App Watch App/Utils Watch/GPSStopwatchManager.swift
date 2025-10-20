import Foundation
import CoreLocation
import Combine

class GPSStopwatchManager: NSObject, ObservableObject, CLLocationManagerDelegate, @unchecked Sendable {
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0 // meters
    @Published var isRunning: Bool = false
    @Published var lastLocation: CLLocation?
    @Published var didReachTargetDistance: Bool = false

    private var timer: Timer?
    @MainActor private var startTime: Date?
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
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            // Timer is already on main thread, no need for Task/@MainActor
            Task { @MainActor in
                guard let self = self, let start = self.startTime else { return }
                // Timer logic here - using weak self properly
                let elapsed = Date().timeIntervalSince(start)
                print("Timer tick: \(elapsed)")
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
}
