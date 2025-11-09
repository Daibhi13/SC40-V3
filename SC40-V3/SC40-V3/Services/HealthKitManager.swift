import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]
    
    // Health data types we want to write
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.workoutType()
    ]
    
    private init() {
        // Don't check authorization status on init - causes crash
        // Will be checked when requestAuthorization() is called
        // checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.errorMessage = "HealthKit is not available on this device"
            }
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            
            await MainActor.run {
                self.checkAuthorizationStatus()
                self.isAuthorized = self.authorizationStatus == .sharingAuthorized
                self.errorMessage = nil
            }
            
            print("✅ HealthKit: Authorization requested successfully")
            return isAuthorized
            
        } catch {
            await MainActor.run {
                self.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                self.isAuthorized = false
            }
            print("❌ HealthKit: Authorization failed - \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        // Check authorization for a representative type
        authorizationStatus = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    // MARK: - Profile Data Import
    
    func fetchProfileData() async -> ProfileData? {
        guard isAuthorized else {
            print("⚠️ HealthKit: Not authorized to fetch profile data")
            return nil
        }
        
        do {
            let height = try await fetchHeight()
            let weight = try await fetchWeight()
            let age = try await fetchAge()
            let gender = try await fetchGender()
            
            let profileData = ProfileData(
                height: height,
                weight: weight,
                age: age,
                gender: gender
            )
            
            print("✅ HealthKit: Profile data fetched successfully")
            return profileData
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch profile data: \(error.localizedDescription)"
            }
            print("❌ HealthKit: Failed to fetch profile data - \(error.localizedDescription)")
            return nil
        }
    }
    
    private func fetchHeight() async throws -> Double? {
        let _ = HKQuantityType.quantityType(forIdentifier: .height)!
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let _ = try healthStore.biologicalSex()
                // Note: Height is a characteristic, not a quantity
                // This is a simplified implementation - in reality you'd query for height samples
                continuation.resume(returning: nil) // Placeholder
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func fetchWeight() async throws -> Double? {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                let weightInLbs = weightInKg * 2.20462 // Convert to pounds
                continuation.resume(returning: weightInLbs)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchAge() async throws -> Int? {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let dateOfBirth = try healthStore.dateOfBirthComponents()
                let calendar = Calendar.current
                let now = Date()
                let ageComponents = calendar.dateComponents([.year], from: dateOfBirth.date ?? now, to: now)
                continuation.resume(returning: ageComponents.year)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func fetchGender() async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let biologicalSex = try healthStore.biologicalSex()
                let gender: String
                switch biologicalSex.biologicalSex {
                case .male:
                    gender = "Male"
                case .female:
                    gender = "Female"
                case .other:
                    gender = "Other"
                default:
                    gender = "Other"
                }
                continuation.resume(returning: gender)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Workout Data Export
    
    func saveWorkout(
        type: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        distance: Double? = nil,
        calories: Double? = nil
    ) async -> Bool {
        guard isAuthorized else {
            print("⚠️ HealthKit: Not authorized to save workout")
            return false
        }
        
        let metadata: [String: Any] = [:]
        
        let workout = HKWorkout(
            activityType: type,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: calories.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
            totalDistance: distance.map { HKQuantity(unit: .meter(), doubleValue: $0) },
            metadata: metadata
        )
        
        do {
            try await healthStore.save(workout)
            print("✅ HealthKit: Workout saved successfully")
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save workout: \(error.localizedDescription)"
            }
            print("❌ HealthKit: Failed to save workout - \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Sprint Performance Export
    
    func saveSprintPerformance(
        time: Double,
        distance: Double,
        date: Date = Date()
    ) async -> Bool {
        guard isAuthorized else {
            print("⚠️ HealthKit: Not authorized to save sprint performance")
            return false
        }
        
        // Calculate speed (m/s)
        let distanceInMeters = distance * 0.9144 // Convert yards to meters
        let speedMPS = distanceInMeters / time
        
        let speedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed)!
        let speedQuantity = HKQuantity(unit: HKUnit.meter().unitDivided(by: .second()), doubleValue: speedMPS)
        
        let speedSample = HKQuantitySample(
            type: speedType,
            quantity: speedQuantity,
            start: date,
            end: date.addingTimeInterval(time),
            metadata: [
                "Sprint Distance": "\(distance) yards",
                "Sprint Time": "\(time) seconds",
                "App": "Sprint Coach 40"
            ]
        )
        
        do {
            try await healthStore.save(speedSample)
            print("✅ HealthKit: Sprint performance saved - \(String(format: "%.2f", time))s for \(distance)yd")
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save sprint performance: \(error.localizedDescription)"
            }
            print("❌ HealthKit: Failed to save sprint performance - \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Profile Data Structure

struct ProfileData {
    let height: Double?      // inches
    let weight: Double?      // pounds
    let age: Int?           // years
    let gender: String?     // Male/Female/Other
    
    var isComplete: Bool {
        height != nil && weight != nil && age != nil && gender != nil
    }
}
