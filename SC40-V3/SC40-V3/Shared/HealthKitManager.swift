import Foundation
import HealthKit

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

// Helper class for thread-safe data storage
final class UserProfileData: @unchecked Sendable {
    private let lock = NSLock()
    private var _age: Int?
    private var _weight: Double?
    private var _biologicalSex: HKBiologicalSex?
    
    var age: Int? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _age
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _age = newValue
        }
    }
    
    var weight: Double? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _weight
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _weight = newValue
        }
    }
    
    var biologicalSex: HKBiologicalSex? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _biologicalSex
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _biologicalSex = newValue
        }
    }
}

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isWorkoutActive = false
    
    private let healthStore = HKHealthStore()
    
    // MARK: - HealthKit Data Types
    
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.workoutType()
    ]
    
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.workoutType()
    ]
    
    init() {
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
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
    
    // MARK: - Workout Management
    
    func startWorkout(activityType: HKWorkoutActivityType = .running, locationType: HKWorkoutSessionLocationType = .outdoor) async -> Bool {
        guard isAuthorized else {
            print("HealthKit not authorized")
            return false
        }
        
        await MainActor.run {
            self.isWorkoutActive = true
            print("✅ HealthKit workout tracking started")
        }
        return true
    }
    
    func endWorkout(startDate: Date, endDate: Date = Date(), totalEnergyBurned: Double? = nil, totalDistance: Double? = nil, metadata: [String: Any]? = nil) async -> Bool {
        guard isAuthorized else {
            print("HealthKit not authorized")
            return false
        }
        
        let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: HKWorkoutConfiguration(), device: .local())
        
        var workoutMetadata = metadata ?? [:]
        workoutMetadata[HKMetadataKeyIndoorWorkout] = false
        
        do {
            // Begin collection using modern async API
            try await workoutBuilder.beginCollection(at: startDate)
            
            // Add samples if available
            var samples: [HKSample] = []
            
            // Add heart rate samples if available
            if let heartRate = await getCurrentHeartRate() {
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: heartRate)
                let heartRateSample = HKQuantitySample(
                    type: heartRateType,
                    quantity: heartRateQuantity,
                    start: startDate,
                    end: endDate
                )
                samples.append(heartRateSample)
            }
            
            // Add distance if provided
            if let totalDistance = totalDistance {
                let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
                let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: totalDistance)
                let distanceSample = HKQuantitySample(
                    type: distanceType,
                    quantity: distanceQuantity,
                    start: startDate,
                    end: endDate
                )
                samples.append(distanceSample)
            }
            
            // Add energy if provided
            if let totalEnergyBurned = totalEnergyBurned {
                let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
                let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergyBurned)
                let energySample = HKQuantitySample(
                    type: energyType,
                    quantity: energyQuantity,
                    start: startDate,
                    end: endDate
                )
                samples.append(energySample)
            }
            
            // Add samples to builder if any
            if !samples.isEmpty {
                do {
                    try await workoutBuilder.addSamples(samples)
                } catch {
                    print("Failed to add samples: \(error.localizedDescription)")
                }
            }
            
            return await withCheckedContinuation { continuation in
                // Finish collection and workout
                workoutBuilder.endCollection(withEnd: endDate) { success, error in
                    if let error = error {
                        print("Failed to end workout collection: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    workoutBuilder.finishWorkout { workout, error in
                        if let error = error {
                            print("❌ Failed to save workout to HealthKit: \(error.localizedDescription)")
                            continuation.resume(returning: false)
                        } else {
                            print("✅ Workout saved to HealthKit successfully")
                            Task { @MainActor in
                                self.isWorkoutActive = false
                            }
                            continuation.resume(returning: true)
                        }
                    }
                }
            }
            
        } catch {
            print("❌ Failed to create workout: \(error.localizedDescription)")
            await MainActor.run {
                self.isWorkoutActive = false
            }
            return false
        }
    }
    
    // MARK: - Heart Rate Monitoring
    
    func getCurrentHeartRate() async -> Double? {
        await withCheckedContinuation { continuation in
            getCurrentHeartRate { heartRate in
                continuation.resume(returning: heartRate)
            }
        }
    }
    
    private func getCurrentHeartRate(completion: @escaping @Sendable (Double?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              isAuthorized else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { @Sendable _, samples, error in
            if let error = error {
                print("Heart rate query error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let samples = samples as? [HKQuantitySample],
                  let latestSample = samples.last else {
                completion(nil)
                return
            }
            
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            let heartRate = latestSample.quantity.doubleValue(for: heartRateUnit)
            
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - User Profile Data
    
    func getUserProfile() async -> (age: Int?, weight: Double?, biologicalSex: HKBiologicalSex?) {
        await withCheckedContinuation { continuation in
            getUserProfile { age, weight, sex in
                continuation.resume(returning: (age, weight, sex))
            }
        }
    }
    
    private func getUserProfile(completion: @escaping @Sendable (Int?, Double?, HKBiologicalSex?) -> Void) {
        guard isAuthorized else {
            completion(nil, nil, nil)
            return
        }
        
        let group = DispatchGroup()
        let profileData = UserProfileData()
        
        // Get age
        group.enter()
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            profileData.age = Calendar.current.dateComponents([.year], from: dateOfBirth.date ?? Date(), to: Date()).year
        } catch {
            print("Failed to fetch date of birth: \(error.localizedDescription)")
        }
        group.leave()
        
        // Get biological sex
        group.enter()
        do {
            let sexObject = try healthStore.biologicalSex()
            profileData.biologicalSex = sexObject.biologicalSex
        } catch {
            print("Failed to fetch biological sex: \(error.localizedDescription)")
        }
        group.leave()
        
        // Get weight
        group.enter()
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { @Sendable _, samples, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Weight query error: \(error.localizedDescription)")
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample],
                      let latestSample = samples.first else {
                    return
                }
                
                profileData.weight = latestSample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(profileData.age, profileData.weight, profileData.biologicalSex)
        }
    }
    
    // MARK: - Workout History
    
    func getWorkoutHistory(limit: Int = 10) async -> [HKWorkout] {
        await withCheckedContinuation { continuation in
            getWorkoutHistory(limit: limit) { workouts in
                continuation.resume(returning: workouts)
            }
        }
    }
    
    private func getWorkoutHistory(limit: Int, completion: @escaping @Sendable ([HKWorkout]) -> Void) {
        guard isAuthorized else {
            completion([])
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: nil,
            limit: limit,
            sortDescriptors: [sortDescriptor]
        ) { @Sendable _, samples, error in
            if let error = error {
                print("Workout history query error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let workouts = samples as? [HKWorkout] ?? []
            completion(workouts)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Utility Methods
    
    func estimateCaloriesBurned(duration: TimeInterval, activityType: HKWorkoutActivityType = .running, userWeight: Double = 70.0) -> Double {
        // METs (Metabolic Equivalent of Task) values for different activities
        let mets: Double
        
        switch activityType {
        case .running:
            mets = 9.8 // Running at moderate pace
        case .walking:
            mets = 3.8 // Walking at moderate pace
        default:
            mets = 6.0 // General moderate activity
        }
        
        // Calories = METs × weight(kg) × time(hours)
        let hours = duration / 3600.0
        return mets * userWeight * hours
    }
}

// MARK: - Convenience Extensions

extension HealthKitManager {
    var isWorkoutAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable() && isAuthorized
    }
    
    func requestPermissionsIfNeeded() {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
    }
}
