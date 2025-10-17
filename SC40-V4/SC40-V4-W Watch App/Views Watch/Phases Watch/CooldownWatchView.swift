import SwiftUI

/// Cooldown phase view.

struct CooldownWatchView: View {
    var workoutVM: WorkoutWatchViewModel
    var body: some View {
        Text("Cooldown")
    }
}

#Preview {
    CooldownWatchView(workoutVM: WorkoutWatchViewModel())
}
