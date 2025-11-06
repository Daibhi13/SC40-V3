import SwiftUI

struct RepLogSummaryFlowView: View {
    @ObservedObject var workoutVM: WorkoutWatchViewModel
    @State private var showSummary = false
    var onDone: (() -> Void)? = nil

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.brandBackground, Color.brandTertiary.opacity(0.18)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                if !showSummary {
                    RepLogWatchLiveView(
                        workoutVM: workoutVM,
                        horizontalTab: .constant(0),
                        isModal: true,
                        showNext: true,
                        onNext: { showSummary = true },
                        session: TrainingSession(
                            week: 1,
                            day: 1,
                            type: "Summary",
                            focus: "Workout Complete",
                            sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
                            accessoryWork: []
                        )
                    )
                } else {
                    SummaryReportView(onDone: onDone, showClose: true)
                }
            }
        }
    }
}

// Preview for Canvas
#Preview {
    // Create a mock workoutVM for preview
    RepLogSummaryFlowView(workoutVM: WorkoutWatchViewModel())
}
