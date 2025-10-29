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
                // SC40 Premium header
                sc40Header
                
                // SC40 Sprint configuration
                VStack(spacing: 16) {
                    sc40SettingsSection
                    sc40WorkoutPreview
                }
                .padding(.top, 24)
                
                // SC40 start button
                sc40StartButton
                    .padding(.top, 32)
                    .padding(.bottom, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25),
                    Color.black
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
    
    // MARK: - SC40 Premium Header
    private var sc40Header: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Text("SPRINT TIMER PRO")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                    
                    Text("Custom Sprint Workout")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(currentTime)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Premium indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [.yellow, .orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .padding(.horizontal, 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - SC40 Settings Section
    private var sc40SettingsSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Text("SPRINT CONFIGURATION")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.8)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Settings grid
            VStack(spacing: 12) {
                // Distance setting
                sc40SettingCard(
                    icon: "ruler",
                    label: "Distance",
                    value: "\(selectedDistance)",
                    unit: "YD",
                    color: .cyan,
                    action: { showDistancePicker = true }
                )
                
                // Sets setting
                sc40SettingCard(
                    icon: "repeat",
                    label: "Sets",
                    value: "\(selectedSets)",
                    unit: "REPS",
                    color: .green,
                    action: { showSetsPicker = true }
                )
                
                // Rest setting
                sc40SettingCard(
                    icon: "clock",
                    label: "Rest",
                    value: "\(selectedRest)",
                    unit: "MIN",
                    color: .orange,
                    action: { showRestPicker = true }
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - SC40 Setting Card
    private func sc40SettingCard(
        icon: String,
        label: String,
        value: String,
        unit: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with colored background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Label
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Value and unit
                HStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - SC40 Workout Preview
    private var sc40WorkoutPreview: some View {
        VStack(spacing: 12) {
            HStack {
                Text("WORKOUT PREVIEW")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.8)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    
                    Text("Estimated Duration")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(estimatedDuration) min")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Image(systemName: "flame")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Text("Total Volume")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(selectedSets * selectedDistance) yards")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - SC40 Premium Start Button
    private var sc40StartButton: some View {
        Button(action: {
            print("🎯 SprintTimer Pro starting workout with: Distance=\(selectedDistance)yd, Sets=\(selectedSets), Rest=\(selectedRest)min")
            showWorkout = true
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("START SPRINT")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(1.0)
                }
                .foregroundColor(.black)
                
                Text("Pro Workout Ready")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Main gradient
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.0),
                            Color(red: 1.0, green: 0.6, blue: 0.0),
                            Color(red: 1.0, green: 0.8, blue: 0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle shine effect
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(16)
            .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - SC40 Picker Sheet
    private func sitPickerSheet<T: Hashable>(
        title: String,
        options: [T],
        selectedValue: Binding<T>,
        formatter: @escaping (T) -> String
    ) -> some View {
        NavigationView {
            VStack(spacing: 0) {
                // Premium header
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Text("SPRINT TIMER PRO")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                    
                    Text("Select \(title)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Picker
                Picker(title, selection: selectedValue) {
                    ForEach(options, id: \.self) { option in
                        Text(formatter(option))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.wheel)
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.25),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Dismiss the appropriate picker
                        if title == "Distance" { showDistancePicker = false }
                        else if title == "Sets" { showSetsPicker = false }
                        else if title == "Rest Time" { showRestPicker = false }
                    }
                    .font(.system(size: 16, weight: .semibold))
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
