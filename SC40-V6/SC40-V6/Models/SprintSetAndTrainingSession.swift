import Foundation
import Combine

// MARK: - Session Tracking Model (Detailed)
// This model tracks individual sprint attempts within a session
struct SessionSprintSet: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let sprintIndex: Int // Index in the session's sprints array
    let setNumber: Int
    let repNumber: Int
    let targetDistanceYards: Int
    let intensity: String
    var actualTime: TimeInterval? // Actual time recorded for this rep
    var completedAt: Date?

    // MARK: - Computed Properties
    var isCompleted: Bool {
        return actualTime != nil
    }

    var performanceRating: PerformanceRating {
        // This would need target time from the session to calculate properly
        return .incomplete
    }

    enum PerformanceRating {
        case excellent, good, average, needsImprovement, incomplete
    }
}

// MARK: - Training Session Manager
class TrainingSessionManager: ObservableObject {
    @Published var currentSession: TrainingSession?
    @Published var sessionSprintSets: [SessionSprintSet] = []
    @Published var isActive = false
    @Published var currentSprintIndex = 0
    @Published var currentRepIndex = 0

    private var timer: Timer?
    private var startTime: Date?

    // MARK: - Session Control
    func startSession(_ session: TrainingSession) {
        currentSession = session
        sessionSprintSets.removeAll()
        currentSprintIndex = 0
        currentRepIndex = 0
        isActive = true

        // Initialize tracking sets for each sprint in the session
        for (sprintIndex, sprint) in session.sprints.enumerated() {
            for repNumber in 1...sprint.reps {
                let sessionSprintSet = SessionSprintSet(
                    id: UUID(),
                    sessionId: session.id,
                    sprintIndex: sprintIndex,
                    setNumber: sprintIndex + 1,
                    repNumber: repNumber,
                    targetDistanceYards: sprint.distanceYards,
                    intensity: sprint.intensity,
                    actualTime: nil,
                    completedAt: nil
                )
                sessionSprintSets.append(sessionSprintSet)
            }
        }
    }

    func pauseSession() {
        isActive = false
        timer?.invalidate()
    }

    func resumeSession() {
        isActive = true
    }

    func endSession() {
        isActive = false
        timer?.invalidate()
        completeCurrentSession()
    }

    // MARK: - Rep Management
    func startRep() {
        startTime = Date()
    }

    func completeRep() {
        guard let startTime = startTime else { return }
        let actualTime = Date().timeIntervalSince(startTime)

        // Find the current rep in sessionSprintSets
        if let currentRepIndex = findCurrentRepIndex(),
           currentRepIndex < sessionSprintSets.count {
            sessionSprintSets[currentRepIndex].actualTime = actualTime
            sessionSprintSets[currentRepIndex].completedAt = Date()

            // Advance to next rep
            advanceToNextRep()
        }
    }

    private func findCurrentRepIndex() -> Int? {
        return sessionSprintSets.firstIndex { set in
            set.sessionId == currentSession?.id &&
            set.sprintIndex == currentSprintIndex &&
            set.repNumber == currentRepIndex + 1
        }
    }

    private func advanceToNextRep() {
        if currentRepIndex < (currentSession?.sprints[currentSprintIndex].reps ?? 1) - 1 {
            currentRepIndex += 1
        } else {
            // Move to next sprint
            advanceToNextSprint()
        }
    }

    private func advanceToNextSprint() {
        if currentSprintIndex < (currentSession?.sprints.count ?? 1) - 1 {
            currentSprintIndex += 1
            currentRepIndex = 0
        } else {
            // Session complete
            endSession()
        }
    }

    private func completeCurrentSession() {
        // Update session with results
        // Calculate personal best, average time, etc.
        if var session = currentSession {
            let completedTimes = sessionSprintSets
                .filter { $0.sessionId == session.id && $0.actualTime != nil }
                .map { $0.actualTime! }

            if !completedTimes.isEmpty {
                session.personalBest = completedTimes.min()
                session.averageTime = completedTimes.reduce(0, +) / Double(completedTimes.count)
                session.isCompleted = true
                session.completionDate = Date()

                // Update sprintTimes array
                session.sprintTimes = completedTimes
            }

            currentSession = session
        }
    }

    // MARK: - Timing
    func startRestTimer(duration: TimeInterval, completion: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            completion()
        }
    }

    // MARK: - Current Sprint Info
    var currentSprint: SprintSet? {
        guard let session = currentSession,
              currentSprintIndex < session.sprints.count else { return nil }
        return session.sprints[currentSprintIndex]
    }

    var isSessionComplete: Bool {
        return currentSprintIndex >= (currentSession?.sprints.count ?? 1)
    }

    var progress: Double {
        let totalReps = sessionSprintSets.count
        let completedReps = sessionSprintSets.filter { $0.actualTime != nil }.count
        return totalReps > 0 ? Double(completedReps) / Double(totalReps) : 0
    }
}
