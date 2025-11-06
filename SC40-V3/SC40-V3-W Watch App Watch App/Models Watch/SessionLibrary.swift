import Foundation

// MARK: - Sprint Session Template for Library (Watch Version)

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

// MARK: - Session Library Data (Watch Version)
// Synchronized with iPhone SessionLibrary for consistency

let sessionLibrary: [SprintSessionTemplate] = [
    // BEGINNER SESSIONS (1-50)
    SprintSessionTemplate(id: 1, name: "10 yd Starts", distance: 10, reps: 8, rest: 1, focus: "Acceleration", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 2, name: "15 yd Starts", distance: 15, reps: 10, rest: 1, focus: "Acceleration", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 3, name: "20 yd Accel", distance: 20, reps: 6, rest: 2, focus: "Early Acceleration", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 4, name: "25 yd Build", distance: 25, reps: 5, rest: 2, focus: "Speed Building", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 5, name: "30 yd Speed", distance: 30, reps: 4, rest: 3, focus: "Speed Development", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 6, name: "35 yd Power", distance: 35, reps: 4, rest: 3, focus: "Power Development", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 7, name: "40 yd Max", distance: 40, reps: 3, rest: 4, focus: "Maximum Velocity", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 8, name: "40 yd Time Trial", distance: 40, reps: 2, rest: 5, focus: "Time Trial", level: "Beginner", sessionType: .benchmark),
    SprintSessionTemplate(id: 9, name: "Basic Recovery", distance: 20, reps: 3, rest: 2, focus: "Active Recovery", level: "Beginner", sessionType: .activeRecovery),
    SprintSessionTemplate(id: 10, name: "Form Focus", distance: 15, reps: 6, rest: 1, focus: "Running Form", level: "Beginner", sessionType: .sprint),
    
    // INTERMEDIATE SESSIONS (11-100)
    SprintSessionTemplate(id: 11, name: "20 yd Explosive", distance: 20, reps: 8, rest: 2, focus: "Explosive Start", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 12, name: "30 yd Drive", distance: 30, reps: 6, rest: 2, focus: "Drive Phase", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 13, name: "40 yd Build", distance: 40, reps: 5, rest: 3, focus: "Speed Building", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 14, name: "50 yd Speed", distance: 50, reps: 4, rest: 3, focus: "Speed Development", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 15, name: "60 yd Power", distance: 60, reps: 4, rest: 4, focus: "Power Development", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 16, name: "70 yd Max", distance: 70, reps: 3, rest: 4, focus: "Maximum Velocity", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 17, name: "40 yd Time Trial", distance: 40, reps: 3, rest: 5, focus: "Time Trial", level: "Intermediate", sessionType: .benchmark),
    SprintSessionTemplate(id: 18, name: "Intermediate Recovery", distance: 30, reps: 4, rest: 2, focus: "Active Recovery", level: "Intermediate", sessionType: .activeRecovery),
    SprintSessionTemplate(id: 19, name: "Tempo Runs", distance: 40, reps: 5, rest: 2, focus: "Tempo Training", level: "Intermediate", sessionType: .tempo),
    SprintSessionTemplate(id: 20, name: "Progressive Distance", distance: 35, reps: 6, rest: 2, focus: "Progressive Training", level: "Intermediate", sessionType: .sprint),
    
    // ADVANCED SESSIONS (21-150)
    SprintSessionTemplate(id: 21, name: "30 yd Explosive", distance: 30, reps: 8, rest: 2, focus: "Explosive Power", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 22, name: "50 yd Drive", distance: 50, reps: 6, rest: 3, focus: "Drive Phase", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 23, name: "70 yd Build", distance: 70, reps: 5, rest: 3, focus: "Speed Building", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 24, name: "80 yd Speed", distance: 80, reps: 4, rest: 4, focus: "Speed Development", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 25, name: "90 yd Power", distance: 90, reps: 4, rest: 4, focus: "Power Development", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 26, name: "100 yd Max", distance: 100, reps: 3, rest: 5, focus: "Maximum Velocity", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 27, name: "40 yd Time Trial", distance: 40, reps: 3, rest: 5, focus: "Time Trial", level: "Advanced", sessionType: .benchmark),
    SprintSessionTemplate(id: 28, name: "Advanced Recovery", distance: 40, reps: 4, rest: 3, focus: "Active Recovery", level: "Advanced", sessionType: .activeRecovery),
    SprintSessionTemplate(id: 29, name: "Advanced Tempo", distance: 60, reps: 5, rest: 3, focus: "Tempo Training", level: "Advanced", sessionType: .tempo),
    SprintSessionTemplate(id: 30, name: "Complex Training", distance: 50, reps: 6, rest: 3, focus: "Complex Training", level: "Advanced", sessionType: .comprehensive),
    
    // ELITE SESSIONS (31-200)
    SprintSessionTemplate(id: 31, name: "40 yd Explosive", distance: 40, reps: 8, rest: 3, focus: "Explosive Power", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 32, name: "60 yd Drive", distance: 60, reps: 6, rest: 3, focus: "Drive Phase", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 33, name: "80 yd Build", distance: 80, reps: 5, rest: 4, focus: "Speed Building", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 34, name: "100 yd Speed", distance: 100, reps: 4, rest: 4, focus: "Speed Development", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 35, name: "100 yd Power", distance: 100, reps: 4, rest: 5, focus: "Power Development", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 36, name: "100 yd Max", distance: 100, reps: 3, rest: 5, focus: "Maximum Velocity", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 37, name: "40 yd Time Trial", distance: 40, reps: 4, rest: 5, focus: "Time Trial", level: "Elite", sessionType: .benchmark),
    SprintSessionTemplate(id: 38, name: "Elite Recovery", distance: 50, reps: 4, rest: 3, focus: "Active Recovery", level: "Elite", sessionType: .activeRecovery),
    SprintSessionTemplate(id: 39, name: "Elite Tempo", distance: 80, reps: 5, rest: 3, focus: "Tempo Training", level: "Elite", sessionType: .tempo),
    SprintSessionTemplate(id: 40, name: "Elite Complex", distance: 70, reps: 6, rest: 4, focus: "Complex Training", level: "Elite", sessionType: .comprehensive),
    
    // ADDITIONAL VARIETY SESSIONS (41-100)
    SprintSessionTemplate(id: 41, name: "Pyramid 20-40-20", distance: 30, reps: 6, rest: 3, focus: "Pyramid Training", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 42, name: "Flying 20s", distance: 40, reps: 5, rest: 3, focus: "Flying Sprints", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 43, name: "Resisted Starts", distance: 20, reps: 8, rest: 2, focus: "Resisted Training", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 44, name: "Overspeed", distance: 30, reps: 6, rest: 3, focus: "Overspeed Training", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 45, name: "Competition Prep", distance: 40, reps: 3, rest: 5, focus: "Competition Preparation", level: "Elite", sessionType: .benchmark),
    
    // RECOVERY AND TEMPO SESSIONS (46-60)
    SprintSessionTemplate(id: 46, name: "Easy Jog", distance: 30, reps: 3, rest: 2, focus: "Recovery", level: "Beginner", sessionType: .recovery),
    SprintSessionTemplate(id: 47, name: "Light Tempo", distance: 40, reps: 4, rest: 2, focus: "Light Tempo", level: "Beginner", sessionType: .tempo),
    SprintSessionTemplate(id: 48, name: "Moderate Tempo", distance: 50, reps: 4, rest: 3, focus: "Moderate Tempo", level: "Intermediate", sessionType: .tempo),
    SprintSessionTemplate(id: 49, name: "Fast Tempo", distance: 60, reps: 4, rest: 3, focus: "Fast Tempo", level: "Advanced", sessionType: .tempo),
    SprintSessionTemplate(id: 50, name: "Elite Tempo", distance: 80, reps: 4, rest: 4, focus: "Elite Tempo", level: "Elite", sessionType: .tempo),
    
    // BENCHMARK SESSIONS (51-60)
    SprintSessionTemplate(id: 51, name: "10 yd Test", distance: 10, reps: 3, rest: 3, focus: "10 Yard Test", level: "Beginner", sessionType: .benchmark),
    SprintSessionTemplate(id: 52, name: "20 yd Test", distance: 20, reps: 3, rest: 4, focus: "20 Yard Test", level: "Intermediate", sessionType: .benchmark),
    SprintSessionTemplate(id: 53, name: "40 yd Test", distance: 40, reps: 3, rest: 5, focus: "40 Yard Test", level: "Advanced", sessionType: .benchmark),
    SprintSessionTemplate(id: 54, name: "60 yd Test", distance: 60, reps: 2, rest: 5, focus: "60 Yard Test", level: "Elite", sessionType: .benchmark),
    SprintSessionTemplate(id: 55, name: "100 yd Test", distance: 100, reps: 2, rest: 6, focus: "100 Yard Test", level: "Elite", sessionType: .benchmark),
    
    // COMPREHENSIVE SESSIONS (56-70)
    SprintSessionTemplate(id: 56, name: "Complete Beginner", distance: 25, reps: 5, rest: 2, focus: "Complete Workout", level: "Beginner", sessionType: .comprehensive),
    SprintSessionTemplate(id: 57, name: "Complete Intermediate", distance: 40, reps: 5, rest: 3, focus: "Complete Workout", level: "Intermediate", sessionType: .comprehensive),
    SprintSessionTemplate(id: 58, name: "Complete Advanced", distance: 60, reps: 5, rest: 3, focus: "Complete Workout", level: "Advanced", sessionType: .comprehensive),
    SprintSessionTemplate(id: 59, name: "Complete Elite", distance: 80, reps: 5, rest: 4, focus: "Complete Workout", level: "Elite", sessionType: .comprehensive),
    SprintSessionTemplate(id: 60, name: "Full Program", distance: 50, reps: 6, rest: 3, focus: "Full Program", level: "Intermediate", sessionType: .comprehensive)
]
