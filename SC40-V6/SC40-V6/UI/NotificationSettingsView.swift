import SwiftUI

struct NotificationSettings: Codable {
    var notificationsEnabled: Bool
    var alertStyle: String // "banner", "alert", "none"
    var soundEnabled: Bool
    var badgeEnabled: Bool
}

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var settings = NotificationSettings(
        notificationsEnabled: true,
        alertStyle: "banner",
        soundEnabled: true,
        badgeEnabled: true
    )
    let alertStyles = ["banner", "alert", "none"]
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                }
                Section(header: Text("Alert Style")) {
                    Picker("Alert Style", selection: $settings.alertStyle) {
                        ForEach(alertStyles, id: \.self) { style in
                            Text(style.capitalized).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Options")) {
                    Toggle("Sound", isOn: $settings.soundEnabled)
                    Toggle("Badge", isOn: $settings.badgeEnabled)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NotificationSettingsView()
}
