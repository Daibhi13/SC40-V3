import Foundation
import SwiftUI
import os.log

// MARK: - Watch Crash Debugger
// Comprehensive debugging utilities to prevent and diagnose Watch app crashes

class WatchCrashDebugger {
    static let shared = WatchCrashDebugger()
    private let logger = Logger(subsystem: "com.accelerate.sc40.watch", category: "CrashDebugger")
    
    private init() {}
    
    // MARK: - Session Validation
    
    /// Validates a TrainingSession for potential crash-causing issues
    func validateSession(_ session: TrainingSession) -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check basic properties
        if session.type.isEmpty {
            issues.append("Empty session type")
        }
        
        if session.focus.isEmpty {
            warnings.append("Empty session focus")
        }
        
        if session.week < 1 || session.week > 12 {
            warnings.append("Week out of range: \(session.week)")
        }
        
        if session.day < 1 || session.day > 7 {
            warnings.append("Day out of range: \(session.day)")
        }
        
        // Check sprints array
        if session.sprints.isEmpty {
            issues.append("No sprints in session")
        } else {
            for (index, sprint) in session.sprints.enumerated() {
                if sprint.distanceYards <= 0 {
                    issues.append("Invalid distance in sprint \(index + 1): \(sprint.distanceYards)")
                }
                
                if sprint.reps <= 0 {
                    issues.append("Invalid reps in sprint \(index + 1): \(sprint.reps)")
                }
                
                if sprint.intensity.isEmpty {
                    warnings.append("Empty intensity in sprint \(index + 1)")
                }
            }
        }
        
        // Check accessory work
        if session.accessoryWork.isEmpty {
            warnings.append("No accessory work defined")
        }
        
        let result = ValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
        
        if !result.isValid {
            logger.error("❌ Session validation failed: \(issues.joined(separator: ", "))")
        } else if !warnings.isEmpty {
            logger.warning("⚠️ Session validation warnings: \(warnings.joined(separator: ", "))")
        } else {
            logger.info("✅ Session validation passed")
        }
        
        return result
    }
    
    // MARK: - JSON Validation
    
    /// Validates JSON data before attempting to decode
    func validateSessionJSON(_ data: [String: Any]) -> JSONValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check required fields
        guard data["week"] is Int else {
            issues.append("Missing or invalid 'week' field")
            return JSONValidationResult(isValid: false, issues: issues, warnings: warnings)
        }
        
        guard data["day"] is Int else {
            issues.append("Missing or invalid 'day' field")
            return JSONValidationResult(isValid: false, issues: issues, warnings: warnings)
        }
        
        // Check optional but important fields
        if let type = data["type"] as? String, type.isEmpty {
            warnings.append("Empty type field")
        } else if data["type"] == nil {
            warnings.append("Missing type field")
        }
        
        if let focus = data["focus"] as? String, focus.isEmpty {
            warnings.append("Empty focus field")
        } else if data["focus"] == nil {
            warnings.append("Missing focus field")
        }
        
        // Check sprints array
        if let sprints = data["sprints"] as? [[String: Any]] {
            if sprints.isEmpty {
                issues.append("Empty sprints array")
            } else {
                for (index, sprint) in sprints.enumerated() {
                    if sprint["distanceYards"] == nil {
                        issues.append("Missing distanceYards in sprint \(index + 1)")
                    }
                    if sprint["reps"] == nil {
                        warnings.append("Missing reps in sprint \(index + 1)")
                    }
                    if sprint["intensity"] == nil {
                        warnings.append("Missing intensity in sprint \(index + 1)")
                    }
                }
            }
        } else {
            issues.append("Missing or invalid sprints array")
        }
        
        return JSONValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
    }
    
    // MARK: - UI Safety Checks
    
    /// Checks if a session is safe to display in UI
    func isSessionSafeForUI(_ session: TrainingSession) -> Bool {
        let _ = validateSession(session)
        
        // Critical checks for UI safety
        let hasValidType = !session.safeType.isEmpty
        let hasValidFocus = !session.safeFocus.isEmpty
        let hasValidSprints = !session.sprints.isEmpty && session.sprints.allSatisfy { $0.distanceYards > 0 }
        
        let isSafe = hasValidType && hasValidFocus && hasValidSprints
        
        if !isSafe {
            logger.error("❌ Session not safe for UI: type=\(hasValidType), focus=\(hasValidFocus), sprints=\(hasValidSprints)")
        }
        
        return isSafe
    }
    
    // MARK: - Crash Prevention
    
    /// Safely formats session data for display
    func safeSessionDescription(_ session: TrainingSession) -> String {
        let type = session.safeType
        let focus = session.safeFocus
        let sprintCount = session.sprints.count
        
        return "W\(session.week)D\(session.day): \(type) - \(focus) (\(sprintCount) sprints)"
    }
    
    /// Safely formats sprint data for display
    func safeSprintDescription(_ sprints: [SprintSet]) -> String {
        guard !sprints.isEmpty else { return "No Sprints" }
        
        let validSprints = sprints.filter { $0.distanceYards > 0 && $0.reps > 0 }
        guard !validSprints.isEmpty else { return "Invalid Sprints" }
        
        if validSprints.count == 1 {
            let sprint = validSprints[0]
            return "\(sprint.reps)x\(sprint.distanceYards)yd"
        }
        
        let distances = validSprints.map { $0.distanceYards }
        let minDistance = distances.min() ?? 0
        let maxDistance = distances.max() ?? 0
        
        if minDistance == maxDistance {
            let totalReps = validSprints.reduce(0) { $0 + $1.reps }
            return "\(totalReps)x\(minDistance)yd"
        } else {
            return "\(validSprints.count) sets: \(minDistance)-\(maxDistance)yd"
        }
    }
    
    // MARK: - Debug Logging
    
    func logSessionDetails(_ session: TrainingSession) {
        logger.info("📋 Session Details:")
        logger.info("   ID: \(session.id)")
        logger.info("   Week/Day: W\(session.week)D\(session.day)")
        logger.info("   Type: '\(session.type)' (safe: '\(session.safeType)')")
        logger.info("   Focus: '\(session.focus)' (safe: '\(session.safeFocus)')")
        logger.info("   Sprints: \(session.sprints.count)")
        
        for (index, sprint) in session.sprints.enumerated() {
            logger.info("     Sprint \(index + 1): \(sprint.reps)x\(sprint.distanceYards)yd @ \(sprint.intensity)")
        }
        
        logger.info("   Accessory Work: \(session.accessoryWork.count) items")
        logger.info("   Notes: \(session.notes ?? "None")")
    }
}

// MARK: - Validation Results

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
    
    var summary: String {
        if isValid && !hasWarnings {
            return "✅ Valid"
        } else if isValid && hasWarnings {
            return "⚠️ Valid with warnings"
        } else {
            return "❌ Invalid"
        }
    }
}

struct JSONValidationResult {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
}

// MARK: - SwiftUI Extensions for Safe Display

extension TrainingSession {
    /// Returns a crash-safe description for debugging
    var debugDescription: String {
        return WatchCrashDebugger.shared.safeSessionDescription(self)
    }
    
    /// Validates this session for UI safety
    var isUIReady: Bool {
        return WatchCrashDebugger.shared.isSessionSafeForUI(self)
    }
}

extension Array where Element == SprintSet {
    /// Returns a crash-safe sprint description
    var safeDescription: String {
        return WatchCrashDebugger.shared.safeSprintDescription(self)
    }
}

// MARK: - Debug View for Testing

#if DEBUG
struct SessionDebugView: View {
    let session: TrainingSession
    @State private var validationResult: ValidationResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Debug Info")
                .font(.headline)
                .foregroundColor(.yellow)
            
            Text(session.debugDescription)
                .font(.caption)
                .foregroundColor(.white)
            
            if let result = validationResult {
                Text(result.summary)
                    .font(.caption)
                    .foregroundColor(result.isValid ? .green : .red)
                
                if !result.issues.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Issues:")
                            .font(.caption2)
                            .foregroundColor(.red)
                        ForEach(result.issues, id: \.self) { issue in
                            Text("• \(issue)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if !result.warnings.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Warnings:")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        ForEach(result.warnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .onAppear {
            validationResult = WatchCrashDebugger.shared.validateSession(session)
        }
    }
}
#endif
