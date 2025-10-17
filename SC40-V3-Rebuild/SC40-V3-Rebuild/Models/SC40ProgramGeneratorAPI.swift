import Foundation

// MARK: - SC40Level Enum
enum SC40Level: String, Codable {
    case beginner
    case intermediate
    case advanced
}

// MARK: - SC40SprintDrill Model
struct SC40SprintDrill: Codable {
    let name: String
    let phase: String
    let setsReps: String
    let coachingNotes: String?
}

// MARK: - SC40SprintLibrary
let SC40SprintLibrary: [SC40SprintDrill] = [
    SC40SprintDrill(name: "40yd Sprint", phase: "S", setsReps: "4x1", coachingNotes: "Max effort, full rest."),
    SC40SprintDrill(name: "Acceleration Drill", phase: "A", setsReps: "3x2", coachingNotes: "Focus on drive phase."),
    SC40SprintDrill(name: "Tempo Run", phase: "RECOVERY", setsReps: "2x4", coachingNotes: "Active recovery.")
]

// MARK: - generateSampleSession
func generateSampleSession(for level: SC40Level) -> [SC40SprintDrill] {
    switch level {
    case .beginner:
        return SC40SprintLibrary.filter { $0.phase == "S" || $0.phase == "RECOVERY" }
    case .intermediate:
        return SC40SprintLibrary.filter { $0.phase == "S" || $0.phase == "A" }
    case .advanced:
        return SC40SprintLibrary
    }
}

public enum Level: String, Codable {
    case beginner, intermediate, advanced
}

public struct ProgramParameters {
    public let level: Level
    public let daysPerWeek: Int        // 1..7
    public let recentPB40: Double?    // seconds (optional)
    public var fatigueScore: Double   // 0.0 (fresh) .. 1.0 (very fatigued)
    
    public init(level: Level, daysPerWeek: Int, recentPB40: Double? = nil, fatigueScore: Double = 0.0) {
        self.level = level
        self.daysPerWeek = min(max(daysPerWeek, 1), 7)
        self.recentPB40 = recentPB40
        self.fatigueScore = min(max(fatigueScore, 0.0), 1.0)
    }
}

// MARK: - Generator API

public func generate12WeekProgram(params: ProgramParameters, recentFeedback: [SessionFeedback] = []) -> [TrainingSession] {
    let sc40Level: SC40Level
    switch params.level {
    case .beginner: sc40Level = .beginner
    case .intermediate: sc40Level = .intermediate
    case .advanced: sc40Level = .advanced
    }
    let daysPerWeek = params.daysPerWeek
    var sessions: [TrainingSession] = []
    for week in 1...12 {
        for day in 1...daysPerWeek {
            // --- Insert recovery/rest logic ---
            let isRecoveryDay = (day == daysPerWeek && week % 2 == 0) // Every other week, last day is recovery
            let isTaperWeek = (week >= 10)
            if isRecoveryDay {
                // Use a recovery drill
                if let recoveryDrill = SC40SprintLibrary.first(where: { $0.phase == "RECOVERY" }) {
                    let sprintSet = SprintSet(distanceYards: 0, reps: 1, intensity: "recovery")
                    let session = TrainingSession(
                        id: TrainingSession.stableSessionID(week: week, day: day),
                        week: week,
                        day: day,
                        type: "Recovery",
                        focus: recoveryDrill.name,
                        sprints: [sprintSet],
                        accessoryWork: [],
                        notes: recoveryDrill.coachingNotes
                    )
                    sessions.append(session)
                    continue
                }
            }
            // --- Taper logic: reduce volume, increase rest in last 3 weeks ---
            var drills = generateSampleSession(for: sc40Level)
            if isTaperWeek {
                drills = drills.prefix(max(6, drills.count / 2)).map { $0 } // Reduce volume
            }
            // Map drills to SprintSets
            let sprintSets: [SprintSet] = drills.map { drill in
                let reps = Int(drill.setsReps.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 6
                return SprintSet(
                    distanceYards: drill.name.contains("10 yd") ? 10 : drill.name.contains("20 yd") ? 20 : drill.name.contains("30 yd") ? 30 : drill.name.contains("40 yd") ? 40 : 10,
                    reps: reps,
                    intensity: drill.phase == "RECOVERY" ? "recovery" : "max"
                )
            }
            // Use the first drill for type/focus/notes
            let type = drills.first?.phase ?? "Session"
            let focus = drills.first?.name ?? "Sprint Work"
            let notes = drills.first?.coachingNotes
            let accessoryWork = drills.dropFirst().map { $0.name }
            let session = TrainingSession(
                id: TrainingSession.stableSessionID(week: week, day: day),
                week: week,
                day: day,
                type: type,
                focus: focus,
                sprints: sprintSets,
                accessoryWork: accessoryWork,
                notes: notes
            )
            sessions.append(session)
        }
    }
    return sessions
}

// MARK: - Export All Programs

public func exportAllPrograms() -> [String: [TrainingSession]] {
    var library: [String: [TrainingSession]] = [:]
    let levels: [Level] = [.beginner, .intermediate, .advanced]
    for level in levels {
        for days in 1...7 {
            let params = ProgramParameters(level: level,
                                           daysPerWeek: days,
                                           recentPB40: nil,
                                           fatigueScore: 0.2)
            let sessions = generate12WeekProgram(params: params)
            let key = "\(level.rawValue.capitalized)_\(days)days"
            library[key] = sessions
        }
    }
    return library
}

public func saveProgramsToDisk() {
    let library = exportAllPrograms()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(library) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SC40_Programs.json")
        try? data.write(to: url)
        print("✅ Exported SC40 programs to \(url.path)")
    }
}
