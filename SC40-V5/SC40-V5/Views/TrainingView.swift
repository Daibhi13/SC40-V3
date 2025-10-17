//
//  TrainingView.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI
import CoreLocation

/// Primary workout interface for sprint training sessions
struct TrainingView: View {
    @StateObject private var viewModel = TrainingViewModel()
    @State private var showSessionSetup = false
    @State private var showSessionComplete = false
    @State private var currentLocation: CLLocation?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [.black, .gray]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)

            VStack {
                // Header
                TrainingHeaderView(
                    sessionName: viewModel.currentSession?.name ?? "Sprint Training",
                    elapsedTime: viewModel.elapsedTime,
                    currentSet: viewModel.currentSet,
                    totalSets: viewModel.totalSets
                )

                Spacer()

                // Main workout interface
                if viewModel.isWorkoutActive {
                    ActiveWorkoutView(viewModel: viewModel)
                } else {
                    PreWorkoutView(viewModel: viewModel)
                }

                Spacer()

                // Control buttons
                TrainingControlsView(viewModel: viewModel)

                // Progress indicator
                if viewModel.isWorkoutActive {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showSessionSetup) {
            Text("Session Setup")
                .font(.title)
                .foregroundColor(.white)
        }
        .sheet(isPresented: $showSessionComplete) {
            Text("Session Complete!")
                .font(.title)
                .foregroundColor(.white)
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }
}

// MARK: - Header View

struct TrainingHeaderView: View {
    let sessionName: String
    let elapsedTime: TimeInterval
    let currentSet: Int
    let totalSets: Int

    var body: some View {
        VStack {
            Text(sessionName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack {
                Text("Time: \(formattedTime(elapsedTime))")
                Spacer()
                Text("Set \(currentSet)/\(totalSets)")
            }
            .font(.headline)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal)
        }
        .padding(.top, 50)
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Pre-Workout View

struct PreWorkoutView: View {
    @ObservedObject var viewModel: TrainingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Ready to start your sprint session?")
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Session info
            VStack(alignment: .leading, spacing: 15) {
                InfoRow(title: "Session Type", value: viewModel.selectedSessionType?.rawValue ?? "Not Selected")
                InfoRow(title: "Duration", value: "\(Int(viewModel.estimatedDuration / 60)) min")
                InfoRow(title: "Sets", value: "\(viewModel.totalSets)")
                InfoRow(title: "Location", value: viewModel.currentLocation?.description ?? "Indoor")
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            // Start button
            Button(action: {
                viewModel.startWorkout()
            }) {
                Text("Start Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .disabled(viewModel.selectedSessionType == nil)
        }
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: TrainingViewModel

    var body: some View {
        VStack {
            // Current sprint set info
            VStack(spacing: 20) {
                Text("Current Set")
                    .font(.headline)
                    .foregroundColor(.white)

                if let currentSet = viewModel.currentSprintSet {
                    Text(currentSet.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)

                    Text("\(Int(currentSet.distance))m sprint")
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("Target: \(formattedTime(currentSet.targetTime))")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Spacer()

            // Sprint timing interface
            if viewModel.isSprintActive {
                SprintTimerView(viewModel: viewModel)
            } else {
                RestTimerView(viewModel: viewModel)
            }

            Spacer()

            // Real-time metrics
            HStack {
                MetricView(title: "Heart Rate", value: "\(viewModel.currentHeartRate)", unit: "BPM")
                Spacer()
                MetricView(title: "Distance", value: String(format: "%.1f", viewModel.currentDistance), unit: "m")
                Spacer()
                MetricView(title: "Pace", value: formattedPace(viewModel.currentPace), unit: "/100m")
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Timer Views

struct SprintTimerView: View {
    @ObservedObject var viewModel: TrainingViewModel

    var body: some View {
        VStack {
            Text("SPRINT!")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.green)
                .padding()

            Text(formattedTime(viewModel.sprintTimer))
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

struct RestTimerView: View {
    @ObservedObject var viewModel: TrainingViewModel

    var body: some View {
        VStack {
            Text("REST")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.blue)
                .padding()

            Text(formattedTime(viewModel.restTimer))
                .font(.system(size: 60, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text("Next: \(viewModel.nextSprintSet?.name ?? "")")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Control Buttons

struct TrainingControlsView: View {
    @ObservedObject var viewModel: TrainingViewModel

    var body: some View {
        HStack(spacing: 20) {
            // Pause/Resume button
            Button(action: {
                if viewModel.isWorkoutActive {
                    if viewModel.isPaused {
                        viewModel.resumeWorkout()
                    } else {
                        viewModel.pauseWorkout()
                    }
                }
            }) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(viewModel.isWorkoutActive ? Color.blue : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.isWorkoutActive)

            // Stop button
            Button(action: {
                viewModel.stopWorkout()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.isWorkoutActive)

            // Emergency stop
            Button(action: {
                viewModel.emergencyStop()
            }) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title + ":")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(unit)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Helper Functions

private func formattedTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
    return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
}

private func formattedPace(_ pace: TimeInterval) -> String {
    let minutes = Int(pace) / 60
    let seconds = Int(pace) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

// MARK: - Preview

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView()
    }
}
