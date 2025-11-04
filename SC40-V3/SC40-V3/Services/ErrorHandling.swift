import Foundation
import Combine
import OSLog
import SwiftUI

// MARK: - SC40 Error Types

enum SC40Error: LocalizedError {
    case watchConnectivityFailed(Error)
    case sessionDataCorrupted(String)
    case invalidPersonalBest(Double, reason: String)
    case networkTimeout
    case healthKitAuthorizationDenied
    case locationAccessDenied
    case gpsAccuracyPoor(accuracy: Double)
    case timerSyncFailed
    case sessionNotFound(Int, Int) // week, day
    case invalidSessionData(String)
    case storageError(Error)
    case workoutSessionFailed(Error)
    case dataValidationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .watchConnectivityFailed(let error):
            return "Failed to connect to Apple Watch: \(error.localizedDescription)"
        case .sessionDataCorrupted(let details):
            return "Training session data is corrupted: \(details)"
        case .invalidPersonalBest(let time, let reason):
            return "Invalid personal best time (\(String(format: "%.2f", time))s): \(reason)"
        case .networkTimeout:
            return "Network request timed out. Please check your connection."
        case .healthKitAuthorizationDenied:
            return "HealthKit access is required for workout tracking"
        case .locationAccessDenied:
            return "Location access is required for GPS tracking"
        case .gpsAccuracyPoor(let accuracy):
            return "GPS accuracy is poor (\(Int(accuracy))m). Move to an open area."
        case .timerSyncFailed:
            return "Failed to synchronize timers between devices"
        case .sessionNotFound(let week, let day):
            return "Training session not found for Week \(week), Day \(day)"
        case .invalidSessionData(let details):
            return "Invalid session data: \(details)"
        case .storageError(let error):
            return "Data storage error: \(error.localizedDescription)"
        case .workoutSessionFailed(let error):
            return "Workout session failed: \(error.localizedDescription)"
        case .dataValidationFailed(let details):
            return "Data validation failed: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .watchConnectivityFailed:
            return "Make sure your Apple Watch is paired and the SC40 app is installed on your watch."
        case .sessionDataCorrupted:
            return "Try refreshing your training program or restart the app."
        case .invalidPersonalBest:
            return "Please enter a realistic time between 3.0 and 15.0 seconds."
        case .networkTimeout:
            return "Check your internet connection and try again."
        case .healthKitAuthorizationDenied:
            return "Enable HealthKit access in Settings > Privacy & Security > Health."
        case .locationAccessDenied:
            return "Enable location access in Settings > Privacy & Security > Location Services."
        case .gpsAccuracyPoor:
            return "Move to an open area away from buildings and try again."
        case .timerSyncFailed:
            return "Restart both your iPhone and Apple Watch, then try again."
        case .sessionNotFound:
            return "Refresh your training program or check your program schedule."
        case .invalidSessionData:
            return "Try refreshing your training sessions."
        case .storageError:
            return "Restart the app or free up device storage."
        case .workoutSessionFailed:
            return "End the current workout and start a new one."
        case .dataValidationFailed:
            return "Check your data and try again."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .watchConnectivityFailed, .networkTimeout, .gpsAccuracyPoor, .timerSyncFailed:
            return true
        case .healthKitAuthorizationDenied, .locationAccessDenied:
            return false // Requires user action in Settings
        case .sessionDataCorrupted, .invalidPersonalBest, .sessionNotFound, .invalidSessionData, .dataValidationFailed:
            return true
        case .storageError, .workoutSessionFailed:
            return true
        }
    }
}

// MARK: - Error Handler Service

@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: SC40Error?
    @Published var errorHistory: [ErrorLogEntry] = []
    @Published var showErrorAlert = false
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "ErrorHandling")
    private let maxHistorySize = 100
    
    private init() {}
    
    // MARK: - Error Reporting
    
    func handle(_ error: SC40Error) {
        logger.error("SC40Error: \(error.localizedDescription)")
        
        let entry = ErrorLogEntry(
            error: error,
            timestamp: Date(),
            isResolved: false
        )
        
        errorHistory.insert(entry, at: 0)
        
        // Keep history size manageable
        if errorHistory.count > maxHistorySize {
            errorHistory = Array(errorHistory.prefix(maxHistorySize))
        }
        
        currentError = error
        
        // Show alert for user-facing errors
        if shouldShowAlert(for: error) {
            showErrorAlert = true
        }
        
        // Log additional context
        logErrorContext(error)
    }
    
    func handle(_ error: Error, context: String = "") {
        logger.error("System error in \(context): \(error.localizedDescription)")
        
        // Convert system errors to SC40Error when possible
        let sc40Error: SC40Error
        
        if let sc40Err = error as? SC40Error {
            sc40Error = sc40Err
        } else if context.contains("HealthKit") {
            sc40Error = .workoutSessionFailed(error)
        } else if context.contains("WatchConnectivity") {
            sc40Error = .watchConnectivityFailed(error)
        } else if context.contains("storage") || context.contains("persistence") {
            sc40Error = .storageError(error)
        } else {
            // Create generic error for unknown system errors
            sc40Error = .dataValidationFailed("System error: \(error.localizedDescription)")
        }
        
        handle(sc40Error)
    }
    
    // MARK: - Error Recovery
    
    func resolveError(_ entry: ErrorLogEntry) {
        if let index = errorHistory.firstIndex(where: { $0.id == entry.id }) {
            errorHistory[index].isResolved = true
            errorHistory[index].resolvedAt = Date()
        }
        
        if currentError != nil {
            currentError = nil
        }
        
        showErrorAlert = false
        logger.info("Error resolved: \(entry.error.localizedDescription)")
    }
    
    func dismissCurrentError() {
        if let current = currentError,
           let entry = errorHistory.first(where: { $0.error.localizedDescription == current.localizedDescription && !$0.isResolved }) {
            resolveError(entry)
        }
        currentError = nil
        showErrorAlert = false
    }
    
    func retryLastOperation() {
        // This can be implemented to retry the last failed operation
        // For now, just clear the current error
        dismissCurrentError()
    }
    
    // MARK: - Error Analysis
    
    private func shouldShowAlert(for error: SC40Error) -> Bool {
        switch error {
        case .healthKitAuthorizationDenied, .locationAccessDenied:
            return true // Critical permissions
        case .watchConnectivityFailed, .timerSyncFailed:
            return true // Critical for workouts
        case .invalidPersonalBest, .sessionNotFound:
            return true // User needs to take action
        case .gpsAccuracyPoor:
            return false // Non-blocking, can continue
        case .networkTimeout:
            return false // Background operation
        default:
            return true
        }
    }
    
    private func logErrorContext(_ error: SC40Error) {
        // Log additional context based on error type
        switch error {
        case .watchConnectivityFailed:
            logger.info("WatchConnectivity error occurred")
        case .gpsAccuracyPoor(let accuracy):
            logger.info("GPS accuracy: \(accuracy)m")
        case .invalidPersonalBest(let time, _):
            logger.info("Attempted PB entry: \(time)s")
        default:
            break
        }
    }
    
    // MARK: - Validation Helpers
    
    func validatePersonalBest(_ time: Double) throws {
        guard time >= 3.0 && time <= 15.0 else {
            throw SC40Error.invalidPersonalBest(time, reason: "Time must be between 3.0 and 15.0 seconds")
        }
        
        guard !time.isNaN && !time.isInfinite else {
            throw SC40Error.invalidPersonalBest(time, reason: "Invalid time value")
        }
    }
    
    func validateSessionData(_ session: TrainingSession) throws {
        guard !session.sprints.isEmpty else {
            throw SC40Error.invalidSessionData("Session has no sprint sets")
        }
        
        guard session.week >= 1 && session.week <= 12 else {
            throw SC40Error.invalidSessionData("Invalid week number: \(session.week)")
        }
        
        guard session.day >= 1 && session.day <= 7 else {
            throw SC40Error.invalidSessionData("Invalid day number: \(session.day)")
        }
        
        for sprint in session.sprints {
            guard sprint.distanceYards > 0 && sprint.distanceYards <= 100 else {
                throw SC40Error.invalidSessionData("Invalid sprint distance: \(sprint.distanceYards)")
            }
            
            guard sprint.reps > 0 && sprint.reps <= 20 else {
                throw SC40Error.invalidSessionData("Invalid rep count: \(sprint.reps)")
            }
        }
    }
    
    func validateGPSAccuracy(_ accuracy: Double) throws {
        guard accuracy <= 10.0 else {
            throw SC40Error.gpsAccuracyPoor(accuracy: accuracy)
        }
    }
}

// MARK: - Error Log Entry

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: SC40Error
    let timestamp: Date
    var isResolved: Bool
    var resolvedAt: Date?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Convenience Extensions

extension View {
    func handleSC40Errors() -> some View {
        self.environmentObject(ErrorHandlingService.shared)
            .alert("Error", isPresented: .constant(ErrorHandlingService.shared.showErrorAlert)) {
                if let error = ErrorHandlingService.shared.currentError {
                    Button("OK") {
                        ErrorHandlingService.shared.dismissCurrentError()
                    }
                    
                    if error.isRecoverable {
                        Button("Retry") {
                            ErrorHandlingService.shared.retryLastOperation()
                        }
                    }
                }
            } message: {
                if let error = ErrorHandlingService.shared.currentError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.errorDescription ?? "Unknown error occurred")
                        
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
    }
}

