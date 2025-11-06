import SwiftUI
import Combine

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
    @State private var gender: String = "Male"
    @State private var age: Int = 25
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var weight: Double = 170.0
    @State private var fitnessLevel: String = "Intermediate"
    @State private var trainingFrequency: Int = 3
    @State private var personalBest40yd: Double = 5.0
    @State private var leaderboardOptIn: Bool = true
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching onboarding
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            }
                            
                            VStack(spacing: 8) {
                                Text("Edit Profile")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Update your training information")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.top, 20)
                        
                        // Personal Information Section
                        EditSection(title: "Personal Information", icon: "person.fill") {
                            VStack(spacing: 16) {
                                EditField(label: "Name") {
                                    TextField("Enter your name", text: $name)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                EditField(label: "Gender") {
                                    Picker("Gender", selection: $gender) {
                                        ForEach(["Male", "Female", "Other"], id: \.self) { g in
                                            Text(g).tag(g)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                EditField(label: "Age") {
                                    Stepper("Age: \(age)", value: $age, in: 8...100)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Body Metrics Section
                        EditSection(title: "Body Metrics", icon: "figure.run") {
                            VStack(spacing: 16) {
                                EditField(label: "Height") {
                                    HStack(spacing: 12) {
                                        Stepper("Height: \(heightFeet)ft \(heightInches)in", value: $heightFeet, in: 4...7)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                        
                                        Stepper("", value: $heightInches, in: 0...11)
                                            .labelsHidden()
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                EditField(label: "Weight") {
                                    HStack {
                                        TextField("Weight", value: $weight, format: .number.precision(.fractionLength(1)))
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(CustomTextFieldStyle())
                                        
                                        Text("lbs")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        
                        // Performance Section
                        EditSection(title: "Performance", icon: "stopwatch") {
                            VStack(spacing: 16) {
                                EditField(label: "40-Yard Dash Time") {
                                    HStack {
                                        TextField("Time", value: $personalBest40yd, format: .number.precision(.fractionLength(2)))
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(CustomTextFieldStyle())
                                        
                                        Text("seconds")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.subheadline)
                                    }
                                }
                                
                                EditField(label: "Fitness Level") {
                                    Picker("Level", selection: $fitnessLevel) {
                                        ForEach(["Beginner", "Intermediate", "Advanced", "Elite"], id: \.self) { level in
                                            Text(level).tag(level)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                        }
                        
                        // Training Section
                        EditSection(title: "Training Schedule", icon: "calendar.badge.clock") {
                            VStack(spacing: 16) {
                                EditField(label: "Training Frequency") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Whatever the level, all 1–7 day options are always available")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                            .bold()
                                        
                                        Stepper("Days per week: \(trainingFrequency)", value: $trainingFrequency, in: 1...7)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                EditField(label: "Leaderboard Participation") {
                                    Toggle("Participate in leaderboard", isOn: $leaderboardOptIn)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: saveProfile) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.8, blue: 0.0),
                                            Color(red: 1.0, green: 0.6, blue: 0.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            
                            Button(action: { isPresented = false }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadCurrentProfile()
            withAnimation(.easeInOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func loadCurrentProfile() {
        name = userProfileVM.profile.name
        gender = userProfileVM.profile.gender.isEmpty ? "Male" : userProfileVM.profile.gender
        age = userProfileVM.profile.age == 0 ? 25 : userProfileVM.profile.age
        
        // Convert height from inches to feet and inches
        let totalInches = userProfileVM.profile.height == 0 ? 70 : userProfileVM.profile.height
        heightFeet = Int(totalInches / 12)
        heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        
        weight = userProfileVM.profile.weight ?? 170.0
        fitnessLevel = userProfileVM.profile.level.isEmpty ? "Intermediate" : userProfileVM.profile.level
        trainingFrequency = userProfileVM.profile.frequency == 0 ? 3 : userProfileVM.profile.frequency
        personalBest40yd = userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime
        leaderboardOptIn = userProfileVM.profile.leaderboardOptIn
    }
    
    private func saveProfile() {
        // Update profile with all fields
        userProfileVM.profile.name = name
        userProfileVM.profile.gender = gender
        userProfileVM.profile.age = age
        userProfileVM.profile.height = Double(heightFeet * 12 + heightInches)
        userProfileVM.profile.weight = weight
        userProfileVM.profile.level = fitnessLevel
        userProfileVM.profile.frequency = trainingFrequency
        userProfileVM.profile.personalBests["40yd"] = personalBest40yd
        userProfileVM.profile.baselineTime = personalBest40yd
        userProfileVM.profile.leaderboardOptIn = leaderboardOptIn
        
        // Save to UserDefaults for persistence
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(gender, forKey: "userGender")
        UserDefaults.standard.set(age, forKey: "userAge")
        UserDefaults.standard.set(heightFeet * 12 + heightInches, forKey: "userHeight")
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(fitnessLevel, forKey: "userLevel")
        UserDefaults.standard.set(trainingFrequency, forKey: "trainingFrequency")
        UserDefaults.standard.set(personalBest40yd, forKey: "personalBest40yd")
        UserDefaults.standard.set(leaderboardOptIn, forKey: "leaderboardOptIn")
        
        // Trigger save through property change (since saveProfile is private)
        userProfileVM.objectWillChange.send()
        
        print("✅ Profile updated with all onboarding fields")
        isPresented = false
    }
}

// MARK: - Edit Profile Components

struct EditSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Section Content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct EditField<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            
            content
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
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
