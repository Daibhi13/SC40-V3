import SwiftUI

struct SettingsView: View {
    @State private var voiceFemale = true
    @State private var appleHealthOn = false
    @State private var leaderboardOptIn = true
    @State private var showCoachSettings = false
    @State private var showReminders = false
    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var showSprintCoachPro = false
    @State private var showShareWithTeammates = false
    var onReminders: (() -> Void)? = nil
    var onNotifications: (() -> Void)? = nil
    var onProfile: (() -> Void)? = nil
    @ObservedObject var userProfileVM: UserProfileViewModel = UserProfileViewModel()
    var body: some View {
        ZStack {
            // Settings Canvas liquid glass background
            Canvas { context, size in
                // Multi-layer settings gradient
                let settingsGradient = Gradient(colors: [
                    Color.brandBackground.opacity(0.95),
                    Color.brandAccent.opacity(0.8),
                    Color.brandSecondary.opacity(0.7),
                    Color.brandPrimary.opacity(0.6)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(settingsGradient,
                                        startPoint: CGPoint(x: 0, y: 0),
                                        endPoint: CGPoint(x: size.width, y: size.height))
                )
                
                // Settings gear visualization
                let gearCount = 5
                for i in 0..<gearCount {
                    let x = size.width * (0.1 + CGFloat(i) * 0.2)
                    let y = size.height * (0.2 + CGFloat(i % 2) * 0.5)
                    let radius: CGFloat = 20 + CGFloat(i) * 5
                    
                    context.addFilter(.blur(radius: 15))
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                               with: .color(Color.brandAccent.opacity(0.15)))
                }
                
                // Glass overlay for frosted effect
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color.brandPrimary.opacity(0.05))
                )
                
                // Subtle wave pattern
                let waveHeight: CGFloat = 12
                let waveLength = size.width / 4
                var wavePath = Path()
                wavePath.move(to: CGPoint(x: 0, y: size.height * 0.7))
                for x in stride(from: 0, through: size.width, by: 2) {
                    let y = size.height * 0.7 + waveHeight * sin((x / waveLength) * 2 * .pi)
                    wavePath.addLine(to: CGPoint(x: x, y: y))
                }
                wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                
                context.fill(wavePath, with: .color(Color.brandTertiary.opacity(0.20)))
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
            // Header
            HStack {
                Text("SETTINGS")
                    .font(.custom("AvenirNext-Bold", size: 22))
                    .foregroundColor(.brandPrimary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
            .background(
                Canvas { context, size in
                    // Header glass background
                    let headerGradient = Gradient(colors: [
                        Color.brandBackground,
                        Color.brandAccent.opacity(0.7),
                        Color.brandTertiary.opacity(0.7)
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(headerGradient,
                                            startPoint: CGPoint(x: 0, y: 0),
                                            endPoint: CGPoint(x: 0, y: size.height))
                    )
                }
            )
            // SOUNDS
            sectionHeader("SOUNDS")
            HStack {
                Text("Voice")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Toggle(isOn: $voiceFemale) {
                    Text(voiceFemale ? "Female" : "Male")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
            }
            .padding()
            dividerLine()
            // Coach Settings
            settingsRow(title: "Coaching Settings", action: { showCoachSettings = true })
            // Apple Health
            sectionHeader("")
            HStack {
                Text("Apple Health")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Toggle(isOn: $appleHealthOn) {
                    Text(appleHealthOn ? "On" : "Off")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
            }
            .padding()
            dividerLine()
            // Reminders
            settingsRow(title: "Reminders", action: { showReminders = true })
            // Notifications
            settingsRow(title: "Notifications Settings", action: { showNotifications = true })
            // Profile
            sectionHeader("")
            settingsRow(title: "Profile", action: { showProfile = true })
            // Leaderboard Opt-in
            sectionHeader("")
            HStack {
                Text("Opt in to Leaderboard")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Toggle(isOn: $leaderboardOptIn) {
                    Text(leaderboardOptIn ? "On" : "Off")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
            }
            .padding()
            dividerLine()

            Spacer()
        }
        }
        .sheet(isPresented: $showCoachSettings) {
            CoachingSettingsView()
        }
        .sheet(isPresented: $showReminders) {
            ReminderSettingsView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView(userProfileVM: userProfileVM)
        }
        .sheet(isPresented: $showSprintCoachPro) {
            NavigationView { SprintCoachProView() }
        }
        .sheet(isPresented: $showShareWithTeammates) {
            NavigationView { ShareWithTeammatesView() }
        }
    }
}

// MARK: - SettingsView Helpers

fileprivate func sectionHeader(_ title: String) -> some View {
    HStack {
        Text(title)
            .font(.caption)
            .foregroundColor(.brandAccent)
            .padding(.leading, 16)
        Spacer()
    }
    .padding(.top, 16)
}

fileprivate func dividerLine() -> some View {
    Rectangle()
        .fill(Color.brandTertiary.opacity(0.3))
        .frame(height: 1)
        .padding(.horizontal, 16)
}

fileprivate func settingsRow(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.brandAccent)
        }
        .padding()
    }
    .background(Color.brandTertiary.opacity(0.1))
    .cornerRadius(8)
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
}
