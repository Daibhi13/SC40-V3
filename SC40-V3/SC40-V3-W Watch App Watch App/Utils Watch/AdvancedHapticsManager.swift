import Foundation
import WatchKit
import Combine

/// Advanced haptic feedback system for immersive workout experiences
/// Provides workout-synchronized haptics, biometric-responsive feedback, and performance celebrations
class AdvancedHapticsManager: ObservableObject {
    static let shared = AdvancedHapticsManager()
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool = true
    @Published var intensity: HapticIntensity = .medium
    @Published var rhythmicHapticsActive: Bool = false
    @Published var currentPattern: HapticPattern?
    
    // MARK: - Private Properties
    private var rhythmicTimer: Timer?
    private var patternTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    // Note: SubscriptionManager not available in Watch target
    // Using basic feature availability for Watch
    
    // MARK: - Enums
    
    enum HapticIntensity: String, CaseIterable {
        case light = "Light"
        case medium = "Medium"
        case strong = "Strong"
        
        var watchHaptic: WKHapticType {
            switch self {
            case .light: return .notification
            case .medium: return .directionUp
            case .strong: return .retry
            }
        }
    }
    
    enum HapticPattern {
        // Basic patterns
        case single, double, triple
        case longBuzz, shortPulse
        
        // Workout-specific patterns
        case sprintCountdown, sprintStart, sprintComplete
        case restPeriodStart, restPeriodEnd
        case warmupComplete, cooldownStart
        
        // Performance feedback
        case personalRecord, goodPace, slowPace
        case heartRateZoneChange, speedMilestone
        
        // Technique feedback
        case formCorrection, rhythmGuide, paceGuide
        
        // Social/Achievement patterns
        case achievement, levelUp, challenge
        case friendBeat, newRecord, celebration
        
        // Biometric patterns
        case heartRateHigh, heartRateRecovery
        case fatigueWarning, recoveryComplete
        
        var description: String {
            switch self {
            case .sprintCountdown: return "3-2-1 countdown with escalating intensity"
            case .personalRecord: return "Celebration pattern for new PRs"
            case .formCorrection: return "Gentle guidance for technique improvement"
            case .achievement: return "Victory pattern for unlocked achievements"
            default: return "Haptic feedback pattern"
            }
        }
        
        var isPremium: Bool {
            switch self {
            case .single, .double, .sprintCountdown, .sprintStart:
                return false // Basic patterns for all users
            case .personalRecord, .achievement, .celebration:
                return false // Important feedback for all users
            case .formCorrection, .rhythmGuide, .paceGuide:
                return true // Pro tier technique feedback
            case .heartRateZoneChange, .speedMilestone:
                return true // Elite tier biometric feedback
            case .friendBeat, .newRecord, .challenge:
                return true // Elite tier social features
            default:
                return false
            }
        }
    }
    
    enum DirectionalHaptic {
        case up, down, left, right, forward, backward
        case leftRight, upDown, circular
    }
    
    enum PerformanceLevel {
        case personalRecord, excellent, good, average, needsImprovement
    }
    
    enum HeartRateZone {
        case zone1, zone2, zone3, zone4, zone5
        
        var hapticPattern: HapticPattern {
            switch self {
            case .zone1: return .shortPulse
            case .zone2: return .single
            case .zone3: return .double
            case .zone4: return .triple
            case .zone5: return .longBuzz
            }
        }
    }
    
    enum TechniqueIssue {
        case armSwing, posture, stride, cadence, groundContact
        
        var correctionPattern: HapticPattern {
            switch self {
            case .armSwing: return .formCorrection
            case .posture: return .formCorrection
            case .stride: return .rhythmGuide
            case .cadence: return .paceGuide
            case .groundContact: return .rhythmGuide
            }
        }
    }
    
    private init() {
        setupHapticPreferences()
    }
    
    // MARK: - Setup
    
    private func setupHapticPreferences() {
        // Load user preferences
        isEnabled = UserDefaults.standard.bool(forKey: "haptics_enabled") 
        if let intensityRaw = UserDefaults.standard.string(forKey: "haptic_intensity"),
           let savedIntensity = HapticIntensity(rawValue: intensityRaw) {
            intensity = savedIntensity
        }
    }
    
    // MARK: - Basic Haptic Methods
    
    func playHaptic(_ type: WKHapticType) {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(type)
    }
    
    func playPattern(_ pattern: HapticPattern) {
        guard isEnabled else { return }
        
        // Check premium access for advanced patterns
        if pattern.isPremium {
            // Note: Premium features available on Watch without subscription checks
            // Fall back to basic pattern for free users
            playBasicAlternative(for: pattern)
            return
        }
        
        currentPattern = pattern
        executeHapticPattern(pattern)
    }
    
    private func playBasicAlternative(for pattern: HapticPattern) {
        // Provide basic haptic feedback for premium patterns
        switch pattern {
        case .formCorrection, .rhythmGuide, .paceGuide:
            playHaptic(.notification)
        case .heartRateZoneChange, .speedMilestone:
            playHaptic(.directionUp)
        case .friendBeat, .newRecord, .challenge:
            playHaptic(.success)
        default:
            playHaptic(.click)
        }
    }
    
    // MARK: - Workout-Specific Haptics
    
    func sprintCountdown() {
        guard isEnabled else { return }
        
        print("🔥 Starting sprint countdown haptics")
        
        // 3... (light tap)
        playHaptic(.notification)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 2... (medium tap)
            self.playHaptic(.directionUp)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 1... (strong tap)
                self.playHaptic(.retry)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // GO! (double pulse + long buzz)
                    self.startSprint()
                }
            }
        }
    }
    
    func startSprint() {
        guard isEnabled else { return }
        
        // Double pulse for "GO!"
        playHaptic(.start)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playHaptic(.start)
        }
        
        // Long buzz for motivation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playHaptic(.retry)
        }
    }
    
    func sprintComplete(time: TimeInterval, isPersonalRecord: Bool = false) {
        guard isEnabled else { return }
        
        if isPersonalRecord {
            playPattern(.personalRecord)
        } else {
            playPattern(.sprintComplete)
        }
    }
    
    func restPeriodStart(duration: TimeInterval) {
        guard isEnabled else { return }
        
        playPattern(.restPeriodStart)
        
        // Gentle pulse every 30 seconds during rest
        startRestPeriodPulses(duration: duration)
    }
    
    private func startRestPeriodPulses(duration: TimeInterval) {
        let pulseInterval: TimeInterval = 30.0
        let totalPulses = Int(duration / pulseInterval)
        
        for i in 1...totalPulses {
            DispatchQueue.main.asyncAfter(deadline: .now() + pulseInterval * Double(i)) {
                self.playHaptic(.notification)
            }
        }
    }
    
    // MARK: - Rhythmic Haptics for Pacing
    
    func startPacingHaptics(bpm: Int) {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        stopRhythmicHaptics()
        
        let interval = 60.0 / Double(bpm)
        rhythmicHapticsActive = true
        
        rhythmicTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.rhythmicHapticsActive else { return }
            self.playHaptic(.click)
        }
        
        print("🥁 Started rhythmic haptics at \(bpm) BPM")
    }
    
    func stopRhythmicHaptics() {
        rhythmicTimer?.invalidate()
        rhythmicTimer = nil
        rhythmicHapticsActive = false
    }
    
    // MARK: - Performance Feedback Haptics
    
    func performanceFeedback(_ performance: PerformanceLevel) {
        guard isEnabled else { return }
        
        switch performance {
        case .personalRecord:
            playPattern(.personalRecord)
        case .excellent:
            playPattern(.goodPace)
        case .good:
            playHaptic(.success)
        case .average:
            playHaptic(.notification)
        case .needsImprovement:
            playPattern(.slowPace)
        }
    }
    
    func speedMilestone(_ speed: Double) {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        if speed >= 20.0 {
            playPattern(.celebration) // 20+ MPH celebration
        } else if speed >= 18.0 {
            playPattern(.speedMilestone) // 18+ MPH milestone
        } else if speed >= 15.0 {
            playHaptic(.success) // 15+ MPH achievement
        }
    }
    
    // MARK: - Biometric-Responsive Haptics
    
    func heartRateZoneHaptic(_ zone: HeartRateZone) {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        playPattern(zone.hapticPattern)
        
        // Special warnings for extreme zones
        if zone == .zone5 {
            // Rapid warning pulses for max effort zone
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    self.playHaptic(.retry)
                }
            }
        }
    }
    
    func heartRateRecovery(recoveryRate: Double) {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        if recoveryRate > 0.8 {
            playPattern(.recoveryComplete) // Excellent recovery
        } else if recoveryRate > 0.6 {
            playHaptic(.success) // Good recovery
        } else {
            playPattern(.heartRateRecovery) // Slow recovery warning
        }
    }
    
    // MARK: - Technique Correction Haptics
    
    func techniqueCorrection(_ issue: TechniqueIssue) {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        playPattern(issue.correctionPattern)
        
        // Add directional haptic for specific corrections
        switch issue {
        case .armSwing:
            playDirectionalHaptic(.leftRight)
        case .posture:
            playDirectionalHaptic(.upDown)
        case .stride:
            playDirectionalHaptic(.forward)
        case .cadence:
            startCadenceGuide()
        case .groundContact:
            playGroundContactFeedback()
        }
    }
    
    private func playDirectionalHaptic(_ direction: DirectionalHaptic) {
        switch direction {
        case .leftRight:
            playHaptic(.click)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playHaptic(.notification)
            }
        case .upDown:
            playHaptic(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playHaptic(.failure)
            }
        case .forward:
            playHaptic(.success)
        default:
            playHaptic(.notification)
        }
    }
    
    private func startCadenceGuide() {
        // Provide rhythmic guidance for optimal cadence (180 steps/min)
        startPacingHaptics(bpm: 90) // 90 BPM = 180 steps/min
        
        // Stop after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.stopRhythmicHaptics()
        }
    }
    
    private func playGroundContactFeedback() {
        // Quick, sharp haptic for minimal ground contact time
        playHaptic(.click)
    }
    
    // MARK: - Social & Achievement Haptics
    
    func achievementUnlocked(_ achievement: String) {
        guard isEnabled else { return }
        
        playPattern(.achievement)
        
        // Special celebration for major achievements
        if achievement.contains("Personal Record") || achievement.contains("Elite") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playPattern(.celebration)
            }
        }
    }
    
    func friendChallenge() {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        playPattern(.challenge)
    }
    
    func beatFriendRecord() {
        guard isEnabled else { return }
        // Note: Premium features available on Watch without subscription checks
        
        playPattern(.friendBeat)
    }
    
    // MARK: - Pattern Execution
    
    private func executeHapticPattern(_ pattern: HapticPattern) {
        switch pattern {
        case .single:
            playHaptic(.click)
            
        case .double:
            playHaptic(.click)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playHaptic(.click)
            }
            
        case .triple:
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    self.playHaptic(.click)
                }
            }
            
        case .longBuzz:
            playHaptic(.retry)
            
        case .personalRecord:
            // Victory pattern: rapid pulses followed by long celebration
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    self.playHaptic(.success)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.playHaptic(.retry)
            }
            
        case .celebration:
            // Complex celebration pattern
            let pattern = [0.0, 0.1, 0.2, 0.4, 0.5, 0.6, 1.0, 1.2]
            for (index, delay) in pattern.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.playHaptic(index % 2 == 0 ? .success : .notification)
                }
            }
            
        case .formCorrection:
            // Gentle guidance pattern
            playHaptic(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.playHaptic(.notification)
            }
            
        case .rhythmGuide:
            // Start temporary rhythmic guidance
            startPacingHaptics(bpm: 180) // Optimal sprint cadence
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.stopRhythmicHaptics()
            }
            
        default:
            playHaptic(.notification)
        }
    }
    
    // MARK: - Settings Management
    
    func setIntensity(_ intensity: HapticIntensity) {
        self.intensity = intensity
        UserDefaults.standard.set(intensity.rawValue, forKey: "haptic_intensity")
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "haptics_enabled")
        
        if !enabled {
            stopRhythmicHaptics()
        }
    }
    
    // MARK: - Premium Feature Access
    
    func getAvailablePatterns() -> [HapticPattern] {
        let basicPatterns: [HapticPattern] = [
            .single, .double, .sprintCountdown, .sprintStart, .sprintComplete
        ]
        
        var availablePatterns = basicPatterns
        
        // Note: All premium patterns available on Watch
        availablePatterns.append(contentsOf: [
            .formCorrection, .rhythmGuide, .paceGuide,
            .heartRateZoneChange, .speedMilestone, .friendBeat, .challenge
        ])
        
        return availablePatterns
    }
    
    deinit {
        stopRhythmicHaptics()
        patternTimer?.invalidate()
    }
}

// MARK: - Haptic Extensions
// Note: Using WKHapticType directly to avoid naming conflicts

// MARK: - Integration with Workout Systems

extension AdvancedHapticsManager {
    
    /// Integration with WatchIntervalManager for workout phase haptics
    func handleWorkoutPhaseChange(_ phase: String) {
        switch phase.lowercased() {
        case "warmup":
            playPattern(.warmupComplete)
        case "countdown":
            sprintCountdown()
        case "sprint":
            startSprint()
        case "rest":
            restPeriodStart(duration: 120) // Default 2-minute rest
        case "cooldown":
            playPattern(.cooldownStart)
        default:
            playHaptic(.notification)
        }
    }
    
    /// Integration with WatchGPSManager for speed-based haptics
    func handleSpeedUpdate(_ speed: Double) {
        if speed >= 15.0 {
            speedMilestone(speed)
        }
    }
    
    /// Integration with WatchWorkoutManager for heart rate haptics
    func handleHeartRateUpdate(_ heartRate: Int, zone: HeartRateZone) {
        heartRateZoneHaptic(zone)
    }
}
