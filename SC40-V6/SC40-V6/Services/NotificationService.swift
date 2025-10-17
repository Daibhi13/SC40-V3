import Foundation
import UserNotifications
import Combine

// MARK: - Notification Service
class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
            }
            throw error
        }
    }
    
    // MARK: - Workout Reminders
    func scheduleWorkoutReminder(for date: Date, session: String) {
        let content = UNMutableNotificationContent()
        content.title = "Sprint Training Reminder"
        content.body = "Time for your \(session) session!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        // Add custom data
        content.userInfo = ["session": session, "type": "workout_reminder"]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "workout_reminder_\(session)_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule workout reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleDailyReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Sprint Training"
        content.body = "Don't forget your sprint training session today!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Achievement Notifications
    func scheduleAchievementNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule achievement notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Motivational Notifications
    func scheduleMotivationalNotification() {
        let motivationalMessages = [
            "Every sprint brings you closer to your goals! 💪",
            "Consistency beats perfection. Keep sprinting! 🏃‍♂️",
            "Your future self will thank you for training today! 🌟",
            "Small sprints lead to big victories! 🏆",
            "You're stronger than you think. Prove it today! 🔥"
        ]
        
        let randomMessage = motivationalMessages.randomElement() ?? motivationalMessages[0]
        
        let content = UNMutableNotificationContent()
        content.title = "Sprint Motivation"
        content.body = randomMessage
        content.sound = .default
        content.categoryIdentifier = "MOTIVATION"
        
        // Schedule for random time between 10 AM and 8 PM
        let randomHour = Int.random(in: 10...20)
        var dateComponents = DateComponents()
        dateComponents.hour = randomHour
        dateComponents.minute = Int.random(in: 0...59)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "motivation_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule motivational notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Progress Notifications
    func scheduleWeeklyProgressNotification(distance: Double, sessions: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Progress Update"
        content.body = "This week: \(String(format: "%.1f", distance/1000))km run in \(sessions) sessions! Great work! 🎉"
        content.sound = .default
        content.categoryIdentifier = "PROGRESS"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "progress_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule progress notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func removeNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications() {
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Notification Actions
    func handleNotificationAction(_ action: String, for category: String, userInfo: [AnyHashable: Any]) {
        switch category {
        case "WORKOUT_REMINDER":
            if action == "START_WORKOUT" {
                // Launch the app and start workout
                print("Starting workout from notification")
            } else if action == "SNOOZE" {
                // Snooze the reminder for 1 hour
                print("Snoozing workout reminder")
            }
        case "ACHIEVEMENT":
            if action == "VIEW_ACHIEVEMENT" {
                // Show achievement details
                print("Viewing achievement from notification")
            }
        default:
            break
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier
        let action = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        handleNotificationAction(action, for: category, userInfo: userInfo)
        completionHandler()
    }
}
