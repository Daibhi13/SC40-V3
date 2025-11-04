import SwiftUI

/// Sprint phase view.

struct SprintPhaseWatchView: View {
    var workoutVM: WorkoutWatchViewModel
    var body: some View {
        Text("Sprint Phase")
    }
}

#Preview {
    SprintPhaseWatchView(workoutVM: WorkoutWatchViewModel())
}
