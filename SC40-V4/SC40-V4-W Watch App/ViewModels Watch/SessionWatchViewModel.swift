import SwiftUI
import Foundation
import Combine

/// Loads and selects sessions for the Watch.
class SessionWatchViewModel: NSObject, ObservableObject {
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
