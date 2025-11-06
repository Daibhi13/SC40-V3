import SwiftUI

struct NotificationSettings: Codable {
    var notificationsEnabled: Bool
    var alertStyle: String // "banner", "alert", "none"
    var soundEnabled: Bool
    var badgeEnabled: Bool
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var dailyReminders = true
    @State private var streakAlerts = true
    @State private var prCelebrations = true
    @State private var workoutReminders = true
    @State private var socialNotifications = false
    @State private var reminderTime = "18:00"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching Settings
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Notifications Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 20)
                            
                            VStack(spacing: 8) {
                                Text("Notifications")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Manage your notification preferences")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Training Notifications Section
                        SettingsSection(
                            icon: "figure.run",
                            title: "Training Notifications",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    title: "Daily Reminders",
                                    subtitle: "Get notified for daily workouts",
                                    isOn: $dailyReminders
                                )
                                
                                SettingsTimeRow(
                                    title: "Reminder Time",
                                    time: reminderTime
                                )
                                
                                SettingsToggleRow(
                                    title: "Workout Reminders",
                                    subtitle: "Reminders for scheduled training",
                                    isOn: $workoutReminders
                                )
                            }
                        }
                        
                        // Progress Notifications Section
                        SettingsSection(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Progress Notifications",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    title: "Streak Alerts",
                                    subtitle: "Notifications for maintaining streaks",
                                    isOn: $streakAlerts
                                )
                                
                                SettingsToggleRow(
                                    title: "PR Celebrations",
                                    subtitle: "Celebrate personal records",
                                    isOn: $prCelebrations
                                )
                            }
                        }
                        
                        // Social Notifications Section
                        SettingsSection(
                            icon: "person.2.fill",
                            title: "Social Notifications",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    title: "Social Updates",
                                    subtitle: "Friend activities and challenges",
                                    isOn: $socialNotifications
                                )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showContent = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    NotificationSettingsView()
}
