import Foundation
// import ProgramModels

func generateNextWeekAI(previousWeek: WeeklyProgram, weekNumber: Int, options: ProgramOptions) -> WeeklyProgram {
    var nextWeek: WeeklyProgram = []
    for (_, prevDay) in previousWeek.enumerated() {
        let newPhases: [PhaseProgram] = prevDay.phases.map { p in
            let base = scalePhase(level: options.level, phase: p.phase, pb40yd: options.pb40yd)
            let overloadMultiplier = 1 + Double(weekNumber - 1) * 0.05
            var adjustedReps = Int(ceil(Double(base.reps) * overloadMultiplier))
            let adjustedDistance = Int(ceil(Double(base.distance) * overloadMultiplier))
            // If PB dropped >5%, reduce reps slightly
            if let lastTime = p.lastTime, let pb = p.pb, lastTime > pb * 1.05 {
                adjustedReps = max(1, Int(floor(Double(adjustedReps) * 0.9)))
            }
            // If PB improved >5%, increase reps for progressive overload
            if let lastTime = p.lastTime, let pb = p.pb, lastTime < pb * 0.95 {
                adjustedReps = Int(ceil(Double(adjustedReps) * 1.05))
            }
            return PhaseProgram(
                phase: p.phase,
                reps: adjustedReps,
                distance: adjustedDistance,
                notes: p.notes,
                lastTime: nil,
                pb: p.pb
            )
        }
        let hybridAI = HybridAISession(
            recommendedAdjustments: [],
            fatigueScore: prevDay.hybridAI?.fatigueScore ?? 0,
            suggestedRest: prevDay.hybridAI?.suggestedRest ?? 90,
            predictedPBs: Dictionary(uniqueKeysWithValues: newPhases.map { ($0.phase, PredictedPB(value: $0.pb ?? 0, confidence: 0.7, trend: .stable)) }) as [Phase: PredictedPB]
        )
        let dayProgram = DayProgram(
            dayNumber: prevDay.dayNumber,
            phases: newPhases,
            hybridAI: hybridAI
        )
        nextWeek.append(dayProgram)
    }
    return nextWeek
}
