import Foundation
import Combine

enum TrainingLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    case elite
    
    var id: String { self.rawValue }
    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .elite: return "Elite"
        }
    }
}
