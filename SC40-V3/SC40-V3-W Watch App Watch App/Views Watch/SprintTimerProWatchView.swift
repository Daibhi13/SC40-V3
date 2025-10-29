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
        VStack(spacing: 0) {
            // SIT-style header
            sitHeader
            
            // SIT-style compact settings
            VStack(spacing: 12) {
                sitSettingsRows
            }
            .padding(.top, 20)
            
            Spacer()
            
            // SIT-style start button
            sitStartButton
                .padding(.bottom, 20)
        }
        .background(Color.black)
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
    
    // MARK: - SIT Style Header
    private var sitHeader: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.yellow)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.yellow.opacity(0.15))
            )
            
            Spacer()
            
            Text("SIT Settings")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(currentTime)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - SIT Style Settings Rows
    private var sitSettingsRows: some View {
        VStack(spacing: 12) {
            // Distance Row - SIT Style
            sitSettingRow(
                label: "Distance",
                value: "\(selectedDistance) YD",
                color: .green,
                action: { showDistancePicker = true }
            )
            
            // Sets Row - SIT Style  
            sitSettingRow(
                label: "Sets",
                value: "\(selectedSets)",
                color: .green,
                action: { showSetsPicker = true }
            )
            
            // Rest Row - SIT Style
            sitSettingRow(
                label: "Rest",
                value: String(format: "%02d:%02d", selectedRest, 0),
                color: .green,
                action: { showRestPicker = true }
            )
            
            // Sounds Toggle - SIT Style
            sitToggleRow(
                label: "Sounds on",
                isOn: .constant(true)
            )
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - SIT Style Setting Row
    private func sitSettingRow(label: String, value: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
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
    
    // MARK: - SIT Style Toggle Row
    private func sitToggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
    }
    
    // MARK: - SIT Style Start Button
    private var sitStartButton: some View {
        Button(action: {
            print("🎯 SprintTimer Pro starting workout with: Distance=\(selectedDistance)yd, Sets=\(selectedSets), Rest=\(selectedRest)min")
            showWorkout = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 18, weight: .bold))
                
                Text("START WORKOUT")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - SIT Style Picker Sheet
    private func sitPickerSheet<T: Hashable>(
        title: String,
        options: [T],
        selectedValue: Binding<T>,
        formatter: @escaping (T) -> String
    ) -> some View {
        NavigationView {
            VStack {
                Picker(title, selection: selectedValue) {
                    ForEach(options, id: \.self) { option in
                        Text(formatter(option))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                .background(Color.black)
            }
            .background(Color.black)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Dismiss the appropriate picker
                        if title == "Distance" { showDistancePicker = false }
                        else if title == "Sets" { showSetsPicker = false }
                        else if title == "Rest Time" { showRestPicker = false }
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
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
