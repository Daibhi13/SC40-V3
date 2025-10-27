import Foundation
import Intents
import IntentsUI
import SwiftUI
import Combine

/// Siri Shortcuts and Intents integration for voice-controlled workouts
@MainActor
class IntentsManager: NSObject, ObservableObject {
    static let shared = IntentsManager()
    
    @Published var donatedShortcuts: [INVoiceShortcut] = []
    @Published var suggestedShortcuts: [INShortcut] = []
    
    override init() {
        super.init()
        setupIntents()
    }
    
    // MARK: - Intent Setup
    
    private func setupIntents() {
        createSuggestedShortcuts()
        donateCommonIntents()
    }
    
    private func createSuggestedShortcuts() {
        let shortcuts = [
            createStartWorkoutShortcut(),
            createCheckProgressShortcut(),
            createViewPersonalBestShortcut(),
            createStartTimerShortcut(),
            createLogSprintTimeShortcut()
        ]
        
        suggestedShortcuts = shortcuts.compactMap { $0 }
    }
    
    // MARK: - Shortcut Creation
    
    private func createStartWorkoutShortcut() -> INShortcut? {
        let intent = StartWorkoutIntent()
        intent.workoutType = "Sprint Training"
        intent.suggestedInvocationPhrase = "Start my sprint workout"
        
        return INShortcut(intent: intent)
    }
    
    private func createCheckProgressShortcut() -> INShortcut? {
        let intent = CheckProgressIntent()
        intent.suggestedInvocationPhrase = "Check my sprint progress"
        
        return INShortcut(intent: intent)
    }
    
    private func createViewPersonalBestShortcut() -> INShortcut? {
        let intent = ViewPersonalBestIntent()
        intent.suggestedInvocationPhrase = "What's my personal best"
        
        return INShortcut(intent: intent)
    }
    
    private func createStartTimerShortcut() -> INShortcut? {
        let intent = StartTimerIntent()
        intent.timerType = "Sprint Timer"
        intent.suggestedInvocationPhrase = "Start sprint timer"
        
        return INShortcut(intent: intent)
    }
    
    private func createLogSprintTimeShortcut() -> INShortcut? {
        let intent = LogSprintTimeIntent()
        intent.suggestedInvocationPhrase = "Log my sprint time"
        
        return INShortcut(intent: intent)
    }
    
    // MARK: - Intent Donation
    
    func donateStartWorkoutIntent(sessionType: String, weekNumber: Int, dayNumber: Int) {
        let intent = StartWorkoutIntent()
        intent.workoutType = sessionType
        intent.weekNumber = NSNumber(value: weekNumber)
        intent.dayNumber = NSNumber(value: dayNumber)
        intent.suggestedInvocationPhrase = "Start my \(sessionType.lowercased()) workout"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "start_workout_\(sessionType)_\(weekNumber)_\(dayNumber)"
        
        interaction.donate { error in
            if let error = error {
                print("Failed to donate start workout intent: \(error)")
            } else {
                print("Donated start workout intent for \(sessionType)")
            }
        }
    }
    
    func donateLogSprintTimeIntent(time: Double, sessionType: String) {
        let intent = LogSprintTimeIntent()
        intent.sprintTime = NSNumber(value: time)
        intent.sessionType = sessionType
        intent.suggestedInvocationPhrase = "Log sprint time \(String(format: "%.2f", time)) seconds"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "log_time_\(time)_\(Date().timeIntervalSince1970)"
        
        interaction.donate { error in
            if let error = error {
                print("Failed to donate log time intent: \(error)")
            } else {
                print("Donated log time intent: \(time)s")
            }
        }
    }
    
    func donatePersonalBestIntent(time: Double) {
        let intent = ViewPersonalBestIntent()
        intent.personalBest = NSNumber(value: time)
        intent.suggestedInvocationPhrase = "My personal best is \(String(format: "%.2f", time)) seconds"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "personal_best_\(time)"
        
        interaction.donate { error in
            if let error = error {
                print("Failed to donate personal best intent: \(error)")
            } else {
                print("Donated personal best intent: \(time)s")
            }
        }
    }
    
    private func donateCommonIntents() {
        // Donate common intents that users might want to use
        donateStartWorkoutIntent(sessionType: "Sprint", weekNumber: 1, dayNumber: 1)
        donateLogSprintTimeIntent(time: 5.0, sessionType: "Sprint")
        donatePersonalBestIntent(time: 4.85)
    }
    
    // MARK: - Shortcut Management
    
    func addShortcutToSiri(_ shortcut: INShortcut) {
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        viewController.delegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
    }
    
    func editShortcut(_ voiceShortcut: INVoiceShortcut) {
        let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
        viewController.delegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
    }
    
    func loadVoiceShortcuts() {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load voice shortcuts: \(error)")
                } else {
                    self.donatedShortcuts = shortcuts ?? []
                }
            }
        }
    }
    
    // MARK: - Intent Handling
    
    func handleStartWorkoutIntent(_ intent: StartWorkoutIntent) -> StartWorkoutIntentResponse {
        // Handle the start workout intent
        print("Handling start workout intent: \(intent.workoutType ?? "Unknown")")
        
        // Trigger workout start in the app
        NotificationCenter.default.post(
            name: .startWorkoutFromSiri,
            object: nil,
            userInfo: [
                "workoutType": intent.workoutType ?? "Sprint",
                "weekNumber": intent.weekNumber?.intValue ?? 1,
                "dayNumber": intent.dayNumber?.intValue ?? 1
            ]
        )
        
        let response = StartWorkoutIntentResponse(code: .success, userActivity: nil)
        response.workoutType = intent.workoutType
        return response
    }
    
    func handleCheckProgressIntent(_ intent: CheckProgressIntent) -> CheckProgressIntentResponse {
        // Handle the check progress intent
        print("Handling check progress intent")
        
        // Get current progress data (mock data for example)
        let currentWeek = 3
        let sessionsCompleted = 4
        let personalBest = 4.85
        
        let response = CheckProgressIntentResponse(code: .success, userActivity: nil)
        response.currentWeek = NSNumber(value: currentWeek)
        response.sessionsCompleted = NSNumber(value: sessionsCompleted)
        response.personalBest = NSNumber(value: personalBest)
        
        return response
    }
    
    func handleViewPersonalBestIntent(_ intent: ViewPersonalBestIntent) -> ViewPersonalBestIntentResponse {
        // Handle the view personal best intent
        print("Handling view personal best intent")
        
        // Get personal best from user data
        let personalBest = getUserPersonalBest()
        
        let response = ViewPersonalBestIntentResponse(code: .success, userActivity: nil)
        response.bestTime = NSNumber(value: personalBest)
        
        return response
    }
    
    func handleLogSprintTimeIntent(_ intent: LogSprintTimeIntent) -> LogSprintTimeIntentResponse {
        // Handle the log sprint time intent
        print("Handling log sprint time intent: \(intent.sprintTime?.doubleValue ?? 0)")
        
        guard let time = intent.sprintTime?.doubleValue else {
            return LogSprintTimeIntentResponse(code: .failure, userActivity: nil)
        }
        
        // Log the sprint time
        logSprintTime(time, sessionType: intent.sessionType ?? "Sprint")
        
        let response = LogSprintTimeIntentResponse(code: .success, userActivity: nil)
        response.sprintTime = intent.sprintTime
        response.sessionType = intent.sessionType
        
        return response
    }
    
    // MARK: - Helper Methods
    
    private func getUserPersonalBest() -> Double {
        // This would fetch from actual user data
        return 4.85
    }
    
    private func logSprintTime(_ time: Double, sessionType: String) {
        // This would save to actual user data
        print("Logged sprint time: \(time)s for \(sessionType)")
        
        // Trigger UI update
        NotificationCenter.default.post(
            name: .sprintTimeLogged,
            object: nil,
            userInfo: [
                "time": time,
                "sessionType": sessionType
            ]
        )
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate

extension IntentsManager: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Failed to add voice shortcut: \(error)")
        } else if let voiceShortcut = voiceShortcut {
            print("Added voice shortcut: \(voiceShortcut.invocationPhrase)")
            donatedShortcuts.append(voiceShortcut)
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate

extension IntentsManager: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Failed to update voice shortcut: \(error)")
        } else if let voiceShortcut = voiceShortcut {
            print("Updated voice shortcut: \(voiceShortcut.invocationPhrase)")
            loadVoiceShortcuts() // Reload to get updated list
        }
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true)
        print("Deleted voice shortcut: \(deletedVoiceShortcutIdentifier)")
        loadVoiceShortcuts() // Reload to get updated list
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Custom Intent Definitions

class StartWorkoutIntent: INIntent {
    @NSManaged public var workoutType: String?
    @NSManaged public var weekNumber: NSNumber?
    @NSManaged public var dayNumber: NSNumber?
}

class CheckProgressIntent: INIntent {
    // No parameters needed for checking progress
}

class ViewPersonalBestIntent: INIntent {
    @NSManaged public var personalBest: NSNumber?
}

class StartTimerIntent: INIntent {
    @NSManaged public var timerType: String?
}

class LogSprintTimeIntent: INIntent {
    @NSManaged public var sprintTime: NSNumber?
    @NSManaged public var sessionType: String?
}

// MARK: - Intent Responses

class StartWorkoutIntentResponse: INIntentResponse {
    @NSManaged public var workoutType: String?
    
    public var code: StartWorkoutIntentResponseCode = .unspecified
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(code: StartWorkoutIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

enum StartWorkoutIntentResponseCode: Int {
    case unspecified = 0
    case ready = 1
    case continueInApp = 2
    case inProgress = 3
    case success = 4
    case failure = 5
    case failureRequiringAppLaunch = 6
}

class CheckProgressIntentResponse: INIntentResponse {
    @NSManaged public var currentWeek: NSNumber?
    @NSManaged public var sessionsCompleted: NSNumber?
    @NSManaged public var personalBest: NSNumber?
    
    public var code: CheckProgressIntentResponseCode = .unspecified
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(code: CheckProgressIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

enum CheckProgressIntentResponseCode: Int {
    case unspecified = 0
    case ready = 1
    case success = 4
    case failure = 5
}

class ViewPersonalBestIntentResponse: INIntentResponse {
    @NSManaged public var bestTime: NSNumber?
    
    public var code: ViewPersonalBestIntentResponseCode = .unspecified
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(code: ViewPersonalBestIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

enum ViewPersonalBestIntentResponseCode: Int {
    case unspecified = 0
    case ready = 1
    case success = 4
    case failure = 5
}

class LogSprintTimeIntentResponse: INIntentResponse {
    @NSManaged public var sprintTime: NSNumber?
    @NSManaged public var sessionType: String?
    
    public var code: LogSprintTimeIntentResponseCode = .unspecified
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(code: LogSprintTimeIntentResponseCode, userActivity: NSUserActivity?) {
        self.init()
        self.code = code
        self.userActivity = userActivity
    }
}

enum LogSprintTimeIntentResponseCode: Int {
    case unspecified = 0
    case ready = 1
    case success = 4
    case failure = 5
}

// MARK: - Notification Names

extension Notification.Name {
    static let startWorkoutFromSiri = Notification.Name("startWorkoutFromSiri")
    static let sprintTimeLogged = Notification.Name("sprintTimeLogged")
}

// MARK: - SwiftUI Integration

struct SiriShortcutsView: View {
    @StateObject private var intentsManager = IntentsManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Suggested Shortcuts") {
                    ForEach(intentsManager.suggestedShortcuts.indices, id: \.self) { index in
                        let shortcut = intentsManager.suggestedShortcuts[index]
                        HStack {
                            VStack(alignment: .leading) {
                                if let intent = shortcut.intent as? StartWorkoutIntent {
                                    Text("Start Workout")
                                        .font(.headline)
                                    Text(intent.suggestedInvocationPhrase ?? "Start my sprint workout")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if shortcut.intent is CheckProgressIntent {
                                    Text("Check Progress")
                                        .font(.headline)
                                    Text("Check my sprint progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if shortcut.intent is ViewPersonalBestIntent {
                                    Text("Personal Best")
                                        .font(.headline)
                                    Text("What's my personal best")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Add to Siri") {
                                intentsManager.addShortcutToSiri(shortcut)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
                
                Section("My Shortcuts") {
                    ForEach(intentsManager.donatedShortcuts, id: \.identifier) { voiceShortcut in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(voiceShortcut.invocationPhrase)
                                    .font(.headline)
                                Text("Tap to edit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Edit") {
                                intentsManager.editShortcut(voiceShortcut)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .onTapGesture {
                            intentsManager.editShortcut(voiceShortcut)
                        }
                    }
                }
            }
            .navigationTitle("Siri Shortcuts")
            .onAppear {
                intentsManager.loadVoiceShortcuts()
            }
        }
    }
}
