import SwiftUI

struct StarterProWatchView: View {
    @State private var currentRep = 1
    @State private var totalReps = 3
    @State private var restTime = 60
    @State private var sprintTimes: [Double] = []
    @State private var isResting = false
    @State private var showResults = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Starter Pro")
                .font(.largeTitle.bold())
                .foregroundColor(.brandPrimary)
                .padding(.top)
            if showResults {
                VStack(spacing: 12) {
                    Text("Session Complete!")
                        .font(.title2)
                        .foregroundColor(.brandSecondary)
                    ForEach(Array(sprintTimes.enumerated()), id: \.offset) { idx, time in
                        Text("Rep \(idx+1): \(String(format: "%.2f", time))s")
                            .foregroundColor(.brandTertiary)
                    }
                    Button("Send to Phone") {
                        sendResultsToPhone()
                    }
                    .padding()
                    .background(Color.brandPrimary)
                    .foregroundColor(.brandBackground)
                    .cornerRadius(12)
                }
            } else if isResting {
                Text("Rest: \(restTime)s")
                    .font(.title)
                    .foregroundColor(.brandAccent)
            } else {
                Text("Rep \(currentRep)/\(totalReps)")
                    .font(.title)
                    .foregroundColor(.brandSecondary)
                Button(action: playStarterSequence) {
                    Text("Start Rep")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.brandPrimary)
                        .foregroundColor(.brandBackground)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding()
        .background(Color.brandBackground.edgesIgnoringSafeArea(.all))
    }

    func playStarterSequence() {
        // Audio: “On your marks… Set… Go!”
        // Timer starts
        let sprintTime = Double.random(in: 4.3...6.5) // placeholder
        sprintTimes.append(sprintTime)

        if currentRep < totalReps {
            currentRep += 1
            isResting = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(restTime) * 1_000_000_000) // restTime in seconds
                isResting = false
            }
        } else {
            showResults = true
        }
    }

    func sendResultsToPhone() {
        // WatchConnectivity → send sprintTimes back as StarterProSession
        // Placeholder: Implement WatchConnectivity logic here
    }
    
    func startSessionOnWatch() {
        let message: [String: Any] = ["trigger": "startSession"]
        WatchSessionManager.shared.send(message: message)
    }
}
