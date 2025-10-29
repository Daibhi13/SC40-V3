import Foundation
import WorkoutKit
import HealthKit
import Combine
import WatchKit

/// WorkoutKit integration for native watchOS workout sessions
@available(watchOS 9.0, *)
@MainActor
class WorkoutKitManager: NSObject, ObservableObject {
    static let shared = WorkoutKitManager()
    
    @Published var isWorkoutActive = false
    @Published var currentWorkout: HKWorkout?
    @Published var workoutState: HKWorkoutSessionState = .notStarted
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    @Published var distance: Double = 0
    
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let healthStore = HKHealthStore()
    
    // Sprint-specific metrics
    @Published var currentSprint: Int = 0
    @Published var totalSprints: Int = 0
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var sprintTimes: [TimeInterval] = []
    @Published var currentPhase: SprintPhase = .warmup
    
    private var sprintStartTime: Date?
    private var phaseTimer: Timer?
    private var workoutTimer: Timer?
    
    override init() {
        super.init()
        requestHealthKitPermissions()
    }
    
    // MARK: - HealthKit Setup
    
    private func requestHealthKitPermissions() {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization failed: \(error)")
            } else {
                print("HealthKit authorization: \(success)")
            }
        }
    }
    
    // MARK: - Workout Session Management
    
    func startSprintWorkout(
        totalSprints: Int,
        sprintDistance: Double = 40, // yards
        restDuration: TimeInterval = 90 // seconds
    ) async {
        guard !isWorkoutActive else { return }
        
        do {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .running
            configuration.locationType = .outdoor
            
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            
            // Set up data collection
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            session.delegate = self
            builder.delegate = self
            
            self.workoutSession = session
            self.builder = builder
            self.totalSprints = totalSprints
            self.currentSprint = 0
            self.currentPhase = .warmup
            
            // Start the session
            session.startActivity(with: Date())
            try await builder.beginCollection(at: Date())
            
            isWorkoutActive = true
            startWorkoutTimer()
            
            // Start with warmup phase
            await startWarmupPhase()
            
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func pauseWorkout() {
        workoutSession?.pause()
    }
    
    func resumeWorkout() {
        workoutSession?.resume()
    }
    
    func endWorkout() async {
        guard let session = workoutSession, let builder = self.builder else { return }
        
        // End the session
        session.end()
        
        do {
            // Finish the workout
            try await builder.endCollection(at: Date())
            let workout = try await builder.finishWorkout()
            
            currentWorkout = workout
            isWorkoutActive = false
            
            // Clean up
            stopWorkoutTimer()
            phaseTimer?.invalidate()
            
            print("Workout completed: \(String(describing: workout))")
            
        } catch {
            print("Failed to end workout: \(error)")
        }
    }
    
    // MARK: - Sprint Phases
    
    private func startWarmupPhase() async {
        currentPhase = .warmup
        
        // 5-minute warmup
        await startPhaseTimer(duration: 300) {
            Task { await self.startSprintPhase() }
        }
    }
    
    private func startSprintPhase() async {
        guard currentSprint < totalSprints else {
            await startCooldownPhase()
            return
        }
        
        currentSprint += 1
        currentPhase = .sprint
        sprintStartTime = Date()
        
        // Sprint phase (typically 10-15 seconds for 40 yards)
        await startPhaseTimer(duration: 15) {
            self.recordSprintTime()
            Task { await self.startRestPhase() }
        }
    }
    
    private func startRestPhase() async {
        currentPhase = .rest
        
        // Rest phase (90 seconds default)
        restTimeRemaining = 90
        
        await startPhaseTimer(duration: 90) {
            Task { await self.startSprintPhase() }
        }
    }
    
    private func startCooldownPhase() async {
        currentPhase = .cooldown
        
        // 5-minute cooldown
        await startPhaseTimer(duration: 300) {
            Task { await self.endWorkout() }
        }
    }
    
    private func startPhaseTimer(duration: TimeInterval, completion: @escaping () -> Void) async {
        phaseTimer?.invalidate()
        
        var remainingTime = duration
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            remainingTime -= 1
            
            Task { @MainActor in
                if self.currentPhase == .rest {
                    self.restTimeRemaining = remainingTime
                }
            }
            
            if remainingTime <= 0 {
                timer.invalidate()
                completion()
            }
        }
    }
    
    private func recordSprintTime() {
        guard let startTime = sprintStartTime else { return }
        
        let sprintTime = Date().timeIntervalSince(startTime)
        sprintTimes.append(sprintTime)
        
        print("Sprint \(currentSprint) completed in \(String(format: "%.2f", sprintTime)) seconds")
        
        // Add sprint time as a sample to HealthKit
        if let builder = self.builder {
            // let sprintTimeQuantity = HKQuantity(unit: HKUnit.second(), doubleValue: sprintTime) // Unused variable
            let sprintTimeSample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                quantity: HKQuantity(unit: HKUnit.yard(), doubleValue: 40),
                start: startTime,
                end: Date()
            )
            
            builder.add([sprintTimeSample]) { success, error in
                if let error = error {
                    print("Failed to add sprint sample: \(error)")
                }
            }
        }
    }
    
    // MARK: - Manual Sprint Control
    
    func startSprint() {
        guard currentPhase == .ready else { return }
        
        currentPhase = .sprint
        sprintStartTime = Date()
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.start)
    }
    
    func finishSprint() {
        guard currentPhase == .sprint else { return }
        
        recordSprintTime()
        currentPhase = .rest
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        // Start rest timer
        Task {
            await startRestPhase()
        }
    }
    
    // MARK: - Workout Timer
    
    private func startWorkoutTimer() {
        let startTime = Date()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                // Calculate elapsed time from start time for accuracy
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    // MARK: - Workout Summary
    
    func getWorkoutSummary() -> SprintWorkoutSummary? {
        guard !sprintTimes.isEmpty else { return nil }
        
        let bestTime = sprintTimes.min() ?? 0
        let averageTime = sprintTimes.reduce(0, +) / Double(sprintTimes.count)
        let totalDistance = Double(sprintTimes.count) * 40 // 40 yards per sprint
        
        return SprintWorkoutSummary(
            totalSprints: sprintTimes.count,
            bestTime: bestTime,
            averageTime: averageTime,
            totalDistance: totalDistance,
            totalDuration: elapsedTime,
            caloriesBurned: calories,
            averageHeartRate: heartRate,
            sprintTimes: sprintTimes
        )
    }
}

// MARK: - HKWorkoutSessionDelegate

@available(watchOS 9.0, *)
extension WorkoutKitManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.workoutState = toState
        }
        
        switch toState {
        case .running:
            print("Workout session started")
        case .paused:
            print("Workout session paused")
        case .stopped:
            print("Workout session stopped")
        default:
            break
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

@available(watchOS 9.0, *)
extension WorkoutKitManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    if let heartRateUnit = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) {
                        self.heartRate = heartRateUnit
                    }
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    if let caloriesUnit = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
                        self.calories = caloriesUnit
                    }
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    if let distanceUnit = statistics?.sumQuantity()?.doubleValue(for: HKUnit.yard()) {
                        self.distance = distanceUnit
                    }
                default:
                    break
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events
    }
}

// MARK: - Supporting Types

enum SprintPhase {
    case warmup
    case ready
    case sprint
    case rest
    case cooldown
    case finished
}

struct SprintWorkoutSummary {
    let totalSprints: Int
    let bestTime: TimeInterval
    let averageTime: TimeInterval
    let totalDistance: Double // in yards
    let totalDuration: TimeInterval
    let caloriesBurned: Double
    let averageHeartRate: Double
    let sprintTimes: [TimeInterval]
}
