import SwiftUI

struct SprintTimerProWatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDistance = 40
    @State private var selectedSets = 3
    @State private var selectedRest = 2 // in minutes
    @State private var showWorkout = false
    @State private var showDistancePicker = false
    @State private var showSetsPicker = false
    @State private var showRestPicker = false
    
    // Distance options (yards) - Match phone app
    private let distanceOptions = [10, 20, 25, 30, 40, 50, 60, 75, 100]
    
    // Sets options - Match phone app (called reps on phone)
    private let setsOptions = Array(1...10)
    
    // Rest options (minutes) - Match phone app
    private let restOptions = Array(1...10)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Minimalist header
                sitHeader
                
                // Clean settings with better spacing
                VStack(spacing: 16) {
                    sitSettingsRows
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Workout summary
                workoutSummary
                    .padding(.top, 16)
                
                Spacer(minLength: 24)
                
                // Enhanced start button
                sitStartButton
                    .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showWorkout) {
            SprintTimerProWorkoutView(
                distance: selectedDistance,
                sets: selectedSets,
                restMinutes: selectedRest
            )
        }
        .sheet(isPresented: $showDistancePicker) {
            sitPickerSheet(
                title: "Distance",
                options: distanceOptions,
                selectedValue: $selectedDistance,
                formatter: { "\($0) YD" }
            )
        }
        .sheet(isPresented: $showSetsPicker) {
            sitPickerSheet(
                title: "Sets",
                options: setsOptions,
                selectedValue: $selectedSets,
                formatter: { "\($0)" }
            )
        }
        .sheet(isPresented: $showRestPicker) {
            sitPickerSheet(
                title: "Rest Time",
                options: restOptions,
                selectedValue: $selectedRest,
                formatter: { "\($0) MIN" }
            )
        }
    }
    
    // MARK: - Polished Header
    private var sitHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 30, height: 30)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            
            Spacer()
            
            Text(currentTime)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Enhanced Settings Rows
    private var sitSettingsRows: some View {
        VStack(spacing: 14) {
            // Distance Row
            sitSettingRow(
                label: "Distance",
                value: "\(selectedDistance)",
                unit: "YD",
                color: .green,
                action: { showDistancePicker = true }
            )
            
            // Sets Row
            sitSettingRow(
                label: "Sets",
                value: "\(selectedSets)",
                unit: "reps",
                color: .green,
                action: { showSetsPicker = true }
            )
            
            // Rest Row
            sitSettingRow(
                label: "Rest",
                value: "\(selectedRest)",
                unit: "min",
                color: .green,
                action: { showRestPicker = true }
            )
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Clean Setting Row (No Icons)
    private func sitSettingRow(
        label: String,
        value: String,
        unit: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                // Label
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Value and unit inline
                HStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Workout Summary
    private var workoutSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "stopwatch")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.yellow)
                
                Text("Total: \(selectedSets * selectedDistance) yards • ~\(estimatedDuration) min")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Enhanced Start Button
    private var sitStartButton: some View {
        Button(action: {
            print("SprintTimer Pro starting workout with: Distance=\(selectedDistance)yd, Sets=\(selectedSets), Rest=\(selectedRest)min")
            showWorkout = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                
                Text("START WORKOUT")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(0.8)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.0),
                            Color(red: 1.0, green: 0.65, blue: 0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .cornerRadius(16)
            .shadow(color: Color.yellow.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Enhanced Picker Sheet
    private func sitPickerSheet<T: Hashable>(
        title: String,
        options: [T],
        selectedValue: Binding<T>,
        formatter: @escaping (T) -> String
    ) -> some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced header
                HStack {
                    Button("Back") {
                        // Dismiss the appropriate picker
                        if title == "Distance" { showDistancePicker = false }
                        else if title == "Sets" { showSetsPicker = false }
                        else if title == "Rest Time" { showRestPicker = false }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        // Dismiss the appropriate picker
                        if title == "Distance" { showDistancePicker = false }
                        else if title == "Sets" { showSetsPicker = false }
                        else if title == "Rest Time" { showRestPicker = false }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.yellow)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
                
                // Enhanced picker
                Picker(title, selection: selectedValue) {
                    ForEach(options, id: \.self) { option in
                        Text(formatter(option))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed Properties
    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    private var estimatedDuration: Int {
        let sprintTime = selectedSets * 15 // 15 seconds per sprint (realistic)
        let restTime = (selectedSets - 1) * selectedRest * 60 // rest between sets
        let setupTime = 120 // 2 minutes setup
        
        return max(1, (sprintTime + restTime + setupTime) / 60)
    }
}

#Preview("Sprint Timer Pro Watch") {
    SprintTimerProWatchView()
        .preferredColorScheme(.dark)
}
