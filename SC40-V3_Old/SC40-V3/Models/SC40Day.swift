import Foundation

struct SC40Day: Codable, Identifiable {
    var id = UUID()
    var dayNumber: Int
    var phases: [SC40Phase]
    var notes: String
}

struct SC40Phase: Codable {
    var distance: Int
    var reps: Int
    var notes: String?
    var phase: String // Changed from SessionType to String to avoid conflicts
}
