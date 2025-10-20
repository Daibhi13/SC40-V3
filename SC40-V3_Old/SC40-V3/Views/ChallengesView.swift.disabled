import SwiftUI
import Combine

struct ChallengesView: View {
    @StateObject private var socialService = MockSocialService()
    @State private var selectedTab = 0
    @State private var showingCreateChallenge = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                if selectedTab == 2 { // Browse tab
                    SearchBar(text: $searchText)
                        .padding()
                }
                
                // Tab Selector
                Picker("Challenge Tab", selection: $selectedTab) {
                    Text("Active").tag(0)
                    Text("Completed").tag(1)
                    Text("Browse").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    ActiveChallengesView(challenges: socialService.activeChallenges)
                        .tag(0)
                    
                    CompletedChallengesView(challenges: socialService.completedChallenges)
                        .tag(1)
                    
                    BrowseChallengesView(challenges: filteredAvailableChallenges)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateChallenge = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateChallenge) {
                CreateChallengeView()
            }
        }
        .onAppear {
            loadChallenges()
        }
    }
    
    private var filteredAvailableChallenges: [Challenge] {
        if searchText.isEmpty {
            return socialService.availableChallenges
        } else {
            return socialService.availableChallenges.filter { challenge in
                challenge.title.localizedCaseInsensitiveContains(searchText) ||
                challenge.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadChallenges() {
        Task {
            do {
                try await socialService.loadChallenges()
            } catch {
                print("Error loading challenges: \(error)")
            }
        }
    }
}

struct ActiveChallengesView: View {
    let challenges: [Challenge]
    
    var body: some View {
        List {
            if challenges.isEmpty {
                EmptyActiveChallengesView()
            } else {
                ForEach(challenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        ActiveChallengeRowView(challenge: challenge)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ActiveChallengeRowView: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: challengeTypeIcon(challenge.type))
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text(challenge.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(challenge.status).opacity(0.2))
                        .foregroundColor(statusColor(challenge.status))
                        .cornerRadius(8)
                }
            }
            
            // Progress indicator
            ProgressView(value: challenge.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("Progress: \(Int(challenge.progressPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Ends \(challenge.endDate, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func challengeTypeIcon(_ type: ChallengeType) -> String {
        switch type {
        case .speed:
            return "bolt.fill"
        case .distance:
            return "figure.run"
        case .consistency:
            return "calendar"
        case .improvement:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func statusColor(_ status: ChallengeStatus) -> Color {
        switch status {
        case .active:
            return .green
        case .completed:
            return .blue
        case .failed:
            return .red
        case .pending:
            return .orange
        }
    }
}

struct CompletedChallengesView: View {
    let challenges: [Challenge]
    
    var body: some View {
        List {
            if challenges.isEmpty {
                EmptyCompletedChallengesView()
            } else {
                ForEach(challenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        CompletedChallengeRowView(challenge: challenge)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct CompletedChallengeRowView: View {
    let challenge: Challenge
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Completed \(challenge.endDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let reward = challenge.reward {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text(reward.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: challenge.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(challenge.status == .completed ? .green : .red)
                    .font(.title2)
                
                if challenge.status == .completed {
                    Text("Success!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct BrowseChallengesView: View {
    let challenges: [Challenge]
    @StateObject private var socialService = MockSocialService()
    
    var body: some View {
        List {
            if challenges.isEmpty {
                EmptyBrowseChallengesView()
            } else {
                ForEach(challenges) { challenge in
                    BrowseChallengeRowView(challenge: challenge, socialService: socialService)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct BrowseChallengeRowView: View {
    let challenge: Challenge
    let socialService: MockSocialService
    @State private var isJoining = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Button(action: {
                    joinChallenge()
                }) {
                    Text("Join")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isJoining)
            }
            
            // Challenge details
            HStack {
                Label {
                    Text("\(challenge.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "person.2")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Label {
                    Text("Ends \(challenge.endDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
            }
            
            if let reward = challenge.reward {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Reward: \(reward.title)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func joinChallenge() {
        isJoining = true
        Task {
            do {
                try await socialService.joinChallenge(challengeId: challenge.id)
                isJoining = false
            } catch {
                print("Error joining challenge: \(error)")
                isJoining = false
            }
        }
    }
}

struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = MockSocialService()
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType = ChallengeType.speed
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1 week from now
    @State private var targetValue = ""
    @State private var isPublic = true
    @State private var invitedFriends: Set<String> = []
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Challenge Details") {
                    TextField("Challenge Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Challenge Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(ChallengeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Target Value", text: $targetValue)
                        .keyboardType(.decimalPad)
                }
                
                Section("Duration") {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Visibility") {
                    Toggle("Public Challenge", isOn: $isPublic)
                    
                    if !isPublic {
                        NavigationLink("Invite Friends") {
                            InviteFriendsView(invitedFriends: $invitedFriends)
                        }
                    }
                }
            }
            .navigationTitle("Create Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChallenge()
                    }
                    .disabled(title.isEmpty || description.isEmpty || targetValue.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createChallenge() {
        isCreating = true
        Task {
            do {
                try await socialService.createChallenge(
                    title: title,
                    description: description,
                    type: selectedType,
                    endDate: endDate,
                    targetValue: Double(targetValue) ?? 0,
                    isPublic: isPublic,
                    invitedUsers: Array(invitedFriends)
                )
                dismiss()
            } catch {
                print("Error creating challenge: \(error)")
                isCreating = false
            }
        }
    }
}

struct InviteFriendsView: View {
    @Binding var invitedFriends: Set<String>
    @StateObject private var socialService = MockSocialService()
    
    var body: some View {
        List {
            ForEach(socialService.friends) { friend in
                HStack {
                    AsyncImage(url: friend.profileImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.displayName)
                            .font(.headline)
                        Text("@\(friend.username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        toggleFriendInvitation(friend.id)
                    }) {
                        Image(systemName: invitedFriends.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(invitedFriends.contains(friend.id) ? .blue : .gray)
                            .font(.title2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Invite Friends")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleFriendInvitation(_ friendId: String) {
        if invitedFriends.contains(friendId) {
            invitedFriends.remove(friendId)
        } else {
            invitedFriends.insert(friendId)
        }
    }
}

struct ChallengeDetailView: View {
    let challenge: Challenge
    @StateObject private var socialService = MockSocialService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(challenge.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress")
                        .font(.headline)
                    
                    ProgressView(value: challenge.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("\(Int(challenge.progressPercentage * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Participants
                VStack(alignment: .leading, spacing: 12) {
                    Text("Participants (\(challenge.participants.count))")
                        .font(.headline)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(challenge.participants) { participant in
                            ParticipantRowView(participant: participant)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Challenge Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Challenge Info")
                        .font(.headline)
                    
                    InfoRow(title: "Type", value: challenge.type.displayName)
                    InfoRow(title: "Target", value: "\(challenge.targetValue, specifier: "%.1f") \(challenge.type.unit)")
                    InfoRow(title: "Duration", value: "\(challenge.startDate.formatted(date: .abbreviated, time: .omitted)) - \(challenge.endDate.formatted(date: .abbreviated, time: .omitted))")
                    InfoRow(title: "Status", value: challenge.status.rawValue.capitalized)
                    
                    if let reward = challenge.reward {
                        InfoRow(title: "Reward", value: reward.title)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ParticipantRowView: View {
    let participant: ChallengeParticipant
    
    var body: some View {
        HStack {
            AsyncImage(url: participant.user.profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.user.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Progress: \(Int(participant.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if participant.hasCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView(value: participant.progress)
                    .frame(width: 50)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// Empty state views
struct EmptyActiveChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Active Challenges")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Join a challenge or create your own to start competing!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyCompletedChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Completed Challenges")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Complete challenges to see your achievements here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyBrowseChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Challenges Available")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Check back later for new challenges to join!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// Extensions for better display
extension ChallengeType {
    var displayName: String {
        switch self {
        case .speed:
            return "Speed"
        case .distance:
            return "Distance"
        case .consistency:
            return "Consistency"
        case .improvement:
            return "Improvement"
        }
    }
    
    var unit: String {
        switch self {
        case .speed:
            return "s"
        case .distance:
            return "m"
        case .consistency:
            return "days"
        case .improvement:
            return "%"
        }
    }
    
    static var allCases: [ChallengeType] {
        return [.speed, .distance, .consistency, .improvement]
    }
}

#Preview {
    ChallengesView()
}
