import Foundation

// MARK: - Sprint Session Template for Library

struct SprintSessionTemplate: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let distance: Int // yards
    let reps: Int
    let rest: Int // minutes
    let focus: String
    let level: String
    let sessionType: LibrarySessionType
}

enum LibrarySessionType: String, Codable, CaseIterable {
    case sprint = "Sprint"
    case activeRecovery = "Active Recovery"
    case recovery = "Recovery"
    case rest = "Rest"
    case benchmark = "Benchmark"
    case tempo = "Tempo"
    case comprehensive = "Comprehensive" // New type for complete workout sessions
}

// MARK: - Weekly Program Template

struct WeeklyProgramTemplate: Codable, Identifiable {
    let id: UUID
    let level: String // Using String for now to match existing level field
    let weekNumber: Int
    let totalDays: Int
    let sessions: [DaySessionTemplate]
    
    init(level: String, weekNumber: Int, totalDays: Int, sessions: [DaySessionTemplate]) {
        self.id = UUID()
        self.level = level
        self.weekNumber = weekNumber
        self.totalDays = totalDays
        self.sessions = sessions
    }
}

struct DaySessionTemplate: Codable, Identifiable {
    let id: UUID
    let dayNumber: Int
    let sessionTemplate: SprintSessionTemplate?
    let sessionType: LibrarySessionType
    let notes: String?
    
    init(dayNumber: Int, sessionTemplate: SprintSessionTemplate? = nil, sessionType: LibrarySessionType, notes: String? = nil) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.sessionTemplate = sessionTemplate
        self.sessionType = sessionType
        self.notes = notes
    }
}

let sessionLibrary: [SprintSessionTemplate] = [
    SprintSessionTemplate(id: 1, name: "10 yd Starts", distance: 10, reps: 8, rest: 1, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 2, name: "15 yd Starts", distance: 15, reps: 10, rest: 1, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 3, name: "20 yd Accel", distance: 20, reps: 6, rest: 2, focus: "Early Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 4, name: "25 yd Accel", distance: 25, reps: 8, rest: 2, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 5, name: "30 yd Drive", distance: 30, reps: 6, rest: 2, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 6, name: "35 yd Drive", distance: 35, reps: 5, rest: 2, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 7, name: "40 yd Repeats", distance: 40, reps: 6, rest: 3, focus: "Max Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 8, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 10, focus: "Benchmark", level: "Beginner", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 9, name: "45 yd Sprint", distance: 45, reps: 5, rest: 3, focus: "Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 10, name: "50 yd Sprints", distance: 50, reps: 5, rest: 3, focus: "Accel → Top Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 11, name: "50 yd Time Trial", distance: 50, reps: 1, rest: 10, focus: "Benchmark", level: "Intermediate", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 12, name: "55 yd Sprint", distance: 55, reps: 4, rest: 3, focus: "Accel → Top Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 13, name: "60 yd Fly", distance: 60, reps: 6, rest: 4, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 14, name: "65 yd Fly", distance: 65, reps: 5, rest: 4, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 15, name: "70 yd Build", distance: 70, reps: 4, rest: 4, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 16, name: "75 yd Sprint", distance: 75, reps: 3, rest: 5, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 17, name: "80 yd Repeats", distance: 80, reps: 3, rest: 5, focus: "Repeat Sprints", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 18, name: "85 yd Sprint", distance: 85, reps: 3, rest: 5, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 19, name: "90 yd Sprints", distance: 90, reps: 3, rest: 5, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 20, name: "95 yd Sprint", distance: 95, reps: 2, rest: 6, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 21, name: "100 yd Max", distance: 100, reps: 2, rest: 6, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 22, name: "10+20 yd Ladder", distance: 20, reps: 4, rest: 1, focus: "Accel progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 23, name: "15+30 yd Ladder", distance: 30, reps: 3, rest: 2, focus: "Accel → Drive", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 24, name: "20+20 yd Split", distance: 20, reps: 5, rest: 2, focus: "Accel mechanics", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 25, name: "10–20–30 yd Pyramid", distance: 30, reps: 3, rest: 2, focus: "Accel progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 26, name: "20–30–40 yd Pyramid", distance: 40, reps: 3, rest: 2, focus: "Accel → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 27, name: "25–35–45 yd Ladder", distance: 45, reps: 4, rest: 3, focus: "Accel + Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 28, name: "30–40–50 yd Ladder", distance: 50, reps: 3, rest: 3, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 29, name: "40 yd ×6", distance: 40, reps: 6, rest: 2, focus: "Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 30, name: "50 yd ×5", distance: 50, reps: 5, rest: 3, focus: "Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 31, name: "60 yd ×4", distance: 60, reps: 4, rest: 4, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 32, name: "70 yd ×3", distance: 70, reps: 3, rest: 4, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 33, name: "80 yd ×3", distance: 80, reps: 3, rest: 5, focus: "Repeat Sprints", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 34, name: "90 yd ×3", distance: 90, reps: 3, rest: 5, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 35, name: "100 yd ×2", distance: 100, reps: 2, rest: 6, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 36, name: "Flying 10 yd", distance: 10, reps: 6, rest: 2, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 37, name: "Flying 15 yd", distance: 15, reps: 6, rest: 2, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 38, name: "Flying 20 yd", distance: 20, reps: 6, rest: 2, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 39, name: "Flying 25 yd", distance: 25, reps: 5, rest: 3, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 40, name: "Flying 30 yd", distance: 30, reps: 5, rest: 3, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 41, name: "Flying 35 yd", distance: 35, reps: 4, rest: 4, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 42, name: "Flying 40 yd", distance: 40, reps: 4, rest: 4, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 43, name: "Flying 45 yd", distance: 45, reps: 3, rest: 5, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 44, name: "Flying 50 yd", distance: 50, reps: 3, rest: 5, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 45, name: "Split 10+20 yd", distance: 20, reps: 5, rest: 1, focus: "Accel mechanics", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 46, name: "Split 15+25 yd", distance: 25, reps: 5, rest: 2, focus: "Accel mechanics", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 47, name: "Split 20+30 yd", distance: 30, reps: 4, rest: 2, focus: "Accel → Drive", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 48, name: "Split 25+35 yd", distance: 35, reps: 4, rest: 3, focus: "Accel → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 49, name: "Split 30+40 yd", distance: 40, reps: 3, rest: 3, focus: "Top-End Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 50, name: "Split 35+45 yd", distance: 45, reps: 3, rest: 3, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 51, name: "Split 40+50 yd", distance: 50, reps: 3, rest: 3, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 52, name: "20 yd Tempo", distance: 20, reps: 6, rest: 2, focus: "Active Recovery", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 53, name: "30 yd Tempo", distance: 30, reps: 5, rest: 2, focus: "Active Recovery", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 54, name: "40 yd Tempo", distance: 40, reps: 4, rest: 3, focus: "Active Recovery", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 55, name: "50 yd Tempo", distance: 50, reps: 4, rest: 3, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 56, name: "60 yd Tempo", distance: 60, reps: 3, rest: 4, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 57, name: "70 yd Tempo", distance: 70, reps: 3, rest: 4, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 58, name: "80 yd Tempo", distance: 80, reps: 2, rest: 5, focus: "Speed Reserve", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 59, name: "10+20+30 yd Split", distance: 30, reps: 3, rest: 2, focus: "Accel → Drive → Top Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 60, name: "15+25+35 yd Split", distance: 35, reps: 3, rest: 3, focus: "Accel → Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 61, name: "20+30+40 yd Split", distance: 40, reps: 3, rest: 3, focus: "Accel → Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 62, name: "25+35+45 yd Split", distance: 45, reps: 3, rest: 3, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 63, name: "30+40+50 yd Split", distance: 50, reps: 3, rest: 3, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 64, name: "35+45+55 yd Split", distance: 55, reps: 3, rest: 3, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 65, name: "40+50+60 yd Split", distance: 60, reps: 2, rest: 4, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 66, name: "45+55+65 yd Split", distance: 65, reps: 2, rest: 5, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 67, name: "10–40 yd Pyramid", distance: 40, reps: 2, rest: 2, focus: "Accel → Max Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 68, name: "20–50 yd Pyramid", distance: 50, reps: 2, rest: 3, focus: "Accel → Top Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 69, name: "30–60 yd Pyramid", distance: 60, reps: 2, rest: 3, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 70, name: "40–70 yd Pyramid", distance: 70, reps: 2, rest: 3, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 71, name: "50–80 yd Pyramid", distance: 80, reps: 2, rest: 4, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 72, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 10, focus: "Benchmark", level: "Beginner", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 73, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 10, focus: "Benchmark", level: "Intermediate", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 74, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 10, focus: "Benchmark", level: "Advanced", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 75, name: "10×10 yd Starts", distance: 10, reps: 10, rest: 1, focus: "Explosive Starts", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 76, name: "12×10 yd Starts", distance: 10, reps: 12, rest: 1, focus: "First-Step Power", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 77, name: "8×15 yd Accel", distance: 15, reps: 8, rest: 2, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 78, name: "6×20 yd Drive", distance: 20, reps: 6, rest: 2, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 79, name: "5×25 yd Drive", distance: 25, reps: 5, rest: 3, focus: "Drive → Max V", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 80, name: "4×30 yd Sprint", distance: 30, reps: 4, rest: 3, focus: "Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 81, name: "3×35 yd Sprint", distance: 35, reps: 3, rest: 3, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 82, name: "2×40 yd Sprint", distance: 40, reps: 2, rest: 4, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 83, name: "10 yd Flying", distance: 10, reps: 6, rest: 2, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 84, name: "20 yd Flying", distance: 20, reps: 6, rest: 2, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 85, name: "30 yd Flying", distance: 30, reps: 5, rest: 3, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 86, name: "40 yd Flying", distance: 40, reps: 4, rest: 3, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 87, name: "50 yd Flying", distance: 50, reps: 3, rest: 4, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 88, name: "10–20–10 yd Pyramid", distance: 20, reps: 3, rest: 2, focus: "Accel Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 89, name: "15–25–15 yd Pyramid", distance: 25, reps: 3, rest: 3, focus: "Accel → Drive", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 90, name: "20–30–20 yd Pyramid", distance: 30, reps: 3, rest: 3, focus: "Accel → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 91, name: "25–35–25 yd Pyramid", distance: 35, reps: 3, rest: 3, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 92, name: "30–40–30 yd Pyramid", distance: 40, reps: 2, rest: 3, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 93, name: "35–45–35 yd Pyramid", distance: 45, reps: 2, rest: 4, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 94, name: "40–50–40 yd Pyramid", distance: 50, reps: 2, rest: 4, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 95, name: "10×5 yd Shuttle", distance: 5, reps: 10, rest: 1, focus: "Quick Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 96, name: "20×5 yd Shuttle", distance: 5, reps: 20, rest: 1, focus: "Quick Acceleration", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 97, name: "30×5 yd Shuttle", distance: 5, reps: 30, rest: 1, focus: "Quick Acceleration", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 98, name: "10 yd → 20 yd Repeats", distance: 20, reps: 5, rest: 2, focus: "Accel → Drive", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 99, name: "20 yd → 30 yd Repeats", distance: 30, reps: 5, rest: 2, focus: "Drive → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 100, name: "30 yd → 40 yd Repeats", distance: 40, reps: 4, rest: 3, focus: "Drive → Max Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 101, name: "40 yd → 50 yd Repeats", distance: 50, reps: 3, rest: 3, focus: "Max Velocity → Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // MARK: - Elite Training Sessions (102-185)
    SprintSessionTemplate(id: 102, name: "Elite Accel 10 yd ×10", distance: 10, reps: 10, rest: 1, focus: "Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 103, name: "Elite Accel 20 yd ×8", distance: 20, reps: 8, rest: 2, focus: "Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 104, name: "Elite Accel 30 yd ×6", distance: 30, reps: 6, rest: 2, focus: "Drive Phase", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 105, name: "Elite Accel 40 yd ×5", distance: 40, reps: 5, rest: 3, focus: "Drive → Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 106, name: "Elite Fly 10 yd ×6", distance: 10, reps: 6, rest: 2, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 107, name: "Elite Fly 20 yd ×6", distance: 20, reps: 6, rest: 2, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 108, name: "Elite Fly 30 yd ×5", distance: 30, reps: 5, rest: 3, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 109, name: "Elite Fly 40 yd ×4", distance: 40, reps: 4, rest: 3, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 110, name: "Elite Fly 50 yd ×3", distance: 50, reps: 3, rest: 4, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 111, name: "Elite Split 10+20 yd ×6", distance: 20, reps: 6, rest: 2, focus: "Accel Mechanics", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 112, name: "Elite Split 15+25 yd ×5", distance: 25, reps: 5, rest: 3, focus: "Accel → Drive", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 113, name: "Elite Split 20+30 yd ×4", distance: 30, reps: 4, rest: 3, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 114, name: "Elite Split 25+35 yd ×4", distance: 35, reps: 4, rest: 3, focus: "Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 115, name: "Elite Split 30+40 yd ×3", distance: 40, reps: 3, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 116, name: "Elite Split 35+45 yd ×3", distance: 45, reps: 3, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 117, name: "Elite Split 40+50 yd ×2", distance: 50, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 118, name: "Elite Contrast 40 yd Sprint + 60 yd Float ×3", distance: 40, reps: 3, rest: 4, focus: "Speed Contrast", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 119, name: "Elite 40 yd Time Trial", distance: 40, reps: 1, rest: 10, focus: "Benchmark", level: "Elite", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 120, name: "Elite 50 yd Time Trial", distance: 50, reps: 1, rest: 10, focus: "Benchmark", level: "Elite", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 121, name: "Elite 60 yd Time Trial", distance: 60, reps: 1, rest: 10, focus: "Benchmark", level: "Elite", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 122, name: "Elite 70 yd Sprint ×2", distance: 70, reps: 2, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 123, name: "Elite 80 yd Sprint ×2", distance: 80, reps: 2, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 124, name: "Elite 90 yd Sprint ×2", distance: 90, reps: 2, rest: 6, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 125, name: "Elite 100 yd Sprint ×2", distance: 100, reps: 2, rest: 6, focus: "Peak Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 126, name: "Elite Flying 20 yd ×6", distance: 20, reps: 6, rest: 2, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 127, name: "Elite Flying 30 yd ×5", distance: 30, reps: 5, rest: 3, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 128, name: "Elite Flying 40 yd ×4", distance: 40, reps: 4, rest: 3, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 129, name: "Elite Flying 50 yd ×3", distance: 50, reps: 3, rest: 4, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 130, name: "Elite Ladder 10+20+30 yd ×3", distance: 30, reps: 3, rest: 3, focus: "Accel → Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 131, name: "Elite Ladder 20+30+40 yd ×3", distance: 40, reps: 3, rest: 3, focus: "Accel → Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 132, name: "Elite Ladder 30+40+50 yd ×2", distance: 50, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 133, name: "Elite Ladder 40+50+60 yd ×2", distance: 60, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 134, name: "Elite Pyramid 10–20–10 yd ×3", distance: 20, reps: 3, rest: 2, focus: "Accel → Drive", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 135, name: "Elite Pyramid 15–25–15 yd ×3", distance: 25, reps: 3, rest: 3, focus: "Accel → Drive", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 136, name: "Elite Pyramid 20–30–20 yd ×3", distance: 30, reps: 3, rest: 3, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 137, name: "Elite Pyramid 25–35–25 yd ×2", distance: 35, reps: 2, rest: 3, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 138, name: "Elite Pyramid 30–40–30 yd ×2", distance: 40, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 139, name: "Elite Pyramid 35–45–35 yd ×2", distance: 45, reps: 2, rest: 4, focus: "Repeat Sprint", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 140, name: "Elite Pyramid 40–50–40 yd ×2", distance: 50, reps: 2, rest: 4, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 141, name: "Elite Shuttle 5 yd ×10", distance: 5, reps: 10, rest: 1, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 142, name: "Elite Shuttle 5 yd ×15", distance: 5, reps: 15, rest: 1, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 143, name: "Elite Shuttle 5 yd ×20", distance: 5, reps: 20, rest: 1, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 144, name: "Elite Split 10+20 yd ×6", distance: 20, reps: 6, rest: 2, focus: "Acceleration Mechanics", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 145, name: "Elite Split 20+30 yd ×5", distance: 30, reps: 5, rest: 3, focus: "Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 146, name: "Elite Split 30+40 yd ×4", distance: 40, reps: 4, rest: 3, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 147, name: "Elite Split 40+50 yd ×3", distance: 50, reps: 3, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 148, name: "Elite 40 yd Sprint ×5", distance: 40, reps: 5, rest: 3, focus: "Acceleration → Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 149, name: "Elite 50 yd Sprint ×4", distance: 50, reps: 4, rest: 4, focus: "Acceleration → Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 150, name: "Elite 60 yd Sprint ×3", distance: 60, reps: 3, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 151, name: "Elite 70 yd Sprint ×3", distance: 70, reps: 3, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 152, name: "Elite 80 yd Sprint ×2", distance: 80, reps: 2, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 153, name: "Elite 90 yd Sprint ×2", distance: 90, reps: 2, rest: 6, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 154, name: "Elite 100 yd Sprint ×2", distance: 100, reps: 2, rest: 6, focus: "Peak Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 155, name: "Elite Flying 10 yd ×6", distance: 10, reps: 6, rest: 2, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 156, name: "Elite Flying 20 yd ×6", distance: 20, reps: 6, rest: 2, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 157, name: "Elite Flying 30 yd ×5", distance: 30, reps: 5, rest: 3, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 158, name: "Elite Flying 40 yd ×4", distance: 40, reps: 4, rest: 3, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 159, name: "Elite Flying 50 yd ×3", distance: 50, reps: 3, rest: 4, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 160, name: "Elite 40 yd → 60 yd Ladder ×3", distance: 60, reps: 3, rest: 4, focus: "Accel → Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 161, name: "Elite 50 yd → 70 yd Ladder ×2", distance: 70, reps: 2, rest: 5, focus: "Top-End Speed → Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 162, name: "Elite 60 yd → 80 yd Ladder ×2", distance: 80, reps: 2, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 163, name: "Elite 70 yd → 90 yd Ladder ×2", distance: 90, reps: 2, rest: 6, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 164, name: "Elite 80 yd → 100 yd Ladder ×2", distance: 100, reps: 2, rest: 6, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 165, name: "Elite Pyramid 10–30–10 yd ×3", distance: 30, reps: 3, rest: 3, focus: "Accel Progression", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 166, name: "Elite Pyramid 20–40–20 yd ×2", distance: 40, reps: 2, rest: 3, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 167, name: "Elite Pyramid 30–50–30 yd ×2", distance: 50, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 168, name: "Elite Pyramid 40–60–40 yd ×2", distance: 60, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 169, name: "Elite Pyramid 50–70–50 yd ×2", distance: 70, reps: 2, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 170, name: "Elite Shuttle 5 yd ×25", distance: 5, reps: 25, rest: 1, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 171, name: "Elite Shuttle 5 yd ×30", distance: 5, reps: 30, rest: 1, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 172, name: "Elite Split 10+30 yd ×3", distance: 30, reps: 3, rest: 3, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 173, name: "Elite Split 20+40 yd ×3", distance: 40, reps: 3, rest: 3, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 174, name: "Elite Split 30+50 yd ×2", distance: 50, reps: 2, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 175, name: "Elite 40 yd Sprint ×6", distance: 40, reps: 6, rest: 3, focus: "Acceleration → Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 176, name: "Elite 50 yd Sprint ×5", distance: 50, reps: 5, rest: 4, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 177, name: "Elite 60 yd Sprint ×4", distance: 60, reps: 4, rest: 4, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 178, name: "Elite 70 yd Sprint ×3", distance: 70, reps: 3, rest: 5, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 179, name: "Elite 80 yd Sprint ×3", distance: 80, reps: 3, rest: 5, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 180, name: "Elite 90 yd Sprint ×2", distance: 90, reps: 2, rest: 6, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 181, name: "Elite 100 yd Sprint ×2", distance: 100, reps: 2, rest: 6, focus: "Peak Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 182, name: "Elite 110 yd Sprint ×2", distance: 110, reps: 2, rest: 7, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 183, name: "Elite 120 yd Sprint ×2", distance: 120, reps: 2, rest: 8, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 184, name: "Elite 130 yd Sprint ×2", distance: 130, reps: 2, rest: 8, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 185, name: "Elite 150 yd Sprint ×2", distance: 150, reps: 2, rest: 9, focus: "Speed Reserve", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // MARK: - Enhanced Pyramid Sessions (186-230) - All Levels
    // Beginner Pyramids (186-200)
    SprintSessionTemplate(id: 186, name: "Beginner 5-10-15 yd Pyramid", distance: 15, reps: 3, rest: 2, focus: "Acceleration Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 187, name: "Beginner 10-15-20 yd Pyramid", distance: 20, reps: 3, rest: 2, focus: "Speed Build-Up", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 188, name: "Beginner 10-20-30 yd Pyramid", distance: 30, reps: 3, rest: 2, focus: "Distance Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 189, name: "Beginner 15-25-35 yd Pyramid", distance: 35, reps: 3, rest: 2, focus: "Progressive Sprint", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 190, name: "Beginner 5-15-25 yd Pyramid ×2", distance: 25, reps: 6, rest: 2, focus: "Volume Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 191, name: "Beginner Full 10-20-10 yd Pyramid", distance: 20, reps: 3, rest: 2, focus: "Up-Down Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 192, name: "Beginner Full 5-10-15-10-5 yd Pyramid", distance: 15, reps: 5, rest: 1, focus: "Complete Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 193, name: "Beginner 10-20-30-20 yd Pyramid", distance: 30, reps: 4, rest: 2, focus: "Peak & Return", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 194, name: "Beginner 8-16-24 yd Pyramid", distance: 24, reps: 3, rest: 2, focus: "Doubling Pattern", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 195, name: "Beginner 5-10-20 yd Pyramid ×2", distance: 20, reps: 6, rest: 1, focus: "Multi-Set Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 196, name: "Beginner 12-18-24 yd Pyramid", distance: 24, reps: 3, rest: 2, focus: "6-Yard Increments", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 197, name: "Beginner 10-25-40 yd Pyramid", distance: 40, reps: 3, rest: 2, focus: "Large Jumps", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 198, name: "Beginner 15-20-25-20-15 yd Pyramid", distance: 25, reps: 5, rest: 2, focus: "Symmetric Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 199, name: "Beginner 10-15-25-30 yd Pyramid", distance: 30, reps: 4, rest: 2, focus: "Irregular Build", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 200, name: "Beginner 5-20-35 yd Pyramid", distance: 35, reps: 3, rest: 2, focus: "Progressive Leaps", level: "Beginner", sessionType: LibrarySessionType.sprint),
    
    // Intermediate Pyramids (201-215)
    SprintSessionTemplate(id: 201, name: "Intermediate 10-20-30-40 yd Pyramid", distance: 40, reps: 4, rest: 2, focus: "Classic 4-Step Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 202, name: "Intermediate 15-30-45 yd Pyramid", distance: 45, reps: 3, rest: 3, focus: "15-Yard Increments", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 203, name: "Intermediate 10-20-30-40-50 yd Pyramid", distance: 50, reps: 5, rest: 3, focus: "5-Step Progressive", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 204, name: "Intermediate 20-35-50 yd Pyramid", distance: 50, reps: 3, rest: 3, focus: "Power Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 205, name: "Intermediate Full 20-40-60-40-20 yd Pyramid", distance: 60, reps: 5, rest: 3, focus: "Complete Speed Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 206, name: "Intermediate 25-40-55 yd Pyramid ×2", distance: 55, reps: 6, rest: 3, focus: "Double Pyramid Set", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 207, name: "Intermediate 10-25-40-55 yd Pyramid", distance: 55, reps: 4, rest: 3, focus: "Varied Increments", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 208, name: "Intermediate 15-35-55-35-15 yd Pyramid", distance: 55, reps: 5, rest: 3, focus: "Symmetric Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 209, name: "Intermediate 20-30-40-50-60 yd Pyramid", distance: 60, reps: 5, rest: 3, focus: "10-Yard Steps", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 210, name: "Intermediate 12-24-36-48 yd Pyramid", distance: 48, reps: 4, rest: 2, focus: "12-Yard Pattern", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 211, name: "Intermediate 30-45-60 yd Pyramid", distance: 60, reps: 3, rest: 3, focus: "Power Intervals", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 212, name: "Intermediate 10-30-50-30-10 yd Pyramid", distance: 50, reps: 5, rest: 3, focus: "Peak & Descend", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 213, name: "Intermediate 25-50-75 yd Pyramid", distance: 75, reps: 3, rest: 3, focus: "25-Yard Jumps", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 214, name: "Intermediate 20-40-60-40 yd Pyramid", distance: 60, reps: 4, rest: 3, focus: "Peak Speed Focus", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 215, name: "Intermediate 15-25-35-45-55 yd Pyramid", distance: 55, reps: 5, rest: 3, focus: "Steady Progression", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    
    // Advanced Pyramids (216-225)
    SprintSessionTemplate(id: 216, name: "Advanced 20-40-60-80 yd Pyramid", distance: 80, reps: 4, rest: 3, focus: "Power Distance Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 217, name: "Advanced 15-30-45-60-75 yd Pyramid", distance: 75, reps: 5, rest: 3, focus: "15-Yard Increments", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 218, name: "Advanced 25-50-75-100 yd Pyramid", distance: 100, reps: 4, rest: 4, focus: "Quarter Mile Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 219, name: "Advanced Full 30-60-90-60-30 yd Pyramid", distance: 90, reps: 5, rest: 4, focus: "Complete Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 220, name: "Advanced 20-45-70-95 yd Pyramid", distance: 95, reps: 4, rest: 4, focus: "25-Yard Variable", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 221, name: "Advanced 40-60-80-100 yd Pyramid", distance: 100, reps: 4, rest: 4, focus: "Top-End Progression", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 222, name: "Advanced 10-30-50-70-90 yd Pyramid", distance: 90, reps: 5, rest: 3, focus: "20-Yard Steps", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 223, name: "Advanced 35-55-75-55-35 yd Pyramid", distance: 75, reps: 5, rest: 3, focus: "Symmetric Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 224, name: "Advanced 50-75-100 yd Pyramid ×2", distance: 100, reps: 6, rest: 4, focus: "Double Peak Sets", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 225, name: "Advanced 20-50-80-110 yd Pyramid", distance: 110, reps: 4, rest: 4, focus: "Extreme Range Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // Elite Pyramids (226-240) 
    SprintSessionTemplate(id: 226, name: "Elite 30-60-90-120 yd Pyramid", distance: 120, reps: 4, rest: 5, focus: "Elite Distance Progression", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 227, name: "Elite 25-50-75-100-125 yd Pyramid", distance: 125, reps: 5, rest: 5, focus: "5-Step Elite Build", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 228, name: "Elite Full 40-80-120-80-40 yd Pyramid", distance: 120, reps: 5, rest: 5, focus: "Complete Elite Challenge", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 229, name: "Elite 50-100-150 yd Pyramid", distance: 150, reps: 3, rest: 6, focus: "Maximum Distance Build", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 230, name: "Elite 20-40-80-120-160 yd Pyramid", distance: 160, reps: 5, rest: 5, focus: "Elite Speed Reserve", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 231, name: "Elite 35-70-105-140 yd Pyramid", distance: 140, reps: 4, rest: 5, focus: "35-Yard Increments", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 232, name: "Elite 60-90-120-90-60 yd Pyramid", distance: 120, reps: 5, rest: 5, focus: "Elite Symmetric", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 233, name: "Elite 40-70-100-130 yd Pyramid", distance: 130, reps: 4, rest: 5, focus: "30-Yard Variable Steps", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 234, name: "Elite 80-110-140 yd Pyramid ×2", distance: 140, reps: 6, rest: 5, focus: "Double Elite Sets", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 235, name: "Elite 15-45-75-105-135 yd Pyramid", distance: 135, reps: 5, rest: 5, focus: "30-Yard Progressive", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // Mixed Level Challenge Pyramids (236-245)
    SprintSessionTemplate(id: 236, name: "Mixed 10-30-50-70 yd Challenge", distance: 70, reps: 4, rest: 3, focus: "All-Level Adaptable", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 237, name: "Mixed 5-25-45-65 yd Progressive", distance: 65, reps: 4, rest: 3, focus: "20-Yard Steps Universal", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 238, name: "Mixed Full 20-50-80-50-20 yd Pyramid", distance: 80, reps: 5, rest: 3, focus: "Universal Peak Training", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 239, name: "Mixed 12-36-60-84 yd Pattern", distance: 84, reps: 4, rest: 3, focus: "24-Yard Increments", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 240, name: "Mixed 15-40-65-90 yd Ultimate", distance: 90, reps: 4, rest: 3, focus: "25-Yard Ultimate Build", level: "All Levels", sessionType: LibrarySessionType.sprint),

    // MARK: - Recovery & Active Recovery Sessions (Starting at 241)
    
    // Recovery Sessions
    SprintSessionTemplate(id: 241, name: "Beginner Recovery Flow A - Reset & Recharge", distance: 0, reps: 0, rest: 0, focus: "Gentle mobility and breathing", level: "Beginner", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 242, name: "Beginner Recovery Flow B - Grounded Mobility", distance: 0, reps: 0, rest: 0, focus: "Mobility and flexibility", level: "Beginner", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 243, name: "Beginner Recovery Flow C - Full Body Stretch", distance: 0, reps: 0, rest: 0, focus: "Full body flexibility", level: "Beginner", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 244, name: "Intermediate Recovery Flow A - Mobility Reset", distance: 0, reps: 0, rest: 0, focus: "Mobility and breathwork", level: "Intermediate", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 245, name: "Intermediate Recovery Flow B - Deep Tissue Recovery", distance: 0, reps: 0, rest: 0, focus: "Movement and flexibility", level: "Intermediate", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 246, name: "Intermediate Recovery Flow C - Breathe & Balance", distance: 0, reps: 0, rest: 0, focus: "Breathing and relaxation", level: "Intermediate", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 247, name: "Advanced Recovery Flow A - Full Reset Protocol", distance: 0, reps: 0, rest: 0, focus: "Mobility and deep breathing", level: "Advanced", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 248, name: "Advanced Recovery Flow B - Contrast Recovery", distance: 0, reps: 0, rest: 0, focus: "Movement reset and relaxation", level: "Advanced", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 249, name: "Advanced Recovery Flow C - Nervous System Downshift", distance: 0, reps: 0, rest: 0, focus: "Relaxation and mindfulness", level: "Advanced", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 250, name: "Elite Recovery Flow A - Pro Regeneration", distance: 0, reps: 0, rest: 0, focus: "Mobility and recovery breathing", level: "Elite", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 251, name: "Elite Recovery Flow B - Restoration Protocol", distance: 0, reps: 0, rest: 0, focus: "Full body restoration", level: "Elite", sessionType: LibrarySessionType.recovery),
    SprintSessionTemplate(id: 252, name: "Elite Recovery Flow C - Parasympathetic Recovery", distance: 0, reps: 0, rest: 0, focus: "Deep relaxation and mobility", level: "Elite", sessionType: LibrarySessionType.recovery),

    // Active Recovery Sessions
    SprintSessionTemplate(id: 253, name: "Beginner Active Recovery A - Sprint Rhythm", distance: 0, reps: 0, rest: 0, focus: "Rhythm and mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 254, name: "Beginner Active Recovery B - Mobility Flush", distance: 0, reps: 0, rest: 0, focus: "Light tempo and mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 255, name: "Beginner Active Recovery C - Technical Flow", distance: 0, reps: 0, rest: 0, focus: "Technique and movement rhythm", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 256, name: "Intermediate Active Recovery A - Tempo Flush", distance: 0, reps: 0, rest: 0, focus: "Aerobic recovery and stride rhythm", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 257, name: "Intermediate Active Recovery B - Mechanics & Flow", distance: 0, reps: 0, rest: 0, focus: "Technical stride rhythm", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 258, name: "Intermediate Active Recovery C - Aerobic Flush", distance: 0, reps: 0, rest: 0, focus: "Blood flow and rhythm", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 259, name: "Advanced Active Recovery A - Tempo + Mobility", distance: 0, reps: 0, rest: 0, focus: "Movement rhythm and posture", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 260, name: "Advanced Active Recovery B - Technical Reset", distance: 0, reps: 0, rest: 0, focus: "Sprint form and rhythm", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 261, name: "Advanced Active Recovery C - Flush Circuit", distance: 0, reps: 0, rest: 0, focus: "Aerobic maintenance and flow", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 262, name: "Elite Active Recovery A - Sprint Rhythm Maintenance", distance: 0, reps: 0, rest: 0, focus: "Elite stride rhythm", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 263, name: "Elite Active Recovery B - Elite Flow Session", distance: 0, reps: 0, rest: 0, focus: "Technical control and rhythm", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 264, name: "Elite Active Recovery C - CNS Light Stimulus", distance: 0, reps: 0, rest: 0, focus: "Nervous system refresh", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    
    // MARK: - Pyramid Sessions (265-364) - 100 Pyramid Variations
    // BEGINNER PYRAMIDS (Speed Focus - Short Peaks)
    SprintSessionTemplate(id: 265, name: "Mini Pyramid", distance: 20, reps: 5, rest: 1, focus: "Speed Development", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 266, name: "Basic Pyramid", distance: 30, reps: 7, rest: 2, focus: "Speed Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 267, name: "Step Pyramid", distance: 25, reps: 5, rest: 1, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 268, name: "Quick Pyramid", distance: 35, reps: 7, rest: 2, focus: "Speed Development", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 269, name: "Short Pyramid", distance: 40, reps: 7, rest: 2, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 270, name: "Micro Pyramid", distance: 15, reps: 5, rest: 1, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 271, name: "Build Pyramid", distance: 45, reps: 9, rest: 2, focus: "Speed Endurance", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 272, name: "Fast Pyramid", distance: 50, reps: 9, rest: 3, focus: "Speed Endurance", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 273, name: "Power Pyramid", distance: 30, reps: 9, rest: 2, focus: "Power Development", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 274, name: "Drive Pyramid", distance: 35, reps: 9, rest: 2, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    
    // INTERMEDIATE PYRAMIDS (Balanced Speed-Endurance)
    SprintSessionTemplate(id: 275, name: "Classic Pyramid", distance: 40, reps: 7, rest: 2, focus: "Progressive Distance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 276, name: "Extended Pyramid", distance: 60, reps: 11, rest: 3, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 277, name: "Double Pyramid", distance: 50, reps: 13, rest: 3, focus: "Endurance Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 278, name: "Peak Pyramid", distance: 70, reps: 13, rest: 4, focus: "Peak Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 279, name: "Wave Pyramid", distance: 55, reps: 11, rest: 3, focus: "Speed Waves", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 280, name: "Climb Pyramid", distance: 65, reps: 11, rest: 3, focus: "Progressive Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 281, name: "Flow Pyramid", distance: 45, reps: 9, rest: 2, focus: "Rhythm Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 282, name: "Tempo Pyramid", distance: 75, reps: 13, rest: 4, focus: "Tempo Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 283, name: "Stride Pyramid", distance: 80, reps: 15, rest: 4, focus: "Stride Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 284, name: "Rhythm Pyramid", distance: 55, reps: 9, rest: 3, focus: "Rhythm Development", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    
    // ADVANCED PYRAMIDS (Endurance Focus - Longer Peaks)
    SprintSessionTemplate(id: 285, name: "Endurance Pyramid", distance: 100, reps: 19, rest: 5, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 286, name: "Distance Pyramid", distance: 90, reps: 17, rest: 5, focus: "Distance Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 287, name: "Long Pyramid", distance: 85, reps: 15, rest: 4, focus: "Long Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 288, name: "Volume Pyramid", distance: 95, reps: 17, rest: 5, focus: "Volume Training", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 289, name: "Capacity Pyramid", distance: 80, reps: 13, rest: 4, focus: "Speed Capacity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 290, name: "Power Endurance Pyramid", distance: 75, reps: 11, rest: 4, focus: "Power Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 291, name: "Max Pyramid", distance: 100, reps: 21, rest: 5, focus: "Maximum Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 292, name: "Elite Pyramid", distance: 90, reps: 19, rest: 5, focus: "Elite Development", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 293, name: "Challenge Pyramid", distance: 85, reps: 17, rest: 4, focus: "Challenge Training", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 294, name: "Ultimate Pyramid", distance: 95, reps: 19, rest: 5, focus: "Ultimate Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // ELITE PYRAMIDS (Maximum Endurance - Complex Patterns)
    SprintSessionTemplate(id: 295, name: "Master Pyramid", distance: 100, reps: 21, rest: 5, focus: "Master Level", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 296, name: "Champion Pyramid", distance: 95, reps: 19, rest: 5, focus: "Championship Training", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 297, name: "Pro Pyramid", distance: 90, reps: 17, rest: 5, focus: "Professional Level", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 298, name: "Olympic Pyramid", distance: 100, reps: 23, rest: 5, focus: "Olympic Preparation", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 299, name: "World Class Pyramid", distance: 95, reps: 21, rest: 5, focus: "World Class Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 300, name: "Record Pyramid", distance: 90, reps: 19, rest: 5, focus: "Record Breaking", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 301, name: "Legendary Pyramid", distance: 100, reps: 25, rest: 5, focus: "Legendary Performance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 302, name: "Supreme Pyramid", distance: 85, reps: 15, rest: 4, focus: "Supreme Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 303, name: "Apex Pyramid", distance: 95, reps: 17, rest: 5, focus: "Apex Performance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 304, name: "Peak Performance Pyramid", distance: 100, reps: 27, rest: 5, focus: "Peak Performance", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // SPECIALIZED PYRAMIDS (Unique Patterns & Increments)
    SprintSessionTemplate(id: 305, name: "Fibonacci Pyramid", distance: 55, reps: 9, rest: 3, focus: "Mathematical Progression", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 306, name: "Golden Pyramid", distance: 62, reps: 11, rest: 3, focus: "Golden Ratio", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 307, name: "Prime Pyramid", distance: 47, reps: 9, rest: 141, focus: "Prime Numbers", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 308, name: "Odd Pyramid", distance: 45, reps: 9, rest: 2, focus: "Odd Increments", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 309, name: "Even Pyramid", distance: 60, reps: 11, rest: 3, focus: "Even Increments", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 310, name: "Mixed Pyramid", distance: 67, reps: 13, rest: 3, focus: "Mixed Increments", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 311, name: "Random Pyramid", distance: 73, reps: 11, rest: 4, focus: "Random Progression", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 312, name: "Chaos Pyramid", distance: 58, reps: 13, rest: 3, focus: "Chaos Training", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 313, name: "Custom Pyramid", distance: 85, reps: 15, rest: 4, focus: "Custom Pattern", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 314, name: "Adaptive Pyramid", distance: 70, reps: 13, rest: 4, focus: "Adaptive Training", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // MICRO PYRAMIDS (5-yard increments)
    SprintSessionTemplate(id: 315, name: "Micro Speed Pyramid", distance: 25, reps: 7, rest: 1, focus: "Micro Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 316, name: "Fine Pyramid", distance: 35, reps: 9, rest: 2, focus: "Fine Tuning", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 317, name: "Precision Pyramid", distance: 45, reps: 11, rest: 2, focus: "Precision Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 318, name: "Detail Pyramid", distance: 55, reps: 13, rest: 3, focus: "Detail Work", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 319, name: "Refined Pyramid", distance: 65, reps: 15, rest: 3, focus: "Refined Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // MACRO PYRAMIDS (15-20 yard increments)
    SprintSessionTemplate(id: 320, name: "Macro Pyramid", distance: 80, reps: 9, rest: 4, focus: "Macro Progression", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 321, name: "Big Step Pyramid", distance: 100, reps: 11, rest: 5, focus: "Big Steps", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 322, name: "Giant Pyramid", distance: 90, reps: 9, rest: 5, focus: "Giant Steps", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 323, name: "Massive Pyramid", distance: 100, reps: 13, rest: 5, focus: "Massive Progression", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // ASYMMETRIC PYRAMIDS (Different up/down patterns)
    SprintSessionTemplate(id: 324, name: "Steep Pyramid", distance: 60, reps: 9, rest: 3, focus: "Steep Climb", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 325, name: "Gentle Pyramid", distance: 50, reps: 13, rest: 3, focus: "Gentle Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 326, name: "Skewed Pyramid", distance: 70, reps: 11, rest: 4, focus: "Asymmetric Pattern", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 327, name: "Lopsided Pyramid", distance: 65, reps: 13, rest: 3, focus: "Uneven Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // DOUBLE PEAK PYRAMIDS
    SprintSessionTemplate(id: 328, name: "Twin Peak Pyramid", distance: 60, reps: 15, rest: 3, focus: "Double Peak", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 329, name: "Double Summit Pyramid", distance: 70, reps: 17, rest: 4, focus: "Two Summits", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 330, name: "Dual Apex Pyramid", distance: 80, reps: 19, rest: 4, focus: "Dual Peaks", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // TRIPLE PEAK PYRAMIDS
    SprintSessionTemplate(id: 331, name: "Triple Peak Pyramid", distance: 50, reps: 21, rest: 3, focus: "Triple Peak", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 332, name: "Three Summit Pyramid", distance: 60, reps: 23, rest: 3, focus: "Three Summits", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // PLATEAU PYRAMIDS (Flat tops)
    SprintSessionTemplate(id: 333, name: "Plateau Pyramid", distance: 40, reps: 11, rest: 2, focus: "Plateau Training", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 334, name: "Mesa Pyramid", distance: 60, reps: 15, rest: 3, focus: "Mesa Pattern", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 335, name: "Table Pyramid", distance: 80, reps: 17, rest: 4, focus: "Table Top", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // WAVE PYRAMIDS (Multiple peaks and valleys)
    SprintSessionTemplate(id: 336, name: "Wave Pattern Pyramid", distance: 70, reps: 19, rest: 4, focus: "Wave Pattern", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 337, name: "Oscillating Pyramid", distance: 60, reps: 17, rest: 3, focus: "Oscillation", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 338, name: "Ripple Pyramid", distance: 50, reps: 15, rest: 3, focus: "Ripple Effect", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // SPEED-SPECIFIC PYRAMIDS
    SprintSessionTemplate(id: 339, name: "Acceleration Pyramid", distance: 30, reps: 9, rest: 2, focus: "Acceleration Focus", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 340, name: "Max Velocity Pyramid", distance: 50, reps: 11, rest: 3, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 341, name: "Speed Maintenance Pyramid", distance: 70, reps: 13, rest: 4, focus: "Speed Maintenance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 342, name: "Deceleration Pyramid", distance: 90, reps: 15, rest: 5, focus: "Deceleration Control", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // ENDURANCE-SPECIFIC PYRAMIDS
    SprintSessionTemplate(id: 343, name: "Short Endurance Pyramid", distance: 60, reps: 13, rest: 2, focus: "Short Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 344, name: "Medium Endurance Pyramid", distance: 80, reps: 15, rest: 3, focus: "Medium Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 345, name: "Long Endurance Pyramid", distance: 100, reps: 17, rest: 3, focus: "Long Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // RECOVERY PYRAMIDS (Active recovery focus)
    SprintSessionTemplate(id: 346, name: "Recovery Pyramid", distance: 40, reps: 9, rest: 3, focus: "Active Recovery", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 347, name: "Easy Pyramid", distance: 30, reps: 7, rest: 3, focus: "Easy Pace", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 348, name: "Gentle Build Pyramid", distance: 50, reps: 11, rest: 3, focus: "Gentle Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    
    // POWER PYRAMIDS (Explosive focus)
    SprintSessionTemplate(id: 349, name: "Explosive Pyramid", distance: 35, reps: 7, rest: 4, focus: "Explosive Power", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 350, name: "Power Burst Pyramid", distance: 45, reps: 9, rest: 5, focus: "Power Bursts", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 351, name: "Dynamic Pyramid", distance: 55, reps: 11, rest: 6, focus: "Dynamic Power", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // TECHNICAL PYRAMIDS (Form focus)
    SprintSessionTemplate(id: 352, name: "Form Pyramid", distance: 40, reps: 9, rest: 2, focus: "Form Development", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 353, name: "Technique Pyramid", distance: 50, reps: 11, rest: 3, focus: "Technique Work", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 354, name: "Mechanics Pyramid", distance: 60, reps: 13, rest: 3, focus: "Mechanics Focus", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // SEASONAL PYRAMIDS (Periodization)
    SprintSessionTemplate(id: 355, name: "Base Building Pyramid", distance: 70, reps: 15, rest: 2, focus: "Base Building", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 356, name: "Competition Prep Pyramid", distance: 50, reps: 9, rest: 5, focus: "Competition Prep", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 357, name: "Peak Season Pyramid", distance: 40, reps: 7, rest: 6, focus: "Peak Performance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 358, name: "Off Season Pyramid", distance: 80, reps: 17, rest: 3, focus: "Off Season", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    
    // WEATHER-SPECIFIC PYRAMIDS
    SprintSessionTemplate(id: 359, name: "Wind Training Pyramid", distance: 60, reps: 11, rest: 3, focus: "Wind Resistance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 360, name: "Heat Adaptation Pyramid", distance: 50, reps: 9, rest: 4, focus: "Heat Training", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 361, name: "Cold Weather Pyramid", distance: 40, reps: 11, rest: 2, focus: "Cold Adaptation", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    
    // FINAL SPECIALTY PYRAMIDS
    SprintSessionTemplate(id: 362, name: "Mental Toughness Pyramid", distance: 90, reps: 19, rest: 3, focus: "Mental Strength", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 363, name: "Breakthrough Pyramid", distance: 100, reps: 21, rest: 3, focus: "Performance Breakthrough", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 364, name: "Ultimate Challenge Pyramid", distance: 100, reps: 25, rest: 4, focus: "Ultimate Challenge", level: "Elite", sessionType: LibrarySessionType.sprint)
]

// MARK: - Comprehensive Session Templates

/// Comprehensive session that includes full workout flow (warm-up, drills, strides, sprints, cool-down)
/// This template represents a complete workout session using the comprehensive library structure
/// Use ComprehensiveSessionLibrary.swift for full 185-session implementation
let comprehensiveSessionTemplate = SprintSessionTemplate(
    id: 186, 
    name: "SC40 Complete Workout", 
    distance: 40, // Main sprint distance
    reps: 4, // Main sprint reps 
    rest: 3, // Main sprint rest
    focus: "Acceleration & Mechanics", 
    level: "All Levels", 
    sessionType: LibrarySessionType.comprehensive
)

// MARK: - Enhanced Session Library Integration
/// Integration point for comprehensive session library
/// For the full 185-session comprehensive library, see ComprehensiveSessionLibrary.swift

// MARK: - Weekly Program Templates with Rest and Active Recovery

// Helper function to create rest and active recovery sessions
extension DaySessionTemplate {
    static func restDay(dayNumber: Int) -> DaySessionTemplate {
        DaySessionTemplate(
            dayNumber: dayNumber,
            sessionTemplate: nil,
            sessionType: LibrarySessionType.rest,
            notes: "Complete rest day - no training"
        )
    }
    
    static func activeRecoveryDay(dayNumber: Int, level: String) -> DaySessionTemplate {
        let activeRecoverySession: SprintSessionTemplate
        
        switch level {
        case "Beginner":
            activeRecoverySession = sessionLibrary.first { $0.id == 52 }! // 20 yd Tempo
        case "Intermediate":
            activeRecoverySession = sessionLibrary.first { $0.id == 54 }! // 40 yd Tempo
        case "Advanced":
            activeRecoverySession = sessionLibrary.first { $0.id == 56 }! // 60 yd Tempo
        default: // Elite
            activeRecoverySession = sessionLibrary.first { $0.id == 58 }! // 80 yd Tempo
        }
        
        return DaySessionTemplate(
            dayNumber: dayNumber,
            sessionTemplate: activeRecoverySession,
            sessionType: LibrarySessionType.activeRecovery,
            notes: "Light tempo work for active recovery"
        )
    }
}

// MARK: - Sample Weekly Program Templates

let weeklyProgramTemplates: [WeeklyProgramTemplate] = [
    
    // MARK: - 3-Day Programs
    WeeklyProgramTemplate(
        level: "Beginner",
        weekNumber: 1,
        totalDays: 3,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 1 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 3 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 3, sessionTemplate: sessionLibrary.first { $0.id == 8 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    // MARK: - 4-Day Programs
    WeeklyProgramTemplate(
        level: "Intermediate",
        weekNumber: 1,
        totalDays: 4,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 10 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 13 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 3, sessionTemplate: sessionLibrary.first { $0.id == 15 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 11 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    // MARK: - 5-Day Programs
    WeeklyProgramTemplate(
        level: "Advanced",
        weekNumber: 1,
        totalDays: 5,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 16 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 17 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 3, sessionTemplate: sessionLibrary.first { $0.id == 20 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 21 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 5, sessionTemplate: sessionLibrary.first { $0.id == 73 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    // MARK: - 6-Day Programs (with Active Recovery)
    WeeklyProgramTemplate(
        level: "Beginner",
        weekNumber: 1,
        totalDays: 6,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 1 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 3 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.activeRecoveryDay(dayNumber: 3, level: "Beginner"),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 5 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 5, sessionTemplate: sessionLibrary.first { $0.id == 7 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 6, sessionTemplate: sessionLibrary.first { $0.id == 8 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    WeeklyProgramTemplate(
        level: "Intermediate",
        weekNumber: 1,
        totalDays: 6,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 10 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 13 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.activeRecoveryDay(dayNumber: 3, level: "Intermediate"),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 15 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 5, sessionTemplate: sessionLibrary.first { $0.id == 26 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 6, sessionTemplate: sessionLibrary.first { $0.id == 11 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    WeeklyProgramTemplate(
        level: "Advanced",
        weekNumber: 1,
        totalDays: 6,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 16 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 17 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.activeRecoveryDay(dayNumber: 3, level: "Advanced"),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 20 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 5, sessionTemplate: sessionLibrary.first { $0.id == 21 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 6, sessionTemplate: sessionLibrary.first { $0.id == 74 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    // MARK: - 7-Day Programs (with Rest Day)
    WeeklyProgramTemplate(
        level: "Beginner",
        weekNumber: 1,
        totalDays: 7,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 1 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 3 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.activeRecoveryDay(dayNumber: 3, level: "Beginner"),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 5 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.restDay(dayNumber: 5),
            DaySessionTemplate(dayNumber: 6, sessionTemplate: sessionLibrary.first { $0.id == 7 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 7, sessionTemplate: sessionLibrary.first { $0.id == 8 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    WeeklyProgramTemplate(
        level: "Intermediate",
        weekNumber: 1,
        totalDays: 7,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 10 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 13 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.activeRecoveryDay(dayNumber: 3, level: "Intermediate"),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 15 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.restDay(dayNumber: 5),
            DaySessionTemplate(dayNumber: 6, sessionTemplate: sessionLibrary.first { $0.id == 26 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 7, sessionTemplate: sessionLibrary.first { $0.id == 11 }!, sessionType: LibrarySessionType.benchmark)
        ]
    ),
    
    WeeklyProgramTemplate(
        level: "Advanced",
        weekNumber: 1,
        totalDays: 7,
        sessions: [
            DaySessionTemplate(dayNumber: 1, sessionTemplate: sessionLibrary.first { $0.id == 16 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 2, sessionTemplate: sessionLibrary.first { $0.id == 17 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.activeRecoveryDay(dayNumber: 3, level: "Advanced"),
            DaySessionTemplate(dayNumber: 4, sessionTemplate: sessionLibrary.first { $0.id == 20 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate.restDay(dayNumber: 5),
            DaySessionTemplate(dayNumber: 6, sessionTemplate: sessionLibrary.first { $0.id == 21 }!, sessionType: LibrarySessionType.sprint),
            DaySessionTemplate(dayNumber: 7, sessionTemplate: sessionLibrary.first { $0.id == 74 }!, sessionType: LibrarySessionType.benchmark)
        ]
    )
]

// MARK: - Sample 12-Week Programs with Integrated 40-Yard Time Trials

let sample12WeekPrograms: [String: [WeeklyProgramTemplate]] = [
    "Beginner_5Day": WeeklyProgramTemplate.generate12WeekProgram(
        level: "Beginner",
        totalDaysPerWeek: 5,
        includeActiveRecovery: true,
        includeRestDay: false
    ),
    
    "Intermediate_6Day": WeeklyProgramTemplate.generate12WeekProgram(
        level: "Intermediate",
        totalDaysPerWeek: 6,
        includeActiveRecovery: true,
        includeRestDay: false
    ),
    
    "Advanced_7Day": WeeklyProgramTemplate.generate12WeekProgram(
        level: "Advanced",
        totalDaysPerWeek: 7,
        includeActiveRecovery: true,
        includeRestDay: true
    ),
    
    "Elite_7Day": WeeklyProgramTemplate.generate12WeekProgram(
        level: "Elite",
        totalDaysPerWeek: 7,
        includeActiveRecovery: true,
        includeRestDay: true
    )
]

// MARK: - Time Trial Tracking Helper

struct TimeTrialResult: Codable, Identifiable {
    let id: UUID
    let weekNumber: Int
    let time: Double // in seconds
    let date: Date
    let level: String
    let notes: String?
    
    init(weekNumber: Int, time: Double, level: String, notes: String? = nil) {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.time = time
        self.date = Date()
        self.level = level
        self.notes = notes
    }
}

extension WeeklyProgramTemplate {
    /// Gets all time trial weeks in a 12-week program
    static var timeTrialWeeks: [Int] {
        return [1, 4, 8, 12]
    }
    
    /// Calculates expected improvement based on week progression
    static func expectedImprovement(fromWeek startWeek: Int, toWeek endWeek: Int, baselineTime: Double) -> Double {
        let weeksDifference = endWeek - startWeek
        let improvementPercentage = Double(weeksDifference) * 0.015 // 1.5% improvement per week
        return baselineTime * (1.0 - improvementPercentage)
    }
}

// MARK: - Program Generation Helper Functions

/// Classifies a 40-yard dash time into training levels based on gender-specific performance standards
func classify_40yd_time(time: Float, gender: String) -> String {
    let normalizedGender = gender.lowercased()
    
    switch normalizedGender {
    case "male":
        if time >= 6.0 {
            return "Beginner"
        } else if time >= 5.2 {
            return "Intermediate"
        } else if time >= 4.6 {
            return "Advanced"
        } else {
            return "Elite"
        }
        
    case "female":
        if time >= 6.5 {
            return "Beginner"
        } else if time >= 5.7 {
            return "Intermediate"
        } else if time >= 5.2 {
            return "Advanced"
        } else {
            return "Elite"
        }
        
    default:
        // Default to male standards if gender is not recognized
        if time >= 6.0 {
            return "Beginner"
        } else if time >= 5.2 {
            return "Intermediate"
        } else if time >= 4.6 {
            return "Advanced"
        } else {
            return "Elite"
        }
    }
}

extension WeeklyProgramTemplate {
    
    /// Gets sessions for a specific training level
    static func sessionsForLevel(_ level: String) -> [SprintSessionTemplate] {
        return sessionLibrary.filter { $0.level == level }
    }
    
    /// Gets sessions by type
    static func sessionsByType(_ type: LibrarySessionType, level: String) -> [SprintSessionTemplate] {
        return sessionLibrary.filter { $0.sessionType == type && $0.level == level }
    }
    
    /// Generates a weekly program based on parameters with intelligent session selection
    static func generateWeeklyProgram(
        level: String,
        totalDays: Int,
        weekNumber: Int,
        includeActiveRecovery: Bool = true,
        includeRestDay: Bool = true
    ) -> WeeklyProgramTemplate {
        
        let availableSessions = sessionsForLevel(level)
        let benchmarkSessions = sessionsByType(.benchmark, level: level)
        
        var sessions: [DaySessionTemplate] = []
        
        // Check if this week should include a 40-yard time trial
        let isTimeTrialWeek = is40YardTimeTrialWeek(weekNumber)
        
        // Get sessions for this week based on progression
        let weekSessions = selectSessionsForWeek(
            weekNumber: weekNumber,
            level: level,
            totalDays: totalDays,
            availableSessions: availableSessions
        )
        var sessionIndex = 0
        var consecutiveTrainingDays = 0
        
        for day in 1...totalDays {
            // Check if we need rest or active recovery after 5 consecutive training days
            if consecutiveTrainingDays >= 5 {
                if includeActiveRecovery && includeRestDay {
                    // Alternate between active recovery and rest after 5 training days
                    if (day - 1) % 2 == 0 {
                        sessions.append(DaySessionTemplate.activeRecoveryDay(dayNumber: day, level: level))
                    } else {
                        sessions.append(DaySessionTemplate.restDay(dayNumber: day))
                    }
                } else if includeActiveRecovery {
                    sessions.append(DaySessionTemplate.activeRecoveryDay(dayNumber: day, level: level))
                } else if includeRestDay {
                    sessions.append(DaySessionTemplate.restDay(dayNumber: day))
                } else {
                    // If neither rest nor active recovery is enabled, continue with training
                    if sessionIndex < weekSessions.count {
                        sessions.append(DaySessionTemplate(
                            dayNumber: day,
                            sessionTemplate: weekSessions[sessionIndex],
                            sessionType: LibrarySessionType.sprint
                        ))
                        sessionIndex += 1
                        consecutiveTrainingDays += 1
                        continue
                    }
                }
                consecutiveTrainingDays = 0 // Reset counter after rest/recovery
            } else if isTimeTrialWeek && day == totalDays {
                // Add 40-yard time trial on last day of time trial weeks
                let timeTrialSession = get40YardTimeTrialSession(for: level)
                sessions.append(DaySessionTemplate(
                    dayNumber: day,
                    sessionTemplate: timeTrialSession,
                    sessionType: LibrarySessionType.benchmark,
                    notes: "40-yard time trial - Week \(weekNumber) assessment"
                ))
                consecutiveTrainingDays += 1
            } else if !isTimeTrialWeek && day == totalDays && !benchmarkSessions.isEmpty {
                // Add regular benchmark session on last day of non-time trial weeks
                let randomBenchmark = benchmarkSessions.randomElement()!
                sessions.append(DaySessionTemplate(
                    dayNumber: day,
                    sessionTemplate: randomBenchmark,
                    sessionType: LibrarySessionType.benchmark
                ))
                consecutiveTrainingDays += 1
            } else if sessionIndex < weekSessions.count {
                // Add regular sprint session
                sessions.append(DaySessionTemplate(
                    dayNumber: day,
                    sessionTemplate: weekSessions[sessionIndex],
                    sessionType: LibrarySessionType.sprint
                ))
                sessionIndex += 1
                consecutiveTrainingDays += 1
            }
        }
        
        return WeeklyProgramTemplate(
            level: level,
            weekNumber: weekNumber,
            totalDays: totalDays,
            sessions: sessions
        )
    }
    
    /// Intelligently selects sessions for a specific week based on training progression
    static func selectSessionsForWeek(
        weekNumber: Int,
        level: String,
        totalDays: Int,
        availableSessions: [SprintSessionTemplate]
    ) -> [SprintSessionTemplate] {
        
        // Calculate how many training sessions we need
        // With new consecutive training day rule, we estimate max training sessions
        // Rest/recovery will be dynamically inserted after every 5 consecutive training days
        var trainingDaysNeeded = totalDays
        
        // Estimate rest/recovery days based on total days and 5-day rule
        let estimatedRestRecoveryDays = max(0, (totalDays - 1) / 6) // Every 6th day (after 5 training days)
        trainingDaysNeeded -= estimatedRestRecoveryDays
        trainingDaysNeeded -= 1 // Benchmark day
        
        // Filter sessions by focus area based on week progression
        let weekPhase = getTrainingPhase(for: weekNumber)
        let focusedSessions = availableSessions.filter { session in
            return sessionMatchesPhase(session, phase: weekPhase)
        }
        
        // If we don't have enough focused sessions, add general sessions
        var selectedSessions = focusedSessions
        if selectedSessions.count < trainingDaysNeeded {
            let generalSessions = availableSessions.filter { session in
                !focusedSessions.contains(session)
            }
            selectedSessions.append(contentsOf: generalSessions)
        }
        
        // Apply user preferences if available (favorites get higher priority)
        selectedSessions = prioritizeUserPreferences(sessions: selectedSessions, userPreferences: nil)
        
        // Shuffle and select the needed number of sessions
        selectedSessions.shuffle()
        return Array(selectedSessions.prefix(trainingDaysNeeded))
    }
    
    /// Determines the training phase based on week number
    static func getTrainingPhase(for weekNumber: Int) -> TrainingPhase {
        switch weekNumber {
        case 1...3:
            return .foundation
        case 4...6:
            return .acceleration
        case 7...9:
            return .maxVelocity
        case 10...12:
            return .peakPerformance
        default:
            return .foundation
        }
    }
    
    /// Checks if a session matches the current training phase
    static func sessionMatchesPhase(_ session: SprintSessionTemplate, phase: TrainingPhase) -> Bool {
        let focus = session.focus.lowercased()
        
        switch phase {
        case .foundation:
            return focus.contains("acceleration") || 
                   focus.contains("accel") || 
                   focus.contains("drive") ||
                   focus.contains("starts")
        case .acceleration:
            return focus.contains("acceleration") || 
                   focus.contains("accel") || 
                   focus.contains("drive") ||
                   focus.contains("progression")
        case .maxVelocity:
            return focus.contains("max velocity") || 
                   focus.contains("max speed") || 
                   focus.contains("speed") ||
                   focus.contains("velocity") ||
                   focus.contains("flying")
        case .peakPerformance:
            return focus.contains("peak") || 
                   focus.contains("top-end") || 
                   focus.contains("repeat") ||
                   focus.contains("endurance") ||
                   focus.contains("max velocity")
        }
    }
    
    /// Training phases for 12-week progression
    enum TrainingPhase {
        case foundation      // Weeks 1-3: Basic acceleration and mechanics
        case acceleration    // Weeks 4-6: Advanced acceleration development
        case maxVelocity     // Weeks 7-9: Maximum velocity development
        case peakPerformance // Weeks 10-12: Peak performance and speed endurance
    }
    
    /// Determines if a given week should include a 40-yard time trial
    /// Time trials are scheduled at weeks 1, 4, 8, and 12 for optimal progression tracking
    static func is40YardTimeTrialWeek(_ weekNumber: Int) -> Bool {
        return [1, 4, 8, 12].contains(weekNumber)
    }
    
    /// Gets the appropriate 40-yard time trial session for the given level
    static func get40YardTimeTrialSession(for level: String) -> SprintSessionTemplate {
        switch level {
        case "Beginner":
            return sessionLibrary.first { $0.id == 72 }! // 40 yd Time Trial - Beginner
        case "Intermediate":
            return sessionLibrary.first { $0.id == 73 }! // 40 yd Time Trial - Intermediate
        case "Advanced":
            return sessionLibrary.first { $0.id == 74 }! // 40 yd Time Trial - Advanced
        default: // Elite
            return sessionLibrary.first { $0.id == 119 }! // Elite 40 yd Time Trial
        }
    }
    
    /// Generates a complete 12-week program with integrated 40-yard time trials
    static func generate12WeekProgram(
        level: String,
        totalDaysPerWeek: Int,
        includeActiveRecovery: Bool = true,
        includeRestDay: Bool = true
    ) -> [WeeklyProgramTemplate] {
        
        var program: [WeeklyProgramTemplate] = []
        
        for week in 1...12 {
            let weeklyProgram = generateWeeklyProgram(
                level: level,
                totalDays: totalDaysPerWeek,
                weekNumber: week,
                includeActiveRecovery: includeActiveRecovery,
                includeRestDay: includeRestDay
            )
            program.append(weeklyProgram)
        }
        
        return program
    }
    
    /// Analyzes session distribution in a 12-week program
    static func analyzeSessionDistribution(for level: String, totalDaysPerWeek: Int) -> SessionDistributionAnalysis {
        let program = generate12WeekProgram(
            level: level,
            totalDaysPerWeek: totalDaysPerWeek
        )
        
        var usedSessionIds: Set<Int> = []
        var sessionUsageCount: [Int: Int] = [:]
        var totalTrainingSessions = 0
        
        for week in program {
            for day in week.sessions {
                if let sessionTemplate = day.sessionTemplate {
                    usedSessionIds.insert(sessionTemplate.id)
                    sessionUsageCount[sessionTemplate.id, default: 0] += 1
                    if day.sessionType == .sprint {
                        totalTrainingSessions += 1
                    }
                }
            }
        }
        
        let availableSessionsForLevel = sessionsForLevel(level)
        let totalAvailableForLevel = availableSessionsForLevel.count
        let totalUsed = usedSessionIds.count
        let utilizationPercentage = Double(totalUsed) / Double(totalAvailableForLevel) * 100
        
        return SessionDistributionAnalysis(
            level: level,
            totalDaysPerWeek: totalDaysPerWeek,
            totalAvailableForLevel: totalAvailableForLevel,
            totalUsedSessions: totalUsed,
            utilizationPercentage: utilizationPercentage,
            totalTrainingSessions: totalTrainingSessions,
            usedSessionIds: Array(usedSessionIds).sorted(),
            sessionUsageCount: sessionUsageCount
        )
    }
}

// MARK: - User Preference & Favorite System

struct UserSessionPreferences {
    let favoriteTemplateIDs: [Int]
    let preferredTemplateIDs: [Int] 
    let dislikedTemplateIDs: [Int]
    let allowRepeatingFavorites: Bool
    let manualOverrides: [UUID: Int]
}

extension WeeklyProgramTemplate {
    
    /// Prioritizes sessions based on user preferences and favorites
    static func prioritizeUserPreferences(sessions: [SprintSessionTemplate], userPreferences: UserSessionPreferences?) -> [SprintSessionTemplate] {
        guard let preferences = userPreferences else { 
            return sessions 
        }
        
        var prioritized: [SprintSessionTemplate] = []
        var regular: [SprintSessionTemplate] = []
        
        // Separate sessions by user preference
        for session in sessions {
            // Skip disliked sessions unless no alternatives
            if preferences.dislikedTemplateIDs.contains(session.id) {
                continue 
            }
            
            // Prioritize favorites and preferred sessions
            if preferences.favoriteTemplateIDs.contains(session.id) || 
               preferences.preferredTemplateIDs.contains(session.id) {
                prioritized.append(session)
            } else {
                regular.append(session)
            }
        }
        
        // If allowing repeating favorites, add them multiple times for higher probability
        if preferences.allowRepeatingFavorites {
            let favorites = prioritized.filter { preferences.favoriteTemplateIDs.contains($0.id) }
            prioritized.append(contentsOf: favorites) // Double the favorites
        }
        
        // Combine with prioritized sessions first
        return prioritized + regular
    }
    
    /// Gets user's favorite sessions that match their current level
    static func getUserFavoriteSessions(for userProfile: UserProfile) -> [SprintSessionTemplate] {
        let userLevel = userProfile.level
        return sessionLibrary.filter { session in
            userProfile.favoriteSessionTemplateIDs.contains(session.id) && 
            (session.level == userLevel || session.level == "All Levels")
        }
    }
    
    /// Allows user to manually select a specific session for a given slot
    static func createManualSessionOverride(sessionID: UUID, templateID: Int, userProfile: inout UserProfile) {
        userProfile.manualSessionOverrides[sessionID] = templateID
        print("👆 User manually selected session template \(templateID) for session \(sessionID)")
    }
    
    /// Enhanced program generation with user preference support and algorithmic optimization
    static func generateWithUserPreferences(
        level: String,
        totalDaysPerWeek: Int,
        userPreferences: UserSessionPreferences,
        includeActiveRecovery: Bool = true,
        includeRestDay: Bool = true
    ) -> [WeeklyProgramTemplate] {
        
        var program: [WeeklyProgramTemplate] = []
        
        for week in 1...12 {
            // Use algorithmic generation for optimal session distribution
            let weeklyProgram = generateAlgorithmicWeeklyProgram(
                level: level,
                totalDays: totalDaysPerWeek,
                weekNumber: week,
                userPreferences: userPreferences,
                includeActiveRecovery: includeActiveRecovery,
                includeRestDay: includeRestDay
            )
            program.append(weeklyProgram)
        }
        
        return program
    }
    
    /// NEW: Algorithmic weekly program generation using all session types
    static func generateAlgorithmicWeeklyProgram(
        level: String,
        totalDays: Int,
        weekNumber: Int,
        userPreferences: UserSessionPreferences,
        includeActiveRecovery: Bool = true,
        includeRestDay: Bool = true
    ) -> WeeklyProgramTemplate {
        
        // Collect performance data for algorithmic optimization
        let performanceData = AlgorithmicSessionGenerator.shared.collectPerformanceData(from: [])
        
        // Generate sessions using algorithmic approach with all session types
        let algorithmicSessions = AlgorithmicSessionGenerator.shared.generateAlgorithmicWeeklyProgram(
            level: level,
            frequency: totalDays,
            weekNumber: weekNumber,
            userPreferences: userPreferences,
            performanceData: performanceData
        )
        
        return WeeklyProgramTemplate(
            level: level,
            weekNumber: weekNumber,
            totalDays: totalDays,
            sessions: algorithmicSessions
        )
    }
    
    /// Enhanced weekly program generation with user preferences
    static func generateWeeklyProgramWithPreferences(
        level: String,
        totalDays: Int,
        weekNumber: Int,
        userPreferences: UserSessionPreferences,
        includeActiveRecovery: Bool = true,
        includeRestDay: Bool = true
    ) -> WeeklyProgramTemplate {
        
        let availableSessions = sessionsForLevel(level)
        let benchmarkSessions = sessionsByType(.benchmark, level: level)
        
        var sessions: [DaySessionTemplate] = []
        
        // Check if this week should include a 40-yard time trial
        let isTimeTrialWeek = is40YardTimeTrialWeek(weekNumber)
        
        // Get sessions for this week based on progression AND user preferences
        let weekSessions = selectSessionsForWeekWithPreferences(
            weekNumber: weekNumber,
            level: level,
            totalDays: totalDays,
            availableSessions: availableSessions,
            userPreferences: userPreferences
        )
        
        var sessionIndex = 0
        var consecutiveTrainingDays = 0
        
        for day in 1...totalDays {
            // Apply manual overrides first
            if let overrideTemplateID = userPreferences.manualOverrides.first(where: { $0.key.uuidString.contains("W\(weekNumber)D\(day)") })?.value,
               let overrideTemplate = sessionLibrary.first(where: { $0.id == overrideTemplateID }) {
                sessions.append(DaySessionTemplate(
                    dayNumber: day,
                    sessionTemplate: overrideTemplate,
                    sessionType: overrideTemplate.sessionType,
                    notes: "👆 User selected: \(overrideTemplate.name)"
                ))
                consecutiveTrainingDays += 1
                continue
            }
            
            // Rest/recovery logic with consecutive day tracking
            if consecutiveTrainingDays >= 5 && includeActiveRecovery {
                if includeRestDay && day % 7 == 0 {
                    sessions.append(DaySessionTemplate.restDay(dayNumber: day))
                } else {
                    sessions.append(DaySessionTemplate.activeRecoveryDay(dayNumber: day, level: level))
                }
                consecutiveTrainingDays = 0
            } else {
                // Check for time trial or benchmark
                if isTimeTrialWeek && day == totalDays {
                    let timeTrialSession = get40YardTimeTrialSession(for: level)
                    sessions.append(DaySessionTemplate(
                        dayNumber: day,
                        sessionTemplate: timeTrialSession,
                        sessionType: LibrarySessionType.benchmark,
                        notes: "40-yard time trial - Week \(weekNumber) assessment"
                    ))
                    consecutiveTrainingDays += 1
                } else if !isTimeTrialWeek && day == totalDays && !benchmarkSessions.isEmpty {
                    let randomBenchmark = benchmarkSessions.randomElement()!
                    sessions.append(DaySessionTemplate(
                        dayNumber: day,
                        sessionTemplate: randomBenchmark,
                        sessionType: LibrarySessionType.benchmark
                    ))
                    consecutiveTrainingDays += 1
                } else if sessionIndex < weekSessions.count {
                    // Add regular sprint session with user preference weighting
                    let selectedSession = weekSessions[sessionIndex]
                    let note = userPreferences.favoriteTemplateIDs.contains(selectedSession.id) ? 
                        "⭐ Favorite: \(selectedSession.name)" : nil
                    
                    sessions.append(DaySessionTemplate(
                        dayNumber: day,
                        sessionTemplate: selectedSession,
                        sessionType: LibrarySessionType.sprint,
                        notes: note
                    ))
                    sessionIndex += 1
                    consecutiveTrainingDays += 1
                }
            }
        }
        
        return WeeklyProgramTemplate(
            level: level,
            weekNumber: weekNumber,
            totalDays: totalDays,
            sessions: sessions
        )
    }
    
    /// Enhanced session selection with user preferences
    static func selectSessionsForWeekWithPreferences(
        weekNumber: Int,
        level: String,
        totalDays: Int,
        availableSessions: [SprintSessionTemplate],
        userPreferences: UserSessionPreferences
    ) -> [SprintSessionTemplate] {
        
        // Calculate how many training sessions we need
        var trainingDaysNeeded = totalDays
        let estimatedRestRecoveryDays = max(0, (totalDays - 1) / 6)
        trainingDaysNeeded -= estimatedRestRecoveryDays
        trainingDaysNeeded -= 1 // Benchmark day
        
        // Filter sessions by focus area based on week progression
        let weekPhase = getTrainingPhase(for: weekNumber)
        let focusedSessions = availableSessions.filter { session in
            return sessionMatchesPhase(session, phase: weekPhase)
        }
        
        // Remove disliked sessions unless no alternatives exist
        var availableForSelection = focusedSessions.filter { session in
            !userPreferences.dislikedTemplateIDs.contains(session.id)
        }
        
        // If filtering removed too many sessions, add back some alternatives
        if availableForSelection.count < trainingDaysNeeded {
            let generalSessions = availableSessions.filter { session in
                !focusedSessions.contains(session) && 
                !userPreferences.dislikedTemplateIDs.contains(session.id)
            }
            availableForSelection.append(contentsOf: generalSessions)
        }
        
        // Apply user preference prioritization
        let prioritizedSessions = prioritizeUserPreferences(
            sessions: availableForSelection, 
            userPreferences: userPreferences
        )
        
        // Shuffle and select
        var selectedSessions = prioritizedSessions
        selectedSessions.shuffle()
        return Array(selectedSessions.prefix(trainingDaysNeeded))
    }
}

// MARK: - Session Distribution Analysis

struct SessionDistributionAnalysis {
    let level: String
    let totalDaysPerWeek: Int
    let totalAvailableForLevel: Int
    let totalUsedSessions: Int
    let utilizationPercentage: Double
    let totalTrainingSessions: Int
    let usedSessionIds: [Int]
    let sessionUsageCount: [Int: Int]
    
    var description: String {
        return """
        Session Distribution Analysis for \(level) (\(totalDaysPerWeek) days/week):
        - Available sessions for level: \(totalAvailableForLevel)
        - Used sessions: \(totalUsedSessions)
        - Utilization: \(String(format: "%.1f", utilizationPercentage))%
        - Total training sessions over 12 weeks: \(totalTrainingSessions)
        - Average sessions per week: \(String(format: "%.1f", Double(totalTrainingSessions) / 12.0))
        """
    }
}

// Remove duplicate TrainingSession and SprintSet definitions from this file.
// Use the canonical definitions from SprintSetAndTrainingSession.swift

// MARK: - Testing and Validation Functions

#if DEBUG
extension WeeklyProgramTemplate {
    /// Test function to show session distribution across all levels
    static func printSessionDistributionAnalysis() {
        let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
        let dayOptions = [5, 6, 7]
        
        print("=== SESSION DISTRIBUTION ANALYSIS ===\n")
        
        for level in levels {
            for days in dayOptions {
                let analysis = analyzeSessionDistribution(for: level, totalDaysPerWeek: days)
                print(analysis.description)
                print("Used session IDs: \(analysis.usedSessionIds)")
                print("---")
            }
        }
        
        // Show total session counts by level
        print("\n=== TOTAL SESSIONS BY LEVEL ===")
        for level in levels {
            let levelSessions = sessionsForLevel(level)
            print("\(level): \(levelSessions.count) sessions available")
            
            // Show focus distribution
            let focusDistribution = Dictionary(grouping: levelSessions) { $0.focus }
            print("Focus areas: \(focusDistribution.keys.sorted())")
        }
    }
}
#endif
