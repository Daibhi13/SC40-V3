import SwiftUI

/// Rest phase view.

struct RestWatchView: View {
    var workoutVM: WorkoutWatchViewModel
    var body: some View {
        Text("Rest")
    }
}

#Preview {
    RestWatchView(workoutVM: WorkoutWatchViewModel())
}
