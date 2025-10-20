import SwiftUI
import Combine

struct SprintWatchView: View {
    @State private var currentTime: String = SprintWatchView.timeString(Date())
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    // Helper to format time as HH:mm
    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    @ObservedObject var viewModel: WorkoutWatchViewModel
    var onDismiss: (() -> Void)? = nil
    @State private var lastPhase: WorkoutPhase? = nil
    @State private var showHaptic = false
    @State private var showAudio = false
    // For animated ring
    @State private var restAnim: Double = 1.0

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.brandBackground, Color.brandTertiary.opacity(0.18)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                // Dynamic phase or motivational message
                HStack {
                    Spacer()
                    Text(viewModel.currentPhase.displayName)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.brandPrimary)
                        .shadow(color: Color.brandTertiary.opacity(0.18), radius: 2, x: 0, y: 1)
                    Spacer()
                }
                HStack(alignment: .center) {
                    // GPS status indicator
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color.brandTertiary)
                            .font(.system(size: 14, weight: .bold))
                        Text("GPS Active")
                            .font(.caption2)
                            .foregroundColor(Color.brandTertiary)
                    }
                    Spacer()
                    Text(currentTime)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.brandAccent)
                        .onReceive(timerPublisher) { date in
                            currentTime = SprintWatchView.timeString(date)
                        }
                }
                // PHASE UI
                if viewModel.currentPhase == .sprint {
                    VStack(spacing: 4) {
                        Text("Sprint Time")
                            .font(.caption)
                            .foregroundColor(Color.brandSecondary)
                        Text(String(format: "%.2f s", viewModel.currentRepTime))
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.brandPrimary)
                    }
                } else if viewModel.currentPhase == .rest && viewModel.repProgress > 0 {
                    VStack(spacing: 8) {
                        Text("Rest Period")
                            .font(.caption)
                            .foregroundColor(Color.brandSecondary)
                        ZStack {
                            Circle()
                                .stroke(Color.brandTertiary.opacity(0.2), lineWidth: 10)
                                .frame(width: 80, height: 80)
                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.repProgress))
                                .stroke(Color.brandTertiary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 80, height: 80)
                                .animation(.linear, value: viewModel.repProgress)
                            VStack {
                                Text("\(viewModel.currentRestSeconds ?? 0)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color.brandPrimary)
                                Text("sec")
                                    .font(.caption2)
                                    .foregroundColor(Color.brandSecondary)
                            }
                        }
                    }
                } else if viewModel.currentPhase == .warmup || viewModel.currentPhase == .cooldown {
                    VStack {
                        Text(viewModel.currentPhase.displayName)
                            .font(.headline)
                            .foregroundColor(Color.brandSecondary)
                        Text(String(format: "%.0f s", viewModel.currentRepTime))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.brandPrimary)
                    }
                } else {
                    Text(viewModel.currentPhase.displayName)
                        .font(.headline)
                        .foregroundColor(Color.brandPrimary)
                }

                // Distance & GPS Info
                HStack {
                    Text("Target: \(viewModel.distanceRemainingString) yd")
                        .font(.caption)
                        .foregroundColor(Color.brandSecondary)
                    Spacer()
                    Text("GPS: \(String(format: "%.1f", viewModel.distanceTraveled * 1.09361)) yd")
                        .font(.caption)
                        .foregroundColor(Color.brandTertiary)
                }
                .padding(.horizontal)

                // Metrics (always shown)
                HStack(spacing: 24) {
                    VStack {
                        Text("Rep \(viewModel.currentRep)/\(viewModel.totalReps)")
                            .font(.caption2)
                            .foregroundColor(Color.brandSecondary)
                        Text("\(viewModel.distanceRemainingString) yd")
                            .font(.title3)
                            .foregroundColor(Color.brandPrimary)
                    }
                    VStack {
                        Text("Heart Rate")
                            .font(.caption2)
                            .foregroundColor(Color.brandSecondary)
                        Text("-- bpm")
                            .font(.title3)
                            .foregroundColor(Color.brandAccent)
                    }
                }
                .padding(.top, 4)
                .font(.footnote)
            }
            .padding()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                    .onEnded { value in
                        print("🔍 SprintView gesture: x=\(value.translation.width), y=\(value.translation.height)")
                        if value.translation.height > 8 {
                            print("🔽 SWIPE DOWN DETECTED in SprintView - dismissing")
                            // WKInterfaceDevice.current().play(.click)
                            onDismiss?()
                        }
                    }
            )
            .onChange(of: viewModel.currentPhase) { oldPhase, newPhase in
                if lastPhase != nil && lastPhase != newPhase {
                    HapticsManager.triggerHaptic()
                    AudioCueManager.shared.playCue(named: "phase_transition")
                }
                lastPhase = newPhase
            }
        }
    }
}

#if DEBUG
#Preview {
    SprintWatchView(viewModel: WorkoutWatchViewModel())
}
#endif


