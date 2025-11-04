import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var voiceFemale = UserDefaults.standard.bool(forKey: "voiceFemale")
    @State private var appleHealthOn = UserDefaults.standard.bool(forKey: "appleHealthOn")
    @State private var leaderboardOptIn = UserDefaults.standard.bool(forKey: "leaderboardOptIn")
    @State private var dailyReminders = UserDefaults.standard.bool(forKey: "dailyReminders")
    @State private var streakAlerts = UserDefaults.standard.bool(forKey: "streakAlerts")
    @State private var prCelebrations = UserDefaults.standard.bool(forKey: "prCelebrations")
    @State private var reminderTime = UserDefaults.standard.string(forKey: "reminderTime") ?? "18:00"
    @State private var showCoachSettings = false
    @State private var showReminders = false
    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var showReferrals = false
    var onReminders: (() -> Void)? = nil
    var onNotifications: (() -> Void)? = nil
    var onProfile: (() -> Void)? = nil
    
    // FIXED: Use shared UserProfileViewModel instead of creating new instance
    @ObservedObject var userProfileVM: UserProfileViewModel
    
    // Get shared profile manager for consistent data
    @StateObject private var profileManager = UserProfileManager.shared
    
    // Initialize with shared UserProfileViewModel
    init(userProfileVM: UserProfileViewModel) {
        self.userProfileVM = userProfileVM
    }
    var body: some View {
        mainNavigationView
            .navigationViewStyle(StackNavigationViewStyle())
            .modifier(SettingsViewModifier(
                showCoachSettings: $showCoachSettings,
                showReminders: $showReminders,
                showNotifications: $showNotifications,
                showProfile: $showProfile,
                showReferrals: $showReferrals,
                userProfileVM: userProfileVM,
                voiceFemale: $voiceFemale,
                appleHealthOn: $appleHealthOn,
                leaderboardOptIn: $leaderboardOptIn,
                dailyReminders: $dailyReminders,
                streakAlerts: $streakAlerts,
                prCelebrations: $prCelebrations,
                reminderTime: $reminderTime,
                initializeSettings: initializeDefaultSettings
            ))
    }
    
    // MARK: - Settings Management
    
    private func initializeDefaultSettings() {
        // Set default values if not already set
        if UserDefaults.standard.object(forKey: "voiceFemale") == nil {
            UserDefaults.standard.set(true, forKey: "voiceFemale")
            voiceFemale = true
        }
        if UserDefaults.standard.object(forKey: "leaderboardOptIn") == nil {
            UserDefaults.standard.set(true, forKey: "leaderboardOptIn")
            leaderboardOptIn = true
        }
        if UserDefaults.standard.object(forKey: "dailyReminders") == nil {
            UserDefaults.standard.set(true, forKey: "dailyReminders")
            dailyReminders = true
        }
        if UserDefaults.standard.object(forKey: "streakAlerts") == nil {
            UserDefaults.standard.set(true, forKey: "streakAlerts")
            streakAlerts = true
        }
        if UserDefaults.standard.object(forKey: "prCelebrations") == nil {
            UserDefaults.standard.set(true, forKey: "prCelebrations")
            prCelebrations = true
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundGradient: some View {
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
    }
    
    private var headerSection: some View {
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
                
                // ADDED: Display current profile info
                VStack(spacing: 4) {
                    Text("\(userProfileVM.profile.name) - \(userProfileVM.profile.level)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    
                    Text("\(userProfileVM.profile.frequency) days/week • PB: \(String(format: "%.2f", userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime))s")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 40)
    }
    
    private var audioSection: some View {
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
    }
    
    private var healthSection: some View {
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
    }
    
    private var mainNavigationView: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView(showsIndicators: false) {
                    mainContent
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            audioSection
            healthSection
            
            Spacer(minLength: 100)
        }
        .padding(.horizontal, 20)
    }
    
}

// MARK: - Settings View Modifier

struct SettingsViewModifier: ViewModifier {
    @Binding var showCoachSettings: Bool
    @Binding var showReminders: Bool
    @Binding var showNotifications: Bool
    @Binding var showProfile: Bool
    @Binding var showReferrals: Bool
    let userProfileVM: UserProfileViewModel
    @Binding var voiceFemale: Bool
    @Binding var appleHealthOn: Bool
    @Binding var leaderboardOptIn: Bool
    @Binding var dailyReminders: Bool
    @Binding var streakAlerts: Bool
    @Binding var prCelebrations: Bool
    @Binding var reminderTime: String
    let initializeSettings: () -> Void
    
    func body(content: Content) -> some View {
        content
            .modifier(SheetsModifier(
                showCoachSettings: $showCoachSettings,
                showReminders: $showReminders,
                showNotifications: $showNotifications,
                showProfile: $showProfile,
                showReferrals: $showReferrals,
                userProfileVM: userProfileVM
            ))
            .modifier(ChangeHandlersModifier(
                voiceFemale: $voiceFemale,
                appleHealthOn: $appleHealthOn,
                leaderboardOptIn: $leaderboardOptIn,
                dailyReminders: $dailyReminders,
                streakAlerts: $streakAlerts,
                prCelebrations: $prCelebrations,
                reminderTime: $reminderTime
            ))
            .onAppear {
                initializeSettings()
            }
    }
}

struct SheetsModifier: ViewModifier {
    @Binding var showCoachSettings: Bool
    @Binding var showReminders: Bool
    @Binding var showNotifications: Bool
    @Binding var showProfile: Bool
    @Binding var showReferrals: Bool
    let userProfileVM: UserProfileViewModel
    
    func body(content: Content) -> some View {
        content
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

struct ChangeHandlersModifier: ViewModifier {
    @Binding var voiceFemale: Bool
    @Binding var appleHealthOn: Bool
    @Binding var leaderboardOptIn: Bool
    @Binding var dailyReminders: Bool
    @Binding var streakAlerts: Bool
    @Binding var prCelebrations: Bool
    @Binding var reminderTime: String
    
    func body(content: Content) -> some View {
        content
            .modifier(BasicSettingsChangeHandler(
                voiceFemale: $voiceFemale,
                appleHealthOn: $appleHealthOn,
                leaderboardOptIn: $leaderboardOptIn
            ))
            .modifier(NotificationSettingsChangeHandler(
                dailyReminders: $dailyReminders,
                streakAlerts: $streakAlerts,
                prCelebrations: $prCelebrations,
                reminderTime: $reminderTime
            ))
    }
}

struct BasicSettingsChangeHandler: ViewModifier {
    @Binding var voiceFemale: Bool
    @Binding var appleHealthOn: Bool
    @Binding var leaderboardOptIn: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: voiceFemale) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "voiceFemale")
            }
            .onChange(of: appleHealthOn) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "appleHealthOn")
            }
            .onChange(of: leaderboardOptIn) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "leaderboardOptIn")
            }
    }
}

struct NotificationSettingsChangeHandler: ViewModifier {
    @Binding var dailyReminders: Bool
    @Binding var streakAlerts: Bool
    @Binding var prCelebrations: Bool
    @Binding var reminderTime: String
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dailyReminders) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "dailyReminders")
            }
            .onChange(of: streakAlerts) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "streakAlerts")
            }
            .onChange(of: prCelebrations) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "prCelebrations")
            }
            .onChange(of: reminderTime) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "reminderTime")
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
