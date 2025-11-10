import Foundation
import os.log

/// Centralized debug logging system with performance optimization
/// Set DEBUG_LOGGING_ENABLED to false to disable all debug logs
final class DebugLogger {
    
    // MARK: - Configuration
    
    /// Master switch for all debug logging - SET TO FALSE FOR PRODUCTION
    static let DEBUG_LOGGING_ENABLED = false
    
    /// Category-specific logging controls
    static let ENABLE_UI_LOGS = false
    static let ENABLE_NETWORK_LOGS = false
    static let ENABLE_WORKOUT_LOGS = false
    static let ENABLE_SYNC_LOGS = false
    static let ENABLE_GPS_LOGS = false
    static let ENABLE_AUDIO_LOGS = false
    
    // MARK: - Logging Categories
    
    enum Category: String {
        case ui = "🎨"
        case network = "🌐"
        case workout = "🏃‍♂️"
        case sync = "🔄"
        case gps = "📍"
        case audio = "🔊"
        case general = "📱"
        case error = "❌"
        case success = "✅"
        case warning = "⚠️"
    }
    
    // MARK: - Logging Methods
    
    /// Log a debug message (only in debug builds when enabled)
    static func log(_ message: String, category: Category = .general) {
        #if DEBUG
        guard DEBUG_LOGGING_ENABLED else { return }
        
        // Check category-specific flags
        switch category {
        case .ui where !ENABLE_UI_LOGS:
            return
        case .network where !ENABLE_NETWORK_LOGS:
            return
        case .workout where !ENABLE_WORKOUT_LOGS:
            return
        case .sync where !ENABLE_SYNC_LOGS:
            return
        case .gps where !ENABLE_GPS_LOGS:
            return
        case .audio where !ENABLE_AUDIO_LOGS:
            return
        default:
            break
        }
        
        print("\(category.rawValue) \(message)")
        #endif
    }
    
    /// Log an error (always enabled)
    static func error(_ message: String) {
        print("❌ ERROR: \(message)")
    }
    
    /// Log a warning (always enabled)
    static func warning(_ message: String) {
        print("⚠️ WARNING: \(message)")
    }
    
    /// Log a success message (always enabled)
    static func success(_ message: String) {
        print("✅ SUCCESS: \(message)")
    }
    
    /// Log critical information (always enabled)
    static func critical(_ message: String) {
        print("🚨 CRITICAL: \(message)")
    }
}

// MARK: - Convenience Extensions

extension DebugLogger {
    
    /// UI-related logs
    static func ui(_ message: String) {
        log(message, category: .ui)
    }
    
    /// Network-related logs
    static func network(_ message: String) {
        log(message, category: .network)
    }
    
    /// Workout-related logs
    static func workout(_ message: String) {
        log(message, category: .workout)
    }
    
    /// Sync-related logs
    static func sync(_ message: String) {
        log(message, category: .sync)
    }
    
    /// GPS-related logs
    static func gps(_ message: String) {
        log(message, category: .gps)
    }
    
    /// Audio-related logs
    static func audio(_ message: String) {
        log(message, category: .audio)
    }
}
