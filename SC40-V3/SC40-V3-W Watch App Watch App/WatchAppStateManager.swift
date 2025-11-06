import SwiftUI
import WatchConnectivity
import Combine

@MainActor
class WatchAppStateManager: ObservableObject {
    @Published var isOnboardingComplete = false
    @Published var userName = "Sprinter"
    @Published var userLevel = "Training Mode"
    @Published var trainingDays = "Ready"
    @Published var hasBasicData = false
    
    // Anonymous user experience - no name required
    private let anonymousGreetings = [
        "Ready to Sprint?",
        "Let's Get Faster",
        "Time to Train",
        "Sprint Mode On",
        "Ready, Champion?"
    ]
    
    private let anonymousIdentities = [
        "Champion",
        "Sprinter", 
        "Athlete",
        "Runner",
        "Speedster"
    ]
    
    private let anonymousLevels = [
        "Universal Mode",
        "Open Training",
        "All Levels",
        "Getting Started"
    ]
    
    init() {
        loadStoredData()
        setupWatchConnectivity()
    }
    
    // MARK: - Data Loading
    
    private func loadStoredData() {
        // Check for stored onboarding data
        if let storedName = UserDefaults.standard.string(forKey: "userName"),
           let storedLevel = UserDefaults.standard.string(forKey: "userLevel") {
            userName = storedName
            userLevel = storedLevel
            isOnboardingComplete = true
            hasBasicData = true
        } else {
            // Use anonymous, action-focused experience
            userName = anonymousIdentities.randomElement() ?? "Champion"
            userLevel = anonymousLevels.randomElement() ?? "Universal Mode"
        }
        
        // Load training frequency
        let frequency = UserDefaults.standard.integer(forKey: "trainingFrequency")
        if frequency > 0 {
            trainingDays = "\(frequency) days/week"
        } else {
            trainingDays = "Ready to Train"
        }
    }
    
    // MARK: - Watch Connectivity
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = WatchConnectivityDelegate.shared
            session.activate()
        }
    }
    
    // MARK: - Public Interface
    
    func getDisplayName() -> String {
        return hasBasicData ? userName : userName
    }
    
    func getDisplayLevel() -> String {
        return hasBasicData ? userLevel.uppercased() : userLevel
    }
    
    func getDisplayDays() -> String {
        return trainingDays
    }
    
    func getWelcomeMessage() -> String {
        if hasBasicData {
            return "Welcome back, \(userName)!"
        } else {
            return anonymousGreetings.randomElement() ?? "Ready to Sprint?"
        }
    }
    
    func getSetupPrompt() -> String {
        if hasBasicData {
            return "Synced with iPhone"
        } else {
            return "Complete setup on iPhone for personalized training"
        }
    }
    
    func updateFromOnboarding(_ data: [String: Any]) {
        // Guard against nil or empty data
        guard !data.isEmpty else {
            print("⚠️ WatchAppStateManager: Received empty data in updateFromOnboarding")
            return
        }
        
        print("📱 WatchAppStateManager: Processing onboarding data with keys: \(data.keys.joined(separator: ", "))")
        
        if let name = data["name"] as? String,
           let level = data["level"] as? String,
           let frequency = data["frequency"] as? Int {
            
            userName = name
            userLevel = level.capitalized // Use title case for consistency with phone
            trainingDays = "\(frequency) days/week"
            isOnboardingComplete = true
            hasBasicData = true
            
            // Store for persistence
            UserDefaults.standard.set(name, forKey: "userName")
            UserDefaults.standard.set(level.capitalized, forKey: "userLevel") // Store in title case
            UserDefaults.standard.set(frequency, forKey: "trainingFrequency")
            UserDefaults.standard.set(true, forKey: "onboardingComplete")
            UserDefaults.standard.synchronize()
            
            print("✅ WatchAppStateManager: Successfully updated from onboarding - Name: \(name), Level: \(level), Frequency: \(frequency)")
            
            print("✅ Watch: Onboarding data updated - \(name), \(level.capitalized), \(frequency) days")
        } else {
            print("⚠️ WatchAppStateManager: Missing required onboarding data (name, level, or frequency)")
            print("🔍 Available keys: \(data.keys.joined(separator: ", "))")
        }
    }
    
    func resetToPreOnboarding() {
        userName = anonymousIdentities.randomElement() ?? "Champion"
        userLevel = anonymousLevels.randomElement() ?? "Universal Mode"
        trainingDays = "Ready to Train"
        isOnboardingComplete = false
        hasBasicData = false
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userLevel")
        UserDefaults.standard.removeObject(forKey: "trainingFrequency")
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }
}

// MARK: - Watch Connectivity Delegate

class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityDelegate()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated with state: \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if message["type"] as? String == "onboarding_complete" {
                // Update app state with onboarding data
                WatchAppStateManager.shared.updateFromOnboarding(message)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // Guard against nil or empty context
        guard !applicationContext.isEmpty else {
            print("⚠️ WatchAppStateManager: Received empty application context")
            return
        }
        
        print("📱 WatchAppStateManager: Received application context with keys: \(applicationContext.keys.joined(separator: ", "))")
        
        DispatchQueue.main.async {
            WatchAppStateManager.shared.updateFromOnboarding(applicationContext)
        }
    }
}

// MARK: - Shared Instance Extension

extension WatchAppStateManager {
    static let shared = WatchAppStateManager()
}
