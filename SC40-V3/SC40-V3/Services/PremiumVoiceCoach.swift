import Foundation
import AVFoundation
import Combine
import NaturalLanguage

/// Premium AI-powered voice coaching system with adaptive, natural speech patterns
/// Provides personalized coaching based on workout analysis and user performance history
@MainActor
class PremiumVoiceCoach: NSObject, ObservableObject {
    static let shared = PremiumVoiceCoach()
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool = true
    @Published var coachingStyle: CoachingStyle = .motivational
    @Published var voicePersonality: VoicePersonality = .professional
    @Published var adaptiveLevel: AdaptiveLevel = .intelligent
    @Published var currentCoachingPhase: CoachingPhase = .preparation
    @Published var isSpeaking: Bool = false
    
    // MARK: - Voice Configuration
    @Published var selectedVoice: VoiceProfile = .defaultCoach
    @Published var speechRate: Float = 0.5
    @Published var volume: Float = 0.8
    @Published var useNaturalPauses: Bool = true
    @Published var contextualAwareness: Bool = true
    
    // MARK: - Adaptive Coaching Properties
    @Published var userPerformanceProfile: AthleteProfile?
    @Published var sessionAnalysis: SessionAnalysis?
    @Published var coachingInsights: [CoachingInsight] = []
    @Published var personalizedMessages: [String] = []
    
    // MARK: - Private Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let subscriptionManager = SubscriptionManager.shared
    private let sessionLibrary = ComprehensiveSessionLibrary()
    private let nlProcessor = NLLanguageRecognizer()
    
    private var speechQueue: [CoachingMessage] = []
    private var isProcessingQueue = false
    private var currentWorkoutSession: TrainingSession?
    private var performanceHistory: [WorkoutResult] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums and Structures
    
    enum CoachingStyle: String, CaseIterable {
        case motivational = "Motivational"
        case technical = "Technical"
        case supportive = "Supportive"
        case intense = "Intense"
        case calm = "Calm"
        case elite = "Elite Athlete"
        
        var description: String {
            switch self {
            case .motivational: return "Energetic and encouraging"
            case .technical: return "Focused on form and technique"
            case .supportive: return "Gentle and reassuring"
            case .intense: return "High-energy and demanding"
            case .calm: return "Steady and composed"
            case .elite: return "Professional athlete coaching"
            }
        }
        
        var isPremium: Bool {
            switch self {
            case .motivational, .supportive: return false
            case .technical, .intense, .calm, .elite: return true
            }
        }
    }
    
    enum VoicePersonality: String, CaseIterable {
        case professional = "Professional Coach"
        case mentor = "Wise Mentor"
        case teammate = "Training Partner"
        case champion = "Champion Athlete"
        case scientist = "Sports Scientist"
        
        var voiceCharacteristics: VoiceCharacteristics {
            switch self {
            case .professional:
                return VoiceCharacteristics(tone: .confident, pace: .measured, emphasis: .clear)
            case .mentor:
                return VoiceCharacteristics(tone: .warm, pace: .deliberate, emphasis: .gentle)
            case .teammate:
                return VoiceCharacteristics(tone: .friendly, pace: .natural, emphasis: .encouraging)
            case .champion:
                return VoiceCharacteristics(tone: .powerful, pace: .dynamic, emphasis: .strong)
            case .scientist:
                return VoiceCharacteristics(tone: .analytical, pace: .precise, emphasis: .informative)
            }
        }
        
        var isPremium: Bool {
            switch self {
            case .professional, .teammate: return false
            case .mentor, .champion, .scientist: return true
            }
        }
    }
    
    enum AdaptiveLevel: String, CaseIterable {
        case basic = "Basic Coaching"
        case intelligent = "Intelligent Adaptation"
        case aiPowered = "AI-Powered Insights"
        
        var isPremium: Bool {
            switch self {
            case .basic: return false
            case .intelligent, .aiPowered: return true
            }
        }
    }
    
    enum CoachingPhase {
        case preparation, warmup, technique, sprint, recovery, cooldown, analysis
    }
    
    struct VoiceProfile {
        let name: String
        let identifier: String
        let language: String
        let gender: String
        let isPremium: Bool
        
        static let defaultCoach = VoiceProfile(
            name: "Default Coach",
            identifier: "com.apple.ttsbundle.Samantha-compact",
            language: "en-US",
            gender: "Female",
            isPremium: false
        )
        
        static let premiumVoices = [
            VoiceProfile(name: "Elite Male Coach", identifier: "com.apple.ttsbundle.Alex", language: "en-US", gender: "Male", isPremium: true),
            VoiceProfile(name: "Champion Female Coach", identifier: "com.apple.ttsbundle.Ava-premium", language: "en-US", gender: "Female", isPremium: true),
            VoiceProfile(name: "International Coach", identifier: "com.apple.ttsbundle.Arthur", language: "en-GB", gender: "Male", isPremium: true)
        ]
    }
    
    struct VoiceCharacteristics {
        let tone: Tone
        let pace: Pace
        let emphasis: Emphasis
        
        enum Tone { case confident, warm, friendly, powerful, analytical }
        enum Pace { case measured, deliberate, natural, dynamic, precise }
        enum Emphasis { case clear, gentle, encouraging, strong, informative }
    }
    
    struct CoachingMessage {
        let content: String
        let priority: Priority
        let context: CoachingContext
        let personalization: PersonalizationLevel
        let timing: MessageTiming
        
        enum Priority: Int { case low = 1, medium = 2, high = 3, critical = 4 }
        enum CoachingContext { case motivation, technique, performance, recovery, achievement }
        enum PersonalizationLevel { case generic, contextual, personalized, adaptive }
        enum MessageTiming { case immediate, delayed, optimal }
    }
    
    struct AthleteProfile {
        let experience: ExperienceLevel
        let strengths: [String]
        let improvementAreas: [String]
        let preferredMotivation: MotivationType
        let personalBests: [String: Double]
        let consistencyScore: Double
        let technicalScore: Double
        
        enum ExperienceLevel { case beginner, intermediate, advanced, elite }
        enum MotivationType { case encouragement, challenge, technical, achievement }
    }
    
    struct SessionAnalysis {
        let sessionType: String
        let difficulty: DifficultyLevel
        let focusAreas: [String]
        let expectedChallenges: [String]
        let coachingOpportunities: [String]
        let adaptiveRecommendations: [String]
        
        enum DifficultyLevel { case easy, moderate, challenging, elite }
    }
    
    struct CoachingInsight {
        let category: InsightCategory
        let message: String
        let confidence: Double
        let actionable: Bool
        
        enum InsightCategory { case technique, pacing, recovery, motivation, strategy }
    }
    
    private override init() {
        super.init()
        setupVoiceCoaching()
        loadUserProfile()
        setupAdaptiveCoaching()
    }
    
    // MARK: - Setup Methods
    
    private func setupVoiceCoaching() {
        speechSynthesizer.delegate = self
        
        // Configure audio session for high-quality speech
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Premium voice coach audio setup failed: \(error)")
        }
    }
    
    private func loadUserProfile() {
        // Load user's performance history and preferences
        performanceHistory = loadPerformanceHistory()
        userPerformanceProfile = analyzeUserProfile()
    }
    
    private func setupAdaptiveCoaching() {
        // Setup real-time adaptation based on performance
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkoutPerformanceUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let performance = notification.object as? WorkoutResult {
                self?.adaptCoachingToPerformance(performance)
            }
        }
    }
    
    // MARK: - Premium Coaching Methods
    
    func startWorkoutCoaching(session: TrainingSession) {
        guard subscriptionManager.hasAccess(to: .aiOptimization) else {
            startBasicCoaching(session: session)
            return
        }
        
        currentWorkoutSession = session
        sessionAnalysis = analyzeWorkoutSession(session)
        
        // Generate personalized welcome message
        let welcomeMessage = generatePersonalizedWelcome(session: session)
        speak(welcomeMessage, priority: .high, context: .motivation)
        
        // Provide session-specific insights
        if let analysis = sessionAnalysis {
            let insightMessage = generateSessionInsights(analysis)
            speak(insightMessage, priority: .medium, context: .technique, delay: 3.0)
        }
        
        print("🎙️ Premium voice coaching started for: \(session.type)")
    }
    
    private func startBasicCoaching(session: TrainingSession) {
        let basicMessage = "Let's begin your \(session.type.lowercased()) training session. Stay focused and give your best effort."
        speak(basicMessage, priority: .medium, context: .motivation)
    }
    
    // MARK: - Adaptive Message Generation
    
    private func generatePersonalizedWelcome(session: TrainingSession) -> String {
        guard let profile = userPerformanceProfile else {
            return generateGenericWelcome(session: session)
        }
        
        var message = ""
        
        // Personalized greeting based on performance history
        if profile.consistencyScore > 0.8 {
            message += "Welcome back, consistent performer! "
        } else if profile.consistencyScore > 0.6 {
            message += "Great to see you back for another session! "
        } else {
            message += "Let's make today count! "
        }
        
        // Session-specific motivation
        switch session.type.lowercased() {
        case let type where type.contains("sprint"):
            if profile.strengths.contains("speed") {
                message += "Time to showcase that speed you've been building. "
            } else {
                message += "Today's sprint work will help develop your explosive power. "
            }
        case let type where type.contains("endurance"):
            message += "Let's work on building that aerobic foundation. "
        default:
            message += "Ready to push your limits today? "
        }
        
        // Add focus area based on session analysis
        if let analysis = sessionAnalysis {
            message += "We'll be focusing on \(analysis.focusAreas.first ?? "overall performance") today."
        }
        
        return message
    }
    
    private func generateGenericWelcome(session: TrainingSession) -> String {
        let welcomes = [
            "Ready to dominate today's \(session.type.lowercased()) session?",
            "Let's make this \(session.type.lowercased()) workout count!",
            "Time to push your limits in today's training.",
            "Welcome to your \(session.type.lowercased()) session. Let's get after it!"
        ]
        return welcomes.randomElement() ?? welcomes[0]
    }
    
    private func generateSessionInsights(_ analysis: SessionAnalysis) -> String {
        var insights = "Here's what to focus on today: "
        
        // Add focus areas
        if !analysis.focusAreas.isEmpty {
            insights += analysis.focusAreas.prefix(2).joined(separator: " and ") + ". "
        }
        
        // Add difficulty-appropriate encouragement
        switch analysis.difficulty {
        case .easy:
            insights += "This is a recovery-focused session, so maintain good form and listen to your body."
        case .moderate:
            insights += "Today's moderate intensity will help build your base. Stay consistent."
        case .challenging:
            insights += "This challenging session will push you. Trust your training and stay strong."
        case .elite:
            insights += "Elite-level training ahead. Channel your inner champion and execute with precision."
        }
        
        return insights
    }
    
    // MARK: - Context-Aware Coaching
    
    func provideSprintCoaching(phase: SprintPhase, performance: SprintPerformance?) {
        guard subscriptionManager.hasAccess(to: .biomechanicsAnalysis) else { return }
        
        let message = generateSprintCoaching(phase: phase, performance: performance)
        speak(message, priority: .high, context: .technique)
    }
    
    private func generateSprintCoaching(phase: SprintPhase, performance: SprintPerformance?) -> String {
        switch phase {
        case .preparation:
            return generatePreparationCoaching()
        case .countdown:
            return generateCountdownCoaching()
        case .acceleration:
            return generateAccelerationCoaching(performance)
        case .maxVelocity:
            return generateMaxVelocityCoaching(performance)
        case .deceleration:
            return generateDecelerationCoaching(performance)
        }
    }
    
    private func generatePreparationCoaching() -> String {
        guard let profile = userPerformanceProfile else {
            return "Get into your starting position. Focus on your setup."
        }
        
        if profile.improvementAreas.contains("starts") {
            return "Remember your start technique. Low and powerful out of the blocks. You've been working on this."
        } else if profile.strengths.contains("acceleration") {
            return "Use that strong acceleration you're known for. Trust your training."
        } else {
            return "Set yourself up for success. Controlled aggression from the start."
        }
    }
    
    private func generateCountdownCoaching() -> String {
        switch coachingStyle {
        case .motivational:
            return "This is your moment. Three... two... one..."
        case .technical:
            return "Focus on your first three steps. Three... two... one..."
        case .intense:
            return "Time to unleash! Three... two... one..."
        case .calm:
            return "Stay relaxed and ready. Three... two... one..."
        case .elite:
            return "Championship execution. Three... two... one..."
        case .supportive:
            return "You've got this. Three... two... one..."
        }
    }
    
    private func generateAccelerationCoaching(_ performance: SprintPerformance?) -> String {
        if let perf = performance, perf.accelerationRate < 0.7 {
            return "Drive those knees! More aggressive out of the start!"
        } else {
            return "Excellent acceleration! Keep building that speed!"
        }
    }
    
    private func generateMaxVelocityCoaching(_ performance: SprintPerformance?) -> String {
        if let perf = performance, perf.maxSpeed > perf.personalBest * 0.95 {
            return "Outstanding speed! You're in PR territory!"
        } else {
            return "Maintain that form! Relaxed but powerful!"
        }
    }
    
    private func generateDecelerationCoaching(_ performance: SprintPerformance?) -> String {
        return "Strong finish! Maintain form through the line!"
    }
    
    // MARK: - Performance-Based Adaptation
    
    private func adaptCoachingToPerformance(_ result: WorkoutResult) {
        performanceHistory.append(result)
        
        // Analyze recent performance trends
        let recentTrend = analyzePerformanceTrend()
        
        // Adapt coaching style based on performance
        if recentTrend.isImproving {
            coachingStyle = .motivational
            speak("Your progress is showing! Keep this momentum going.", priority: .medium, context: .achievement)
        } else if recentTrend.isStagnant {
            coachingStyle = .technical
            speak("Let's focus on technique refinements to break through this plateau.", priority: .medium, context: .technique)
        } else if recentTrend.isDeclining {
            coachingStyle = .supportive
            speak("Every athlete has ups and downs. Trust the process and stay consistent.", priority: .medium, context: .motivation)
        }
    }
    
    // MARK: - Natural Speech Enhancement
    
    private func speak(_ message: String, priority: CoachingMessage.Priority, context: CoachingMessage.CoachingContext, delay: TimeInterval = 0) {
        let enhancedMessage = enhanceMessageNaturalness(message)
        let coachingMessage = CoachingMessage(
            content: enhancedMessage,
            priority: priority,
            context: context,
            personalization: .adaptive,
            timing: delay > 0 ? .delayed : .immediate
        )
        
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.queueMessage(coachingMessage)
            }
        } else {
            queueMessage(coachingMessage)
        }
    }
    
    private func enhanceMessageNaturalness(_ message: String) -> String {
        var enhanced = message
        
        // Add natural pauses
        if useNaturalPauses {
            enhanced = addNaturalPauses(enhanced)
        }
        
        // Adjust for personality
        enhanced = adjustForPersonality(enhanced)
        
        // Add contextual emphasis
        enhanced = addContextualEmphasis(enhanced)
        
        return enhanced
    }
    
    private func addNaturalPauses(_ message: String) -> String {
        var enhanced = message
        
        // Add pauses after key phrases
        enhanced = enhanced.replacingOccurrences(of: ". ", with: "... ")
        enhanced = enhanced.replacingOccurrences(of: "! ", with: "!... ")
        enhanced = enhanced.replacingOccurrences(of: ", ", with: ",... ")
        
        return enhanced
    }
    
    private func adjustForPersonality(_ message: String) -> String {
        let characteristics = voicePersonality.voiceCharacteristics
        
        switch characteristics.tone {
        case .powerful:
            return message.uppercased()
        case .warm:
            return "Hey there, " + message.lowercased()
        case .analytical:
            return "Based on your performance, " + message
        default:
            return message
        }
    }
    
    private func addContextualEmphasis(_ message: String) -> String {
        var enhanced = message
        
        // Emphasize key performance words
        let emphasisWords = ["excellent", "outstanding", "perfect", "strong", "powerful", "fast"]
        for word in emphasisWords {
            enhanced = enhanced.replacingOccurrences(of: word, with: "**\(word)**", options: .caseInsensitive)
        }
        
        return enhanced
    }
    
    // MARK: - Message Queue Management
    
    private func queueMessage(_ message: CoachingMessage) {
        speechQueue.append(message)
        
        // Sort by priority
        speechQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        if !isProcessingQueue {
            processMessageQueue()
        }
    }
    
    private func processMessageQueue() {
        guard !speechQueue.isEmpty, !isProcessingQueue else { return }
        
        isProcessingQueue = true
        let message = speechQueue.removeFirst()
        
        speakMessage(message) { [weak self] in
            self?.isProcessingQueue = false
            self?.processMessageQueue()
        }
    }
    
    private func speakMessage(_ message: CoachingMessage, completion: @escaping () -> Void) {
        let utterance = AVSpeechUtterance(string: message.content)
        
        // Configure voice based on premium settings
        if subscriptionManager.hasAccess(to: .aiOptimization) {
            configurePremuimVoice(utterance)
        } else {
            configureBasicVoice(utterance)
        }
        
        // Store completion handler
        speechCompletionHandlers[utterance] = completion
        
        isSpeaking = true
        speechSynthesizer.speak(utterance)
    }
    
    private var speechCompletionHandlers: [AVSpeechUtterance: () -> Void] = [:]
    
    private func configurePremuimVoice(_ utterance: AVSpeechUtterance) {
        // Use premium voice settings
        utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoice.identifier)
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
    }
    
    private func configureBasicVoice(_ utterance: AVSpeechUtterance) {
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 0.8
    }
    
    // MARK: - Session Analysis
    
    private func analyzeWorkoutSession(_ session: TrainingSession) -> SessionAnalysis {
        let sessionData = sessionLibrary.getSessionData(for: session)
        
        let difficulty: SessionAnalysis.DifficultyLevel
        if session.sprints.first?.intensity == "max" {
            difficulty = .elite
        } else if session.sprints.count > 6 {
            difficulty = .challenging
        } else if session.sprints.count > 3 {
            difficulty = .moderate
        } else {
            difficulty = .easy
        }
        
        let focusAreas = determineFocusAreas(session)
        let challenges = predictChallenges(session)
        let opportunities = identifyCoachingOpportunities(session)
        let recommendations = generateAdaptiveRecommendations(session)
        
        return SessionAnalysis(
            sessionType: session.type,
            difficulty: difficulty,
            focusAreas: focusAreas,
            expectedChallenges: challenges,
            coachingOpportunities: opportunities,
            adaptiveRecommendations: recommendations
        )
    }
    
    private func determineFocusAreas(_ session: TrainingSession) -> [String] {
        var areas: [String] = []
        
        if session.focus.lowercased().contains("acceleration") {
            areas.append("explosive starts")
        }
        if session.focus.lowercased().contains("speed") {
            areas.append("maximum velocity")
        }
        if session.focus.lowercased().contains("endurance") {
            areas.append("speed endurance")
        }
        
        return areas.isEmpty ? ["overall performance"] : areas
    }
    
    private func predictChallenges(_ session: TrainingSession) -> [String] {
        var challenges: [String] = []
        
        if let firstSprint = session.sprints.first {
            if firstSprint.distanceYards >= 60 {
                challenges.append("maintaining speed over distance")
            }
            if firstSprint.reps >= 8 {
                challenges.append("consistency across multiple reps")
            }
            if firstSprint.intensity == "max" {
                challenges.append("peak performance execution")
            }
        }
        
        return challenges
    }
    
    private func identifyCoachingOpportunities(_ session: TrainingSession) -> [String] {
        var opportunities: [String] = []
        
        if session.type.lowercased().contains("technique") {
            opportunities.append("form refinement")
        }
        if session.sprints.count > 5 {
            opportunities.append("pacing strategy")
        }
        
        return opportunities
    }
    
    private func generateAdaptiveRecommendations(_ session: TrainingSession) -> [String] {
        guard let profile = userPerformanceProfile else { return [] }
        
        var recommendations: [String] = []
        
        if profile.improvementAreas.contains("consistency") {
            recommendations.append("Focus on maintaining form across all repetitions")
        }
        if profile.improvementAreas.contains("starts") {
            recommendations.append("Pay extra attention to your starting position and first three steps")
        }
        
        return recommendations
    }
    
    // MARK: - User Profile Analysis
    
    private func analyzeUserProfile() -> AthleteProfile? {
        guard !performanceHistory.isEmpty else { return nil }
        
        let recentResults = Array(performanceHistory.suffix(10))
        
        // Determine experience level
        let experience: AthleteProfile.ExperienceLevel
        if performanceHistory.count < 10 {
            experience = .beginner
        } else if performanceHistory.count < 50 {
            experience = .intermediate
        } else if recentResults.contains(where: { $0.personalRecord }) {
            experience = .elite
        } else {
            experience = .advanced
        }
        
        // Analyze strengths and improvement areas
        let strengths = identifyStrengths(recentResults)
        let improvementAreas = identifyImprovementAreas(recentResults)
        
        // Calculate consistency score
        let consistencyScore = calculateConsistencyScore(recentResults)
        
        // Calculate technical score
        let technicalScore = calculateTechnicalScore(recentResults)
        
        return AthleteProfile(
            experience: experience,
            strengths: strengths,
            improvementAreas: improvementAreas,
            preferredMotivation: .encouragement,
            personalBests: extractPersonalBests(performanceHistory),
            consistencyScore: consistencyScore,
            technicalScore: technicalScore
        )
    }
    
    private func loadPerformanceHistory() -> [WorkoutResult] {
        // Load from UserDefaults or Core Data
        // Placeholder implementation
        return []
    }
    
    private func identifyStrengths(_ results: [WorkoutResult]) -> [String] {
        // Analyze performance patterns to identify strengths
        return ["acceleration", "consistency"]
    }
    
    private func identifyImprovementAreas(_ results: [WorkoutResult]) -> [String] {
        // Analyze performance patterns to identify areas for improvement
        return ["top speed", "starts"]
    }
    
    private func calculateConsistencyScore(_ results: [WorkoutResult]) -> Double {
        // Calculate consistency based on performance variance
        return 0.75
    }
    
    private func calculateTechnicalScore(_ results: [WorkoutResult]) -> Double {
        // Calculate technical proficiency score
        return 0.80
    }
    
    private func extractPersonalBests(_ results: [WorkoutResult]) -> [String: Double] {
        // Extract personal bests for different distances
        return ["40yd": 4.8, "60yd": 7.2]
    }
    
    private func analyzePerformanceTrend() -> PerformanceTrend {
        // Analyze recent performance trend
        return PerformanceTrend(isImproving: true, isStagnant: false, isDeclining: false)
    }
    
    // MARK: - Premium Feature Access
    
    func getAvailableVoices() -> [VoiceProfile] {
        var voices = [VoiceProfile.defaultCoach]
        
        if subscriptionManager.hasAccess(to: .aiOptimization) {
            voices.append(contentsOf: VoiceProfile.premiumVoices)
        }
        
        return voices
    }
    
    func getAvailableCoachingStyles() -> [CoachingStyle] {
        let basicStyles: [CoachingStyle] = [.motivational, .supportive]
        
        if subscriptionManager.hasAccess(to: .biomechanicsAnalysis) {
            return CoachingStyle.allCases
        }
        
        return basicStyles
    }
    
    // MARK: - Settings Management
    
    func updateCoachingStyle(_ style: CoachingStyle) {
        if style.isPremium && !subscriptionManager.hasAccess(to: .biomechanicsAnalysis) {
            // Show upgrade prompt
            return
        }
        
        coachingStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "coaching_style")
    }
    
    func updateVoicePersonality(_ personality: VoicePersonality) {
        if personality.isPremium && !subscriptionManager.hasAccess(to: .aiOptimization) {
            // Show upgrade prompt
            return
        }
        
        voicePersonality = personality
        UserDefaults.standard.set(personality.rawValue, forKey: "voice_personality")
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension PremiumVoiceCoach: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        
        // Call completion handler
        if let completion = speechCompletionHandlers[utterance] {
            completion()
            speechCompletionHandlers.removeValue(forKey: utterance)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
}

// MARK: - Supporting Structures

struct WorkoutResult {
    let sessionId: UUID
    let date: Date
    let performance: Double
    let personalRecord: Bool
    let consistency: Double
    let technique: Double
}

struct SprintPerformance {
    let accelerationRate: Double
    let maxSpeed: Double
    let personalBest: Double
    let formScore: Double
}

enum SprintPhase {
    case preparation, countdown, acceleration, maxVelocity, deceleration
}

struct PerformanceTrend {
    let isImproving: Bool
    let isStagnant: Bool
    let isDeclining: Bool
}

// MARK: - Session Library Integration

class ComprehensiveSessionLibrary {
    func getSessionData(for session: TrainingSession) -> [String: Any] {
        // Return session-specific data for analysis
        return [:]
    }
}
