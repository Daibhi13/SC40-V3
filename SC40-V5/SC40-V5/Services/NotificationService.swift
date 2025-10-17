//
//  NotificationService.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import UserNotifications
import Combine

/// Service for managing push notifications and local notifications
class NotificationService: NSObject, ObservableObject {

    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var notificationSettings: UNNotificationSettings?

    private let notificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // MARK: - Authorization

    /// Request notification permissions
    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async throws -> Bool {
        let granted = try await notificationCenter.requestAuthorization(options: options)

        await MainActor.run {
            self.authorizationStatus = granted ? .authorized : .denied
        }

        return granted
    }

    /// Get current notification settings
    func getNotificationSettings() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            self.notificationSettings = settings
            self.authorizationStatus = settings.authorizationStatus
        }
    }

    // MARK: - Local Notifications

    /// Schedule a workout reminder notification
    func scheduleWorkoutReminder(title: String,
                                message: String,
                                scheduledTime: Date,
                                workoutId: String,
                                repeating: Bool = false) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        content.userInfo = ["workoutId": workoutId]

        // Add workout reminder actions
        let startAction = UNNotificationAction(identifier: "START_WORKOUT",
                                             title: "Start Workout",
                                             options: .foreground)
        let rescheduleAction = UNNotificationAction(identifier: "RESCHEDULE",
                                                  title: "Reschedule",
                                                  options: [])

        let category = UNNotificationCategory(identifier: "WORKOUT_REMINDER",
                                            actions: [startAction, rescheduleAction],
                                            intentIdentifiers: [],
                                            options: [])
        notificationCenter.setNotificationCategories([category])

        let trigger: UNNotificationTrigger
        if repeating {
            let components = Calendar.current.dateComponents([.hour, .minute], from: scheduledTime)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        } else {
            let timeInterval = scheduledTime.timeIntervalSinceNow
            guard timeInterval > 0 else { return }
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        }

        let request = UNNotificationRequest(identifier: "workout_reminder_\(workoutId)",
                                          content: content,
                                          trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule a session completion reminder
    func scheduleSessionReminder(sessionName: String,
                                estimatedDuration: TimeInterval,
                                startTime: Date) async throws {
        let endTime = startTime.addingTimeInterval(estimatedDuration)

        let content = UNMutableNotificationContent()
        content.title = "Session Almost Complete"
        content.body = "Your \(sessionName) session should be finishing soon. Great work!"
        content.sound = .default
        content.categoryIdentifier = "SESSION_REMINDER"

        let timeInterval = endTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "session_reminder_\(sessionName)",
                                          content: content,
                                          trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule achievement notification
    func scheduleAchievementNotification(achievement: String,
                                       description: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(achievement): \(description)"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(achievement)",
                                          content: content,
                                          trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule challenge reminder
    func scheduleChallengeReminder(challengeName: String,
                                 daysRemaining: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Challenge Reminder"
        content.body = "\(challengeName) ends in \(daysRemaining) days. Don't miss out!"
        content.sound = .default
        content.categoryIdentifier = "CHALLENGE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "challenge_reminder_\(challengeName)",
                                          content: content,
                                          trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule motivational notification
    func scheduleMotivationalNotification() async throws {
        let motivationalMessages = [
            "Every sprint counts! Let's crush today's workout! 💪",
            "Consistency beats perfection. You've got this! 🌟",
            "Your future self will thank you for today's effort! 🔥",
            "Small progress is still progress. Keep moving forward! 🚀",
            "The only bad workout is the one that didn't happen! 🏃‍♂️"
        ]

        let randomMessage = motivationalMessages.randomElement() ?? motivationalMessages[0]

        let content = UNMutableNotificationContent()
        content.title = "SC40 Motivation"
        content.body = randomMessage
        content.sound = .default
        content.categoryIdentifier = "MOTIVATIONAL"

        // Schedule for random time during the day
        let randomHour = Int.random(in: 9...18)
        let randomMinute = Int.random(in: 0...59)
        var dateComponents = DateComponents()
        dateComponents.hour = randomHour
        dateComponents.minute = randomMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "motivational_\(randomHour)_\(randomMinute)",
                                          content: content,
                                          trigger: trigger)

        try await notificationCenter.add(request)
    }

    // MARK: - Notification Management

    /// Remove specific notification
    func removeNotification(identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Remove all notifications for a category
    func removeNotifications(category: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests.filter { $0.content.categoryIdentifier == category }
                                    .map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    /// Remove all workout-related notifications
    func removeAllWorkoutNotifications() {
        let categories = ["WORKOUT_REMINDER", "SESSION_REMINDER"]
        categories.forEach { removeNotifications(category: $0) }
    }

    /// Get pending notifications count
    func getPendingNotificationsCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }

    // MARK: - Notification Categories

    /// Setup notification categories with actions
    func setupNotificationCategories() {
        // Workout reminder category
        let startAction = UNNotificationAction(identifier: "START_WORKOUT",
                                             title: "Start Workout",
                                             options: .foreground)
        let rescheduleAction = UNNotificationAction(identifier: "RESCHEDULE",
                                                  title: "Reschedule",
                                                  options: [])
        let workoutCategory = UNNotificationCategory(identifier: "WORKOUT_REMINDER",
                                                   actions: [startAction, rescheduleAction],
                                                   intentIdentifiers: [],
                                                   options: [])

        // Achievement category
        let shareAction = UNNotificationAction(identifier: "SHARE_ACHIEVEMENT",
                                             title: "Share",
                                             options: .foreground)
        let achievementCategory = UNNotificationCategory(identifier: "ACHIEVEMENT",
                                                       actions: [shareAction],
                                                       intentIdentifiers: [],
                                                       options: [])

        // Challenge category
        let joinAction = UNNotificationAction(identifier: "JOIN_CHALLENGE",
                                            title: "Join Challenge",
                                            options: .foreground)
        let challengeCategory = UNNotificationCategory(identifier: "CHALLENGE_REMINDER",
                                                      actions: [joinAction],
                                                      intentIdentifiers: [],
                                                      options: [])

        // Motivational category
        let dismissAction = UNNotificationAction(identifier: "DISMISS_MOTIVATIONAL",
                                               title: "Got it!",
                                               options: [])
        let motivationalCategory = UNNotificationCategory(identifier: "MOTIVATIONAL",
                                                        actions: [dismissAction],
                                                        intentIdentifiers: [],
                                                        options: [])

        notificationCenter.setNotificationCategories([
            workoutCategory,
            achievementCategory,
            challengeCategory,
            motivationalCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground for workout reminders
        if notification.request.content.categoryIdentifier == "WORKOUT_REMINDER" {
            return [.banner, .sound, .badge]
        }

        return [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse) async {
        let category = response.notification.request.content.categoryIdentifier

        switch category {
        case "WORKOUT_REMINDER":
            if response.actionIdentifier == "START_WORKOUT" {
                await handleStartWorkout(response.notification.request.content.userInfo)
            } else if response.actionIdentifier == "RESCHEDULE" {
                await handleRescheduleWorkout(response.notification.request.content.userInfo)
            }

        case "ACHIEVEMENT":
            if response.actionIdentifier == "SHARE_ACHIEVEMENT" {
                await handleShareAchievement(response.notification.request.content)
            }

        case "CHALLENGE_REMINDER":
            if response.actionIdentifier == "JOIN_CHALLENGE" {
                await handleJoinChallenge(response.notification.request.content.userInfo)
            }

        default:
            break
        }
    }

    // MARK: - Notification Action Handlers

    private func handleStartWorkout(_ userInfo: [AnyHashable: Any]) async {
        // Extract workout ID and navigate to workout
        if let workoutId = userInfo["workoutId"] as? String {
            NotificationCenter.default.post(name: .startWorkoutFromNotification,
                                          object: nil,
                                          userInfo: ["workoutId": workoutId])
        }
    }

    private func handleRescheduleWorkout(_ userInfo: [AnyHashable: Any]) async {
        // Open reschedule interface
        NotificationCenter.default.post(name: .rescheduleWorkoutFromNotification,
                                      object: nil,
                                      userInfo: userInfo)
    }

    private func handleShareAchievement(_ content: UNNotificationContent) async {
        // Open share interface for achievement
        let shareText = "\(content.title)\n\(content.body)"
        NotificationCenter.default.post(name: .shareAchievementFromNotification,
                                      object: nil,
                                      userInfo: ["shareText": shareText])
    }

    private func handleJoinChallenge(_ userInfo: [AnyHashable: Any]) async {
        // Navigate to challenge
        NotificationCenter.default.post(name: .joinChallengeFromNotification,
                                      object: nil,
                                      userInfo: userInfo)
    }
}

// MARK: - NotificationCenter Extensions

extension Notification.Name {
    static let startWorkoutFromNotification = Notification.Name("startWorkoutFromNotification")
    static let rescheduleWorkoutFromNotification = Notification.Name("rescheduleWorkoutFromNotification")
    static let shareAchievementFromNotification = Notification.Name("shareAchievementFromNotification")
    static let joinChallengeFromNotification = Notification.Name("joinChallengeFromNotification")
}
