import SwiftUI

/// Drills phase view.

struct DrillWatchView: View {
    var workoutVM: WorkoutWatchViewModel
    var body: some View {
        Text("Drills")
    }
}

#Preview {
    DrillWatchView(workoutVM: WorkoutWatchViewModel())
}
