import Foundation
import Combine

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

// MARK: - Workout Data Persistence Manager
/// Manages workout data persistence, history, and analytics for both watch apps
class WorkoutDataManager: ObservableObject {
    static let shared = WorkoutDataManager()
    
    @Published var workoutHistory: [CompletedWorkout] = []
    @Published var analytics: WorkoutAnalytics = WorkoutAnalytics()
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "SC40_WorkoutHistory"
    private let analyticsKey = "SC40_WorkoutAnalytics"
    
    private init() {
        loadWorkoutHistory()
        loadAnalytics()
    }
    
    // MARK: - Save Workout Data
    
    func saveWorkout(_ workout: CompletedWorkout) {
        workoutHistory.append(workout)
        updateAnalytics(with: workout)
        
        saveWorkoutHistory()
        saveAnalytics()
        
        // Send to phone app
        sendWorkoutToPhone(workout)
        
        print("💾 Workout saved: \(workout.type) - \(workout.completedReps.count) reps")
    }
    
    func saveSprintWorkout(
        distance: Int,
        sets: Int,
        sprintTimes: [TimeInterval],
        avgTime: TimeInterval,
        totalTime: TimeInterval
    ) {
        let completedReps = sprintTimes.enumerated().map { index, time in
            CompletedRep(
                repNumber: index + 1,
                distance: distance,
                time: time,
                heartRate: nil,
                timestamp: Date()
            )
        }
        
        let workout = CompletedWorkout(
            id: UUID(),
            type: .sprintTimer,
            date: Date(),
            duration: totalTime,
            completedReps: completedReps,
            averageTime: avgTime,
            bestTime: sprintTimes.min() ?? 0,
            totalDistance: distance * sets,
            heartRateData: [],
            notes: "Sprint Timer Pro - \(distance)yd x\(sets) sets"
        )
        
        saveWorkout(workout)
    }
    
    func saveMainProgramWorkout(
        session: TrainingSession,
        completedReps: [CompletedRep],
        duration: TimeInterval
    ) {
        let workout = CompletedWorkout(
            id: UUID(),
            type: .mainProgram,
            date: Date(),
            duration: duration,
            completedReps: completedReps,
            averageTime: completedReps.isEmpty ? 0 : completedReps.map { $0.time }.reduce(0, +) / Double(completedReps.count),
            bestTime: completedReps.map { $0.time }.min() ?? 0,
            totalDistance: completedReps.map { $0.distance }.reduce(0, +),
            heartRateData: [],
            notes: "Week \(session.week), Day \(session.day) - \(session.type)"
        )
        
        saveWorkout(workout)
    }
    
    // MARK: - Analytics
    
    private func updateAnalytics(with workout: CompletedWorkout) {
        analytics.totalWorkouts += 1
        analytics.totalTime += workout.duration
        analytics.totalDistance += workout.totalDistance
        
        if workout.bestTime > 0 {
            if analytics.personalBest == 0 || workout.bestTime < analytics.personalBest {
                analytics.personalBest = workout.bestTime
            }
        }
        
        // Update weekly stats
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: workout.date)
        let year = calendar.component(.year, from: workout.date)
        let weekKey = "\(year)-W\(weekOfYear)"
        
        if analytics.weeklyStats[weekKey] == nil {
            analytics.weeklyStats[weekKey] = WeeklyStats()
        }
        
        analytics.weeklyStats[weekKey]?.workouts += 1
        analytics.weeklyStats[weekKey]?.totalTime += workout.duration
        analytics.weeklyStats[weekKey]?.totalDistance += workout.totalDistance
    }
    
    // MARK: - Data Persistence
    
    private func saveWorkoutHistory() {
        if let encoded = try? JSONEncoder().encode(workoutHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadWorkoutHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([CompletedWorkout].self, from: data) {
            workoutHistory = decoded
        }
    }
    
    private func saveAnalytics() {
        if let encoded = try? JSONEncoder().encode(analytics) {
            userDefaults.set(encoded, forKey: analyticsKey)
        }
    }
    
    private func loadAnalytics() {
        if let data = userDefaults.data(forKey: analyticsKey),
           let decoded = try? JSONDecoder().decode(WorkoutAnalytics.self, from: data) {
            analytics = decoded
        }
    }
    
    // MARK: - Phone Sync
    
    private func sendWorkoutToPhone(_ workout: CompletedWorkout) {
        #if canImport(WatchConnectivity)
        
        print("🔄 SYNC: Attempting to send workout to phone...")
        print("📊 SYNC: Workout ID: \(workout.id)")
        print("📊 SYNC: Type: \(workout.type.rawValue)")
        print("📊 SYNC: Reps: \(workout.completedReps.count)")
        print("📊 SYNC: Duration: \(String(format: "%.1f", workout.duration))s")
        
        guard WCSession.default.isReachable else {
            print("⚠️ SYNC FAILED: Phone not reachable")
            print("📱 SYNC STATUS: Supported=\(WCSession.isSupported()), Activated=\(WCSession.default.activationState == .activated), Reachable=\(WCSession.default.isReachable)")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(workout)
            let message = ["completedWorkout": data]
            
            print("📤 SYNC: Sending \(data.count) bytes to phone...")
            
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("✅ SYNC SUCCESS: Phone acknowledged workout data")
                print("📱 SYNC RESPONSE: \(response)")
            }, errorHandler: { error in
                print("❌ SYNC FAILED: \(error.localizedDescription)")
                print("🔍 SYNC ERROR: \(error)")
            })
            
            print("📱 SYNC: Workout data transmission initiated")
        } catch {
            print("❌ SYNC ENCODE ERROR: \(error.localizedDescription)")
            print("🔍 SYNC ENCODE DETAILS: \(error)")
        }
        #endif
    }
    
    // MARK: - History Queries
    
    func getRecentWorkouts(limit: Int = 10) -> [CompletedWorkout] {
        return Array(workoutHistory.suffix(limit).reversed())
    }
    
    func getWorkoutsForWeek(_ weekOffset: Int = 0) -> [CompletedWorkout] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        return workoutHistory.filter { workout in
            workout.date >= weekStart && workout.date < weekEnd
        }
    }
    
    func getBestTimes(for distance: Int, limit: Int = 5) -> [CompletedRep] {
        let repsForDistance = workoutHistory.flatMap { workout in
            workout.completedReps.filter { $0.distance == distance }
        }
        
        return Array(repsForDistance.sorted { $0.time < $1.time }.prefix(limit))
    }
}

// MARK: - Data Models

struct CompletedWorkout: Codable, Identifiable {
    let id: UUID
    let type: WorkoutType
    let date: Date
    let duration: TimeInterval
    let completedReps: [CompletedRep]
    let averageTime: TimeInterval
    let bestTime: TimeInterval
    let totalDistance: Int
    let heartRateData: [HeartRatePoint]
    let notes: String?
}

struct CompletedRep: Codable, Identifiable {
    let id: UUID
    let repNumber: Int
    let distance: Int
    let time: TimeInterval
    let heartRate: Int?
    let timestamp: Date
    
    init(repNumber: Int, distance: Int, time: TimeInterval, heartRate: Int?, timestamp: Date) {
        self.id = UUID()
        self.repNumber = repNumber
        self.distance = distance
        self.time = time
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}

struct HeartRatePoint: Codable {
    let timestamp: Date
    let heartRate: Int
}

enum WorkoutType: String, Codable {
    case sprintTimer = "Sprint Timer Pro"
    case mainProgram = "Main Program"
}

struct WorkoutAnalytics: Codable {
    var totalWorkouts: Int = 0
    var totalTime: TimeInterval = 0
    var totalDistance: Int = 0
    var personalBest: TimeInterval = 0
    var weeklyStats: [String: WeeklyStats] = [:]
    var lastUpdated: Date = Date()
}

struct WeeklyStats: Codable {
    var workouts: Int = 0
    var totalTime: TimeInterval = 0
    var totalDistance: Int = 0
}
