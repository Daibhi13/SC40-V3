import Foundation
import UIKit
import CoreHaptics
import Combine

/// Advanced haptic feedback system for iOS with Core Haptics support
@MainActor
class AdvancedHapticsManager: ObservableObject {
    static let shared = AdvancedHapticsManager()
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool = true
    @Published var intensity: HapticIntensity = .medium
    @Published var rhythmicHapticsActive: Bool = false
    @Published var currentPattern: HapticPattern?
    
    // MARK: - Private Properties
    private var hapticEngine: CHHapticEngine?
    private var rhythmicTimer: Timer?
    private var patternTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum HapticIntensity: String, CaseIterable {
        case light = "Light"
        case medium = "Medium"
        case strong = "Strong"
        
        var value: Float {
            switch self {
            case .light: return 0.3
            case .medium: return 0.7
            case .strong: return 1.0
            }
        }
    }
    
    enum HapticPattern: String, CaseIterable {
        case single = "Single Tap"
        case double = "Double Tap"
        case sprintCountdown = "Sprint Countdown"
        case sprintStart = "Sprint Start"
        case sprintComplete = "Sprint Complete"
        case achievement = "Achievement"
        case personalRecord = "Personal Record"
        case speedMilestone = "Speed Milestone"
        case heartRateZoneChange = "Heart Rate Zone"
        case formCorrection = "Form Correction"
        case rhythmGuide = "Rhythm Guide"
        case paceGuide = "Pace Guide"
        case celebration = "Celebration"
        case warning = "Warning"
        case recoveryComplete = "Recovery Complete"
        case heartRateRecovery = "Heart Rate Recovery"
        case slowPace = "Slow Pace"
        case friendBeat = "Friend Beat"
        case challenge = "Challenge"
        case warmupComplete = "Warmup Complete"
        case cooldownStart = "Cooldown Start"
        
        var isPremium: Bool {
            switch self {
            case .single, .double, .sprintCountdown, .sprintStart, .sprintComplete:
                return false
            default:
                return true
            }
        }
    }
    
    enum HeartRateZone: String, CaseIterable {
        case zone1 = "Zone 1"
        case zone2 = "Zone 2"
        case zone3 = "Zone 3"
        case zone4 = "Zone 4"
        case zone5 = "Zone 5"
        
        var hapticPattern: HapticPattern {
            switch self {
            case .zone1, .zone2: return .single
            case .zone3: return .double
            case .zone4, .zone5: return .warning
            }
        }
    }
    
    enum TechniqueIssue: String, CaseIterable {
        case armSwing = "Arm Swing"
        case posture = "Posture"
        case stride = "Stride Length"
        case cadence = "Cadence"
        case groundContact = "Ground Contact"
        
        var correctionPattern: HapticPattern {
            return .formCorrection
        }
    }
    
    enum DirectionalHaptic: String, CaseIterable {
        case leftRight = "Left-Right"
        case upDown = "Up-Down"
        case forward = "Forward"
    }
    
    private init() {
        setupHapticEngine()
        print("📳 AdvancedHapticsManager initialized (iOS)")
    }
    
    // MARK: - Setup
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("📳 Device doesn't support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("📳 Haptic engine stopped: \(reason)")
                self?.restartHapticEngine()
            }
            
            hapticEngine?.resetHandler = { [weak self] in
                print("📳 Haptic engine reset")
                self?.restartHapticEngine()
            }
            
        } catch {
            print("📳 Failed to create haptic engine: \(error)")
        }
    }
    
    private func restartHapticEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("📳 Failed to restart haptic engine: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func playHaptic(_ type: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        
        let impactGenerator = UIImpactFeedbackGenerator(style: type)
        impactGenerator.impactOccurred(intensity: CGFloat(intensity.value))
    }
    
    func playPattern(_ pattern: HapticPattern) {
        guard isEnabled else { return }
        
        // Check premium access for advanced patterns
        if pattern.isPremium {
            // Note: Premium features available on iOS with subscription checks
            // Fall back to basic pattern for free users if needed
        }
        
        currentPattern = pattern
        executeHapticPattern(pattern)
    }
    
    func speedMilestone(_ speed: Double) {
        guard isEnabled else { return }
        
        if speed >= 20.0 {
            playPattern(.celebration) // 20+ MPH celebration
        } else if speed >= 18.0 {
            playPattern(.speedMilestone) // 18+ MPH milestone
        } else if speed >= 15.0 {
            playHaptic(.heavy) // 15+ MPH achievement
        }
    }
    
    func heartRateZoneHaptic(_ zone: HeartRateZone) {
        guard isEnabled else { return }
        
        playPattern(zone.hapticPattern)
        
        // Special warnings for extreme zones
        if zone == .zone5 {
            // Rapid warning pulses for max effort zone
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    self.playHaptic(.heavy)
                }
            }
        }
    }
    
    func celebrateAchievement(_ achievement: String) {
        guard isEnabled else { return }
        
        playPattern(.achievement)
        
        // Special celebration for major achievements
        if achievement.contains("Personal Record") || achievement.contains("Elite") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playPattern(.celebration)
            }
        }
    }
    
    // MARK: - Pattern Execution
    private func executeHapticPattern(_ pattern: HapticPattern) {
        switch pattern {
        case .single:
            playHaptic(.light)
        case .double:
            playHaptic(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playHaptic(.medium)
            }
        case .sprintCountdown:
            playCountdownPattern()
        case .sprintStart:
            playHaptic(.heavy)
        case .sprintComplete:
            playCompletionPattern()
        case .achievement:
            playAchievementPattern()
        case .personalRecord:
            playPersonalRecordPattern()
        case .celebration:
            playCelebrationPattern()
        case .warning:
            playWarningPattern()
        default:
            playHaptic(.medium)
        }
    }
    
    private func playCountdownPattern() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                self.playHaptic(.medium)
            }
        }
    }
    
    private func playCompletionPattern() {
        playHaptic(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playHaptic(.heavy)
        }
    }
    
    private func playAchievementPattern() {
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                self.playHaptic(.heavy)
            }
        }
    }
    
    private func playPersonalRecordPattern() {
        // Special extended celebration for personal records
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                let style: UIImpactFeedbackGenerator.FeedbackStyle = i % 2 == 0 ? .heavy : .medium
                self.playHaptic(style)
            }
        }
    }
    
    private func playCelebrationPattern() {
        // Rhythmic celebration pattern
        let pattern = [0.0, 0.1, 0.2, 0.4, 0.5, 0.6]
        for (index, delay) in pattern.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let intensity: UIImpactFeedbackGenerator.FeedbackStyle = index < 3 ? .medium : .heavy
                self.playHaptic(intensity)
            }
        }
    }
    
    private func playWarningPattern() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                self.playHaptic(.heavy)
            }
        }
    }
    
    deinit {
        // Clean up timers without accessing main actor properties
        rhythmicTimer?.invalidate()
        rhythmicTimer = nil
        patternTimer?.invalidate()
        hapticEngine?.stop()
    }
    
    // MARK: - Rhythmic Haptics
    func startPacingHaptics(bpm: Int) {
        guard isEnabled else { return }
        
        Task { @MainActor in
            stopRhythmicHaptics()
        }
        
        let interval = 60.0 / Double(bpm)
        rhythmicHapticsActive = true
        
        rhythmicTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.rhythmicHapticsActive else { return }
                self.playHaptic(.light)
            }
        }
    }
    
    func stopRhythmicHaptics() {
        rhythmicHapticsActive = false
        rhythmicTimer?.invalidate()
        rhythmicTimer = nil
    }
}
