import Foundation
import SwiftUI

// MARK: - App Configuration
class AppConfiguration {
    static let shared = AppConfiguration()
    
    // MARK: - App Info
    let appVersion: String = "5.0.0"
    let appName: String = "Sprint Coach 40"
    let appBundle: String = "com.sprintcoach.sc40"
    
    // MARK: - Feature Flags
    let enableSocialFeatures: Bool = true
    let enableWatchIntegration: Bool = true
    let enableHealthKit: Bool = true
    let enableNotifications: Bool = true
    let enableAudioCues: Bool = true
    
    // MARK: - API Configuration
    let apiBaseURL: String = "https://api.sprintcoach40.com"
    let apiVersion: String = "v1"
    let requestTimeout: TimeInterval = 30.0
    
    // MARK: - Workout Configuration
    let defaultRestTime: TimeInterval = 60.0
    let minimumRestTime: TimeInterval = 30.0
    let maximumRestTime: TimeInterval = 300.0
    
    let defaultSets: Int = 4
    let minimumSets: Int = 1
    let maximumSets: Int = 10
    
    let defaultReps: Int = 1
    let minimumReps: Int = 1
    let maximumReps: Int = 10
    
    // MARK: - UI Configuration
    let primaryColor: Color = .blue
    let secondaryColor: Color = .purple
    let accentColor: Color = .green
    
    // MARK: - Analytics
    let enableAnalytics: Bool = true
    let analyticsProvider: String = "firebase"
    
    private init() {}
}

// MARK: - Environment Keys
struct AppConfigurationKey: EnvironmentKey {
    static let defaultValue: AppConfiguration = .shared
}

extension EnvironmentValues {
    var appConfig: AppConfiguration {
        get { self[AppConfigurationKey.self] }
        set { self[AppConfigurationKey.self] = newValue }
    }
}

// MARK: - User Defaults Keys
struct UserDefaultsKeys {
    static let userProfile = "userProfile"
    static let onboardingCompleted = "onboardingCompleted"
    static let notificationsEnabled = "notificationsEnabled"
    static let audioCuesEnabled = "audioCuesEnabled"
    static let watchHapticsEnabled = "watchHapticsEnabled"
    static let unitsPreference = "unitsPreference"
    static let weeklyGoal = "weeklyGoal"
    static let personalBests = "personalBests"
    static let completedWorkouts = "completedWorkouts"
    static let currentProgram = "currentProgram"
}

// MARK: - Notification Categories
struct NotificationCategories {
    static let workoutReminder = "WORKOUT_REMINDER"
    static let achievement = "ACHIEVEMENT"
    static let motivation = "MOTIVATION"
    static let progress = "PROGRESS"
    static let challenge = "CHALLENGE"
}

// MARK: - Haptic Feedback Types
enum HapticType {
    case success
    case warning
    case error
    case selection
    case impactLight
    case impactMedium
    case impactHeavy
    
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .impactLight: return .light
        case .impactMedium: return .medium
        case .impactHeavy: return .heavy
        default: return .light
        }
    }
}

// MARK: - App Theme
struct AppTheme {
    static let colors = ThemeColors()
    static let fonts = ThemeFonts()
    static let spacing = ThemeSpacing()
    static let cornerRadius = ThemeCornerRadius()
}

struct ThemeColors {
    let primary = Color.blue
    let secondary = Color.purple
    let success = Color.green
    let warning = Color.orange
    let error = Color.red
    let background = Color(UIColor.systemBackground)
    let secondaryBackground = Color(UIColor.secondarySystemBackground)
    let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
}

struct ThemeFonts {
    let largeTitle = Font.largeTitle
    let title = Font.title
    let title2 = Font.title2
    let title3 = Font.title3
    let headline = Font.headline
    let subheadline = Font.subheadline
    let body = Font.body
    let caption = Font.caption
    let footnote = Font.footnote
}

struct ThemeSpacing {
    let extraSmall: CGFloat = 4
    let small: CGFloat = 8
    let medium: CGFloat = 16
    let large: CGFloat = 24
    let extraLarge: CGFloat = 32
}

struct ThemeCornerRadius {
    let small: CGFloat = 4
    let medium: CGFloat = 8
    let large: CGFloat = 12
    let extraLarge: CGFloat = 16
    let round: CGFloat = 999
}
