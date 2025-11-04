import Foundation
import Combine

/// ViewModel for managing training sessions on the Watch
@MainActor
class SessionWatchViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var sessions: [TrainingSession] = []
    @Published var currentSession: TrainingSession? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let sessionManager = WatchSessionManager.shared

    // MARK: - Initialization
    override init() {
        super.init()
        setupObservers()
        loadSessions()
    }

    // MARK: - Setup
    private func setupObservers() {
        // Observe session manager changes
        sessionManager.$trainingSessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                self?.sessions = sessions
            }
            .store(in: &cancellables)
    }

    private func loadSessions() {
        isLoading = true
        // Sessions will be loaded via the session manager observer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }

    // MARK: - Public Methods
    func selectSession(_ session: TrainingSession) {
        currentSession = session
    }

    func completeSession(_ session: TrainingSession) {
        // Mark session as completed
        if sessions.contains(where: { $0.id == session.id }) {
            // Update session in local storage or send to phone
            let workoutResults: [String: Any] = [
                "sessionId": session.id.uuidString,
                "week": session.week,
                "day": session.day,
                "type": session.type,
                "completedAt": Date().timeIntervalSince1970,
                "isCompleted": true
            ]
            sessionManager.sendWorkoutResults(workoutResults)
        }
    }

    func refreshSessions() {
        loadSessions()
    }
}
