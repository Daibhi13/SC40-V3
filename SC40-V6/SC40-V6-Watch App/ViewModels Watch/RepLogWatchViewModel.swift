import Foundation
import Combine

class RepLogWatchViewModel: ObservableObject {
    @Published var reps: [RepLogWatch] = []
    private var cancellables = Set<AnyCancellable>()

    func updateReps(_ newReps: [RepLogWatch]) {
        DispatchQueue.main.async {
            self.reps = newReps
        }
    }
}
