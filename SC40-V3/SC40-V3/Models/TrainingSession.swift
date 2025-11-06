// import AdaptiveAI
// import NextWeekAI
// import ProgramModels
// import ProgramGenerator
import Foundation
import Combine

// Example: Generate a 12-week hybrid AI training program in Swift
// Updated: Generate a 12-week hybrid AI training program with dynamic reps, rest, and AI adjustments
func generateWeeklyProgram(options: ProgramOptions, weekNumber: Int) -> WeeklyProgram {
    var program: WeeklyProgram = []
    let dayPhases: [[Phase]] = {
        switch options.daysPerWeek {
        case 1: return [[.F]]
        case 2: return [[.S, .A], [.T, .F]]
        case 3: return [[.S], [.A, .T], [.F]]
        case 4: return [[.S], [.A], [.T, .F], [.AR]]
        case 5: return [[.S], [.A], [.T], [.F], [.O]]
        case 6: return [[.S], [.A], [.T], [.F], [.O], [.AR]]
        case 7: return [[.S], [.A], [.T], [.F], [.O], [.AR], [.R]]
        default: return [[.S, .A, .T, .F]]
        }
    }()
    for (i, phases) in dayPhases.enumerated() {
        let repsBase = 5 + weekNumber / 3 // Example: increase reps every 3 weeks
        let restBase = 90 - weekNumber * 2 // Example: decrease rest as weeks progress
        let phasePrograms = phases.map { phase in
            PhaseProgram(
                phase: phase,
                reps: repsBase,
                distance: 40,
                notes: "Week \(weekNumber) session",
                lastTime: nil,
                pb: options.pb40yd
            )
        }
        let hybridAI = HybridAISession(
            recommendedAdjustments: [Adjustment(type: .increaseReps, phase: phases.first ?? .S, value: 1)],
            fatigueScore: Double(weekNumber) * 0.5,
            suggestedRest: Int(restBase),
            predictedPBs: Dictionary(uniqueKeysWithValues: phasePrograms.map { ($0.phase, PredictedPB(value: ($0.pb ?? 0) - Double(weekNumber) * 0.01, confidence: 0.7, trend: .stable)) })
        )
        let dayProgram = DayProgram(
            dayNumber: i + 1,
            phases: phasePrograms,
            hybridAI: hybridAI
        )
        program.append(dayProgram)
    }
    return program
}

func generate12WeekProgram(options: ProgramOptions) -> [WeeklyProgram] {
    var fullProgram: [WeeklyProgram] = []
    for week in 1...12 {
        fullProgram.append(generateWeeklyProgram(options: options, weekNumber: week))
    }
    return fullProgram
}

// Example usage integrating AI update and next week generation
// Commented out - AI functions not yet implemented
/*
func simulateAIWorkflow() {
    let userOptions = ProgramOptions(level: .advanced, daysPerWeek: 5, pb40yd: 4.8)
    var trainingProgram12Weeks = generate12WeekProgramWithAI(options: userOptions)
    // Simulate updating Day 1 of Week 1
    var week1 = trainingProgram12Weeks[0]
    let phaseTimesDay1: [Phase: Double] = [.S: 1.0, .A: 1.8, .T: 2.5, .F: 3.9]
    let fatigueScoreDay1 = 6 // Int, matches function signature
    updateDayProgramWithAI(day: &week1[0], phaseTimes: phaseTimesDay1, fatigueScore: fatigueScoreDay1)
    // Generate AI-driven Week 2 based on Week 1 performance
    let week2AI = generateNextWeekAI(previousWeek: week1, weekNumber: 2, options: userOptions)
    trainingProgram12Weeks[1] = week2AI
    print("Week 2 AI-Adjusted Program:", week2AI)
}
*/

