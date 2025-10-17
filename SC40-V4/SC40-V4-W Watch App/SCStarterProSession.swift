import Foundation

/// The SC StarterPro Training Session Model
struct SCStarterProSessionWatch: Identifiable, Codable {
    var id: UUID = UUID()
    var numReps: Int
    var restInterval: TimeInterval // seconds
    var customWarmUp: [SCStarterProPhase]?
    var customCoolDown: [SCStarterProPhase]?
    var phases: [SCStarterProPhase]
    
    init(numReps: Int, restInterval: TimeInterval, customWarmUp: [SCStarterProPhase]? = nil, customCoolDown: [SCStarterProPhase]? = nil) {
        self.numReps = numReps
        self.restInterval = restInterval
        self.customWarmUp = customWarmUp
        self.customCoolDown = customCoolDown
        self.phases = SCStarterProSessionWatch.defaultPhases(numReps: numReps, restInterval: restInterval, customWarmUp: customWarmUp, customCoolDown: customCoolDown)
    }
    
    static func defaultPhases(numReps: Int, restInterval: TimeInterval, customWarmUp: [SCStarterProPhase]? = nil, customCoolDown: [SCStarterProPhase]? = nil) -> [SCStarterProPhase] {
        var phases: [SCStarterProPhase] = []
        // Warm-up
        phases.append(.warmup(duration: 180)) // 3 min jog
        phases.append(.mobility)
        phases.append(.drill(name: "A-skips"))
        phases.append(.drill(name: "B-skips"))
        phases.append(.strides(count: 3, distance: 20, intensity: 0.7))
        phases.append(.stretch(targets: ["Hamstrings", "Quads", "Hip Flexors", "Calves"]))
        // Drills
        phases.append(.chooseDrill)
        phases.append(.strides(count: 2, distance: 20, intensity: 0.9))
        // 40-Yard Time Trial Block
        for i in 1...numReps {
            phases.append(.starterCue(rep: i))
            phases.append(.sprint40yd(rep: i))
            phases.append(.rest(duration: restInterval, rep: i))
        }
        // Warm-down
        phases.append(.warmdown(duration: 120)) // 2 min jog
        phases.append(.stretch(targets: ["Hamstrings", "Quads", "Hip Flexors", "Calves"]))
        // Custom warmup/cooldown
        if let customWarmUp = customWarmUp {
            phases.insert(contentsOf: customWarmUp, at: 0)
        }
        if let customCoolDown = customCoolDown {
            phases.append(contentsOf: customCoolDown)
        }
        return phases
    }
}

enum SCStarterProPhase: Codable, Identifiable {
    case warmup(duration: TimeInterval)
    case mobility
    case drill(name: String)
    case strides(count: Int, distance: Int, intensity: Double)
    case stretch(targets: [String])
    case chooseDrill
    case starterCue(rep: Int)
    case sprint40yd(rep: Int)
    case rest(duration: TimeInterval, rep: Int)
    case warmdown(duration: TimeInterval)
    
    var id: String {
        switch self {
        case .warmup: return "warmup"
        case .mobility: return "mobility"
        case .drill(let name): return "drill_\(name)"
        case .strides(let count, let distance, _): return "strides_\(count)_\(distance)"
        case .stretch(let targets): return "stretch_\(targets.joined(separator: ","))"
        case .chooseDrill: return "chooseDrill"
        case .starterCue(let rep): return "starterCue_\(rep)"
        case .sprint40yd(let rep): return "sprint40yd_\(rep)"
        case .rest(_, let rep): return "rest_\(rep)"
        case .warmdown: return "warmdown"
        }
    }
}
