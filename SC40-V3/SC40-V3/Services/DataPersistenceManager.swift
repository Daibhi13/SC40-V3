import Foundation
import Combine
import os.log

/// Manages data persistence and handles common file system errors
class DataPersistenceManager: ObservableObject {
    static let shared = DataPersistenceManager()
    
    private let logger = Logger(subsystem: "com.sc40.app", category: "DataPersistence")
    
    @Published var isInitialized = false
    @Published var hasDataDirectory = false
    @Published var applicationContextAvailable = false
    
    private init() {
        initializeDataPersistence()
    }
    
    // MARK: - Initialization
    
    private func initializeDataPersistence() {
        logger.info("🗂️ Initializing data persistence manager")
        
        // Create necessary directories
        createRequiredDirectories()
        
        // Initialize application context
        initializeApplicationContext()
        
        // Verify data integrity
        verifyDataIntegrity()
        
        DispatchQueue.main.async {
            self.isInitialized = true
        }
        logger.info("✅ Data persistence manager initialized")
    }
    
    // MARK: - Directory Management
    
    private func createRequiredDirectories() {
        let fileManager = FileManager.default
        
        // Get documents directory
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("❌ Could not access documents directory")
            return
        }
        
        // Create app-specific directories
        let appDataURL = documentsURL.appendingPathComponent("SC40Data")
        let cacheURL = documentsURL.appendingPathComponent("SC40Cache")
        let logsURL = documentsURL.appendingPathComponent("SC40Logs")
        
        let directories = [appDataURL, cacheURL, logsURL]
        
        for directory in directories {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                logger.info("📁 Created directory: \(directory.lastPathComponent)")
            } catch {
                logger.error("❌ Failed to create directory \(directory.lastPathComponent): \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.hasDataDirectory = true
        }
    }
    
    // MARK: - Application Context Management
    
    private func initializeApplicationContext() {
        logger.info("🔄 Initializing application context")
        
        // Create default application context data
        let defaultContext: [String: Any] = [
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
            "installDate": Date(),
            "lastLaunch": Date(),
            "onboardingCompleted": false,
            "userProfileExists": false,
            "trainingDataSynced": false
        ]
        
        // Save to UserDefaults
        for (key, value) in defaultContext {
            if UserDefaults.standard.object(forKey: "SC40_\(key)") == nil {
                UserDefaults.standard.set(value, forKey: "SC40_\(key)")
                logger.info("📝 Set default context: SC40_\(key)")
            }
        }
        
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.applicationContextAvailable = true
        }
        
        logger.info("✅ Application context initialized")
    }
    
    // MARK: - Data Integrity
    
    private func verifyDataIntegrity() {
        logger.info("🔍 Verifying data integrity")
        
        // Check for corrupted files and clean up
        cleanupCorruptedFiles()
        
        // Validate critical data structures
        validateCriticalData()
        
        logger.info("✅ Data integrity verification completed")
    }
    
    private func cleanupCorruptedFiles() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let cacheURL = documentsURL.appendingPathComponent("SC40Cache")
        
        // Clear cache directory to resolve file access issues
        do {
            if fileManager.fileExists(atPath: cacheURL.path) {
                try fileManager.removeItem(at: cacheURL)
                try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
                logger.info("🧹 Cleared and recreated cache directory")
            }
        } catch {
            logger.error("❌ Failed to cleanup cache: \(error)")
        }
    }
    
    private func validateCriticalData() {
        // Validate UserDefaults integrity
        let criticalKeys = ["onboardingCompleted", "userLevel", "trainingFrequency"]
        
        for key in criticalKeys {
            if UserDefaults.standard.object(forKey: key) == nil {
                // Set safe defaults
                switch key {
                case "onboardingCompleted":
                    UserDefaults.standard.set(false, forKey: key)
                case "userLevel":
                    UserDefaults.standard.set("Beginner", forKey: key)
                case "trainingFrequency":
                    UserDefaults.standard.set(1, forKey: key)
                default:
                    break
                }
                logger.info("🔧 Set default value for missing key: \(key)")
            }
        }
        
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Error Recovery
    
    func handleFileSystemError(_ error: Error) {
        logger.error("🚨 File system error: \(error)")
        
        // Attempt recovery
        if error.localizedDescription.contains("No such file or directory") {
            logger.info("🔄 Attempting to recover from missing file error")
            createRequiredDirectories()
            initializeApplicationContext()
        }
    }
    
    func invalidateCache() {
        logger.info("🗑️ Invalidating cache due to errors")
        cleanupCorruptedFiles()
    }
    
    // MARK: - Public Interface
    
    func getApplicationContext() -> [String: Any] {
        // ✅ CRITICAL FIX: Include actual user profile data for Watch sync
        var context: [String: Any] = [
            "appVersion": UserDefaults.standard.string(forKey: "SC40_appVersion") ?? "1.0.0",
            "buildNumber": UserDefaults.standard.string(forKey: "SC40_buildNumber") ?? "1",
            "onboardingCompleted": UserDefaults.standard.bool(forKey: "onboardingCompleted"),
            "userProfileExists": UserDefaults.standard.bool(forKey: "SC40_userProfileExists"),
            "lastLaunch": Date()
        ]
        
        // Add user profile data if available
        if let userName = UserDefaults.standard.string(forKey: "user_name") {
            context["userName"] = userName
        }
        
        if let pb = UserDefaults.standard.object(forKey: "personalBest40yd") as? Double {
            context["pb"] = pb
        }
        
        if let fitnessLevel = UserDefaults.standard.string(forKey: "userLevel") {
            context["fitnessLevel"] = fitnessLevel
        }
        
        if let daysAvailable = UserDefaults.standard.object(forKey: "trainingFrequency") as? Int {
            context["daysAvailable"] = daysAvailable
        }
        
        if let age = UserDefaults.standard.object(forKey: "SC40_UserAge") as? Int {
            context["age"] = age
        }
        
        if let height = UserDefaults.standard.object(forKey: "SC40_UserHeight") as? Int {
            context["height"] = height
        }
        
        if let weight = UserDefaults.standard.object(forKey: "SC40_UserWeight") as? Double {
            context["weight"] = weight
        }
        
        if let currentWeek = UserDefaults.standard.object(forKey: "SC40_CurrentWeek") as? Int {
            context["currentWeek"] = currentWeek
        }
        
        if let currentDay = UserDefaults.standard.object(forKey: "SC40_CurrentDay") as? Int {
            context["currentDay"] = currentDay
        }
        
        logger.info("📖 Retrieved application context with user profile data")
        return context
    }
    
    func updateApplicationContext(_ updates: [String: Any]) {
        for (key, value) in updates {
            UserDefaults.standard.set(value, forKey: "SC40_\(key)")
        }
        UserDefaults.standard.synchronize()
        
        logger.info("📝 Updated application context with \(updates.count) items")
    }
}
