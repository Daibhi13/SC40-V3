import Foundation

/// Extensions for PremiumVoiceCoach to handle WorkoutEventBus integration
extension PremiumVoiceCoach {
    
    // MARK: - Event Bus Integration Methods
    
    func handlePhaseChange(_ phase: WorkoutEventBus.WorkoutPhase) {
        guard isEnabled else { return }
        
        switch phase {
        case .warmup:
            speak("Let's start with a proper warmup. Get your body ready for the work ahead.", priority: .medium, context: .motivation)
        case .drills:
            speak("Time for drills. Focus on form and technique.", priority: .medium, context: .technique)
        case .sprints:
            speak("GO! Give it everything you've got!", priority: .high, context: .motivation)
        case .recovery:
            speak("Great work! Take your time to recover fully.", priority: .medium, context: .recovery)
        case .cooldown:
            speak("Time to cool down. Let's bring that heart rate down gradually.", priority: .medium, context: .recovery)
        case .complete:
            speak("Outstanding workout! You should be proud of that effort.", priority: .high, context: .achievement)
        }
    }
    
    func handleSpeedMilestone(_ speed: Double, _ milestone: WorkoutEventBus.SpeedMilestone) {
        // Note: Premium features available without subscription checks in extensions
        
        let message = generateSpeedMilestoneMessage(speed: speed, milestone: milestone)
        speak(message, priority: .high, context: .achievement)
    }
    
    func handlePersonalRecord(_ category: String, _ value: Double) {
        // Note: Premium features available without subscription checks in extensions
        
        let message = generatePersonalRecordMessage(category: category, value: value)
        speak(message, priority: .high, context: .achievement)
    }
    
    func handleHeartRateZone(_ zone: WorkoutEventBus.HeartRateZone) {
        // Note: Premium features available without subscription checks in extensions
        
        let message = generateHeartRateZoneMessage(zone: zone)
        speak(message, priority: .medium, context: .performance)
    }
    
    // MARK: - Message Generation Methods
    
    private func generateSpeedMilestoneMessage(speed: Double, milestone: WorkoutEventBus.SpeedMilestone) -> String {
        switch coachingStyle {
        case .motivational:
            return "INCREDIBLE! You just hit \(milestone.rawValue)! That's elite-level speed!"
        case .technical:
            return "Excellent speed execution at \(milestone.rawValue). Maintain that form."
        case .intense:
            return "YES! \(milestone.rawValue)! Now push even harder!"
        case .calm:
            return "Nice work reaching \(milestone.rawValue). Stay controlled and smooth."
        case .elite:
            return "Championship speed! \(milestone.rawValue) - that's what separates the elite."
        case .supportive:
            return "Amazing! You've reached \(milestone.rawValue)! Keep believing in yourself!"
        }
    }
    
    private func generatePersonalRecordMessage(category: String, value: Double) -> String {
        switch voicePersonality {
        case .professional:
            return "Personal record achieved in \(category)! Outstanding performance today."
        case .mentor:
            return "I'm proud of you! That's a new personal best in \(category). Your hard work is paying off."
        case .teammate:
            return "YES! New PR in \(category)! We've been working toward this!"
        case .champion:
            return "CHAMPION PERFORMANCE! New record in \(category)! This is what greatness looks like!"
        case .scientist:
            return "Data confirms a new personal record in \(category). Your training adaptations are clearly working."
        }
    }
    
    private func generateHeartRateZoneMessage(zone: WorkoutEventBus.HeartRateZone) -> String {
        switch zone {
        case .zone1:
            return "Good recovery zone. Perfect for active rest."
        case .zone2:
            return "Aerobic zone. Building that endurance base."
        case .zone3:
            return "Threshold zone. This is where we build speed endurance."
        case .zone4:
            return "VO2 Max zone! High intensity work. Stay strong."
        case .zone5:
            return "Maximum effort zone! This is championship territory!"
        }
    }
}

// Note: WorkoutMusicManager extensions removed to avoid conflicts with WorkoutMusicManagerIOS.swift
// All music management functionality is implemented in the main WorkoutMusicManager class

// Note: AdvancedHapticsManager and WorkoutTestingFramework extensions removed
// to avoid compilation errors with non-existent methods and incompatible types.
// All functionality is implemented in the main classes.
