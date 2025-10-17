import UserNotifications
import Combine

/// Schedules reminders for workouts on watchOS.
class WorkoutNotificationManager: @unchecked Sendable {
    static let shared = WorkoutNotificationManager()

    private init() {}

    /// Request notification authorization from the user
    func requestAuthorization(completion: (@Sendable (Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                completion?(granted)
            }
        }
    }

    /// Schedule a local notification for a workout reminder
    func scheduleWorkoutReminder(at date: Date, title: String = "Workout Reminder", body: String = "It's time for your workout!") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
