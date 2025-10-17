import SwiftUI
import Foundation
#if os(watchOS)
import WatchKit
import Combine
#endif

/// Watch User Profile Model - Separate from main UserProfile to avoid conflicts
struct WatchUserProfile {
    let id: String
    let level: String
    let targetTime: Double
    let authMethod: String
    let joinDate: Date
    
    var displayName: String {
        switch authMethod {
        case "Apple ID":
            return "Apple User"
        case "Guest":
            return "Guest Runner"
        default:
            return "SC40 Athlete"
        }
    }
    
    var levelEmoji: String {
        switch level.lowercased() {
        case "beginner":
            return "🟠"
        case "intermediate":
            return "🟢"
        case "advanced":
            return "🔵"
        case "elite":
            return "🟣"
        default:
            return "🟢"
        }
    }
}
