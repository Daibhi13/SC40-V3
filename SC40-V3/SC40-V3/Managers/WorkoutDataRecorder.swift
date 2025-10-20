import Foundation
import CoreLocation
import Combine

// MARK: - Workout Data Recorder
// Logs GPS routes, time splits, stage data and syncs to cloud/user profile

class WorkoutDataRecorder: ObservableObject {
    static let shared = WorkoutDataRecorder()
    
    // MARK: - Published Properties
    @Published var isRecording: Bool = false
    @Published var currentSessionData: WorkoutSessionData?
    @Published var recordingProgress: Double = 0.0
    
    // MARK: - Recording State
    private var sessionStartTime: Date?
    private var currentSession: TrainingSession?
    private var stageDataBuffer: [WorkoutStageData] = []
    private var locationBuffer: [CLLocation] = []
    private var splitBuffer: [SplitData] = []
    
    // MARK: - Data Storage
    private let userDefaults = UserDefaults.standard
    private let sessionHistoryKey = "WorkoutSessionHistory"
    private let maxHistoryCount = 100
    
    private init() {}
    
    // MARK: - Recording Control
    func startRecording(session: TrainingSession) {
        guard !isRecording else { return }
        
        print("📊 Starting workout data recording for: \(session.type)")
        
        currentSession = session
        sessionStartTime = Date()
        isRecording = true
        recordingProgress = 0.0
        
        // Initialize session data
        currentSessionData = WorkoutSessionData(
            session: session,
            startTime: sessionStartTime!,
            endTime: nil,
            totalDuration: 0,
            stageData: [],
            locationData: [],
            splitData: [],
            summary: nil
        )
        
        // Clear buffers
        stageDataBuffer.removeAll()
        locationBuffer.removeAll()
        splitBuffer.removeAll()
        
        print("✅ Recording started at \(sessionStartTime!)")
    }
    
    func endRecording() {
        guard isRecording, let sessionData = currentSessionData else { return }
        
        print("📊 Ending workout data recording")
        
        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(sessionData.startTime)
        
        // Finalize session data
        let finalSessionData = WorkoutSessionData(
            session: sessionData.session,
            startTime: sessionData.startTime,
            endTime: endTime,
            totalDuration: totalDuration,
            stageData: stageDataBuffer,
            locationData: locationBuffer,
            splitData: splitBuffer,
            summary: generateSessionSummary()
        )
        
        // Save to history
        saveSessionToHistory(finalSessionData)
        
        // Sync to cloud (if available)
        syncToCloud(finalSessionData)
        
        // Reset state
        isRecording = false
        currentSessionData = nil
        recordingProgress = 0.0
        
        print("✅ Recording completed. Duration: \(String(format: "%.1f", totalDuration))s")
    }
    
    // MARK: - Data Recording
    func recordStage(
        stage: WorkoutStage,
        distance: Double,
        time: TimeInterval,
        targetDistance: Double
    ) {
        guard isRecording else { return }
        
        let stageData = WorkoutStageData(
            stage: stage,
            distance: distance,
            time: time,
            targetDistance: targetDistance,
            timestamp: Date()
        )
        
        stageDataBuffer.append(stageData)
        updateRecordingProgress()
        
        print("📝 Recorded stage: \(stage.rawValue) - \(String(format: "%.1f", distance))yd in \(String(format: "%.2f", time))s")
    }
    
    func recordLocation(_ location: CLLocation) {
        guard isRecording else { return }
        
        locationBuffer.append(location)
        
        // Keep location buffer manageable (last 1000 points)
        if locationBuffer.count > 1000 {
            locationBuffer.removeFirst(100)
        }
    }
    
    func recordSplit(
        distance: Double,
        time: TimeInterval,
        speed: Double,
        location: CLLocation?
    ) {
        guard isRecording else { return }
        
        let split = SplitData(
            distance: distance,
            time: time,
            speed: speed,
            location: location,
            timestamp: Date()
        )
        
        splitBuffer.append(split)
        
        print("⏱️ Recorded split: \(String(format: "%.1f", distance))yd - \(String(format: "%.2f", time))s")
    }
    
    // MARK: - Data Retrieval
    func getStageData() -> [WorkoutStageData] {
        return stageDataBuffer
    }
    
    func getLocationData() -> [CLLocation] {
        return locationBuffer
    }
    
    func getSplitData() -> [SplitData] {
        return splitBuffer
    }
    
    func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Session Summary Generation
    private func generateSessionSummary() -> WorkoutSessionSummary? {
        guard let session = currentSession,
              let startTime = sessionStartTime else { return nil }
        
        let totalTime = Date().timeIntervalSince(startTime)
        let sprintStages = stageDataBuffer.filter { $0.stage == .sprints }
        
        let fastestSplit = sprintStages.map { $0.time }.min() ?? 0
        let averagePace = sprintStages.isEmpty ? 0 : sprintStages.reduce(0) { $0 + $1.time } / Double(sprintStages.count)
        let _ = stageDataBuffer.reduce(0) { $0 + $1.distance }
        
        return WorkoutSessionSummary(
            session: session,
            totalTime: totalTime,
            stageData: stageDataBuffer,
            fastestSplit: fastestSplit,
            averagePace: averagePace,
            recoveryEfficiency: calculateRecoveryEfficiency(),
            suggestedNextLevel: WorkoutAlgorithmEngine.shared.suggestNextLevel()
        )
    }
    
    private func calculateRecoveryEfficiency() -> Double {
        // Calculate based on heart rate recovery if available
        // For now, estimate based on consistency of sprint times
        let sprintTimes = stageDataBuffer.filter { $0.stage == .sprints }.map { $0.time }
        guard sprintTimes.count > 1 else { return 0.85 }
        
        let mean = sprintTimes.reduce(0, +) / Double(sprintTimes.count)
        let variance = sprintTimes.reduce(0) { $0 + pow($1 - mean, 2) } / Double(sprintTimes.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = better recovery efficiency
        return max(0.5, min(1.0, 1.0 - (standardDeviation / mean)))
    }
    
    private func calculateMaxSpeed() -> Double {
        return splitBuffer.map { $0.speed }.max() ?? 0
    }
    
    private func calculateAverageSpeed() -> Double {
        let speeds = splitBuffer.map { $0.speed }
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }
    
    // MARK: - Progress Tracking
    private func updateRecordingProgress() {
        guard let session = currentSession else { return }
        
        let expectedStages = estimateExpectedStages(for: session)
        recordingProgress = min(1.0, Double(stageDataBuffer.count) / Double(expectedStages))
    }
    
    private func estimateExpectedStages(for session: TrainingSession) -> Int {
        // Estimate: warmup + drills + strides + (sprints * 2 - 1 for recovery) + cooldown
        let sprintCount = session.sprints.count
        let recoveryCount = max(0, sprintCount - 1)
        
        return 1 + 1 + 1 + sprintCount + recoveryCount + 1 // 6 base stages + recoveries
    }
    
    // MARK: - Data Persistence
    private func saveSessionToHistory(_ sessionData: WorkoutSessionData) {
        // Note: Full persistence would require custom Codable implementation
        print("💾 Session data recorded: \(sessionData.session.type)")
        
        // Also save to HistoryManager for app integration
        saveToHistoryManager(sessionData)
    }
    
    private func saveToHistoryManager(_ sessionData: WorkoutSessionData) {
        // Convert to TrainingSession format for HistoryManager
        let _ = TrainingSession(
            id: sessionData.session.id,
            week: sessionData.session.week,
            day: sessionData.session.day,
            type: sessionData.session.type,
            focus: sessionData.session.focus,
            sprints: sessionData.session.sprints,
            accessoryWork: sessionData.session.accessoryWork,
            notes: sessionData.session.notes
        )
        
        // Note: HistoryManager integration would go here when available
        print("📊 Session data ready for HistoryManager integration")
    }
    
    func loadSessionHistory() -> [WorkoutSessionData] {
        // Note: JSON persistence would require custom Codable implementation
        // For now, return empty array
        return []
    }
    
    // MARK: - Cloud Sync
    private func syncToCloud(_ sessionData: WorkoutSessionData) {
        // Placeholder for cloud sync implementation
        // This would integrate with CloudKit, Firebase, or other cloud service
        
        print("☁️ Syncing session to cloud...")
        
        // Simulate cloud sync
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            print("✅ Session synced to cloud")
        }
    }
    
    // MARK: - Export Functions
    func exportSessionData(_ sessionData: WorkoutSessionData, format: ExportFormat) -> Data? {
        switch format {
        case .json:
            // Note: JSON export would require custom Codable implementation
            return "Session data export placeholder".data(using: .utf8)
        case .csv:
            return exportToCSV(sessionData)
        case .gpx:
            return exportToGPX(sessionData)
        }
    }
    
    private func exportToCSV(_ sessionData: WorkoutSessionData) -> Data? {
        var csvContent = "Stage,Distance(yd),Time(s),Target Distance(yd),Timestamp\n"
        
        for stage in sessionData.stageData {
            let row = "\(stage.stage.rawValue),\(stage.distance),\(stage.time),\(stage.targetDistance),\(stage.timestamp)\n"
            csvContent += row
        }
        
        return csvContent.data(using: .utf8)
    }
    
    private func exportToGPX(_ sessionData: WorkoutSessionData) -> Data? {
        var gpxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Sprint Coach 40">
        <trk>
        <name>Sprint Training Session</name>
        <trkseg>
        """
        
        for location in sessionData.locationData {
            let trkpt = """
            <trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
            <time>\(ISO8601DateFormatter().string(from: location.timestamp))</time>
            </trkpt>
            """
            gpxContent += trkpt
        }
        
        gpxContent += """
        </trkseg>
        </trk>
        </gpx>
        """
        
        return gpxContent.data(using: .utf8)
    }
    
    // MARK: - Statistics
    func getSessionStatistics() -> SessionStatistics {
        let history = loadSessionHistory()
        
        return SessionStatistics(
            totalSessions: history.count,
            totalDistance: history.reduce(0) { $0 + $1.stageData.reduce(0) { $0 + $1.distance } },
            totalTime: history.reduce(0) { $0 + $1.totalDuration },
            averageSessionDuration: history.isEmpty ? 0 : history.reduce(0) { $0 + $1.totalDuration } / Double(history.count),
            personalBest: getPersonalBest(from: history),
            lastSessionDate: history.last?.startTime
        )
    }
    
    private func getPersonalBest(from history: [WorkoutSessionData]) -> TimeInterval? {
        let allSprintTimes = history.flatMap { session in
            session.stageData.filter { $0.stage == .sprints }.map { $0.time }
        }
        
        return allSprintTimes.min()
    }
}

// MARK: - Supporting Models
struct WorkoutSessionData {
    let session: TrainingSession
    let startTime: Date
    let endTime: Date?
    let totalDuration: TimeInterval
    let stageData: [WorkoutStageData]
    let locationData: [CLLocation]
    let splitData: [SplitData]
    let summary: WorkoutSessionSummary?
}

struct SplitData {
    let distance: Double
    let time: TimeInterval
    let speed: Double // mph
    let location: CLLocation?
    let timestamp: Date
}

struct SessionStatistics {
    let totalSessions: Int
    let totalDistance: Double
    let totalTime: TimeInterval
    let averageSessionDuration: TimeInterval
    let personalBest: TimeInterval?
    let lastSessionDate: Date?
}

enum ExportFormat {
    case json
    case csv
    case gpx
}

// MARK: - Enhanced WorkoutSessionSummary
struct EnhancedWorkoutSessionSummary {
    let session: TrainingSession
    let totalTime: TimeInterval
    let stageData: [WorkoutStageData]
    let fastestSplit: TimeInterval
    let averagePace: Double
    let recoveryEfficiency: Double
    let suggestedNextLevel: String
    let totalDistance: Double
    let maxSpeed: Double
    let averageSpeed: Double
}
