import Foundation

// Canonical SessionFeedback for fatigue and feedback
public struct SessionFeedback: Codable, Identifiable {
    public let id: UUID
    public let sessionID: UUID
    public let time: Double? // seconds
    public let rpe: Double? // 0-10
    public let sleepHours: Double?
    public let soreness: Double? // 0-10
    public let notes: String?
    
    public init(sessionID: UUID, time: Double? = nil, rpe: Double? = nil, sleepHours: Double? = nil, soreness: Double? = nil, notes: String? = nil) {
        self.id = UUID()
        self.sessionID = sessionID
        self.time = time
        self.rpe = rpe
        self.sleepHours = sleepHours
        self.soreness = soreness
        self.notes = notes
    }
}
