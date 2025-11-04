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
    
    lazy var persistentContainer: NSPersistentContainer? = {
        // TODO: Create WatchWorkoutDataModel.xcdatamodeld
        // For now, disable CoreData to prevent crashes
        print("⚠️ CoreData disabled - WatchWorkoutDataModel not found")
        isLoading = false
        return nil
    }()
    
    private var context: NSManagedObjectContext? {
        return persistentContainer?.viewContext
    }
    
    // MARK: - Sync Queue Management
    private var syncQueue: [Any] = [] // TODO: Use WatchWorkoutData when available
    private let maxSyncQueueSize = 50
    
    private init() {
        setupNotifications()
        loadSyncQueue()
    }
    
    // MARK: - Workout Data Management
    
    func saveWorkout(_ workoutData: Any) {
        print("💾 Saving workout to local storage...")
        
        // Check if CoreData is available
        guard let context = context else {
            print("⚠️ CoreData not available - adding to sync queue only")
            addToSyncQueue(workoutData)
            isLoading = false
            return
        }
        
        isLoading = true
        
        context.perform { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create Core Data entity
                let workoutEntity = NSEntityDescription.entity(forEntityName: "WorkoutEntity", in: context)!
                let workout = NSManagedObject(entity: workoutEntity, insertInto: context)
                
                // Map workout data to Core Data
                self.mapWorkoutDataToEntity(workoutData, entity: workout)
                
                // Save to Core Data
                try context.save()
                
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
    
    func loadWorkouts(limit: Int = 20) -> [Any] {
        print("📖 Loading workouts from local storage...")
        
        guard let context = context else {
            print("⚠️ CoreData not available - returning empty workouts")
            return []
        }
        
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
    
    func loadWorkout(id: UUID) -> Any? {
        guard let context = context else {
            print("⚠️ CoreData not available - cannot load workout")
            return nil
        }
        
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            return entities.first.flatMap { self.mapEntityToWorkoutData($0) }
        } catch {
            print("❌ Failed to load workout: \(error)")
            return nil
        }
    }
    
    func deleteWorkout(id: UUID) {
        print("🗑️ Deleting workout: \(id)")
        
        guard let context = context else {
            print("⚠️ CoreData not available - cannot delete workout")
            return
        }
        
        context.perform { [weak self] in
            guard let self = self, let context = self.context else { return }
            
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                entities.forEach { context.delete($0) }
                
                try context.save()
                
                DispatchQueue.main.async {
                    self.updateStorageUsage()
                    print("✅ Workout deleted successfully")
                }
                
            } catch {
                print("❌ Failed to delete workout: \(error)")
            }
        }
    }
    
    func deleteOldWorkouts(olderThan days: Int) {
        print("🧹 Cleaning up workouts older than \(days) days...")
        
        guard let context = context else {
            print("⚠️ CoreData not available - cannot delete old workouts")
            return
        }
        
        context.perform { [weak self] in
            guard let self = self, let context = self.context else { return }
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
            request.predicate = NSPredicate(format: "startTime < %@", cutoffDate as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                let count = entities.count
                
                entities.forEach { context.delete($0) }
                try context.save()
                
                DispatchQueue.main.async {
                    self.updateStorageUsage()
                    print("✅ Deleted \(count) old workouts")
                }
                
            } catch {
                print("❌ Failed to delete old workouts: \(error)")
            }
        }
    }
    
    // MARK: - Sync Queue Management
    
    private func addToSyncQueue(_ workoutData: Any) {
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
    
    func getSyncQueue() -> [Any] {
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
        // TODO: Implement when WatchWorkoutData type is available
        // For now, clear entire queue since we can't access individual workout IDs
        print("⚠️ Selective workout removal not available - WatchWorkoutData required")
        syncQueue.removeAll()
        DispatchQueue.main.async { [weak self] in
            self?.syncQueueCount = 0
        }
        saveSyncQueue()
    }
    
    private func loadSyncQueue() {
        // TODO: Implement when WatchWorkoutData type is available
        // For now, initialize empty queue
        print("⚠️ Sync queue loading not available - WatchWorkoutData required")
        syncQueue = []
        DispatchQueue.main.async { [weak self] in
            self?.syncQueueCount = 0
        }
    }
    
    private func saveSyncQueue() {
        // TODO: Implement when WatchWorkoutData type is available
        // For now, do nothing since we can't encode [Any]
        print("⚠️ Sync queue saving not available - WatchWorkoutData required")
    }
    
    // MARK: - Sync Operations
    
    private func attemptSync() {
        // TODO: Implement when WatchWorkoutSyncManager is available
        // For now, do nothing since sync manager is not accessible
        print("⚠️ Sync attempt not available - WatchWorkoutSyncManager required")
    }
    
    private func syncWorkout(_ workout: Any) {
        // TODO: Implement when WatchWorkoutData and WatchWorkoutSyncManager are available
        // For now, do nothing since types are not accessible
        print("⚠️ Workout sync not available - WatchWorkoutData and WatchWorkoutSyncManager required")
    }
    
    // MARK: - Analytics and Queries
    
    func getWorkoutStats(for period: StatsPeriod) -> WorkoutStats {
        guard let context = context else {
            print("⚠️ CoreData not available - returning empty stats")
            return WorkoutStats()
        }
        
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "WorkoutEntity")
        
        // Set date predicate based on period
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .year:
            startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .allTime:
            startDate = Date.distantPast
        }
        
        request.predicate = NSPredicate(format: "startTime >= %@", startDate as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            let workouts = entities.compactMap { self.mapEntityToWorkoutData($0) }
            
            return calculateStats(from: workouts)
        } catch {
            print("❌ Failed to fetch workout stats: \(error)")
            return WorkoutStats()
        }
    }
    
    func getPersonalRecords() -> [Any] {
        // TODO: Implement when PersonalRecord type is available
        // For now, return empty array since types are not accessible
        print("⚠️ PersonalRecord type not available - returning empty records")
        return []
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
    
    private func mapWorkoutDataToEntity(_ workoutData: Any, entity: NSManagedObject) {
        // TODO: Implement when CoreData model is available
        // For now, do nothing since CoreData is disabled
        print("⚠️ CoreData entity mapping not available - WatchWorkoutDataModel required")
    }
    
    private func mapEntityToWorkoutData(_ entity: NSManagedObject) -> Any? {
        // TODO: Implement when CoreData model is available
        // For now, return nil since CoreData is disabled
        print("⚠️ CoreData entity mapping not available - WatchWorkoutDataModel required")
        return nil
    }
    
    private func setupNotifications() {
        // TODO: Setup CoreData notifications when model is available
        print("⚠️ CoreData notifications disabled - WatchWorkoutDataModel required")
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
    
    private func calculateStats(from workouts: [Any]) -> WorkoutStats {
        // TODO: Implement when WatchWorkoutData type is available
        // For now, return empty stats since we can't access workout properties
        print("⚠️ Workout stats calculation not available - WatchWorkoutData required")
        return WorkoutStats()
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

// TODO: Add WatchWorkoutSyncManager extension when type is available
