import Foundation
import os.log

/// Handles file system errors and provides recovery mechanisms
class FileSystemErrorHandler {
    static let shared = FileSystemErrorHandler()
    
    private let logger = Logger(subsystem: "com.sc40.app", category: "FileSystem")
    
    private init() {
        setupErrorHandling()
    }
    
    // MARK: - Error Handling Setup
    
    private func setupErrorHandling() {
        logger.info("🛡️ Setting up file system error handling")
        
        // Create error recovery directories
        createRecoveryDirectories()
        
        // Set up file system monitoring
        monitorFileSystemHealth()
        
        // Proactively handle common file errors
        preemptiveErrorPrevention()
    }
    
    // MARK: - Directory Management
    
    private func createRecoveryDirectories() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("❌ Cannot access documents directory")
            return
        }
        
        // Create recovery directories
        let recoveryDirectories = [
            "SC40Recovery",
            "SC40Backup", 
            "SC40Temp"
        ]
        
        for dirName in recoveryDirectories {
            let dirURL = documentsURL.appendingPathComponent(dirName)
            
            do {
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                logger.info("📁 Created recovery directory: \(dirName)")
            } catch {
                logger.error("❌ Failed to create recovery directory \(dirName): \(error)")
            }
        }
    }
    
    // MARK: - File System Monitoring
    
    private func monitorFileSystemHealth() {
        logger.info("🔍 Starting file system health monitoring")
        
        // Check available disk space
        checkDiskSpace()
        
        // Verify critical directories exist
        verifyCriticalDirectories()
        
        // Clean up temporary files
        cleanupTemporaryFiles()
    }
    
    private func checkDiskSpace() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let resourceValues = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            
            if let availableCapacity = resourceValues.volumeAvailableCapacity {
                let availableMB = availableCapacity / (1024 * 1024)
                logger.info("💾 Available disk space: \(availableMB) MB")
                
                if availableMB < 100 { // Less than 100MB
                    logger.warning("⚠️ Low disk space detected: \(availableMB) MB")
                    handleLowDiskSpace()
                }
            }
        } catch {
            logger.error("❌ Failed to check disk space: \(error)")
        }
    }
    
    private func verifyCriticalDirectories() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let criticalDirectories = [
            "SC40Data",
            "SC40Cache", 
            "SC40Logs",
            "SC40Recovery"
        ]
        
        for dirName in criticalDirectories {
            let dirURL = documentsURL.appendingPathComponent(dirName)
            
            if !fileManager.fileExists(atPath: dirURL.path) {
                do {
                    try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                    logger.info("🔧 Recreated missing directory: \(dirName)")
                } catch {
                    logger.error("❌ Failed to recreate directory \(dirName): \(error)")
                }
            }
        }
    }
    
    private func cleanupTemporaryFiles() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let tempURL = documentsURL.appendingPathComponent("SC40Temp")
        
        do {
            let tempFiles = try fileManager.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            for fileURL in tempFiles {
                let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                
                if let creationDate = resourceValues.creationDate, creationDate < cutoffDate {
                    try fileManager.removeItem(at: fileURL)
                    logger.info("🗑️ Cleaned up old temp file: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            logger.info("ℹ️ No temp files to clean up or directory doesn't exist")
        }
    }
    
    // MARK: - Error Recovery
    
    func handleFileOpenError(errno: Int32, path: String) {
        logger.error("🚨 File open error: errno \(errno) for path: \(path)")
        
        switch errno {
        case 2: // ENOENT - No such file or directory
            handleMissingFileError(path: path)
        case 13: // EACCES - Permission denied
            handlePermissionError(path: path)
        case 28: // ENOSPC - No space left on device
            handleNoSpaceError()
        default:
            handleGenericFileError(errno: errno, path: path)
        }
    }
    
    private func handleMissingFileError(path: String) {
        logger.info("🔧 Handling missing file error for: \(path)")
        
        // Try to create the missing file or directory
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)
        
        // Check if it's a directory path
        if path.hasSuffix("/") || !url.pathExtension.isEmpty {
            // Try to create parent directories
            let parentURL = url.deletingLastPathComponent()
            
            do {
                try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true, attributes: nil)
                logger.info("✅ Created missing parent directories for: \(path)")
            } catch {
                logger.error("❌ Failed to create parent directories: \(error)")
            }
        }
    }
    
    private func handlePermissionError(path: String) {
        logger.warning("⚠️ Permission denied for: \(path)")
        
        // Log the issue but don't attempt to fix permissions for security
        logger.info("ℹ️ Check app sandbox permissions for file access")
    }
    
    private func handleNoSpaceError() {
        logger.error("💾 No space left on device")
        handleLowDiskSpace()
    }
    
    private func handleLowDiskSpace() {
        logger.info("🧹 Attempting to free up disk space")
        
        // Clean up cache directories
        cleanupCacheDirectories()
        
        // Clean up old log files
        cleanupOldLogFiles()
        
        // Notify user if needed
        NotificationCenter.default.post(
            name: NSNotification.Name("LowDiskSpaceDetected"),
            object: nil
        )
    }
    
    private func handleGenericFileError(errno: Int32, path: String) {
        logger.error("❌ Generic file error \(errno) for: \(path)")
        
        // Log the error for debugging
        let errorDescription = String(cString: strerror(errno))
        logger.error("Error description: \(errorDescription)")
    }
    
    // MARK: - Cleanup Methods
    
    private func cleanupCacheDirectories() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let cacheURL = documentsURL.appendingPathComponent("SC40Cache")
        
        do {
            if fileManager.fileExists(atPath: cacheURL.path) {
                try fileManager.removeItem(at: cacheURL)
                try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
                logger.info("🧹 Cleared cache directory to free space")
            }
        } catch {
            logger.error("❌ Failed to clear cache directory: \(error)")
        }
    }
    
    private func cleanupOldLogFiles() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logsURL = documentsURL.appendingPathComponent("SC40Logs")
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsURL, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            
            for fileURL in logFiles {
                let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                
                if let creationDate = resourceValues.creationDate, creationDate < cutoffDate {
                    try fileManager.removeItem(at: fileURL)
                    logger.info("🗑️ Removed old log file: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            logger.info("ℹ️ No old log files to clean up")
        }
    }
    
    // MARK: - Public Interface
    
    func invalidateAllCaches() {
        logger.info("🗑️ Invalidating all caches due to errors")
        
        cleanupCacheDirectories()
        cleanupTemporaryFiles()
        
        // Notify other systems
        NotificationCenter.default.post(
            name: NSNotification.Name("CachesInvalidated"),
            object: nil
        )
    }
    
    func performFileSystemRecovery() {
        logger.info("🔄 Performing file system recovery")
        
        createRecoveryDirectories()
        verifyCriticalDirectories()
        cleanupTemporaryFiles()
        preemptiveErrorPrevention()
        
        logger.info("✅ File system recovery completed")
    }
    
    // MARK: - Preemptive Error Prevention
    
    private func preemptiveErrorPrevention() {
        logger.info("🔮 Starting preemptive error prevention")
        
        // Create common data files that third-party SDKs might expect
        createCommonDataFiles()
        
        // Set proper file permissions
        setProperFilePermissions()
        
        // Initialize cache structures
        initializeCacheStructures()
    }
    
    private func createCommonDataFiles() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Common data files that might be expected by SDKs
        let commonFiles = [
            "SC40Data/user_data.json",
            "SC40Data/app_state.json", 
            "SC40Cache/session_cache.json",
            "SC40Logs/app.log"
        ]
        
        for filePath in commonFiles {
            let fileURL = documentsURL.appendingPathComponent(filePath)
            
            if !fileManager.fileExists(atPath: fileURL.path) {
                // Create parent directory if needed
                let parentURL = fileURL.deletingLastPathComponent()
                try? fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true, attributes: nil)
                
                // Create empty file with basic structure
                let defaultContent: Data
                if filePath.hasSuffix(".json") {
                    defaultContent = "{}".data(using: .utf8) ?? Data()
                } else {
                    defaultContent = "".data(using: .utf8) ?? Data()
                }
                
                try? defaultContent.write(to: fileURL)
                logger.info("📄 Created common data file: \(filePath)")
            }
        }
    }
    
    private func setProperFilePermissions() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Set proper permissions for SC40 directories
        let directories = ["SC40Data", "SC40Cache", "SC40Logs", "SC40Recovery"]
        
        for dirName in directories {
            let dirURL = documentsURL.appendingPathComponent(dirName)
            
            if fileManager.fileExists(atPath: dirURL.path) {
                do {
                    try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dirURL.path)
                    logger.debug("🔐 Set permissions for directory: \(dirName)")
                } catch {
                    logger.warning("⚠️ Could not set permissions for \(dirName): \(error)")
                }
            }
        }
    }
    
    private func initializeCacheStructures() {
        let fileManager = FileManager.default
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let cacheURL = documentsURL.appendingPathComponent("SC40Cache")
        
        // Create cache index file
        let cacheIndexURL = cacheURL.appendingPathComponent("cache_index.json")
        
        if !fileManager.fileExists(atPath: cacheIndexURL.path) {
            let cacheIndex = [
                "version": "1.0",
                "created": Date().timeIntervalSince1970,
                "entries": []
            ] as [String: Any]
            
            if let data = try? JSONSerialization.data(withJSONObject: cacheIndex, options: .prettyPrinted) {
                try? data.write(to: cacheIndexURL)
                logger.info("📋 Created cache index file")
            }
        }
    }
}
