import Foundation
import Combine
import SwiftUI

// Removed legacy SessionFeedback definition. Use canonical struct from Models/SessionFeedback.swift.

func phase(for week: Int) -> String {
    switch week {
    case 1...4: return "Foundation"
    case 5...8: return "Development"
    case 9...12: return "Performance"
    default: return "Unknown"
    }
}

func drillsFor(level: String, phase: String) -> [String] {
    if phase == "Foundation" { return ["A-Skip", "Wall Drill"] }
    if phase == "Development" { return ["B-Skip", "Resisted Sprints"] }
    return ["Contrast Jumps", "Flying Sprints"]
}

// Remove sprintsFor, not needed with canonical model

func generateSession(for profile: UserProfile) -> TrainingSession {
    let type = profile.level.capitalized
    let focus = "Sprint/Drill Focus"
    let sprints = [SprintSet(distanceYards: 20, reps: 4, intensity: "moderate")]
    let accessoryWork = ["A-Skip", "Wall Drill"]
    let notes: String? = nil
    return TrainingSession(
        week: profile.currentWeek,
        day: profile.currentDay,
        type: type,
        focus: focus,
        sprints: sprints,
        accessoryWork: accessoryWork,
        notes: notes
    )
}

func adjustSession(profile: inout UserProfile, lastFeedback: SessionFeedback) {
    // This function can be refactored to use notes or accessoryWork for feedback if needed
}

// MARK: - 21 Pathways Phase Rotation Logic
private func phaseRotation(level: String, daysPerWeek: Int, week: Int, day: Int) -> [String] {
    let phases = ["S", "A", "T", "F"]
    let plyo = "P"
    let recovery = "Recovery"
    let strength = "Strength"
    let mobility = "Mobility"
    if daysPerWeek == 1 {
        return [phases[(week-1)%4]]
    }
    if daysPerWeek == 2 {
        return day == 1 ? ["S", "A"] : ["T", "F"]
    }
    if daysPerWeek == 3 {
        if day == 1 { return [phases[(week-1)%4]] }
        if day == 2 { return [plyo] }
        return [phases[(week)%4]]
    }
    if daysPerWeek == 4 {
        return [phases[(day-1)%4]]
    }
    if daysPerWeek >= 5 {
        switch day {
        case 1: return ["S"]
        case 2: return ["A"]
        case 3: return ["T"]
        case 4: return ["F"]
        case 5: return [recovery]
        case 6: return [strength]
        case 7: return [mobility]
        default: return [phases[(day-1)%4]]
        }
    }
    return ["S"]
}

// MARK: - 12-Week Training Matrix Generator
// Utility: Generate a set of distances for a session (e.g., 10, 20, 30, 40, 50 yd)
private func variedDistances(for base: Int, count: Int) -> [Int] {
    return (0..<count).map { base + $0 * 10 }
}

func generateTrainingMatrix(level: String, pb: Double, daysPerWeek: Int, previousSessions: [TrainingSession] = [], fatigueHistory: [Int] = [], pbHistory: [Double] = []) -> [TrainingSession] {
    let mesocycles = [
        (name: "Foundation", weeks: 1...4, focus: "Technique & Base"),
        (name: "Development", weeks: 5...8, focus: "Speed & Power"),
        (name: "Performance", weeks: 9...12, focus: "Max Velocity & Peaking")
    ]
    let drillLibrary: [String: [String]] = [
        "Acceleration": ["A-Skip", "Wall Drill", "Falling Start", "3-Point Start"],
        "Speed Endurance": ["Flying 20s", "Tempo Runs", "Split Runs"],
        "Technique": ["B-Skip", "High Knees", "Butt Kicks"],
        "Plyometrics": ["Bounding", "Hops", "Depth Jumps"],
        "Recovery": ["Mobility/Stretch", "Foam Roll", "Light Jog"],
        "Strength": ["Med Ball Throws", "Bodyweight Circuit"]
    ]
    let sessionTypes = ["Acceleration", "Speed Endurance", "Technique", "Plyometrics", "Recovery", "Strength"]
    var sessions: [TrainingSession] = []
    let fatigueRolling = fatigueHistory.suffix(3)
    let pbRolling = pbHistory.suffix(3)
    let sprintDrillTypes = ["Acceleration", "Speed Endurance", "Technique", "Plyometrics"]
    for week in 1...12 {
        let mesocycle = mesocycles.first { $0.weeks.contains(week) } ?? mesocycles[0]
        for day in 1...daysPerWeek {
            let isMilestone = (week == 4 || week == 8 || week == 12) && day == 1
            let plateau = pbRolling.count == 3 && (pbRolling.max()! - pbRolling.min()! < 0.05)
            let highFatigue = fatigueRolling.filter { $0 >= 8 }.count >= 2
            var sessionType = sessionTypes[(week + day) % sessionTypes.count]
            if isMilestone { sessionType = "Test" }
            if highFatigue { sessionType = "Recovery" }
            if plateau { sessionType = "Technique" }
            // Only include accessory work for sprint-relevant sessions
            let drills: [String]
            if sprintDrillTypes.contains(sessionType) {
                drills = Array((drillLibrary[sessionType] ?? ["Custom"]).shuffled().prefix(2))
            } else {
                drills = []
            }
            let focus = drills.joined(separator: ", ")
            let baseDistance = 40
            let sprintSet = SprintSet(distanceYards: baseDistance, reps: isMilestone ? 1 : 4 + week/4, intensity: isMilestone ? "test" : "max")
            let accessoryWork = drills
            let notes = isMilestone ? "Milestone test: Go all out and record your time!" : "Focus: \(mesocycle.focus)"
            sessions.append(TrainingSession(
                week: week,
                day: day,
                type: sessionType,
                focus: focus,
                sprints: [sprintSet],
                accessoryWork: accessoryWork,
                notes: notes
            ))
        }
    }
    return sessions
}

func applyDynamicAdjustments(profile: UserProfile, basePlan: [TrainingSession]) -> [TrainingSession] {
    // This function can be refactored to use notes or accessoryWork for feedback if needed
    return basePlan
}

func refreshUpcomingSessions(profile: inout UserProfile) {
    // Updated to work with UUID-based session storage
    let completedCount = profile.completedSessionIDs.count
    let totalSessions = profile.sessionIDs.count
    let remainingSessions = totalSessions - completedCount
    guard remainingSessions > 0 else { return }
    let _: [Int] = [] // fatigueHistory - unused for now
    let _: [Double] = [] // pbHistory - unused for now
    
    // Generate new training plan if needed
    // Note: This function may need additional logic to handle UUID-based session management
    // For now, we'll maintain the basic structure
}
