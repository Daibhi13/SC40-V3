import SwiftUI

// Need to import or make available:
// - TrainingSession (from SprintSetAndTrainingSession.swift)  
// - UserProfileViewModel (from UserProfileViewModel.swift)
// - Color extensions (from wherever brand colors are defined)

struct DayDetailView: View {
    var session: TrainingSession
    @State private var userNotes: String = ""
    @EnvironmentObject var userProfileVM: UserProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Session Detail Section
                Group {
                    Text("W\(session.week)/D\(session.day)")
                        .font(.largeTitle.bold())
                        .foregroundColor(.brandTertiary)
                    
                    // Session Type
                    Text(session.type)
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                    
                    // Focus Section - NEW
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.brandSecondary)
                        Text(session.focus)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    
                    // Level Section - NEW
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Training Level")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.brandSecondary)
                        Text(userProfileVM.profile.level)
                            .font(.body)
                            .foregroundColor(.yellow)
                    }
                    
                    if let notes = session.notes, !notes.isEmpty {
                        Text("Notes: \(notes)")
                            .font(.body)
                            .foregroundColor(.brandSecondary)
                    }
                    Divider().padding(.vertical, 4)
                    // Warm-up (mocked)
                    Text("Warm-up: Jog + A-skips")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.brandTertiary)
                    // --- Adaptive Sprint Sets ---
                    if !session.sprints.isEmpty {
                        Text("Sprints:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.brandTertiary)
                        ForEach(session.sprints.indices, id: \.self) { idx in
                            let set = session.sprints[idx]
                            Text("Set \(idx+1): \(set.reps)x \(set.distanceYards) yd @ \(set.intensity)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    // --- Accessory Work ---
                    if !session.accessoryWork.isEmpty {
                        Text("Accessory Work:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.brandTertiary)
                        ForEach(session.accessoryWork, id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                // Show splits chart here (if you want)
                // MiniSessionChartView()
                Divider().padding(.vertical, 8)
                // PostSessionAnalyticsPanel(session: session) // If you want analytics
                Divider().padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Notes & Feedback")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                    TextEditor(text: $userNotes)
                        .frame(height: 80)
                        .background(Color.brandAccent.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.bottom, 8)
                    Button(action: { /* Save notes/feedback action */ }) {
                        Text("Save Feedback")
                            .font(.subheadline.bold())
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.brandPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}
