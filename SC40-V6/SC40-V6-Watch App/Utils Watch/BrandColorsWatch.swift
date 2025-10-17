import SwiftUI

// MARK: - Sprint Coach Brand Colors
// Single source of truth for all brand colors across the Watch App

public struct BrandColorsWatch {
    // Primary brand colors - Sprint Coach 40 theme
    public static let primary = Color(red: 1.0, green: 0.8, blue: 0.0)      // Golden yellow
    public static let secondary = Color(red: 0.95, green: 0.95, blue: 0.95)  // Light gray/white
    public static let accent = Color(red: 0.2, green: 0.8, blue: 1.0)       // Cyan blue
    public static let background = Color(red: 0.05, green: 0.05, blue: 0.1)  // Dark navy
    public static let tertiary = Color(red: 0.1, green: 0.1, blue: 0.15)     // Darker navy

    // Level-based colors for dynamic theming
    public static let levelElite = Color.purple
    public static let levelAdvanced = Color.blue
    public static let levelIntermediate = Color.green
    public static let levelBeginner = Color.orange

    // Gradient colors for backgrounds
    public static let gradientStart = Color(red: 0.08, green: 0.12, blue: 0.25)
    public static let gradientMiddle = Color(red: 0.12, green: 0.08, blue: 0.28)
    public static let gradientEnd = Color(red: 0.15, green: 0.08, blue: 0.25)

    // Session type colors
    public static let speedColor = Color(red: 1.0, green: 0.4, blue: 0.4)         // Red for speed
    public static let accelColor = Color(red: 1.0, green: 0.8, blue: 0.0)         // Yellow for acceleration
    public static let enduranceColor = Color(red: 0.4, green: 1.0, blue: 0.4)     // Green for endurance
    public static let recoveryColor = Color(red: 0.4, green: 0.6, blue: 1.0)      // Blue for recovery

    // UI state colors
    public static let successColor = Color.green
    public static let warningColor = Color.orange
    public static let errorColor = Color.red
    public static let infoColor = Color.blue
}
