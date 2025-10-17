import SwiftUI

struct TimeTrialPhoneView: View {
    @EnvironmentObject var userProfileVM: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning = false
    @State private var currentTime: Double = 0.0
    @State private var finalTime: Double?
    @State private var showResults = false
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.brandBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text("40 Yard Time Trial")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text("Professional performance test")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Timer display
                VStack(spacing: 16) {
                    Text(String(format: "%.2f", currentTime))
                        .font(.system(size: 72, weight: .black, design: .monospaced))
                        .foregroundColor(isRunning ? .purple : .primary)
                        .animation(.easeInOut(duration: 0.3), value: isRunning)
                    
                    Text("SECONDS")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .tracking(2)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Color.brandAccent.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                // Control buttons
                VStack(spacing: 16) {
                    if !isRunning && finalTime == nil {
                        // Start button
                        Button(action: startTimer) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title2.bold())
                                Text("Start Time Trial")
                                    .font(.title2.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                    } else if isRunning {
                        // Stop button
                        Button(action: stopTimer) {
                            HStack(spacing: 12) {
                                Image(systemName: "stop.fill")
                                    .font(.title2.bold())
                                Text("Finish")
                                    .font(.title2.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                    } else if let time = finalTime {
                        // Results and reset
                        VStack(spacing: 12) {
                            Text("Final Time: \(String(format: "%.2f", time))s")
                                .font(.title2.bold())
                                .foregroundColor(.purple)
                            
                            Button(action: resetTimer) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2.bold())
                                    Text("Try Again")
                                        .font(.title2.bold())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.purple.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                        }
                    }
                    
                    // Instructions
                    Text("Tap START when ready to sprint 40 yards at maximum effort")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(24)
        }
        .navigationTitle("Time Trial")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        isRunning = true
        currentTime = 0.0
        finalTime = nil
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            Task { @MainActor in
                currentTime += 0.01
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        finalTime = currentTime
        
        // Save the time trial result
        saveTimeTrialResult(time: currentTime)
    }
    
    private func resetTimer() {
        currentTime = 0.0
        finalTime = nil
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func saveTimeTrialResult(time: Double) {
        // TODO: Save to history when HistoryManager is available
        // let timeTrialSession = TrainingSession(
        //     week: 0,
        //     day: 0,
        //     type: "Time Trial",
        //     focus: "40 Yard Performance Test",
        //     sprints: [SprintSet(distanceYards: 40, reps: 1, intensity: "100%")],
        //     accessoryWork: [],
        //     notes: "Time Trial - \(String(format: "%.2f", time))s"
        // )
        // HistoryManager.shared.addSession(timeTrialSession)
        
        // Update personal best if this is better
        let currentPB = userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime
        if time < currentPB {
            userProfileVM.updatePersonalBest(time)
        }
    }
}

#if DEBUG
#Preview("1. Time Trial Ready") {
    NavigationView {
        TimeTrialPhoneView()
            .environmentObject(UserProfileViewModel())
    }
    .preferredColorScheme(.dark)
}

#Preview("2. Time Trial Interface") {
    TimeTrialPhoneView()
        .environmentObject(UserProfileViewModel())
        .preferredColorScheme(.dark)
}

#Preview("3. Time Trial Running") {
    TimeTrialPhoneView()
        .environmentObject(UserProfileViewModel())
        .preferredColorScheme(.light)
}

#Preview("4. Time Trial Complete") {
    NavigationView {
        TimeTrialPhoneView()
            .environmentObject(UserProfileViewModel())
            .navigationTitle("Time Trial")
    }
    .preferredColorScheme(.dark)
}
#endif
