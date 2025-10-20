import SwiftUI

// MARK: - Wave AI Rep Log View
// Real-time performance feedback during automated workouts

struct RepLogView: View {
    let drillTimes: [Double]
    let strideTimes: [Double]
    let sprintTimes: [Double]
    let currentStage: WorkoutStage
    let currentRep: Int
    let session: TrainingSession
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Live Results")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(stageStatusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(stageColor.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.3))
            )
            
            // Results Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Drills Column
                    if !drillTimes.isEmpty || currentStage == .drills {
                        RepColumnView(
                            title: "DRILLS",
                            times: drillTimes,
                            currentRep: currentStage == .drills ? currentRep : nil,
                            color: .blue,
                            targetDistance: "20yd"
                        )
                    }
                    
                    // Strides Column
                    if !strideTimes.isEmpty || currentStage == .strides {
                        RepColumnView(
                            title: "STRIDES", 
                            times: strideTimes,
                            currentRep: currentStage == .strides ? currentRep : nil,
                            color: .purple,
                            targetDistance: "20yd"
                        )
                    }
                    
                    // Sprints Column
                    if !sprintTimes.isEmpty || currentStage == .sprints {
                        RepColumnView(
                            title: "SPRINTS",
                            times: sprintTimes,
                            currentRep: currentStage == .sprints ? currentRep : nil,
                            color: .red,
                            targetDistance: "\(session.sprints.first?.distanceYards ?? 40)yd"
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var stageStatusText: String {
        switch currentStage {
        case .idle: return "Ready"
        case .warmUp: return "Warming Up"
        case .drills: return "Rep \(currentRep)/3"
        case .strides: return "Rep \(currentRep)/3"
        case .sprints: return "Rep \(currentRep)/\(session.sprints.first?.reps ?? 4)"
        case .recovery: return "Recovery"
        case .cooldown: return "Cooling Down"
        }
    }
    
    private var stageColor: Color {
        switch currentStage {
        case .idle: return .gray
        case .warmUp: return .orange
        case .drills: return .blue
        case .strides: return .purple
        case .sprints: return .red
        case .recovery: return .green
        case .cooldown: return .cyan
        }
    }
}

// MARK: - Rep Column View

struct RepColumnView: View {
    let title: String
    let times: [Double]
    let currentRep: Int?
    let color: Color
    let targetDistance: String
    
    private let maxReps = 6 // Maximum rows to show
    
    var body: some View {
        VStack(spacing: 8) {
            // Column Header
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                    .tracking(0.5)
                
                Text(targetDistance)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(height: 32)
            
            // Time Rows
            VStack(spacing: 4) {
                ForEach(0..<maxReps, id: \.self) { index in
                    RepRowView(
                        repNumber: index + 1,
                        time: times.count > index ? times[index] : nil,
                        isCurrent: currentRep == index + 1,
                        isCompleted: times.count > index,
                        color: color
                    )
                }
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Rep Row View

struct RepRowView: View {
    let repNumber: Int
    let time: Double?
    let isCurrent: Bool
    let isCompleted: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            // Rep Number
            Text("\(repNumber)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textColor)
                .frame(width: 16, alignment: .leading)
            
            // Time or Status
            Text(displayText)
                .font(.system(size: 11, weight: isCompleted ? .semibold : .medium))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .monospacedDigit()
        }
        .frame(height: 20)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(borderColor, lineWidth: isCurrent ? 1.5 : 0.5)
        )
        .scaleEffect(isCurrent ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }
    
    // MARK: - Computed Properties
    
    private var displayText: String {
        if let time = time {
            return String(format: "%.2f", time)
        } else if isCurrent {
            return "..."
        } else {
            return "--"
        }
    }
    
    private var textColor: Color {
        if isCompleted {
            return .white
        } else if isCurrent {
            return color
        } else {
            return .white.opacity(0.5)
        }
    }
    
    private var backgroundColor: Color {
        if isCurrent {
            return color.opacity(0.2)
        } else if isCompleted {
            return Color.white.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isCurrent {
            return color
        } else if isCompleted {
            return color.opacity(0.5)
        } else {
            return Color.white.opacity(0.2)
        }
    }
}

// MARK: - Extensions for Wave AI Integration

extension WorkoutDataRecorder {
    var drillTimes: [Double] {
        // Return drill times from recorded data
        return [] // Implement based on your data structure
    }
    
    var strideTimes: [Double] {
        // Return stride times from recorded data
        return [] // Implement based on your data structure
    }
    
    var sprintTimes: [Double] {
        // Return sprint times from recorded data
        return [] // Implement based on your data structure
    }
}

// MARK: - Preview

#Preview {
    RepLogView(
        drillTimes: [3.2, 3.1, 2.9],
        strideTimes: [2.8, 2.7],
        sprintTimes: [4.5, 4.3],
        currentStage: .sprints,
        currentRep: 3,
        session: TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Speed Development",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 40, reps: 4, intensity: "Max")],
            accessoryWork: [],
            notes: nil
        )
    )
    .frame(height: 180)
    .padding()
    .background(
        LinearGradient(
            colors: [Color.black, Color.blue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
