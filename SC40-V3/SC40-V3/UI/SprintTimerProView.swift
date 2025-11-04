import SwiftUI
import Combine
import Foundation

struct SprintTimerProView: View {
    @StateObject private var timer: WorkoutTimer = WorkoutTimer()
    @State private var isRunning = false
    @State private var elapsedTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Timer Display
            Text(formatTime(elapsedTime))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            // Control Buttons
            HStack(spacing: 20) {
                Button(action: {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(isRunning ? Color.orange : Color.green)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    resetTimer()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Sprint Timer Pro")
        .onReceive(timer.$elapsedTime) { time in
            elapsedTime = time
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer.start()
    }
    
    private func pauseTimer() {
        isRunning = false
        timer.pause()
    }
    
    private func resetTimer() {
        isRunning = false
        timer.reset()
        elapsedTime = 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

#Preview {
    NavigationView {
        SprintTimerProView()
    }
}
