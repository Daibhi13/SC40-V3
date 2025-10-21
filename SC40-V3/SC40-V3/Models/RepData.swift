import Foundation

// MARK: - Rep Data Model for Workout Tracking
struct RepData: Identifiable, Codable, Equatable {
    let id = UUID()
    let rep: Int
    let time: Double?
    let isCompleted: Bool
    let repType: RepType
    let distance: Int
    let timestamp: Date
    
    // Additional properties for compatibility
    var speed: Double? {
        guard let time = time, time > 0 else { return nil }
        // Convert to mph: distance in yards to miles, time in seconds to hours
        let distanceMiles = Double(distance) / 1760.0
        let timeHours = time / 3600.0
        return distanceMiles / timeHours
    }
    
    enum RepType: String, Codable, CaseIterable {
        case drill = "drill"
        case stride = "stride" 
        case sprint = "sprint"
        case warmup = "warmup"
        case cooldown = "cooldown"
        
        var displayName: String {
            switch self {
            case .drill: return "Drill"
            case .stride: return "Stride"
            case .sprint: return "Sprint"
            case .warmup: return "Warm-up"
            case .cooldown: return "Cool-down"
            }
        }
        
        var color: String {
            switch self {
            case .drill: return "blue"
            case .stride: return "purple"
            case .sprint: return "green"
            case .warmup: return "orange"
            case .cooldown: return "cyan"
            }
        }
    }
    
    // Initializer for compatibility
    init(rep: Int, time: Double?, isCompleted: Bool, repType: RepType, distance: Int, timestamp: Date) {
        self.rep = rep
        self.time = time
        self.isCompleted = isCompleted
        self.repType = repType
        self.distance = distance
        self.timestamp = timestamp
    }
    
    // Legacy initializer for MainProgramWorkoutView compatibility
    init(type: RepType, rep: Int, distance: Int, time: Double, speed: Double, timestamp: Date) {
        self.rep = rep
        self.time = time
        self.isCompleted = true
        self.repType = type
        self.distance = distance
        self.timestamp = timestamp
    }
    
    static func == (lhs: RepData, rhs: RepData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Extensions for Workout Analysis
extension RepData {
    var formattedTime: String {
        guard let time = time else { return "N/A" }
        return String(format: "%.2fs", time)
    }
    
    var formattedSpeed: String {
        guard let speed = speed else { return "N/A" }
        return String(format: "%.1f mph", speed)
    }
    
    var isPersonalBest: Bool {
        // This could be enhanced to check against historical data
        guard let time = time else { return false }
        return time < 5.0 // Example threshold
    }
}
