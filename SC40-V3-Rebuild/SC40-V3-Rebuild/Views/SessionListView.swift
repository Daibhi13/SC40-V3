import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        NavigationView {
            List {
                // Temporarily using empty array until UUID-based session management is implemented
                ForEach([] as [Int], id: \.self) { _ in
                    Text("Sessions will be available once session management is restored")
                        .foregroundColor(.secondary)
                }
                /*
                ForEach(viewModel.profile.sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session).environmentObject(viewModel)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Week \(session.week), Day \(session.day)")
                                    .font(.headline)
                                Text(session.type)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !session.accessoryWork.isEmpty {
                                    Text("Accessory: \(session.accessoryWork.joined(separator: ", "))")
                                        .font(.caption)
                                }
                                if !session.sprints.isEmpty {
                                    ForEach(session.sprints.indices, id: \.self) { idx in
                                        let set = session.sprints[idx]
                                        Text("Set \(idx+1): \(set.reps)x \(set.distanceYards) yd @ \(set.intensity)")
                                            .font(.caption)
                                    }
                                }
                                if let notes = session.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption2)
                                        .foregroundColor(.brandAccent)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }
                }
                */
            }
            .navigationTitle("Sprint Sessions")
        }
    }
}

#Preview {
    SessionListView(viewModel: UserProfileViewModel())
}
