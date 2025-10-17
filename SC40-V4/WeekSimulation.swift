#!/usr/bin/env swift

import Foundation

// Simulate a Beginner's 7-Day Training Week
print("🏃‍♂️ SC40-V3: Beginner 7-Day Training Week Simulation")
print("═══════════════════════════════════════════════════════")

// Mock SessionLibrary data structures
struct SprintSessionTemplate {
    let id: Int
    let name: String
    let distance: Int
    let reps: Int
    let rest: Int
    let focus: String
    let level: String
    
    var totalYardage: Int { distance * reps }
    var restMinutes: Double { Double(rest) / 60.0 }
}

enum SessionType {
    case sprint, benchmark, activeRecovery, rest
}

struct DaySession {
    let day: Int
    let type: SessionType
    let session: SprintSessionTemplate?
    let notes: String
    
    var description: String {
        switch type {
        case .sprint:
            guard let s = session else { return "Sprint session" }
            return "💨 SPRINT - \(s.name)\n    └── \(s.reps)x\(s.distance)yd @ max effort, \(s.restMinutes)min rest\n    └── Focus: \(s.focus)\n    └── Total: \(s.totalYardage) yards"
        case .benchmark:
            guard let s = session else { return "Benchmark session" }
            return "🏃‍♂️ BENCHMARK - \(s.name)\n    └── \(s.reps)x\(s.distance)yd @ test effort, \(s.restMinutes)min rest\n    └── \(notes)"
        case .activeRecovery:
            guard let s = session else { return "Active recovery" }
            return "🧘‍♂️ ACTIVE RECOVERY - \(s.name)\n    └── \(s.reps)x\(s.distance)yd @ 70% effort, \(s.restMinutes)min rest\n    └── Light tempo work"
        case .rest:
            return "🛌 REST DAY - Complete rest\n    └── No training - recovery and adaptation"
        }
    }
}

// Beginner sessions from SessionLibrary (IDs 1-50 approximately)
let beginnerSessions: [SprintSessionTemplate] = [
    SprintSessionTemplate(id: 1, name: "10 yd Starts", distance: 10, reps: 8, rest: 60, focus: "Acceleration", level: "Beginner"),
    SprintSessionTemplate(id: 3, name: "20 yd Accel", distance: 20, reps: 6, rest: 90, focus: "Early Acceleration", level: "Beginner"),
    SprintSessionTemplate(id: 5, name: "30 yd Build-Up", distance: 30, reps: 5, rest: 120, focus: "Drive Phase", level: "Beginner"),
    SprintSessionTemplate(id: 7, name: "40 yd Repeats", distance: 40, reps: 6, rest: 150, focus: "Max Speed", level: "Beginner"),
    SprintSessionTemplate(id: 186, name: "Beginner 5-10-15 yd Pyramid", distance: 15, reps: 3, rest: 90, focus: "Acceleration Progression", level: "Beginner"),
    SprintSessionTemplate(id: 187, name: "Beginner 10-15-20 yd Pyramid", distance: 20, reps: 3, rest: 100, focus: "Speed Build-Up", level: "Beginner"),
    SprintSessionTemplate(id: 52, name: "20 yd Tempo", distance: 20, reps: 4, rest: 60, focus: "Active Recovery", level: "Beginner"),
    SprintSessionTemplate(id: 8, name: "40 yd Time Trial", distance: 40, reps: 3, rest: 300, focus: "Benchmark Test", level: "Beginner")
]

// Foundation phase sessions (weeks 1-3 focus on acceleration/starts)
let foundationSessions = beginnerSessions.filter { 
    $0.focus.lowercased().contains("acceleration") || 
    $0.focus.lowercased().contains("accel") || 
    $0.focus.lowercased().contains("starts") ||
    $0.focus.lowercased().contains("drive") ||
    $0.focus.lowercased().contains("progression")
}

let activeRecoverySession = beginnerSessions.first { $0.name.contains("Tempo") }!
let benchmarkSession = beginnerSessions.first { $0.focus.contains("Benchmark") }!

// Weekly program generation simulation
func generateBeginnerWeek() -> [DaySession] {
    var weekProgram: [DaySession] = []
    var consecutiveTrainingDays = 0
    let totalDays = 7
    let weekNumber = 1 // Week 1
    
    // Simulate session selection (shuffled foundation sessions)
    var availableSessions = foundationSessions.shuffled()
    var sessionIndex = 0
    
    for day in 1...totalDays {
        
        // Rest/recovery logic with consecutive day tracking (5-day rule)
        if consecutiveTrainingDays >= 5 {
            if day == 7 { // Rest on day 7 after 5+ consecutive days
                weekProgram.append(DaySession(day: day, type: .rest, session: nil, notes: "Complete rest day"))
                consecutiveTrainingDays = 0
            } else {
                weekProgram.append(DaySession(day: day, type: .activeRecovery, session: activeRecoverySession, notes: "Light tempo work"))
                consecutiveTrainingDays = 0
            }
        } else {
            // Check for benchmark on last day (if not time trial week)
            let isTimeTrialWeek = (weekNumber % 4 == 0) // Every 4th week
            
            if day == totalDays && !isTimeTrialWeek {
                // Benchmark session on last day
                weekProgram.append(DaySession(day: day, type: .benchmark, session: benchmarkSession, notes: "Week 1 assessment"))
                consecutiveTrainingDays += 1
            } else if sessionIndex < availableSessions.count {
                // Regular sprint session
                let selectedSession = availableSessions[sessionIndex]
                weekProgram.append(DaySession(day: day, type: .sprint, session: selectedSession, notes: "Foundation phase training"))
                sessionIndex += 1
                consecutiveTrainingDays += 1
            }
        }
    }
    
    return weekProgram
}

// Generate and display the week
let weekProgram = generateBeginnerWeek()

print("Level: Beginner")
print("Training Frequency: 7 days/week") 
print("Week: 1 (Foundation Phase)")
print("Focus: Acceleration, Drive Phase, Early Development")
print("")

for daySession in weekProgram {
    print("Day \(daySession.day):")
    print(daySession.description)
    print("")
}

// Calculate weekly totals
let sprintSessions = weekProgram.filter { $0.type == .sprint }
let totalYardage = sprintSessions.compactMap { $0.session?.totalYardage }.reduce(0, +)
let trainingDays = weekProgram.filter { $0.type == .sprint || $0.type == .benchmark }.count

print("📊 WEEKLY SUMMARY")
print("═══════════════════")
print("• Total Training Days: \(trainingDays)")
print("• Sprint Sessions: \(sprintSessions.count)")
print("• Benchmark Sessions: \(weekProgram.filter { $0.type == .benchmark }.count)")
print("• Active Recovery Days: \(weekProgram.filter { $0.type == .activeRecovery }.count)")
print("• Rest Days: \(weekProgram.filter { $0.type == .rest }.count)")
print("• Total Sprint Yardage: \(totalYardage) yards")
print("• Average per Training Day: \(totalYardage / max(trainingDays, 1)) yards")
print("• Phase Focus: Foundation (Acceleration & Drive Development)")

print("\n🔄 COMPLETE WORKOUT FLOW EXAMPLE")
print("═══════════════════════════════════")
print("Each session includes:")
print("• Warmup: 440yd jog (¼ mile)")
print("• Dynamic stretching: 5-8 minutes")
print("• Sprint drills: 3x20yd (High knees, A-skips, B-skips)")
print("• Strides: 4x20yd @ 80% effort")
print("• Main Sprint Set: [As shown above]")
print("• Cooldown: 400yd easy jog")
print("• Static stretching: 5-10 minutes")
print("")
print("Total Workout Time: 35-45 minutes per session")
print("Total Weekly Volume: ~980-1400 yards including warmup/cooldown")
