import Foundation

enum SessionType: String, Codable, CaseIterable, Identifiable, Hashable {
    case pro
    case faster40
    case hybrid
    case recovery
    case custom
    // Added missing cases for library compatibility
    case acceleration
    case transition
    case maxVelocity
    case combinePrep
    
    var id: String { self.rawValue }
}
