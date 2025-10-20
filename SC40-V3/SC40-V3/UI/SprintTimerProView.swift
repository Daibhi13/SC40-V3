import SwiftUI

struct SprintTimerProView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDistance: Int = 40
    @State private var selectedReps: Int = 3
    @State private var selectedRestMinutes: Int = 2
    @State private var showWorkout = false
    
    // Distance options (yards)
    private let distanceOptions = [10, 20, 25, 30, 40, 50, 60, 75, 100]
    
    // Reps options
    private let repsOptions = Array(1...10)
    
    // Rest time options (minutes)
    private let restOptions = Array(1...10)
    
    var body: some View {
        ZStack {
            // Same gradient background as MainProgramWorkoutView
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.3, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Sprint Timer Pro")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Pro Header
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.6), radius: 20)
                            
                            Text("SPRINT TIMER PRO")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            Text("Custom Sprint Workouts")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        // Configuration Section
                        VStack(spacing: 24) {
                            // Distance Picker
                            VStack(spacing: 12) {
                                Text("DISTANCE")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1)
                                
                                Picker("Distance", selection: $selectedDistance) {
                                    ForEach(distanceOptions, id: \.self) { distance in
                                        Text("\(distance) YD")
                                            .font(.system(size: 18, weight: .bold))
                                            .tag(distance)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                            
                            // Reps Picker
                            VStack(spacing: 12) {
                                Text("REPETITIONS")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1)
                                
                                Picker("Reps", selection: $selectedReps) {
                                    ForEach(repsOptions, id: \.self) { reps in
                                        Text("\(reps) REP\(reps == 1 ? "" : "S")")
                                            .font(.system(size: 18, weight: .bold))
                                            .tag(reps)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                            
                            // Rest Time Picker
                            VStack(spacing: 12) {
                                Text("REST TIME")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1)
                                
                                Picker("Rest", selection: $selectedRestMinutes) {
                                    ForEach(restOptions, id: \.self) { rest in
                                        Text("\(rest) MIN\(rest == 1 ? "" : "S")")
                                            .font(.system(size: 18, weight: .bold))
                                            .tag(rest)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Workout Preview
                        VStack(spacing: 16) {
                            Text("WORKOUT PREVIEW")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(1)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "figure.run")
                                        .font(.system(size: 20))
                                        .foregroundColor(.yellow)
                                    
                                    Text("\(selectedReps) × \(selectedDistance) Yard Sprints")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange)
                                    
                                    Text("\(selectedRestMinutes) minute\(selectedRestMinutes == 1 ? "" : "s") rest between reps")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "timer")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                    
                                    let totalTime = (selectedReps * selectedRestMinutes) + 10 // Approximate
                                    Text("~\(totalTime) minute workout")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Start Workout Button
                        Button(action: {
                            showWorkout = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 20, weight: .bold))
                                Text("START CUSTOM WORKOUT")
                                    .font(.system(size: 18, weight: .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.yellow,
                                        Color.orange
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showWorkout) {
            SprintTimerProWorkoutView(
                distance: selectedDistance,
                reps: selectedReps,
                restMinutes: selectedRestMinutes
            )
        }
    }
}

#Preview {
    SprintTimerProView()
}
