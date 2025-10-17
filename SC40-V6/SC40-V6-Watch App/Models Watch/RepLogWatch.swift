import Foundation

/// Represents a single rep log entry on the Watch.
struct RepLogWatch: Identifiable {
    let id = UUID()
    let repNumber: Int
    let distance: Double
    let gpsTime: Date
    let splitTime: TimeInterval
    // TODO: Add additional properties if needed
}
