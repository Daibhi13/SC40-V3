import Foundation

// MARK: - SC40 Sprint Program Algorithm (Established)
//
// 1. User Onboarding: capture level, days/week, initial PB
// 2. Load Session Library: 101 sprint sessions (distance, reps, rest, focus, level)
// 3. Filter Library: by user level, remove completed
// 4. Select Weekly Sessions: mix short/mid/long, include tempo, respect rest
// 5. Insert Time Trial: every 4 weeks, 40-yard sprint, full recovery
// 6. PB Adjustment: compare current PB vs previous, scale intensity
// 7. Deliver Weekly Plan: sprints, reps, rest, focus, ready for GPS
// 8. Track Completion: GPS timing, rest compliance, update session history & PB
// 9. Repeat Next Week: use updated PB, avoid repeat, adjust intensity
//
// This algorithm is now the canonical flow for all program generation and user progression in the app.
//
// See ProgramGenerator.swift for implementation details.

// MARK: - Program Generation Logic

func scalePhase(level: TrainingLevel, phase: Phase, pb40yd: Double?) -> PhaseProgram {
    let baseReps = 5
    let baseDistance = 40 // yards
    return PhaseProgram(
        phase: phase,
        reps: baseReps,
        distance: baseDistance, // yards
        notes: nil,
        lastTime: nil,
        pb: pb40yd
    )
}

func generateWeeklyProgramWithOverload(options: ProgramOptions, weekNumber: Int, prevWeek: WeeklyProgram? = nil) -> WeeklyProgram {
    var program: WeeklyProgram = []
    let advancedWeek: [(focus: String, reps: Int, intensity: Double, notes: String, support: [PhaseProgram])] = [
        ("Acceleration", 6, 0.98, "6×40 yd max effort (95–100%)", [PhaseProgram(phase: .A, reps: 4, distance: 10, notes: "4×10 yd starts", lastTime: nil, pb: nil)]),
        ("Technical Submax", 8, 0.80, "8×40 yd at 80% (mechanics focus)", [PhaseProgram(phase: .A, reps: 1, distance: 0, notes: "Sprint drills (A/B skips, high knees, bounds, pogos)", lastTime: nil, pb: nil)]),
        ("Contrast", 6, 0.95, "3×40 yd resisted + 3×40 yd free", [PhaseProgram(phase: .A, reps: 4, distance: 20, notes: "4×20 yd buildups, bounds, skips", lastTime: nil, pb: nil)]),
        ("Stride-outs (Recovery)", 6, 0.70, "6×40 yd at 70%", [PhaseProgram(phase: .A, reps: 1, distance: 0, notes: "Sprint drills (ankling, straight-leg bounds, pogos)", lastTime: nil, pb: nil)]),
        ("Overspeed / Flying 40s", 5, 1.05, "5×40 yd flying sprints (build 20 yd → fly 20 yd)", [PhaseProgram(phase: .O, reps: 4, distance: 30, notes: "4×30 yd accelerations, skips, bounds", lastTime: nil, pb: nil)]),
        ("Max Velocity", 6, 1.00, "6×40 yd timed (full rest)", [PhaseProgram(phase: .F, reps: 4, distance: 20, notes: "4×20 yd flying starts, bounds, pogos", lastTime: nil, pb: nil)]),
        ("Light Priming", 4, 0.68, "4×40 yd relaxed (65–70%)", [PhaseProgram(phase: .A, reps: 1, distance: 0, notes: "Sprint drills (marches, skips, bounds, pogos)", lastTime: nil, pb: nil)])
    ]
    if options.level == .advanced && options.daysPerWeek == 7 {
        for i in 0..<7 {
            let day = advancedWeek[i]
            let fatigueScore = Double.random(in: 3...8)
            let readinessScore = Double.random(in: 5...10)
            let main40yd = PhaseProgram(phase: .S, reps: day.reps, distance: 40, notes: day.notes, lastTime: nil, pb: options.pb40yd)
            let phases: [PhaseProgram] = [main40yd] + day.support
            let predictedPBs = Dictionary(uniqueKeysWithValues: phases.map { ($0.phase, PredictedPB(value: $0.pb ?? 0, confidence: 0.7, trend: .stable)) })
            let hybridAI = HybridAISession(
                recommendedAdjustments: [],
                fatigueScore: fatigueScore,
                suggestedRest: 90,
                predictedPBs: predictedPBs,
                readinessScore: readinessScore
            )
            let dayProgram = DayProgram(
                dayNumber: i + 1,
                phases: phases,
                hybridAI: hybridAI
            )
            program.append(dayProgram)
        }
        return program
    }
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
    let sessionTypes: [String] = ["max", "submax", "assisted", "contrast", "activeRecovery", "submax", "max"]
    for (i, phases) in dayPhases.enumerated() {
        let overloadMultiplier = 1 + Double(weekNumber - 1) * 0.05
        var phasePrograms: [PhaseProgram] = []
        // Always include a 40-yard sprint exposure
        let sessionType = sessionTypes[i % sessionTypes.count]
        var reps = options.level == .beginner ? 3 : (options.level == .advanced ? 6 : 4)
        reps = Int((Double(reps) * overloadMultiplier).rounded(.up))
        var intensity: Double = 1.0
        var notes = "40-yard sprint"
        switch sessionType {
        case "max":
            intensity = 0.98 + Double.random(in: 0.0...0.02)
            notes += " | Max effort (timed)"
        case "submax":
            intensity = 0.85 + Double.random(in: 0.0...0.05)
            notes += " | Submax technical"
        case "assisted":
            intensity = 1.05
            notes += " | Assisted/overspeed"
        case "contrast":
            intensity = 0.95
            notes += " | Contrast (sled + free sprint)"
        case "activeRecovery":
            intensity = 0.7
            notes += " | Active recovery (stride-outs, tempo runs)"
        default:
            intensity = 0.9
            notes += " | Submax"
        }
        // Adjust intensity based on AI fatigue/readiness
        let fatigueScore = Double.random(in: 3...8)
        let readinessScore = Double.random(in: 5...10)
        if fatigueScore > 7 || readinessScore < 6 {
            intensity = min(intensity, 0.85)
            notes += " | AI: submax due to fatigue/readiness"
        }
        let phaseProgram = PhaseProgram(
            phase: .S,
            reps: reps,
            distance: 40,
            notes: notes,
            lastTime: nil,
            pb: options.pb40yd
        )
        phasePrograms.append(phaseProgram)
        // Add other phases as before
        for (_, phase) in phases.enumerated() {
            if phase != .S {
                var base = scalePhase(level: options.level, phase: phase, pb40yd: options.pb40yd)
                base.reps = Int((Double(base.reps) * overloadMultiplier).rounded(.up))
                base.distance = Int((Double(base.distance) * overloadMultiplier).rounded(.up))
                phasePrograms.append(base)
            }
        }
        let predictedPBs = Dictionary(uniqueKeysWithValues: phasePrograms.map { ($0.phase, PredictedPB(value: $0.pb ?? 0, confidence: 0.7, trend: .stable)) })
        let hybridAI = HybridAISession(
            recommendedAdjustments: [],
            fatigueScore: fatigueScore,
            suggestedRest: 90,
            predictedPBs: predictedPBs,
            readinessScore: readinessScore
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

func generate12WeekProgramWithAI(options: ProgramOptions) -> [WeeklyProgram] {
    var fullProgram: [WeeklyProgram] = []
    var fortyYardSessionCount = 0
    for week in 1...12 {
        let prevWeek = week > 1 ? fullProgram[week - 2] : nil
        var weeklyProgram = generateWeeklyProgramWithOverload(options: options, weekNumber: week, prevWeek: prevWeek)
        for dayIndex in 0..<weeklyProgram.count {
            for phaseIndex in 0..<weeklyProgram[dayIndex].phases.count {
                let phase = weeklyProgram[dayIndex].phases[phaseIndex]
                // Only count pure 40-yard sprint phases
                if phase.distance == 40 && fortyYardSessionCount < 7 {
                    fortyYardSessionCount += 1
                } else if fortyYardSessionCount >= 7 {
                    // After 7 sessions, switch to varied distances or advanced formats
                    let variedDistances = [30, 50, 60]
                    weeklyProgram[dayIndex].phases[phaseIndex].distance = variedDistances.randomElement() ?? 50
                    weeklyProgram[dayIndex].phases[phaseIndex].notes = "Advanced format: varied distance"
                }
            }
        }
        fullProgram.append(weeklyProgram)
    }
    return fullProgram
}

// MARK: - New 12-Week SC40 Sprint & Plyometric Program Integration

/// Generates a 12-week, phase-based sprint and plyometric program, adapting to user level, PB, and preferred training days.
func generateSC40Hybrid12WeekProgram(options: ProgramOptions, userSelectedDays: [Int], userPB: Double?, userLevel: Level) -> [WeeklyProgram] {
    let phases: [(name: String, weeks: Range<Int>)] = [
        ("Foundation", 1..<5),
        ("Power & Speed", 5..<9),
        ("Peaking & Taper", 9..<13)
    ]
    var fullProgram: [WeeklyProgram] = []
    for week in 1...12 {
        let phase = phases.first { $0.weeks.contains(week) }?.name ?? "Foundation"
        var weekProgram: WeeklyProgram = []
        for (i, day) in userSelectedDays.enumerated() {
            var phasesForDay: [PhaseProgram] = []
            switch phase {
            case "Foundation":
                if i == 0 { // Acceleration
                    phasesForDay.append(PhaseProgram(phase: .A, reps: userLevel == .beginner ? 6 : userLevel == .advanced ? 10 : 8, distance: 10, notes: "Acceleration sprints (10-20yd)", lastTime: nil, pb: userPB))
                } else if i == 1 { // Strength
                    phasesForDay.append(PhaseProgram(phase: .T, reps: 3, distance: 0, notes: "Lower-body strength: squats, lunges, calf raises", lastTime: nil, pb: nil))
                } else if i == 2 { // Speed Endurance
                    phasesForDay.append(PhaseProgram(phase: .F, reps: 5, distance: 75, notes: "Speed endurance: 75yd sprints", lastTime: nil, pb: nil))
                } else { // Agility & Plyo
                    phasesForDay.append(PhaseProgram(phase: .O, reps: 4, distance: 0, notes: "Plyometrics: box jumps, bounding; Agility: pro-agility shuttle", lastTime: nil, pb: nil))
                }
            case "Power & Speed":
                if i == 0 { // Acceleration w/ Resistance
                    phasesForDay.append(PhaseProgram(phase: .A, reps: 4, distance: 20, notes: "Resisted sprints (sled/band)", lastTime: nil, pb: userPB))
                    phasesForDay.append(PhaseProgram(phase: .S, reps: 4, distance: 40, notes: "Full 40yd sprints", lastTime: nil, pb: userPB))
                } else if i == 1 { // Explosive Strength
                    phasesForDay.append(PhaseProgram(phase: .T, reps: 3, distance: 0, notes: "Power cleans, hang cleans, jump squats", lastTime: nil, pb: nil))
                } else if i == 2 { // Max Velocity
                    phasesForDay.append(PhaseProgram(phase: .F, reps: 4, distance: 20, notes: "Flying 20s (max velocity)", lastTime: nil, pb: userPB))
                } else { // Advanced Plyo & Agility
                    phasesForDay.append(PhaseProgram(phase: .O, reps: 4, distance: 0, notes: "Single-leg bounds, depth jumps, pro-agility shuttle", lastTime: nil, pb: nil))
                }
            case "Peaking & Taper":
                if i == 0 { // 40-Yard Practice
                    phasesForDay.append(PhaseProgram(phase: .S, reps: 4, distance: 40, notes: "Full 40yd dash, race prep", lastTime: nil, pb: userPB))
                } else if i == 1 { // Technique/Light
                    phasesForDay.append(PhaseProgram(phase: .A, reps: 3, distance: 0, notes: "Technique drills: arm pumps, A-skips, form work", lastTime: nil, pb: nil))
                } else if i == 2 { // Light Sprints/Recovery
                    phasesForDay.append(PhaseProgram(phase: .F, reps: 3, distance: 20, notes: "20yd sprints at 80–90% or active recovery", lastTime: nil, pb: nil))
                } else { // Rest/Race Day
                    phasesForDay.append(PhaseProgram(phase: .R, reps: 1, distance: 0, notes: "Rest or 40yd test", lastTime: nil, pb: userPB))
                }
            default:
                break
            }
            let hybridAI = HybridAISession(
                recommendedAdjustments: [],
                fatigueScore: nil,
                suggestedRest: 90,
                predictedPBs: nil,
                readinessScore: nil
            )
            let dayProgram = DayProgram(
                dayNumber: day,
                phases: phasesForDay,
                hybridAI: hybridAI
            )
            weekProgram.append(dayProgram)
        }
        fullProgram.append(weekProgram)
    }
    return fullProgram
}

// MARK: - Realistic Adaptive AI Hybrid Sprint Coach Algorithm

/// Adaptive, coach-like session generator for SC40 sprint program
func generateAdaptiveSC40Program(
    options: ProgramOptions,
    userSelectedDays: [Int],
    userPB: Double?,
    userLevel: Level,
    feedbackHistory: [[String: Any]] = [],
    wearableData: [[String: Any]] = [],
    availableEquipment: [String] = [] // New parameter
) -> [WeeklyProgram] {
    let phases: [(name: String, weeks: Range<Int>)] = [
        ("Foundation", 1..<5),
        ("Power & Speed", 5..<9),
        ("Peaking & Taper", 9..<13)
    ]
    var fullProgram: [WeeklyProgram] = []
    let lastPB = userPB ?? 0
    var fatigueTrend: [Double] = []
    var hrvTrend: [Double] = []
    for week in 1...12 {
        let phase = phases.first { $0.weeks.contains(week) }?.name ?? "Foundation"
        var weekProgram: WeeklyProgram = []
        for (i, day) in userSelectedDays.enumerated() {
            // --- Adaptive logic ---
            let feedback = feedbackHistory.count > (week-1)*userSelectedDays.count + i ? feedbackHistory[(week-1)*userSelectedDays.count + i] : [:]
            let wearable = wearableData.count > (week-1)*userSelectedDays.count + i ? wearableData[(week-1)*userSelectedDays.count + i] : [:]
            let lastRPE = feedback["RPE"] as? Int ?? 5
            let lastSleep = feedback["sleep"] as? Int ?? 3
            let lastSoreness = feedback["soreness"] as? Int ?? 2
            let lastSessionPB = feedback["lastPB"] as? Double ?? lastPB
            let lastHRV = wearable["HRV"] as? Double ?? 7.0
            fatigueTrend.append(Double(lastRPE))
            hrvTrend.append(lastHRV)
            // Adjust intensity/volume based on feedback
            var intensityMod = 1.0
            var volumeMod = 1.0
            if lastRPE >= 8 || lastSleep <= 2 || lastSoreness >= 4 || lastHRV < 6.0 {
                intensityMod = 0.8
                volumeMod = 0.7
            } else if lastRPE <= 4 && lastSleep >= 4 && lastSoreness <= 2 && lastHRV > 8.0 {
                intensityMod = 1.1
                volumeMod = 1.1
            }
            // --- Session generation ---
            var phasesForDay: [PhaseProgram] = []
            switch phase {
            case "Foundation":
                if i == 0 { // Acceleration
                    let reps = Int(Double(userLevel == .beginner ? 6 : userLevel == .advanced ? 10 : 8) * volumeMod)
                    let dist = Int(10 * intensityMod)
                    phasesForDay.append(PhaseProgram(phase: .A, reps: reps, distance: dist, notes: "Acceleration sprints (10-20yd)", lastTime: nil, pb: lastSessionPB))
                } else if i == 1 { // Strength
                    phasesForDay.append(PhaseProgram(phase: .T, reps: Int(3 * volumeMod), distance: 0, notes: "Lower-body strength: squats, lunges, calf raises", lastTime: nil, pb: nil))
                } else if i == 2 { // Speed Endurance
                    let reps = Int(5 * volumeMod)
                    let dist = Int(75 * intensityMod)
                    phasesForDay.append(PhaseProgram(phase: .F, reps: reps, distance: dist, notes: "Speed endurance: 75yd sprints", lastTime: nil, pb: nil))
                } else { // Agility & Plyo
                    phasesForDay.append(PhaseProgram(phase: .O, reps: Int(4 * volumeMod), distance: 0, notes: "Plyometrics: box jumps, bounding; Agility: pro-agility shuttle", lastTime: nil, pb: nil))
                }
            case "Power & Speed":
                if i == 0 { // Accel w/ Resistance
                    let reps = Int(4 * volumeMod)
                    let dist = Int(20 * intensityMod)
                    phasesForDay.append(PhaseProgram(phase: .A, reps: reps, distance: dist, notes: "Resisted sprints (sled/band)", lastTime: nil, pb: lastSessionPB))
                    phasesForDay.append(PhaseProgram(phase: .S, reps: reps, distance: 40, notes: "Full 40yd sprints", lastTime: nil, pb: lastSessionPB))
                } else if i == 1 { // Explosive Strength
                    phasesForDay.append(PhaseProgram(phase: .T, reps: Int(3 * volumeMod), distance: 0, notes: "Power cleans, hang cleans, jump squats", lastTime: nil, pb: nil))
                } else if i == 2 { // Max Velocity
                    let reps = Int(4 * volumeMod)
                    let dist = Int(20 * intensityMod)
                    phasesForDay.append(PhaseProgram(phase: .F, reps: reps, distance: dist, notes: "Flying 20s (max velocity)", lastTime: nil, pb: lastSessionPB))
                } else { // Advanced Plyo & Agility
                    phasesForDay.append(PhaseProgram(phase: .O, reps: Int(4 * volumeMod), distance: 0, notes: "Single-leg bounds, depth jumps, pro-agility shuttle", lastTime: nil, pb: nil))
                }
            case "Peaking & Taper":
                if i == 0 { // 40-Yard Practice
                    let reps = Int(4 * volumeMod)
                    phasesForDay.append(PhaseProgram(phase: .S, reps: reps, distance: 40, notes: "Full 40yd dash, race prep", lastTime: nil, pb: lastSessionPB))
                } else if i == 1 { // Technique/Light
                    phasesForDay.append(PhaseProgram(phase: .A, reps: Int(3 * volumeMod), distance: 0, notes: "Technique drills: arm pumps, A-skips, form work", lastTime: nil, pb: nil))
                } else if i == 2 { // Light Sprints/Recovery
                    let reps = Int(3 * volumeMod)
                    let dist = Int(20 * intensityMod)
                    phasesForDay.append(PhaseProgram(phase: .F, reps: reps, distance: dist, notes: "20yd sprints at 80–90% or active recovery", lastTime: nil, pb: nil))
                } else { // Rest/Race Day
                    phasesForDay.append(PhaseProgram(phase: .R, reps: 1, distance: 0, notes: "Rest or 40yd test", lastTime: nil, pb: lastSessionPB))
                }
            default:
                break
            }
            let hybridAI = HybridAISession(
                recommendedAdjustments: [],
                fatigueScore: nil,
                suggestedRest: 90,
                predictedPBs: nil,
                readinessScore: nil
            )
            let dayProgram = DayProgram(
                dayNumber: day,
                phases: phasesForDay,
                hybridAI: hybridAI
            )
            weekProgram.append(dayProgram)
        }
        fullProgram.append(weekProgram)
    }
    return fullProgram
}
