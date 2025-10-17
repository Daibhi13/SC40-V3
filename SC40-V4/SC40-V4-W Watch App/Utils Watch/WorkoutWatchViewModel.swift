import Foundation
import Combine
import CoreLocation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Simplified workout phase enum for Watch
enum WorkoutPhase: String, CaseIterable {
    case warmup = "Warm Up"
    case drills = "Drills"
    case strides20 = "20s Strides"
    case sprint = "Sprint"
    case rest = "Rest"
    case timeTrial = "Time Trial"
    case cooldown = "Cool Down"
    
    var displayName: String { rawValue }
}

/// Manages workout phases, timers, and GPS.
@MainActor
class WorkoutWatchViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    /// Array of distances for each rep (in yards). Will be populated from real session data.
    @Published var repDistances: [Int] = [40] // Default to 40yd, will be updated from session
    
    /// Updates rep distances from a real training session
    func updateFromSession(distances: [Int]) {
        self.repDistances = distances
        self.totalReps = distances.count
    }
    @Published var isSessionFinished: Bool = false {
        didSet {
            if isSessionFinished {
                Task {
                    await endHealthKitWorkout()
                    sendWorkoutToPhone()
                }
            }
        }
    }
    @Published var currentPhase: WorkoutPhase = .warmup
    @Published var isPaused: Bool = false

    // --- Properties needed for MainWorkoutWatchView ---
    @Published var currentRepTime: TimeInterval = 0 // seconds
    @Published var currentRestSeconds: Int? = nil // seconds left in rest, or nil if not resting

    // Computed string for display
    var currentRepTimeString: String {
        String(format: "%.1f", currentRepTime)
    }

    // Placeholder properties for the rest of the view
    @Published var currentRep: Int = 1
    @Published var totalReps: Int = 5
    @Published var restTimeString: String = "--"
    @Published var repProgress: Double = 0.5
    @Published var currentStrides: Int = 0
    @Published var lastRepTime: TimeInterval = 0 // seconds

    var lastRepTimeString: String {
        lastRepTime > 0 ? String(format: "%.1f", lastRepTime) : "--"
    }

    // MARK: - Properties for GPS and Timer
    @Published var restTime: TimeInterval = 30
    @Published var isRunning: Bool = false
    @Published var distanceTraveled: Double = 0
    @Published var isHapticEnabled: Bool = true
    private var lastLocation: CLLocation?
    private var timer: AnyCancellable?

    // MARK: - Private Properties
    private var restTimer: Timer?
    private var restSecondsLeft: Int = 0
    private var cancellables = Set<AnyCancellable>()
    private var locationManager: CLLocationManager
    private var workoutStartTime: Date?

    // MARK: - Initializer
    init(totalReps: Int = 3, restTime: TimeInterval = 30) {
        self.totalReps = totalReps
        self.restTime = restTime
        self.isRunning = false
        self.distanceTraveled = 0
        self.lastLocation = nil
        self.timer = nil
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 1
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        #endif
    }

    override convenience init() {
        self.init(totalReps: 3, restTime: 30)
    }
    
    // MARK: - HealthKit Integration Stubs
    
    private func startHealthKitWorkout() async {
        workoutStartTime = Date()
        print("✅ HealthKit workout started (Watch stub)")
    }
    
    private func endHealthKitWorkout() async {
        print("✅ HealthKit workout ended (Watch stub)")
    }

    // MARK: - Phase Logic
    func phaseDuration(for phase: WorkoutPhase) -> TimeInterval {
        switch phase {
        case .warmup, .drills, .cooldown: return 60
        case .sprint, .rest: return 0
        case .strides20: return 30 // Set a default duration for strides20, adjust as needed
        case .timeTrial: return 40 // Set a default duration for timeTrial, adjust as needed
        }
    }

    func startPhase() {
        // Start HealthKit workout when entering main workout phases
        if currentPhase == .sprint || currentPhase == .strides20 || currentPhase == .timeTrial {
            Task {
                await startHealthKitWorkout()
            }
        }
        
        switch currentPhase {
        case .warmup, .drills, .cooldown:
            startTimer(duration: phaseDuration(for: currentPhase)) { [weak self] in
                self?.completeRep()
            }
        case .sprint, .rest:
            currentRep = 1
            startRep()
        case .strides20, .timeTrial:
            startTimer(duration: phaseDuration(for: currentPhase)) { [weak self] in
                self?.completeRep()
            }
        }
    }

    func startRep() {
        isRunning = true
        currentRepTime = 0
        repProgress = 0  // Reset rest progress when starting new rep
        startGPS()
        
        timer?.cancel()
        timer = Timer.publish(every: 0.1, on: .main, in: .common) // More frequent updates
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentRepTime += 0.1
                
                // Get current session distance from repDistances array
                let currentDistance = self.repDistances[safe: self.currentRep - 1] ?? 40
                let targetDistanceMeters = Double(currentDistance) * 0.9144 // Correct yards to meters
                
                if self.distanceTraveled >= targetDistanceMeters {
                    self.completeCurrentRep()
                }
            }
    }
    
    func completeCurrentRep() {
        isRunning = false
        stopGPS()
        lastRepTime = currentRepTime
        
        // Haptic feedback for rep completion
        if isHapticEnabled {
            // Add haptic feedback here
        }
        startRest()
    }

    func startRest() {
        repProgress = 0
        if isHapticEnabled {
            // Haptic feedback would go here
        }
        
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.repProgress += 1 / self.restTime
                if self.repProgress >= 1.0 {
                    self.timer?.cancel()
                    self.currentRep += 1
                    if self.currentRep <= self.totalReps {
                        self.startRep()
                    } else {
                        self.nextPhase()
                    }
                }
            }
    }

    private func startTimer(duration: TimeInterval, completion: @escaping () -> Void) {
        timer?.cancel()
        var timeLeft = duration
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timeLeft -= 1
                if timeLeft <= 0 {
                    self.timer?.cancel()
                    completion()
                }
            }
    }

    func completeRep() {
        if currentRep < totalReps {
            currentRep += 1
            startPhase()
        } else {
            nextPhase()
        }
    }

    func nextPhase() {
        let allPhases: [WorkoutPhase] = [.warmup, .drills, .strides20, .sprint, .rest, .cooldown]
        if let index = allPhases.firstIndex(of: currentPhase), index + 1 < allPhases.count {
            currentPhase = allPhases[index + 1]
            startPhase()
        } else {
            // Workout finished
            isSessionFinished = true
        }
    }

    func setupUltra2Features() {
        startPhase()
    }

    // MARK: - UI Computed Properties
    var heartRateString: String {
        return "--" // Placeholder for heart rate
    }
    
    // MARK: - Distance Display Logic (Fixed)
    /// Returns the yards to display in the main workout view.
    /// **Behavior:**
    /// - During active sprint: Shows current rep's distance (static throughout the rep)
    /// - During rest period: Shows next rep's distance (so user can prepare)
    /// - Before workout starts: Shows first rep's distance
    /// - After final rep: Shows final rep's distance
    ///
    /// **Example with [40, 60, 40] yard reps:**
    /// Rep 1 sprint: "40", Rest after Rep 1: "60", Rep 2 sprint: "60", Rest after Rep 2: "40", Rep 3 sprint: "40"
    var distanceRemainingString: String { 
        // During active sprint: show current rep's distance (static throughout the rep)
        // During rest (between reps): show next rep's distance so user can prepare
        // Before workout starts: show first rep's distance
        // After final rep: show final rep's distance
        
        let distanceToShow: Int
        
        if !isRunning && repProgress > 0 && currentRep < totalReps {
            // We're in rest between reps, show next rep's distance
            distanceToShow = repDistances[safe: currentRep] ?? 40
        } else {
            // During active sprint or before starting, show current rep's distance
            distanceToShow = repDistances[safe: currentRep - 1] ?? 40
        }
        
        return String(distanceToShow)
    }
    
    var stopwatchTimeString: String { String(format: "%.2f", currentRepTime) }
    var currentPhaseLabel: String { currentPhase.displayName }
    
    var avgSplitString: String {
        return "--" // Placeholder for average split
    }
    
    var lastSprintString: String { lastRepTimeString }
    var rpe: String { "--" }
    var leaderboardRank: String { "--" }

    // Add computed property for restProgress
    var restProgress: Double {
        // If in rest, show progress, else 0
        if currentPhase == .rest && restTime > 0 {
            return min(repProgress, 1.0)
        } else {
            return 0.0
        }
    }
    // Add computed property for paceString
    var paceString: String { "--" }

    var isGPSPhase: Bool {
        switch currentPhase {
        case .strides20, .sprint, .timeTrial:
            return true
        default:
            return false
        }
    }

    func sendWorkoutToPhone() {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else { return }
        
        let workoutData: [String: Any] = [
            "date": Date().timeIntervalSince1970,
            "distance": distanceTraveled,
            "duration": Date().timeIntervalSince(workoutStartTime ?? Date()),
            "phase": currentPhase.displayName,
            "totalReps": totalReps,
            "completedReps": currentRep - 1
        ]
        
        WCSession.default.sendMessage(workoutData, replyHandler: nil, errorHandler: nil)
        #endif
    }
    
    func sendCompletedSession(_ session: WatchTrainingSession) {
        #if canImport(WatchConnectivity)
        guard WCSession.default.isReachable else { return }
        
        // Convert session to dictionary format for sending
        let sessionData: [String: Any] = [
            "week": session.week,
            "day": session.day,
            "type": session.type,
            "focus": session.focus,
            "sprints": session.sprints.map { sprint in
                [
                    "distanceYards": sprint.distanceYards,
                    "reps": sprint.reps,
                    "intensity": sprint.intensity
                ]
            },
            "accessoryWork": session.accessoryWork,
            "notes": session.notes ?? "",
            "date": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(sessionData, replyHandler: nil) { error in
            print("Error sending session to phone: \(error.localizedDescription)")
        }
        #endif
    }
    
    // MARK: - Session Control Methods
    func pauseSession() {
        isPaused = true
        stopGPS()
        restTimer?.invalidate()
        print("📱 Session paused")
    }
    
    func resumeSession() {
        isPaused = false
        print("📱 Session resumed")
    }
    
    func goToPreviousStep() {
        guard currentRep > 1 else { return }
        currentRep -= 1
        print("📱 Went back to rep \(currentRep)")
    }
    
    func goToNextStep() {
        guard currentRep < totalReps else { return }
        currentRep += 1
        print("📱 Advanced to rep \(currentRep)")
    }
    
    func toggleHapticFeedback() {
        isHapticEnabled.toggle()
        print("📱 Haptic feedback \(isHapticEnabled ? "enabled" : "disabled")")
    }
    
    // MARK: - GPS Methods
    
    func startGPS() {
        distanceTraveled = 0
        lastLocation = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopGPS() {
        locationManager.stopUpdatingLocation()
        lastLocation = nil
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - CLLocationManagerDelegate
extension WorkoutWatchViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard isRunning else { return }
            if let newLocation = locations.last {
                if let last = lastLocation {
                    distanceTraveled += newLocation.distance(from: last)
                }
                lastLocation = newLocation
            }
        }
    }
}

// MARK: - WCSessionDelegate
#if canImport(WatchConnectivity)
extension WorkoutWatchViewModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {}
}
#endif

extension WorkoutWatchViewModel {
    static var mock: WorkoutWatchViewModel {
        let vm = WorkoutWatchViewModel()
        vm.isSessionFinished = false
        vm.currentPhase = .warmup
        vm.isPaused = false
        vm.isHapticEnabled = true
        vm.currentRepTime = 7.2
        vm.currentRestSeconds = 30
        vm.currentRep = 3
        vm.totalReps = 8
        vm.restTimeString = "00:30"
        vm.repProgress = 0.45
        vm.currentStrides = 22
        return vm
    }
    
    /// Creates a WorkoutWatchViewModel configured for a specific training session
    static func fromSession(_ session: WatchTrainingSession) -> WorkoutWatchViewModel {
        // Calculate total reps from all sprint sets
        let totalReps = session.sprints.reduce(0) { total, sprint in
            total + sprint.reps
        }
        
        // Use a reasonable default rest time (could be made configurable)
        let restTime: TimeInterval = 90
        
        let vm = WorkoutWatchViewModel(totalReps: max(1, totalReps), restTime: restTime)
        
        // Configure distances for each rep
        vm.repDistances = session.sprints.flatMap { sprint in
            Array(repeating: sprint.distanceYards, count: sprint.reps)
        }
        
        print("🏃‍♂️ Created WorkoutWatchViewModel from session: W\(session.week)/D\(session.day)")
        print("   Total reps: \(totalReps)")
        print("   Distances: \(vm.repDistances)")
        print("   Session type: \(session.type)")
        print("   Focus: \(session.focus)")
        
        return vm
    }
}

// MARK: - Distance Display Documentation
/*
 ## Distance Display Behavior Across Watch Views
 
 All workout-related watch views now use the centralized `distanceRemainingString` property for consistent distance display behavior.
 
 ### Views Using Fixed Distance Display:
 
 1. **MainWorkoutWatchView**
    - Location: `StatModuleView` in top stats row
    - Usage: `workoutVM.distanceRemainingString`
    - Purpose: Main workout interface showing yards in "Yards" module
 
 2. **SprintWatchView**
    - Location: Distance & GPS Info section
    - Usage: `viewModel.distanceRemainingString` 
    - Purpose: Shows "Target: XX yd" during sprint sessions
 
 3. **TimeTrialWorkoutView**
    - Location: `StatModuleView` in top stats row
    - Usage: `workoutVM.distanceRemainingString`
    - Purpose: Time trial interface showing yards in "Yards" module
 
 ### Fixed Behavior:
 - **During Active Sprint** (`isRunning = true`): Shows current rep's distance (static throughout the rep)
 - **During Rest Period** (`!isRunning && repProgress > 0`): Shows next rep's distance (preview for preparation)
 - **Before Workout Starts**: Shows first rep's distance
 - **After Final Rep**: Shows final rep's distance
 
 ### Example with [40, 60, 40] yard session:
 - Rep 1 sprint: Displays "40" (static during sprint)
 - Rest after Rep 1: Displays "60" (shows next distance)
 - Rep 2 sprint: Displays "60" (static during sprint)
 - Rest after Rep 2: Displays "40" (shows next distance)
 - Rep 3 sprint: Displays "40" (static during sprint)
 
 ### Views with Independent Distance Management:
 - **StarterProWatchView**: Uses local distance picker (manual selection), not session-based
 
 This ensures consistent user experience where the yards display remains static during active sprints 
 and only changes during rest periods to show the upcoming distance.
 */
