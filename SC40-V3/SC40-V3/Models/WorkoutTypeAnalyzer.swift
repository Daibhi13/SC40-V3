import Foundation
import SwiftUI

// MARK: - Workout Type Analyzer
/// Analyzes SessionLibrary data to categorize workouts efficiently
struct WorkoutTypeAnalyzer {
    
    // MARK: - Workout Categories
    enum WorkoutCategory: String, CaseIterable {
        case speedDistances = "Speed Distances"
        case pyramidDistances = "Pyramid Distances"
        case flyingDistances = "Flying Distances"
        case splitDistances = "Split Distances"
        case ladderDistances = "Ladder Distances"
        case repeatDistances = "Repeat Distances"
        case tempoDistances = "Tempo Distances"
        case benchmarkTest = "Benchmark Test"
        case accelerationWork = "Acceleration Work"
        case maxVelocityWork = "Max Velocity Work"
        case shuttleWork = "Shuttle Work"
        case drillWork = "Drill Work"
        
        var icon: String {
            switch self {
            case .speedDistances: return "bolt.fill"
            case .pyramidDistances: return "triangle.fill"
            case .flyingDistances: return "airplane"
            case .splitDistances: return "divide.square.fill"
            case .ladderDistances: return "ladder"
            case .repeatDistances: return "repeat"
            case .tempoDistances: return "metronome.fill"
            case .benchmarkTest: return "stopwatch.fill"
            case .accelerationWork: return "forward.fill"
            case .maxVelocityWork: return "speedometer"
            case .shuttleWork: return "arrow.left.arrow.right"
            case .drillWork: return "figure.run"
            }
        }
        
        var color: (red: Double, green: Double, blue: Double) {
            switch self {
            case .speedDistances: return (1.0, 0.8, 0.0) // Yellow
            case .pyramidDistances: return (0.0, 0.8, 1.0) // Blue
            case .flyingDistances: return (1.0, 0.4, 0.8) // Pink
            case .splitDistances: return (0.8, 0.4, 1.0) // Purple
            case .ladderDistances: return (0.4, 1.0, 0.8) // Green
            case .repeatDistances: return (1.0, 0.6, 0.4) // Orange
            case .tempoDistances: return (0.6, 0.8, 1.0) // Light Blue
            case .benchmarkTest: return (1.0, 0.2, 0.2) // Red
            case .accelerationWork: return (0.2, 1.0, 0.2) // Bright Green
            case .maxVelocityWork: return (1.0, 0.0, 0.5) // Magenta
            case .shuttleWork: return (0.8, 0.8, 0.2) // Olive
            case .drillWork: return (0.4, 0.6, 1.0) // Periwinkle
            }
        }
        
        var description: String {
            switch self {
            case .speedDistances: return "Pure speed development at various distances"
            case .pyramidDistances: return "Progressive distance increases and decreases"
            case .flyingDistances: return "Maximum velocity work with running start"
            case .splitDistances: return "Multi-segment distance combinations"
            case .ladderDistances: return "Progressive distance ladder sequences"
            case .repeatDistances: return "Consistent distance repetitions"
            case .tempoDistances: return "Controlled pace endurance work"
            case .benchmarkTest: return "Performance testing and measurement"
            case .accelerationWork: return "Starting speed and early acceleration"
            case .maxVelocityWork: return "Top-end speed development"
            case .shuttleWork: return "Multi-directional speed and agility"
            case .drillWork: return "Technical skill development"
            }
        }
    }
    
    // MARK: - Workout Analysis
    static func categorizeWorkout(_ template: MockSprintTemplate) -> WorkoutCategory {
        let name = template.name.lowercased()
        let focus = template.focus.lowercased()
        
        // Pyramid patterns
        if name.contains("pyramid") || name.contains("–") && name.contains("yd") {
            return .pyramidDistances
        }
        
        // Flying patterns
        if name.contains("flying") || focus.contains("max velocity") {
            return .flyingDistances
        }
        
        // Split patterns
        if name.contains("split") || name.contains("+") {
            return .splitDistances
        }
        
        // Ladder patterns
        if name.contains("ladder") {
            return .ladderDistances
        }
        
        // Tempo patterns
        if name.contains("tempo") {
            return .tempoDistances
        }
        
        // Benchmark patterns
        if name.contains("time trial") {
            return .benchmarkTest
        }
        
        // Shuttle patterns
        if name.contains("shuttle") {
            return .shuttleWork
        }
        
        // Acceleration work (short distances)
        if template.distance <= 25 && focus.contains("accel") {
            return .accelerationWork
        }
        
        // Max velocity work (longer distances)
        if template.distance >= 60 && (focus.contains("max") || focus.contains("velocity")) {
            return .maxVelocityWork
        }
        
        // Repeat patterns (multiple reps of same distance)
        if name.contains("×") || template.reps >= 5 {
            return .repeatDistances
        }
        
        // Default to speed distances
        return .speedDistances
    }
    
    // MARK: - Workout Process Steps
    static func getWorkoutSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        let category = categorizeWorkout(template)
        
        switch category {
        case .pyramidDistances:
            return getPyramidSteps(template)
        case .splitDistances:
            return getSplitSteps(template)
        case .ladderDistances:
            return getLadderSteps(template)
        case .flyingDistances:
            return getFlyingSteps(template)
        case .repeatDistances:
            return getRepeatSteps(template)
        case .benchmarkTest:
            return getBenchmarkSteps(template)
        default:
            return getStandardSteps(template)
        }
    }
    
    private static func getPyramidSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        // Parse pyramid pattern from name (e.g., "10–20–30 yd Pyramid")
        let distances = extractDistancesFromName(template.name)
        var steps: [WorkoutStep] = []
        
        for (index, distance) in distances.enumerated() {
            steps.append(WorkoutStep(
                stepNumber: index + 1,
                distance: distance,
                intensity: "Max Effort",
                restTime: template.rest,
                description: "Sprint \(distance) yards at maximum effort"
            ))
        }
        
        return steps
    }
    
    private static func getSplitSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        // Parse split pattern from name (e.g., "10+20 yd Split")
        let distances = extractDistancesFromName(template.name)
        var steps: [WorkoutStep] = []
        
        for (index, distance) in distances.enumerated() {
            steps.append(WorkoutStep(
                stepNumber: index + 1,
                distance: distance,
                intensity: index == 0 ? "Build Up" : "Max Effort",
                restTime: index == distances.count - 1 ? template.rest : 30,
                description: "Sprint \(distance) yards \(index == 0 ? "building speed" : "at maximum effort")"
            ))
        }
        
        return steps
    }
    
    private static func getLadderSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        // Similar to pyramid but with consistent progression
        let distances = extractDistancesFromName(template.name)
        var steps: [WorkoutStep] = []
        
        for (index, distance) in distances.enumerated() {
            steps.append(WorkoutStep(
                stepNumber: index + 1,
                distance: distance,
                intensity: "Progressive",
                restTime: template.rest,
                description: "Sprint \(distance) yards with progressive intensity"
            ))
        }
        
        return steps
    }
    
    private static func getFlyingSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        return [
            WorkoutStep(
                stepNumber: 1,
                distance: 20,
                intensity: "Build Up",
                restTime: 0,
                description: "20 yard acceleration build-up"
            ),
            WorkoutStep(
                stepNumber: 2,
                distance: template.distance,
                intensity: "Max Velocity",
                restTime: template.rest,
                description: "\(template.distance) yard flying sprint at max velocity"
            )
        ]
    }
    
    private static func getRepeatSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        return [
            WorkoutStep(
                stepNumber: 1,
                distance: template.distance,
                intensity: "Max Effort",
                restTime: template.rest,
                description: "\(template.distance) yard sprint × \(template.reps) reps"
            )
        ]
    }
    
    private static func getBenchmarkSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        return [
            WorkoutStep(
                stepNumber: 1,
                distance: template.distance,
                intensity: "Time Trial",
                restTime: template.rest,
                description: "\(template.distance) yard time trial - give everything you have!"
            )
        ]
    }
    
    private static func getStandardSteps(_ template: MockSprintTemplate) -> [WorkoutStep] {
        return [
            WorkoutStep(
                stepNumber: 1,
                distance: template.distance,
                intensity: "Max Effort",
                restTime: template.rest,
                description: "\(template.distance) yard sprint at maximum effort"
            )
        ]
    }
    
    // MARK: - Helper Functions
    private static func extractDistancesFromName(_ name: String) -> [Int] {
        let pattern = #"\d+"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: name, range: NSRange(name.startIndex..., in: name))
        
        return matches.compactMap { match in
            let range = Range(match.range, in: name)!
            return Int(name[range])
        }
    }
}

// MARK: - Workout Step Model
struct WorkoutStep: Identifiable {
    let id = UUID()
    let stepNumber: Int
    let distance: Int
    let intensity: String
    let restTime: Int
    let description: String
}

// MARK: - Helper Functions for SessionData
extension WorkoutTypeAnalyzer {
    static func getWorkoutCategoryForSession(name: String, focus: String, distance: Int, reps: Int) -> WorkoutCategory {
        let template = MockSprintTemplate(name: name, focus: focus, distance: distance, reps: reps)
        return categorizeWorkout(template)
    }
    
    static func getWorkoutStepsForSession(name: String, focus: String, distance: Int, reps: Int, rest: Int) -> [WorkoutStep] {
        let template = MockSprintTemplate(name: name, focus: focus, distance: distance, reps: reps, rest: rest)
        return getWorkoutSteps(template)
    }
}

// MARK: - Mock Template for Analysis
struct MockSprintTemplate {
    let name: String
    let focus: String
    let distance: Int
    let reps: Int
    let rest: Int
    
    init(name: String, focus: String, distance: Int, reps: Int, rest: Int = 120) {
        self.name = name
        self.focus = focus
        self.distance = distance
        self.reps = reps
        self.rest = rest
    }
}
