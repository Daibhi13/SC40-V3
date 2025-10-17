import Foundation

enum TrainingLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    case pro
    
    var id: String { self.rawValue }
    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .pro: return "Pro"
        }
    }
}
