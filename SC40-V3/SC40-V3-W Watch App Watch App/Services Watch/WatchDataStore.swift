import Foundation
import CoreData
import Combine

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Offline data persistence system for Apple Watch
/// Handles Core Data integration, workout session caching, and sync queue management
class WatchDataStore: ObservableObject {
    static let shared = WatchDataStore()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var syncQueueCount = 0
    @Published var lastSyncDate: Date?
    @Published var storageUsed: Int64 = 0 // bytes
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WatchWorkoutDataModel")
        
        // Configure for watch app
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("WatchWorkouts.sqlite")
        
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                print("❌ Core Data error: \(error)")
            } else {
                print("✅ Core Data loaded successfully")
                self?.updateStorageUsage()
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Sync Queue Management
    private var syncQueue: [WatchWorkoutData] = []
    private let maxSyncQueueSize = 50
    
    private init() {
        setupNotifications()
        loadSyncQueue()
    }
    
    // MARK: - Workout Data Management
    
    func saveWorkout(_ workoutData: WatchWorkoutData) {
        print("💾 Saving workout to local storage...")
        
        isLoading = true
        
        context.perform { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create Core Data entity
                let workoutEntity = NSEntityDescription.entity(forEntityName: "WorkoutEntity", in: self.context)!
                let workout = NSManagedObject(entity: workoutEntity, insertInto: self.context)
                
                // Map workout data to Core Data
                self.mapWorkoutDataToEntity(workoutData, entity: workout)
                
                // Save to Core Data
                try self.context.save()
                
                // Add to sync queue
                self.addToSyncQueue(workoutData)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.updateStorageUsage()
                    print("✅ Workout saved successfully")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ Failed to save workout: \(error)")
                }
            }
        }
    }
    
    func loadWorkouts(limit: Int = 20) -> [WatchWorkoutData] {
        print("📖 Loading workouts from local storage...")
        
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            let workouts = entities.compactMap { mapEntityToWorkoutData($0) }
            print("✅ Loaded \(workouts.count) workouts")
            return workouts
        } catch {
            print("❌ Failed to load workouts: \(error)")
            return []
        }
    }
    
    func loadWorkout(id: UUID) -> WatchWorkoutData? {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            return entities.first.flatMap { mapEntityToWorkoutData($0) }
        } catch {
            print("❌ Failed to load workout \(id): \(error)")
            return nil
        }
    }
    
    func deleteWorkout(id: UUID) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let entities = try self.context.fetch(request)
                for entity in entities {
                    self.context.delete(entity)
                }
                try self.context.save()
                
                DispatchQueue.main.async {
                    self.updateStorageUsage()
                    print("✅ Workout deleted successfully")
                }
            } catch {
                print("❌ Failed to delete workout: \(error)")
            }
        }
    }
    
    func deleteOldWorkouts(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
            request.predicate = NSPredicate(format: "startTime < %@", cutoffDate as CVarArg)
            
            do {
                let entities = try self.context.fetch(request)
                for entity in entities {
                    self.context.delete(entity)
                }
                try self.context.save()
                
                DispatchQueue.main.async {
                    self.updateStorageUsage()
                    print("✅ Deleted \(entities.count) old workouts")
                }
            } catch {
                print("❌ Failed to delete old workouts: \(error)")
            }
        }
    }
    
    // MARK: - Sync Queue Management
    
    private func addToSyncQueue(_ workoutData: WatchWorkoutData) {
        syncQueue.append(workoutData)
        
        // Limit queue size
        if syncQueue.count > maxSyncQueueSize {
            syncQueue.removeFirst(syncQueue.count - maxSyncQueueSize)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.syncQueueCount = self?.syncQueue.count ?? 0
        }
        
        saveSyncQueue()
        
        // Attempt immediate sync if possible
        attemptSync()
    }
    
    func getSyncQueue() -> [WatchWorkoutData] {
        return syncQueue
    }
    
    func clearSyncQueue() {
        syncQueue.removeAll()
        DispatchQueue.main.async { [weak self] in
            self?.syncQueueCount = 0
        }
        saveSyncQueue()
    }
    
    func removeSyncedWorkout(_ workoutId: UUID) {
        syncQueue.removeAll { $0.id == workoutId }
        DispatchQueue.main.async { [weak self] in
            self?.syncQueueCount = self?.syncQueue.count ?? 0
        }
        saveSyncQueue()
    }
    
    private func loadSyncQueue() {
        guard let data = UserDefaults.standard.data(forKey: "WatchSyncQueue"),
              let queue = try? JSONDecoder().decode([WatchWorkoutData].self, from: data) else {
            return
        }
        
        syncQueue = queue
        DispatchQueue.main.async { [weak self] in
            self?.syncQueueCount = queue.count
        }
    }
    
    private func saveSyncQueue() {
        guard let data = try? JSONEncoder().encode(syncQueue) else { return }
        UserDefaults.standard.set(data, forKey: "WatchSyncQueue")
    }
    
    // MARK: - Sync Operations
    
    private func attemptSync() {
        guard !syncQueue.isEmpty else { return }
        
        // Check if sync manager is available and phone is connected
        let syncManager = WatchWorkoutSyncManager.shared
        guard syncManager.isPhoneConnected else {
            print("📱 Phone not connected - sync queued")
            return
        }
        
        print("🔄 Attempting to sync \(syncQueue.count) workouts...")
        
        // Sync workouts one by one
        for workout in syncQueue {
            syncWorkout(workout)
        }
    }
    
    private func syncWorkout(_ workout: WatchWorkoutData) {
        // Convert to sync format and send
        guard let data = workout.exportDetailedData() else {
            print("❌ Failed to export workout data for sync")
            return
        }
        
        // Send via sync manager
        let syncManager = WatchWorkoutSyncManager.shared
        syncManager.sendWorkoutData(data, workoutId: workout.id) { [weak self] success in
            if success {
                self?.removeSyncedWorkout(workout.id)
                DispatchQueue.main.async {
                    self?.lastSyncDate = Date()
                }
                print("✅ Workout \(workout.id) synced successfully")
            } else {
                print("❌ Failed to sync workout \(workout.id)")
            }
        }
    }
    
    // MARK: - Analytics and Queries
    
    func getWorkoutStats(for period: StatsPeriod) -> WorkoutStats {
        let startDate = period.startDate
        let endDate = Date()
        
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as CVarArg, endDate as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            let workouts = entities.compactMap { mapEntityToWorkoutData($0) }
            
            return calculateStats(from: workouts)
        } catch {
            print("❌ Failed to load workout stats: \(error)")
            return WorkoutStats()
        }
    }
    
    func getPersonalRecords() -> [PersonalRecord] {
        let workouts = loadWorkouts(limit: 100)
        var records: [PersonalRecord] = []
        
        // Find best times
        if let bestTime = workouts.compactMap({ $0.bestSprintTime }).filter({ $0 > 0 }).min() {
            records.append(PersonalRecord(
                type: .bestSprintTime,
                value: bestTime,
                date: Date(),
                description: "Best sprint time: \(String(format: "%.2f", bestTime))s"
            ))
        }
        
        // Find max speed
        if let maxSpeed = workouts.compactMap({ $0.maxSpeed }).max() {
            records.append(PersonalRecord(
                type: .maxSpeed,
                value: maxSpeed,
                date: Date(),
                description: "Max speed: \(String(format: "%.1f", maxSpeed)) mph"
            ))
        }
        
        return records
    }
    
    // MARK: - Storage Management
    
    private func updateStorageUsage() {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("WatchWorkouts.sqlite")
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            DispatchQueue.main.async { [weak self] in
                self?.storageUsed = fileSize
            }
        } catch {
            print("⚠️ Could not determine storage usage: \(error)")
        }
    }
    
    func getStorageInfo() -> StorageInfo {
        let totalSpace = getTotalDiskSpace()
        let freeSpace = getFreeDiskSpace()
        
        return StorageInfo(
            usedByApp: storageUsed,
            totalSpace: totalSpace,
            freeSpace: freeSpace,
            syncQueueSize: Int64(syncQueue.count)
        )
    }
    
    // MARK: - Data Mapping
    
    private func mapWorkoutDataToEntity(_ workoutData: WatchWorkoutData, entity: NSManagedObject) {
        entity.setValue(workoutData.id, forKey: "id")
        entity.setValue(workoutData.startTime, forKey: "startTime")
        entity.setValue(workoutData.endTime, forKey: "endTime")
        entity.setValue(workoutData.workoutType.rawValue, forKey: "workoutType")
        entity.setValue(workoutData.sessionName, forKey: "sessionName")
        entity.setValue(workoutData.totalIntervals, forKey: "totalIntervals")
        entity.setValue(workoutData.completedIntervals, forKey: "completedIntervals")
        entity.setValue(workoutData.totalDuration, forKey: "totalDuration")
        entity.setValue(workoutData.bestSprintTime, forKey: "bestSprintTime")
        entity.setValue(workoutData.averageSprintTime, forKey: "averageSprintTime")
        entity.setValue(workoutData.maxSpeed, forKey: "maxSpeed")
        entity.setValue(workoutData.averageSpeed, forKey: "averageSpeed")
        entity.setValue(workoutData.maxHeartRate, forKey: "maxHeartRate")
        entity.setValue(workoutData.averageHeartRate, forKey: "averageHeartRate")
        entity.setValue(workoutData.caloriesBurned, forKey: "caloriesBurned")
        entity.setValue(workoutData.actualDistance, forKey: "actualDistance")
        
        // Store complex data as JSON
        if let sprintData = try? JSONEncoder().encode(workoutData.sprintData) {
            entity.setValue(sprintData, forKey: "sprintDataJSON")
        }
        
        if let heartRateData = try? JSONEncoder().encode(workoutData.heartRateData) {
            entity.setValue(heartRateData, forKey: "heartRateDataJSON")
        }
        
        if let splitTimes = try? JSONEncoder().encode(workoutData.splitTimes) {
            entity.setValue(splitTimes, forKey: "splitTimesJSON")
        }
    }
    
    private func mapEntityToWorkoutData(_ entity: NSManagedObject) -> WatchWorkoutData? {
        guard let _ = entity.value(forKey: "id") as? UUID,
              let _ = entity.value(forKey: "startTime") as? Date,
              let workoutTypeString = entity.value(forKey: "workoutType") as? String,
              let workoutType = WatchWorkoutType(rawValue: workoutTypeString),
              let sessionName = entity.value(forKey: "sessionName") as? String,
              let totalIntervals = entity.value(forKey: "totalIntervals") as? Int else {
            return nil
        }
        
        let workoutData = WatchWorkoutData(workoutType: workoutType, sessionName: sessionName, totalIntervals: totalIntervals)
        
        // Map basic properties
        workoutData.endTime = entity.value(forKey: "endTime") as? Date
        workoutData.completedIntervals = entity.value(forKey: "completedIntervals") as? Int ?? 0
        workoutData.totalDuration = entity.value(forKey: "totalDuration") as? TimeInterval ?? 0
        workoutData.bestSprintTime = entity.value(forKey: "bestSprintTime") as? TimeInterval ?? 0
        workoutData.averageSprintTime = entity.value(forKey: "averageSprintTime") as? TimeInterval ?? 0
        workoutData.maxSpeed = entity.value(forKey: "maxSpeed") as? Double ?? 0
        workoutData.averageSpeed = entity.value(forKey: "averageSpeed") as? Double ?? 0
        workoutData.maxHeartRate = entity.value(forKey: "maxHeartRate") as? Int ?? 0
        workoutData.averageHeartRate = entity.value(forKey: "averageHeartRate") as? Int ?? 0
        workoutData.caloriesBurned = entity.value(forKey: "caloriesBurned") as? Int ?? 0
        workoutData.actualDistance = entity.value(forKey: "actualDistance") as? Double ?? 0
        
        // Decode complex data from JSON
        if let sprintDataJSON = entity.value(forKey: "sprintDataJSON") as? Data,
           let sprintData = try? JSONDecoder().decode([SprintPerformance].self, from: sprintDataJSON) {
            workoutData.sprintData = sprintData
        }
        
        if let heartRateDataJSON = entity.value(forKey: "heartRateDataJSON") as? Data,
           let heartRateData = try? JSONDecoder().decode([WatchHeartRateReading].self, from: heartRateDataJSON) {
            workoutData.heartRateData = heartRateData
        }
        
        if let splitTimesJSON = entity.value(forKey: "splitTimesJSON") as? Data,
           let splitTimes = try? JSONDecoder().decode([SplitTime].self, from: splitTimesJSON) {
            workoutData.splitTimes = splitTimes
        }
        
        return workoutData
    }
    
    // MARK: - Helper Methods
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.updateStorageUsage()
        }
    }
    
    private func getTotalDiskSpace() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return systemAttributes[.systemSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func getFreeDiskSpace() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return systemAttributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStats(from workouts: [WatchWorkoutData]) -> WorkoutStats {
        guard !workouts.isEmpty else {
            return WorkoutStats()
        }
        
        let totalWorkouts = workouts.count
        let totalTime = workouts.reduce(into: 0) { $0 += $1.totalDuration }
        let totalDistance = workouts.reduce(into: 0) { $0 += $1.actualDistance }
        let totalCalories = workouts.reduce(into: 0) { $0 += $1.caloriesBurned }
        
        // Calculate best times and max speeds
        let bestTimes = workouts.compactMap { $0.bestSprintTime }.filter { $0 > 0 }
        let maxSpeeds = workouts.compactMap { $0.maxSpeed }.filter { $0 > 0 }
        
        return WorkoutStats(
            totalWorkouts: totalWorkouts,
            totalTime: totalTime,
            totalDistance: totalDistance,
            totalCalories: totalCalories,
            bestTime: bestTimes.min() ?? 0,
            maxSpeed: maxSpeeds.max() ?? 0,
            averageWorkoutTime: totalTime / Double(totalWorkouts)
        )
    }
}

// MARK: - Supporting Data Models

enum StatsPeriod {
    case week
    case month
    case year
    case allTime
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            return Date.distantPast
        }
    }
}

struct WorkoutStats {
    let totalWorkouts: Int
    let totalTime: TimeInterval
    let totalDistance: Double
    let totalCalories: Int
    let bestTime: TimeInterval
    let maxSpeed: Double
    let averageWorkoutTime: TimeInterval
    
    init() {
        self.totalWorkouts = 0
        self.totalTime = 0
        self.totalDistance = 0
        self.totalCalories = 0
        self.bestTime = 0
        self.maxSpeed = 0
        self.averageWorkoutTime = 0
    }
    
    init(totalWorkouts: Int, totalTime: TimeInterval, totalDistance: Double, totalCalories: Int, bestTime: TimeInterval, maxSpeed: Double, averageWorkoutTime: TimeInterval) {
        self.totalWorkouts = totalWorkouts
        self.totalTime = totalTime
        self.totalDistance = totalDistance
        self.totalCalories = totalCalories
        self.bestTime = bestTime
        self.maxSpeed = maxSpeed
        self.averageWorkoutTime = averageWorkoutTime
    }
}

struct StorageInfo {
    let usedByApp: Int64
    let totalSpace: Int64
    let freeSpace: Int64
    let syncQueueSize: Int64
    
    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedByApp) / Double(totalSpace) * 100
    }
    
    var freePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(freeSpace) / Double(totalSpace) * 100
    }
}

// MARK: - WatchWorkoutSyncManager Extension

extension WatchWorkoutSyncManager {
    func sendWorkoutData(_ data: Data, workoutId: UUID, completion: @escaping (Bool) -> Void) {
        // Implementation would send data via WatchConnectivity
        // This is a placeholder for the actual sync implementation
        
        #if canImport(WatchConnectivity)
        
        guard WCSession.default.isReachable else {
            completion(false)
            return
        }
        
        let message = [
            "workoutData": data,
            "workoutId": workoutId.uuidString
        ] as [String: Any]
        
        WCSession.default.sendMessage(message, replyHandler: { response in
            completion(true)
        }, errorHandler: { error in
            print("❌ Sync error: \(error)")
            completion(false)
        })
        #else
        completion(false)
        #endif
    }
}
