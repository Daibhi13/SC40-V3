import SwiftUI

struct SprintTimerProWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Picker parameters
    let distance: Int
    let reps: Int
    let restMinutes: Int
    
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "warmup"
        case stretch = "stretch"
        case drill = "drill"
        case strides = "strides"
        case sprints = "sprints"
        case resting = "resting"
        case cooldown = "cooldown"
        case completed = "completed"
    }
    
    var body: some View {
        // Use UnifiedSprintCoachView as the main workout interface
        UnifiedSprintCoachView(
            sessionConfig: createSessionConfigFromPicker(),
            onClose: {
                presentationMode.wrappedValue.dismiss()
            }
        )
        .navigationBarHidden(true)
    }
    
    // MARK: - Session Configuration Creation
    private func createSessionConfigFromPicker() -> SessionConfiguration {
        let sessionName = "\(distance) Yard Custom Sprint"
        let sessionType = determineSessionType()
        let difficulty = determineDifficulty()
        let estimatedDuration = calculateEstimatedDuration()
        let workoutVariation = determineWorkoutVariation()
        
        return SessionConfiguration(
            sessionName: sessionName,
            sessionType: sessionType,
            distance: distance,
            reps: reps,
            restMinutes: restMinutes,
            description: "Custom sprint workout configured via Sprint Timer Pro",
            difficulty: difficulty,
            estimatedDuration: estimatedDuration,
            focus: determineFocus(),
            hasWarmup: true,
            hasStretching: true,
            hasDrills: true,
            hasStrides: true,
            hasCooldown: true,
            workoutVariation: workoutVariation
        )
    }
    
    private func determineSessionType() -> String {
        switch distance {
        case 10...25: return "Acceleration Training"
        case 26...45: return "Speed Training"
        case 46...60: return "Max Velocity Training"
        default: return "Endurance Training"
        }
    }
    
    private func determineDifficulty() -> String {
        let totalVolume = distance * reps
        switch totalVolume {
        case 0...200: return "Beginner"
        case 201...400: return "Intermediate"
        default: return "Advanced"
        }
    }
    
    private func calculateEstimatedDuration() -> String {
        let workoutTime = (reps * restMinutes) + 15
        return "\(workoutTime) min"
    }
    
    private func determineWorkoutVariation() -> SessionConfiguration.WorkoutVariation {
        if reps >= 10 && restMinutes <= 2 {
            return .intervals
        } else if distance >= 50 {
            return .flying
        } else if distance <= 25 {
            return .acceleration
        } else if reps >= 8 {
            return .endurance
        } else {
            return .standard
        }
    }
    
    private func determineFocus() -> String {
        switch distance {
        case 10...25: return "Explosive starts and acceleration"
        case 26...45: return "Maximum speed development"
        case 46...60: return "Top-end velocity maintenance"
        default: return "Speed endurance and power"
        }
    }
}

#Preview {
    SprintTimerProWorkoutView(distance: 40, reps: 6, restMinutes: 2)
}
