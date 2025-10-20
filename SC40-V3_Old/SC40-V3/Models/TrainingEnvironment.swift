import Foundation
import Combine

enum TrainingEnvironment: String, Codable, CaseIterable, Identifiable {
    case proCoach
    case indoor
    case outdoor
    case hybrid
    
    var id: String { self.rawValue }
    var label: String {
        switch self {
        case .proCoach: return "Pro Coach"
        case .indoor: return "Indoor"
        case .outdoor: return "Outdoor"
        case .hybrid: return "Hybrid"
        }
    }
}
