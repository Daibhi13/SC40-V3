import SwiftUI
import Foundation // Ensure canonical SessionFeedback is available

struct SessionDetailView: View {
    let session: TrainingSession
    var onFeedback: ((SessionFeedback) -> Void)?
    @State private var time: Double = 0
    @State private var rpe: Double = 5 // Use canonical rpe (0-10)
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfileVM: UserProfileViewModel // Injected for adaptive logic
    @State private var feedbacks: [SessionFeedback] = [] // Local feedback history
    @State private var showLevelChange: Bool = false
    @State private var levelMessage: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Week \(session.week) • Day \(session.day)").font(.title2)
                Text(session.type).font(.headline)
                if let notes = session.notes, !notes.isEmpty {
                    Text(notes).font(.body)
                }
                Divider()
                Text("Accessory Work:").font(.headline)
                ForEach(session.accessoryWork, id: \.self) { item in
                    Text(item).padding(.leading, 8)
                }
                if !session.sprints.isEmpty {
                    Text("Sprints:").font(.headline)
                    ForEach(session.sprints.indices, id: \.self) { idx in
                        let set = session.sprints[idx]
                        Text("Set \(idx+1): \(set.reps)x \(set.distanceYards) yd @ \(set.intensity)")
                            .padding(.leading, 8)
                    }
                }
                Divider()
                Text("Your Feedback").font(.headline)
                HStack {
                    Text("Time (s):")
                    TextField("0.00", value: $time, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text("RPE (0-10):")
                    Stepper(value: $rpe, in: 0...10, step: 1) {
                        Text("\(Int(rpe))")
                    }
                }
                Button("Submit Feedback") {
                    let feedback = SessionFeedback(sessionID: session.id, time: time, rpe: rpe)
                    onFeedback?(feedback)
                    // Save feedback to local array (in real app, persist to model)
                    feedbacks.append(feedback)
                    // Evaluate adaptive logic
                    // userProfileVM.evaluateAndAdjustLevel(feedbacks: feedbacks) // Temporarily disabled - function not available
                    // Show message if level changed
                    let currentLevel = userProfileVM.profile.level
                    if feedbacks.count >= 3 {
                        let prevLevel = feedbacks.count > 3 ? userProfileVM.profile.level : currentLevel
                        if userProfileVM.profile.level != prevLevel {
                            levelMessage = "Level changed to \(userProfileVM.profile.level)!"
                            showLevelChange = true
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                // Level change alert
                if showLevelChange {
                    Text(levelMessage)
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
    }
}

// #Preview {
//     SessionDetailView(session: sc40SessionExample)
//         .environmentObject(UserProfileViewModel())
// }
