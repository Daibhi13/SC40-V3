import Foundation
import ActivityKit
import SwiftUI
import WidgetKit
import Combine

/// ActivityKit integration for Live Activities during workouts
@available(iOS 16.1, *)
class ActivityKitManager: ObservableObject {
    static let shared = ActivityKitManager()
    
    @Published var currentActivity: Activity<SC40WorkoutAttributes>?
    @Published var isActivityActive = false
    
    private init() {}
    
    // MARK: - Live Activity Management
    
    func startWorkoutActivity(
        sessionType: String,
        weekNumber: Int,
        dayNumber: Int,
        totalSprints: Int
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = SC40WorkoutAttributes(
            sessionType: sessionType,
            weekNumber: weekNumber,
            dayNumber: dayNumber,
            totalSprints: totalSprints
        )
        
        let initialState = SC40WorkoutAttributes.ContentState(
            currentSprint: 0,
            phase: .warmup,
            elapsedTime: 0,
            bestTime: nil as Double?,
            currentTime: nil as Double?,
            heartRate: nil as Double?,
            isActive: true
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            print("Started Live Activity: \(activity.id)")
            
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateWorkoutActivity(
        currentSprint: Int,
        phase: ActivityWorkoutPhase,
        elapsedTime: TimeInterval,
        bestTime: Double? = nil,
        currentTime: Double? = nil,
        heartRate: Double? = nil
    ) async {
        guard let activity = currentActivity else { return }
        
        let updatedState = SC40WorkoutAttributes.ContentState(
            currentSprint: currentSprint,
            phase: phase,
            elapsedTime: elapsedTime,
            bestTime: bestTime,
            currentTime: currentTime,
            heartRate: heartRate,
            isActive: true
        )
        
        let content = ActivityContent(state: updatedState, staleDate: nil)
        
        await activity.update(content)
        print("Updated Live Activity")
    }
    
    func endWorkoutActivity(
        finalStats: WorkoutFinalStats
    ) async {
        guard let activity = currentActivity else { return }
        
        let finalState = SC40WorkoutAttributes.ContentState(
            currentSprint: finalStats.totalSprints,
            phase: .finished,
            elapsedTime: finalStats.totalTime,
            bestTime: finalStats.bestTime,
            currentTime: nil as Double?,
            heartRate: finalStats.averageHeartRate,
            isActive: false
        )
        
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: Calendar.current.date(byAdding: .minute, value: 5, to: Date())
        )
        
        await activity.end(finalContent, dismissalPolicy: .after(.now + 30))
        currentActivity = nil
        isActivityActive = false
        
        print("Ended Live Activity")
    }
    
    func cancelWorkoutActivity() async {
        guard let activity = currentActivity else { return }
        
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
        isActivityActive = false
        
        print("Cancelled Live Activity")
    }
    
    // MARK: - Activity Monitoring
    
    func monitorActivityUpdates() {
        Task {
            for await activity in Activity<SC40WorkoutAttributes>.activityUpdates {
                if activity.activityState == .active {
                    currentActivity = activity
                    isActivityActive = true
                } else {
                    currentActivity = nil
                    isActivityActive = false
                }
            }
        }
    }
}

// MARK: - Activity Attributes

@available(iOS 16.1, *)
struct SC40WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let currentSprint: Int
        let phase: ActivityWorkoutPhase
        let elapsedTime: TimeInterval
        let bestTime: Double?
        let currentTime: Double?
        let heartRate: Double?
        let isActive: Bool
    }
    
    let sessionType: String
    let weekNumber: Int
    let dayNumber: Int
    let totalSprints: Int
}

// MARK: - Supporting Types

enum ActivityWorkoutPhase: String, Codable, CaseIterable {
    case warmup = "Warmup"
    case ready = "Ready"
    case sprint = "Sprint"
    case rest = "Rest"
    case cooldown = "Cooldown"
    case finished = "Finished"
    
    var emoji: String {
        switch self {
        case .warmup: return "🔥"
        case .ready: return "⚡"
        case .sprint: return "🏃‍♂️"
        case .rest: return "😤"
        case .cooldown: return "🧘‍♂️"
        case .finished: return "🎉"
        }
    }
    
    var color: Color {
        switch self {
        case .warmup: return .orange
        case .ready: return .yellow
        case .sprint: return .red
        case .rest: return .blue
        case .cooldown: return .green
        case .finished: return .purple
        }
    }
}

struct WorkoutFinalStats {
    let totalSprints: Int
    let bestTime: Double
    let averageTime: Double
    let totalTime: TimeInterval
    let averageHeartRate: Double?
    let caloriesBurned: Double?
}

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct SC40WorkoutActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SC40WorkoutAttributes.self) { context in
            // Lock screen/banner UI
            SC40WorkoutLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Text(context.state.phase.emoji)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(context.state.phase.rawValue)
                                .font(.caption.bold())
                            Text("Sprint \(context.state.currentSprint)/\(context.attributes.totalSprints)")
                                .font(.caption2)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        if let bestTime = context.state.bestTime {
                            Text("Best: \(String(format: "%.2fs", bestTime))")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        Text(formatTime(context.state.elapsedTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if context.state.phase == .sprint, let currentTime = context.state.currentTime {
                            Text("Current: \(String(format: "%.2fs", currentTime))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        if let heartRate = context.state.heartRate {
                            HStack(spacing: 2) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("\(Int(heartRate))")
                            }
                            .font(.caption)
                        }
                    }
                }
            } compactLeading: {
                Text(context.state.phase.emoji)
            } compactTrailing: {
                Text("\(context.state.currentSprint)/\(context.attributes.totalSprints)")
                    .font(.caption2.bold())
            } minimal: {
                Text(context.state.phase.emoji)
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Live Activity View

@available(iOS 16.1, *)
struct SC40WorkoutLiveActivityView: View {
    let context: ActivityViewContext<SC40WorkoutAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("SC40 Sprint Coach")
                    .font(.headline.bold())
                Spacer()
                Text("Week \(context.attributes.weekNumber), Day \(context.attributes.dayNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Main content
            HStack(spacing: 20) {
                // Phase indicator
                VStack {
                    Text(context.state.phase.emoji)
                        .font(.title)
                    Text(context.state.phase.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(context.state.phase.color)
                }
                
                Spacer()
                
                // Sprint progress
                VStack {
                    Text("Sprint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(context.state.currentSprint)/\(context.attributes.totalSprints)")
                        .font(.title2.bold())
                }
                
                Spacer()
                
                // Time display
                VStack {
                    if let bestTime = context.state.bestTime {
                        Text("Best")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2fs", bestTime))
                            .font(.title3.bold())
                            .foregroundColor(.green)
                    } else {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(context.state.elapsedTime))
                            .font(.title3.bold())
                    }
                }
                
                // Heart rate (if available)
                if let heartRate = context.state.heartRate {
                    Spacer()
                    
                    VStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("\(Int(heartRate))")
                            .font(.title3.bold())
                    }
                }
            }
            
            // Progress bar
            if context.attributes.totalSprints > 0 {
                ProgressView(value: Double(context.state.currentSprint), total: Double(context.attributes.totalSprints))
                    .progressViewStyle(LinearProgressViewStyle(tint: context.state.phase.color))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
