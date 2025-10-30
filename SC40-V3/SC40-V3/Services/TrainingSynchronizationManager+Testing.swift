import Foundation
import SwiftUI
import os

// MARK: - TrainingSynchronizationManager Testing Extensions

extension TrainingSynchronizationManager {
    
    // MARK: - Testing Support Methods
    
    /// Clears all active sessions for testing purposes
    func clearActiveSessions() async {
        await MainActor.run {
            self.activeSessions.removeAll()
            self.sessionProgress.removeAll()
            self.currentCompilationID = nil
            self.isPhoneSynced = false
            self.isWatchSynced = false
        }
        
        logger.info("🧪 Test: Cleared all active sessions")
    }
    
    /// Forces a complete re-sync for testing
    func forceResync(level: TrainingLevel, days: Int) async {
        await clearActiveSessions()
        await synchronizeTrainingProgram(level: level, days: days)
        
        logger.info("🧪 Test: Forced complete re-sync for \(level.label) × \(days) days")
    }
    
    /// Validates the current state matches expected values
    func validateState(expectedLevel: TrainingLevel, expectedDays: Int) -> TrainingSyncValidationResult {
        var issues: [String] = []
        
        // Check level
        if selectedLevel != expectedLevel {
            issues.append("Level mismatch: expected \(expectedLevel.label), got \(selectedLevel.label)")
        }
        
        // Check days
        if selectedDays != expectedDays {
            issues.append("Days mismatch: expected \(expectedDays), got \(selectedDays)")
        }
        
        // Check session count
        let expectedSessionCount = expectedDays * 12
        if activeSessions.count != expectedSessionCount {
            issues.append("Session count mismatch: expected \(expectedSessionCount), got \(activeSessions.count)")
        }
        
        // Check compilation ID
        if currentCompilationID == nil {
            issues.append("Compilation ID is nil")
        }
        
        // Check sync states
        if !isPhoneSynced {
            issues.append("Phone not synced")
        }
        
        return TrainingSyncValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            level: selectedLevel,
            days: selectedDays,
            sessionCount: activeSessions.count,
            compilationID: currentCompilationID,
            isPhoneSynced: isPhoneSynced,
            isWatchSynced: isWatchSynced
        )
    }
    
    /// Attempts to auto-fix common synchronization issues
    func attemptAutoFix(targetLevel: TrainingLevel, targetDays: Int) async -> AutoFixResult {
        let initialValidation = validateState(expectedLevel: targetLevel, expectedDays: targetDays)
        
        if initialValidation.isValid {
            return AutoFixResult(
                success: true,
                message: "No fix needed - state is already valid",
                appliedFixes: []
            )
        }
        
        var appliedFixes: [String] = []
        
        // Fix 1: Correct level and days if wrong
        if selectedLevel != targetLevel || selectedDays != targetDays {
            await MainActor.run {
                self.selectedLevel = targetLevel
                self.selectedDays = targetDays
            }
            appliedFixes.append("Corrected level and days")
        }
        
        // Fix 2: Regenerate sessions if count is wrong
        let expectedSessionCount = targetDays * 12
        if activeSessions.count != expectedSessionCount {
            let newSessions = await generateSessionModel(level: targetLevel, days: targetDays)
            await MainActor.run {
                self.activeSessions = newSessions
            }
            appliedFixes.append("Regenerated session model")
        }
        
        // Fix 3: Generate compilation ID if missing
        if currentCompilationID == nil {
            let newCompilationID = generateCompilationID(level: targetLevel, days: targetDays)
            await MainActor.run {
                self.currentCompilationID = newCompilationID
            }
            appliedFixes.append("Generated new compilation ID")
        }
        
        // Fix 4: Update sync states
        if !isPhoneSynced {
            await MainActor.run {
                self.isPhoneSynced = true
            }
            appliedFixes.append("Updated phone sync state")
        }
        
        // Fix 5: Initialize session progress if missing
        for session in activeSessions {
            if sessionProgress[session.id.uuidString] == nil {
                sessionProgress[session.id.uuidString] = SessionProgress(
                    isLocked: session.week > 1, // First week unlocked
                    isCompleted: false,
                    completionPercentage: 0.0
                )
            }
        }
        if !activeSessions.isEmpty && appliedFixes.count < 5 {
            appliedFixes.append("Initialized session progress")
        }
        
        // Validate after fixes
        let finalValidation = validateState(expectedLevel: targetLevel, expectedDays: targetDays)
        
        return AutoFixResult(
            success: finalValidation.isValid,
            message: finalValidation.isValid ? 
                "Auto-fix successful: \(appliedFixes.joined(separator: ", "))" :
                "Auto-fix failed: \(finalValidation.issues.joined(separator: ", "))",
            appliedFixes: appliedFixes
        )
    }
    
    /// Gets detailed diagnostic information for debugging
    func getDiagnosticInfo() -> DiagnosticInfo {
        return DiagnosticInfo(
            selectedLevel: selectedLevel,
            selectedDays: selectedDays,
            sessionCount: activeSessions.count,
            compilationID: currentCompilationID,
            isPhoneSynced: isPhoneSynced,
            isWatchSynced: isWatchSynced,
            sessionProgressCount: sessionProgress.count,
            supportedLevelsCount: supportedLevels.count,
            supportedDaysCount: supportedDays.count,
            lastSyncTimestamp: Date() // Could be tracked separately
        )
    }
    
    /// Simulates onboarding flow for testing
    func simulateOnboarding(level: TrainingLevel, days: Int) async -> OnboardingSimulationResult {
        let startTime = Date()
        
        // Step 1: Clear existing state
        await clearActiveSessions()
        
        // Step 2: Set user selections
        await MainActor.run {
            self.selectedLevel = level
            self.selectedDays = days
        }
        
        // Step 3: Generate compilation ID
        let compilationID = generateCompilationID(level: level, days: days)
        await MainActor.run {
            self.currentCompilationID = compilationID
        }
        
        // Step 4: Generate session model
        let sessions = await generateSessionModel(level: level, days: days)
        await MainActor.run {
            self.activeSessions = sessions
        }
        
        // Step 5: Initialize session progress
        for session in sessions {
            sessionProgress[session.id.uuidString] = SessionProgress(
                isLocked: session.week > 1,
                isCompleted: false,
                completionPercentage: 0.0
            )
        }
        
        // Step 6: Update sync states
        await MainActor.run {
            self.isPhoneSynced = true
            self.isWatchSynced = false // Would be updated by actual watch sync
        }
        
        // Step 7: Validate final state
        let validation = validateState(expectedLevel: level, expectedDays: days)
        let duration = Date().timeIntervalSince(startTime)
        
        return OnboardingSimulationResult(
            success: validation.isValid,
            duration: duration,
            compilationID: compilationID,
            sessionCount: sessions.count,
            validationResult: validation
        )
    }
}

// MARK: - Testing Support Types

struct TrainingSyncValidationResult {
    let isValid: Bool
    let issues: [String]
    let level: TrainingLevel?
    let days: Int
    let sessionCount: Int
    let compilationID: String?
    let isPhoneSynced: Bool
    let isWatchSynced: Bool
}

struct AutoFixResult {
    let success: Bool
    let message: String
    let appliedFixes: [String]
}

struct DiagnosticInfo {
    let selectedLevel: TrainingLevel?
    let selectedDays: Int
    let sessionCount: Int
    let compilationID: String?
    let isPhoneSynced: Bool
    let isWatchSynced: Bool
    let sessionProgressCount: Int
    let supportedLevelsCount: Int
    let supportedDaysCount: Int
    let lastSyncTimestamp: Date
}

struct OnboardingSimulationResult {
    let success: Bool
    let duration: TimeInterval
    let compilationID: String
    let sessionCount: Int
    let validationResult: TrainingSyncValidationResult
}
