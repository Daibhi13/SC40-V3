import Foundation
import HealthKit
import WatchKit
import Combine

#if canImport(CoreLocation)
import CoreLocation
#endif

/// Core autonomous workout execution manager for Apple Watch
/// Handles HealthKit integration, workout sessions, and real-time monitoring
class WatchWorkoutManager: NSObject, ObservableObject {
    static let shared = WatchWorkoutManager()
    
    // MARK: - Published Properties
    @Published var isWorkoutActive = false
    @Published var currentHeartRate: Int = 0
    @Published var averageHeartRate: Int = 0
    @Published var maxHeartRate: Int = 0
    @Published var currentPace: Double = 0.0 // mph
    @Published var currentDistance: Double = 0.0 // yards
    @Published var caloriesBurned: Int = 0
    @Published var workoutDuration: TimeInterval = 0
    @Published var currentWorkoutType: HKWorkoutActivityType = .running
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var workoutTimer: Timer?
    private var startDate: Date?
    
    // Heart rate data collection
    private var heartRateData: [HeartRateReading] = []
    private var heartRateSum: Int = 0
    private var heartRateCount: Int = 0
    
    // Workout metrics
    private var totalEnergyBurned: Double = 0
    private var totalDistance: Double = 0
    
    private override init() {
        super.init()
        requestHealthKitPermissions()
    }
    
    // MARK: - HealthKit Permissions
    
    private func requestHealthKitPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKWorkoutType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit permissions granted")
                    self?.setupHealthKitQueries()
                } else {
                    print("❌ HealthKit permissions denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Workout Session Management
    
    func startWorkout(type: HKWorkoutActivityType = .running) {
        guard !isWorkoutActive else {
            print("⚠️ Workout already active")
            return
        }
        
        // Clean up any existing sessions first
        if workoutSession != nil {
            print("🧹 Cleaning up existing session before starting new one")
            cleanupWorkoutSession()
        }
        
        print("🏃‍♂️ Creating new workout session...")
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            // Set data source
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            // Start the session
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.isWorkoutActive = true
                        self?.startDate = Date()
                        if let strongSelf = self {
                            strongSelf.currentWorkoutType = type
                        }
                        self?.startWorkoutTimer()
                        self?.startHeartRateMonitoring()
                        print("✅ Workout session started successfully")
                    } else {
                        print("❌ Failed to start workout: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } catch {
            print("❌ Failed to create workout session: \(error.localizedDescription)")
        }
    }
    
    func pauseWorkout() {
        guard isWorkoutActive else { return }
        
        print("⏸️ Pausing workout session...")
        workoutSession?.pause()
        workoutTimer?.invalidate()
    }
    
    func resumeWorkout() {
        guard isWorkoutActive else { return }
        
        print("▶️ Resuming workout session...")
        workoutSession?.resume()
        startWorkoutTimer()
    }
    
    func endWorkout() {
        guard isWorkoutActive else { return }
        
        print("🏁 Ending workout session...")
        
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.finishWorkout()
                } else {
                    print("❌ Failed to end workout: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func finishWorkout() {
        workoutBuilder?.finishWorkout { [weak self] workout, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let workout = workout {
                    print("✅ Workout saved to HealthKit: \(workout)")
                    self.saveWorkoutData(workout)
                } else {
                    print("❌ Failed to save workout: \(error?.localizedDescription ?? "Unknown error")")
                }
                
                self.cleanupWorkoutSession()
            }
        }
    }
    
    private func cleanupWorkoutSession() {
        print("🧹 Cleaning up workout session...")
        
        // Stop and end workout session properly
        if let session = workoutSession {
            if session.state == .running {
                session.end()
                print("🛑 Workout session ended")
            }
        }
        
        // Stop workout builder
        if let builder = workoutBuilder {
            builder.endCollection(withEnd: Date()) { [weak self] success, error in
                if let error = error {
                    print("❌ Error ending workout builder: \(error.localizedDescription)")
                } else {
                    print("✅ Workout builder ended successfully")
                }
            }
        }
        
        isWorkoutActive = false
        workoutSession = nil
        workoutBuilder = nil
        workoutTimer?.invalidate()
        workoutTimer = nil
        stopHeartRateMonitoring()
        
        // Reset metrics
        currentHeartRate = 0
        averageHeartRate = 0
        maxHeartRate = 0
        currentPace = 0.0
        currentDistance = 0.0
        workoutDuration = 0
        
        print("✅ Workout session cleanup completed")
        
        // Clear data arrays
        heartRateData.removeAll()
        heartRateSum = 0
        heartRateCount = 0
        totalEnergyBurned = 0
        totalDistance = 0
        
        print("🧹 Workout session cleanup completed")
    }
    
    // MARK: - Heart Rate Monitoring
    
    private func setupHealthKitQueries() {
        // This will be called after permissions are granted
        print("📊 HealthKit queries ready for setup")
    }
    
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("❌ Heart rate type not available")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )
        
        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        heartRateQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(heartRateQuery!)
        print("❤️ Heart rate monitoring started")
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for sample in heartRateSamples {
                let heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                
                // Update current heart rate
                self.currentHeartRate = heartRate
                
                // Track for averages
                self.heartRateSum += heartRate
                self.heartRateCount += 1
                self.averageHeartRate = self.heartRateCount > 0 ? self.heartRateSum / self.heartRateCount : 0
                
                // Track max
                if heartRate > self.maxHeartRate {
                    self.maxHeartRate = heartRate
                }
                
                // Store reading
                let reading = HeartRateReading(
                    heartRate: heartRate,
                    timestamp: sample.startDate
                )
                self.heartRateData.append(reading)
                
                print("❤️ Heart Rate: \(heartRate) bpm (Avg: \(self.averageHeartRate), Max: \(self.maxHeartRate))")
            }
        }
    }
    
    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            print("❤️ Heart rate monitoring stopped")
        }
    }
    
    // MARK: - Workout Timer
    
    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.startDate else { return }
            
            DispatchQueue.main.async {
                self.workoutDuration = Date().timeIntervalSince(startDate)
            }
        }
    }
    
    // MARK: - Data Management
    
    private func saveWorkoutData(_ workout: HKWorkout) {
        let workoutData = CompletedWorkout(
            id: UUID(),
            type: .mainProgram,
            date: workout.startDate,
            duration: workout.duration,
            completedReps: [], // Will be populated by interval manager
            averageTime: 0, // Will be calculated from reps
            bestTime: 0, // Will be calculated from reps
            totalDistance: Int(totalDistance),
            heartRateData: heartRateData.map { HeartRatePoint(timestamp: $0.timestamp, heartRate: $0.heartRate) },
            notes: "Autonomous watch workout - \(currentWorkoutType.name)"
        )
        
        // Save to local data manager
        WorkoutDataManager.shared.saveWorkout(workoutData)
        
        print("💾 Workout data saved locally")
    }
    
    // MARK: - Workout Type Detection
    
    func updateWorkoutType(for phase: String) {
        let newType: HKWorkoutActivityType
        
        switch phase.lowercased() {
        case "sprint", "sprints":
            newType = .running
        case "warmup", "warm-up":
            newType = .preparationAndRecovery
        case "cooldown", "cool-down":
            newType = .cooldown
        case "drills":
            newType = .functionalStrengthTraining
        default:
            newType = .other
        }
        
        if newType != currentWorkoutType {
            currentWorkoutType = newType
            print("🔄 Workout type updated to: \(newType.name)")
        }
    }
    
    // MARK: - Metrics Access
    
    func getCurrentMetrics() -> WorkoutMetrics {
        return WorkoutMetrics(
            heartRate: currentHeartRate,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            pace: currentPace,
            distance: currentDistance,
            calories: caloriesBurned,
            duration: workoutDuration
        )
    }
    
    func getHeartRateData() -> [HeartRateReading] {
        return heartRateData
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [weak self] in
            switch toState {
            case .running:
                print("🏃‍♂️ Workout session running")
            case .paused:
                print("⏸️ Workout session paused")
            case .ended:
                print("🏁 Workout session ended")
                self?.isWorkoutActive = false
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.cleanupWorkoutSession()
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Handle collected workout data
        for type in collectedTypes {
            if type == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                updateCaloriesBurned(from: workoutBuilder)
            } else if type == HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
                updateDistance(from: workoutBuilder)
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
    
    private func updateCaloriesBurned(from builder: HKLiveWorkoutBuilder) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let statistics = builder.statistics(for: energyType)
        let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        
        DispatchQueue.main.async { [weak self] in
            self?.caloriesBurned = Int(calories)
            self?.totalEnergyBurned = calories
        }
    }
    
    private func updateDistance(from builder: HKLiveWorkoutBuilder) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let statistics = builder.statistics(for: distanceType)
        let distance = statistics?.sumQuantity()?.doubleValue(for: .yard()) ?? 0
        
        DispatchQueue.main.async { [weak self] in
            self?.currentDistance = distance
            self?.totalDistance = distance
        }
    }
}

// MARK: - Supporting Data Models

struct HeartRateReading: Codable {
    let heartRate: Int
    let timestamp: Date
}

struct WorkoutMetrics {
    let heartRate: Int
    let averageHeartRate: Int
    let maxHeartRate: Int
    let pace: Double
    let distance: Double
    let calories: Int
    let duration: TimeInterval
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running:
            return "Running"
        case .preparationAndRecovery:
            return "Warm-up"
        case .cooldown:
            return "Cool-down"
        case .functionalStrengthTraining:
            return "Drills"
        default:
            return "Training"
        }
    }
}
