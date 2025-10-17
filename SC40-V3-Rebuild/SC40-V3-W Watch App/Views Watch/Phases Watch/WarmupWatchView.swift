import SwiftUI

/// Warmup phase view.

struct WarmupWatchView: View {
    var workoutVM: WorkoutWatchViewModel
    var body: some View {
        Text("Warmup")
    }
}

#Preview {
    WarmupWatchView(workoutVM: WorkoutWatchViewModel())
}
