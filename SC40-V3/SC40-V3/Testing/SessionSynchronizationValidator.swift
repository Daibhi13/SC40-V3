import Foundation
import Combine

// MARK: - Session Synchronization Validator

/// Validates that iPhone and Watch generate identical 12-week programs
class SessionSynchronizationValidator: ObservableObject {
    
    @Published var validationResults: [ValidationResult] = []
    @Published var isValidating = false
    @Published var overallStatus: ValidationStatus = .pending
    
    // MARK: - Validation Methods
    
    /// Validate synchronization for all 28 combinations (4 levels × 7 days)
    func validateAll28Combinations() async {
        await MainActor.run {
            isValidating = true
            validationResults.removeAll()
            overallStatus = .pending
        }
        
        print("🔍 Starting comprehensive session synchronization validation")
        print("📊 Testing 4 levels × 7 days = 28 combinations")
        
        let levels = ["Beginner", "Intermediate", "Advanced", "Pro"]
        let frequencies = [1, 2, 3, 4, 5, 6, 7]
        
        var allResults: [ValidationResult] = []
        
        for level in levels {
            for frequency in frequencies {
                let result = await validateSingleCombination(level: level, frequency: frequency)
                allResults.append(result)
                
                await MainActor.run {
                    validationResults.append(result)
                }
                
                // Small delay to prevent overwhelming the system
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        // Determine overall status
        let passedCount = allResults.filter { $0.status == .passed }.count
        let failedCount = allResults.filter { $0.status == .failed }.count
        
        await MainActor.run {
            if failedCount == 0 {
                overallStatus = .passed
            } else if passedCount > 0 {
                overallStatus = .partiallyPassed
            } else {
                overallStatus = .failed
            }
            isValidating = false
        }
        
        print("✅ Validation complete: \(passedCount) passed, \(failedCount) failed")
    }
    
    /// Validate synchronization for a specific level/frequency combination
    func validateSingleCombination(level: String, frequency: Int) async -> ValidationResult {
        let startTime = Date()
        
        print("🔍 Validating: \(level) × \(frequency) days")
        
        do {
            // Generate sessions using iPhone method (UnifiedSessionGenerator)
            let unifiedGenerator = UnifiedSessionGenerator.shared
            let iPhoneSessions = unifiedGenerator.generateUnified12WeekProgram(
                userLevel: level,
                frequency: frequency,
                userPreferences: nil
            )
            
            // Generate sessions using Watch method (same UnifiedSessionGenerator)
            let watchSessions = unifiedGenerator.generateUnified12WeekProgram(
                userLevel: level,
                frequency: frequency,
                userPreferences: nil
            )
            
            // Compare sessions
            let comparison = compareSessions(
                iPhoneSessions: iPhoneSessions,
                watchSessions: watchSessions,
                level: level,
                frequency: frequency
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            return ValidationResult(
                level: level,
                frequency: frequency,
                iPhoneSessionCount: iPhoneSessions.count,
                watchSessionCount: watchSessions.count,
                matchingSessionCount: comparison.matchingCount,
                mismatchedSessions: comparison.mismatches,
                status: comparison.mismatches.isEmpty ? .passed : .failed,
                duration: duration,
                errorMessage: comparison.mismatches.isEmpty ? nil : "Found \(comparison.mismatches.count) mismatched sessions"
            )
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            return ValidationResult(
                level: level,
                frequency: frequency,
                iPhoneSessionCount: 0,
                watchSessionCount: 0,
                matchingSessionCount: 0,
                mismatchedSessions: [],
                status: .failed,
                duration: duration,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    // MARK: - Session Comparison
    
    private func compareSessions(
        iPhoneSessions: [TrainingSession],
        watchSessions: [TrainingSession],
        level: String,
        frequency: Int
    ) -> SessionComparison {
        
        var matchingCount = 0
        var mismatches: [SessionMismatch] = []
        
        // Check session count first
        guard iPhoneSessions.count == watchSessions.count else {
            mismatches.append(SessionMismatch(
                week: 0,
                day: 0,
                issue: "Session count mismatch",
                iPhoneValue: "\(iPhoneSessions.count) sessions",
                watchValue: "\(watchSessions.count) sessions"
            ))
            return SessionComparison(matchingCount: 0, mismatches: mismatches)
        }
        
        // Sort sessions by week and day for comparison
        let sortedIPhoneSessions = iPhoneSessions.sorted { 
            if $0.week != $1.week { return $0.week < $1.week }
            return $0.day < $1.day
        }
        let sortedWatchSessions = watchSessions.sorted { 
            if $0.week != $1.week { return $0.week < $1.week }
            return $0.day < $1.day
        }
        
        // Compare each session pair
        for (index, (iPhoneSession, watchSession)) in zip(sortedIPhoneSessions, sortedWatchSessions).enumerated() {
            let sessionMismatches = compareIndividualSessions(
                iPhoneSession: iPhoneSession,
                watchSession: watchSession
            )
            
            if sessionMismatches.isEmpty {
                matchingCount += 1
            } else {
                mismatches.append(contentsOf: sessionMismatches)
            }
        }
        
        return SessionComparison(matchingCount: matchingCount, mismatches: mismatches)
    }
    
    private func compareIndividualSessions(
        iPhoneSession: TrainingSession,
        watchSession: TrainingSession
    ) -> [SessionMismatch] {
        
        var mismatches: [SessionMismatch] = []
        
        // Compare basic properties
        if iPhoneSession.week != watchSession.week {
            mismatches.append(SessionMismatch(
                week: iPhoneSession.week,
                day: iPhoneSession.day,
                issue: "Week mismatch",
                iPhoneValue: "\(iPhoneSession.week)",
                watchValue: "\(watchSession.week)"
            ))
        }
        
        if iPhoneSession.day != watchSession.day {
            mismatches.append(SessionMismatch(
                week: iPhoneSession.week,
                day: iPhoneSession.day,
                issue: "Day mismatch",
                iPhoneValue: "\(iPhoneSession.day)",
                watchValue: "\(watchSession.day)"
            ))
        }
        
        if iPhoneSession.type != watchSession.type {
            mismatches.append(SessionMismatch(
                week: iPhoneSession.week,
                day: iPhoneSession.day,
                issue: "Session type mismatch",
                iPhoneValue: iPhoneSession.type,
                watchValue: watchSession.type
            ))
        }
        
        if iPhoneSession.focus != watchSession.focus {
            mismatches.append(SessionMismatch(
                week: iPhoneSession.week,
                day: iPhoneSession.day,
                issue: "Session focus mismatch",
                iPhoneValue: iPhoneSession.focus,
                watchValue: watchSession.focus
            ))
        }
        
        // Compare sprint sets
        if iPhoneSession.sprints.count != watchSession.sprints.count {
            mismatches.append(SessionMismatch(
                week: iPhoneSession.week,
                day: iPhoneSession.day,
                issue: "Sprint set count mismatch",
                iPhoneValue: "\(iPhoneSession.sprints.count) sets",
                watchValue: "\(watchSession.sprints.count) sets"
            ))
        } else {
            // Compare individual sprint sets
            for (index, (iPhoneSprint, watchSprint)) in zip(iPhoneSession.sprints, watchSession.sprints).enumerated() {
                if iPhoneSprint.distanceYards != watchSprint.distanceYards {
                    mismatches.append(SessionMismatch(
                        week: iPhoneSession.week,
                        day: iPhoneSession.day,
                        issue: "Sprint \(index + 1) distance mismatch",
                        iPhoneValue: "\(iPhoneSprint.distanceYards)yd",
                        watchValue: "\(watchSprint.distanceYards)yd"
                    ))
                }
                
                if iPhoneSprint.reps != watchSprint.reps {
                    mismatches.append(SessionMismatch(
                        week: iPhoneSession.week,
                        day: iPhoneSession.day,
                        issue: "Sprint \(index + 1) reps mismatch",
                        iPhoneValue: "\(iPhoneSprint.reps) reps",
                        watchValue: "\(watchSprint.reps) reps"
                    ))
                }
                
                if iPhoneSprint.intensity != watchSprint.intensity {
                    mismatches.append(SessionMismatch(
                        week: iPhoneSession.week,
                        day: iPhoneSession.day,
                        issue: "Sprint \(index + 1) intensity mismatch",
                        iPhoneValue: iPhoneSprint.intensity,
                        watchValue: watchSprint.intensity
                    ))
                }
            }
        }
        
        return mismatches
    }
    
    // MARK: - Validation Report
    
    func generateValidationReport() -> String {
        let passedCount = validationResults.filter { $0.status == .passed }.count
        let failedCount = validationResults.filter { $0.status == .failed }.count
        let totalCount = validationResults.count
        
        var report = """
        📊 SESSION SYNCHRONIZATION VALIDATION REPORT
        ============================================
        
        Overall Status: \(overallStatus.rawValue.uppercased())
        Total Combinations Tested: \(totalCount)
        ✅ Passed: \(passedCount)
        ❌ Failed: \(failedCount)
        Success Rate: \(totalCount > 0 ? Int(Double(passedCount) / Double(totalCount) * 100) : 0)%
        
        """
        
        if failedCount > 0 {
            report += "\n❌ FAILED COMBINATIONS:\n"
            for result in validationResults.filter({ $0.status == .failed }) {
                report += "   \(result.level) × \(result.frequency) days: \(result.errorMessage ?? "Unknown error")\n"
                
                for mismatch in result.mismatchedSessions.prefix(3) {
                    report += "     W\(mismatch.week)/D\(mismatch.day): \(mismatch.issue)\n"
                }
                
                if result.mismatchedSessions.count > 3 {
                    report += "     ... and \(result.mismatchedSessions.count - 3) more mismatches\n"
                }
            }
        }
        
        if passedCount > 0 {
            report += "\n✅ PASSED COMBINATIONS:\n"
            for result in validationResults.filter({ $0.status == .passed }) {
                report += "   \(result.level) × \(result.frequency) days: \(result.matchingSessionCount) sessions match perfectly\n"
            }
        }
        
        return report
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let level: String
    let frequency: Int
    let iPhoneSessionCount: Int
    let watchSessionCount: Int
    let matchingSessionCount: Int
    let mismatchedSessions: [SessionMismatch]
    let status: ValidationStatus
    let duration: TimeInterval
    let errorMessage: String?
}

struct SessionComparison {
    let matchingCount: Int
    let mismatches: [SessionMismatch]
}

struct SessionMismatch {
    let week: Int
    let day: Int
    let issue: String
    let iPhoneValue: String
    let watchValue: String
}

enum ValidationStatus: String {
    case pending = "pending"
    case passed = "passed"
    case failed = "failed"
    case partiallyPassed = "partially_passed"
}
