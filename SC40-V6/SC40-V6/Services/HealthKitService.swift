import Foundation
import HealthKit
import Combine
import CoreLocation

// MARK: - HealthKit Service
class HealthKitService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var lastError: String?
    
    private let healthStore = HKHealthStore()
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
        HKObjectType.quantityType(forIdentifier: .runningPower)!,
    ]
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Workout Recording
    func startWorkout(type: HKWorkoutActivityType, location: CLLocation? = nil) -> HKWorkoutSession? {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        configuration.locationType = .outdoor
        
        do {
            // Use version-compatible initializer
            let session: HKWorkoutSession
            if #available(iOS 26.0, *) {
                session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            } else {
                // For older iOS, this functionality is not available
                lastError = "Workout sessions require iOS 26.0 or later"
                return nil
            }
            session.delegate = self
            session.startActivity(with: Date())
            return session
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
    
    func stopWorkout(_ session: HKWorkoutSession) {
        session.stopActivity(with: Date())
    }
    
    // MARK: - Data Retrieval
    func getTodaysWorkouts() async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getHeartRateData(for workout: HKWorkout) async throws -> [HKQuantitySample] {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let heartRateSamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: heartRateSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    func getDistanceData(for workout: HKWorkout) async throws -> HKQuantity? {
        let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: statistics?.sumQuantity())
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Statistics
    func getWeeklyStats() async throws -> (totalDistance: Double, totalWorkouts: Int, averageHeartRate: Double?) {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        
        let workouts = try await getWorkoutsInDateRange(start: startOfWeek, end: now)
        
        var totalDistance = 0.0
        var totalHeartRate = 0.0
        var heartRateCount = 0
        
        for workout in workouts {
            if let distanceQuantity = try? await getDistanceData(for: workout),
               distanceQuantity.doubleValue(for: HKUnit.meter()) > 0 {
                totalDistance += distanceQuantity.doubleValue(for: HKUnit.meter())
            }
            
            let heartRateSamples = try await getHeartRateData(for: workout)
            for sample in heartRateSamples {
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                totalHeartRate += heartRate
                heartRateCount += 1
            }
        }
        
        let averageHeartRate = heartRateCount > 0 ? totalHeartRate / Double(heartRateCount) : nil
        
        return (totalDistance, workouts.count, averageHeartRate)
    }
    
    private func getWorkoutsInDateRange(start: Date, end: Date) async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension HealthKitService: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session state changed: \(fromState) -> \(toState)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        lastError = error.localizedDescription
    }
}
