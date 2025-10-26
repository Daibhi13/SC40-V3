import SwiftUI

struct SprintTimerProWatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDistance = 40
    @State private var selectedSets = 3
    @State private var selectedRest = 2 // in minutes
    @State private var showWorkout = false
    
    // Distance options (yards) - Match phone app
    private let distanceOptions = [10, 20, 25, 30, 40, 50, 60, 75, 100]
    
    // Sets options - Match phone app (called reps on phone)
    private let setsOptions = Array(1...10)
    
    // Rest options (minutes) - Match phone app
    private let restOptions = Array(1...10)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Compact header
                    compactHeader
                    
                    // Ultra-compact SIT-style layout
                    VStack(spacing: 0) {
                        sitStylePickers
                            .padding(.top, 8)
                        
                        // Start button (remove summary to save space)
                        startButtonOnly
                            .padding(.top, 16)
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showWorkout) {
            SprintTimerProWorkoutView(
                distance: selectedDistance,
                sets: selectedSets,
                restMinutes: selectedRest
            )
        }
    }
    
    // MARK: - Minimal Header (SIT Style)
    private var compactHeader: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.yellow)
            
            Spacer()
            
            // Remove title to save space - context is clear from usage
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    // MARK: - Phone App Style Pickers (Adapted for Watch)
    private var sitStylePickers: some View {
        VStack(spacing: 8) {
            // Distance Picker Row - Match phone app terminology
            HStack {
                Text("DISTANCE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                Picker("Distance", selection: $selectedDistance) {
                    ForEach(distanceOptions, id: \.self) { distance in
                        Text("\(distance) YD")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 40)
                .clipped()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Reps Picker Row - Match phone app terminology
            HStack {
                Text("REPS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                Picker("Reps", selection: $selectedSets) {
                    ForEach(setsOptions, id: \.self) { reps in
                        Text("\(reps) REP\(reps == 1 ? "" : "S")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 40)
                .clipped()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Rest Time Picker Row - Match phone app terminology
            HStack {
                Text("REST TIME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                Picker("Rest", selection: $selectedRest) {
                    ForEach(restOptions, id: \.self) { rest in
                        Text("\(rest) MIN\(rest == 1 ? "" : "S")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70, height: 40)
                .clipped()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Compact Workout Summary
    private var workoutSummary: some View {
        VStack(spacing: 6) {
            Text("\(selectedSets) × \(selectedDistance)yd • \(selectedRest)min rest")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
            
            Text("Est. Duration: \(estimatedDuration) min")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Phone App Style Start Button
    private var startButtonOnly: some View {
        Button(action: {
            print("🎯 SprintTimer Pro starting workout with: Distance=\(selectedDistance)yd, Sets=\(selectedSets), Rest=\(selectedRest)min")
            showWorkout = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 16, weight: .bold))
                
                Text("START WORKOUT")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Computed Properties
    private var estimatedDuration: Int {
        let sprintTime = selectedSets * 30 // 30 seconds per sprint (estimate)
        let restTime = (selectedSets - 1) * selectedRest * 60 // rest between sets
        let warmupCooldown = 300 // 5 minutes
        
        return (sprintTime + restTime + warmupCooldown) / 60
    }
}

#Preview("Sprint Timer Pro Watch") {
    SprintTimerProWatchView()
        .preferredColorScheme(.dark)
}
