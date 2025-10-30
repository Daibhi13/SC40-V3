import Foundation

// MARK: - Dynamic Session Naming Service (Watch Version)

/// Service that generates dynamic session names and types based on user profile and session characteristics
class DynamicSessionNamingService {
    static let shared = DynamicSessionNamingService()
    
    private init() {}
    
    // MARK: - Session Type Generation
    
    /// Generate dynamic session type based on user level, distance, and training focus
    func generateSessionType(
        userLevel: String,
        distance: Int,
        reps: Int,
        intensity: String,
        dayInWeek: Int = 1
    ) -> String {
        let level = userLevel.lowercased()
        
        // Base session type on distance and intensity
        let baseType = getBaseSessionType(distance: distance, intensity: intensity)
        
        // Add level-specific modifier
        let levelModifier = getLevelModifier(level: level, dayInWeek: dayInWeek)
        
        return "\(levelModifier) \(baseType)"
    }
    
    /// Generate dynamic session focus based on user profile and session characteristics
    func generateSessionFocus(
        userLevel: String,
        distance: Int,
        reps: Int,
        weekNumber: Int,
        dayInWeek: Int
    ) -> String {
        let level = userLevel.lowercased()
        
        // Get phase-based focus
        let phaseFocus = getPhaseFocus(weekNumber: weekNumber)
        
        // Get level-specific focus
        let levelFocus = getLevelSpecificFocus(
            level: level,
            distance: distance,
            dayInWeek: dayInWeek
        )
        
        return "\(levelFocus) \(phaseFocus)"
    }
    
    /// Generate dynamic session name based on session characteristics
    func generateSessionName(
        distance: Int,
        reps: Int,
        sessionType: String,
        userLevel: String
    ) -> String {
        let level = userLevel.lowercased()
        
        // Check for special patterns
        if isLadderPattern(distance: distance, reps: reps) {
            return generateLadderName(distance: distance, reps: reps, level: level)
        }
        
        if isPyramidPattern(distance: distance, reps: reps) {
            return generatePyramidName(distance: distance, reps: reps, level: level)
        }
        
        // Standard session naming
        return generateStandardName(distance: distance, reps: reps, level: level)
    }
    
    // MARK: - Private Helper Methods
    
    private func getBaseSessionType(distance: Int, intensity: String) -> String {
        switch (distance, intensity.lowercased()) {
        case (10...25, _):
            return "Acceleration Work"
        case (26...40, "moderate"):
            return "Speed Development"
        case (26...40, "high"), (26...40, "max"):
            return "Speed Training"
        case (41...60, "moderate"), (41...60, "high"):
            return "Speed Building"
        case (41...60, "max"):
            return "Velocity Training"
        case (61...80, _):
            return "Speed Endurance"
        case (81..., _):
            return "Extended Speed"
        default:
            return "Sprint Training"
        }
    }
    
    private func getLevelModifier(level: String, dayInWeek: Int) -> String {
        switch level {
        case "beginner":
            let modifiers = ["Foundation", "Basic", "Technique"]
            return modifiers[dayInWeek % modifiers.count]
            
        case "intermediate":
            let modifiers = ["Progressive", "Development", "Building"]
            return modifiers[dayInWeek % modifiers.count]
            
        case "advanced":
            let modifiers = ["High-Intensity", "Performance", "Power"]
            return modifiers[dayInWeek % modifiers.count]
            
        case "pro", "elite":
            let modifiers = ["Elite", "Competition", "Peak"]
            return modifiers[dayInWeek % modifiers.count]
            
        default:
            return "Progressive"
        }
    }
    
    private func getPhaseFocus(weekNumber: Int) -> String {
        switch weekNumber {
        case 1...3:
            return "Mechanics"
        case 4...6:
            return "Development"
        case 7...9:
            return "Velocity"
        case 10...12:
            return "Performance"
        default:
            return "Training"
        }
    }
    
    private func getLevelSpecificFocus(level: String, distance: Int, dayInWeek: Int) -> String {
        switch level {
        case "beginner":
            let focuses = ["Technique", "Form", "Movement Quality"]
            return focuses[dayInWeek % focuses.count]
            
        case "intermediate":
            let focuses = ["Speed Building", "Power Development", "Endurance Speed"]
            return focuses[dayInWeek % focuses.count]
            
        case "advanced":
            let focuses = ["Maximum Output", "Explosive Power", "Speed Maintenance"]
            return focuses[dayInWeek % focuses.count]
            
        case "pro", "elite":
            let focuses = ["Peak Velocity", "Elite Performance", "Competition Ready"]
            return focuses[dayInWeek % focuses.count]
            
        default:
            return "Speed Focus"
        }
    }
    
    private func isLadderPattern(distance: Int, reps: Int) -> Bool {
        // Detect ladder patterns (multiple distances in progression)
        return reps >= 3 && distance >= 30
    }
    
    private func isPyramidPattern(distance: Int, reps: Int) -> Bool {
        // Detect pyramid patterns (up and down distance progression)
        return reps >= 5 && reps % 2 == 1 && distance >= 20
    }
    
    private func generateLadderName(distance: Int, reps: Int, level: String) -> String {
        let startDistance = max(10, distance - (reps * 5))
        let endDistance = distance
        
        let levelPrefix = getLevelPrefix(level: level)
        return "\(levelPrefix) \(startDistance)-\(endDistance)yd Ladder"
    }
    
    private func generatePyramidName(distance: Int, reps: Int, level: String) -> String {
        let peakDistance = distance
        let baseDistance = max(10, distance - 20)
        
        let levelPrefix = getLevelPrefix(level: level)
        return "\(levelPrefix) \(baseDistance)-\(peakDistance)yd Pyramid"
    }
    
    private func generateStandardName(distance: Int, reps: Int, level: String) -> String {
        let levelPrefix = getLevelPrefix(level: level)
        return "\(levelPrefix) \(distance)yd × \(reps)"
    }
    
    private func getLevelPrefix(level: String) -> String {
        switch level {
        case "beginner":
            return "Foundation"
        case "intermediate":
            return "Progressive"
        case "advanced":
            return "Performance"
        case "pro", "elite":
            return "Elite"
        default:
            return "Training"
        }
    }
}

// MARK: - Session Configuration Extensions

extension DynamicSessionNamingService {
    
    /// Generate complete session configuration with dynamic naming
    func generateSessionConfiguration(
        userLevel: String,
        distance: Int,
        reps: Int,
        intensity: String,
        weekNumber: Int,
        dayInWeek: Int
    ) -> (name: String, type: String, focus: String) {
        
        let sessionType = generateSessionType(
            userLevel: userLevel,
            distance: distance,
            reps: reps,
            intensity: intensity,
            dayInWeek: dayInWeek
        )
        
        let sessionFocus = generateSessionFocus(
            userLevel: userLevel,
            distance: distance,
            reps: reps,
            weekNumber: weekNumber,
            dayInWeek: dayInWeek
        )
        
        let sessionName = generateSessionName(
            distance: distance,
            reps: reps,
            sessionType: sessionType,
            userLevel: userLevel
        )
        
        return (name: sessionName, type: sessionType, focus: sessionFocus)
    }
}
