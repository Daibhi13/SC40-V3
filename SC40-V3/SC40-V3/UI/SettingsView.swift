import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var voiceFemale = true
    @State private var appleHealthOn = false
    @State private var leaderboardOptIn = true
    @State private var dailyReminders = true
    @State private var streakAlerts = true
    @State private var prCelebrations = true
    @State private var reminderTime = "18:00"
    @State private var showCoachSettings = false
    @State private var showReminders = false
    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var showReferrals = false
    var onReminders: (() -> Void)? = nil
    var onNotifications: (() -> Void)? = nil
    var onProfile: (() -> Void)? = nil
    @ObservedObject var userProfileVM: UserProfileViewModel = UserProfileViewModel()
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching your design
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
                            // Settings Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 20)
                            
                            VStack(spacing: 8) {
                                Text("Settings")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Customize your training experience")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Audio Section
                        SettingsSection(
                            icon: "speaker.wave.2.fill",
                            title: "Audio",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    title: "Voice",
                                    subtitle: voiceFemale ? "Female" : "Male",
                                    isOn: $voiceFemale
                                )
                            }
                        }
                        
                        // Health & Fitness Section
                        SettingsSection(
                            icon: "heart.fill",
                            title: "Health & Fitness",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsToggleRow(
                                    title: "Apple Health",
                                    subtitle: "Sync workouts and metrics",
                                    isOn: $appleHealthOn
                                )
                            }
                        }
                        
                        // Training Section
                        SettingsSection(
                            icon: "bolt.fill",
                            title: "Training",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsNavigationRow(
                                    icon: "target",
                                    title: "Coaching Settings",
                                    subtitle: "Adjust your training preferences",
                                    iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                                    action: { showCoachSettings = true }
                                )
                                
                                SettingsNavigationRow(
                                    icon: "bell.fill",
                                    title: "Reminders",
                                    subtitle: "Set workout reminders",
                                    iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                                    action: { showReminders = true }
                                )
                                
                                SettingsNavigationRow(
                                    icon: "app.badge.fill",
                                    title: "Notifications",
                                    subtitle: "Manage notifications",
                                    iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                                    action: { showNotifications = true }
                                )
                                
                                SettingsNavigationRow(
                                    icon: "person.3.fill",
                                    title: "Referrals",
                                    subtitle: "Invite friends, get rewards",
                                    iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                                    action: { showReferrals = true }
                                )
                            }
                        }
                        
                        // Notification Preferences Section
                        SettingsSection(
                            icon: "bell.fill",
                            title: "Notification Preferences",
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
                        
                        // Profile & Social Section
                        SettingsSection(
                            icon: "person.circle.fill",
                            title: "Profile & Social",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 16) {
                                SettingsNavigationRow(
                                    icon: "person.fill",
                                    title: "Profile",
                                    subtitle: "Edit your information",
                                    iconColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                                    action: { showProfile = true }
                                )
                                
                                SettingsToggleRow(
                                    title: "Leaderboard",
                                    subtitle: "Compete with other athletes",
                                    isOn: $leaderboardOptIn
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showCoachSettings) {
            CoachingSettingsView()
        }
        .sheet(isPresented: $showReminders) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(userProfileVM: userProfileVM)
        }
        .sheet(isPresented: $showReferrals) {
            ReferralsView()
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(icon: String, title: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Section Content
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.0)))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct SettingsTimeRow: View {
    let title: String
    let time: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
