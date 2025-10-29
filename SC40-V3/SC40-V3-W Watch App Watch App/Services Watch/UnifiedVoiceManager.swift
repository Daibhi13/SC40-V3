import Foundation
import AVFoundation
import WatchConnectivity
import Combine

/// Unified Voice Manager for consistent voice settings across iPhone and Apple Watch
@MainActor
class UnifiedVoiceManager: NSObject, ObservableObject {
    static let shared = UnifiedVoiceManager()
    
    // MARK: - Voice Configuration
    @Published var selectedVoiceIdentifier: String = "com.apple.ttsbundle.Samantha-compact"
    @Published var speechRate: Float = 0.5
    @Published var speechVolume: Float = 0.8
    @Published var language: String = "en-US"
    @Published var isVoiceEnabled: Bool = true
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var speechQueue: [String] = []
    private var isProcessingQueue = false
    
    // MARK: - Voice Profiles (Synced from iPhone)
    struct VoiceProfile: Codable {
        let name: String
        let identifier: String
        let language: String
        let rate: Float
        let volume: Float
        
        static let defaultProfile = VoiceProfile(
            name: "Default Coach",
            identifier: "com.apple.ttsbundle.Samantha-compact",
            language: "en-US",
            rate: 0.5,
            volume: 0.8
        )
    }
    
    @Published var currentVoiceProfile: VoiceProfile = .defaultProfile
    
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        loadVoiceSettings()
        setupWatchConnectivity()
    }
    
    // MARK: - Voice Settings Management
    
    private func loadVoiceSettings() {
        // Load saved voice settings from UserDefaults
        if let savedIdentifier = UserDefaults.standard.string(forKey: "voiceIdentifier") {
            selectedVoiceIdentifier = savedIdentifier
        }
        
        speechRate = UserDefaults.standard.float(forKey: "speechRate")
        if speechRate == 0 { speechRate = 0.5 } // Default if not set
        
        speechVolume = UserDefaults.standard.float(forKey: "speechVolume")
        if speechVolume == 0 { speechVolume = 0.8 } // Default if not set
        
        language = UserDefaults.standard.string(forKey: "voiceLanguage") ?? "en-US"
        isVoiceEnabled = UserDefaults.standard.bool(forKey: "isVoiceEnabled")
        
        // Update current profile
        currentVoiceProfile = VoiceProfile(
            name: "Current Voice",
            identifier: selectedVoiceIdentifier,
            language: language,
            rate: speechRate,
            volume: speechVolume
        )
        
        print("🎤 Watch: Voice settings loaded - \(selectedVoiceIdentifier), rate: \(speechRate)")
    }
    
    private func saveVoiceSettings() {
        UserDefaults.standard.set(selectedVoiceIdentifier, forKey: "voiceIdentifier")
        UserDefaults.standard.set(speechRate, forKey: "speechRate")
        UserDefaults.standard.set(speechVolume, forKey: "speechVolume")
        UserDefaults.standard.set(language, forKey: "voiceLanguage")
        UserDefaults.standard.set(isVoiceEnabled, forKey: "isVoiceEnabled")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Watch Connectivity
    
    private func setupWatchConnectivity() {
        // Listen for voice settings updates from iPhone
        NotificationCenter.default.addObserver(
            forName: .voiceSettingsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let voiceSettings = notification.object as? [String: Any] {
                Task { @MainActor [weak self] in
                    self?.updateVoiceSettings(from: voiceSettings)
                }
            }
        }
    }
    
    func updateVoiceSettings(from phoneSettings: [String: Any]) {
        if let identifier = phoneSettings["voiceIdentifier"] as? String {
            selectedVoiceIdentifier = identifier
        }
        
        if let rate = phoneSettings["speechRate"] as? Float {
            speechRate = rate
        }
        
        if let volume = phoneSettings["speechVolume"] as? Float {
            speechVolume = volume
        }
        
        if let lang = phoneSettings["language"] as? String {
            language = lang
        }
        
        if let enabled = phoneSettings["isVoiceEnabled"] as? Bool {
            isVoiceEnabled = enabled
        }
        
        // Update current profile
        currentVoiceProfile = VoiceProfile(
            name: "Synced from iPhone",
            identifier: selectedVoiceIdentifier,
            language: language,
            rate: speechRate,
            volume: speechVolume
        )
        
        saveVoiceSettings()
        print("🔄 Watch: Voice settings synced from iPhone - \(selectedVoiceIdentifier)")
    }
    
    // MARK: - Unified Speech Interface
    
    func speak(_ text: String, priority: SpeechPriority = .normal) {
        guard isVoiceEnabled else { return }
        
        print("🗣️ Watch: Speaking with unified voice - \(text)")
        
        if priority == .high {
            // Stop current speech and speak immediately
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
            speakImmediately(text)
        } else {
            // Add to queue
            speechQueue.append(text)
            processQueue()
        }
    }
    
    private func speakImmediately(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Use unified voice configuration
        configureUtterance(utterance)
        
        speechSynthesizer.speak(utterance)
    }
    
    private func configureUtterance(_ utterance: AVSpeechUtterance) {
        // Try to use the specific voice identifier first
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            utterance.voice = voice
            print("🎤 Using specific voice: \(selectedVoiceIdentifier)")
        } else {
            // Fallback to language-based voice
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            print("🎤 Using language voice: \(language)")
        }
        
        utterance.rate = speechRate
        utterance.volume = speechVolume
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
    }
    
    private func processQueue() {
        guard !isProcessingQueue && !speechQueue.isEmpty else { return }
        
        isProcessingQueue = true
        let text = speechQueue.removeFirst()
        speakImmediately(text)
    }
    
    // MARK: - Voice Control
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        isProcessingQueue = false
    }
    
    func testVoice() {
        speak("Voice test. Sprint Coach 40 is ready with synchronized voice settings.", priority: .high)
    }
    
    // MARK: - Settings Updates
    
    func updateVoiceProfile(_ profile: VoiceProfile) {
        currentVoiceProfile = profile
        selectedVoiceIdentifier = profile.identifier
        language = profile.language
        speechRate = profile.rate
        speechVolume = profile.volume
        
        saveVoiceSettings()
        print("🎤 Watch: Voice profile updated to \(profile.name)")
    }
}

// MARK: - Speech Priority
enum SpeechPriority {
    case low, normal, high, critical
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let voiceSettingsUpdated = Notification.Name("voiceSettingsUpdated")
}

// MARK: - AVSpeechSynthesizerDelegate
extension UnifiedVoiceManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isProcessingQueue = false
            
            // Process next item in queue
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.processQueue()
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isProcessingQueue = false
        }
    }
}
