import Foundation

// MARK: - Program Scheduler Models (Standalone Implementation)

/// A scheduled session with week/day metadata for export
struct ScheduledSession: Codable, Identifiable {
    let id: UUID
    let week: Int
    let day: Int
    let session: TrainingSessionCodable
    
    init(week: Int, day: Int, session: TrainingSessionCodable) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.session = session
    }
}

/// Complete training session for JSON export
struct TrainingSessionCodable: Codable {
    let id: String
    let week: Int
    let day: Int
    let name: String
    let type: String
    let focus: String
    let sprints: [SprintSetCodable]
    let accessoryWork: [String]
    let notes: String
}

/// Sprint set for JSON export
struct SprintSetCodable: Codable {
    let distanceYards: Int
    let reps: Int
    let intensity: String
    let restSeconds: Int
}

/// Complete scheduled program for export
struct ScheduledProgram: Codable {
    let userId: String?
    let generatedAtISO: String
    let weeks: Int
    let daysPerWeek: Int
    let level: String
    let schedule: [ScheduledSession]
}

// MARK: - Session Templates (Simplified)

/// Simplified session template for program generation
struct SessionTemplate {
    let id: Int
    let name: String
    let distance: Int
    let reps: Int
    let rest: Int
    let focus: String
    let level: String
    let type: String
    
    func toCodableSession(week: Int, day: Int) -> TrainingSessionCodable {
        let sprint = SprintSetCodable(
            distanceYards: distance,
            reps: reps,
            intensity: "max",
            restSeconds: rest
        )
        
        return TrainingSessionCodable(
            id: UUID().uuidString,
            week: week,
            day: day,
            name: name,
            type: type,
            focus: focus,
            sprints: [sprint],
            accessoryWork: [],
            notes: "Generated session for \(level) level"
        )
    }
}

// MARK: - Basic Session Library for Program Generation

private let basicSessionTemplates: [SessionTemplate] = [
    // Beginner sessions
    SessionTemplate(id: 1, name: "10 yd Starts", distance: 10, reps: 8, rest: 60, focus: "Acceleration", level: "Beginner", type: "Sprint"),
    SessionTemplate(id: 2, name: "15 yd Starts", distance: 15, reps: 10, rest: 60, focus: "Acceleration", level: "Beginner", type: "Sprint"),
    SessionTemplate(id: 3, name: "20 yd Accel", distance: 20, reps: 6, rest: 90, focus: "Early Acceleration", level: "Beginner", type: "Sprint"),
    SessionTemplate(id: 4, name: "25 yd Accel", distance: 25, reps: 8, rest: 90, focus: "Drive Phase", level: "Beginner", type: "Sprint"),
    SessionTemplate(id: 5, name: "30 yd Drive", distance: 30, reps: 6, rest: 120, focus: "Drive Phase", level: "Beginner", type: "Sprint"),
    SessionTemplate(id: 6, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Beginner", type: "Benchmark"),
    
    // Intermediate sessions
    SessionTemplate(id: 10, name: "50 yd Sprints", distance: 50, reps: 5, rest: 180, focus: "Accel → Top Speed", level: "Intermediate", type: "Sprint"),
    SessionTemplate(id: 11, name: "60 yd Fly", distance: 60, reps: 6, rest: 240, focus: "Max Velocity", level: "Intermediate", type: "Sprint"),
    SessionTemplate(id: 12, name: "70 yd Build", distance: 70, reps: 4, rest: 240, focus: "Speed Endurance", level: "Intermediate", type: "Sprint"),
    SessionTemplate(id: 13, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Intermediate", type: "Benchmark"),
    
    // Advanced sessions
    SessionTemplate(id: 20, name: "75 yd Sprint", distance: 75, reps: 3, rest: 300, focus: "Top-End Speed", level: "Advanced", type: "Sprint"),
    SessionTemplate(id: 21, name: "80 yd Repeats", distance: 80, reps: 3, rest: 300, focus: "Repeat Sprints", level: "Advanced", type: "Sprint"),
    SessionTemplate(id: 22, name: "90 yd Sprints", distance: 90, reps: 3, rest: 300, focus: "Top-End Speed", level: "Advanced", type: "Sprint"),
    SessionTemplate(id: 23, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Advanced", type: "Benchmark"),
    
    // Elite sessions
    SessionTemplate(id: 30, name: "100 yd Max", distance: 100, reps: 2, rest: 360, focus: "Peak Velocity", level: "Elite", type: "Sprint"),
    SessionTemplate(id: 31, name: "120 yd Sprint", distance: 120, reps: 2, rest: 480, focus: "Speed Endurance", level: "Elite", type: "Sprint"),
    SessionTemplate(id: 32, name: "150 yd Sprint", distance: 150, reps: 2, rest: 540, focus: "Speed Reserve", level: "Elite", type: "Sprint"),
    SessionTemplate(id: 33, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Elite", type: "Benchmark")
]

// MARK: - Program Generator

/// Generates a 12-week program using simplified session templates
/// - Parameters:
///   - level: "Beginner"/"Intermediate"/"Advanced"/"Elite"
///   - daysPerWeek: 1...7
///   - weeks: number of weeks (default 12)
///   - userId: optional user identifier
/// - Returns: ScheduledProgram instance
func generateScheduledProgram(level: String,
                              daysPerWeek: Int,
                              weeks: Int = 12,
                              userId: String? = nil) -> ScheduledProgram {

    precondition(daysPerWeek >= 1 && daysPerWeek <= 7, "daysPerWeek must be 1..7")
    precondition(weeks >= 1, "weeks must be >=1")

    // Filter sessions for the specified level
    let levelSessions = basicSessionTemplates.filter { $0.level == level }
    let sprintSessions = levelSessions.filter { $0.type == "Sprint" }
    let timeTrialSession = levelSessions.first { $0.type == "Benchmark" }
    
    // Build schedule week-by-week
    var scheduled: [ScheduledSession] = []
    var sessionIndex = 0

    for week in 1...weeks {
        for dayIndex in 1...daysPerWeek {
            let sessionTemplate: SessionTemplate
            
            // Insert 40-yard time trial every 4th week on day 1
            if (week % 4 == 0) && (dayIndex == 1) {
                sessionTemplate = timeTrialSession ?? sprintSessions[0]
            } else {
                // Use sprint sessions with cycling
                sessionTemplate = sprintSessions[sessionIndex % sprintSessions.count]
                sessionIndex += 1
            }
            
            let codableSession = sessionTemplate.toCodableSession(week: week, day: dayIndex)
            let scheduledSession = ScheduledSession(week: week, day: dayIndex, session: codableSession)
            scheduled.append(scheduledSession)
        }
    }

    // Build ScheduledProgram structure
    let iso = ISO8601DateFormatter().string(from: Date())
    return ScheduledProgram(
        userId: userId,
        generatedAtISO: iso,
        weeks: weeks,
        daysPerWeek: daysPerWeek,
        level: level,
        schedule: scheduled
    )
}

// MARK: - JSON Export Utilities

/// Encode ScheduledProgram to JSON Data (pretty printed)
func exportProgramToJSONData(_ program: ScheduledProgram) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(program)
}

/// Save JSON Data to a file in app Documents directory and return the file URL
func saveJSONToDocuments(data: Data, filename: String) throws -> URL {
    let fm = FileManager.default
    #if os(watchOS)
    let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
    #else
    let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
    #endif

    let fileURL = docsDir.appendingPathComponent(filename)
    try data.write(to: fileURL, options: [.atomic])
    return fileURL
}

/// Convenience: generate + export + save to disk (returns file URL)
func generateAndExportProgram(level: String,
                              daysPerWeek: Int,
                              weeks: Int = 12,
                              userId: String? = nil,
                              filename: String? = nil) throws -> URL {
    let program = generateScheduledProgram(level: level, daysPerWeek: daysPerWeek, weeks: weeks, userId: userId)
    let jsonData = try exportProgramToJSONData(program)
    let name = filename ?? "sc40_program_\(level.lowercased())_\(Int(Date().timeIntervalSince1970)).json"
    let url = try saveJSONToDocuments(data: jsonData, filename: name)
    return url
}

// MARK: - Usage Examples
/*
 // Generate a 12-week Elite program for 4 days/week
 let program = generateScheduledProgram(level: "Elite", daysPerWeek: 4, weeks: 12, userId: "user_123")

 // Export to JSON Data
 do {
     let data = try exportProgramToJSONData(program)
     print(String(data: data, encoding: .utf8) ?? "Failed to convert to string")
 } catch {
     print("Export failed: \(error)")
 }

 // Generate and save to documents
 do {
     let url = try generateAndExportProgram(level: "Beginner", daysPerWeek: 3, userId: "user_123")
     print("Saved program at: \(url.path)")
 } catch {
     print("Failed to generate & save program: \(error)")
 }
*/

// MARK: - Notes
/*
 This is a standalone program scheduler that:
 - Uses simplified session templates (no external dependencies)
 - Automatically inserts 40-yard time trials every 4th week
 - Cycles through appropriate sessions for each level
 - Exports to human-readable JSON format
 - Saves to Documents directory for sharing or upload
 - Works across iOS, watchOS, and macOS platforms
 */