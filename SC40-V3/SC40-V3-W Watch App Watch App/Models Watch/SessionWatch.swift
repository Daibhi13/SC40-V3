import Foundation

/// Represents a workout session on the Watch.
struct SessionWatch: Identifiable {
    let id = UUID()
    let week: Int
    let day: Int
    let totalDuration: TimeInterval
    let reps: Int
    let distances: [Double]
    let rest: TimeInterval
    // TODO: Add additional properties if needed
}
