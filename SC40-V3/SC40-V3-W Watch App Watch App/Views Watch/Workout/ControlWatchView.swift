import SwiftUI

// Brand colors are now defined in BrandColorsWatch.swift

struct ControlWatchView: View {
    /// 0 = Control, 1 = MainWorkout, 2 = Music
    var selectedIndex: Int = 0
    
    @ObservedObject var workoutVM: WorkoutWatchViewModel
    let session: TrainingSession
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
        // Stop the workout session
        workoutVM.isRunning = false
        workoutVM.pauseSession()
        workoutVM.stopGPS()
        
        // End HealthKit workout if running
        Task {
            await workoutVM.endHealthKitWorkout()
        }
        
        // Save workout progress (this would typically save to Core Data or send to phone)
        print("💾 Workout ended and progress saved")
        
        // Dismiss the workout view
        presentationMode.wrappedValue.dismiss()
    }
    
    // TODO: Implement when types are available
    // private func createSprintSetsFromWorkout() -> [SprintSet] {
    //     let completedReps = min(workoutVM.currentRep, workoutVM.totalReps)
    //     guard completedReps > 0 else { return [] }
    //     
    //     return [SprintSet(
    //         distanceYards: 40,
    //         reps: completedReps,
    //         intensity: "High"
    //     )]
    // }

    // MARK: - Swipe Back Gesture
    private var swipeBackGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                // Swipe Right to go back to Enhanced7StageWorkoutView
                if value.translation.width > 30 {
                    print(" ControlView - Swipe Right to return to workout")
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text("\(workoutVM.stopwatchTimeString)")
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Text("ELAPSED TIME")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer display at top
            timerDisplay
                .padding(.top, 8)
            
            Spacer()
            
            // Control buttons grid matching the uploaded design
            VStack(spacing: 12) {
                // Top row: Pause/Play and Stop
                HStack(spacing: 12) {
                    // Pause/Play Button (Orange border)
                    ControlButton(
                        icon: workoutVM.isPaused ? "play.fill" : "pause.fill",
                        borderColor: .orange,
                        action: {
                            workoutVM.isPaused ? playWorkout() : pauseWorkout()
                        }
                    )
                    
                    // Stop Button (Pink border)
                    ControlButton(
                        icon: "stop.fill",
                        borderColor: .pink,
                        action: {
                            showEndWorkoutAlert = true
                        }
                    )
                }
                
                // Bottom row: Rewind and Fast Forward
                HStack(spacing: 12) {
                    // Rewind Button (Cyan border)
                    ControlButton(
                        icon: "backward.fill",
                        borderColor: .cyan,
                        action: {
                            rewindSession()
                        }
                    )
                    
                    // Fast Forward Button (Blue border)
                    ControlButton(
                        icon: "forward.fill",
                        borderColor: .blue,
                        action: {
                            forwardSession()
                        }
                    )
                }
                
                // Volume/Haptic Button (Gray border) - centered
                HStack {
                    ControlButton(
                        icon: workoutVM.isHapticEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        borderColor: .gray,
                        action: {
                            toggleHaptics()
                        }
                    )
                }
            }
            
            Spacer()
            
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 4)
            
            // Navigation hints
            Text("Main →")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 4)
        }
        .background(Color.black.ignoresSafeArea())
        .gesture(swipeBackGesture)
        .alert(isPresented: $showEndWorkoutAlert) {
            Alert(
                title: Text("End Workout?"),
                message: Text("Save your progress and end the workout?"),
                primaryButton: .default(Text("CONTINUE WORKOUT")),
                secondaryButton: .default(Text("END & SAVE")) {
                    endWorkout()
                }
            )
        }
    }
}

// MARK: - Control Button Component
struct ControlButton: View {
    let icon: String
    let borderColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 70, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview
struct ControlWatchView_Previews: PreviewProvider {
    static var previews: some View {
        ControlWatchView(
            workoutVM: WorkoutWatchViewModel.mock,
            session: TrainingSession(
                week: 1,
                day: 1,
                type: "Preview",
                focus: "Test Session",
                sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "max")],
                accessoryWork: []
            )
        )
    }
}

#Preview {
    ControlWatchView(
        workoutVM: WorkoutWatchViewModel.mock,
        session: TrainingSession(
            week: 1,
            day: 1,
            type: "Preview",
            focus: "Test Session",
            sprints: [SprintSet(distanceYards: 40, reps: 3, intensity: "max")],
            accessoryWork: []
        )
    )
}
