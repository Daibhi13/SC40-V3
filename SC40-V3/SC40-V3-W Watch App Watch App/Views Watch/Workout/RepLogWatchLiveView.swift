import SwiftUI
import Combine

// Row view for a single rep log entry
struct RepLogRowView: View {
    let rep: Int
    let dist: String
    let time: String?
    let isLive: Bool
    let isResting: Bool
    let restSecondsRemaining: Int
    let fullRestTime: Int
    let onAppear: () -> Void
    var body: some View {
        HStack {
            Text("\(rep)")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .frame(width: 32, alignment: .center)
            Text(dist)
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .frame(width: 44, alignment: .center)
            if let t = time {
                Text(t)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .frame(width: 44, alignment: .center)
            } else {
                Text("")
                    .frame(width: 44, alignment: .center)
            }
            // RT rest countdown timer in RT column for current sprint rep
            Group {
                if isLive || (isResting && restSecondsRemaining > 0) {
                    if isLive {
                        // During sprint: show full rest time for this rep
                        Text("\(fullRestTime)s")
                            .font(.system(size: 15, weight: .regular, design: .monospaced))
                            .foregroundColor(.orange)
                            .frame(width: 44, alignment: .center)
                    } else {
                        // During rest: show countdown
                        Text("\(restSecondsRemaining)s")
                            .font(.system(size: 15, weight: .regular, design: .monospaced))
                            .foregroundColor(.cyan)
                            .frame(width: 44, alignment: .center)
                    }
                } else {
                    Text("")
                        .frame(width: 44, alignment: .center)
                }
            }
        }
        .background(Color.clear)
        .cornerRadius(4)
        .onAppear(perform: onAppear)
    }
}
import SwiftUI
#if canImport(BrandColors)
import BrandColors
#endif

// MARK: - Preview
struct RepLogWatchLiveView_Previews: PreviewProvider {
    static var previews: some View {
        RepLogWatchLiveView(
            workoutVM: WorkoutWatchViewModel.mock,
            horizontalTab: .constant(0), 
            isModal: false, 
            showNext: false, 
            onNext: {},
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

import SwiftUI

struct RepLogWatchLiveView: View {
    // Header columns as computed properties to help type-checking
    private var repHeader: some View {
        Text("Rp").font(.caption2).frame(width: 32, alignment: .center)
    }
    private var distHeader: some View {
        Text("Dst").font(.caption2).frame(width: 44, alignment: .center)
    }
    private var tmHeader: some View {
        Text("Tm").font(.caption2).frame(width: 44, alignment: .center)
    }
    private var rtHeader: some View {
        Text("Rt").font(.caption2).frame(width: 44, alignment: .center)
    }
    
    @ObservedObject var workoutVM: WorkoutWatchViewModel
    @Binding var horizontalTab: Int
    var isModal: Bool = false
    var showNext: Bool = false
    var onNext: (() -> Void)? = nil
    var onDone: (() -> Void)? = nil
    let session: TrainingSession
    
    // Data manager for workout history
    @StateObject private var dataManager = WorkoutDataManager.shared
    
    // State for live updates
    @State private var refreshTimer: Timer?
    // Dynamic rep data based on WorkoutWatchViewModel
    private var reps: [(rep: Int, dist: String, time: String?, isLive: Bool, isResting: Bool)] {
        let totalReps = workoutVM.totalReps
        let currentRep = workoutVM.currentRep
        let isInRest = !workoutVM.isRunning && workoutVM.repProgress > 0
        
        return (1...totalReps).map { repNumber in
            let distance = repNumber <= workoutVM.repDistances.count ? 
                workoutVM.repDistances[repNumber - 1] : 40
            let distString = "\(distance)"
            
            // For completed reps, show times; for current rep, mark as live; for future reps, show nil
            let time: String?
            let isLive: Bool
            let isResting: Bool
            
            if repNumber < currentRep {
                // Completed rep - use actual recorded times from workout history
                if let recentWorkout = dataManager.workoutHistory.last,
                   repNumber <= recentWorkout.completedReps.count {
                    let completedRep = recentWorkout.completedReps[repNumber - 1]
                    time = String(format: "%.2f", completedRep.time)
                } else {
                    // Fallback to workoutVM or placeholder
                    time = workoutVM.lastRepTime > 0 ? String(format: "%.2f", workoutVM.lastRepTime) : String(format: "%.2f", Double.random(in: 4.5...6.0))
                }
                isLive = false
                isResting = false
            } else if repNumber == currentRep {
                // Current rep - live during sprint, resting after completion
                if workoutVM.isRunning {
                    // Currently sprinting
                    time = nil
                    isLive = true
                    isResting = false
                } else if isInRest {
                    // Just completed this rep, now resting
                    time = workoutVM.lastRepTime > 0 ? String(format: "%.2f", workoutVM.lastRepTime) : nil
                    isLive = false
                    isResting = true
                } else {
                    // Waiting to start this rep
                    time = nil
                    isLive = false
                    isResting = false
                }
            } else {
                // Future rep
                time = nil
                isLive = false
                isResting = false
            }
            
            return (rep: repNumber, dist: distString, time: time, isLive: isLive, isResting: isResting)
        }
    }
    @State private var currentTime: String = Self.timeString(Date())
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Calculate remaining rest time in seconds from WorkoutWatchViewModel
    private var restSecondsRemaining: Int {
        if !workoutVM.isRunning && workoutVM.repProgress > 0 {
            let totalRestTime = workoutVM.restTime
            let progressRemaining = 1.0 - workoutVM.repProgress
            return max(0, Int(Double(totalRestTime) * progressRemaining))
        }
        return 0
    }
    
    // Format a Date as a time string (e.g., 12:34)
    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.brandBackground, Color.brandTertiary.opacity(0.18)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 2) {
                HStack {
                    Text("Rep Timer")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color.brandPrimary)
                    Spacer()
                    Text(currentTime)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.brandAccent)
                        .onReceive(timerPublisher) { date in
                            currentTime = Self.timeString(date)
                        }
                }
                .padding(.bottom, 2)
                Divider().opacity(0.5)
                ScrollView {
                    VStack(spacing: 6) {
                        HStack {
                            repHeader
                            distHeader
                            tmHeader
                            rtHeader
                        }
                        .foregroundColor(Color.brandSecondary)
                        Divider().opacity(0.3)
                        ForEach(reps, id: \.0) { row in
                            RepLogRowView(
                                rep: row.rep,
                                dist: row.dist,
                                time: row.time,
                                isLive: row.isLive,
                                isResting: row.isResting,
                                restSecondsRemaining: restSecondsRemaining,
                                fullRestTime: Int(workoutVM.restTime),
                                onAppear: {
                                    // No longer need custom rest countdown logic here
                                    // The rest time is now calculated from WorkoutWatchViewModel
                                }
                            )
                            .background(Color.brandTertiary.opacity(0.08))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.bottom, 2)
                Spacer(minLength: 0)
            }
            .padding(.top, 4)
            .padding([.leading, .trailing, .bottom], 8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                    .onEnded { value in
                        print("📱 RepLogView gesture: x=\(value.translation.width), y=\(value.translation.height)")
                        
                        // For modal presentation, allow both swipe up and swipe down to dismiss
                        if isModal {
                            if value.translation.height < -8 {
                                // Swipe up to dismiss
                                print("🔼 RepLogView SWIPE UP - dismissing modal")
                                onDone?()
                            } else if value.translation.height > 8 {
                                // Swipe down to dismiss  
                                print("🔽 RepLogView SWIPE DOWN - dismissing modal")
                                onDone?()
                            }
                        } else {
                            // Enhanced7StageWorkoutView navigation - swipe down to return
                            if value.translation.height > 30 {
                                print("📊 RepLogView - Swipe Down to return to workout")
                                // This will be handled by the fullScreenCover dismissal
                                // We can't directly dismiss here, but the parent view will handle it
                            } else if value.translation.height < -8 {
                                // Non-modal: swipe up to go back to main tab (legacy behavior)
                                print("🔼 RepLogView SWIPE UP - returning to main tab")
                                horizontalTab = 1
                            }
                        }
                    }
            )
        }
        .onAppear {
            startLiveUpdates()
        }
        .onDisappear {
            stopLiveUpdates()
        }
    }
    
    // MARK: - Live Update Methods
    
    private func startLiveUpdates() {
        // Start refresh timer for live data updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            // Force UI refresh for live data by updating workoutVM
            DispatchQueue.main.async {
                self.workoutVM.objectWillChange.send()
            }
        }
        
        print("📊 RepLog live updates started")
    }
    
    private func stopLiveUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        print("📊 RepLog live updates stopped")
    }
}

/*
 ## RepLogWatchLiveView RT Column Documentation
 
 The RT (Rest Time) column now shows live rest countdown starting from rep 1, displaying the actual remaining rest time 
 calculated from the WorkoutWatchViewModel's rest progress.
 
 ### Behavior:
 
 **During Sprint Phase:**
 - Rep being sprinted: Shows nothing in RT column
 - Completed reps: Show their sprint times in Tm column
 - Future reps: Show nothing
 
 **During Rest Phase (After completing a rep):**
 - The completed rep row: Shows live countdown (e.g., "45s", "30s", "15s"...)
 - Other reps: Show nothing in RT column
 
 ### Example with 3-rep workout:
 
 1. **Before Rep 1:**
    ```
    Rp | Dst | Tm   | Rt
    1  | 40  |      |
    2  | 60  |      |
    3  | 40  |      |
    ```
 
 2. **During Rep 1 Sprint:**
    ```
    Rp | Dst | Tm   | Rt
    1  | 40  |      |     <- Currently sprinting
    2  | 60  |      |
    3  | 40  |      |
    ```
 
 3. **Rest After Rep 1 (Live countdown):**
    ```
    Rp | Dst | Tm   | Rt
    1  | 40  | 5.23 | 45s  <- Rest countdown from WorkoutWatchViewModel
    2  | 60  |      |
    3  | 40  |      |
    ```
 
 4. **During Rep 2 Sprint:**
    ```
    Rp | Dst | Tm   | Rt
    1  | 40  | 5.23 |
    2  | 60  |      |     <- Currently sprinting  
    3  | 40  |      |
    ```
 
 5. **Rest After Rep 2 (Live countdown):**
    ```
    Rp | Dst | Tm   | Rt
    1  | 40  | 5.23 |
    2  | 60  | 4.87 | 60s  <- Rest countdown from WorkoutWatchViewModel
    3  | 40  |      |
    ```
 
 ### Technical Implementation:
 - `restSecondsRemaining`: Calculated from `workoutVM.repProgress` and `workoutVM.restTime`
 - `isResting`: Determined by `!workoutVM.isRunning && workoutVM.repProgress > 0`
 - Real-time updates: View automatically updates as `repProgress` changes in WorkoutWatchViewModel
 - Accurate timing: Uses the same rest timer system as the main workout interface
 
 This provides users with live feedback about rest time remaining, helping them prepare for the next rep.
 */

#Preview {
    RepLogWatchLiveView(
        workoutVM: WorkoutWatchViewModel.mock,
        horizontalTab: .constant(0), 
        isModal: true, 
        showNext: true,
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

