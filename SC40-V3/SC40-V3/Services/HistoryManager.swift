import Foundation
import Combine

// MARK: - History Manager
// Real-time session history tracking and analytics updates

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var completedSessions: [CompletedSession] = []
    @Published var analytics: SessionAnalytics = SessionAnalytics()
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "completedSessionHistory"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadHistoryFromStorage()
        setupAnalyticsUpdates()
    }
    
    // MARK: - Session Completion Recording
    
    /// Record a completed session (finished or stopped partway)
    func recordSessionCompletion(
        session: TrainingSession,
        completionType: SessionCompletionType,
        sprintTimes: [Double] = [],
        completedSprints: Int = 0,
        totalSprints: Int = 0,
        notes: String? = nil,
        location: String? = nil,
        weather: String? = nil,
        temperature: Double? = nil
    ) {
        let completedSession = CompletedSession(
            id: UUID(),
            originalSessionId: session.id,
            week: session.week,
            day: session.day,
            sessionType: session.type,
            focus: session.focus,
            completionDate: Date(),
            completionType: completionType,
            sprintTimes: sprintTimes,
            completedSprints: completedSprints,
            totalSprints: totalSprints,
            bestTime: sprintTimes.min(),
            averageTime: sprintTimes.isEmpty ? nil : sprintTimes.reduce(0, +) / Double(sprintTimes.count),
            notes: notes,
            location: location,
            weather: weather,
            temperature: temperature
        )
        
        // Add to history
        completedSessions.append(completedSession)
        
        // Update analytics in real-time
        updateAnalytics()
        
        // Save to storage
        saveHistoryToStorage()
        
        print("📊 HistoryManager: Recorded \(completionType.rawValue) session - \(session.type)")
        print("   Sprint times: \(sprintTimes)")
        print("   Completed: \(completedSprints)/\(totalSprints) sprints")
    }
    
    /// Record session stopped partway through
    func recordPartialSession(
        session: TrainingSession,
        completedSprints: Int,
        totalSprints: Int,
        sprintTimes: [Double],
        stopReason: String,
        notes: String? = nil
    ) {
        recordSessionCompletion(
            session: session,
            completionType: .stoppedPartway,
            sprintTimes: sprintTimes,
            completedSprints: completedSprints,
            totalSprints: totalSprints,
            notes: notes ?? "Stopped: \(stopReason)"
        )
    }
    
    /// Record fully completed session
    func recordFullSession(
        session: TrainingSession,
        sprintTimes: [Double],
        notes: String? = nil,
        location: String? = nil,
        weather: String? = nil
    ) {
        recordSessionCompletion(
            session: session,
            completionType: .completed,
            sprintTimes: sprintTimes,
            completedSprints: sprintTimes.count,
            totalSprints: session.sprints.reduce(0) { $0 + $1.reps },
            notes: notes,
            location: location,
            weather: weather
        )
    }
    
    // MARK: - Analytics Updates
    
    private func setupAnalyticsUpdates() {
        // Update analytics whenever sessions change
        $completedSessions
            .sink { [weak self] _ in
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
    }
    
    private func updateAnalytics() {
        let sessions = completedSessions
        
        analytics = SessionAnalytics(
            totalSessions: sessions.count,
            completedSessions: sessions.filter { $0.completionType == .completed }.count,
            partialSessions: sessions.filter { $0.completionType == .stoppedPartway }.count,
            personalBest: sessions.compactMap { $0.bestTime }.min(),
            averageTime: calculateOverallAverage(sessions),
            totalDistance: calculateTotalDistance(sessions),
            thisWeekSessions: getThisWeekSessions(sessions).count,
            thisMonthSessions: getThisMonthSessions(sessions).count,
            improvementTrend: calculateImprovementTrend(sessions),
            consistencyScore: calculateConsistencyScore(sessions),
            completionRate: calculateCompletionRate(sessions)
        )
        
        print("📈 Analytics updated: \(analytics.totalSessions) sessions, PB: \(analytics.personalBest ?? 0.0)s")
    }
    
    // MARK: - Data Filtering
    
    func getSessionsForFilter(_ filter: HistoryFilter) -> [CompletedSession] {
        let calendar = Calendar.current
        let now = Date()
        
        return completedSessions.filter { session in
            switch filter {
            case .all:
                return true
            case .sprints:
                return session.sessionType != "Time Trial"
            case .timeTrials:
                return session.sessionType == "Time Trial"
            case .thisWeek:
                return calendar.isDate(session.completionDate, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth:
                return calendar.isDate(session.completionDate, equalTo: now, toGranularity: .month)
            case .completed:
                return session.completionType == .completed
            case .partial:
                return session.completionType == .stoppedPartway
            }
        }.sorted { $0.completionDate > $1.completionDate }
    }
    
    func getThisWeekSessions(_ sessions: [CompletedSession]) -> [CompletedSession] {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { calendar.isDate($0.completionDate, equalTo: now, toGranularity: .weekOfYear) }
    }
    
    func getThisMonthSessions(_ sessions: [CompletedSession]) -> [CompletedSession] {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { calendar.isDate($0.completionDate, equalTo: now, toGranularity: .month) }
    }
    
    // MARK: - Analytics Calculations
    
    private func calculateOverallAverage(_ sessions: [CompletedSession]) -> Double? {
        let allTimes = sessions.compactMap { $0.averageTime }
        guard !allTimes.isEmpty else { return nil }
        return allTimes.reduce(0, +) / Double(allTimes.count)
    }
    
    private func calculateTotalDistance(_ sessions: [CompletedSession]) -> Double {
        return sessions.reduce(0) { total, session in
            total + Double(session.completedSprints * 40) // Assuming 40-yard sprints
        }
    }
    
    private func calculateImprovementTrend(_ sessions: [CompletedSession]) -> Double {
        let recentSessions = sessions.suffix(10).compactMap { $0.bestTime }
        guard recentSessions.count >= 2 else { return 0.0 }
        
        let firstHalf = recentSessions.prefix(recentSessions.count / 2)
        let secondHalf = recentSessions.suffix(recentSessions.count / 2)
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        return firstAvg - secondAvg // Positive = improvement (lower times)
    }
    
    private func calculateConsistencyScore(_ sessions: [CompletedSession]) -> Double {
        let times = sessions.compactMap { $0.averageTime }
        guard times.count >= 3 else { return 0.0 }
        
        let mean = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - mean, 2) }.reduce(0, +) / Double(times.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = higher consistency (scale 0-1)
        return max(0, 1 - (standardDeviation / mean))
    }
    
    private func calculateCompletionRate(_ sessions: [CompletedSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        let completedCount = sessions.filter { $0.completionType == .completed }.count
        return Double(completedCount) / Double(sessions.count)
    }
    
    // MARK: - Data Persistence
    
    private func saveHistoryToStorage() {
        do {
            let data = try JSONEncoder().encode(completedSessions)
            userDefaults.set(data, forKey: historyKey)
            print("💾 Saved \(completedSessions.count) sessions to storage")
        } catch {
            print("❌ Failed to save history: \(error)")
        }
    }
    
    private func loadHistoryFromStorage() {
        guard let data = userDefaults.data(forKey: historyKey) else {
            print("📊 No existing history found")
            return
        }
        
        do {
            completedSessions = try JSONDecoder().decode([CompletedSession].self, from: data)
            updateAnalytics()
            print("📊 Loaded \(completedSessions.count) sessions from storage")
        } catch {
            print("❌ Failed to load history: \(error)")
            completedSessions = []
        }
    }
    
    // MARK: - Testing & Debug
    
    func clearHistory() {
        completedSessions.removeAll()
        userDefaults.removeObject(forKey: historyKey)
        updateAnalytics()
        print("🗑️ Cleared all session history")
    }
    
    func addTestSession() {
        let testSession = TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Sprint Training",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "Max")],
            accessoryWork: ["Warm-up", "Cool-down"],
            notes: "Test session"
        )
        
        recordFullSession(
            session: testSession,
            sprintTimes: [4.85, 4.92, 4.88],
            notes: "Test session for development",
            location: "Test Track",
            weather: "Clear"
        )
    }
    
    func addTestPartialSession() {
        let testSession = TrainingSession(
            id: UUID(),
            week: 1,
            day: 2,
            type: "Sprint Training",
            focus: "Max Velocity",
            sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "Max")],
            accessoryWork: ["Warm-up", "Cool-down"],
            notes: "Test partial session"
        )
        
        recordPartialSession(
            session: testSession,
            completedSprints: 3,
            totalSprints: 5,
            sprintTimes: [4.92, 4.88, 4.95],
            stopReason: "Fatigue",
            notes: "Stopped due to fatigue after 3 sprints"
        )
    }
}

// MARK: - Supporting Models

struct CompletedSession: Codable, Identifiable {
    let id: UUID
    let originalSessionId: UUID
    let week: Int
    let day: Int
    let sessionType: String
    let focus: String
    let completionDate: Date
    let completionType: SessionCompletionType
    let sprintTimes: [Double]
    let completedSprints: Int
    let totalSprints: Int
    let bestTime: Double?
    let averageTime: Double?
    let notes: String?
    let location: String?
    let weather: String?
    let temperature: Double?
}

enum SessionCompletionType: String, Codable, CaseIterable {
    case completed = "Completed"
    case stoppedPartway = "Stopped Partway"
}

struct SessionAnalytics: Codable {
    let totalSessions: Int
    let completedSessions: Int
    let partialSessions: Int
    let personalBest: Double?
    let averageTime: Double?
    let totalDistance: Double
    let thisWeekSessions: Int
    let thisMonthSessions: Int
    let improvementTrend: Double
    let consistencyScore: Double
    let completionRate: Double
    
    init() {
        self.totalSessions = 0
        self.completedSessions = 0
        self.partialSessions = 0
        self.personalBest = nil
        self.averageTime = nil
        self.totalDistance = 0
        self.thisWeekSessions = 0
        self.thisMonthSessions = 0
        self.improvementTrend = 0
        self.consistencyScore = 0
        self.completionRate = 0
    }
    
    init(totalSessions: Int, completedSessions: Int, partialSessions: Int, personalBest: Double?, averageTime: Double?, totalDistance: Double, thisWeekSessions: Int, thisMonthSessions: Int, improvementTrend: Double, consistencyScore: Double, completionRate: Double) {
        self.totalSessions = totalSessions
        self.completedSessions = completedSessions
        self.partialSessions = partialSessions
        self.personalBest = personalBest
        self.averageTime = averageTime
        self.totalDistance = totalDistance
        self.thisWeekSessions = thisWeekSessions
        self.thisMonthSessions = thisMonthSessions
        self.improvementTrend = improvementTrend
        self.consistencyScore = consistencyScore
        self.completionRate = completionRate
    }
}

enum HistoryFilter: String, CaseIterable {
    case all = "All Sessions"
    case sprints = "Sprint Training"
    case timeTrials = "Time Trials"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case completed = "Completed"
    case partial = "Partial"
}
