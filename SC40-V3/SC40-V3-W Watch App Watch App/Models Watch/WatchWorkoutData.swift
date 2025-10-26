import Foundation
import CoreLocation
import HealthKit

/// Comprehensive workout data collection and management for Apple Watch
/// Handles all metrics, splits, heart rate zones, and performance analytics
class WatchWorkoutData: Codable {
    
    // MARK: - Basic Workout Information
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var workoutType: WatchWorkoutType
    var sessionName: String
    
    // MARK: - Workout Structure
    var totalIntervals: Int
    var completedIntervals: Int
    var plannedDistance: Int // Total planned distance in yards
    var actualDistance: Double // Actual distance covered in yards
    
    // MARK: - Timing Data
    var totalDuration: TimeInterval = 0
    var activeDuration: TimeInterval = 0 // Excluding rest periods
    var warmupDuration: TimeInterval = 0
    var cooldownDuration: TimeInterval = 0
    
    // MARK: - Sprint Performance Data
    var sprintData: [SprintPerformance] = []
    var bestSprintTime: TimeInterval = 0
    var averageSprintTime: TimeInterval = 0
    var worstSprintTime: TimeInterval = 0
    
    // MARK: - Speed and Pace Analytics
    var maxSpeed: Double = 0 // mph
    var averageSpeed: Double = 0 // mph
    var speedByInterval: [Double] = [] // mph per interval
    var paceData: [PaceReading] = []
    
    // MARK: - Heart Rate Analytics
    var heartRateData: [WatchHeartRateReading] = []
    var restingHeartRate: Int = 0
    var maxHeartRate: Int = 0
    var averageHeartRate: Int = 0
    var heartRateZones: HeartRateZones = HeartRateZones()
    var recoveryHeartRate: [WatchRecoveryReading] = []
    
    // MARK: - Split Times and Distances
    var splitTimes: [SplitTime] = [] // 10yd, 20yd, 30yd, 40yd splits
    var intervalSplits: [IntervalSplits] = [] // Splits for each interval
    
    // MARK: - GPS and Location Data
    var gpsAccuracy: [GPSAccuracyReading] = []
    var locationData: [LocationReading] = []
    var elevationData: [ElevationReading] = []
    
    // MARK: - Energy and Calories
    var caloriesBurned: Int = 0
    var activeCalories: Int = 0
    var basalCalories: Int = 0
    var energyByInterval: [Int] = []
    
    // MARK: - Environmental Data
    var temperature: Double? // Celsius
    var humidity: Double? // Percentage
    var windSpeed: Double? // mph
    var weatherConditions: String?
    
    // MARK: - Performance Metrics
    var fatigueIndex: Double = 0 // Calculated from performance decline
    var consistencyScore: Double = 0 // How consistent were the sprint times
    var improvementFromLastWorkout: Double = 0 // Percentage improvement
    var personalRecords: [PersonalRecord] = []
    
    // MARK: - Recovery Data
    var restPeriods: [RestPeriod] = []
    var heartRateRecovery: [HeartRateRecoveryData] = []
    
    // MARK: - Initialization
    
    init(workoutType: WatchWorkoutType, sessionName: String, totalIntervals: Int) {
        self.id = UUID()
        self.startTime = Date()
        self.workoutType = workoutType
        self.sessionName = sessionName
        self.totalIntervals = totalIntervals
        self.completedIntervals = 0
        self.plannedDistance = 0
        self.actualDistance = 0
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, workoutType, sessionName
        case totalIntervals, completedIntervals, plannedDistance, actualDistance
        case totalDuration, activeDuration, warmupDuration, cooldownDuration
        case sprintData, bestSprintTime, averageSprintTime, worstSprintTime
        case maxSpeed, averageSpeed, speedByInterval, paceData
        case heartRateData, restingHeartRate, maxHeartRate, averageHeartRate
        case heartRateZones, recoveryHeartRate
        case splitTimes, intervalSplits
        case gpsAccuracy, locationData, elevationData
        case caloriesBurned, activeCalories, basalCalories, energyByInterval
        case temperature, humidity, windSpeed, weatherConditions
        case fatigueIndex, consistencyScore, improvementFromLastWorkout, personalRecords
        case restPeriods, heartRateRecovery
    }
    
    // MARK: - Data Collection Methods
    
    func startInterval(_ intervalNumber: Int, distance: Int) {
        print("📊 Starting interval \(intervalNumber) - \(distance)yd")
        
        let sprint = SprintPerformance(
            intervalNumber: intervalNumber,
            distance: distance,
            startTime: Date()
        )
        sprintData.append(sprint)
        
        // Update planned distance
        plannedDistance += distance
    }
    
    func endInterval(_ intervalNumber: Int, finalTime: TimeInterval, maxSpeed: Double, splits: [SplitTime]) {
        guard let sprintIndex = sprintData.firstIndex(where: { $0.intervalNumber == intervalNumber }) else {
            print("⚠️ Could not find sprint data for interval \(intervalNumber)")
            return
        }
        
        print("📊 Ending interval \(intervalNumber) - Time: \(String(format: "%.2f", finalTime))s, Max Speed: \(String(format: "%.1f", maxSpeed)) mph")
        
        // Update sprint data
        sprintData[sprintIndex].endTime = Date()
        sprintData[sprintIndex].totalTime = finalTime
        sprintData[sprintIndex].maxSpeed = maxSpeed
        sprintData[sprintIndex].splits = splits
        
        // Update interval splits
        let intervalSplit = IntervalSplits(
            intervalNumber: intervalNumber,
            splits: splits,
            totalTime: finalTime
        )
        intervalSplits.append(intervalSplit)
        
        // Update overall metrics
        updateSprintMetrics()
        completedIntervals += 1
        
        // Add speed to interval tracking
        speedByInterval.append(maxSpeed)
    }
    
    func addHeartRateReading(_ heartRate: Int, timestamp: Date = Date()) {
        let reading = WatchHeartRateReading(heartRate: heartRate, timestamp: timestamp)
        heartRateData.append(reading)
        
        // Update heart rate metrics
        updateHeartRateMetrics()
        
        // Update heart rate zones
        updateHeartRateZones(heartRate)
    }
    
    func addGPSReading(location: CLLocation, speed: Double, accuracy: CLLocationAccuracy) {
        let locationReading = LocationReading(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            speed: speed
        )
        locationData.append(locationReading)
        
        let accuracyReading = GPSAccuracyReading(
            accuracy: accuracy,
            timestamp: location.timestamp
        )
        gpsAccuracy.append(accuracyReading)
        
        if let altitude = location.altitude as Double? {
            let elevationReading = ElevationReading(
                elevation: altitude,
                timestamp: location.timestamp
            )
            elevationData.append(elevationReading)
        }
        
        // Update distance
        updateActualDistance()
    }
    
    func addPaceReading(_ pace: Double, timestamp: Date = Date()) {
        let reading = PaceReading(pace: pace, timestamp: timestamp)
        paceData.append(reading)
    }
    
    func startRestPeriod(_ intervalNumber: Int) {
        let restPeriod = RestPeriod(
            intervalNumber: intervalNumber,
            startTime: Date(),
            startHeartRate: heartRateData.last?.heartRate ?? 0
        )
        restPeriods.append(restPeriod)
    }
    
    func endRestPeriod(_ intervalNumber: Int) {
        guard let restIndex = restPeriods.firstIndex(where: { 
            $0.intervalNumber == intervalNumber && $0.endTime == nil 
        }) else { return }
        
        restPeriods[restIndex].endTime = Date()
        restPeriods[restIndex].endHeartRate = heartRateData.last?.heartRate ?? 0
        
        // Calculate heart rate recovery
        calculateHeartRateRecovery(for: intervalNumber)
    }
    
    func updateCalories(_ calories: Int, active: Int, basal: Int) {
        caloriesBurned = calories
        activeCalories = active
        basalCalories = basal
        
        // Track calories by interval
        if energyByInterval.count < completedIntervals {
            energyByInterval.append(calories)
        }
    }
    
    func setEnvironmentalData(temperature: Double?, humidity: Double?, windSpeed: Double?, conditions: String?) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.weatherConditions = conditions
    }
    
    func completeWorkout() {
        endTime = Date()
        totalDuration = endTime!.timeIntervalSince(startTime)
        
        // Calculate final metrics
        calculateFinalMetrics()
        
        print("📊 Workout completed - Duration: \(String(format: "%.1f", totalDuration/60)) min, Intervals: \(completedIntervals)/\(totalIntervals)")
    }
    
    // MARK: - Metrics Calculation
    
    private func updateSprintMetrics() {
        let completedSprints = sprintData.filter { $0.totalTime > 0 }
        
        guard !completedSprints.isEmpty else { return }
        
        let times = completedSprints.map { $0.totalTime }
        bestSprintTime = times.min() ?? 0
        worstSprintTime = times.max() ?? 0
        averageSprintTime = times.reduce(0, +) / Double(times.count)
        
        let speeds = completedSprints.map { $0.maxSpeed }
        maxSpeed = speeds.max() ?? 0
        averageSpeed = speeds.reduce(0, +) / Double(speeds.count)
    }
    
    private func updateHeartRateMetrics() {
        guard !heartRateData.isEmpty else { return }
        
        let heartRates = heartRateData.map { $0.heartRate }
        maxHeartRate = heartRates.max() ?? 0
        averageHeartRate = heartRates.reduce(0, +) / heartRates.count
        
        // Set resting heart rate from first reading if not set
        if restingHeartRate == 0 {
            restingHeartRate = heartRates.first ?? 0
        }
    }
    
    private func updateHeartRateZones(_ heartRate: Int) {
        // Calculate zones based on max heart rate (220 - age, or use actual max)
        let estimatedMaxHR = 200 // Default, should be personalized
        
        let zone1Max = Int(Double(estimatedMaxHR) * 0.6)
        let zone2Max = Int(Double(estimatedMaxHR) * 0.7)
        let zone3Max = Int(Double(estimatedMaxHR) * 0.8)
        let zone4Max = Int(Double(estimatedMaxHR) * 0.9)
        
        switch heartRate {
        case 0..<zone1Max:
            heartRateZones.zone1Time += 1
        case zone1Max..<zone2Max:
            heartRateZones.zone2Time += 1
        case zone2Max..<zone3Max:
            heartRateZones.zone3Time += 1
        case zone3Max..<zone4Max:
            heartRateZones.zone4Time += 1
        default:
            heartRateZones.zone5Time += 1
        }
    }
    
    private func updateActualDistance() {
        // Calculate total distance from GPS data
        guard locationData.count >= 2 else { return }
        
        var totalDistance: Double = 0
        
        for i in 1..<locationData.count {
            let prev = locationData[i-1]
            let curr = locationData[i]
            
            let prevLocation = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let currLocation = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            
            let distance = currLocation.distance(from: prevLocation)
            totalDistance += distance * 1.09361 // Convert meters to yards
        }
        
        actualDistance = totalDistance
    }
    
    private func calculateHeartRateRecovery(for intervalNumber: Int) {
        guard let restPeriod = restPeriods.first(where: { $0.intervalNumber == intervalNumber }),
              let startTime = restPeriod.endTime else { return }
        
        // Find heart rate readings during the first minute of rest
        let recoveryReadings = heartRateData.filter { reading in
            reading.timestamp >= startTime && 
            reading.timestamp <= startTime.addingTimeInterval(60)
        }
        
        if let peakHR = recoveryReadings.first?.heartRate,
           let oneMinHR = recoveryReadings.last?.heartRate {
            let recovery = HeartRateRecoveryData(
                intervalNumber: intervalNumber,
                peakHeartRate: peakHR,
                oneMinuteHeartRate: oneMinHR,
                recoveryRate: Int(peakHR - oneMinHR)
            )
            heartRateRecovery.append(recovery)
        }
    }
    
    private func calculateFinalMetrics() {
        // Calculate fatigue index (performance decline over workout)
        if sprintData.count >= 2 {
            let firstHalf = sprintData.prefix(sprintData.count / 2)
            let secondHalf = sprintData.suffix(sprintData.count / 2)
            
            let firstHalfAvg = firstHalf.map { $0.totalTime }.reduce(0, +) / Double(firstHalf.count)
            let secondHalfAvg = secondHalf.map { $0.totalTime }.reduce(0, +) / Double(secondHalf.count)
            
            fatigueIndex = ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100
        }
        
        // Calculate consistency score (lower standard deviation = higher consistency)
        if sprintData.count >= 3 {
            let times = sprintData.map { $0.totalTime }
            let mean = times.reduce(0, +) / Double(times.count)
            let variance = times.map { pow($0 - mean, 2) }.reduce(0, +) / Double(times.count)
            let standardDeviation = sqrt(variance)
            
            // Convert to 0-100 scale (lower std dev = higher score)
            consistencyScore = max(0, 100 - (standardDeviation * 100))
        }
        
        // Calculate active duration (excluding rest periods)
        activeDuration = sprintData.map { $0.totalTime }.reduce(0, +)
        
        // Check for personal records
        checkPersonalRecords()
    }
    
    private func checkPersonalRecords() {
        // Check for various PRs
        if bestSprintTime > 0 {
            let pr = PersonalRecord(
                type: .bestSprintTime,
                value: bestSprintTime,
                date: Date(),
                description: "Best sprint time: \(String(format: "%.2f", bestSprintTime))s"
            )
            personalRecords.append(pr)
        }
        
        if maxSpeed > 0 {
            let pr = PersonalRecord(
                type: .maxSpeed,
                value: maxSpeed,
                date: Date(),
                description: "Max speed: \(String(format: "%.1f", maxSpeed)) mph"
            )
            personalRecords.append(pr)
        }
    }
    
    // MARK: - Data Export
    
    func exportSummary() -> WorkoutSummary {
        return WorkoutSummary(
            id: id,
            date: startTime,
            duration: totalDuration,
            workoutType: workoutType,
            intervalsCompleted: completedIntervals,
            totalIntervals: totalIntervals,
            bestTime: bestSprintTime,
            averageTime: averageSprintTime,
            maxSpeed: maxSpeed,
            averageSpeed: averageSpeed,
            maxHeartRate: maxHeartRate,
            averageHeartRate: averageHeartRate,
            caloriesBurned: caloriesBurned,
            totalDistance: actualDistance,
            personalRecords: personalRecords.count
        )
    }
    
    func exportDetailedData() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            print("❌ Failed to export workout data: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Data Models

struct SprintPerformance: Codable {
    let intervalNumber: Int
    let distance: Int
    let startTime: Date
    var endTime: Date?
    var totalTime: TimeInterval = 0
    var maxSpeed: Double = 0
    var averageSpeed: Double = 0
    var splits: [SplitTime] = []
}

struct SplitTime: Codable {
    let distance: Int // yards (10, 20, 30, 40)
    let time: TimeInterval
    let speed: Double // mph at this split
}

struct IntervalSplits: Codable {
    let intervalNumber: Int
    let splits: [SplitTime]
    let totalTime: TimeInterval
}

struct WatchHeartRateReading: Codable {
    let heartRate: Int
    let timestamp: Date
}

struct WatchRecoveryReading: Codable {
    let heartRate: Int
    let timestamp: Date
    let recoveryTime: TimeInterval
}

struct PaceReading: Codable {
    let pace: Double // minutes per mile
    let timestamp: Date
}

struct LocationReading: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double
}

struct GPSAccuracyReading: Codable {
    let accuracy: CLLocationAccuracy
    let timestamp: Date
}

struct ElevationReading: Codable {
    let elevation: Double
    let timestamp: Date
}

struct RestPeriod: Codable {
    let intervalNumber: Int
    let startTime: Date
    var endTime: Date?
    let startHeartRate: Int
    var endHeartRate: Int = 0
}

struct HeartRateZones: Codable {
    var zone1Time: Int = 0 // Recovery (50-60% max HR)
    var zone2Time: Int = 0 // Aerobic (60-70% max HR)
    var zone3Time: Int = 0 // Aerobic (70-80% max HR)
    var zone4Time: Int = 0 // Anaerobic (80-90% max HR)
    var zone5Time: Int = 0 // Neuromuscular (90-100% max HR)
}

struct HeartRateRecoveryData: Codable {
    let intervalNumber: Int
    let peakHeartRate: Int
    let oneMinuteHeartRate: Int
    let recoveryRate: Int // BPM recovered in 1 minute
}

struct PersonalRecord: Codable {
    let type: PRType
    let value: Double
    let date: Date
    let description: String
}

enum PRType: String, Codable {
    case bestSprintTime = "best_sprint_time"
    case maxSpeed = "max_speed"
    case mostIntervals = "most_intervals"
    case longestWorkout = "longest_workout"
    case bestConsistency = "best_consistency"
}

enum WatchWorkoutType: String, Codable {
    case speed = "speed"
    case endurance = "endurance"
    case power = "power"
    case mixed = "mixed"
    case custom = "custom"
}

struct WorkoutSummary: Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let workoutType: WatchWorkoutType
    let intervalsCompleted: Int
    let totalIntervals: Int
    let bestTime: TimeInterval
    let averageTime: TimeInterval
    let maxSpeed: Double
    let averageSpeed: Double
    let maxHeartRate: Int
    let averageHeartRate: Int
    let caloriesBurned: Int
    let totalDistance: Double
    let personalRecords: Int
}
