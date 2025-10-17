import Foundation
import Combine

// MARK: - Sprint Session Template for Library

struct SprintSessionTemplate: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let distance: Int // yards
    let reps: Int
    let rest: Int // seconds
    let focus: String
    let level: String
    let sessionType: LibrarySessionType
}

enum LibrarySessionType: String, Codable, CaseIterable {
    case sprint = "Sprint"
    case activeRecovery = "Active Recovery"
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
    SprintSessionTemplate(id: 1, name: "10-20-30-40-30-20-10 yd Pyramid", distance: 40, reps: 7, rest: 120, focus: "Up-Down Pyramid", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 2, name: "15 yd Starts", distance: 15, reps: 10, rest: 60, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 3, name: "20 yd Accel", distance: 20, reps: 6, rest: 90, focus: "Early Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 4, name: "25 yd Accel", distance: 25, reps: 8, rest: 90, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 5, name: "30 yd Drive", distance: 30, reps: 6, rest: 120, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 6, name: "35 yd Drive", distance: 35, reps: 5, rest: 120, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 7, name: "40 yd Repeats", distance: 40, reps: 6, rest: 150, focus: "Max Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 8, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Beginner", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 9, name: "45 yd Sprint", distance: 45, reps: 5, rest: 150, focus: "Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 10, name: "50 yd Sprints", distance: 50, reps: 5, rest: 180, focus: "Accel → Top Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 11, name: "50 yd Time Trial", distance: 50, reps: 1, rest: 600, focus: "Benchmark", level: "Intermediate", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 12, name: "55 yd Sprint", distance: 55, reps: 4, rest: 180, focus: "Accel → Top Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 13, name: "60 yd Fly", distance: 60, reps: 6, rest: 240, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 14, name: "65 yd Fly", distance: 65, reps: 5, rest: 240, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 15, name: "70 yd Build", distance: 70, reps: 4, rest: 240, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 16, name: "75 yd Sprint", distance: 75, reps: 3, rest: 300, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 17, name: "80 yd Repeats", distance: 80, reps: 3, rest: 300, focus: "Repeat Sprints", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 18, name: "85 yd Sprint", distance: 85, reps: 3, rest: 300, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 19, name: "90 yd Sprints", distance: 90, reps: 3, rest: 300, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 20, name: "95 yd Sprint", distance: 95, reps: 2, rest: 360, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 21, name: "100 yd Max", distance: 100, reps: 2, rest: 360, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 22, name: "10+20 yd Ladder", distance: 20, reps: 4, rest: 60, focus: "Accel progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 23, name: "15+30 yd Ladder", distance: 30, reps: 3, rest: 90, focus: "Accel → Drive", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 24, name: "20+20 yd Split", distance: 20, reps: 5, rest: 90, focus: "Accel mechanics", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 25, name: "10–20–30 yd Pyramid", distance: 30, reps: 3, rest: 120, focus: "Accel progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 26, name: "20–30–40 yd Pyramid", distance: 40, reps: 3, rest: 120, focus: "Accel → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 27, name: "25–35–45 yd Ladder", distance: 45, reps: 4, rest: 150, focus: "Accel + Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 28, name: "30–40–50 yd Ladder", distance: 50, reps: 3, rest: 180, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 29, name: "40 yd ×6", distance: 40, reps: 6, rest: 120, focus: "Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 30, name: "50 yd ×5", distance: 50, reps: 5, rest: 180, focus: "Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 31, name: "60 yd ×4", distance: 60, reps: 4, rest: 240, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 32, name: "70 yd ×3", distance: 70, reps: 3, rest: 240, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 33, name: "80 yd ×3", distance: 80, reps: 3, rest: 300, focus: "Repeat Sprints", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 34, name: "90 yd ×3", distance: 90, reps: 3, rest: 300, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 35, name: "100 yd ×2", distance: 100, reps: 2, rest: 360, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 36, name: "Flying 10 yd", distance: 10, reps: 6, rest: 90, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 37, name: "Flying 15 yd", distance: 15, reps: 6, rest: 120, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 38, name: "Flying 20 yd", distance: 20, reps: 6, rest: 120, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 39, name: "Flying 25 yd", distance: 25, reps: 5, rest: 150, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 40, name: "Flying 30 yd", distance: 30, reps: 5, rest: 180, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 41, name: "Flying 35 yd", distance: 35, reps: 4, rest: 240, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 42, name: "Flying 40 yd", distance: 40, reps: 4, rest: 240, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 43, name: "Flying 45 yd", distance: 45, reps: 3, rest: 300, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 44, name: "Flying 50 yd", distance: 50, reps: 3, rest: 300, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 45, name: "Split 10+20 yd", distance: 20, reps: 5, rest: 60, focus: "Accel mechanics", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 46, name: "Split 15+25 yd", distance: 25, reps: 5, rest: 90, focus: "Accel mechanics", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 47, name: "Split 20+30 yd", distance: 30, reps: 4, rest: 120, focus: "Accel → Drive", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 48, name: "Split 25+35 yd", distance: 35, reps: 4, rest: 150, focus: "Accel → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 49, name: "Split 30+40 yd", distance: 40, reps: 3, rest: 180, focus: "Top-End Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 50, name: "Split 35+45 yd", distance: 45, reps: 3, rest: 180, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 51, name: "Split 40+50 yd", distance: 50, reps: 3, rest: 180, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 52, name: "20 yd Tempo", distance: 20, reps: 6, rest: 90, focus: "Active Recovery", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 53, name: "30 yd Tempo", distance: 30, reps: 5, rest: 120, focus: "Active Recovery", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 54, name: "40 yd Tempo", distance: 40, reps: 4, rest: 150, focus: "Active Recovery", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 55, name: "50 yd Tempo", distance: 50, reps: 4, rest: 180, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 56, name: "60 yd Tempo", distance: 60, reps: 3, rest: 240, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 57, name: "70 yd Tempo", distance: 70, reps: 3, rest: 240, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 58, name: "80 yd Tempo", distance: 80, reps: 2, rest: 300, focus: "Speed Reserve", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 59, name: "10+20+30 yd Split", distance: 30, reps: 3, rest: 120, focus: "Accel → Drive → Top Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 60, name: "15+25+35 yd Split", distance: 35, reps: 3, rest: 150, focus: "Accel → Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 61, name: "20+30+40 yd Split", distance: 40, reps: 3, rest: 150, focus: "Accel → Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 62, name: "25+35+45 yd Split", distance: 45, reps: 3, rest: 180, focus: "Speed Endurance", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 63, name: "30+40+50 yd Split", distance: 50, reps: 3, rest: 180, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 64, name: "35+45+55 yd Split", distance: 55, reps: 3, rest: 180, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 65, name: "40+50+60 yd Split", distance: 60, reps: 2, rest: 240, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 66, name: "45+55+65 yd Split", distance: 65, reps: 2, rest: 300, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 67, name: "10–40 yd Pyramid", distance: 40, reps: 2, rest: 120, focus: "Accel → Max Speed", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 68, name: "20–50 yd Pyramid", distance: 50, reps: 2, rest: 150, focus: "Accel → Top Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 69, name: "30–60 yd Pyramid", distance: 60, reps: 2, rest: 180, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 70, name: "40–70 yd Pyramid", distance: 70, reps: 2, rest: 180, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 71, name: "50–80 yd Pyramid", distance: 80, reps: 2, rest: 240, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 72, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Beginner", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 73, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Intermediate", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 74, name: "40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Advanced", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 75, name: "10×10 yd Starts", distance: 10, reps: 10, rest: 60, focus: "Explosive Starts", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 76, name: "12×10 yd Starts", distance: 10, reps: 12, rest: 60, focus: "First-Step Power", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 77, name: "8×15 yd Accel", distance: 15, reps: 8, rest: 90, focus: "Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 78, name: "6×20 yd Drive", distance: 20, reps: 6, rest: 120, focus: "Drive Phase", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 79, name: "5×25 yd Drive", distance: 25, reps: 5, rest: 150, focus: "Drive → Max V", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 80, name: "4×30 yd Sprint", distance: 30, reps: 4, rest: 180, focus: "Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 81, name: "3×35 yd Sprint", distance: 35, reps: 3, rest: 180, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 82, name: "2×40 yd Sprint", distance: 40, reps: 2, rest: 240, focus: "Peak Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 83, name: "10 yd Flying", distance: 10, reps: 6, rest: 90, focus: "Max Velocity", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 84, name: "20 yd Flying", distance: 20, reps: 6, rest: 120, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 85, name: "30 yd Flying", distance: 30, reps: 5, rest: 150, focus: "Max Velocity", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 86, name: "40 yd Flying", distance: 40, reps: 4, rest: 180, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 87, name: "50 yd Flying", distance: 50, reps: 3, rest: 240, focus: "Max Velocity", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 88, name: "10–20–10 yd Pyramid", distance: 20, reps: 3, rest: 120, focus: "Accel Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 89, name: "15–25–15 yd Pyramid", distance: 25, reps: 3, rest: 150, focus: "Accel → Drive", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 90, name: "20–30–20 yd Pyramid", distance: 30, reps: 3, rest: 180, focus: "Accel → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 91, name: "25–35–25 yd Pyramid", distance: 35, reps: 3, rest: 180, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 92, name: "30–40–30 yd Pyramid", distance: 40, reps: 2, rest: 180, focus: "Top-End Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 93, name: "35–45–35 yd Pyramid", distance: 45, reps: 2, rest: 240, focus: "Repeat Sprint", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 94, name: "40–50–40 yd Pyramid", distance: 50, reps: 2, rest: 240, focus: "Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 95, name: "10×5 yd Shuttle", distance: 5, reps: 10, rest: 30, focus: "Quick Acceleration", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 96, name: "20×5 yd Shuttle", distance: 5, reps: 20, rest: 30, focus: "Quick Acceleration", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 97, name: "30×5 yd Shuttle", distance: 5, reps: 30, rest: 30, focus: "Quick Acceleration", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 98, name: "10 yd → 20 yd Repeats", distance: 20, reps: 5, rest: 90, focus: "Accel → Drive", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 99, name: "20 yd → 30 yd Repeats", distance: 30, reps: 5, rest: 120, focus: "Drive → Max Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 100, name: "30 yd → 40 yd Repeats", distance: 40, reps: 4, rest: 150, focus: "Drive → Max Speed", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 101, name: "40 yd → 50 yd Repeats", distance: 50, reps: 3, rest: 180, focus: "Max Velocity → Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // MARK: - Elite Training Sessions (102-185)
    SprintSessionTemplate(id: 102, name: "Elite Accel 10 yd ×10", distance: 10, reps: 10, rest: 60, focus: "Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 103, name: "Elite Accel 20 yd ×8", distance: 20, reps: 8, rest: 90, focus: "Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 104, name: "Elite Accel 30 yd ×6", distance: 30, reps: 6, rest: 120, focus: "Drive Phase", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 105, name: "Elite Accel 40 yd ×5", distance: 40, reps: 5, rest: 150, focus: "Drive → Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 106, name: "Elite Fly 10 yd ×6", distance: 10, reps: 6, rest: 90, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 107, name: "Elite Fly 20 yd ×6", distance: 20, reps: 6, rest: 120, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 108, name: "Elite Fly 30 yd ×5", distance: 30, reps: 5, rest: 150, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 109, name: "Elite Fly 40 yd ×4", distance: 40, reps: 4, rest: 180, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 110, name: "Elite Fly 50 yd ×3", distance: 50, reps: 3, rest: 240, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 111, name: "Elite Split 10+20 yd ×6", distance: 20, reps: 6, rest: 120, focus: "Accel Mechanics", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 112, name: "Elite Split 15+25 yd ×5", distance: 25, reps: 5, rest: 150, focus: "Accel → Drive", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 113, name: "Elite Split 20+30 yd ×4", distance: 30, reps: 4, rest: 180, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 114, name: "Elite Split 25+35 yd ×4", distance: 35, reps: 4, rest: 180, focus: "Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 115, name: "Elite Split 30+40 yd ×3", distance: 40, reps: 3, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 116, name: "Elite Split 35+45 yd ×3", distance: 45, reps: 3, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 117, name: "Elite Split 40+50 yd ×2", distance: 50, reps: 2, rest: 240, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 118, name: "Elite Contrast 40 yd Sprint + 60 yd Float ×3", distance: 40, reps: 3, rest: 240, focus: "Speed Contrast", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 119, name: "Elite 40 yd Time Trial", distance: 40, reps: 1, rest: 600, focus: "Benchmark", level: "Elite", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 120, name: "Elite 50 yd Time Trial", distance: 50, reps: 1, rest: 600, focus: "Benchmark", level: "Elite", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 121, name: "Elite 60 yd Time Trial", distance: 60, reps: 1, rest: 600, focus: "Benchmark", level: "Elite", sessionType: LibrarySessionType.benchmark),
    SprintSessionTemplate(id: 122, name: "Elite 70 yd Sprint ×2", distance: 70, reps: 2, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 123, name: "Elite 80 yd Sprint ×2", distance: 80, reps: 2, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 124, name: "Elite 90 yd Sprint ×2", distance: 90, reps: 2, rest: 360, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 125, name: "Elite 100 yd Sprint ×2", distance: 100, reps: 2, rest: 360, focus: "Peak Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 126, name: "Elite Flying 20 yd ×6", distance: 20, reps: 6, rest: 120, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 127, name: "Elite Flying 30 yd ×5", distance: 30, reps: 5, rest: 150, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 128, name: "Elite Flying 40 yd ×4", distance: 40, reps: 4, rest: 180, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 129, name: "Elite Flying 50 yd ×3", distance: 50, reps: 3, rest: 240, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 130, name: "Elite Ladder 10+20+30 yd ×3", distance: 30, reps: 3, rest: 150, focus: "Accel → Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 131, name: "Elite Ladder 20+30+40 yd ×3", distance: 40, reps: 3, rest: 180, focus: "Accel → Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 132, name: "Elite Ladder 30+40+50 yd ×2", distance: 50, reps: 2, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 133, name: "Elite Ladder 40+50+60 yd ×2", distance: 60, reps: 2, rest: 240, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 134, name: "Elite Pyramid 10–20–10 yd ×3", distance: 20, reps: 3, rest: 120, focus: "Accel → Drive", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 135, name: "Elite Pyramid 15–25–15 yd ×3", distance: 25, reps: 3, rest: 150, focus: "Accel → Drive", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 136, name: "Elite Pyramid 20–30–20 yd ×3", distance: 30, reps: 3, rest: 180, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 137, name: "Elite Pyramid 25–35–25 yd ×2", distance: 35, reps: 2, rest: 180, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 138, name: "Elite Pyramid 30–40–30 yd ×2", distance: 40, reps: 2, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 139, name: "Elite Pyramid 35–45–35 yd ×2", distance: 45, reps: 2, rest: 240, focus: "Repeat Sprint", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 140, name: "Elite Pyramid 40–50–40 yd ×2", distance: 50, reps: 2, rest: 240, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 141, name: "Elite Shuttle 5 yd ×10", distance: 5, reps: 10, rest: 30, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 142, name: "Elite Shuttle 5 yd ×15", distance: 5, reps: 15, rest: 30, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 143, name: "Elite Shuttle 5 yd ×20", distance: 5, reps: 20, rest: 30, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 144, name: "Elite Split 10+20 yd ×6", distance: 20, reps: 6, rest: 120, focus: "Acceleration Mechanics", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 145, name: "Elite Split 20+30 yd ×5", distance: 30, reps: 5, rest: 150, focus: "Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 146, name: "Elite Split 30+40 yd ×4", distance: 40, reps: 4, rest: 180, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 147, name: "Elite Split 40+50 yd ×3", distance: 50, reps: 3, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 148, name: "Elite 40 yd Sprint ×5", distance: 40, reps: 5, rest: 180, focus: "Acceleration → Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 149, name: "Elite 50 yd Sprint ×4", distance: 50, reps: 4, rest: 210, focus: "Acceleration → Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 150, name: "Elite 60 yd Sprint ×3", distance: 60, reps: 3, rest: 240, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 151, name: "Elite 70 yd Sprint ×3", distance: 70, reps: 3, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 152, name: "Elite 80 yd Sprint ×2", distance: 80, reps: 2, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 153, name: "Elite 90 yd Sprint ×2", distance: 90, reps: 2, rest: 360, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 154, name: "Elite 100 yd Sprint ×2", distance: 100, reps: 2, rest: 360, focus: "Peak Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 155, name: "Elite Flying 10 yd ×6", distance: 10, reps: 6, rest: 90, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 156, name: "Elite Flying 20 yd ×6", distance: 20, reps: 6, rest: 120, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 157, name: "Elite Flying 30 yd ×5", distance: 30, reps: 5, rest: 150, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 158, name: "Elite Flying 40 yd ×4", distance: 40, reps: 4, rest: 180, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 159, name: "Elite Flying 50 yd ×3", distance: 50, reps: 3, rest: 240, focus: "Max Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 160, name: "Elite 40 yd → 60 yd Ladder ×3", distance: 60, reps: 3, rest: 240, focus: "Accel → Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 161, name: "Elite 50 yd → 70 yd Ladder ×2", distance: 70, reps: 2, rest: 300, focus: "Top-End Speed → Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 162, name: "Elite 60 yd → 80 yd Ladder ×2", distance: 80, reps: 2, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 163, name: "Elite 70 yd → 90 yd Ladder ×2", distance: 90, reps: 2, rest: 360, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 164, name: "Elite 80 yd → 100 yd Ladder ×2", distance: 100, reps: 2, rest: 360, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 165, name: "Elite Pyramid 10–30–10 yd ×3", distance: 30, reps: 3, rest: 150, focus: "Accel Progression", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 166, name: "Elite Pyramid 20–40–20 yd ×2", distance: 40, reps: 2, rest: 180, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 167, name: "Elite Pyramid 30–50–30 yd ×2", distance: 50, reps: 2, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 168, name: "Elite Pyramid 40–60–40 yd ×2", distance: 60, reps: 2, rest: 240, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 169, name: "Elite Pyramid 50–70–50 yd ×2", distance: 70, reps: 2, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 170, name: "Elite Shuttle 5 yd ×25", distance: 5, reps: 25, rest: 30, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 171, name: "Elite Shuttle 5 yd ×30", distance: 5, reps: 30, rest: 30, focus: "Quick Acceleration", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 172, name: "Elite Split 10+30 yd ×3", distance: 30, reps: 3, rest: 150, focus: "Accel → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 173, name: "Elite Split 20+40 yd ×3", distance: 40, reps: 3, rest: 180, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 174, name: "Elite Split 30+50 yd ×2", distance: 50, reps: 2, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 175, name: "Elite 40 yd Sprint ×6", distance: 40, reps: 6, rest: 180, focus: "Acceleration → Drive → Max Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 176, name: "Elite 50 yd Sprint ×5", distance: 50, reps: 5, rest: 210, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 177, name: "Elite 60 yd Sprint ×4", distance: 60, reps: 4, rest: 240, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 178, name: "Elite 70 yd Sprint ×3", distance: 70, reps: 3, rest: 300, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 179, name: "Elite 80 yd Sprint ×3", distance: 80, reps: 3, rest: 300, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 180, name: "Elite 90 yd Sprint ×2", distance: 90, reps: 2, rest: 360, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 181, name: "Elite 100 yd Sprint ×2", distance: 100, reps: 2, rest: 360, focus: "Peak Velocity", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 182, name: "Elite 110 yd Sprint ×2", distance: 110, reps: 2, rest: 420, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 183, name: "Elite 120 yd Sprint ×2", distance: 120, reps: 2, rest: 480, focus: "Speed Endurance", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 184, name: "Elite 130 yd Sprint ×2", distance: 130, reps: 2, rest: 480, focus: "Top-End Speed", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 185, name: "Elite 150 yd Sprint ×2", distance: 150, reps: 2, rest: 540, focus: "Speed Reserve", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // MARK: - Enhanced Pyramid Sessions (186-230) - All Levels
    // Beginner Pyramids (186-200)
    SprintSessionTemplate(id: 186, name: "Beginner 5-10-15 yd Pyramid", distance: 15, reps: 3, rest: 90, focus: "Acceleration Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 187, name: "Beginner 10-15-20 yd Pyramid", distance: 20, reps: 3, rest: 100, focus: "Speed Build-Up", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 188, name: "Beginner 10-20-30 yd Pyramid", distance: 30, reps: 3, rest: 120, focus: "Distance Progression", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 189, name: "Beginner 15-25-35 yd Pyramid", distance: 35, reps: 3, rest: 140, focus: "Progressive Sprint", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 190, name: "Beginner 5-15-25 yd Pyramid ×2", distance: 25, reps: 6, rest: 90, focus: "Volume Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 191, name: "Beginner Full 10-20-10 yd Pyramid", distance: 20, reps: 3, rest: 100, focus: "Up-Down Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 192, name: "Beginner Full 5-10-15-10-5 yd Pyramid", distance: 15, reps: 5, rest: 80, focus: "Complete Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 193, name: "Beginner 10-20-30-20 yd Pyramid", distance: 30, reps: 4, rest: 110, focus: "Peak & Return", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 194, name: "Beginner 8-16-24 yd Pyramid", distance: 24, reps: 3, rest: 105, focus: "Doubling Pattern", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 195, name: "Beginner 5-10-20 yd Pyramid ×2", distance: 20, reps: 6, rest: 85, focus: "Multi-Set Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 196, name: "Beginner 12-18-24 yd Pyramid", distance: 24, reps: 3, rest: 110, focus: "6-Yard Increments", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 197, name: "Beginner 10-25-40 yd Pyramid", distance: 40, reps: 3, rest: 130, focus: "Large Jumps", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 198, name: "Beginner 15-20-25-20-15 yd Pyramid", distance: 25, reps: 5, rest: 95, focus: "Symmetric Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 199, name: "Beginner 10-15-25-30 yd Pyramid", distance: 30, reps: 4, rest: 115, focus: "Irregular Build", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 200, name: "Beginner 5-20-35 yd Pyramid", distance: 35, reps: 3, rest: 125, focus: "Progressive Leaps", level: "Beginner", sessionType: LibrarySessionType.sprint),
    
    // Intermediate Pyramids (201-215)
    SprintSessionTemplate(id: 201, name: "Intermediate 10-20-30-40 yd Pyramid", distance: 40, reps: 4, rest: 140, focus: "Classic 4-Step Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 202, name: "Intermediate 15-30-45 yd Pyramid", distance: 45, reps: 3, rest: 160, focus: "15-Yard Increments", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 203, name: "Intermediate 10-20-30-40-50 yd Pyramid", distance: 50, reps: 5, rest: 150, focus: "5-Step Progressive", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 204, name: "Intermediate 20-35-50 yd Pyramid", distance: 50, reps: 3, rest: 170, focus: "Power Build", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 205, name: "Intermediate Full 20-40-60-40-20 yd Pyramid", distance: 60, reps: 5, rest: 160, focus: "Complete Speed Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 206, name: "Intermediate 25-40-55 yd Pyramid ×2", distance: 55, reps: 6, rest: 150, focus: "Double Pyramid Set", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 207, name: "Intermediate 10-25-40-55 yd Pyramid", distance: 55, reps: 4, rest: 165, focus: "Varied Increments", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 208, name: "Intermediate 15-35-55-35-15 yd Pyramid", distance: 55, reps: 5, rest: 155, focus: "Symmetric Speed", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 209, name: "Intermediate 20-30-40-50-60 yd Pyramid", distance: 60, reps: 5, rest: 170, focus: "10-Yard Steps", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 210, name: "Intermediate 12-24-36-48 yd Pyramid", distance: 48, reps: 4, rest: 145, focus: "12-Yard Pattern", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 211, name: "Intermediate 30-45-60 yd Pyramid", distance: 60, reps: 3, rest: 180, focus: "Power Intervals", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 212, name: "Intermediate 10-30-50-30-10 yd Pyramid", distance: 50, reps: 5, rest: 150, focus: "Peak & Descend", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 213, name: "Intermediate 25-50-75 yd Pyramid", distance: 75, reps: 3, rest: 200, focus: "25-Yard Jumps", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 214, name: "Intermediate 20-40-60-40 yd Pyramid", distance: 60, reps: 4, rest: 165, focus: "Peak Speed Focus", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 215, name: "Intermediate 15-25-35-45-55 yd Pyramid", distance: 55, reps: 5, rest: 155, focus: "Steady Progression", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    
    // Advanced Pyramids (216-225)
    SprintSessionTemplate(id: 216, name: "Advanced 20-40-60-80 yd Pyramid", distance: 80, reps: 4, rest: 200, focus: "Power Distance Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 217, name: "Advanced 15-30-45-60-75 yd Pyramid", distance: 75, reps: 5, rest: 190, focus: "15-Yard Increments", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 218, name: "Advanced 25-50-75-100 yd Pyramid", distance: 100, reps: 4, rest: 240, focus: "Quarter Mile Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 219, name: "Advanced Full 30-60-90-60-30 yd Pyramid", distance: 90, reps: 5, rest: 210, focus: "Complete Speed Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 220, name: "Advanced 20-45-70-95 yd Pyramid", distance: 95, reps: 4, rest: 220, focus: "25-Yard Variable", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 221, name: "Advanced 40-60-80-100 yd Pyramid", distance: 100, reps: 4, rest: 250, focus: "Top-End Progression", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 222, name: "Advanced 10-30-50-70-90 yd Pyramid", distance: 90, reps: 5, rest: 200, focus: "20-Yard Steps", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 223, name: "Advanced 35-55-75-55-35 yd Pyramid", distance: 75, reps: 5, rest: 185, focus: "Symmetric Endurance", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 224, name: "Advanced 50-75-100 yd Pyramid ×2", distance: 100, reps: 6, rest: 220, focus: "Double Peak Sets", level: "Advanced", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 225, name: "Advanced 20-50-80-110 yd Pyramid", distance: 110, reps: 4, rest: 260, focus: "Extreme Range Build", level: "Advanced", sessionType: LibrarySessionType.sprint),
    
    // Elite Pyramids (226-240) 
    SprintSessionTemplate(id: 226, name: "Elite 30-60-90-120 yd Pyramid", distance: 120, reps: 4, rest: 300, focus: "Elite Distance Progression", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 227, name: "Elite 25-50-75-100-125 yd Pyramid", distance: 125, reps: 5, rest: 280, focus: "5-Step Elite Build", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 228, name: "Elite Full 40-80-120-80-40 yd Pyramid", distance: 120, reps: 5, rest: 270, focus: "Complete Elite Challenge", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 229, name: "Elite 50-100-150 yd Pyramid", distance: 150, reps: 3, rest: 360, focus: "Maximum Distance Build", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 230, name: "Elite 20-40-80-120-160 yd Pyramid", distance: 160, reps: 5, rest: 320, focus: "Elite Speed Reserve", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 231, name: "Elite 35-70-105-140 yd Pyramid", distance: 140, reps: 4, rest: 310, focus: "35-Yard Increments", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 232, name: "Elite 60-90-120-90-60 yd Pyramid", distance: 120, reps: 5, rest: 280, focus: "Elite Symmetric", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 233, name: "Elite 40-70-100-130 yd Pyramid", distance: 130, reps: 4, rest: 300, focus: "30-Yard Variable Steps", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 234, name: "Elite 80-110-140 yd Pyramid ×2", distance: 140, reps: 6, rest: 290, focus: "Double Elite Sets", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 235, name: "Elite 15-45-75-105-135 yd Pyramid", distance: 135, reps: 5, rest: 295, focus: "30-Yard Progressive", level: "Elite", sessionType: LibrarySessionType.sprint),
    
    // Mixed Level Challenge Pyramids (236-245)
    SprintSessionTemplate(id: 236, name: "Mixed 10-30-50-70 yd Challenge", distance: 70, reps: 4, rest: 175, focus: "All-Level Adaptable", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 237, name: "Mixed 5-25-45-65 yd Progressive", distance: 65, reps: 4, rest: 165, focus: "20-Yard Steps Universal", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 238, name: "Mixed Full 20-50-80-50-20 yd Pyramid", distance: 80, reps: 5, rest: 185, focus: "Universal Peak Training", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 239, name: "Mixed 12-36-60-84 yd Pattern", distance: 84, reps: 4, rest: 195, focus: "24-Yard Increments", level: "All Levels", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 241, name: "Elite 20-40-60-80-60-40-20 yd Pyramid", distance: 80, reps: 7, rest: 200, focus: "Elite Up-Down Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 242, name: "Elite 10-30-50-70-90-70-50-30-10 yd Pyramid", distance: 90, reps: 9, rest: 220, focus: "Elite Complete Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 243, name: "Elite 15-35-55-75-95-75-55-35-15 yd Pyramid", distance: 95, reps: 9, rest: 240, focus: "Elite Long Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 244, name: "Elite 25-50-75-100-125-100-75-50-25 yd Pyramid", distance: 125, reps: 9, rest: 260, focus: "Elite Extreme Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 245, name: "Elite 5-15-25-35-45-35-25-15-5 yd Pyramid", distance: 45, reps: 9, rest: 160, focus: "Elite Short Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 246, name: "Elite 30-60-90-120-150-120-90-60-30 yd Pyramid", distance: 150, reps: 9, rest: 320, focus: "Elite Maximum Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 247, name: "Elite 40-70-100-130-160-130-100-70-40 yd Pyramid", distance: 160, reps: 9, rest: 340, focus: "Elite Ultimate Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 248, name: "Elite 20-45-70-95-120-95-70-45-20 yd Pyramid", distance: 120, reps: 9, rest: 280, focus: "Elite Variable Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 249, name: "Elite 10-25-40-55-70-55-40-25-10 yd Pyramid", distance: 70, reps: 9, rest: 190, focus: "Elite Medium Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 250, name: "Elite 15-30-45-60-75-60-45-30-15 yd Pyramid", distance: 75, reps: 9, rest: 210, focus: "Elite Balanced Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 251, name: "Elite 5-20-35-50-65-50-35-20-5 yd Pyramid", distance: 65, reps: 9, rest: 180, focus: "Elite Compact Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 252, name: "Elite 25-50-75-100-125-100-75-50-25 yd Pyramid", distance: 125, reps: 9, rest: 260, focus: "Elite Large Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 253, name: "Elite 10-35-60-85-110-85-60-35-10 yd Pyramid", distance: 110, reps: 9, rest: 250, focus: "Elite Irregular Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 254, name: "Elite 20-40-60-80-100-80-60-40-20 yd Pyramid", distance: 100, reps: 9, rest: 230, focus: "Elite Symmetric Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 255, name: "Elite 15-40-65-90-115-90-65-40-15 yd Pyramid", distance: 115, reps: 9, rest: 270, focus: "Elite Extended Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 256, name: "Elite 5-15-25-35-45-55-45-35-25-15-5 yd Pyramid", distance: 55, reps: 11, rest: 170, focus: "Elite Detailed Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 257, name: "Elite 30-60-90-120-150-120-90-60-30 yd Pyramid", distance: 150, reps: 9, rest: 320, focus: "Elite Distance Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 258, name: "Elite 25-55-85-115-145-115-85-55-25 yd Pyramid", distance: 145, reps: 9, rest: 300, focus: "Elite Progressive Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 259, name: "Elite 10-30-50-70-90-110-90-70-50-30-10 yd Pyramid", distance: 110, reps: 11, rest: 250, focus: "Elite Comprehensive Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 260, name: "Elite 20-45-70-95-120-145-120-95-70-45-20 yd Pyramid", distance: 145, reps: 11, rest: 310, focus: "Elite Ultimate Pyramid", level: "Elite", sessionType: LibrarySessionType.sprint),
    // Additional Beginner Pyramids (261-280)
    SprintSessionTemplate(id: 261, name: "Beginner 6-12-18-24-18-12-6 yd Pyramid", distance: 24, reps: 7, rest: 90, focus: "Beginner Up-Down Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 262, name: "Beginner 8-16-24-32-24-16-8 yd Pyramid", distance: 32, reps: 7, rest: 100, focus: "Beginner Doubling Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 263, name: "Beginner 7-14-21-28-21-14-7 yd Pyramid", distance: 28, reps: 7, rest: 95, focus: "Beginner 7-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 264, name: "Beginner 9-18-27-36-27-18-9 yd Pyramid", distance: 36, reps: 7, rest: 105, focus: "Beginner 9-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 265, name: "Beginner 4-8-12-16-20-16-12-8-4 yd Pyramid", distance: 20, reps: 9, rest: 85, focus: "Beginner Long Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 266, name: "Beginner 11-22-33-44-33-22-11 yd Pyramid", distance: 44, reps: 7, rest: 115, focus: "Beginner 11-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 267, name: "Beginner 3-6-9-12-15-12-9-6-3 yd Pyramid", distance: 15, reps: 9, rest: 75, focus: "Beginner Small Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 268, name: "Beginner 13-26-39-52-39-26-13 yd Pyramid", distance: 52, reps: 7, rest: 125, focus: "Beginner 13-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 269, name: "Beginner 2-4-6-8-10-8-6-4-2 yd Pyramid", distance: 10, reps: 9, rest: 70, focus: "Beginner Tiny Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 270, name: "Beginner 14-28-42-56-42-28-14 yd Pyramid", distance: 56, reps: 7, rest: 130, focus: "Beginner 14-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 271, name: "Beginner 16-32-48-64-48-32-16 yd Pyramid", distance: 64, reps: 7, rest: 140, focus: "Beginner 16-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 272, name: "Beginner 18-36-54-72-54-36-18 yd Pyramid", distance: 72, reps: 7, rest: 150, focus: "Beginner 18-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 273, name: "Beginner 19-38-57-76-57-38-19 yd Pyramid", distance: 76, reps: 7, rest: 155, focus: "Beginner 19-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 274, name: "Beginner 21-42-63-84-63-42-21 yd Pyramid", distance: 84, reps: 7, rest: 165, focus: "Beginner 21-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 275, name: "Beginner 22-44-66-88-66-44-22 yd Pyramid", distance: 88, reps: 7, rest: 170, focus: "Beginner 22-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 276, name: "Beginner 23-46-69-92-69-46-23 yd Pyramid", distance: 92, reps: 7, rest: 175, focus: "Beginner 23-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 277, name: "Beginner 24-48-72-96-72-48-24 yd Pyramid", distance: 96, reps: 7, rest: 180, focus: "Beginner 24-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 278, name: "Beginner 26-52-78-104-78-52-26 yd Pyramid", distance: 104, reps: 7, rest: 190, focus: "Beginner 26-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 279, name: "Beginner 28-56-84-112-84-56-28 yd Pyramid", distance: 112, reps: 7, rest: 200, focus: "Beginner 28-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 280, name: "Beginner 29-58-87-116-87-58-29 yd Pyramid", distance: 116, reps: 7, rest: 205, focus: "Beginner 29-Yard Pyramid", level: "Beginner", sessionType: LibrarySessionType.sprint),
    // Additional Intermediate Pyramids (281-300)
    SprintSessionTemplate(id: 281, name: "Intermediate 12-24-36-48-60-48-36-24-12 yd Pyramid", distance: 60, reps: 9, rest: 170, focus: "Intermediate Up-Down Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 282, name: "Intermediate 14-28-42-56-70-56-42-28-14 yd Pyramid", distance: 70, reps: 9, rest: 185, focus: "Intermediate Doubling Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 283, name: "Intermediate 16-32-48-64-80-64-48-32-16 yd Pyramid", distance: 80, reps: 9, rest: 200, focus: "Intermediate 16-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 284, name: "Intermediate 18-36-54-72-90-72-54-36-18 yd Pyramid", distance: 90, reps: 9, rest: 215, focus: "Intermediate 18-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 285, name: "Intermediate 22-44-66-88-110-88-66-44-22 yd Pyramid", distance: 110, reps: 9, rest: 235, focus: "Intermediate 22-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 286, name: "Intermediate 26-52-78-104-130-104-78-52-26 yd Pyramid", distance: 130, reps: 9, rest: 255, focus: "Intermediate 26-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 287, name: "Intermediate 28-56-84-112-140-112-84-56-28 yd Pyramid", distance: 140, reps: 9, rest: 270, focus: "Intermediate 28-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 288, name: "Intermediate 32-64-96-128-160-128-96-64-32 yd Pyramid", distance: 160, reps: 9, rest: 290, focus: "Intermediate 32-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 289, name: "Intermediate 34-68-102-136-170-136-102-68-34 yd Pyramid", distance: 170, reps: 9, rest: 305, focus: "Intermediate 34-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 290, name: "Intermediate 36-72-108-144-180-144-108-72-36 yd Pyramid", distance: 180, reps: 9, rest: 320, focus: "Intermediate 36-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 291, name: "Intermediate 38-76-114-152-190-152-114-76-38 yd Pyramid", distance: 190, reps: 9, rest: 335, focus: "Intermediate 38-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 292, name: "Intermediate 42-84-126-168-210-168-126-84-42 yd Pyramid", distance: 210, reps: 9, rest: 355, focus: "Intermediate 42-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 293, name: "Intermediate 44-88-132-176-220-176-132-88-44 yd Pyramid", distance: 220, reps: 9, rest: 370, focus: "Intermediate 44-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 294, name: "Intermediate 46-92-138-184-230-184-138-92-46 yd Pyramid", distance: 230, reps: 9, rest: 385, focus: "Intermediate 46-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 295, name: "Intermediate 48-96-144-192-240-192-144-96-48 yd Pyramid", distance: 240, reps: 9, rest: 400, focus: "Intermediate 48-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 296, name: "Intermediate 52-104-156-208-260-208-156-104-52 yd Pyramid", distance: 260, reps: 9, rest: 420, focus: "Intermediate 52-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 297, name: "Intermediate 54-108-162-216-270-216-162-108-54 yd Pyramid", distance: 270, reps: 9, rest: 435, focus: "Intermediate 54-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 298, name: "Intermediate 56-112-168-224-280-224-168-112-56 yd Pyramid", distance: 280, reps: 9, rest: 450, focus: "Intermediate 56-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 299, name: "Intermediate 58-116-174-232-290-232-174-116-58 yd Pyramid", distance: 290, reps: 9, rest: 465, focus: "Intermediate 58-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),
    SprintSessionTemplate(id: 300, name: "Intermediate 62-124-186-248-310-248-186-124-62 yd Pyramid", distance: 310, reps: 9, rest: 485, focus: "Intermediate 62-Yard Pyramid", level: "Intermediate", sessionType: LibrarySessionType.sprint),

    // MARK: - Active Recovery Sessions (301-350) - No Jogging, Drills, Strides, Flexibility
    // Beginner Active Recovery (301-320)
    SprintSessionTemplate(id: 301, name: "Beginner Drills & Strides", distance: 0, reps: 10, rest: 60, focus: "A-Skips & Strides", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 302, name: "Beginner Flexibility Routine", distance: 0, reps: 5, rest: 120, focus: "Dynamic Stretching", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 303, name: "Beginner Core Drills", distance: 0, reps: 8, rest: 90, focus: "Plank & Core Work", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 304, name: "Beginner Mobility Drills", distance: 0, reps: 6, rest: 100, focus: "Hip & Ankle Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 305, name: "Beginner Stride Outs", distance: 20, reps: 6, rest: 120, focus: "Controlled Strides", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 306, name: "Beginner Foam Rolling", distance: 0, reps: 10, rest: 60, focus: "Self-Massage", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 307, name: "Beginner Yoga Flows", distance: 0, reps: 5, rest: 180, focus: "Yoga Poses", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 308, name: "Beginner Balance Drills", distance: 0, reps: 8, rest: 90, focus: "Single Leg Balance", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 309, name: "Beginner Arm Swings", distance: 0, reps: 10, rest: 60, focus: "Arm Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 310, name: "Beginner Breathing Drills", distance: 0, reps: 6, rest: 120, focus: "Breath Control", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 311, name: "Beginner Leg Swings", distance: 0, reps: 10, rest: 60, focus: "Hip Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 312, name: "Beginner Jumping Jacks", distance: 0, reps: 20, rest: 60, focus: "Light Cardio", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 313, name: "Beginner Wall Drills", distance: 0, reps: 8, rest: 90, focus: "Wall Push & Pull", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 314, name: "Beginner Marching", distance: 0, reps: 10, rest: 60, focus: "High Knees March", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 315, name: "Beginner Calf Raises", distance: 0, reps: 15, rest: 60, focus: "Calf Strength", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 316, name: "Beginner Arm Circles", distance: 0, reps: 10, rest: 60, focus: "Shoulder Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 317, name: "Beginner Torso Twists", distance: 0, reps: 10, rest: 60, focus: "Spinal Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 318, name: "Beginner Ankle Pumps", distance: 0, reps: 15, rest: 60, focus: "Ankle Flexibility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 319, name: "Beginner Neck Rolls", distance: 0, reps: 8, rest: 90, focus: "Neck Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 320, name: "Beginner Wrist Flex", distance: 0, reps: 10, rest: 60, focus: "Wrist Mobility", level: "Beginner", sessionType: LibrarySessionType.activeRecovery),

    // Intermediate Active Recovery (321-340)
    SprintSessionTemplate(id: 321, name: "Intermediate Drills & Strides", distance: 0, reps: 12, rest: 60, focus: "B-Skips & Strides", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 322, name: "Intermediate Flexibility Routine", distance: 0, reps: 6, rest: 120, focus: "Advanced Stretching", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 323, name: "Intermediate Core Drills", distance: 0, reps: 10, rest: 90, focus: "Plank Variations", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 324, name: "Intermediate Mobility Drills", distance: 0, reps: 8, rest: 100, focus: "Joint Mobility", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 325, name: "Intermediate Stride Outs", distance: 30, reps: 8, rest: 120, focus: "Progressive Strides", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 326, name: "Intermediate Foam Rolling", distance: 0, reps: 12, rest: 60, focus: "Deep Tissue", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 327, name: "Intermediate Yoga Flows", distance: 0, reps: 6, rest: 180, focus: "Vinyasa Flows", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 328, name: "Intermediate Balance Drills", distance: 0, reps: 10, rest: 90, focus: "Single Leg Advanced", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 329, name: "Intermediate Arm Swings", distance: 0, reps: 12, rest: 60, focus: "Dynamic Arm Work", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 330, name: "Intermediate Breathing Drills", distance: 0, reps: 8, rest: 120, focus: "Diaphragmatic Breathing", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 331, name: "Intermediate Leg Swings", distance: 0, reps: 12, rest: 60, focus: "Advanced Hip Mobility", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 332, name: "Intermediate Jumping Jacks", distance: 0, reps: 25, rest: 60, focus: "Elevated Cardio", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 333, name: "Intermediate Wall Drills", distance: 0, reps: 10, rest: 90, focus: "Wall March & Skip", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 334, name: "Intermediate Marching", distance: 0, reps: 12, rest: 60, focus: "High Knees March", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 335, name: "Intermediate Calf Raises", distance: 0, reps: 20, rest: 60, focus: "Single Leg Raises", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 336, name: "Intermediate Arm Circles", distance: 0, reps: 12, rest: 60, focus: "Reverse Circles", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 337, name: "Intermediate Torso Twists", distance: 0, reps: 12, rest: 60, focus: "Russian Twists", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 338, name: "Intermediate Ankle Pumps", distance: 0, reps: 20, rest: 60, focus: "Advanced Ankle Work", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 339, name: "Intermediate Neck Rolls", distance: 0, reps: 10, rest: 90, focus: "Full Range", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 340, name: "Intermediate Wrist Flex", distance: 0, reps: 12, rest: 60, focus: "Wrist Extensions", level: "Intermediate", sessionType: LibrarySessionType.activeRecovery),

    // Advanced Active Recovery (341-360)
    SprintSessionTemplate(id: 341, name: "Advanced Drills & Strides", distance: 0, reps: 15, rest: 60, focus: "C-Skips & Strides", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 342, name: "Advanced Flexibility Routine", distance: 0, reps: 8, rest: 120, focus: "PNF Stretching", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 343, name: "Advanced Core Drills", distance: 0, reps: 12, rest: 90, focus: "Hanging Leg Raises", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 344, name: "Advanced Mobility Drills", distance: 0, reps: 10, rest: 100, focus: "3D Mobility", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 345, name: "Advanced Stride Outs", distance: 40, reps: 10, rest: 120, focus: "Max Strides", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 346, name: "Advanced Foam Rolling", distance: 0, reps: 15, rest: 60, focus: "Trigger Point", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 347, name: "Advanced Yoga Flows", distance: 0, reps: 8, rest: 180, focus: "Power Yoga", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 348, name: "Advanced Balance Drills", distance: 0, reps: 12, rest: 90, focus: "Pistol Squats", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 349, name: "Advanced Arm Swings", distance: 0, reps: 15, rest: 60, focus: "Weighted Swings", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 350, name: "Advanced Breathing Drills", distance: 0, reps: 10, rest: 120, focus: "Box Breathing", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 351, name: "Advanced Leg Swings", distance: 0, reps: 15, rest: 60, focus: "Multi-Directional", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 352, name: "Advanced Jumping Jacks", distance: 0, reps: 30, rest: 60, focus: "Explosive Jacks", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 353, name: "Advanced Wall Drills", distance: 0, reps: 12, rest: 90, focus: "Wall Runs", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 354, name: "Advanced Marching", distance: 0, reps: 15, rest: 60, focus: "Butt Kicks March", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 355, name: "Advanced Calf Raises", distance: 0, reps: 25, rest: 60, focus: "Weighted Raises", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 356, name: "Advanced Arm Circles", distance: 0, reps: 15, rest: 60, focus: "Giant Circles", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 357, name: "Advanced Torso Twists", distance: 0, reps: 15, rest: 60, focus: "Medicine Ball Twists", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 358, name: "Advanced Ankle Pumps", distance: 0, reps: 25, rest: 60, focus: "Rapid Pumps", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 359, name: "Advanced Neck Rolls", distance: 0, reps: 12, rest: 90, focus: "Full Rotation", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 360, name: "Advanced Wrist Flex", distance: 0, reps: 15, rest: 60, focus: "Advanced Flexion", level: "Advanced", sessionType: LibrarySessionType.activeRecovery),

    // Elite Active Recovery (361-380)
    SprintSessionTemplate(id: 361, name: "Elite Drills & Strides", distance: 0, reps: 18, rest: 60, focus: "Elite Skips & Strides", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 362, name: "Elite Flexibility Routine", distance: 0, reps: 10, rest: 120, focus: "Elite PNF", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 363, name: "Elite Core Drills", distance: 0, reps: 15, rest: 90, focus: "L-Sit & Dragon Flags", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 364, name: "Elite Mobility Drills", distance: 0, reps: 12, rest: 100, focus: "Elite Joint Work", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 365, name: "Elite Stride Outs", distance: 50, reps: 12, rest: 120, focus: "Elite Strides", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 366, name: "Elite Foam Rolling", distance: 0, reps: 18, rest: 60, focus: "Elite Release", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 367, name: "Elite Yoga Flows", distance: 0, reps: 10, rest: 180, focus: "Elite Ashtanga", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 368, name: "Elite Balance Drills", distance: 0, reps: 15, rest: 90, focus: "Elite Single Leg", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 369, name: "Elite Arm Swings", distance: 0, reps: 18, rest: 60, focus: "Elite Dynamic", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 370, name: "Elite Breathing Drills", distance: 0, reps: 12, rest: 120, focus: "Elite Breath Work", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 371, name: "Elite Leg Swings", distance: 0, reps: 18, rest: 60, focus: "Elite Hip Openers", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 372, name: "Elite Jumping Jacks", distance: 0, reps: 35, rest: 60, focus: "Elite Explosive", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 373, name: "Elite Wall Drills", distance: 0, reps: 15, rest: 90, focus: "Elite Wall Runs", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 374, name: "Elite Marching", distance: 0, reps: 18, rest: 60, focus: "Elite High Knees", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 375, name: "Elite Calf Raises", distance: 0, reps: 30, rest: 60, focus: "Elite Single Leg", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 376, name: "Elite Arm Circles", distance: 0, reps: 18, rest: 60, focus: "Elite Full Range", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 377, name: "Elite Torso Twists", distance: 0, reps: 18, rest: 60, focus: "Elite Medicine Ball", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 378, name: "Elite Ankle Pumps", distance: 0, reps: 30, rest: 60, focus: "Elite Rapid", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 379, name: "Elite Neck Rolls", distance: 0, reps: 15, rest: 90, focus: "Elite Full Rotation", level: "Elite", sessionType: LibrarySessionType.activeRecovery),
    SprintSessionTemplate(id: 380, name: "Elite Wrist Flex", distance: 0, reps: 18, rest: 60, focus: "Elite Advanced Flexion", level: "Elite", sessionType: LibrarySessionType.activeRecovery),

    // Rest Days (381-400) - Complete Rest
    SprintSessionTemplate(id: 381, name: "Beginner Rest Day", distance: 0, reps: 0, rest: 0, focus: "Complete Rest", level: "Beginner", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 382, name: "Intermediate Rest Day", distance: 0, reps: 0, rest: 0, focus: "Complete Rest", level: "Intermediate", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 383, name: "Advanced Rest Day", distance: 0, reps: 0, rest: 0, focus: "Complete Rest", level: "Advanced", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 384, name: "Elite Rest Day", distance: 0, reps: 0, rest: 0, focus: "Complete Rest", level: "Elite", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 385, name: "All Levels Rest Day", distance: 0, reps: 0, rest: 0, focus: "Complete Rest", level: "All Levels", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 386, name: "Recovery Rest Day", distance: 0, reps: 0, rest: 0, focus: "Recovery Rest", level: "All Levels", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 387, name: "Light Rest Day", distance: 0, reps: 0, rest: 0, focus: "Light Rest", level: "All Levels", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 388, name: "Full Rest Day", distance: 0, reps: 0, rest: 0, focus: "Full Rest", level: "All Levels", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 389, name: "Beginner Light Rest", distance: 0, reps: 0, rest: 0, focus: "Light Rest", level: "Beginner", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 390, name: "Intermediate Light Rest", distance: 0, reps: 0, rest: 0, focus: "Light Rest", level: "Intermediate", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 391, name: "Advanced Light Rest", distance: 0, reps: 0, rest: 0, focus: "Light Rest", level: "Advanced", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 392, name: "Elite Light Rest", distance: 0, reps: 0, rest: 0, focus: "Light Rest", level: "Elite", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 393, name: "Beginner Full Rest", distance: 0, reps: 0, rest: 0, focus: "Full Rest", level: "Beginner", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 394, name: "Intermediate Full Rest", distance: 0, reps: 0, rest: 0, focus: "Full Rest", level: "Intermediate", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 395, name: "Advanced Full Rest", distance: 0, reps: 0, rest: 0, focus: "Full Rest", level: "Advanced", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 396, name: "Elite Full Rest", distance: 0, reps: 0, rest: 0, focus: "Full Rest", level: "Elite", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 397, name: "All Levels Full Rest", distance: 0, reps: 0, rest: 0, focus: "Full Rest", level: "All Levels", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 398, name: "Recovery Full Rest", distance: 0, reps: 0, rest: 0, focus: "Recovery Rest", level: "All Levels", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 399, name: "Beginner Recovery Rest", distance: 0, reps: 0, rest: 0, focus: "Recovery Rest", level: "Beginner", sessionType: LibrarySessionType.rest),
    SprintSessionTemplate(id: 400, name: "Elite Recovery Rest", distance: 0, reps: 0, rest: 0, focus: "Recovery Rest", level: "Elite", sessionType: LibrarySessionType.rest)
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
    rest: 180, // Main sprint rest
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
    
    /// Enhanced program generation with user preference support
    static func generateWithUserPreferences(
        level: String,
        totalDaysPerWeek: Int,
        userPreferences: UserSessionPreferences,
        includeActiveRecovery: Bool = true,
        includeRestDay: Bool = true
    ) -> [WeeklyProgramTemplate] {
        
        var program: [WeeklyProgramTemplate] = []
        
        for week in 1...12 {
            let weeklyProgram = generateWeeklyProgramWithPreferences(
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
