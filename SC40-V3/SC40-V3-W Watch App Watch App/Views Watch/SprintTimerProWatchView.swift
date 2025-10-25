import SwiftUI

struct SprintTimerProWatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDistance = 40
    @State private var selectedSets = 3
    @State private var selectedRest = 2 // in minutes
    @State private var showWorkout = false
    
    // Distance options (yards)
    private let distanceOptions = [20, 30, 40, 50, 60, 75, 100]
    
    // Sets options
    private let setsOptions = [1, 2, 3, 4, 5, 6, 8]
    
    // Rest options (minutes)
    private let restOptions = [1, 2, 3, 4, 5]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // 3-Choice Picker (SIT app style)
                pickerSection
                
                // Workout Preview
                workoutPreview
                
                // Start Button
                startButton
            }
            .background(Color.black)
            .navigationTitle("Sprint Timer Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
        .fullScreenCover(isPresented: $showWorkout) {
            SprintTimerProWorkoutView(
                distance: selectedDistance,
                sets: selectedSets,
                restMinutes: selectedRest
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Custom Sprint Workout")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - 3-Choice Picker Section (SIT App Style)
    private var pickerSection: some View {
        VStack(spacing: 12) {
            // Distance Picker
            VStack(spacing: 4) {
                Text("Distance")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    Picker("Distance", selection: $selectedDistance) {
                        ForEach(distanceOptions, id: \.self) { distance in
                            Text("\(distance)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    #if os(watchOS)
                    .pickerStyle(.wheel)
                    #else
                    .pickerStyle(.menu)
                    #endif
                    .frame(width: 60, height: 60)
                    .clipped()
                    
                    Text("YD")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
            }
            
            // Sets Picker
            VStack(spacing: 4) {
                Text("Sets")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    Picker("Sets", selection: $selectedSets) {
                        ForEach(setsOptions, id: \.self) { sets in
                            Text("\(sets)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    #if os(watchOS)
                    .pickerStyle(.wheel)
                    #else
                    .pickerStyle(.menu)
                    #endif
                    .frame(width: 60, height: 60)
                    .clipped()
                    
                    Text("SETS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
            }
            
            // Rest Picker
            VStack(spacing: 4) {
                Text("Rest")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    Picker("Rest", selection: $selectedRest) {
                        ForEach(restOptions, id: \.self) { rest in
                            Text("\(rest)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    #if os(watchOS)
                    .pickerStyle(.wheel)
                    #else
                    .pickerStyle(.menu)
                    #endif
                    .frame(width: 60, height: 60)
                    .clipped()
                    
                    Text("MIN")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Workout Preview
    private var workoutPreview: some View {
        VStack(spacing: 8) {
            Text("Workout Preview")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 4) {
                Text("\(selectedSets) × \(selectedDistance) Yard Sprints")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(selectedRest) min rest between sets")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Est. Duration: \(estimatedDuration) min")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            showWorkout = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                
                Text("START SPRINT")
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
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
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
