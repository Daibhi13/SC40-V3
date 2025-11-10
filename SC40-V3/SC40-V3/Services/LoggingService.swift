import Foundation
import Combine
import OSLog
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Logging Service

final class LoggingService: @unchecked Sendable {
    static let shared = LoggingService()
    
    // PERFORMANCE: Master switch for all logging - set to false for speed
    static let LOGGING_ENABLED = false
    
    // MARK: - Logger Categories
    
    private let subsystem = "com.accelerate.sc40"
    
    lazy var connectivity = Logger(subsystem: subsystem, category: "WatchConnectivity")
    lazy var session = Logger(subsystem: subsystem, category: "SessionManagement")
    lazy var workout = Logger(subsystem: subsystem, category: "WorkoutTracking")
    lazy var healthKit = Logger(subsystem: subsystem, category: "HealthKit")
    lazy var gps = Logger(subsystem: subsystem, category: "GPSTracking")
    lazy var persistence = Logger(subsystem: subsystem, category: "DataPersistence")
    lazy var performance = Logger(subsystem: subsystem, category: "Performance")
    lazy var ui = Logger(subsystem: subsystem, category: "UserInterface")
    lazy var network = Logger(subsystem: subsystem, category: "Network")
    
    private init() {}
    
    // MARK: - Convenience Methods
    
    func logSessionStart(_ session: Any) {
        guard Self.LOGGING_ENABLED else { return }
        // Logging disabled for performance
    }
    
    func logSessionComplete(_ session: Any, duration: TimeInterval) {
        guard Self.LOGGING_ENABLED else { return }
        // Logging disabled for performance
    }
    
    func logPersonalBest(_ distance: String, oldTime: Double?, newTime: Double) {
        guard Self.LOGGING_ENABLED else { return }
        if let oldTime = oldTime {
            self.performance.info("🏆 New PB for \(distance): \(String(format: "%.2f", newTime))s (prev: \(String(format: "%.2f", oldTime))s)")
        } else {
            self.performance.info("🏆 First PB for \(distance): \(String(format: "%.2f", newTime))s")
        }
    }
    
    func logWatchSync(sessionCount: Int, dataSize: Int) {
        guard Self.LOGGING_ENABLED else { return }
        self.connectivity.info("Synced \(sessionCount) sessions to watch (\(dataSize) bytes)")
    }
    
    func logGPSAccuracy(_ accuracy: Double) {
        guard Self.LOGGING_ENABLED else { return }
        if accuracy <= 5 {
            self.gps.info("GPS accuracy excellent: \(String(format: "%.1f", accuracy))m")
        } else if accuracy <= 10 {
            self.gps.info("GPS accuracy good: \(String(format: "%.1f", accuracy))m")
        } else {
            self.gps.warning("GPS accuracy poor: \(String(format: "%.1f", accuracy))m")
        }
    }
    
    func logWorkoutMetrics(heartRate: Double?, distance: Double?, pace: Double?) {
        guard Self.LOGGING_ENABLED else { return }
        var metrics: [String] = []
        
        if let hr = heartRate {
            metrics.append("HR: \(Int(hr))bpm")
        }
        
        if let dist = distance {
            metrics.append("Dist: \(String(format: "%.1f", dist))yd")
        }
        
        if let pace = pace {
            metrics.append("Pace: \(String(format: "%.2f", pace))s/yd")
        }
        
        self.workout.info("Workout metrics: \(metrics.joined(separator: ", "))")
    }
    
    func logDataPersistence(_ operation: String, success: Bool, itemCount: Int? = nil) {
        guard Self.LOGGING_ENABLED else { return }
        if success {
            let countStr = itemCount != nil ? " (\(itemCount!) items)" : ""
            self.persistence.info("\(operation) successful\(countStr)")
        } else {
            self.persistence.error("\(operation) failed")
        }
    }
}

// MARK: - Performance Monitoring

final class PerformanceMonitor: @unchecked Sendable {
    static let shared = PerformanceMonitor()
    private let logger = LoggingService.shared.performance
    
    private var timers: [String: Date] = [:]
    
    private init() {}
    
    func startTimer(_ name: String) {
        timers[name] = Date()
        logger.debug("Started timer: \(name)")
    }
    
    @discardableResult
    func endTimer(_ name: String) -> TimeInterval? {
        guard let startTime = timers.removeValue(forKey: name) else {
            logger.warning("Timer '\(name)' not found")
            return nil
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Timer '\(name)': \(String(format: "%.3f", duration))s")
        return duration
    }
    
    func measureAsync<T>(_ operation: String, _ work: () async throws -> T) async rethrows -> T {
        startTimer(operation)
        let result = try await work()
        endTimer(operation)
        return result
    }
    
    func measureSync<T>(_ operation: String, _ work: () throws -> T) rethrows -> T {
        startTimer(operation)
        let result = try work()
        endTimer(operation)
        return result
    }
}

// MARK: - Debug Utilities

#if DEBUG
final class DebugUtils: @unchecked Sendable {
    static let shared = DebugUtils()
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "Debug")
    
    private init() {}
    
    func logWatchConnectivityState() {
        logger.debug("WatchConnectivity debug info disabled due to compilation issues")
    }
    
    @MainActor
    func logDeviceInfo() {
        #if canImport(UIKit)
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let model = device.model
        let name = device.name
        let message = """
        Device Info:
        - iOS Version: \(systemVersion)
        - Device Model: \(model)
        - Device Name: \(name)
        """
        logger.debug("\(message)")
        #else
        logger.debug("Device Info: Not available on this platform")
        #endif
    }
    
    func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            logger.debug("Memory usage: \(String(format: "%.1f", usedMB))MB")
        }
    }
    
    func simulateError(_ error: SC40Error) {
        logger.debug("Simulating error: \(error.localizedDescription)")
        Task { @MainActor in
            ErrorHandlingService.shared.handle(error)
        }
    }
}
#endif

// MARK: - Log Level Configuration

extension OSLogType {
    static var sc40DefaultLevel: OSLogType {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }
}

// MARK: - Convenience Extensions

extension Logger {
    func logError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        self.error("\(message)")
    }
    
    func logSuccess(_ operation: String) {
        self.info("✅ \(operation)")
    }
    
    func logWarning(_ message: String) {
        self.warning("⚠️ \(message)")
    }
    
    func logFailure(_ operation: String, error: Error? = nil) {
        if let error = error {
            self.error("❌ \(operation): \(error.localizedDescription)")
        } else {
            self.error("❌ \(operation)")
        }
    }
}

