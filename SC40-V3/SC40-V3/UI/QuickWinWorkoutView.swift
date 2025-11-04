import SwiftUI

struct QuickWinWorkoutView: View {
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var isActive = false
    @State private var timeRemaining = 30
    @State private var timer: Timer?
    
    private let workoutSteps = [
        "Get ready to start!",
        "High knees - 30 seconds",
        "Butt kicks - 30 seconds", 
        "Arm circles - 30 seconds",
        "Light jog in place - 30 seconds",
        "Great job! You're done!"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Progress indicator
            ProgressView(value: Double(currentStep), total: Double(workoutSteps.count - 1))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Current step
            VStack(spacing: 16) {
                Text("Step \(currentStep + 1) of \(workoutSteps.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(workoutSteps[currentStep])
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Timer (only show during active steps)
            if currentStep > 0 && currentStep < workoutSteps.count - 1 {
                VStack(spacing: 8) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("seconds remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action button
            Button(action: handleButtonTap) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Quick Win Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var buttonText: String {
        switch currentStep {
        case 0:
            return "Start Workout"
        case workoutSteps.count - 1:
            return "Complete"
        default:
            return isActive ? "Skip" : "Next"
        }
    }
    
    private var buttonColor: Color {
        switch currentStep {
        case 0:
            return .blue
        case workoutSteps.count - 1:
            return .green
        default:
            return isActive ? .orange : .blue
        }
    }
    
    private func handleButtonTap() {
        if currentStep == 0 {
            // Start workout
            nextStep()
        } else if currentStep == workoutSteps.count - 1 {
            // Complete workout
            onComplete()
        } else {
            // Skip or next
            nextStep()
        }
    }
    
    private func nextStep() {
        timer?.invalidate()
        
        if currentStep < workoutSteps.count - 1 {
            currentStep += 1
            
            // Start timer for exercise steps (not first or last)
            if currentStep > 0 && currentStep < workoutSteps.count - 1 {
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        timeRemaining = 30
        isActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                isActive = false
                nextStep()
            }
        }
    }
}

#Preview {
    NavigationView {
        QuickWinWorkoutView {
            print("Workout completed!")
        }
    }
}
