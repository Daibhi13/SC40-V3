import SwiftUI
import Combine

struct FriendsView: View {
    @StateObject private var socialService = MockSocialService()
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var isAddingFriend = false
    @State private var newFriendUsername = ""
    @State private var showingAddFriendAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Tab Selector
                Picker("Friends Tab", selection: $selectedTab) {
                    Text("Friends (\(socialService.friends.count))").tag(0)
                    Text("Requests (\(socialService.friendRequests.count))").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    FriendsListView(friends: filteredFriends)
                        .tag(0)
                    
                    FriendRequestsView(requests: socialService.friendRequests)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $isAddingFriend) {
                AddFriendView(
                    username: $newFriendUsername,
                    onAdd: addFriend,
                    onCancel: {
                        isAddingFriend = false
                        newFriendUsername = ""
                    }
                )
            }
            .alert("Friend Request", isPresented: $showingAddFriendAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadFriends()
        }
    }
    
    private var filteredFriends: [SocialUser] {
        if searchText.isEmpty {
            return socialService.friends
        } else {
            return socialService.friends.filter { friend in
                friend.username.localizedCaseInsensitiveContains(searchText) ||
                friend.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadFriends() {
        Task {
            do {
                try await socialService.loadFriends()
            } catch {
                print("Error loading friends: \(error)")
            }
        }
    }
    
    private func addFriend() {
        guard !newFriendUsername.isEmpty else { return }
        
        Task {
            do {
                try await socialService.addFriend(username: newFriendUsername)
                alertMessage = "Friend request sent to \(newFriendUsername)!"
                showingAddFriendAlert = true
                isAddingFriend = false
                newFriendUsername = ""
            } catch {
                alertMessage = "Failed to send friend request: \(error.localizedDescription)"
                showingAddFriendAlert = true
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search friends...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct FriendsListView: View {
    let friends: [SocialUser]
    @StateObject private var socialService = MockSocialService()
    
    var body: some View {
        List {
            if friends.isEmpty {
                EmptyFriendsView()
            } else {
                ForEach(friends) { friend in
                    FriendRowView(friend: friend, socialService: socialService)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct FriendRowView: View {
    let friend: SocialUser
    let socialService: MockSocialService
    @State private var showingProfile = false
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack {
            // Profile Image
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
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(friend.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let lastSeen = friend.lastSeen {
                    Text("Last seen \(lastSeen, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(friend.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            showingProfile = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Remove", role: .destructive) {
                showingRemoveAlert = true
            }
        }
        .sheet(isPresented: $showingProfile) {
            FriendProfileView(friend: friend)
        }
        .alert("Remove Friend", isPresented: $showingRemoveAlert) {
            Button("Remove", role: .destructive) {
                removeFriend()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(friend.displayName) as a friend?")
        }
    }
    
    private func removeFriend() {
        Task {
            do {
                try await socialService.removeFriend(userId: friend.id)
            } catch {
                print("Error removing friend: \(error)")
            }
        }
    }
}

struct FriendRequestsView: View {
    let requests: [FriendRequest]
    @StateObject private var socialService = MockSocialService()
    
    var body: some View {
        List {
            if requests.isEmpty {
                EmptyRequestsView()
            } else {
                ForEach(requests) { request in
                    FriendRequestRowView(request: request, socialService: socialService)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct FriendRequestRowView: View {
    let request: FriendRequest
    let socialService: MockSocialService
    
    var body: some View {
        HStack {
            // Profile Image
            AsyncImage(url: request.fromUser.profileImageURL) { image in
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
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUser.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(request.fromUser.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Sent \(request.createdAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Accept") {
                    acceptRequest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Decline") {
                    declineRequest()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func acceptRequest() {
        Task {
            do {
                try await socialService.acceptFriendRequest(requestId: request.id)
            } catch {
                print("Error accepting friend request: \(error)")
            }
        }
    }
    
    private func declineRequest() {
        Task {
            do {
                try await socialService.declineFriendRequest(requestId: request.id)
            } catch {
                print("Error declining friend request: \(error)")
            }
        }
    }
}

struct AddFriendView: View {
    @Binding var username: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Friend")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your friend's username to send them a friend request")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button("Send Request") {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add friends to compete in challenges and see their progress!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Friend Requests")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Friend requests will appear here when someone wants to connect with you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct FriendProfileView: View {
    let friend: SocialUser
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        AsyncImage(url: friend.profileImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(spacing: 4) {
                            Text(friend.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("@\(friend.username)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let bio = friend.bio {
                            Text(bio)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stats")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(title: "Friends", value: "\(friend.friendsCount)")
                            StatCard(title: "Challenges", value: "\(friend.completedChallenges)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    FriendsView()
}
