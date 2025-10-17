import SwiftUI
import Combine

struct PrivacySettingsView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var leaderboardOptIn: Bool = true

    init(userProfileVM: UserProfileViewModel) {
        self.userProfileVM = userProfileVM
        _leaderboardOptIn = State(initialValue: userProfileVM.profile.leaderboardOptIn)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Leaderboard Privacy")) {
                    Toggle(isOn: $leaderboardOptIn) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show my stats on Leaderboard")
                                .font(.headline)
                            Text("Opt out to keep your stats private from others. You will still see the leaderboard for motivation.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: leaderboardOptIn) { _, newValue in
                        userProfileVM.profile.leaderboardOptIn = newValue
                    }
                }
            }
            .navigationTitle("Privacy Settings")
        }
    }
}

#Preview {
    PrivacySettingsView(userProfileVM: UserProfileViewModel())
}
