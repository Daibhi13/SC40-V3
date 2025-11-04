import Foundation

class UnifiedSessionGenerator {
    static let shared = UnifiedSessionGenerator()
    
    private init() {}
    
    func generateSession(for level: TrainingLevel, week: Int, day: Int) -> TrainingSession {
        let focus = getFocusForWeek(week)
        let sprints = generateSprintsForWeek(week, userLevel: level.rawValue)
        
        return TrainingSession(
            week: week,
            day: day,
            type: "Sprint Training",
            focus: focus,
            sprints: sprints,
            accessoryWork: []
        )
    }
    
    func generateUnified12WeekProgram(userLevel: String, frequency: Int) -> [TrainingSession] {
        var sessions: [TrainingSession] = []
        
        for week in 1...12 {
            for day in 1...frequency {
                let session = TrainingSession(
                    id: TrainingSession.stableSessionID(week: week, day: day),
                    week: week,
                    day: day,
                    type: "Sprint Training Week \(week) Day \(day)",
                    focus: getFocusForWeek(week),
                    sprints: generateSprintsForWeek(week, userLevel: userLevel),
                    accessoryWork: []
                )
                sessions.append(session)
            }
        }
        
        return sessions
    }
    
    private func getFocusForWeek(_ week: Int) -> String {
        switch week {
        case 1...2: return "Acceleration Development"
        case 3...4: return "Max Velocity Building"
        case 5...6: return "Speed Endurance"
        case 7...8: return "Power Development"
        case 9...10: return "Peak Speed Training"
        case 11...12: return "Competition Prep"
        default: return "General Speed"
        }
    }
    
    private func getRepsForWeek(_ week: Int, userLevel: String) -> Int {
        let baseReps = getBaseRepsForLevel(userLevel)
        return max(1, baseReps - (week - 1) / 3)
    }
    
    private func getBaseRepsForLevel(_ level: String) -> Int {
        switch level.lowercased() {
        case "beginner": return 3
        case "intermediate": return 4
        case "advanced": return 5
        case "elite": return 6
        default: return 3
        }
    }
    
    private func getIntensityForWeek(_ week: Int) -> String {
        switch week {
        case 1...4: return "moderate"
        case 5...8: return "high"
        case 9...12: return "max"
        default: return "moderate"
        }
    }
    
    private func generateSprintsForWeek(_ week: Int, userLevel: String) -> [SprintSet] {
        var sprints: [SprintSet] = []
        let baseDistance: Double = 30.0 // meters
        let baseReps: Int
        let baseRest: TimeInterval
        
        // Adjust parameters based on week and user level
        switch week {
        case 1...4:
            baseReps = userLevel.lowercased() == "beginner" ? 4 : 6
            baseRest = userLevel.lowercased() == "beginner" ? 90 : 75
        case 5...8:
            baseReps = userLevel.lowercased() == "beginner" ? 5 : 8
            baseRest = userLevel.lowercased() == "beginner" ? 120 : 90
        case 9...12:
            baseReps = userLevel.lowercased() == "beginner" ? 6 : 10
            baseRest = userLevel.lowercased() == "beginner" ? 150 : 120
        default:
            baseReps = 4
            baseRest = 90
        }
        
        // Create sprint sets
        for i in 0..<baseReps {
            let distance = baseDistance * (1.0 + Double(i) * 0.1) // Gradually increase distance
            let rest = baseRest + TimeInterval(i * 5) // Gradually increase rest time
            
            let sprint = SprintSet(
                distanceYards: Int(distance),
                reps: 1,
                intensity: "max"
            )
            sprints.append(sprint)
        }
        
        return sprints
    }
    
    private func generateExercises(for level: TrainingLevel) -> [Exercise] {
        switch level {
        case .beginner:
            return [
                Exercise(name: "Warm-up", duration: 300),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 60),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 60),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Cool-down", duration: 300)
            ]
        case .intermediate:
            return [
                Exercise(name: "Warm-up", duration: 300),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 45),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 45),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 45),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Cool-down", duration: 300)
            ]
        case .advanced:
            return [
                Exercise(name: "Warm-up", duration: 300),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 30),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 30),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 30),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 30),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Cool-down", duration: 300)
            ]
        case .pro:
            return [
                Exercise(name: "Warm-up", duration: 300),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 20),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 20),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 20),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 20),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 20),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Cool-down", duration: 300)
            ]
        case .elite:
            return [
                Exercise(name: "Warm-up", duration: 300),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 15),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 15),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 15),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 15),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 15),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Rest", duration: 15),
                Exercise(name: "40-yard Sprint", duration: 10),
                Exercise(name: "Cool-down", duration: 300)
            ]
        }
    }
}

struct Exercise {
    let name: String
    let duration: TimeInterval
}
