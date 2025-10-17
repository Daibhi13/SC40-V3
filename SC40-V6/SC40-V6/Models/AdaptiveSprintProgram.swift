import Foundation

// MARK: - Adaptive Program Generation

func generateAdaptiveProgram(user: inout UserProfile) -> [AdaptiveSprintSession] {
    let level = user.level.lowercased()
    let daysPerWeek = user.frequency
    var sessions: [AdaptiveSprintSession] = []
    for week in 1...12 {
        let weeklySessions = min(daysPerWeek, 7)
        for day in 1...weeklySessions {
            var baseDistance = 0
            var baseReps = 0
            var intensity = "moderate"
            switch level {
            case "beginner":
                baseDistance = 20 + ((week - 1) / 2) * 5
                baseReps = 3 + (weeklySessions / 2)
                intensity = "moderate"
            case "intermediate":
                baseDistance = 25 + ((week - 1) / 2) * 5
                baseReps = 4 + (weeklySessions / 2)
                intensity = "submax"
            case "advanced":
                baseDistance = 30 + ((week - 1) / 2) * 5
                baseReps = 5 + (weeklySessions / 2)
                intensity = "max"
            default:
                baseDistance = 20
                baseReps = 3
                intensity = "moderate"
            }
            var sprints: [SprintSet] = []
            if weeklySessions >= 5 {
                sprints.append(SprintSet(distanceYards: baseDistance - 5, reps: baseReps, intensity: intensity))
                sprints.append(SprintSet(distanceYards: baseDistance, reps: max(1, baseReps - 1), intensity: "submax"))
            } else {
                sprints.append(SprintSet(distanceYards: baseDistance, reps: baseReps, intensity: intensity))
            }
            var accessoryWork: [String] = ["mobility", "acceleration drills"]
            if level != "beginner" { accessoryWork.append("plyometrics") }
            if weeklySessions <= 3 { accessoryWork.append("strength") }
            let session = AdaptiveSprintSession(week: week, day: day, level: level, sprints: sprints, accessoryWork: accessoryWork)
            user.addAdaptiveSession(session)
            sessions.append(session)
        }
    }
    return sessions
}

// MARK: - Varied Adaptive Program

func generateVariedAdaptiveProgram(user: inout UserProfile) -> [AdaptiveSprintSession] {
    let sessionTypes = [
        "Acceleration", "Max Velocity", "Speed Endurance", "Technique", "Plyometrics", "Recovery"
    ]
    let drillPool: [String: [String]] = [
        "Acceleration": ["A-Skip", "Falling Start", "3-Point Start", "Wall Drill"],
        "Max Velocity": ["Flying 20s", "Ins & Outs", "Build-Ups", "Resisted Sprints"],
        "Speed Endurance": ["Split Runs", "Tempo Runs", "Ladders", "Bounds"],
        "Technique": ["Wall Drill", "High Knees", "Butt Kicks", "B-Skip"],
        "Plyometrics": ["Bounding", "Hops", "Depth Jumps", "Box Jumps"],
        "Recovery": ["Mobility", "Foam Roll", "Light Jog", "Stretch"]
    ]
    let intensityMap: [String: String] = [
        "Acceleration": "max",
        "Max Velocity": "submax",
        "Speed Endurance": "submax",
        "Technique": "moderate",
        "Plyometrics": "max",
        "Recovery": "easy"
    ]
    let daysPerWeek = user.frequency
    let level = user.level.lowercased()
    var sessions: [AdaptiveSprintSession] = []
    for week in 1...12 {
        let weeklySessions = min(daysPerWeek, 7)
        var usedTypes: [String] = []
        for day in 1...weeklySessions {
            var type = sessionTypes[(week + day) % sessionTypes.count]
            if usedTypes.contains(type) {
                type = sessionTypes.first(where: { !usedTypes.contains($0) }) ?? type
            }
            usedTypes.append(type)
            let drills = (drillPool[type] ?? ["Custom"]).shuffled().prefix(2)
            let baseDistance = 20 + (week-1) * 2 + (type == "Max Velocity" ? 10 : 0)
            let baseReps = 3 + (week-1)/3 + (type == "Speed Endurance" ? 2 : 0)
            let intensity = intensityMap[type] ?? "moderate"
            var sprints: [SprintSet] = []
            sprints.append(SprintSet(distanceYards: baseDistance, reps: baseReps, intensity: intensity))
            if level != "beginner" && type != "Recovery" {
                sprints.append(SprintSet(distanceYards: baseDistance + 10, reps: max(1, baseReps-1), intensity: intensity))
            }
            var accessoryWork = Array(drillPool.keys.shuffled().prefix(2)).map { $0 }
            if type == "Plyometrics" { accessoryWork.append("strength") }
            if type == "Recovery" { accessoryWork.append("mobility") }
            if (week % 4 == 0 && day == 1) {
                sprints = [SprintSet(distanceYards: 40, reps: 1, intensity: "test")]
                accessoryWork = ["PB Test", "Record Time"]
            }
            let session = AdaptiveSprintSession(
                week: week,
                day: day,
                level: user.level,
                sprints: sprints,
                accessoryWork: drills + accessoryWork
            )
            user.addAdaptiveSession(session)
            sessions.append(session)
        }
    }
    return sessions
}
