import Foundation
import SwiftUI
import Combine

// MARK: - Training Preferences Workflow System
// Handles user training preference submissions and generates personalized 12-week plans

class TrainingPreferencesWorkflow: ObservableObject {
    
    @Published var isProcessing = false
    @Published var workflowStatus: WorkflowStatus = .idle
    @Published var generatedPlan: TrainingPlan?
    
    enum WorkflowStatus {
        case idle
        case validating
        case allocatingSchedule
        case fetchingSessions
        case generatingPlan
        case storingPlan
        case completed
        case error(String)
    }
    
    // MARK: - Main Workflow Trigger
    
    /// Triggered when user submits training preferences (level, days_per_week)
    func handleTrainingPreferencesSubmitted(
        userId: String,
        level: String,
        daysPerWeek: Int,
        userProfileVM: UserProfileViewModel
    ) async {
        await MainActor.run {
            isProcessing = true
            workflowStatus = .validating
        }
        
        do {
            // Step 1: Validate inputs
            try await validateInputs(level: level, daysPerWeek: daysPerWeek)
            
            // Step 2: Allocate schedule
            let schedule = try await allocateSchedule(daysPerWeek: daysPerWeek)
            
            // Step 3: Fetch sessions based on level
            await MainActor.run { workflowStatus = .fetchingSessions }
            let sessions = try await fetchSessions(level: level)
            
            // Step 4: Generate personalized plan
            await MainActor.run { workflowStatus = .generatingPlan }
            let plan = try await generatePlan(
                userId: userId,
                level: level,
                daysPerWeek: daysPerWeek,
                schedule: schedule,
                sessions: sessions
            )
            
            // Step 5: Store plan
            await MainActor.run { workflowStatus = .storingPlan }
            try await storePlan(userId: userId, plan: plan)
            
            // Step 6: Update user profile
            await MainActor.run {
                userProfileVM.profile.level = level
                userProfileVM.profile.frequency = daysPerWeek
                userProfileVM.profile.currentWeek = 1
                userProfileVM.profile.currentDay = 1
                generatedPlan = plan
                workflowStatus = .completed
                isProcessing = false
            }
            
            // Step 7: Notify user
            await notifyUser(message: "Your 12-week Sprint Plan is live!")
            
            print("✅ Training Preferences Workflow Completed Successfully")
            
        } catch {
            await MainActor.run {
                workflowStatus = .error(error.localizedDescription)
                isProcessing = false
            }
            print("❌ Training Preferences Workflow Failed: \(error)")
        }
    }
    
    // MARK: - Workflow Steps Implementation
    
    /// Step 1: Validate user inputs
    private func validateInputs(level: String, daysPerWeek: Int) async throws {
        await MainActor.run { workflowStatus = .validating }
        
        // Validate level
        let validLevels = ["beginner", "intermediate", "advanced", "elite"]
        guard validLevels.contains(level.lowercased()) else {
            throw WorkflowError.invalidLevel("Level must be one of: \(validLevels.joined(separator: ", "))")
        }
        
        // Validate days per week
        guard daysPerWeek >= 1 && daysPerWeek <= 7 else {
            throw WorkflowError.invalidDaysPerWeek("Days per week must be between 1 and 7")
        }
        
        // Simulate validation processing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        print("✅ Inputs validated: Level=\(level), Days=\(daysPerWeek)")
    }
    
    /// Step 2: Allocate training schedule
    private func allocateSchedule(daysPerWeek: Int) async throws -> TrainingSchedule {
        await MainActor.run { workflowStatus = .allocatingSchedule }
        
        // Generate optimal training schedule based on frequency
        let schedule = TrainingSchedule.generateOptimalSchedule(daysPerWeek: daysPerWeek)
        
        // Simulate schedule allocation processing
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        print("✅ Schedule allocated: \(daysPerWeek) days/week pattern")
        return schedule
    }
    
    /// Step 3: Fetch sessions based on user level
    private func fetchSessions(level: String) async throws -> [WorkflowSessionTemplate] {
        // Simulate fetching sessions from session library
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let sessions = SessionLibrary.getSessionsForLevel(level: level)
        
        print("✅ Fetched \(sessions.count) sessions for \(level) level")
        return sessions
    }
    
    /// Step 4: Generate personalized 12-week plan
    private func generatePlan(
        userId: String,
        level: String,
        daysPerWeek: Int,
        schedule: TrainingSchedule,
        sessions: [WorkflowSessionTemplate]
    ) async throws -> TrainingPlan {
        
        // Generate comprehensive 12-week plan
        let planGenerator = TrainingPlanGenerator()
        let plan = try await planGenerator.generatePlan(
            userId: userId,
            level: level,
            daysPerWeek: daysPerWeek,
            schedule: schedule,
            sessions: sessions
        )
        
        print("✅ Generated 12-week plan with \(plan.totalSessions) sessions")
        return plan
    }
    
    /// Step 5: Store plan in user's profile
    private func storePlan(userId: String, plan: TrainingPlan) async throws {
        // Simulate storing plan to persistent storage
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // In a real app, this would save to Core Data, UserDefaults, or cloud storage
        UserDefaults.standard.set(try JSONEncoder().encode(plan), forKey: "trainingPlan_\(userId)")
        
        print("✅ Plan stored for user: \(userId)")
    }
    
    /// Step 6: Notify user of completion
    private func notifyUser(message: String) async {
        // Send local notification
        await WorkflowNotificationManager.shared.sendLocalNotification(
            title: "Sprint Coach 40",
            body: message,
            identifier: "training_plan_ready"
        )
        
        // Show in-app notification
        await MainActor.run {
            NotificationCenter.default.post(
                name: .trainingPlanGenerated,
                object: nil,
                userInfo: ["message": message]
            )
        }
        
        print("✅ User notified: \(message)")
    }
}

// MARK: - Supporting Models

struct TrainingSchedule: Codable {
    let daysPerWeek: Int
    let restDays: [Int] // Day indices for rest days (0 = Sunday)
    let trainingDays: [Int] // Day indices for training days
    let sessionPattern: [String] // Session types for each training day
    
    static func generateOptimalSchedule(daysPerWeek: Int) -> TrainingSchedule {
        switch daysPerWeek {
        case 1:
            return TrainingSchedule(
                daysPerWeek: 1,
                restDays: [0, 1, 2, 4, 5, 6],
                trainingDays: [3], // Wednesday
                sessionPattern: ["Speed"]
            )
        case 2:
            return TrainingSchedule(
                daysPerWeek: 2,
                restDays: [0, 2, 4, 6],
                trainingDays: [1, 5], // Monday, Friday
                sessionPattern: ["Acceleration", "Speed"]
            )
        case 3:
            return TrainingSchedule(
                daysPerWeek: 3,
                restDays: [0, 3, 6],
                trainingDays: [1, 2, 5], // Monday, Tuesday, Friday
                sessionPattern: ["Acceleration", "Technique", "Speed"]
            )
        case 4:
            return TrainingSchedule(
                daysPerWeek: 4,
                restDays: [0, 3, 6],
                trainingDays: [1, 2, 4, 5], // Monday, Tuesday, Thursday, Friday
                sessionPattern: ["Acceleration", "Technique", "Power", "Speed"]
            )
        case 5:
            return TrainingSchedule(
                daysPerWeek: 5,
                restDays: [0, 6],
                trainingDays: [1, 2, 3, 4, 5], // Monday-Friday
                sessionPattern: ["Acceleration", "Technique", "Power", "Speed", "Recovery"]
            )
        case 6:
            return TrainingSchedule(
                daysPerWeek: 6,
                restDays: [0],
                trainingDays: [1, 2, 3, 4, 5, 6], // Monday-Saturday
                sessionPattern: ["Acceleration", "Technique", "Power", "Speed", "Endurance", "Recovery"]
            )
        case 7:
            return TrainingSchedule(
                daysPerWeek: 7,
                restDays: [],
                trainingDays: [0, 1, 2, 3, 4, 5, 6], // Every day
                sessionPattern: ["Recovery", "Acceleration", "Technique", "Power", "Speed", "Endurance", "Active Recovery"]
            )
        default:
            return generateOptimalSchedule(daysPerWeek: 3) // Default to 3 days
        }
    }
}

struct WorkflowSessionTemplate: Codable {
    let id: Int
    let name: String
    let type: String
    let level: String
    let distance: Int
    let reps: Int
    let intensity: String
    let restTime: Int
    let focus: String
}

struct TrainingPlan: Codable {
    let id: String
    let userId: String
    let level: String
    let daysPerWeek: Int
    let schedule: TrainingSchedule
    let weeks: [WeekPlan]
    let totalSessions: Int
    let createdAt: Date
    
    struct WeekPlan: Codable {
        let weekNumber: Int
        let sessions: [WorkflowSessionTemplate]
        let focus: String
        let notes: String
    }
}

// MARK: - Session Library Integration

class SessionLibrary {
    static func getSessionsForLevel(level: String) -> [WorkflowSessionTemplate] {
        // This would integrate with the existing ComprehensiveSessionLibrary
        switch level.lowercased() {
        case "beginner":
            return generateBeginnerSessions()
        case "intermediate":
            return generateIntermediateSessions()
        case "advanced":
            return generateAdvancedSessions()
        case "elite":
            return generateEliteSessions()
        default:
            return generateBeginnerSessions()
        }
    }
    
    private static func generateBeginnerSessions() -> [WorkflowSessionTemplate] {
        return [
            WorkflowSessionTemplate(id: 1, name: "10 yd Starts", type: "Acceleration", level: "Beginner", distance: 10, reps: 8, intensity: "moderate", restTime: 60, focus: "First Step"),
            WorkflowSessionTemplate(id: 2, name: "20 yd Accel", type: "Acceleration", level: "Beginner", distance: 20, reps: 6, intensity: "moderate", restTime: 90, focus: "Drive Phase"),
            WorkflowSessionTemplate(id: 3, name: "30 yd Speed", type: "Speed", level: "Beginner", distance: 30, reps: 4, intensity: "high", restTime: 120, focus: "Top Speed"),
            WorkflowSessionTemplate(id: 4, name: "Technique Work", type: "Technique", level: "Beginner", distance: 25, reps: 3, intensity: "moderate", restTime: 90, focus: "Form")
        ]
    }
    
    private static func generateIntermediateSessions() -> [WorkflowSessionTemplate] {
        return [
            WorkflowSessionTemplate(id: 11, name: "25 yd Accel", type: "Acceleration", level: "Intermediate", distance: 25, reps: 5, intensity: "high", restTime: 90, focus: "Drive Phase"),
            WorkflowSessionTemplate(id: 12, name: "40 yd Speed", type: "Speed", level: "Intermediate", distance: 40, reps: 4, intensity: "max", restTime: 180, focus: "Max Velocity"),
            WorkflowSessionTemplate(id: 13, name: "50 yd Endurance", type: "Speed Endurance", level: "Intermediate", distance: 50, reps: 3, intensity: "high", restTime: 240, focus: "Conditioning"),
            WorkflowSessionTemplate(id: 14, name: "Power Development", type: "Power", level: "Intermediate", distance: 30, reps: 4, intensity: "max", restTime: 180, focus: "Explosive Power")
        ]
    }
    
    private static func generateAdvancedSessions() -> [WorkflowSessionTemplate] {
        return [
            WorkflowSessionTemplate(id: 21, name: "30 yd Power", type: "Power", level: "Advanced", distance: 30, reps: 6, intensity: "max", restTime: 180, focus: "Explosive Starts"),
            WorkflowSessionTemplate(id: 22, name: "40 yd Max Speed", type: "Speed", level: "Advanced", distance: 40, reps: 5, intensity: "max", restTime: 240, focus: "Top Speed"),
            WorkflowSessionTemplate(id: 23, name: "60 yd Endurance", type: "Speed Endurance", level: "Advanced", distance: 60, reps: 4, intensity: "high", restTime: 300, focus: "Lactate Tolerance"),
            WorkflowSessionTemplate(id: 24, name: "Recovery Run", type: "Recovery", level: "Advanced", distance: 20, reps: 2, intensity: "easy", restTime: 120, focus: "Active Recovery")
        ]
    }
    
    private static func generateEliteSessions() -> [WorkflowSessionTemplate] {
        return [
            WorkflowSessionTemplate(id: 31, name: "35 yd Power", type: "Power", level: "Elite", distance: 35, reps: 6, intensity: "max", restTime: 240, focus: "Maximum Power"),
            WorkflowSessionTemplate(id: 32, name: "40 yd Peak Speed", type: "Speed", level: "Elite", distance: 40, reps: 5, intensity: "max", restTime: 300, focus: "Peak Velocity"),
            WorkflowSessionTemplate(id: 33, name: "Competition Sim", type: "Competition", level: "Elite", distance: 40, reps: 3, intensity: "race", restTime: 360, focus: "Race Prep"),
            WorkflowSessionTemplate(id: 34, name: "75 yd Conditioning", type: "Speed Endurance", level: "Elite", distance: 75, reps: 3, intensity: "high", restTime: 400, focus: "Elite Conditioning")
        ]
    }
}

// MARK: - Training Plan Generator

class TrainingPlanGenerator {
    func generatePlan(
        userId: String,
        level: String,
        daysPerWeek: Int,
        schedule: TrainingSchedule,
        sessions: [WorkflowSessionTemplate]
    ) async throws -> TrainingPlan {
        
        // Simulate plan generation processing
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        var weeks: [TrainingPlan.WeekPlan] = []
        
        // Generate 12 weeks of training
        for weekNumber in 1...12 {
            let weekSessions = selectSessionsForWeek(
                weekNumber: weekNumber,
                schedule: schedule,
                availableSessions: sessions,
                level: level
            )
            
            let weekPlan = TrainingPlan.WeekPlan(
                weekNumber: weekNumber,
                sessions: weekSessions,
                focus: getWeekFocus(weekNumber: weekNumber),
                notes: getWeekNotes(weekNumber: weekNumber, level: level)
            )
            
            weeks.append(weekPlan)
        }
        
        let totalSessions = weeks.reduce(0) { $0 + $1.sessions.count }
        
        return TrainingPlan(
            id: UUID().uuidString,
            userId: userId,
            level: level,
            daysPerWeek: daysPerWeek,
            schedule: schedule,
            weeks: weeks,
            totalSessions: totalSessions,
            createdAt: Date()
        )
    }
    
    private func selectSessionsForWeek(
        weekNumber: Int,
        schedule: TrainingSchedule,
        availableSessions: [WorkflowSessionTemplate],
        level: String
    ) -> [WorkflowSessionTemplate] {
        
        var weekSessions: [WorkflowSessionTemplate] = []
        
        // Select sessions based on schedule pattern
        for (dayIndex, sessionType) in schedule.sessionPattern.enumerated() {
            if dayIndex < schedule.daysPerWeek {
                if let session = availableSessions.first(where: { $0.type == sessionType }) {
                    weekSessions.append(session)
                }
            }
        }
        
        return weekSessions
    }
    
    private func getWeekFocus(weekNumber: Int) -> String {
        switch weekNumber {
        case 1...3: return "Foundation & Mechanics"
        case 4...6: return "Acceleration Development"
        case 7...9: return "Velocity Development"
        case 10...12: return "Peak Performance"
        default: return "Progressive Training"
        }
    }
    
    private func getWeekNotes(weekNumber: Int, level: String) -> String {
        let levelPrefix = level.capitalized
        
        switch weekNumber {
        case 1: return "\(levelPrefix): Focus on proper form and technique foundation"
        case 4: return "\(levelPrefix): Begin intensive acceleration work"
        case 7: return "\(levelPrefix): Develop maximum velocity capabilities"
        case 10: return "\(levelPrefix): Peak performance and competition preparation"
        default: return "\(levelPrefix): Continue progressive development"
        }
    }
}

// MARK: - Workflow Notification Manager

class WorkflowNotificationManager {
    static let shared = WorkflowNotificationManager()
    
    func sendLocalNotification(title: String, body: String, identifier: String) async {
        // Implementation would use UNUserNotificationCenter
        print("📱 Local Notification: \(title) - \(body)")
    }
}

// MARK: - Workflow Errors

enum WorkflowError: LocalizedError {
    case invalidLevel(String)
    case invalidDaysPerWeek(String)
    case planGenerationFailed(String)
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidLevel(let message): return message
        case .invalidDaysPerWeek(let message): return message
        case .planGenerationFailed(let message): return message
        case .storageError(let message): return message
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let trainingPlanGenerated = Notification.Name("trainingPlanGenerated")
}
