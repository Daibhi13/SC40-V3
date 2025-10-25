import SwiftUI

public struct SimpleControlWatchView: View {
    @Binding var isWorkoutActive: Bool
    let onBack: () -> Void
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Workout Control")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                isWorkoutActive.toggle()
            }) {
                HStack {
                    Image(systemName: isWorkoutActive ? "pause.fill" : "play.fill")
                    Text(isWorkoutActive ? "Pause" : "Resume")
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .cornerRadius(8)
            }
            
            Button("Back to Workout") {
                onBack()
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.black)
    }
}

public struct SimpleMusicWatchView: View {
    let onBack: () -> Void
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Music Control")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "backward.fill")
                        Text("Previous")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play/Pause")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("Next")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
            
            Button("Back to Workout") {
                onBack()
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.black)
    }
}

public struct SimpleRepLogWatchView: View {
    let currentSet: Int
    let totalSets: Int
    let onBack: () -> Void
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Rep Log")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Set \(currentSet) of \(totalSets)")
                .font(.title2)
                .foregroundColor(.yellow)
            
            VStack(spacing: 8) {
                Text("Log your time:")
                    .foregroundColor(.white.opacity(0.7))
                
                Text("5.25s")
                    .font(.title)
                    .foregroundColor(.green)
                    .monospacedDigit()
            }
            
            Button("Save Time") {
                // Save logic here
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(8)
            
            Button("Back to Workout") {
                onBack()
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.black)
    }
}
