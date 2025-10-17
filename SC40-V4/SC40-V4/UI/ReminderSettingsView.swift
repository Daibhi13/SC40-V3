import SwiftUI

struct ReminderSettings: Codable {
    var trainingReminders: Bool
    var reminderTime: Date
    var dayBeforeReminder: Bool
    var missedSessionReminder: Bool
    var hydrationReminders: Bool
    var mobilityReminders: Bool
    var motivationalQuotes: Bool
    var weeklySummary: Bool
}

struct ReminderSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var settings = ReminderSettings(
        trainingReminders: true,
        reminderTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
        dayBeforeReminder: true,
        missedSessionReminder: true,
        hydrationReminders: true,
        mobilityReminders: true,
        motivationalQuotes: true,
        weeklySummary: true
    )
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Training Reminders")) {
                    Toggle("Enable Training Reminders", isOn: $settings.trainingReminders)
                    DatePicker("Reminder Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
                }
                Section(header: Text("Additional Reminders")) {
                    Toggle("Remind me the day before", isOn: $settings.dayBeforeReminder)
                    Toggle("Missed Session Reminder", isOn: $settings.missedSessionReminder)
                    Toggle("Hydration Reminders (every 3–4 hrs)", isOn: $settings.hydrationReminders)
                    Toggle("Mobility Reminders (once daily)", isOn: $settings.mobilityReminders)
                }
                Section(header: Text("Motivation & Recap")) {
                    Toggle("Motivational Quotes", isOn: $settings.motivationalQuotes)
                    Toggle("Weekly Summary", isOn: $settings.weeklySummary)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
