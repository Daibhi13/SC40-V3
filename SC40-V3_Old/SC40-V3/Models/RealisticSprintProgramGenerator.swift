import Foundation

// MARK: - Realistic 12-Week Sprint Program Generator

func generateRealisticSprintProgram(level: String, daysPerWeek: Int) -> [TrainingSession] {
    let safeLevel = level.lowercased()
    let weeks = 12
    var sessions: [TrainingSession] = []
    let maxEffortLimit = min(2, daysPerWeek) // No more than 2 max 40y sprints per week
    let progression: [(accel: Int, speed: Int, max: Int)] = [
        // (accel reps, speed reps, max reps) by phase
        (3, 2, 1), // Weeks 1-3
        (4, 2, 1), // Weeks 4-6
        (4, 3, 2), // Weeks 7-9
        (3, 2, 1)  // Deload/test (10-12)
    ]
    let accelDistances = [10, 15, 20, 25]
    let speedDistances = [30, 35]
    let maxDistance = 40
    let accessoryByType: [String: [String]] = [
        "Acceleration": ["A-Skip", "Wall Drill", "Falling Start", "Core"],
        "Speed Endurance": ["Tempo Runs", "Bounds", "Core"],
        "Max Velocity": ["Flying 20s", "Ins & Outs", "Plyometrics"],
        "Technique": ["High Knees", "Butt Kicks", "Mobility"],
        "Recovery": ["Mobility", "Foam Roll", "Stretch"],
        "Test": ["PB Test", "Record Time"]
    ]
    let allAccessory = ["Mobility", "Core", "Plyometrics", "Strength", "Technique"]
    for week in 1...weeks {
        let phaseIdx = (week-1)/3
        let (accelReps, speedReps, maxReps) = progression[min(phaseIdx, progression.count-1)]
        var maxEffortCount = 0
        for day in 1...daysPerWeek {
            var type = ""
            var focus = ""
            var sprints: [SprintSet] = []
            var accessory: [String] = []
            var notes: String? = nil
            // Periodization: Test/deload every 4th week, otherwise rotate types
            if week % 4 == 0 && day == 1 {
                type = "Test"
                focus = "40yd PB Test"
                sprints = [SprintSet(distanceYards: maxDistance, reps: 1, intensity: "test")]
                accessory = accessoryByType["Test"] ?? []
                notes = "Go all out, full recovery between attempts. Record your time."
            } else {
                // Rotate session types: Accel, Speed, MaxV, Technique, Recovery
                let typeOrder = daysPerWeek <= 3 ? ["Acceleration", "Speed Endurance", "Max Velocity"] : ["Acceleration", "Speed Endurance", "Max Velocity", "Technique", "Recovery"]
                type = typeOrder[(day-1) % typeOrder.count]
                switch type {
                case "Acceleration":
                    focus = "Start mechanics, drive phase"
                    let dist = accelDistances[min(phaseIdx, accelDistances.count-1)]
                    let reps = accelReps + (safeLevel == "advanced" ? 1 : 0)
                    sprints = [SprintSet(distanceYards: dist, reps: reps, intensity: safeLevel == "beginner" ? "moderate" : "submax")]
                    accessory = accessoryByType["Acceleration"] ?? []
                case "Speed Endurance":
                    focus = "Hold top speed, resist slowing"
                    let dist = speedDistances[min(phaseIdx, speedDistances.count-1)]
                    let reps = speedReps + (safeLevel == "advanced" ? 1 : 0)
                    sprints = [SprintSet(distanceYards: dist, reps: reps, intensity: "submax")]
                    accessory = accessoryByType["Speed Endurance"] ?? []
                case "Max Velocity":
                    focus = "Full 40yd sprints, max effort"
                    let reps = (maxEffortCount < maxEffortLimit) ? maxReps : 0
                    if reps > 0 {
                        sprints = [SprintSet(distanceYards: maxDistance, reps: reps, intensity: "max")]
                        maxEffortCount += 1
                    } else {
                        // If max already hit, do technique
                        type = "Technique"
                        focus = "Form, relaxation, drills"
                        sprints = [SprintSet(distanceYards: 20, reps: 2, intensity: "easy")]
                        accessory = accessoryByType["Technique"] ?? []
                        notes = "Focus on form, not speed."
                    }
                    accessory = accessoryByType["Max Velocity"] ?? []
                case "Technique":
                    focus = "Form, relaxation, drills"
                    sprints = [SprintSet(distanceYards: 20, reps: 2, intensity: "easy")]
                    accessory = accessoryByType["Technique"] ?? []
                    notes = "Focus on form, not speed."
                case "Recovery":
                    focus = "Active recovery, mobility"
                    sprints = [SprintSet(distanceYards: 10, reps: 2, intensity: "easy")]
                    accessory = accessoryByType["Recovery"] ?? []
                    notes = "Keep it light, focus on recovery."
                default:
                    focus = "General sprint work"
                    sprints = [SprintSet(distanceYards: 20, reps: 2, intensity: "moderate")]
                    accessory = allAccessory.shuffled().prefix(2).map { $0 }
                }
            }
            // Add core/strength for advanced/intermediate, less for beginners
            if safeLevel != "beginner" && !accessory.contains("Core") {
                accessory.append("Core")
            }
            if safeLevel == "advanced" && !accessory.contains("Strength") {
                accessory.append("Strength")
            }
            // Compose session
            let session = TrainingSession(
                week: week,
                day: day,
                type: type,
                focus: focus,
                sprints: sprints,
                accessoryWork: accessory,
                notes: notes
            )
            sessions.append(session)
        }
    }
    return sessions
}
