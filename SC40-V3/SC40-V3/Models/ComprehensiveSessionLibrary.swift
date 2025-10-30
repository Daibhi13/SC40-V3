import Foundation

// MARK: - Enhanced Sprint Session Models for 12-Week Program

/// Enhanced sprint session with comprehensive workout flow
struct ComprehensiveSprintSession: Identifiable, Codable {
    let id: Int
    let name: String
    let distanceYards: Int
    let reps: Int
    let restMinutes: Int
    let focus: String
    let level: String
}

/// Enhanced sprint set for comprehensive training sessions
struct ComprehensiveSprintSet: Codable {
    let distanceYards: Int
    let reps: Int
    let intensity: String
    let restMinutes: Int
}

/// Complete training session with full SC40 workout flow
struct ComprehensiveTrainingSession: Identifiable, Codable {
    let id: Int
    let name: String
    let focus: String
    let level: String
    let sprints: [ComprehensiveSprintSet]
    let accessoryWork: [String]
    let notes: String
}

// MARK: - Full Sprint Session Library (185 sessions)
// Comprehensive session library for the 12-week program

let comprehensiveSprintSessions: [ComprehensiveSprintSession] = [
    // 1 - 21 (Beginner → Advanced)
    ComprehensiveSprintSession(id: 1, name: "10 yd Starts", distanceYards: 10, reps: 8, restMinutes: 1, focus: "Acceleration", level: "Beginner"),
    ComprehensiveSprintSession(id: 2, name: "15 yd Starts", distanceYards: 15, reps: 10, restMinutes: 1, focus: "Acceleration", level: "Beginner"),
    ComprehensiveSprintSession(id: 3, name: "20 yd Accel", distanceYards: 20, reps: 6, restMinutes: 2, focus: "Early Acceleration", level: "Beginner"),
    ComprehensiveSprintSession(id: 4, name: "25 yd Accel", distanceYards: 25, reps: 8, restMinutes: 2, focus: "Drive Phase", level: "Beginner"),
    ComprehensiveSprintSession(id: 5, name: "30 yd Drive", distanceYards: 30, reps: 6, restMinutes: 2, focus: "Drive Phase", level: "Beginner"),
    ComprehensiveSprintSession(id: 6, name: "35 yd Drive", distanceYards: 35, reps: 5, restMinutes: 2, focus: "Drive Phase", level: "Beginner"),
    ComprehensiveSprintSession(id: 7, name: "40 yd Repeats", distanceYards: 40, reps: 6, restMinutes: 3, focus: "Max Speed", level: "Beginner"),
    ComprehensiveSprintSession(id: 8, name: "40 yd Time Trial", distanceYards: 40, reps: 1, restMinutes: 10, focus: "Benchmark", level: "Beginner"),
    ComprehensiveSprintSession(id: 9, name: "45 yd Sprint", distanceYards: 45, reps: 5, restMinutes: 3, focus: "Speed", level: "Beginner"),
    ComprehensiveSprintSession(id: 10, name: "50 yd Sprints", distanceYards: 50, reps: 5, restMinutes: 3, focus: "Accel → Top Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 11, name: "50 yd Time Trial", distanceYards: 50, reps: 1, restMinutes: 10, focus: "Benchmark", level: "Intermediate"),
    ComprehensiveSprintSession(id: 12, name: "55 yd Sprint", distanceYards: 55, reps: 4, restMinutes: 3, focus: "Accel → Top Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 13, name: "60 yd Fly", distanceYards: 60, reps: 6, restMinutes: 4, focus: "Max Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 14, name: "65 yd Fly", distanceYards: 65, reps: 5, restMinutes: 4, focus: "Max Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 15, name: "70 yd Build", distanceYards: 70, reps: 4, restMinutes: 4, focus: "Speed Endurance", level: "Intermediate"),
    ComprehensiveSprintSession(id: 16, name: "75 yd Sprint", distanceYards: 75, reps: 3, restMinutes: 5, focus: "Top-End Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 17, name: "80 yd Repeats", distanceYards: 80, reps: 3, restMinutes: 5, focus: "Repeat Sprints", level: "Advanced"),
    ComprehensiveSprintSession(id: 18, name: "85 yd Sprint", distanceYards: 85, reps: 3, restMinutes: 5, focus: "Top-End Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 19, name: "90 yd Sprints", distanceYards: 90, reps: 3, restMinutes: 5, focus: "Top-End Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 20, name: "95 yd Sprint", distanceYards: 95, reps: 2, restMinutes: 6, focus: "Peak Velocity", level: "Advanced"),
    ComprehensiveSprintSession(id: 21, name: "100 yd Max", distanceYards: 100, reps: 2, restMinutes: 6, focus: "Peak Velocity", level: "Advanced"),

    // 22 - 50 (Ladders, repeats)
    ComprehensiveSprintSession(id: 22, name: "10+20 yd Ladder", distanceYards: 20, reps: 4, restMinutes: 1, focus: "Accel progression", level: "Beginner"),
    ComprehensiveSprintSession(id: 23, name: "15+30 yd Ladder", distanceYards: 30, reps: 3, restMinutes: 2, focus: "Accel → Drive", level: "Beginner"),
    ComprehensiveSprintSession(id: 24, name: "20+20 yd Split", distanceYards: 20, reps: 5, restMinutes: 2, focus: "Accel mechanics", level: "Beginner"),
    ComprehensiveSprintSession(id: 25, name: "10–20–30 yd Pyramid", distanceYards: 30, reps: 3, restMinutes: 2, focus: "Accel progression", level: "Beginner"),
    ComprehensiveSprintSession(id: 26, name: "Progressive 20-40yd Pyramid", distanceYards: 40, reps: 7, restMinutes: 2, focus: "Speed Building Development", level: "Intermediate"),
    ComprehensiveSprintSession(id: 27, name: "25–35–45 yd Ladder", distanceYards: 45, reps: 4, restMinutes: 3, focus: "Accel + Max Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 28, name: "30–40–50 yd Ladder", distanceYards: 50, reps: 3, restMinutes: 3, focus: "Speed Endurance", level: "Intermediate"),
    ComprehensiveSprintSession(id: 29, name: "40 yd ×6", distanceYards: 40, reps: 6, restMinutes: 2, focus: "Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 30, name: "50 yd ×5", distanceYards: 50, reps: 5, restMinutes: 3, focus: "Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 31, name: "Progressive 40yd × 3", distanceYards: 40, reps: 3, restMinutes: 3, focus: "Speed Building Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 32, name: "70 yd ×3", distanceYards: 70, reps: 3, restMinutes: 4, focus: "Speed Endurance", level: "Advanced"),
    ComprehensiveSprintSession(id: 33, name: "80 yd ×3", distanceYards: 80, reps: 3, restMinutes: 5, focus: "Repeat Sprints", level: "Advanced"),
    ComprehensiveSprintSession(id: 34, name: "90 yd ×3", distanceYards: 90, reps: 3, restMinutes: 5, focus: "Top-End Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 35, name: "100 yd ×2", distanceYards: 100, reps: 2, restMinutes: 6, focus: "Peak Velocity", level: "Advanced"),
    ComprehensiveSprintSession(id: 36, name: "Flying 10 yd", distanceYards: 10, reps: 6, restMinutes: 2, focus: "Max Velocity", level: "Beginner"),
    ComprehensiveSprintSession(id: 37, name: "Flying 15 yd", distanceYards: 15, reps: 6, restMinutes: 2, focus: "Max Velocity", level: "Beginner"),
    ComprehensiveSprintSession(id: 38, name: "Flying 20 yd", distanceYards: 20, reps: 6, restMinutes: 2, focus: "Max Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 39, name: "Flying 25 yd", distanceYards: 25, reps: 5, restMinutes: 3, focus: "Max Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 40, name: "Flying 30 yd", distanceYards: 30, reps: 5, restMinutes: 3, focus: "Max Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 41, name: "Flying 35 yd", distanceYards: 35, reps: 4, restMinutes: 4, focus: "Max Velocity", level: "Advanced"),
    ComprehensiveSprintSession(id: 42, name: "Flying 40 yd", distanceYards: 40, reps: 4, restMinutes: 4, focus: "Max Velocity", level: "Advanced"),
    ComprehensiveSprintSession(id: 43, name: "Flying 45 yd", distanceYards: 45, reps: 3, restMinutes: 5, focus: "Max Velocity", level: "Advanced"),
    ComprehensiveSprintSession(id: 44, name: "Flying 50 yd", distanceYards: 50, reps: 3, restMinutes: 5, focus: "Max Velocity", level: "Advanced"),
    ComprehensiveSprintSession(id: 45, name: "Split 10+20 yd", distanceYards: 20, reps: 5, restMinutes: 1, focus: "Accel mechanics", level: "Beginner"),
    ComprehensiveSprintSession(id: 46, name: "Split 15+25 yd", distanceYards: 25, reps: 5, restMinutes: 2, focus: "Accel mechanics", level: "Beginner"),
    ComprehensiveSprintSession(id: 47, name: "Split 20+30 yd", distanceYards: 30, reps: 4, restMinutes: 2, focus: "Accel → Drive", level: "Intermediate"),
    ComprehensiveSprintSession(id: 48, name: "Split 25+35 yd", distanceYards: 35, reps: 4, restMinutes: 3, focus: "Accel → Max Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 49, name: "Split 30+40 yd", distanceYards: 40, reps: 3, restMinutes: 3, focus: "Top-End Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 50, name: "Split 35+45 yd", distanceYards: 45, reps: 3, restMinutes: 3, focus: "Top-End Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 51, name: "Split 40+50 yd", distanceYards: 50, reps: 3, restMinutes: 3, focus: "Top-End Speed", level: "Advanced"),

    // 52 - 151 (Pyramid Sessions) - 100 Pyramid Variations
    // BEGINNER PYRAMIDS (Speed Focus - Short Peaks)
    ComprehensiveSprintSession(id: 52, name: "Mini Pyramid", distanceYards: 20, reps: 5, restMinutes: 1, focus: "Speed Development", level: "Beginner"),
    ComprehensiveSprintSession(id: 53, name: "Basic Pyramid", distanceYards: 30, reps: 7, restMinutes: 2, focus: "Speed Progression", level: "Beginner"),
    ComprehensiveSprintSession(id: 54, name: "Step Pyramid", distanceYards: 25, reps: 5, restMinutes: 1, focus: "Acceleration", level: "Beginner"),
    ComprehensiveSprintSession(id: 55, name: "Quick Pyramid", distanceYards: 35, reps: 7, restMinutes: 2, focus: "Speed Development", level: "Beginner"),
    ComprehensiveSprintSession(id: 56, name: "Short Pyramid", distanceYards: 40, reps: 7, restMinutes: 2, focus: "Max Velocity", level: "Beginner"),
    ComprehensiveSprintSession(id: 57, name: "Micro Pyramid", distanceYards: 15, reps: 5, restMinutes: 1, focus: "Acceleration", level: "Beginner"),
    ComprehensiveSprintSession(id: 58, name: "Build Pyramid", distanceYards: 45, reps: 9, restMinutes: 2, focus: "Speed Endurance", level: "Beginner"),
    ComprehensiveSprintSession(id: 59, name: "Fast Pyramid", distanceYards: 50, reps: 9, restMinutes: 3, focus: "Speed Endurance", level: "Beginner"),
    ComprehensiveSprintSession(id: 60, name: "Power Pyramid", distanceYards: 30, reps: 9, restMinutes: 2, focus: "Power Development", level: "Beginner"),
    ComprehensiveSprintSession(id: 61, name: "Drive Pyramid", distanceYards: 35, reps: 9, restMinutes: 2, focus: "Drive Phase", level: "Beginner"),
    
    // INTERMEDIATE PYRAMIDS (Balanced Speed-Endurance)
    ComprehensiveSprintSession(id: 62, name: "Progressive 20-40yd Classic", distanceYards: 40, reps: 7, restMinutes: 2, focus: "Speed Building Development", level: "Intermediate"),
    ComprehensiveSprintSession(id: 63, name: "Extended Pyramid", distanceYards: 60, reps: 11, restMinutes: 3, focus: "Speed Endurance", level: "Intermediate"),
    ComprehensiveSprintSession(id: 64, name: "Double Pyramid", distanceYards: 50, reps: 13, restMinutes: 3, focus: "Endurance Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 65, name: "Peak Pyramid", distanceYards: 70, reps: 13, restMinutes: 4, focus: "Peak Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 66, name: "Wave Pyramid", distanceYards: 55, reps: 11, restMinutes: 3, focus: "Speed Waves", level: "Intermediate"),
    ComprehensiveSprintSession(id: 67, name: "Climb Pyramid", distanceYards: 65, reps: 11, restMinutes: 3, focus: "Progressive Build", level: "Intermediate"),
    ComprehensiveSprintSession(id: 68, name: "Flow Pyramid", distanceYards: 45, reps: 9, restMinutes: 2, focus: "Rhythm Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 69, name: "Tempo Pyramid", distanceYards: 75, reps: 13, restMinutes: 4, focus: "Tempo Endurance", level: "Intermediate"),
    ComprehensiveSprintSession(id: 70, name: "Stride Pyramid", distanceYards: 80, reps: 15, restMinutes: 4, focus: "Stride Endurance", level: "Intermediate"),
    ComprehensiveSprintSession(id: 71, name: "Rhythm Pyramid", distanceYards: 55, reps: 9, restMinutes: 3, focus: "Rhythm Development", level: "Intermediate"),
    
    // ADVANCED PYRAMIDS (Endurance Focus - Longer Peaks)
    ComprehensiveSprintSession(id: 72, name: "Endurance Pyramid", distanceYards: 100, reps: 19, restMinutes: 5, focus: "Speed Endurance", level: "Advanced"),
    ComprehensiveSprintSession(id: 73, name: "Distance Pyramid", distanceYards: 90, reps: 17, restMinutes: 5, focus: "Distance Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 74, name: "Long Pyramid", distanceYards: 85, reps: 15, restMinutes: 4, focus: "Long Speed", level: "Advanced"),
    ComprehensiveSprintSession(id: 75, name: "Volume Pyramid", distanceYards: 95, reps: 17, restMinutes: 5, focus: "Volume Training", level: "Advanced"),
    ComprehensiveSprintSession(id: 76, name: "Capacity Pyramid", distanceYards: 80, reps: 13, restMinutes: 4, focus: "Speed Capacity", level: "Advanced"),
    ComprehensiveSprintSession(id: 77, name: "Power Endurance Pyramid", distanceYards: 75, reps: 11, restMinutes: 4, focus: "Power Endurance", level: "Advanced"),
    ComprehensiveSprintSession(id: 78, name: "Max Pyramid", distanceYards: 100, reps: 21, restMinutes: 5, focus: "Maximum Endurance", level: "Advanced"),
    ComprehensiveSprintSession(id: 79, name: "Elite Pyramid", distanceYards: 90, reps: 19, restMinutes: 5, focus: "Elite Development", level: "Advanced"),
    ComprehensiveSprintSession(id: 80, name: "Challenge Pyramid", distanceYards: 85, reps: 17, restMinutes: 4, focus: "Challenge Training", level: "Advanced"),
    ComprehensiveSprintSession(id: 81, name: "Ultimate Pyramid", distanceYards: 95, reps: 19, restMinutes: 5, focus: "Ultimate Speed", level: "Advanced"),
    
    // ELITE PYRAMIDS (Maximum Endurance - Complex Patterns)
    ComprehensiveSprintSession(id: 82, name: "Master Pyramid", distanceYards: 100, reps: 21, restMinutes: 5, focus: "Master Level", level: "Elite"),
    ComprehensiveSprintSession(id: 83, name: "Champion Pyramid", distanceYards: 95, reps: 19, restMinutes: 5, focus: "Championship Training", level: "Elite"),
    ComprehensiveSprintSession(id: 84, name: "Pro Pyramid", distanceYards: 90, reps: 17, restMinutes: 5, focus: "Professional Level", level: "Elite"),
    ComprehensiveSprintSession(id: 85, name: "Olympic Pyramid", distanceYards: 100, reps: 23, restMinutes: 5, focus: "Olympic Preparation", level: "Elite"),
    ComprehensiveSprintSession(id: 86, name: "World Class Pyramid", distanceYards: 95, reps: 21, restMinutes: 5, focus: "World Class Speed", level: "Elite"),
    ComprehensiveSprintSession(id: 87, name: "Record Pyramid", distanceYards: 90, reps: 19, restMinutes: 5, focus: "Record Breaking", level: "Elite"),
    ComprehensiveSprintSession(id: 88, name: "Legendary Pyramid", distanceYards: 100, reps: 25, restMinutes: 5, focus: "Legendary Performance", level: "Elite"),
    ComprehensiveSprintSession(id: 89, name: "Supreme Pyramid", distanceYards: 85, reps: 15, restMinutes: 4, focus: "Supreme Speed", level: "Elite"),
    ComprehensiveSprintSession(id: 90, name: "Apex Pyramid", distanceYards: 95, reps: 17, restMinutes: 5, focus: "Apex Performance", level: "Elite"),
    ComprehensiveSprintSession(id: 91, name: "Peak Performance Pyramid", distanceYards: 100, reps: 27, restMinutes: 5, focus: "Peak Performance", level: "Elite"),
    
    // SPECIALIZED PYRAMIDS (Unique Patterns & Increments)
    ComprehensiveSprintSession(id: 92, name: "Fibonacci Pyramid", distanceYards: 55, reps: 9, restMinutes: 3, focus: "Mathematical Progression", level: "Intermediate"),
    ComprehensiveSprintSession(id: 93, name: "Golden Pyramid", distanceYards: 62, reps: 11, restMinutes: 3, focus: "Golden Ratio", level: "Intermediate"),
    ComprehensiveSprintSession(id: 94, name: "Prime Pyramid", distanceYards: 47, reps: 9, restMinutes: 2, focus: "Prime Numbers", level: "Intermediate"),
    ComprehensiveSprintSession(id: 95, name: "Odd Pyramid", distanceYards: 45, reps: 9, restMinutes: 2, focus: "Odd Increments", level: "Intermediate"),
    ComprehensiveSprintSession(id: 96, name: "Even Pyramid", distanceYards: 60, reps: 11, restMinutes: 3, focus: "Even Increments", level: "Intermediate"),
    ComprehensiveSprintSession(id: 97, name: "Mixed Pyramid", distanceYards: 67, reps: 13, restMinutes: 3, focus: "Mixed Increments", level: "Advanced"),
    ComprehensiveSprintSession(id: 98, name: "Random Pyramid", distanceYards: 73, reps: 11, restMinutes: 4, focus: "Random Progression", level: "Advanced"),
    ComprehensiveSprintSession(id: 99, name: "Chaos Pyramid", distanceYards: 58, reps: 13, restMinutes: 3, focus: "Chaos Training", level: "Advanced"),
    ComprehensiveSprintSession(id: 100, name: "Custom Pyramid", distanceYards: 85, reps: 15, restMinutes: 4, focus: "Custom Pattern", level: "Advanced"),
    ComprehensiveSprintSession(id: 101, name: "Adaptive Pyramid", distanceYards: 70, reps: 13, restMinutes: 4, focus: "Adaptive Training", level: "Advanced"),
    
    // MICRO PYRAMIDS (5-yard increments)
    ComprehensiveSprintSession(id: 102, name: "Micro Speed Pyramid", distanceYards: 25, reps: 7, restMinutes: 1, focus: "Micro Progression", level: "Beginner"),
    ComprehensiveSprintSession(id: 103, name: "Fine Pyramid", distanceYards: 35, reps: 9, restMinutes: 2, focus: "Fine Tuning", level: "Beginner"),
    ComprehensiveSprintSession(id: 104, name: "Precision Pyramid", distanceYards: 45, reps: 11, restMinutes: 2, focus: "Precision Speed", level: "Intermediate"),
    ComprehensiveSprintSession(id: 105, name: "Detail Pyramid", distanceYards: 55, reps: 13, restMinutes: 3, focus: "Detail Work", level: "Intermediate"),
    ComprehensiveSprintSession(id: 106, name: "Refined Pyramid", distanceYards: 65, reps: 15, restMinutes: 3, focus: "Refined Speed", level: "Advanced"),
    
    // MACRO PYRAMIDS (15-20 yard increments)
    ComprehensiveSprintSession(id: 107, name: "Macro Pyramid", distanceYards: 80, reps: 9, restMinutes: 4, focus: "Macro Progression", level: "Advanced"),
    ComprehensiveSprintSession(id: 108, name: "Big Step Pyramid", distanceYards: 100, reps: 11, restMinutes: 5, focus: "Big Steps", level: "Advanced"),
    ComprehensiveSprintSession(id: 109, name: "Giant Pyramid", distanceYards: 90, reps: 9, restMinutes: 5, focus: "Giant Steps", level: "Elite"),
    ComprehensiveSprintSession(id: 110, name: "Massive Pyramid", distanceYards: 100, reps: 13, restMinutes: 5, focus: "Massive Progression", level: "Elite"),
    
    // ASYMMETRIC PYRAMIDS (Different up/down patterns)
    ComprehensiveSprintSession(id: 111, name: "Steep Pyramid", distanceYards: 60, reps: 9, restMinutes: 3, focus: "Steep Climb", level: "Intermediate"),
    ComprehensiveSprintSession(id: 112, name: "Gentle Pyramid", distanceYards: 50, reps: 13, restMinutes: 3, focus: "Gentle Build", level: "Intermediate"),
    ComprehensiveSprintSession(id: 113, name: "Skewed Pyramid", distanceYards: 70, reps: 11, restMinutes: 4, focus: "Asymmetric Pattern", level: "Advanced"),
    ComprehensiveSprintSession(id: 114, name: "Lopsided Pyramid", distanceYards: 65, reps: 13, restMinutes: 3, focus: "Uneven Build", level: "Advanced"),
    
    // DOUBLE PEAK PYRAMIDS
    ComprehensiveSprintSession(id: 115, name: "Twin Peak Pyramid", distanceYards: 60, reps: 15, restMinutes: 3, focus: "Double Peak", level: "Advanced"),
    ComprehensiveSprintSession(id: 116, name: "Double Summit Pyramid", distanceYards: 70, reps: 17, restMinutes: 4, focus: "Two Summits", level: "Advanced"),
    ComprehensiveSprintSession(id: 117, name: "Dual Apex Pyramid", distanceYards: 80, reps: 19, restMinutes: 4, focus: "Dual Peaks", level: "Elite"),
    
    // TRIPLE PEAK PYRAMIDS
    ComprehensiveSprintSession(id: 118, name: "Triple Peak Pyramid", distanceYards: 50, reps: 21, restMinutes: 3, focus: "Triple Peak", level: "Elite"),
    ComprehensiveSprintSession(id: 119, name: "Three Summit Pyramid", distanceYards: 60, reps: 23, restMinutes: 3, focus: "Three Summits", level: "Elite"),
    
    // PLATEAU PYRAMIDS (Flat tops)
    ComprehensiveSprintSession(id: 120, name: "Plateau Pyramid", distanceYards: 40, reps: 11, restMinutes: 2, focus: "Plateau Training", level: "Intermediate"),
    ComprehensiveSprintSession(id: 121, name: "Mesa Pyramid", distanceYards: 60, reps: 15, restMinutes: 3, focus: "Mesa Pattern", level: "Advanced"),
    ComprehensiveSprintSession(id: 122, name: "Table Pyramid", distanceYards: 80, reps: 17, restMinutes: 4, focus: "Table Top", level: "Advanced"),
    
    // WAVE PYRAMIDS (Multiple peaks and valleys)
    ComprehensiveSprintSession(id: 123, name: "Wave Pattern Pyramid", distanceYards: 70, reps: 19, restMinutes: 4, focus: "Wave Pattern", level: "Elite"),
    ComprehensiveSprintSession(id: 124, name: "Oscillating Pyramid", distanceYards: 60, reps: 17, restMinutes: 3, focus: "Oscillation", level: "Advanced"),
    ComprehensiveSprintSession(id: 125, name: "Ripple Pyramid", distanceYards: 50, reps: 15, restMinutes: 3, focus: "Ripple Effect", level: "Advanced"),
    
    // SPEED-SPECIFIC PYRAMIDS
    ComprehensiveSprintSession(id: 126, name: "Acceleration Pyramid", distanceYards: 30, reps: 9, restMinutes: 2, focus: "Acceleration Focus", level: "Beginner"),
    ComprehensiveSprintSession(id: 127, name: "Max Velocity Pyramid", distanceYards: 50, reps: 11, restMinutes: 3, focus: "Max Velocity", level: "Intermediate"),
    ComprehensiveSprintSession(id: 128, name: "Speed Maintenance Pyramid", distanceYards: 70, reps: 13, restMinutes: 4, focus: "Speed Maintenance", level: "Advanced"),
    ComprehensiveSprintSession(id: 129, name: "Deceleration Pyramid", distanceYards: 90, reps: 15, restMinutes: 5, focus: "Deceleration Control", level: "Advanced"),
    
    // ENDURANCE-SPECIFIC PYRAMIDS
    ComprehensiveSprintSession(id: 130, name: "Short Endurance Pyramid", distanceYards: 60, reps: 13, restMinutes: 2, focus: "Short Endurance", level: "Intermediate"),
    ComprehensiveSprintSession(id: 131, name: "Medium Endurance Pyramid", distanceYards: 80, reps: 15, restMinutes: 3, focus: "Medium Endurance", level: "Advanced"),
    ComprehensiveSprintSession(id: 132, name: "Long Endurance Pyramid", distanceYards: 100, reps: 17, restMinutes: 3, focus: "Long Endurance", level: "Elite"),
    
    // RECOVERY PYRAMIDS (Active recovery focus)
    ComprehensiveSprintSession(id: 133, name: "Recovery Pyramid", distanceYards: 40, reps: 9, restMinutes: 3, focus: "Active Recovery", level: "Beginner"),
    ComprehensiveSprintSession(id: 134, name: "Easy Pyramid", distanceYards: 30, reps: 7, restMinutes: 3, focus: "Easy Pace", level: "Beginner"),
    ComprehensiveSprintSession(id: 135, name: "Gentle Build Pyramid", distanceYards: 50, reps: 11, restMinutes: 3, focus: "Gentle Build", level: "Intermediate"),
    
    // POWER PYRAMIDS (Explosive focus)
    ComprehensiveSprintSession(id: 136, name: "Explosive Pyramid", distanceYards: 35, reps: 7, restMinutes: 4, focus: "Explosive Power", level: "Intermediate"),
    ComprehensiveSprintSession(id: 137, name: "Power Burst Pyramid", distanceYards: 45, reps: 9, restMinutes: 5, focus: "Power Bursts", level: "Advanced"),
    ComprehensiveSprintSession(id: 138, name: "Dynamic Pyramid", distanceYards: 55, reps: 11, restMinutes: 6, focus: "Dynamic Power", level: "Advanced"),
    
    // TECHNICAL PYRAMIDS (Form focus)
    ComprehensiveSprintSession(id: 139, name: "Form Pyramid", distanceYards: 40, reps: 9, restMinutes: 2, focus: "Form Development", level: "Beginner"),
    ComprehensiveSprintSession(id: 140, name: "Technique Pyramid", distanceYards: 50, reps: 11, restMinutes: 3, focus: "Technique Work", level: "Intermediate"),
    ComprehensiveSprintSession(id: 141, name: "Mechanics Pyramid", distanceYards: 60, reps: 13, restMinutes: 3, focus: "Mechanics Focus", level: "Advanced"),
    
    // SEASONAL PYRAMIDS (Periodization)
    ComprehensiveSprintSession(id: 142, name: "Base Building Pyramid", distanceYards: 70, reps: 15, restMinutes: 2, focus: "Base Building", level: "Intermediate"),
    ComprehensiveSprintSession(id: 143, name: "Competition Prep Pyramid", distanceYards: 50, reps: 9, restMinutes: 5, focus: "Competition Prep", level: "Advanced"),
    ComprehensiveSprintSession(id: 144, name: "Peak Season Pyramid", distanceYards: 40, reps: 7, restMinutes: 6, focus: "Peak Performance", level: "Elite"),
    ComprehensiveSprintSession(id: 145, name: "Off Season Pyramid", distanceYards: 80, reps: 17, restMinutes: 3, focus: "Off Season", level: "Intermediate"),
    
    // WEATHER-SPECIFIC PYRAMIDS
    ComprehensiveSprintSession(id: 146, name: "Wind Training Pyramid", distanceYards: 60, reps: 11, restMinutes: 3, focus: "Wind Resistance", level: "Advanced"),
    ComprehensiveSprintSession(id: 147, name: "Heat Adaptation Pyramid", distanceYards: 50, reps: 9, restMinutes: 4, focus: "Heat Training", level: "Intermediate"),
    ComprehensiveSprintSession(id: 148, name: "Cold Weather Pyramid", distanceYards: 40, reps: 11, restMinutes: 2, focus: "Cold Adaptation", level: "Intermediate"),
    
    // FINAL SPECIALTY PYRAMIDS
    ComprehensiveSprintSession(id: 149, name: "Mental Toughness Pyramid", distanceYards: 90, reps: 19, restMinutes: 3, focus: "Mental Strength", level: "Elite"),
    ComprehensiveSprintSession(id: 150, name: "Breakthrough Pyramid", distanceYards: 100, reps: 21, restMinutes: 3, focus: "Performance Breakthrough", level: "Elite"),
    ComprehensiveSprintSession(id: 151, name: "Ultimate Challenge Pyramid", distanceYards: 100, reps: 25, restMinutes: 4, focus: "Ultimate Challenge", level: "Elite")
]

// MARK: - Comprehensive Session Wrapper Function
/// Wraps a sprint session into a complete SC40 training session with full workout flow

func wrapComprehensiveSession(_ sprint: ComprehensiveSprintSession) -> ComprehensiveTrainingSession {
    // Build the complete workout flow
    var sets: [ComprehensiveSprintSet] = []

    // Warm-up jog (300-400m) represented as ~440 yards (~400m), 1 rep
    sets.append(ComprehensiveSprintSet(distanceYards: 440, reps: 1, intensity: "Warm-up Jog (3 min)", restMinutes: 0))

    // Dynamic stretch (5 minutes) - modeled as 0 distance with restSeconds to represent a timed block
    sets.append(ComprehensiveSprintSet(distanceYards: 0, reps: 1, intensity: "Dynamic Stretch (5 min)", restMinutes: 300))

    // Drills: High Knees, Butt Kicks, A-Skips (each 3 reps at 20 yards)
    sets.append(ComprehensiveSprintSet(distanceYards: 20, reps: 3, intensity: "High Knees", restMinutes: 30))
    sets.append(ComprehensiveSprintSet(distanceYards: 20, reps: 3, intensity: "Butt Kicks", restMinutes: 30))
    sets.append(ComprehensiveSprintSet(distanceYards: 20, reps: 3, intensity: "A-Skips", restMinutes: 30))

    // Strides (GPS check) - 20 yards x4 with 2 minutes rest between reps
    sets.append(ComprehensiveSprintSet(distanceYards: 20, reps: 4, intensity: "Strides (GPS Check)", restMinutes: 120))

    // Main sprint block (from sprint session)
    sets.append(ComprehensiveSprintSet(distanceYards: sprint.distanceYards, reps: sprint.reps, intensity: sprint.name, restMinutes: sprint.restMinutes))

    // Cool down jog (~400m represented as 440 yards) and short mobility
    sets.append(ComprehensiveSprintSet(distanceYards: 440, reps: 1, intensity: "Cool Down Jog", restMinutes: 0))
    sets.append(ComprehensiveSprintSet(distanceYards: 0, reps: 1, intensity: "Cool Down Mobility / Foam Roll", restMinutes: 180))

    let accessories = [
        "Foam Roll Quads/Hamstrings 5 min",
        "Mobility Flow 5 min",
        "Core Stability 5 min"
    ]

    let notes = "SC40 flow: Warm-up → Drills → Strides (GPS check) → Main sprints → Cool-down. Adjust main sprint reps/distance by week. Watch enforces rest via haptics."

    return ComprehensiveTrainingSession(
        id: sprint.id,
        name: sprint.name,
        focus: sprint.focus,
        level: sprint.level,
        sprints: sets,
        accessoryWork: accessories,
        notes: notes
    )
}

// MARK: - Full Comprehensive Library
/// Complete library of 185 comprehensive training sessions
let comprehensiveTrainingLibrary: [ComprehensiveTrainingSession] = comprehensiveSprintSessions.map { wrapComprehensiveSession($0) }

// MARK: - Integration Extensions
extension SprintSessionTemplate {
    /// Converts existing SprintSessionTemplate to ComprehensiveTrainingSession format
    func toComprehensiveSession() -> ComprehensiveTrainingSession {
        let sprintSession = ComprehensiveSprintSession(
            id: self.id,
            name: self.name,
            distanceYards: self.distance,
            reps: self.reps,
            restMinutes: self.rest,
            focus: self.focus,
            level: self.level
        )
        return wrapComprehensiveSession(sprintSession)
    }
}

// MARK: - 12-Week Program Integration
extension ComprehensiveTrainingSession {
    /// Converts ComprehensiveTrainingSession to existing TrainingSession format for compatibility
    func toTrainingSession(week: Int, day: Int) -> TrainingSession {
        // Convert ComprehensiveSprintSet to SprintSet
        let convertedSprints = self.sprints.map { comprehensiveSet in
            SprintSet(
                distanceYards: comprehensiveSet.distanceYards,
                reps: comprehensiveSet.reps,
                intensity: comprehensiveSet.intensity
            )
        }
        
        return TrainingSession(
            id: TrainingSession.stableSessionID(week: week, day: day),
            week: week,
            day: day,
            type: "Comprehensive",
            focus: self.focus,
            sprints: convertedSprints,
            accessoryWork: self.accessoryWork,
            notes: self.notes
        )
    }
}
