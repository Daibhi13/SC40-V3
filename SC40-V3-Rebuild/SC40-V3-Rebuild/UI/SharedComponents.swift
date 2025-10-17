import SwiftUI

// MARK: - Shared Components for DashboardView and TrainingView

struct PersonalBestCard: View {
    var personalBest: Double
    var date: String
    var competition: String
    var rank: String
    @State private var showEditPB = false
    @State private var newPB: String = ""
    @State private var showEditProfile = false
    @EnvironmentObject var userProfileVM: UserProfileViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Personal Best")
                .font(.headline)
                .foregroundColor(.brandPrimary)
            HStack {
                Text(String(format: "%.2f s", personalBest))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.brandPrimary)
                    .onTapGesture {
                        showEditPB = true
                    }
                    .onLongPressGesture {
                        showEditProfile = true
                    }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Date: \(date)")
                    Text("Event: \(competition)")
                    Text("Rank: \(rank)")
                }
                .font(.subheadline)
                .foregroundColor(.brandSecondary)
            }
        }
        .padding()
        .background(Color.brandAccent.opacity(0.2))
        .cornerRadius(16)
        .sheet(isPresented: $showEditPB) {
            VStack(spacing: 20) {
                Text("Edit Personal Best")
                    .font(.title2.bold())
                TextField("New PB (seconds)", text: $newPB)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Save") {
                    if let pbValue = Double(newPB) {
                        userProfileVM.profile.personalBests["40yd"] = pbValue
                        userProfileVM.profile.baselineTime = pbValue // Keep both values in sync
                    }
                    showEditPB = false
                }
                .buttonStyle(.borderedProminent)
                Button("Cancel") { showEditPB = false }
            }
            .padding()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(userProfileVM: userProfileVM, isPresented: $showEditProfile)
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var weight: String = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Profile").font(.title2.bold())
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Age", text: $age)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Weight (lbs)", text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Save") {
                userProfileVM.profile.name = name
                if let ageVal = Int(age) { userProfileVM.profile.age = ageVal }
                if let weightVal = Double(weight) { userProfileVM.profile.weight = weightVal }
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            Button("Cancel") { isPresented = false }
        }
        .padding()
        .onAppear {
            name = userProfileVM.profile.name
            age = String(userProfileVM.profile.age)
            weight = userProfileVM.profile.weight != nil ? String(format: "%.1f", userProfileVM.profile.weight!) : ""
        }
    }
}

struct KeyMetricsStrip: View {
    var profile: UserProfile
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                MetricCard(title: "Reaction", value: String(format: "%.2fs", profile.personalBests["reaction"] ?? 0.18), color: .brandTertiary)
                MetricCard(title: "10m Split", value: String(format: "%.2fs", profile.personalBests["10m"] ?? 1.60), color: .brandTertiary)
                MetricCard(title: "20m Split", value: String(format: "%.2fs", profile.personalBests["20m"] ?? 2.80), color: .brandTertiary)
                MetricCard(title: "Max Velocity", value: String(format: "%.1f mph", (profile.personalBests["maxV"] ?? 10.2) * 2.23694), color: .brandTertiary)
                MetricCard(title: "Endurance", value: profile.personalBests["endurance"] != nil ? "Strong" : "-", color: .brandPrimary)
            }
            .padding(.horizontal)
        }
    }
}

// REMOVE this duplicate PerformanceTrendsView to avoid redeclaration error
// struct PerformanceTrendsView: View {
//     var sessions: [TrainingSession]
//     var body: some View {
//         VStack(alignment: .leading, spacing: 12) {
//             Text("Performance Trends")
//                 .font(.title3.bold())
//                 .foregroundColor(.brandSecondary.opacity(0.9))
//             RoundedRectangle(cornerRadius: 14)
//                 .fill(Color.brandTertiary.opacity(0.3))
//                 .frame(height: 180)
//                 .overlay(
//                     VStack {
//                         Text("Progress Over Last \(min(10, sessions.count)) Sessions")
//                             .foregroundColor(.brandSecondary)
//                             .font(.caption)
//                         Spacer()
//                         Text("📈 Trend Graph Placeholder")
//                             .foregroundColor(.brandSecondary.opacity(0.8))
//                             .font(.footnote)
//                         Spacer()
//                     }
//                     .padding()
//                 )
//         }
//         .padding(.horizontal)
//     }
// }

struct MetricCard: View {
    var title: String
    var value: String
    var color: Color = .blue
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.brandSecondary.opacity(0.7))
            Text(value)
                .font(.headline)
                .foregroundColor(.brandSecondary)
        }
        .frame(width: 70, height: 60)
        .background(color.opacity(0.7))
        .cornerRadius(10)
    }
}

struct ProFeaturesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlock Pro Features")
                .font(.title2.bold())
                .foregroundColor(.brandPrimary)
            VStack(spacing: 12) {
                ProFeatureRow(title: "Advanced Analytics", description: "Dive deep into your performance metrics.", isPro: true)
                ProFeatureRow(title: "Personalized Coaching", description: "1-on-1 coaching sessions with experts.", isPro: true)
                ProFeatureRow(title: "Exclusive Content", description: "Access to premium training videos and articles.", isPro: false)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.brandAccent.opacity(0.7))
        .cornerRadius(16)
    }
}

struct ProFeatureRow: View {
    var title: String
    var description: String
    var isPro: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.brandSecondary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.brandSecondary.opacity(0.7))
            }
            Spacer()
            if isPro {
                Text("PRO")
                    .font(.caption.bold())
                    .foregroundColor(.brandPrimary)
                    .padding(6)
                    .background(Color.brandAccent.opacity(0.7))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TrainingProgressSection: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @State private var showGoalSheet = false
    @State private var newGoal: String = ""
    var completedSessions: Int {
        userProfileVM.profile.completedSessionIDs.count
    }
    var totalSessions: Int { userProfileVM.profile.sessionIDs.count }
    var streak: Int {
        // Simple streak: consecutive completed sessions from the end
        return userProfileVM.profile.completedSessionIDs.count
    }
    var currentGoal: String {
        userProfileVM.profile.personalBests["goal"] != nil ? String(format: "%.2f s", userProfileVM.profile.personalBests["goal"]!) : "No goal set"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Training Progress")
                .font(.title3.bold())
                .foregroundColor(.brandPrimary)
            ProgressView(value: Double(completedSessions), total: Double(max(1, totalSessions))) {
                Text("\(completedSessions) of \(totalSessions) sessions completed")
                    .font(.subheadline)
            }
            .accentColor(.brandPrimary)
            HStack {
                Text("Streak: \(streak) 🔥")
                    .font(.subheadline)
                Spacer()
                Button(action: { showGoalSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                        Text("Goal: \(currentGoal)")
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.brandAccent.opacity(0.18))
        .cornerRadius(14)
        .sheet(isPresented: $showGoalSheet) {
            VStack(spacing: 20) {
                Text("Set New Goal")
                    .font(.title2.bold())
                TextField("Goal (seconds)", text: $newGoal)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Save Goal") {
                    if let goalValue = Double(newGoal) {
                        userProfileVM.profile.personalBests["goal"] = goalValue
                    }
                    showGoalSheet = false
                }
                .buttonStyle(.borderedProminent)
                Button("Cancel") { showGoalSheet = false }
            }
            .padding()
        }
    }
}

// MARK: - US DateFormatter
extension DateFormatter {
    static let usShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
}
