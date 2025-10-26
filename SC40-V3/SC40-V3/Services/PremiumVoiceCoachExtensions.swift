import Foundation

/// Extensions for PremiumVoiceCoach to handle WorkoutEventBus integration
extension PremiumVoiceCoach {
    
    // MARK: - Event Bus Integration Methods
    
    func handlePhaseChange(_ phase: WorkoutEventBus.WorkoutPhase) {
        guard isEnabled else { return }
        
        switch phase {
        case .preparation:
            speak("Get ready. Set yourself up for success.", priority: .medium, context: .motivation)
        case .warmup:
            speak("Let's start with a proper warmup. Get your body ready for the work ahead.", priority: .medium, context: .motivation)
        case .countdown:
            provideSprintCoaching(phase: .countdown, performance: nil)
        case .sprint:
            speak("GO! Give it everything you've got!", priority: .high, context: .motivation)
        case .rest:
            speak("Great work! Take your time to recover fully.", priority: .medium, context: .recovery)
        case .cooldown:
            speak("Time to cool down. Let's bring that heart rate down gradually.", priority: .medium, context: .recovery)
        case .complete:
            speak("Outstanding workout! You should be proud of that effort.", priority: .high, context: .achievement)
        }
    }
    
    func handleSpeedMilestone(_ speed: Double, _ milestone: WorkoutEventBus.SpeedMilestone) {
        guard subscriptionManager.hasAccess(to: .biomechanicsAnalysis) else { return }
        
        let message = generateSpeedMilestoneMessage(speed: speed, milestone: milestone)
        speak(message, priority: .high, context: .achievement)
    }
    
    func handlePersonalRecord(_ category: String, _ value: Double) {
        guard subscriptionManager.hasAccess(to: .aiOptimization) else { return }
        
        let message = generatePersonalRecordMessage(category: category, value: value)
        speak(message, priority: .high, context: .achievement)
    }
    
    func handleHeartRateZone(_ zone: WorkoutEventBus.HeartRateZone) {
        guard subscriptionManager.hasAccess(to: .biomechanicsAnalysis) else { return }
        
        let message = generateHeartRateZoneMessage(zone: zone)
        speak(message, priority: .medium, context: .performance)
    }
    
    // MARK: - Message Generation Methods
    
    private func generateSpeedMilestoneMessage(speed: Double, milestone: WorkoutEventBus.SpeedMilestone) -> String {
        switch coachingStyle {
        case .motivational:
            return "INCREDIBLE! You just hit \(milestone.rawValue)! That's elite-level speed!"
        case .technical:
            return "Excellent speed execution at \(milestone.rawValue). Maintain that form."
        case .intense:
            return "YES! \(milestone.rawValue)! Now push even harder!"
        case .calm:
            return "Nice work reaching \(milestone.rawValue). Stay controlled and smooth."
        case .elite:
            return "Championship speed! \(milestone.rawValue) - that's what separates the elite."
        case .supportive:
            return "Amazing! You've reached \(milestone.rawValue)! Keep believing in yourself!"
        }
    }
    
    private func generatePersonalRecordMessage(category: String, value: Double) -> String {
        switch voicePersonality {
        case .professional:
            return "Personal record achieved in \(category)! Outstanding performance today."
        case .mentor:
            return "I'm proud of you! That's a new personal best in \(category). Your hard work is paying off."
        case .teammate:
            return "YES! New PR in \(category)! We've been working toward this!"
        case .champion:
            return "CHAMPION PERFORMANCE! New record in \(category)! This is what greatness looks like!"
        case .scientist:
            return "Data confirms a new personal record in \(category). Your training adaptations are clearly working."
        }
    }
    
    private func generateHeartRateZoneMessage(zone: WorkoutEventBus.HeartRateZone) -> String {
        switch zone {
        case .zone1:
            return "Good recovery zone. Perfect for active rest."
        case .zone2:
            return "Aerobic zone. Building that endurance base."
        case .zone3:
            return "Threshold zone. This is where we build speed endurance."
        case .zone4:
            return "VO2 Max zone! High intensity work. Stay strong."
        case .zone5:
            return "Maximum effort zone! This is championship territory!"
        }
    }
}

/// Extensions for WorkoutMusicManager to handle WorkoutEventBus integration
extension WorkoutMusicManager {
    
    func syncMusicToWorkout(_ phase: WorkoutEventBus.WorkoutPhase) {
        guard autoSyncEnabled else { return }
        
        let targetPlaylist = getPlaylistForEventPhase(phase)
        
        if currentPlaylist != targetPlaylist {
            switchToPlaylist(targetPlaylist, fadeTransition: fadeTransitions)
        }
        
        adjustVolumeForEventPhase(phase)
        
        if hapticSync {
            syncHapticsToMusic()
        }
    }
    
    func setupMusicForWorkout(_ session: TrainingSession) {
        // Auto-select appropriate playlist based on session type
        if session.type.lowercased().contains("sprint") {
            if let sprintPlaylist = sprintPlaylists.first {
                switchToPlaylist(sprintPlaylist)
            }
        } else if session.type.lowercased().contains("endurance") {
            if let recoveryPlaylist = recoveryPlaylists.first {
                switchToPlaylist(recoveryPlaylist)
            }
        }
    }
    
    func playCompletionMusic() {
        // Play celebration music for workout completion
        if let celebrationPlaylist = sprintPlaylists.first(where: { $0.name.contains("Elite") }) {
            switchToPlaylist(celebrationPlaylist)
        }
    }
    
    private func getPlaylistForEventPhase(_ phase: WorkoutEventBus.WorkoutPhase) -> WorkoutPlaylist? {
        switch phase {
        case .preparation, .warmup:
            return warmupPlaylists.randomElement()
        case .countdown, .sprint:
            return sprintPlaylists.randomElement()
        case .rest:
            return recoveryPlaylists.randomElement()
        case .cooldown:
            return cooldownPlaylists.randomElement()
        case .complete:
            return sprintPlaylists.first(where: { $0.name.contains("Elite") })
        }
    }
    
    private func adjustVolumeForEventPhase(_ phase: WorkoutEventBus.WorkoutPhase) {
        let targetVolume: Float
        
        switch phase {
        case .preparation: targetVolume = 0.4
        case .warmup: targetVolume = 0.6
        case .countdown: targetVolume = 0.7
        case .sprint: targetVolume = 0.8
        case .rest: targetVolume = 0.5
        case .cooldown: targetVolume = 0.4
        case .complete: targetVolume = 0.7
        }
        
        animateVolumeChange(to: targetVolume, duration: 2.0)
    }
}

/// Extensions for AdvancedHapticsManager to handle WorkoutEventBus integration
extension AdvancedHapticsManager {
    
    func handleWorkoutPhaseChange(_ phase: String) {
        guard isEnabled else { return }
        
        switch phase.lowercased() {
        case "preparation":
            playPattern(.single)
        case "warmup":
            playPattern(.double)
        case "countdown":
            sprintCountdown()
        case "sprint":
            startSprint()
        case "rest":
            restPeriodStart(duration: 120)
        case "cooldown":
            playPattern(.cooldownStart)
        case "complete":
            playPattern(.celebration)
        default:
            playHaptic(.notification)
        }
    }
    
    func handleSpeedUpdate(_ speed: Double) {
        if speed >= 15.0 {
            speedMilestone(speed)
        }
    }
    
    func handleHeartRateUpdate(_ heartRate: Int, zone: WorkoutEventBus.HeartRateZone) {
        heartRateZoneHaptic(zone)
    }
}

/// Extensions for WorkoutTestingFramework to handle WorkoutEventBus integration
extension WorkoutTestingFramework {
    
    func recordSystemError(_ component: String, _ error: Error) {
        addTestResult(TestResult(
            category: .systemError,
            test: "System Error in \(component)",
            status: .failed,
            timestamp: Date(),
            details: error.localizedDescription
        ))
    }
    
    func recordPerformanceMetric(_ category: String, _ value: Double) {
        addTestResult(TestResult(
            category: .gpsAccuracy,
            test: "Performance Metric: \(category)",
            status: .passed,
            timestamp: Date(),
            details: "Value: \(value)",
            metrics: [category: value]
        ))
    }
}
