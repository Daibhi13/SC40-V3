import SwiftUI

// Brand colors are now defined in BrandColorsWatch.swift

struct ControlWatchView: View {
    /// 0 = Control, 1 = MainWorkout, 2 = Music
    var selectedIndex: Int = 0
    
    @ObservedObject var workoutVM: WorkoutWatchViewModel
    @State private var showEndWorkoutAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    private func pauseWorkout() {
        workoutVM.isPaused = true
        // Pause any running timers or GPS tracking
        workoutVM.pauseSession()
    }
    
    private func playWorkout() {
        workoutVM.isPaused = false
        // Resume any paused timers or GPS tracking
        workoutVM.resumeSession()
    }
    
    private func rewindSession() {
        // Go back to previous rep or phase
        workoutVM.goToPreviousStep()
    }
    
    private func forwardSession() {
        // Move forward to next rep or phase
        workoutVM.goToNextStep()
    }
    

    private func toggleHaptics() {
        // Toggle haptic feedback on/off
        workoutVM.toggleHapticFeedback()
    }
    
    private func endWorkout() {
        // TODO: Properly end the workout session
        // workoutVM.endWorkout() // Method doesn't exist yet
        
        // Dismiss the workout view
        presentationMode.wrappedValue.dismiss()
    }
    
    // TODO: Implement when types are available
    // private func createWatchSprintSetsFromWorkout() -> [WatchSprintSet] {
    //     let completedReps = min(workoutVM.currentRep, workoutVM.totalReps)
    //     guard completedReps > 0 else { return [] }
    //     
    //     return [WatchSprintSet(
    //         distanceYards: 40,
    //         reps: completedReps,
    //         intensity: "High"
    //     )]
    // }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.18)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                // Top Row: Pause/Play and End Workout
                HStack(spacing: 16) {
                    Button(action: { workoutVM.isPaused ? playWorkout() : pauseWorkout() }) {
                        Image(systemName: workoutVM.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                            .frame(width: 38, height: 38)
                            .background(Circle().stroke(Color(red: 0.1, green: 0.1, blue: 0.15), lineWidth: 2))
                    }
                    Button(action: { showEndWorkoutAlert = true }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .frame(width: 38, height: 38)
                            .background(Circle().stroke(Color(red: 1.0, green: 0.8, blue: 0.0), lineWidth: 2))
                    }
                }
                

                
                // Navigation Controls: Sprint Start/Stop and Rep Navigation
                HStack(spacing: 16) {
                    // Previous/Back Button - also functions as Sprint START when not running
                    Button(action: { 
                        if !workoutVM.isRunning {
                            // Start current sprint rep
                            workoutVM.startRep()
                        } else {
                            // Go back to previous rep or phase
                            workoutVM.goToPreviousStep()
                        }
                    }) {
                        Image(systemName: workoutVM.isRunning ? "backward.fill" : "play.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(workoutVM.isRunning ? Color(red: 0.95, green: 0.95, blue: 0.95) : Color.green)
                            .frame(width: 38, height: 38)
                            .background(Circle().stroke(workoutVM.isRunning ? Color(red: 0.95, green: 0.95, blue: 0.95) : Color.green, lineWidth: 2))
                    }
                    
                    // Forward/Next Button - also functions as Sprint STOP when running
                    Button(action: { 
                        if workoutVM.isRunning {
                            // Complete current sprint rep
                            workoutVM.completeCurrentRep()
                        } else {
                            // Move forward to next rep or phase
                            workoutVM.goToNextStep()
                        }
                    }) {
                        Image(systemName: workoutVM.isRunning ? "stop.circle.fill" : "forward.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(workoutVM.isRunning ? Color.red : Color(red: 0.2, green: 0.8, blue: 1.0))
                            .frame(width: 38, height: 38)
                            .background(Circle().stroke(workoutVM.isRunning ? Color.red : Color(red: 0.2, green: 0.8, blue: 1.0), lineWidth: 2))
                    }
                }
                Spacer(minLength: 4)
                // Haptic Feedback Toggle and Reset Control
                HStack(spacing: 16) {
                    // Haptic Toggle
                    Button(action: { toggleHaptics() }) {
                        Image(systemName: workoutVM.isHapticEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.05, green: 0.05, blue: 0.1))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(workoutVM.isHapticEnabled ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color(red: 0.2, green: 0.8, blue: 1.0)))
                    }
                    
                    // Reset Current Rep
                    Button(action: { 
                        // Reset current rep data
                        workoutVM.isRunning = false
                        workoutVM.stopGPS()
                        workoutVM.currentRepTime = 0
                        workoutVM.distanceTraveled = 0
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .frame(width: 34, height: 34)
                            .background(Circle().stroke(Color(red: 0.95, green: 0.95, blue: 0.95), lineWidth: 2))
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .alert(isPresented: $showEndWorkoutAlert) {
            Alert(
                title: Text("End Workout?").foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)),
                message: Text("Save your progress and end the workout?"),
                primaryButton: .default(Text("CONTINUE WORKOUT")),
                secondaryButton: .default(Text("END & SAVE")) {
                    endWorkout()
                }
            )
        }
    }
// MARK: - Preview
struct ControlWatchView_Previews: PreviewProvider {
    static var previews: some View {
        ControlWatchView(workoutVM: WorkoutWatchViewModel.mock)
    }
}
}

#Preview {
    ControlWatchView(workoutVM: WorkoutWatchViewModel.mock)
}
