import SwiftUI

struct TrainingProgramView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @State private var selectedSession: TrainingSession?
    
    var body: some View {
        NavigationView {
            List {
                Text("Training sessions will be available once session management is restored")
                    .foregroundColor(.secondary)
                    .padding()
            }
            /*
            List(viewModel.profile.sessions) { session in
                Button(action: { selectedSession = session }) {
                    SessionCardView(session: session)
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session) { feedback in
                    viewModel.updateSessionNotes(for: session, notes: "Feedback: Time \(feedback.time ?? 0), RPE \(feedback.rpe ?? 0)")
                }
            }
            */
            .navigationTitle("12-Week Program")
        }
    }
}

// MARK: - Supporting Views (Temporarily Disabled)
/*
struct SessionCardView: View {
    let session: TrainingSession
    @State private var isPressed = false
    @State private var showShareSheet = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Week \(session.week) • Day \(session.day)")
                    .font(.headline)
                // Milestone indicator: if type is "Test" or notes contains "milestone"
                if session.type.lowercased().contains("test") || (session.notes?.lowercased().contains("milestone") ?? false) {
                    Text("Milestone").font(.caption).foregroundColor(.orange)
                }
            }
            Text(session.type)
                .font(.subheadline).foregroundColor(.secondary)
            if !session.focus.isEmpty {
                Text(session.focus)
                    .font(.footnote)
            }
            if let notes = session.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundColor(.gray)
            }
        }
        .padding(8)
        .glassEffect(blurRadius: 18, opacity: 0.88)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .shadow(radius: 1)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            // Animate tap
            withAnimation { isPressed = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
                withAnimation { isPressed = false }
            }
            // Could trigger detail view or haptic here
        }
        .onLongPressGesture {
            // Show share sheet or quick edit
            showShareSheet = true
        }
        .contextMenu {
            Button(action: { showShareSheet = true }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button(action: { /* Add quick edit logic here */ }) {
                Label("Quick Edit", systemImage: "pencil")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: ["Check out my session: Week \(session.week) Day \(session.day) - \(session.type)"])
        }
    }
}
*/
