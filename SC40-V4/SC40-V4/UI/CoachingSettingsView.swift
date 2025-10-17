import SwiftUI
import Foundation

// MARK: - Coaching Settings Models
enum TrainingGoal: String, CaseIterable, Identifiable, Codable {
    case faster40, reaction, maxVelocity, conditioning
    var id: String { rawValue }
    var label: String {
        switch self {
        case .faster40: return "Faster 40"
        case .reaction: return "Reaction"
        case .maxVelocity: return "Max Velocity"
        case .conditioning: return "Conditioning"
        }
    }
}

enum CoachingStyle: String, CaseIterable, Identifiable, Codable {
    case classic, motivational, dataDriven, hybrid
    var id: String { rawValue }
    var label: String {
        switch self {
        case .classic: return "Classic"
        case .motivational: return "Motivational"
        case .dataDriven: return "Data Driven"
        case .hybrid: return "Hybrid"
        }
    }
}

enum VoiceCoach: String, CaseIterable, Identifiable, Codable {
    case neutral, motivator, calm, proCoach
    var id: String { rawValue }
    var label: String {
        switch self {
        case .neutral: return "Neutral"
        case .motivator: return "Motivator"
        case .calm: return "Calm"
        case .proCoach: return "Pro Coach"
        }
    }
}

struct CoachingSettings: Codable {
    var level: TrainingLevel
    var goal: TrainingGoal
    var daysPerWeek: Int
    var style: CoachingStyle
    var autoProgression: Bool
    var sessionDuration: Int
    var injurySafe: Bool
    var notifications: Bool
    var voiceCoach: VoiceCoach
    var isProUser: Bool
    var environment: TrainingEnvironment // <-- Add environment to settings
}

// MARK: - Coaching Settings View
struct CoachingSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var settings: CoachingSettings = CoachingSettings(
        level: .pro,
        goal: .faster40,
        daysPerWeek: 7,
        style: .hybrid,
        autoProgression: true,
        sessionDuration: 60,
        injurySafe: true,
        notifications: true,
        voiceCoach: .proCoach,
        isProUser: true,
        environment: .indoor // <-- Initialize environment
    )
    var body: some View {
        NavigationView {
            Form {
                levelSection
                goalSection
                daysPerWeekSection
                coachingStyleSection
                sessionDurationSection
                voiceCoachSection
                environmentSection
                featuresSection
            }
            .navigationTitle("Coaching Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    private var levelSection: some View {
        Section(header: Text("Level")) {
            Picker("Level", selection: $settings.level) {
                ForEach(TrainingLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
        }
    }
    private var goalSection: some View {
        Section(header: Text("Goal")) {
            Picker("Goal", selection: $settings.goal) {
                ForEach(TrainingGoal.allCases) { goal in
                    Text(goal.label).tag(goal)
                }
            }
        }
    }
    private var daysPerWeekSection: some View {
        Section(header: Text("Days Per Week")) {
            Stepper(value: $settings.daysPerWeek, in: 2...7) {
                Text("\(settings.daysPerWeek) days")
            }
        }
    }
    private var coachingStyleSection: some View {
        Section(header: Text("Coaching Style")) {
            Picker("Style", selection: $settings.style) {
                ForEach(CoachingStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
        }
    }
    private var sessionDurationSection: some View {
        Section(header: Text("Session Duration")) {
            Picker("Duration", selection: $settings.sessionDuration) {
                Text("20 min").tag(20)
                Text("40 min").tag(40)
                Text("60 min").tag(60)
            }
        }
    }
    private var voiceCoachSection: some View {
        Section(header: Text("Voice Coach")) {
            Picker("Voice Coach", selection: $settings.voiceCoach) {
                ForEach(VoiceCoach.allCases) { voice in
                    Text(voice.label).tag(voice)
                }
            }
        }
    }
    private var environmentSection: some View {
        Section(header: Text("Environment")) {
            Picker("Environment", selection: $settings.environment) {
                ForEach(TrainingEnvironment.allCases) { env in
                    Text(env.label).tag(env)
                }
            }
        }
    }
    private var featuresSection: some View {
        Section(header: Text("Features")) {
            Toggle("Auto Progression", isOn: $settings.autoProgression)
            Toggle("Injury Safe (Recovery/Mobility)", isOn: $settings.injurySafe)
            Toggle("Coaching Notifications", isOn: $settings.notifications)
            Toggle("Pro User (Unlocks Pro Features)", isOn: $settings.isProUser)
        }
    }
}
