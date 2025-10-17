import Foundation
import Combine

// Results data structure for completed training sessions
public struct SessionResults: Codable, Sendable {
    public let sprintTimes: [Double]
    public let personalBest: Double?
    public let averageTime: Double?
    public let rpe: Int? // Rate of Perceived Exertion (1-10)
    public let weatherCondition: String?
    public let temperature: Double?
    public let location: String?
    
    public init(
        sprintTimes: [Double],
        personalBest: Double? = nil,
        averageTime: Double? = nil,
        rpe: Int? = nil,
        weatherCondition: String? = nil,
        temperature: Double? = nil,
        location: String? = nil
    ) {
        self.sprintTimes = sprintTimes
        self.personalBest = personalBest ?? sprintTimes.min()
        self.averageTime = averageTime ?? (sprintTimes.isEmpty ? nil : sprintTimes.reduce(0, +) / Double(sprintTimes.count))
        self.rpe = rpe
        self.weatherCondition = weatherCondition
        self.temperature = temperature
        self.location = location
    }
}
