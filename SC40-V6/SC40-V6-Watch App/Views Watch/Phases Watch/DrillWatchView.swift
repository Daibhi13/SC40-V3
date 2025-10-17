import SwiftUI
import Combine

// MARK: - Local Type Definitions (required for subdirectory access)
struct WatchSprintSet: Codable, Sendable {
    let distanceYards: Int
    let reps: Int
    let intensity: String

    init(distanceYards: Int, reps: Int, intensity: String) {
        self.distanceYards = distanceYards
        self.reps = reps
        self.intensity = intensity
    }
}

struct WatchTrainingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let week: Int
    let day: Int
    let type: String
    let focus: String
    let sprints: [WatchSprintSet]
    let accessoryWork: [String]
    let notes: String?
    let isCompleted: Bool

    init(id: UUID = UUID(), week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = isCompleted
    }

    init(week: Int, day: Int, type: String, focus: String, sprints: [WatchSprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
        self.isCompleted = false
    }
}

// MARK: - Workout Phase Enum
enum WorkoutPhase: String, CaseIterable {
    case warmup = "Warm Up"
    case drills = "Drills"
    case strides20 = "20s Strides"
    case sprint = "Sprint"
    case rest = "Rest"
    case timeTrial = "Time Trial"
    case cooldown = "Cool Down"

    var displayName: String { rawValue }
}

// MARK: - WorkoutWatchViewModel (minimal definition for this view)
class WorkoutWatchViewModel: NSObject, ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    
    // MARK: - Published Properties
    @Published var repDistances: [Int] = [40]
    @Published var isSessionFinished: Bool = false
    @Published var currentPhase: WorkoutPhase = .warmup
    @Published var isPaused: Bool = false
    @Published var currentRepTime: TimeInterval = 0
    @Published var currentRestSeconds: Int? = nil
    @Published var currentRep: Int = 1
    @Published var totalReps: Int = 5
    @Published var restTimeString: String = "--"
    @Published var repProgress: Double = 0.5
    @Published var currentStrides: Int = 0
    @Published var lastRepTime: TimeInterval = 0
    @Published var restTime: TimeInterval = 30
    @Published var isRunning: Bool = false
    @Published var distanceTraveled: Double = 0
    @Published var isHapticEnabled: Bool = true

    var lastRepTimeString: String {
        lastRepTime > 0 ? String(format: "%.1f", lastRepTime) : "--"
    }

    var currentRepTimeString: String {
        String(format: "%.1f", currentRepTime)
    }

    var currentPhaseLabel: String { currentPhase.displayName }

    override init() {
        super.init()
    }

    func updateFromSession(distances: [Int]) {
        self.repDistances = distances
        self.totalReps = distances.count
    }

    static var mock: WorkoutWatchViewModel {
        let vm = WorkoutWatchViewModel()
        vm.isSessionFinished = false
        vm.currentPhase = .warmup
        vm.isPaused = false
        vm.isHapticEnabled = true
        vm.currentRepTime = 7.2
        vm.currentRestSeconds = 30
        vm.currentRep = 3
        vm.totalReps = 8
        vm.restTimeString = "00:30"
        vm.repProgress = 0.45
        vm.currentStrides = 22
        return vm
    }
}

/// Drills phase view.

struct DrillWatchView: View {
    var workoutVM: WorkoutWatchViewModel
    var body: some View {
        Text("Drills")
    }
}

#Preview {
    DrillWatchView(workoutVM: WorkoutWatchViewModel())
}
