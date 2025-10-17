import Foundation
import HealthKit
import Combine

#if os(watchOS)
@MainActor
class WatchHealthKitService: NSObject, ObservableObject {
    static let shared = WatchHealthKitService()
    
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0
    @Published var isMonitoringHeartRate = false
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var workoutSession: HKWorkoutSession?
    
    // Track heart rate data during workout
    private var heartRateReadings: [Double] = []
    private var workoutStartTime: Date?
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        let readTypes: Set<HKObjectType> = [heartRateType, activeEnergyType, distanceType]
        let writeTypes: Set<HKSampleType> = [HKObjectType.workoutType(), heartRateType, activeEnergyType, distanceType]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                } else {
                    print("HealthKit authorization: \(success ? "granted" : "denied")")
                }
            }
        }
    }
    
    // MARK: - Workout Session Management
    
    func startWorkout() async -> Bool {
        guard isAuthorized else {
            print("HealthKit not authorized")
            return false
        }
        
        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            // Create workout session
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            
            // Store references
            workoutSession = session
            workoutBuilder = builder
            
            // Set up delegates and data sources
            session.delegate = self
            builder.delegate = self
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            // Start the session
            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
            
            workoutStartTime = startDate
            heartRateReadings.removeAll()
            
            // Start heart rate monitoring
            startHeartRateMonitoring()
            
            print("✅ Workout session started successfully")
            return true
            
        } catch {
            print("❌ Failed to start workout session: \(error.localizedDescription)")
            return false
        }
    }
    
    func endWorkout() async -> Bool {
        guard let workoutBuilder = workoutBuilder,
              let workoutSession = workoutSession,
              let startTime = workoutStartTime else {
            print("No active workout session to end")
            return false
        }
        
        let endDate = Date()
        
        // Stop heart rate monitoring
        stopHeartRateMonitoring()
        
        do {
            // End workout session
            workoutSession.end()
            
            // End data collection
            try await workoutBuilder.endCollection(at: endDate)
            
            // Calculate workout metrics
            let duration = endDate.timeIntervalSince(startTime)
            let avgHeartRate = heartRateReadings.isEmpty ? 0 : heartRateReadings.reduce(0, +) / Double(heartRateReadings.count)
            let maxHeartRate = heartRateReadings.max() ?? 0
            
            // Add workout metadata
            try await workoutBuilder.addMetadata([
                HKMetadataKeyIndoorWorkout: false,
                "Sprint_Session": true,
                "Average_Heart_Rate": avgHeartRate,
                "Max_Heart_Rate": maxHeartRate,
                "Total_Duration": duration
            ])
            
            // Finalize workout
            _ = try await workoutBuilder.finishWorkout()
            
            // Update published values
            self.averageHeartRate = avgHeartRate
            self.maxHeartRate = maxHeartRate
            
            // Clear references
            self.workoutBuilder = nil
            self.workoutSession = nil
            workoutStartTime = nil
            
            print("✅ Workout session ended successfully")
            print("📊 Duration: \(String(format: "%.1f", duration))s, Avg HR: \(String(format: "%.0f", avgHeartRate)), Max HR: \(String(format: "%.0f", maxHeartRate))")
            
            return true
            
        } catch {
            print("❌ Failed to end workout session: \(error.localizedDescription)")
            return false
        }
    }
    
    func pauseWorkout() {
        workoutSession?.pause()
        stopHeartRateMonitoring()
        print("⏸️ Workout session paused")
    }
    
    func resumeWorkout() {
        workoutSession?.resume()
        startHeartRateMonitoring()
        print("▶️ Workout session resumed")
    }
    
    // MARK: - Heart Rate Monitoring
    
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              isAuthorized else {
            print("Heart rate monitoring not available")
            return
        }
        
        // Stop any existing query
        stopHeartRateMonitoring()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-10), // Last 10 seconds
            end: nil,
            options: .strictStartDate
        )
        
        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            Task { @MainActor in
                self?.processHeartRateSamples(samples, error: error)
            }
        }
        
        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, error in
            Task { @MainActor in
                self?.processHeartRateSamples(samples, error: error)
            }
        }
        
        healthStore.execute(heartRateQuery!)
        isMonitoringHeartRate = true
        
        print("📊 Heart rate monitoring started")
    }
    
    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        isMonitoringHeartRate = false
        print("📊 Heart rate monitoring stopped")
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?, error: Error?) {
        if let error = error {
            print("Heart rate query error: \(error.localizedDescription)")
            return
        }
        
        guard let samples = samples as? [HKQuantitySample],
              let latestSample = samples.last else {
            return
        }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRate = latestSample.quantity.doubleValue(for: heartRateUnit)
        
        currentHeartRate = heartRate
        
        // Store reading for workout statistics
        if workoutSession?.state == .running {
            heartRateReadings.append(heartRate)
            
            // Keep only recent readings (last 100 readings to avoid memory issues)
            if heartRateReadings.count > 100 {
                heartRateReadings.removeFirst(heartRateReadings.count - 100)
            }
            
            // Update average and max
            if !heartRateReadings.isEmpty {
                averageHeartRate = heartRateReadings.reduce(0, +) / Double(heartRateReadings.count)
                maxHeartRate = heartRateReadings.max() ?? 0
            }
        }
    }
    
    // MARK: - Calories Estimation
    
    func estimateCalories(duration: TimeInterval, averageHeartRate: Double, userWeight: Double = 70.0) -> Double {
        // Simple METs-based calculation for running/sprinting
        // Sprint training is approximately 8-12 METs
        let mets: Double = 10.0 // Conservative estimate for sprint training
        
        // Calories = METs × weight(kg) × time(hours)
        let hours = duration / 3600.0
        let calories = mets * userWeight * hours
        
        return calories
    }
    
    // MARK: - Public Getters
    
    var isWorkoutActive: Bool {
        return workoutSession?.state == .running
    }
    
    var workoutDuration: TimeInterval {
        guard let startTime = workoutStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    var heartRateString: String {
        if currentHeartRate > 0 {
            return String(format: "%.0f", currentHeartRate)
        }
        return "--"
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchHealthKitService: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [weak self] in
            switch toState {
            case .running:
                print("🏃‍♂️ Workout session is now running")
                self?.startHeartRateMonitoring()
            case .paused:
                print("⏸️ Workout session is now paused")
                self?.stopHeartRateMonitoring()
            case .ended:
                print("🛑 Workout session has ended")
                self?.stopHeartRateMonitoring()
            default:
                break
            }
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchHealthKitService: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Data collection updated - could add more detailed processing here
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Workout event collected
    }
}

#else
// Fallback for non-watchOS platforms
@MainActor
class WatchHealthKitService: ObservableObject {
    static let shared = WatchHealthKitService()
    
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0
    @Published var isMonitoringHeartRate = false
    
    private init() {}
    
    func requestAuthorization() { }
    func startWorkout() async -> Bool { return false }
    func endWorkout() async -> Bool { return false }
    func pauseWorkout() { }
    func resumeWorkout() { }
    
    var isWorkoutActive: Bool { false }
    var workoutDuration: TimeInterval { 0 }
    var heartRateString: String { "--" }
    
    func estimateCalories(duration: TimeInterval, averageHeartRate: Double, userWeight: Double = 70.0) -> Double {
        return 0
    }
}
#endif
