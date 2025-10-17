import Foundation

func updateDayProgramWithAI(day: inout DayProgram, phaseTimes: [Phase: Double], fatigueScore: Int) {
    if day.hybridAI == nil {
        day.hybridAI = HybridAISession(recommendedAdjustments: [], fatigueScore: nil, fatigue: nil, suggestedRest: nil, predictedPBs: nil, phaseTrends: nil, focusPhases: nil)
    }
    day.hybridAI?.fatigueScore = Double(fatigueScore)
    var predictedPBs: [Phase: PredictedPB] = [:]
    for i in 0..<day.phases.count {
        let phase = day.phases[i]
        if let currentTime = phaseTimes[phase.phase] {
            day.phases[i].lastTime = currentTime
            var confidence: Double = 0.8 // Example: default confidence
            var trend: TrendDirection = .stable // Default, can be improved
            if let pb = phase.pb {
                if currentTime < pb {
                    day.phases[i].pb = currentTime
                    day.hybridAI?.recommendedAdjustments?.append(Adjustment(type: .increaseReps, phase: phase.phase, value: nil))
                    confidence = 0.95
                    trend = .improving
                } else if currentTime > pb * 1.05 {
                    day.hybridAI?.recommendedAdjustments?.append(Adjustment(type: .decreaseReps, phase: phase.phase, value: nil))
                    confidence = 0.6
                    trend = .declining
                }
            } else {
                day.phases[i].pb = currentTime
                confidence = 0.7
                trend = .stable
            }
            predictedPBs[phase.phase] = PredictedPB(value: day.phases[i].pb ?? currentTime, confidence: confidence, trend: trend)
        } else {
            predictedPBs[phase.phase] = PredictedPB(value: day.phases[i].pb ?? 0, confidence: 0.5, trend: .stable)
        }
    }
    if fatigueScore >= 8 { day.hybridAI?.suggestedRest = 120 }
    else if fatigueScore >= 5 { day.hybridAI?.suggestedRest = 90 }
    else { day.hybridAI?.suggestedRest = 60 }
    day.hybridAI?.predictedPBs = predictedPBs
}
