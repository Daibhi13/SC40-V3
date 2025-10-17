//
//  SharedResources.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import SwiftUI

// MARK: - App Constants

class AppConstants {
    static let appName = "SC40-V5"
    static let appVersion = "5.0.0"
    static let buildNumber = "1"

    static let websiteURL = URL(string: "https://sc40.app")!
    static let supportEmail = "support@sc40.app"
    static let privacyPolicyURL = URL(string: "https://sc40.app/privacy")!
    static let termsOfServiceURL = URL(string: "https://sc40.app/terms")!

    static let minSupportediOSVersion = "18.0"
    static let minSupportedWatchOSVersion = "9.0"

    // API Configuration
    static let apiBaseURL = URL(string: "https://api.sc40.app/v1")!
    static let apiTimeoutInterval: TimeInterval = 30.0

    // Core Data Configuration
    static let coreDataModelName = "SC40_V5"

    // HealthKit Configuration
    static let healthKitEnabled = true

    // Watch Connectivity
    static let watchConnectivityEnabled = true

    // Notifications
    static let notificationsEnabled = true

    // Social Features
    static let socialFeaturesEnabled = true
}

// MARK: - Color Palette

class AppColors {
    static let primary = Color.blue
    static let secondary = Color.purple
    static let accent = Color.orange

    // Training Colors
    static let sprintGreen = Color.green
    static let restBlue = Color.blue
    static let warningOrange = Color.orange
    static let errorRed = Color.red

    // Background Colors
    static let lightBackground = Color.white
    static let darkBackground = Color.black
    static let cardBackground = Color.white.opacity(0.95)

    // Text Colors
    static let primaryText = Color.black
    static let secondaryText = Color.gray
    static let lightText = Color.white

    // Gradient Colors
    static let mainGradient = LinearGradient(
        colors: [.blue, .purple, .pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [.green, .mint],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let warningGradient = LinearGradient(
        colors: [.orange, .yellow],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let errorGradient = LinearGradient(
        colors: [.red, .pink],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Typography

class AppFonts {
    static let largeTitle = Font.system(.largeTitle, design: .rounded)
    static let title = Font.system(.title, design: .rounded)
    static let title2 = Font.system(.title2, design: .rounded)
    static let title3 = Font.system(.title3, design: .rounded)
    static let headline = Font.system(.headline, design: .rounded)
    static let subheadline = Font.system(.subheadline, design: .rounded)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    static let footnote = Font.system(.footnote, design: .rounded)

    // Monospace for timers
    static let timerFont = Font.system(size: 48, weight: .regular, design: .monospaced)
    static let smallTimerFont = Font.system(size: 32, weight: .regular, design: .monospaced)
}

// MARK: - Spacing

class AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // Specific spacing
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 32
    static let itemSpacing: CGFloat = 12
}

// MARK: - Animations

class AppAnimations {
    static let standard = Animation.easeInOut(duration: 0.3)
    static let fast = Animation.easeInOut(duration: 0.15)
    static let slow = Animation.easeInOut(duration: 0.6)
    static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 15)
    static let smooth = Animation.interactiveSpring(response: 0.6, dampingFraction: 0.8)

    // Spring animations
    static let gentleSpring = Animation.interpolatingSpring(stiffness: 100, damping: 10)
    static let stiffSpring = Animation.interpolatingSpring(stiffness: 400, damping: 20)
}

// MARK: - Haptic Feedback

class AppHaptics {
    static let shared = AppHaptics()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    /// Light impact feedback
    func triggerLightImpact() {
        lightImpact.impactOccurred()
    }

    /// Medium impact feedback
    func triggerMediumImpact() {
        mediumImpact.impactOccurred()
    }

    /// Heavy impact feedback
    func triggerHeavyImpact() {
        heavyImpact.impactOccurred()
    }

    /// Selection feedback
    func selection() {
        selectionFeedback.selectionChanged()
    }

    /// Success notification feedback
    func success() {
        notificationFeedback.notificationOccurred(.success)
    }

    /// Error notification feedback
    func error() {
        notificationFeedback.notificationOccurred(.error)
    }

    /// Warning notification feedback
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }
}

// MARK: - User Defaults Keys

class UserDefaultsKeys {
    static let userProfile = "sc40_user_profile"
    static let userPreferences = "sc40_user_preferences"
    static let trainingHistory = "sc40_training_history"
    static let personalBests = "sc40_personal_bests"
    static let achievements = "sc40_achievements"
    static let settings = "sc40_settings"
    static let firstLaunch = "sc40_first_launch"
    static let lastSyncDate = "sc40_last_sync_date"
    static let subscriptionStatus = "sc40_subscription_status"
}

// MARK: - Error Types

enum AppError: Error {
    case networkError(String)
    case dataError(String)
    case validationError(String)
    case permissionError(String)
    case unknownError(String)

    var localizedDescription: String {
        switch self {
        case .networkError(let message),
             .dataError(let message),
             .validationError(let message),
             .permissionError(let message),
             .unknownError(let message):
            return message
        }
    }
}

// MARK: - Feature Flags

class FeatureFlags {
    static let enableAdvancedAnalytics = true
    static let enableSocialChallenges = true
    static let enableWatchConnectivity = true
    static let enableSiriIntegration = true
    static let enablePremiumFeatures = true
    static let enableOfflineMode = true
    static let enableDataExport = true
    static let enableCustomWorkouts = true
}

// MARK: - Accessibility

class AccessibilityConstants {
    static let buttonMinimumSize = CGSize(width: 44, height: 44)
    static let minimumFontSize: CGFloat = 16
    static let maximumLinesForReadability = 3

    // VoiceOver labels
    static let startWorkoutLabel = "Start workout session"
    static let pauseWorkoutLabel = "Pause current workout"
    static let stopWorkoutLabel = "Stop workout session"
    static let settingsLabel = "Application settings"
    static let profileLabel = "User profile"
}

// MARK: - Localization Keys

class LocalizationKeys {
    // Common
    static let ok = "OK"
    static let cancel = "Cancel"
    static let save = "Save"
    static let delete = "Delete"
    static let edit = "Edit"
    static let done = "Done"

    // Training
    static let startTraining = "Start Training"
    static let pauseTraining = "Pause Training"
    static let resumeTraining = "Resume Training"
    static let stopTraining = "Stop Training"
    static let restPeriod = "Rest Period"
    static let sprintComplete = "Sprint Complete"

    // Profile
    static let editProfile = "Edit Profile"
    static let saveProfile = "Save Profile"
    static let profileUpdated = "Profile Updated"

    // Settings
    static let settings = "Settings"
    static let notifications = "Notifications"
    static let privacy = "Privacy"
    static let about = "About"

    // Errors
    static let networkError = "Network Error"
    static let permissionDenied = "Permission Denied"
    static let dataError = "Data Error"
    static let unknownError = "Unknown Error"
}
