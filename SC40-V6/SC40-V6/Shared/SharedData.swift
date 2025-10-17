import Foundation

// MARK: - Shared Constants
struct SharedConstants {
    static let appGroup = "group.com.sprintcoach.sc40"
    static let watchAppBundle = "com.sprintcoach.sc40.watchapp"
    static let siriExtensionBundle = "com.sprintcoach.sc40.siriextension"
    static let notificationExtensionBundle = "com.sprintcoach.sc40.notificationextension"
}

// MARK: - Shared User Defaults
class SharedUserDefaults {
    static let suite = UserDefaults(suiteName: SharedConstants.appGroup)
    
    static func saveWorkoutData(_ data: [String: Any]) {
        suite?.set(data, forKey: "lastWorkout")
        suite?.synchronize()
    }
    
    static func getWorkoutData() -> [String: Any]? {
        return suite?.dictionary(forKey: "lastWorkout")
    }
}

// MARK: - Shared File Manager
class SharedFileManager {
    static let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.appGroup)
    
    static func saveData(_ data: Data, filename: String) throws {
        guard let containerURL = sharedContainerURL else {
            throw NSError(domain: "SharedFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Shared container not available"])
        }
        
        let fileURL = containerURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
    }
    
    static func loadData(filename: String) throws -> Data {
        guard let containerURL = sharedContainerURL else {
            throw NSError(domain: "SharedFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Shared container not available"])
        }
        
        let fileURL = containerURL.appendingPathComponent(filename)
        return try Data(contentsOf: fileURL)
    }
}
