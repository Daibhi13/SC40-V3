import SwiftUI

// MARK: - Sprint Coach Brand Colors
// Single source of truth for all brand colors across the Watch App

extension Color {
    // Primary brand colors - Sprint Coach 40 theme
    static let brandPrimary = Color(red: 1.0, green: 0.8, blue: 0.0)      // Golden yellow
    static let brandSecondary = Color(red: 0.95, green: 0.95, blue: 0.95)  // Light gray/white
    static let brandAccent = Color(red: 0.2, green: 0.8, blue: 1.0)       // Cyan blue
    static let brandBackground = Color(red: 0.05, green: 0.05, blue: 0.1)  // Dark navy
    static let brandTertiary = Color(red: 0.1, green: 0.1, blue: 0.15)     // Darker navy

    // Level-based colors for dynamic theming
    static let levelElite = Color.purple
    static let levelAdvanced = Color.blue
    static let levelIntermediate = Color.green
    static let levelBeginner = Color.orange

    // Gradient colors for backgrounds
    static let gradientStart = Color(red: 0.08, green: 0.12, blue: 0.25)
    static let gradientMiddle = Color(red: 0.12, green: 0.08, blue: 0.28)
    static let gradientEnd = Color(red: 0.15, green: 0.08, blue: 0.25)

    // Session type colors
    static let speedColor = Color(red: 1.0, green: 0.4, blue: 0.4)         // Red for speed
    static let accelColor = Color(red: 1.0, green: 0.8, blue: 0.0)         // Yellow for acceleration
    static let enduranceColor = Color(red: 0.4, green: 1.0, blue: 0.4)     // Green for endurance
    static let recoveryColor = Color(red: 0.4, green: 0.6, blue: 1.0)      // Blue for recovery

    // UI state colors
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
}
