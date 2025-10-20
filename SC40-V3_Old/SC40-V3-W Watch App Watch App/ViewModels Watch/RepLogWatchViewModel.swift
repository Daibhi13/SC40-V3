import Foundation
import Combine

/// Updates rep performance live.
class RepLogWatchViewModel: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()

    @Published var reps: [RepLogWatch] = []
    // TODO: Update rep performance live
}
