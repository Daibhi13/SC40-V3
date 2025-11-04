import Foundation
import SwiftUI
import Combine

// MARK: - Specialized Manager Classes

// MARK: - History Manager
@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var sessions: [CompletedSession] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "completed_sessions"
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        isLoading = true
        
        if let data = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([CompletedSession].self, from: data) {
            self.sessions = sessions
        }
        
        isLoading = false
    }
    
    func addSession(_ session: CompletedSession) {
        sessions.append(session)
        saveSessions()
    }
    
    func deleteSession(_ session: CompletedSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            userDefaults.set(data, forKey: sessionsKey)
        }
    }
    
    func recordFullSession(
        session: SprintSessionTemplate,
        sprintTimes: [Double],
        notes: String,
        location: String?,
        weather: String?
    ) {
        // Convert sprint times to RepData
        let repData = sprintTimes.enumerated().map { index, time in
            RepData(
                rep: index + 1,
                time: time,
                isCompleted: true,
                repType: .sprint,
                distance: session.distance,
                timestamp: Date()
            )
        }
        
        let completedSession = CompletedSession(
            sessionName: session.name,
            date: Date(),
            duration: TimeInterval(sprintTimes.count * session.rest + Int(sprintTimes.reduce(0, +))),
            completedReps: repData,
            sessionType: session.sessionType.rawValue,
            level: session.level,
            notes: notes
        )
        
        addSession(completedSession)
    }
    
    func recordFullSession(
        session: TrainingSession,
        sprintTimes: [Double],
        notes: String,
        location: String?,
        weather: String?
    ) {
        // Convert sprint times to RepData
        let repData = sprintTimes.enumerated().map { index, time in
            RepData(
                rep: index + 1,
                time: time,
                isCompleted: true,
                repType: .sprint,
                distance: 40, // Default to 40 yards for time trials
                timestamp: Date()
            )
        }
        
        let completedSession = CompletedSession(
            sessionName: session.type,
            date: Date(),
            duration: TimeInterval(sprintTimes.reduce(0, +)),
            completedReps: repData,
            sessionType: session.type,
            level: "Intermediate", // Default level
            notes: notes
        )
        
        addSession(completedSession)
    }
    
    func getFilteredSessions(_ filter: HistoryFilter) -> [CompletedSession] {
        switch filter {
        case .all:
            return sessions
        case .sprints:
            return sessions.filter { $0.sessionType.lowercased().contains("sprint") }
        case .drills:
            return sessions.filter { $0.sessionType.lowercased().contains("drill") }
        case .benchmarks:
            return sessions.filter { $0.sessionType.lowercased().contains("benchmark") }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return sessions.filter { $0.date >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return sessions.filter { $0.date >= monthAgo }
        }
    }
}

// MARK: - Live Rep Log Manager
@MainActor
class LiveRepLogManager: ObservableObject {
    static let shared = LiveRepLogManager()
    
    @Published var currentSession: LiveSession?
    @Published var activeReps: [LiveRep] = []
    @Published var isRecording = false
    
    struct LiveSession {
        let id: UUID
        let startTime: Date
        let sessionName: String
        var reps: [LiveRep]
        
        init(sessionName: String) {
            self.id = UUID()
            self.startTime = Date()
            self.sessionName = sessionName
            self.reps = []
        }
    }
    
    func startSession(_ sessionName: String) {
        currentSession = LiveSession(sessionName: sessionName)
        activeReps.removeAll()
        isRecording = true
    }
    
    func addRep(_ rep: LiveRep) {
        activeReps.append(rep)
        currentSession?.reps.append(rep)
    }
    
    func completeSession() -> CompletedSession? {
        guard let session = currentSession else { return nil }
        
        let completedReps = session.reps.map { liveRep in
            RepData(
                rep: liveRep.repNumber,
                time: liveRep.duration ?? 0.0,
                isCompleted: liveRep.endTime != nil,
                repType: liveRep.repType,
                distance: Int(liveRep.distance),
                timestamp: liveRep.startTime
            )
        }
        
        let completedSession = CompletedSession(
            sessionName: session.sessionName,
            date: session.startTime,
            duration: Date().timeIntervalSince(session.startTime),
            completedReps: completedReps,
            sessionType: "Live Session",
            level: "User",
            notes: "Recorded via Live Rep Log"
        )
        
        currentSession = nil
        activeReps.removeAll()
        isRecording = false
        
        return completedSession
    }
    
    func cancelSession() {
        currentSession = nil
        activeReps.removeAll()
        isRecording = false
    }
}

// MARK: - Framework Managers
@MainActor
class GameKitManager: ObservableObject {
    static let shared = GameKitManager()
    
    @Published var isAuthenticated = false
    @Published var playerName: String?
    @Published var leaderboardScores: [LeaderboardScore] = []
    
    struct LeaderboardScore {
        let playerName: String
        let score: Double
        let rank: Int
        let date: Date
    }
    
    func authenticatePlayer() {
        // Simulate GameKit authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAuthenticated = true
            self.playerName = "Sprint Coach Player"
            self.loadLeaderboard()
        }
    }
    
    func submitScore(_ time: Double, category: String) {
        print("Submitting score: \(time)s for \(category)")
    }
    
    private func loadLeaderboard() {
        // Simulate leaderboard data
        leaderboardScores = [
            LeaderboardScore(playerName: "Speed Demon", score: 4.2, rank: 1, date: Date()),
            LeaderboardScore(playerName: "Fast Runner", score: 4.5, rank: 2, date: Date()),
            LeaderboardScore(playerName: "Sprint Master", score: 4.8, rank: 3, date: Date())
        ]
    }
}

@MainActor
class MusicKitManager: ObservableObject {
    static let shared = MusicKitManager()
    
    @Published var isAuthorized = false
    @Published var currentPlaylist: String?
    @Published var isPlaying = false
    
    func requestAuthorization() {
        // Simulate MusicKit authorization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAuthorized = true
        }
    }
    
    func playWorkoutPlaylist() {
        guard isAuthorized else { return }
        currentPlaylist = "Sprint Training Mix"
        isPlaying = true
    }
    
    func stopMusic() {
        isPlaying = false
        currentPlaylist = nil
    }
}

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [WorkoutNotification] = []
    
    struct WorkoutNotification {
        let id: UUID
        let title: String
        let body: String
        let scheduledDate: Date
        let type: NotificationType
        
        enum NotificationType {
            case workoutReminder
            case restDayReminder
            case achievementUnlocked
            case weeklyProgress
        }
        
        init(title: String, body: String, scheduledDate: Date, type: NotificationType) {
            self.id = UUID()
            self.title = title
            self.body = body
            self.scheduledDate = scheduledDate
            self.type = type
        }
    }
    
    func requestPermission() {
        // Simulate notification permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAuthorized = true
        }
    }
    
    func scheduleWorkoutReminder(for date: Date) {
        let notification = WorkoutNotification(
            title: "Sprint Training Reminder",
            body: "Time for your scheduled sprint session!",
            scheduledDate: date,
            type: .workoutReminder
        )
        pendingNotifications.append(notification)
    }
    
    func scheduleAchievementNotification(_ achievement: SC40Achievement) {
        let notification = WorkoutNotification(
            title: "Achievement Unlocked!",
            body: "You've earned: \(achievement.title)",
            scheduledDate: Date(),
            type: .achievementUnlocked
        )
        pendingNotifications.append(notification)
    }
}

@MainActor
class MessagesManager: ObservableObject {
    static let shared = MessagesManager()
    
    @Published var canSendMessages = false
    @Published var recentShares: [ShareMessage] = []
    
    struct ShareMessage {
        let id: UUID
        let content: String
        let timestamp: Date
        let type: ShareType
        
        enum ShareType {
            case workoutResult
            case achievement
            case progress
        }
        
        init(content: String, type: ShareType) {
            self.id = UUID()
            self.content = content
            self.timestamp = Date()
            self.type = type
        }
    }
    
    func checkAvailability() {
        // Simulate Messages availability check
        canSendMessages = true
    }
    
    func shareWorkoutResult(_ session: CompletedSession) {
        let message = ShareMessage(
            content: "Just completed a \(session.sessionName) session! 🏃‍♂️💨",
            type: .workoutResult
        )
        recentShares.append(message)
    }
    
    func shareAchievement(_ achievement: SC40Achievement) {
        let message = ShareMessage(
            content: "Unlocked new achievement: \(achievement.title)! 🏆",
            type: .achievement
        )
        recentShares.append(message)
    }
}

@MainActor
class IntentsManager: ObservableObject {
    static let shared = IntentsManager()
    
    @Published var isConfigured = false
    @Published var availableIntents: [WorkoutIntent] = []
    
    struct WorkoutIntent {
        let id: UUID
        let phrase: String
        let action: IntentAction
        let description: String
        
        enum IntentAction {
            case startWorkout
            case viewProgress
            case scheduleSession
            case checkStats
        }
        
        init(phrase: String, action: IntentAction, description: String) {
            self.id = UUID()
            self.phrase = phrase
            self.action = action
            self.description = description
        }
    }
    
    func setupIntents() {
        availableIntents = [
            WorkoutIntent(
                phrase: "Start sprint workout",
                action: .startWorkout,
                description: "Begin a new sprint training session"
            ),
            WorkoutIntent(
                phrase: "Show my progress",
                action: .viewProgress,
                description: "Display recent workout progress"
            ),
            WorkoutIntent(
                phrase: "Schedule training",
                action: .scheduleSession,
                description: "Schedule a future training session"
            ),
            WorkoutIntent(
                phrase: "Check my stats",
                action: .checkStats,
                description: "View current performance statistics"
            )
        ]
        isConfigured = true
    }
    
    func handleIntent(_ intent: WorkoutIntent) {
        print("Handling intent: \(intent.phrase)")
        // Handle the intent action
    }
}

// MARK: - Workout Data Recorder
@MainActor
class WorkoutDataRecorder: ObservableObject {
    static let shared = WorkoutDataRecorder()
    
    @Published var isRecording = false
    @Published var currentWorkout: WorkoutRecording?
    
    struct WorkoutRecording {
        let id: UUID
        let startTime: Date
        var endTime: Date?
        var dataPoints: [DataPoint]
        let workoutType: String
        
        struct DataPoint {
            let timestamp: Date
            let speed: Double
            let distance: Double
            let heartRate: Int?
            let gpsAccuracy: Double?
        }
        
        init(workoutType: String) {
            self.id = UUID()
            self.startTime = Date()
            self.dataPoints = []
            self.workoutType = workoutType
        }
    }
    
    func startRecording(workoutType: String) {
        currentWorkout = WorkoutRecording(workoutType: workoutType)
        isRecording = true
    }
    
    func addDataPoint(speed: Double, distance: Double, heartRate: Int? = nil, gpsAccuracy: Double? = nil) {
        guard isRecording else { return }
        
        let dataPoint = WorkoutRecording.DataPoint(
            timestamp: Date(),
            speed: speed,
            distance: distance,
            heartRate: heartRate,
            gpsAccuracy: gpsAccuracy
        )
        
        currentWorkout?.dataPoints.append(dataPoint)
    }
    
    func stopRecording() -> WorkoutRecording? {
        guard let workout = currentWorkout else { return nil }
        
        var finalWorkout = workout
        finalWorkout.endTime = Date()
        
        currentWorkout = nil
        isRecording = false
        
        return finalWorkout
    }
}
