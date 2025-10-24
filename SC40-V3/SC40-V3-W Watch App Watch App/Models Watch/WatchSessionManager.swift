import SwiftUI
import Combine

@MainActor
class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var trainingSessions: [TrainingSession] = []
    @Published var isPhoneConnected = false
    @Published var isPhoneReachable = false
    
    override init() {
        super.init()
    }
}
