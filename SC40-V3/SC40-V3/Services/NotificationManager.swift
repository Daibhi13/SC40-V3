import Foundation
import UserNotifications
import SwiftUI
import Combine

/// Smart notification system for workout reminders, achievements, and motivation
@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            authorizationStatus = granted ? .authorized : .denied
            isAuthorized = granted
            
            if granted {
                await setupDefaultNotifications()
            }
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            authorizationStatus = settings.authorizationStatus
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Workout Reminders
    
    func scheduleWorkoutReminder(
        for date: Date,
        sessionType: String,
        weekNumber: Int,
        dayNumber: Int
    ) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏃‍♂️ Time to Sprint!"
        content.body = "Week \(weekNumber), Day \(dayNumber): \(sessionType) session is ready"
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "type": "workout_reminder",
            "sessionType": sessionType,
            "weekNumber": weekNumber,
            "dayNumber": dayNumber
        ]
        
        // Create trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "workout_\(weekNumber)_\(dayNumber)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("Scheduled workout reminder for \(date)")
        } catch {
            print("Failed to schedule workout reminder: \(error)")
        }
    }
    
    func scheduleWeeklyReminders(
        userProfile: UserProfile,
        preferredTimes: [Int: Date] // Day of week (1-7) to preferred time
    ) async {
        guard isAuthorized else { return }
        
        // Remove existing weekly reminders
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_reminder"])
        
        for (dayOfWeek, time) in preferredTimes {
            let content = UNMutableNotificationContent()
            content.title = "💪 Sprint Training Day!"
            content.body = getMotivationalMessage()
            content.sound = .default
            content.badge = 1
            
            content.userInfo = [
                "type": "weekly_reminder",
                "dayOfWeek": dayOfWeek
            ]
            
            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: time)
            components.weekday = dayOfWeek
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "weekly_reminder_\(dayOfWeek)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule weekly reminder for day \(dayOfWeek): \(error)")
            }
        }
    }
    
    // MARK: - Achievement Notifications
    
    func notifyAchievementUnlocked(
        title: String,
        description: String,
        points: Int
    ) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(title) - \(description) (+\(points) points)"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "type": "achievement",
            "title": title,
            "points": points
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to send achievement notification: \(error)")
        }
    }
    
    func notifyPersonalRecord(
        newTime: Double,
        improvement: Double
    ) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 New Personal Record!"
        content.body = "Amazing! You ran \(String(format: "%.2f", newTime))s - \(String(format: "%.2f", improvement))s faster!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
        content.badge = 1
        
        content.userInfo = [
            "type": "personal_record",
            "newTime": newTime,
            "improvement": improvement
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "pr_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to send PR notification: \(error)")
        }
    }
    
    // MARK: - Motivational Notifications
    
    func scheduleMotivationalReminders() async {
        guard isAuthorized else { return }
        
        let motivationalMessages = [
            ("Morning Motivation", "🌅 Champions train when others sleep. Ready to dominate today?"),
            ("Afternoon Push", "⚡ Your afternoon sprint session is calling. Time to unleash your speed!"),
            ("Evening Excellence", "🌟 End your day strong with a powerful sprint session!"),
            ("Rest Day Reminder", "💤 Recovery is when you grow stronger. Great job resting today!"),
            ("Streak Keeper", "🔥 Keep your training streak alive! Every session counts."),
            ("Progress Check", "📈 Check your progress and see how far you've come!"),
            ("Technique Focus", "🎯 Perfect practice makes perfect. Focus on your form today."),
            ("Speed Demon", "🏃‍♂️💨 Time to channel your inner speed demon!")
        ]
        
        for (index, (title, message)) in motivationalMessages.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            content.userInfo = [
                "type": "motivational",
                "messageIndex": index
            ]
            
            // Schedule for random times throughout the week
            let randomHour = Int.random(in: 9...20) // 9 AM to 8 PM
            let randomMinute = Int.random(in: 0...59)
            let randomDay = Int.random(in: 1...7)
            
            var components = DateComponents()
            components.weekday = randomDay
            components.hour = randomHour
            components.minute = randomMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "motivational_\(index)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule motivational reminder \(index): \(error)")
            }
        }
    }
    
    // MARK: - Smart Reminders
    
    func scheduleSmartReminder(
        basedOnHistory userHistory: [Date],
        preferredTime: Date
    ) async {
        guard isAuthorized else { return }
        
        // Analyze user's workout patterns
        let calendar = Calendar.current
        let dayFrequency = Dictionary(grouping: userHistory) { date in
            calendar.component(.weekday, from: date)
        }
        
        // Find most common workout days
        let preferredDays = dayFrequency
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key }
        
        for day in preferredDays {
            let content = UNMutableNotificationContent()
            content.title = "🎯 Smart Reminder"
            content.body = "Based on your pattern, this is a great time for a sprint session!"
            content.sound = .default
            
            let components = calendar.dateComponents([.hour, .minute], from: preferredTime)
            var triggerComponents = components
            triggerComponents.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "smart_reminder_\(day)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule smart reminder for day \(day): \(error)")
            }
        }
    }
    
    // MARK: - Weather-Based Notifications
    
    func scheduleWeatherAlert(
        for date: Date,
        weatherCondition: WeatherCondition
    ) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        switch weatherCondition {
        case .perfect:
            content.title = "🌤️ Perfect Sprint Weather!"
            content.body = "Ideal conditions for outdoor training. Time to hit the track!"
        case .hot:
            content.title = "🌡️ Hot Weather Alert"
            content.body = "It's hot outside! Stay hydrated and consider indoor training."
        case .cold:
            content.title = "🥶 Cold Weather Tips"
            content.body = "Chilly day ahead. Extra warmup recommended for outdoor sprints."
        case .rainy:
            content.title = "🌧️ Indoor Training Day"
            content.body = "Rainy weather detected. Perfect time for technique drills indoors!"
        case .windy:
            content.title = "💨 Windy Conditions"
            content.body = "Strong winds today. Consider wind-assisted training or indoor alternatives."
        }
        
        content.sound = .default
        content.userInfo = [
            "type": "weather_alert",
            "condition": weatherCondition.rawValue
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "weather_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule weather alert: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    func cancelNotifications(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func getPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        pendingNotifications = requests
    }
    
    // MARK: - Default Setup
    
    private func setupDefaultNotifications() async {
        // Schedule motivational reminders
        await scheduleMotivationalReminders()
        
        // Schedule weekly check-in
        await scheduleWeeklyCheckIn()
    }
    
    private func scheduleWeeklyCheckIn() async {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Check-In"
        content.body = "How was your training this week? Check your progress and plan ahead!"
        content.sound = .default
        
        content.userInfo = [
            "type": "weekly_checkin"
        ]
        
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18   // 6 PM
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_checkin",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule weekly check-in: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMotivationalMessage() -> String {
        let messages = [
            "Every sprint brings you closer to your goals! 🎯",
            "Champions are made in training. Let's go! 💪",
            "Your speed is waiting to be unleashed! ⚡",
            "Consistency beats perfection. Time to train! 🔥",
            "Today's effort is tomorrow's strength! 💯",
            "The track is calling your name! 🏃‍♂️",
            "Great athletes train when they don't feel like it! 🌟",
            "Your personal best is within reach! 🏆"
        ]
        
        return messages.randomElement() ?? "Time for your sprint training! 🏃‍♂️"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "workout_reminder":
                handleWorkoutReminderTap(userInfo: userInfo)
            case "achievement":
                handleAchievementTap(userInfo: userInfo)
            case "personal_record":
                handlePersonalRecordTap(userInfo: userInfo)
            case "weekly_checkin":
                handleWeeklyCheckInTap()
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    private func handleWorkoutReminderTap(userInfo: [AnyHashable: Any]) {
        // Navigate to workout screen
        NotificationCenter.default.post(
            name: .navigateToWorkout,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleAchievementTap(userInfo: [AnyHashable: Any]) {
        // Navigate to achievements screen
        NotificationCenter.default.post(
            name: .navigateToAchievements,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handlePersonalRecordTap(userInfo: [AnyHashable: Any]) {
        // Navigate to progress screen
        NotificationCenter.default.post(
            name: .navigateToProgress,
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleWeeklyCheckInTap() {
        // Navigate to weekly summary
        NotificationCenter.default.post(
            name: .navigateToWeeklySummary,
            object: nil
        )
    }
}

// MARK: - Supporting Types

enum WeatherCondition: String, CaseIterable {
    case perfect = "perfect"
    case hot = "hot"
    case cold = "cold"
    case rainy = "rainy"
    case windy = "windy"
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToWorkout = Notification.Name("navigateToWorkout")
    static let navigateToAchievements = Notification.Name("navigateToAchievements")
    static let navigateToProgress = Notification.Name("navigateToProgress")
    static let navigateToWeeklySummary = Notification.Name("navigateToWeeklySummary")
}
