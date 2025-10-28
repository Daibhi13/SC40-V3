import Foundation
import Combine
import WatchConnectivity

// MARK: - Live Rep Log Manager for iPhone
// Receives and manages rep data from Apple Watch in real-time

@MainActor
class LiveRepLogManager: NSObject, ObservableObject {
    static let shared = LiveRepLogManager()
    
    // MARK: - Published Properties
    @Published var currentSession: LiveSession?
    @Published var liveReps: [LiveRep] = []
    @Published var isReceivingData = false
    @Published var lastRepReceived: Date?
    @Published var sessionStats = SessionStats()
    
    // Real-time metrics
    @Published var currentRep: Int = 0
    @Published var averageTime: TimeInterval = 0.0
    @Published var bestTime: TimeInterval = 0.0
    @Published var lastRepTime: TimeInterval = 0.0
    @Published var totalDistance: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Watch Connectivity Setup
    
    private func setupWatchConnectivity() {
        // Listen for rep data from Watch
        NotificationCenter.default.publisher(for: .repDataReceived)
            .sink { [weak self] notification in
                if let repData = notification.object as? [String: Any] {
                    self?.handleRepDataFromWatch(repData)
                }
            }
            .store(in: &cancellables)
        
        // Listen for session data from Watch
        NotificationCenter.default.publisher(for: .sessionDataReceived)
            .sink { [weak self] notification in
                if let sessionData = notification.object as? [String: Any] {
                    self?.handleSessionDataFromWatch(sessionData)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Session Management
    
    func startLiveSession(type: String, focus: String, week: Int, day: Int) {
        currentSession = LiveSession(
            id: UUID(),
            type: type,
            focus: focus,
            week: week,
            day: day,
            startTime: Date()
        )
        
        // Reset all data
        liveReps.removeAll()
        currentRep = 0
        sessionStats = SessionStats()
        isReceivingData = true
        
        print("📊 LiveRepLog: Started session - \(type): \(focus)")
    }
    
    func endLiveSession() -> LiveSession? {
        guard var session = currentSession else { return nil }
        
        session.endTime = Date()
        session.reps = liveReps
        session.stats = sessionStats
        
        // Save to history
        saveSessionToHistory(session)
        
        // Reset state
        currentSession = nil
        isReceivingData = false
        
        print("📊 LiveRepLog: Ended session - Total reps: \(liveReps.count)")
        
        return session
    }
    
    // MARK: - Watch Data Handling
    
    private func handleRepDataFromWatch(_ data: [String: Any]) {
        guard let repNumber = data["repNumber"] as? Int,
              let distance = data["distance"] as? Double,
              let time = data["time"] as? TimeInterval,
              let timestamp = data["timestamp"] as? TimeInterval else {
            print("❌ LiveRepLog: Invalid rep data received")
            return
        }
        
        let rep = LiveRep(
            id: UUID(),
            repNumber: repNumber,
            distance: distance,
            time: time,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
        
        // Add to live reps
        liveReps.append(rep)
        
        // Update metrics
        currentRep = repNumber
        lastRepTime = time
        lastRepReceived = Date()
        totalDistance += distance
        
        updateSessionStats()
        
        print("📊 LiveRepLog: Received rep \(repNumber) - \(String(format: "%.2f", time))s")
    }
    
    private func handleSessionDataFromWatch(_ data: [String: Any]) {
        guard let sessionType = data["sessionType"] as? String,
              let focus = data["focus"] as? String,
              let week = data["week"] as? Int,
              let day = data["day"] as? Int else {
            print("❌ LiveRepLog: Invalid session data received")
            return
        }
        
        // Update current session with final data
        if var session = currentSession {
            session.totalTime = data["totalTime"] as? TimeInterval ?? 0.0
            session.averageTime = data["averageTime"] as? TimeInterval ?? 0.0
            session.bestTime = data["bestTime"] as? TimeInterval ?? 0.0
            
            currentSession = session
        }
        
        print("📊 LiveRepLog: Received complete session data")
    }
    
    // MARK: - Statistics Updates
    
    private func updateSessionStats() {
        guard !liveReps.isEmpty else { return }
        
        let times = liveReps.map { $0.time }
        
        sessionStats.totalReps = liveReps.count
        sessionStats.averageTime = times.reduce(0, +) / Double(times.count)
        sessionStats.bestTime = times.min() ?? 0.0
        sessionStats.worstTime = times.max() ?? 0.0
        sessionStats.totalDistance = liveReps.reduce(0) { $0 + $1.distance }
        
        // Update published properties
        averageTime = sessionStats.averageTime
        bestTime = sessionStats.bestTime
        
        // Calculate consistency (standard deviation)
        if times.count > 1 {
            let mean = sessionStats.averageTime
            let variance = times.map { pow($0 - mean, 2) }.reduce(0, +) / Double(times.count)
            sessionStats.consistency = sqrt(variance)
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveSessionToHistory(_ session: LiveSession) {
        // Save to UserDefaults or integrate with HistoryManager
        var savedSessions = loadSessionHistory()
        savedSessions.append(session)
        
        // Keep only last 50 sessions
        if savedSessions.count > 50 {
            savedSessions = Array(savedSessions.suffix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(encoded, forKey: "liveRepLogHistory")
        }
        
        // Also integrate with existing HistoryManager if available
        integrateWithHistoryManager(session)
    }
    
    private func loadSessionHistory() -> [LiveSession] {
        guard let data = UserDefaults.standard.data(forKey: "liveRepLogHistory"),
              let sessions = try? JSONDecoder().decode([LiveSession].self, from: data) else {
            return []
        }
        
        return sessions
    }
    
    private func integrateWithHistoryManager(_ session: LiveSession) {
        // Convert to format compatible with existing HistoryManager
        // This would integrate with the existing history system
        print("📊 LiveRepLog: Integrated session with HistoryManager")
    }
    
    // MARK: - Real-time Analysis
    
    func getRepTrend() -> RepTrend {
        guard liveReps.count >= 3 else { return .stable }
        
        let recentReps = Array(liveReps.suffix(3))
        let times = recentReps.map { $0.time }
        
        let firstTime = times.first!
        let lastTime = times.last!
        
        let improvement = (firstTime - lastTime) / firstTime
        
        if improvement > 0.02 { // 2% improvement
            return .improving
        } else if improvement < -0.02 { // 2% decline
            return .declining
        } else {
            return .stable
        }
    }
    
    func getPaceAnalysis() -> PaceAnalysis {
        guard !liveReps.isEmpty else {
            return PaceAnalysis(currentPace: 0, targetPace: 0, variance: 0)
        }
        
        let currentPace = liveReps.last?.time ?? 0.0
        let targetPace = averageTime
        let variance = abs(currentPace - targetPace) / targetPace
        
        return PaceAnalysis(
            currentPace: currentPace,
            targetPace: targetPace,
            variance: variance
        )
    }
}

// MARK: - Supporting Data Models

struct LiveSession: Codable, Identifiable {
    let id: UUID
    let type: String
    let focus: String
    let week: Int
    let day: Int
    let startTime: Date
    var endTime: Date?
    var reps: [LiveRep] = []
    var stats: SessionStats = SessionStats()
    var totalTime: TimeInterval = 0.0
    var averageTime: TimeInterval = 0.0
    var bestTime: TimeInterval = 0.0
}

struct LiveRep: Codable, Identifiable {
    let id: UUID
    let repNumber: Int
    let distance: Double
    let time: TimeInterval
    let timestamp: Date
}

struct SessionStats: Codable {
    var totalReps: Int = 0
    var averageTime: TimeInterval = 0.0
    var bestTime: TimeInterval = 0.0
    var worstTime: TimeInterval = 0.0
    var totalDistance: Double = 0.0
    var consistency: TimeInterval = 0.0 // Standard deviation
}

enum RepTrend {
    case improving
    case declining
    case stable
}

struct PaceAnalysis {
    let currentPace: TimeInterval
    let targetPace: TimeInterval
    let variance: Double // Percentage variance from target
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let repDataReceived = Notification.Name("repDataReceived")
    static let sessionDataReceived = Notification.Name("sessionDataReceived")
}
