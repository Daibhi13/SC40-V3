import Foundation

/// Represents a single rep log entry on the Watch.
public struct RepLogWatch: Codable, Identifiable {
    public let id: UUID
    public let repNumber: Int
    public let distance: Double
    public let gpsTime: Date
    public let splitTime: TimeInterval
    
    public init(repNumber: Int, distance: Double, gpsTime: Date, splitTime: TimeInterval) {
        self.id = UUID()
        self.repNumber = repNumber
        self.distance = distance
        self.gpsTime = gpsTime
        self.splitTime = splitTime
    }
}
