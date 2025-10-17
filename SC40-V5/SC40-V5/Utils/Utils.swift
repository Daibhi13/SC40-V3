//
//  Utils.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import UIKit
import CoreLocation
import SwiftUI

// MARK: - Date and Time Utilities

class DateUtils {
    static let shared = DateUtils()

    /// Format time interval as MM:SS.s
    static func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let tenths = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }

    /// Format time interval as MM:SS
    static func formatTimeIntervalShort(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format pace as seconds per 100m
    static func formatPace(_ paceInSeconds: TimeInterval) -> String {
        let minutes = Int(paceInSeconds) / 60
        let seconds = Int(paceInSeconds) % 60
        return String(format: "%d:%02d/100m", minutes, seconds)
    }

    /// Get current week start date (Monday)
    static func getWeekStart() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday - calendar.firstWeekday) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today) ?? today
    }

    /// Get current month start date
    static func getMonthStart() -> Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
    }
}

// MARK: - Distance and Unit Conversions

class UnitUtils {
    static let shared = UnitUtils()

    /// Convert meters to kilometers
    static func metersToKilometers(_ meters: Double) -> Double {
        return meters / 1000.0
    }

    /// Convert kilometers to meters
    static func kilometersToMeters(_ kilometers: Double) -> Double {
        return kilometers * 1000.0
    }

    /// Convert meters per second to kilometers per hour
    static func mpsToKmh(_ mps: Double) -> Double {
        return mps * 3.6
    }

    /// Convert kilometers per hour to meters per second
    static func kmhToMps(_ kmh: Double) -> Double {
        return kmh / 3.6
    }

    /// Format distance based on user preferences
    static func formatDistance(_ meters: Double, unit: UserProfile.UnitSystem) -> String {
        switch unit {
        case .metric:
            return meters >= 1000 ?
                String(format: "%.2f km", meters / 1000.0) :
                String(format: "%.0f m", meters)
        case .imperial:
            let feet = meters * 3.28084
            return feet >= 5280 ?
                String(format: "%.2f mi", feet / 5280.0) :
                String(format: "%.0f ft", feet)
        }
    }

    /// Format speed based on user preferences
    static func formatSpeed(_ mps: Double, unit: UserProfile.UnitSystem) -> String {
        switch unit {
        case .metric:
            return String(format: "%.1f km/h", mps * 3.6)
        case .imperial:
            return String(format: "%.1f mph", mps * 2.23694)
        }
    }
}

// MARK: - Color Utilities

class ColorUtils {
    static let shared = ColorUtils()

    /// Generate gradient colors for different intensities
    static func gradientForIntensity(_ intensity: SprintSetConfiguration.Intensity) -> LinearGradient {
        switch intensity {
        case .low:
            return LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
        case .moderate:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
        case .high:
            return LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        case .maximum:
            return LinearGradient(colors: [.red, .purple], startPoint: .leading, endPoint: .trailing)
        case .supramaximal:
            return LinearGradient(colors: [.purple, .black], startPoint: .leading, endPoint: .trailing)
        }
    }

    /// Get color for session type
    static func colorForSessionType(_ type: SprintSetAndTrainingSession.SessionType) -> Color {
        switch type {
        case .speedDevelopment:
            return .blue
        case .acceleration:
            return .green
        case .maximumVelocity:
            return .orange
        case .speedEndurance:
            return .red
        case .specialEndurance:
            return .purple
        case .technique:
            return .cyan
        case .strength:
            return .brown
        case .recovery:
            return .mint
        case .testing:
            return .indigo
        case .competition:
            return .pink
        }
    }
}

// MARK: - Location Utilities

class LocationUtils {
    static let shared = LocationUtils()

    /// Calculate distance between two coordinates
    static func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }

    /// Format location for display
    static func formatLocation(_ location: CLLocation) -> String {
        let geocoder = CLGeocoder()
        // In a real app, you would reverse geocode to get location name
        return String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }

    /// Check if location is valid for training
    static func isValidTrainingLocation(_ location: CLLocation) -> Bool {
        // Check for reasonable speed, accuracy, and location
        return location.horizontalAccuracy < 100 && // Better than 100m accuracy
               location.speed >= 0 && location.speed <= 15 // Reasonable speed range
    }
}

// MARK: - Data Persistence Utilities

class DataUtils {
    static let shared = DataUtils()

    /// Save data to UserDefaults
    static func saveToUserDefaults<T: Encodable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    /// Load data from UserDefaults
    static func loadFromUserDefaults<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }

    /// Clear all app data
    static func clearAllData() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.hasPrefix("sc40_") {
                defaults.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Notification Utilities

class NotificationUtils {
    static let shared = NotificationUtils()

    /// Format notification time
    static func formatNotificationTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Get notification icon for category
    static func iconForNotificationCategory(_ category: String) -> String {
        switch category {
        case "WORKOUT_REMINDER":
            return "figure.run"
        case "ACHIEVEMENT":
            return "trophy.fill"
        case "CHALLENGE_REMINDER":
            return "flame.fill"
        case "MOTIVATIONAL":
            return "star.fill"
        default:
            return "bell.fill"
        }
    }
}

// MARK: - Validation Utilities

class ValidationUtils {
    static let shared = ValidationUtils()

    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validate password strength
    static func isValidPassword(_ password: String) -> (isValid: Bool, strength: PasswordStrength) {
        let length = password.count >= 8
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasNumber = password.contains(where: { $0.isNumber })
        let hasSpecial = password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })

        let score = [length, hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count

        var strength: PasswordStrength = .weak
        if score >= 4 {
            strength = .strong
        } else if score >= 3 {
            strength = .medium
        }

        return (length && hasUppercase && hasLowercase && hasNumber, strength)
    }

    enum PasswordStrength {
        case weak
        case medium
        case strong
    }
}

// MARK: - String Extensions

extension String {
    /// Capitalize first letter
    func capitalizeFirst() -> String {
        return prefix(1).uppercased() + dropFirst()
    }

    /// Remove whitespace and newlines
    func trimmed() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if string contains only numbers
    func isNumeric() -> Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
}

// MARK: - Double Extensions

extension Double {
    /// Round to specified decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    /// Format as percentage
    func asPercentage() -> String {
        return String(format: "%.1f%%", self * 100)
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe access with default value
    subscript(safe index: Int, default defaultValue: Element) -> Element {
        guard index >= 0, index < count else { return defaultValue }
        return self[index]
    }
}
