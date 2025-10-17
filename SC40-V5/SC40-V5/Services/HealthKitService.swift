//
//  HealthKitService.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import HealthKit
import Combine

/// Service for integrating with Apple HealthKit
class HealthKitService: NSObject, ObservableObject {

    static let shared = HealthKitService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var lastError: Error?

    private let healthStore = HKHealthStore()
    private var activeQueries: Set<HKQuery> = []

    // MARK: - HealthKit Types

    private let workoutType = HKObjectType.workoutType()
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    // MARK: - Authorization

    /// Request authorization to access HealthKit data
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceType,
            stepCountType,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        ]

        let typesToWrite: Set<HKSampleType> = [
            workoutType,
            activeEnergyType,
            distanceType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            await MainActor.run {
                self.lastError = error
            }
            throw error
        }
    }

    // MARK: - Workout Recording

    /// Start recording a sprint workout
    func startWorkout(startDate: Date = Date(),
                     metadata: [String: Any]? = nil) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        try await healthStore.startWatchApp(toHandle: configuration)
    }

    /// End the current workout session
    func endWorkout(endDate: Date = Date(),
                   totalDistance: Double,
                   totalEnergy: Double,
                   metadata: [String: Any]? = nil) async throws {

        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: totalDistance)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergy)

        // Note: In iOS 18+, we don't need to explicitly end workouts
        // The system handles this automatically when the app goes to background
        // or when explicitly stopped via other means
    }

    // MARK: - Data Retrieval

    /// Get heart rate data for a specific time period
    func getHeartRateData(startDate: Date,
                         endDate: Date) async throws -> [HeartRateSample] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                   end: endDate,
                                                   options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType,
                                    predicate: predicate,
                                    limit: HKObjectQueryNoLimit,
                                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let heartRateSamples = samples.map { sample in
                    HeartRateSample(
                        value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        startDate: sample.startDate,
                        endDate: sample.endDate
                    )
                }

                continuation.resume(returning: heartRateSamples)
            }

            healthStore.execute(query)
            activeQueries.insert(query)
        }
    }

    /// Get workout sessions for a specific time period
    func getWorkouts(startDate: Date,
                    endDate: Date) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                   end: endDate,
                                                   options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType,
                                    predicate: predicate,
                                    limit: HKObjectQueryNoLimit,
                                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
            activeQueries.insert(query)
        }
    }

    /// Get distance data for a time period
    func getDistanceData(startDate: Date,
                        endDate: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                   end: endDate,
                                                   options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType,
                                        quantitySamplePredicate: predicate,
                                        options: .cumulativeSum) { _, statistics, error in

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                continuation.resume(returning: distance)
            }

            healthStore.execute(query)
            activeQueries.insert(query)
        }
    }

    /// Get active energy burned for a time period
    func getActiveEnergyBurned(startDate: Date,
                              endDate: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                   end: endDate,
                                                   options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: activeEnergyType,
                                        quantitySamplePredicate: predicate,
                                        options: .cumulativeSum) { _, statistics, error in

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let energy = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
                continuation.resume(returning: energy)
            }

            healthStore.execute(query)
            activeQueries.insert(query)
        }
    }

    // MARK: - Real-time Monitoring

    /// Start real-time heart rate monitoring
    func startHeartRateMonitoring() async throws -> AsyncStream<HeartRateSample> {
        return AsyncStream { continuation in
            let query = HKAnchoredObjectQuery(type: heartRateType,
                                           predicate: nil,
                                           anchor: nil,
                                           limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in

                if let error = error {
                    continuation.finish()
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else { return }

                for sample in samples {
                    let heartRateSample = HeartRateSample(
                        value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        startDate: sample.startDate,
                        endDate: sample.endDate
                    )
                    continuation.yield(heartRateSample)
                }
            }

            query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
                if let error = error {
                    continuation.finish()
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else { return }

                for sample in samples {
                    let heartRateSample = HeartRateSample(
                        value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        startDate: sample.startDate,
                        endDate: sample.endDate
                    )
                    continuation.yield(heartRateSample)
                }
            }

            healthStore.execute(query)
            activeQueries.insert(query)
        }
    }

    // MARK: - Data Structures

    struct HeartRateSample {
        let value: Double // BPM
        let startDate: Date
        let endDate: Date
    }

    // MARK: - Cleanup

    /// Stop all active queries
    func stopAllQueries() {
        for query in activeQueries {
            healthStore.stop(query)
        }
        activeQueries.removeAll()
    }

    deinit {
        stopAllQueries()
    }
}
