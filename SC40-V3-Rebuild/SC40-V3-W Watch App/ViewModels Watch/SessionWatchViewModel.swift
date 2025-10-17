import Foundation

/// Loads and selects sessions for the Watch.
class SessionWatchViewModel: ObservableObject {
    @Published var sessions: [TrainingSession] = []
    @Published var feedback: [SessionFeedback] = []
    
    init() {
        loadSessions()
        loadFeedback()
    }
    
    func loadSessions() {
        sessions = ProgramPersistence.loadSessions()
    }
    
    func loadFeedback() {
        feedback = ProgramPersistence.loadFeedback()
    }
    
    func addFeedback(_ newFeedback: SessionFeedback) {
        feedback.append(newFeedback)
        ProgramPersistence.saveFeedback(feedback)
        // Optionally trigger refresh on iPhone via App Group or notification
    }
}
