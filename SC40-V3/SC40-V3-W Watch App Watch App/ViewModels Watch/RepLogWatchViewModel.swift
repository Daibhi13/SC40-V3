import Foundation
import Combine
import CoreLocation

/// Updates rep performance live.
@MainActor
class RepLogWatchViewModel: ObservableObject {
    @Published var reps: [RepLogWatch] = []
    @Published var currentRep: Int = 1
    @Published var isRecording = false
    @Published var currentDistance: Double = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var sessionStartTime: Date?
    @Published var lastRepTime: TimeInterval = 0.0
    @Published var averageTime: TimeInterval = 0.0
    @Published var bestTime: TimeInterval = 0.0
    
    // Session data
    @Published var sessionData: SessionData?
    
    private var repStartTime: Date?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // GPS and location tracking
    @Published var currentLocation: CLLocation?
    @Published var repStartLocation: CLLocation?
    
    init() {
        setupLiveTracking()
    }
    
    // MARK: - Live Tracking Setup
    
    private func setupLiveTracking() {
        // Start live updates timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.updateLiveMetrics()
            }
        }
    }
    
    // MARK: - Rep Management
    
    func startRep(distance: Double, location: CLLocation? = nil) {
        repStartTime = Date()
        repStartLocation = location
        currentDistance = 0.0
        currentTime = 0.0
        isRecording = true
        
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        
        print("📊 RepLog: Started rep \(currentRep) - Distance: \(distance)yd")
    }
    
    func completeRep(finalDistance: Double, finalLocation: CLLocation? = nil) {
        guard let startTime = repStartTime else { return }
        
        let endTime = Date()
        let repTime = endTime.timeIntervalSince(startTime)
        
        // Create rep log entry
        let repLog = RepLogWatch(
            repNumber: currentRep,
            distance: finalDistance,
            gpsTime: endTime,
            splitTime: repTime
        )
        
        // Add to reps array
        reps.append(repLog)
        
        // Update metrics
        lastRepTime = repTime
        updateAverageTime()
        updateBestTime()
        
        // Move to next rep
        currentRep += 1
        isRecording = false
        repStartTime = nil
        
        // Sync to phone
        syncRepToPhone(repLog)
        
        print("📊 RepLog: Completed rep \(repLog.repNumber) - Time: \(String(format: "%.2f", repTime))s")
    }
    
    func updateDistance(_ distance: Double, location: CLLocation? = nil) {
        currentDistance = distance
        currentLocation = location
        
        if let startTime = repStartTime {
            currentTime = Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Live Metrics Updates
    
    private func updateLiveMetrics() {
        guard isRecording, let startTime = repStartTime else { return }
        
        currentTime = Date().timeIntervalSince(startTime)
        
        // Update UI
        objectWillChange.send()
    }
    
    private func updateAverageTime() {
        guard !reps.isEmpty else { return }
        
        let totalTime = reps.reduce(0.0) { $0 + $1.splitTime }
        averageTime = totalTime / Double(reps.count)
    }
    
    private func updateBestTime() {
        guard !reps.isEmpty else { return }
        
        bestTime = reps.map { $0.splitTime }.min() ?? 0.0
    }
    
    // MARK: - Session Data Management
    
    func startSession(type: String, focus: String, week: Int, day: Int) {
        sessionData = SessionData(
            id: UUID(),
            type: type,
            focus: focus,
            week: week,
            day: day,
            startTime: Date(),
            reps: []
        )
        
        sessionStartTime = Date()
        currentRep = 1
        reps.removeAll()
        
        print("📊 RepLog: Started session - \(type): \(focus)")
    }
    
    func endSession() -> SessionData? {
        guard var session = sessionData else { return nil }
        
        session.endTime = Date()
        session.reps = reps
        session.totalTime = session.endTime?.timeIntervalSince(session.startTime) ?? 0.0
        session.averageTime = averageTime
        session.bestTime = bestTime
        
        // Save session data
        saveSessionData(session)
        
        print("📊 RepLog: Ended session - Total reps: \(reps.count)")
        
        return session
    }
    
    // MARK: - Data Persistence
    
    private func saveSessionData(_ session: SessionData) {
        // Save to UserDefaults or Core Data
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: "lastRepLogSession")
        }
    }
    
    func loadLastSession() -> SessionData? {
        guard let data = UserDefaults.standard.data(forKey: "lastRepLogSession"),
              let session = try? JSONDecoder().decode(SessionData.self, from: data) else {
            return nil
        }
        
        return session
    }
    
    // MARK: - Phone Sync
    
    private func syncRepToPhone(_ rep: RepLogWatch) {
        // Send rep data to iPhone via WatchConnectivity
        #if canImport(WatchConnectivity)
        let repData: [String: Any] = [
            "type": "rep_completed",
            "repNumber": rep.repNumber,
            "distance": rep.distance,
            "time": rep.splitTime,
            "timestamp": rep.gpsTime.timeIntervalSince1970
        ]
        
        // Use existing sync manager to send data
        WatchWorkoutSyncManager.shared.sendRepDataToPhone(repData)
        #endif
    }
    
    // MARK: - Cleanup
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Supporting Data Models

struct SessionData: Codable, Identifiable {
    let id: UUID
    let type: String
    let focus: String
    let week: Int
    let day: Int
    let startTime: Date
    var endTime: Date?
    var reps: [RepLogWatch]
    var totalTime: TimeInterval = 0.0
    var averageTime: TimeInterval = 0.0
    var bestTime: TimeInterval = 0.0
}
