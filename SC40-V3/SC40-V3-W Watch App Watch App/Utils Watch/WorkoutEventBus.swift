import Foundation
import Combine

/// Unified event communication system for all SC40 workout components
/// Coordinates between autonomous systems, premium features, and entertainment components
class WorkoutEventBus: ObservableObject {
    static let shared = WorkoutEventBus()
    
    // MARK: - Published Properties
    @Published var currentEvent: WorkoutEvent?
    @Published var eventHistory: [WorkoutEvent] = []
    @Published var isEventProcessing = false
    
    // MARK: - Event Types
    enum WorkoutEvent: Equatable {
        // Workout Lifecycle
        case workoutStarted(TrainingSession)
        case workoutPaused
        case workoutResumed  
        case workoutCompleted(WorkoutSummary)
        case workoutCancelled
        
        // Phase Changes
        case phaseChanged(WorkoutPhase, previousPhase: WorkoutPhase?)
        case countdownStarted(seconds: Int)
        case sprintStarted(setNumber: Int)
        case restPeriodStarted(duration: TimeInterval)
        case cooldownStarted
        
        // Performance Milestones
        case speedMilestone(speed: Double, milestone: SpeedMilestone)
        case personalRecord(category: String, value: Double, previous: Double)
        case heartRateZoneChanged(zone: HeartRateZone, previous: HeartRateZone?)
        case distanceCompleted(distance: Double, time: TimeInterval)
        
        // System Events
        case gpsSignalAcquired(accuracy: Double)
        case gpsSignalLost
        case healthKitConnected
        case healthKitDisconnected
        case batteryLow(percentage: Float)
        
        // User Interactions
        case userTappedScreen
        case userSwipedLeft
        case userSwipedRight
        case userPressedCrown
        
        // Premium Feature Events
        case musicPhaseSync(phase: WorkoutPhase)
        case voiceCoachingTriggered(message: String, context: CoachingContext)
        case hapticPatternTriggered(pattern: HapticPattern)
        case achievementUnlocked(achievement: Achievement)
        
        // Error Events
        case systemError(component: String, error: Error)
        case permissionDenied(permission: String)
        case syncFailed(reason: String)
        
        static func == (lhs: WorkoutEvent, rhs: WorkoutEvent) -> Bool {
            switch (lhs, rhs) {
            case (.workoutStarted, .workoutStarted),
                 (.workoutPaused, .workoutPaused),
                 (.workoutResumed, .workoutResumed),
                 (.workoutCancelled, .workoutCancelled):
                return true
            case (.phaseChanged(let lPhase, _), .phaseChanged(let rPhase, _)):
                return lPhase == rPhase
            case (.speedMilestone(let lSpeed, _), .speedMilestone(let rSpeed, _)):
                return lSpeed == rSpeed
            default:
                return false
            }
        }
    }
    
    enum WorkoutPhase: String, Codable, CaseIterable {
        case preparation = "Preparation"
        case warmup = "Warmup"
        case countdown = "Countdown"
        case sprint = "Sprint"
        case rest = "Rest"
        case cooldown = "Cooldown"
        case complete = "Complete"
        
        var duration: TimeInterval? {
            switch self {
            case .preparation: return nil
            case .warmup: return 300 // 5 minutes
            case .countdown: return 3
            case .sprint: return nil // Variable
            case .rest: return 120 // 2 minutes
            case .cooldown: return 300 // 5 minutes
            case .complete: return nil
            }
        }
    }
    
    enum SpeedMilestone: String, CaseIterable {
        case mph15 = "15 MPH"
        case mph18 = "18 MPH" 
        case mph20 = "20 MPH"
        case mph22 = "22 MPH"
        case mph25 = "25 MPH"
        
        var speed: Double {
            switch self {
            case .mph15: return 15.0
            case .mph18: return 18.0
            case .mph20: return 20.0
            case .mph22: return 22.0
            case .mph25: return 25.0
            }
        }
    }
    
    enum HeartRateZone: Int, CaseIterable {
        case zone1 = 1 // Recovery (50-60% max HR)
        case zone2 = 2 // Aerobic (60-70% max HR)
        case zone3 = 3 // Threshold (70-80% max HR)
        case zone4 = 4 // VO2 Max (80-90% max HR)
        case zone5 = 5 // Neuromuscular (90-100% max HR)
        
        var name: String {
            switch self {
            case .zone1: return "Recovery"
            case .zone2: return "Aerobic"
            case .zone3: return "Threshold"
            case .zone4: return "VO2 Max"
            case .zone5: return "Neuromuscular"
            }
        }
        
        var color: String {
            switch self {
            case .zone1: return "gray"
            case .zone2: return "blue"
            case .zone3: return "green"
            case .zone4: return "orange"
            case .zone5: return "red"
            }
        }
    }
    
    enum CoachingContext: String {
        case motivation, technique, performance, recovery, achievement, warning
    }
    
    enum HapticPattern: String {
        case countdown, sprint, milestone, achievement, warning, recovery
    }
    
    struct Achievement {
        let id: String
        let name: String
        let description: String
        let category: String
        let value: Double
    }
    
    struct WorkoutSummary {
        let sessionId: UUID
        let duration: TimeInterval
        let totalSprints: Int
        let maxSpeed: Double
        let averageHeartRate: Int
        let caloriesBurned: Int
        let personalRecords: [String]
    }
    
    // MARK: - Private Properties
    private var eventSubscribers: [String: [(WorkoutEvent) -> Void]] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let eventQueue = DispatchQueue(label: "workout.events", qos: .userInitiated)
    
    private init() {
        setupEventLogging()
    }
    
    // MARK: - Event Broadcasting
    
    func broadcast(_ event: WorkoutEvent) {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isEventProcessing = true
                self.currentEvent = event
                self.eventHistory.append(event)
                
                // Keep only last 100 events to prevent memory issues
                if self.eventHistory.count > 100 {
                    self.eventHistory.removeFirst()
                }
                
                print("🎯 WorkoutEvent: \(event)")
            }
            
            // Notify all subscribers
            self.notifySubscribers(event)
            
            // Send system notification for legacy components
            NotificationCenter.default.post(
                name: NSNotification.Name("WorkoutEvent"),
                object: event
            )
            
            DispatchQueue.main.async {
                self.isEventProcessing = false
            }
        }
    }
    
    // MARK: - Event Subscription
    
    func subscribe(_ subscriberId: String, handler: @escaping (WorkoutEvent) -> Void) {
        eventQueue.async { [weak self] in
            if self?.eventSubscribers[subscriberId] == nil {
                self?.eventSubscribers[subscriberId] = []
            }
            self?.eventSubscribers[subscriberId]?.append(handler)
            
            print("📡 Subscriber registered: \(subscriberId)")
        }
    }
    
    func unsubscribe(_ subscriberId: String) {
        eventQueue.async { [weak self] in
            self?.eventSubscribers.removeValue(forKey: subscriberId)
            print("📡 Subscriber removed: \(subscriberId)")
        }
    }
    
    // MARK: - Event Processing
    
    private func notifySubscribers(_ event: WorkoutEvent) {
        for (_, handlers) in eventSubscribers {
            for handler in handlers {
                handler(event)
            }
        }
    }
    
    private func setupEventLogging() {
        // Log critical events for debugging
        subscribe("EventLogger") { event in
            switch event {
            case .workoutStarted(let session):
                print("🏃‍♂️ Workout Started: \(session.type)")
            case .personalRecord(let category, let value, let previous):
                print("🏆 Personal Record: \(category) - \(value) (was \(previous))")
            case .systemError(let component, let error):
                print("❌ System Error in \(component): \(error.localizedDescription)")
            default:
                break
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func broadcastPhaseChange(to newPhase: WorkoutPhase, from previousPhase: WorkoutPhase? = nil) {
        broadcast(.phaseChanged(newPhase, previousPhase: previousPhase))
    }
    
    func broadcastSpeedMilestone(_ speed: Double) {
        for milestone in SpeedMilestone.allCases {
            if speed >= milestone.speed && speed < milestone.speed + 1.0 {
                broadcast(.speedMilestone(speed: speed, milestone: milestone))
                break
            }
        }
    }
    
    func broadcastPersonalRecord(category: String, newValue: Double, previousValue: Double) {
        broadcast(.personalRecord(category: category, value: newValue, previous: previousValue))
    }
    
    func broadcastHeartRateZoneChange(to newZone: HeartRateZone, from previousZone: HeartRateZone? = nil) {
        broadcast(.heartRateZoneChanged(zone: newZone, previous: previousZone))
    }
    
    func broadcastSystemError(component: String, error: Error) {
        broadcast(.systemError(component: component, error: error))
    }
    
    // MARK: - Event Filtering
    
    func getEvents(ofType eventType: String) -> [WorkoutEvent] {
        return eventHistory.filter { event in
            String(describing: event).contains(eventType)
        }
    }
    
    func getRecentEvents(count: Int = 10) -> [WorkoutEvent] {
        return Array(eventHistory.suffix(count))
    }
    
    func clearEventHistory() {
        eventHistory.removeAll()
        print("🗑️ Event history cleared")
    }
    
    // MARK: - Event Analytics
    
    func getEventStats() -> EventStats {
        let totalEvents = eventHistory.count
        let phaseChanges = eventHistory.filter { 
            if case .phaseChanged = $0 { return true }
            return false
        }.count
        
        let milestones = eventHistory.filter {
            if case .speedMilestone = $0 { return true }
            return false
        }.count
        
        let personalRecords = eventHistory.filter {
            if case .personalRecord = $0 { return true }
            return false
        }.count
        
        let errors = eventHistory.filter {
            if case .systemError = $0 { return true }
            return false
        }.count
        
        return EventStats(
            totalEvents: totalEvents,
            phaseChanges: phaseChanges,
            speedMilestones: milestones,
            personalRecords: personalRecords,
            systemErrors: errors
        )
    }
    
    struct EventStats {
        let totalEvents: Int
        let phaseChanges: Int
        let speedMilestones: Int
        let personalRecords: Int
        let systemErrors: Int
    }
}

// MARK: - Event Bus Extensions for Integration

extension WorkoutEventBus {
    
    /// Register all SC40 systems to listen for events
    func registerAllSystems() {
        registerBasicHapticsSystem()
        setupEventLogging()
        print("📡 Event bus systems registered for Watch target")
    }
    
    private func registerBasicHapticsSystem() {
        subscribe("BasicHaptics") { event in
            switch event {
            case .countdownStarted(let seconds):
                if seconds <= 3 {
                    HapticsManager.triggerHaptic()
                }
            case .personalRecord:
                HapticsManager.triggerHaptic()
            case .speedMilestone:
                HapticsManager.triggerHaptic()
            default:
                break
            }
        }
    }
}

// MARK: - TrainingSession Extension for Event Bus

extension TrainingSession {
    var workoutPhases: [WorkoutEventBus.WorkoutPhase] {
        var phases: [WorkoutEventBus.WorkoutPhase] = [.preparation, .warmup]
        
        for _ in 0..<sprints.count {
            phases.append(.countdown)
            phases.append(.sprint)
            phases.append(.rest)
        }
        
        phases.append(.cooldown)
        phases.append(.complete)
        
        return phases
    }
}
