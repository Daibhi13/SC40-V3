import SwiftUI
import Combine

// Local definitions for Watch App
public struct TrainingSession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let week: Int
    public let day: Int
    public let type: String
    public let focus: String
    public let sprints: [SprintSet]
    public let accessoryWork: [String]
    public let notes: String?
    
    public init(week: Int, day: Int, type: String, focus: String, sprints: [SprintSet], accessoryWork: [String], notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.day = day
        self.type = type
        self.focus = focus
        self.sprints = sprints
        self.accessoryWork = accessoryWork
        self.notes = notes
    }
}

public struct SprintSet: Codable, Sendable {
    public let distanceYards: Int
    public let reps: Int
    public let intensity: String
}

struct WatchSessionPlaybackView: View {
    let session: TrainingSession
    @State private var currentDrillIndex = 0
    @State private var isResting = false
    @State private var restTime = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            Canvas { context, size in
                // Session playback liquid glass background
                let playbackGradient = Gradient(colors: [
                    Color.black,
                    Color.orange.opacity(0.2),
                    Color.red.opacity(0.1)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(playbackGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Training intensity visualization
                let intensity: CGFloat = isResting ? 0.3 : 0.8
                context.addFilter(.blur(radius: 15))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.2, y: size.height * 0.2, width: 40 * intensity, height: 40 * intensity)),
                           with: .color(Color.orange.opacity(0.25)))
                
                // Pulse effect during rest
                if isResting {
                    context.fill(Path(ellipseIn: CGRect(x: size.width * 0.6, y: size.height * 0.6, width: 25, height: 25)),
                               with: .color(Color.red.opacity(0.20)))
                }
                
                // Progress wave
                let progressWave = CGFloat(currentDrillIndex) / max(CGFloat(session.accessoryWork.count), 1.0)
                let waveY = size.height * (0.9 - progressWave * 0.3)
                context.fill(Path(CGRect(x: 0, y: waveY, width: size.width, height: 4)),
                           with: .color(Color.green.opacity(0.30)))
            }
            .ignoresSafeArea()
            VStack(spacing: 16) {
            Text("Week \(session.week), Day \(session.day)")
                .font(.headline)
            Text(session.type)
                .font(.title2)
                .foregroundColor(.accentColor)
            if !isResting {
                if !session.accessoryWork.isEmpty {
                    Text(session.accessoryWork[currentDrillIndex])
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
                Button("Next") {
                    startRest()
                }
                .padding()
            } else {
                Text("Rest: \(restTime)s")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
            }
        }
        .onDisappear { timer?.invalidate() }
        }
    }

    func startRest() {
        // Parse rest from accessoryWork string (e.g., ...| Rest: 90s)
        guard !session.accessoryWork.isEmpty else { return }
        let drill = session.accessoryWork[currentDrillIndex]
        let rest = Int(drill.components(separatedBy: "Rest: ").last?.replacingOccurrences(of: "s", with: "") ?? "90") ?? 90
        restTime = rest
        isResting = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { @Sendable _ in
            Task { @MainActor in
                if restTime > 0 {
                    restTime -= 1
                } else {
                    timer?.invalidate()
                    isResting = false
                    if currentDrillIndex < session.accessoryWork.count - 1 {
                        currentDrillIndex += 1
                    }
                }
            }
        }
    }
}

// Preview
struct WatchSessionPlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        let sprintSet = SprintSet(distanceYards: 40, reps: 3, intensity: "max")
        let session = TrainingSession(
            week: 1,
            day: 1,
            type: "Start",
            focus: "Sprint Mechanics",
            sprints: [sprintSet],
            accessoryWork: ["W → S drills 3×5 yd → C | Target: 5.00s | Rest: 90s", "W → S drills 3×5 yd → C | Target: 4.98s | Rest: 92s"],
            notes: ""
        )
        WatchSessionPlaybackView(session: session)
    }
}
