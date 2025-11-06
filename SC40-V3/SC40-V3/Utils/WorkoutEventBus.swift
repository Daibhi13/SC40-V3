import Foundation
import Combine

/// Unified event communication system for all SC40 workout components
/// Provides centralized event broadcasting and subscription management
@MainActor
class WorkoutEventBus: ObservableObject {
    static let shared = WorkoutEventBus()
    
    // MARK: - Published Properties
    @Published var currentPhase: WorkoutPhase = .warmup
    @Published var isWorkoutActive: Bool = false
    @Published var currentEvent: WorkoutEvent?
    
    // MARK: - Private Properties
    private var eventSubscribers: [String: [EventHandler]] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Type Definitions
    typealias EventHandler = (WorkoutEvent) -> Void
    
    // MARK: - Workout Events
    enum WorkoutEvent {
        case workoutStarted(WorkoutSummary)
        case workoutPaused
        case workoutResumed
        case workoutCompleted(WorkoutSummary)
        case phaseChanged(WorkoutPhase)
        case countdownStarted(Int)
        case sprintStarted(Int)
        case sprintCompleted(Int, Double)
        case restStarted(Int)
        case personalRecord(String, Double)
        case speedMilestone(Double, SpeedMilestone)
        case heartRateZone(HeartRateZone)
        case formCorrection(String)
        case motivationalCue(String)
        case workoutSummary(WorkoutSummary)
    }
    
    // MARK: - Workout Phases
    enum WorkoutPhase: String, CaseIterable {
        case warmup = "Warmup"
        case drills = "Drills"
        case sprints = "Sprints"
        case recovery = "Recovery"
        case cooldown = "Cooldown"
        case complete = "Complete"
        
        var description: String {
            return rawValue
        }
    }
    
    // MARK: - Speed Milestones
    enum SpeedMilestone: String, CaseIterable {
        case mph15 = "15 MPH"
        case mph18 = "18 MPH"
        case mph20 = "20 MPH"
        case mph22 = "22 MPH"
        case mph25 = "25 MPH"
        
        var value: Double {
            switch self {
            case .mph15: return 15.0
            case .mph18: return 18.0
            case .mph20: return 20.0
            case .mph22: return 22.0
            case .mph25: return 25.0
            }
        }
    }
    
    // MARK: - Heart Rate Zones
    enum HeartRateZone: String, CaseIterable {
        case zone1 = "Zone 1 - Recovery"
        case zone2 = "Zone 2 - Aerobic"
        case zone3 = "Zone 3 - Tempo"
        case zone4 = "Zone 4 - Threshold"
        case zone5 = "Zone 5 - Neuromuscular"
        
        var targetRange: ClosedRange<Int> {
            switch self {
            case .zone1: return 50...60
            case .zone2: return 60...70
            case .zone3: return 70...80
            case .zone4: return 80...90
            case .zone5: return 90...100
            }
        }
    }
    
    // MARK: - Workout Summary
    struct WorkoutSummary {
        let sessionId: UUID
        let duration: TimeInterval
        let totalSprints: Int
        let maxSpeed: Double
        let averageHeartRate: Int
        let caloriesBurned: Int
        let personalRecords: [String]
        
        init(sessionId: UUID = UUID(), duration: TimeInterval = 0, totalSprints: Int = 0, maxSpeed: Double = 0, averageHeartRate: Int = 0, caloriesBurned: Int = 0, personalRecords: [String] = []) {
            self.sessionId = sessionId
            self.duration = duration
            self.totalSprints = totalSprints
            self.maxSpeed = maxSpeed
            self.averageHeartRate = averageHeartRate
            self.caloriesBurned = caloriesBurned
            self.personalRecords = personalRecords
        }
    }
    
    private init() {
        print("📡 WorkoutEventBus initialized for iOS target")
    }
    
    // MARK: - Event Broadcasting
    func broadcast(_ event: WorkoutEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.currentEvent = event
            self?.notifySubscribers(event)
            self?.logEvent(event)
        }
    }
    
    func broadcastPhaseChange(to phase: WorkoutPhase) {
        currentPhase = phase
        broadcast(.phaseChanged(phase))
    }
    
    // MARK: - Subscription Management
    func subscribe(_ subscriberId: String, handler: @escaping EventHandler) {
        if eventSubscribers[subscriberId] == nil {
            eventSubscribers[subscriberId] = []
        }
        eventSubscribers[subscriberId]?.append(handler)
        print("📡 \(subscriberId) subscribed to workout events")
    }
    
    func unsubscribe(_ subscriberId: String) {
        eventSubscribers.removeValue(forKey: subscriberId)
        print("📡 \(subscriberId) unsubscribed from workout events")
    }
    
    // MARK: - Private Methods
    private func notifySubscribers(_ event: WorkoutEvent) {
        for (_, handlers) in eventSubscribers {
            for handler in handlers {
                handler(event)
            }
        }
    }
    
    private func logEvent(_ event: WorkoutEvent) {
        switch event {
        case .workoutStarted:
            print("📡 Event: Workout Started")
        case .workoutCompleted:
            print("📡 Event: Workout Completed")
        case .phaseChanged(let phase):
            print("📡 Event: Phase Changed to \(phase.rawValue)")
        case .personalRecord(let type, let value):
            print("📡 Event: Personal Record - \(type): \(value)")
        case .speedMilestone(let speed, let milestone):
            print("📡 Event: Speed Milestone - \(speed) MPH (\(milestone.rawValue))")
        default:
            print("📡 Event: \(event)")
        }
    }
}

// MARK: - iOS Extensions
extension WorkoutEventBus {
    
    /// Register all SC40 systems to listen for events (iOS version)
    func registerAllSystems() {
        registerVoiceCoachingSystem()
        registerMusicSystem()
        registerHapticsSystem()
        setupEventLogging()
        print("📡 Event bus systems registered for iOS target")
    }
    
    private func registerVoiceCoachingSystem() {
        subscribe("PremiumVoiceCoach") { event in
            switch event {
            case .phaseChanged(let phase):
                PremiumVoiceCoach.shared.handlePhaseChange(phase)
            case .speedMilestone(let speed, let milestone):
                PremiumVoiceCoach.shared.handleSpeedMilestone(speed, milestone)
            case .heartRateZone(let zone):
                PremiumVoiceCoach.shared.handleHeartRateZone(zone)
            case .personalRecord(let type, let value):
                PremiumVoiceCoach.shared.speak("Congratulations! \(type) Personal Record: \(value)", priority: .high, context: .achievement)
            default:
                break
            }
        }
    }
    
    private func registerMusicSystem() {
        subscribe("WorkoutMusicManager") { event in
            switch event {
            case .phaseChanged(let phase):
                WorkoutMusicManager.shared.syncMusicToWorkout(phase)
            case .workoutCompleted:
                WorkoutMusicManager.shared.playCompletionMusic()
            default:
                break
            }
        }
    }
    
    private func registerHapticsSystem() {
        subscribe("AdvancedHapticsManager") { event in
            switch event {
            case .countdownStarted(let seconds):
                if seconds <= 3 {
                    AdvancedHapticsManager.shared.playPattern(.sprintCountdown)
                }
            case .sprintStarted:
                AdvancedHapticsManager.shared.playPattern(.sprintStart)
            case .personalRecord:
                AdvancedHapticsManager.shared.playPattern(.achievement)
            case .speedMilestone(let speed, _):
                AdvancedHapticsManager.shared.speedMilestone(speed)
            default:
                break
            }
        }
    }
    
    private func setupEventLogging() {
        subscribe("EventLogger") { event in
            // Log events for analytics and debugging
            print("📊 Analytics: \(event)")
        }
    }
}
