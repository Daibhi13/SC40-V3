import SwiftUI

struct EditProfileView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showContent = false
    
    // Local state for editing
    @State private var editGender: String = ""
    @State private var editAge: Int = 0
    @State private var editWeight: Double = 0.0
    @State private var editHeight: Double = 0.0
    @State private var editFitnessLevel: String = ""
    @State private var editTrainingDays: Int = 0
    @State private var editLeaderboardOptIn: Bool = true
    @State private var editPersonalBest: Double = 0.0
    
    let genderOptions = ["Male", "Female", "Other"]
    let fitnessLevels = ["Beginner", "Intermediate", "Advanced", "Elite"]
    let trainingDaysOptions = [1, 2, 3, 4, 5, 6, 7]
    
    var body: some View {
        ZStack {
            // Premium gradient background
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
                VStack(spacing: 20) {
                    // Profile Fields
                    VStack(spacing: 16) {
                        EditableProfileRow(
                            label: "Gender",
                            value: editGender,
                            showContent: showContent,
                            delay: 0.3
                        ) {
                            Menu {
                                ForEach(genderOptions, id: \.self) { option in
                                    Button(option) {
                                        editGender = option
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(editGender.isEmpty ? "Select" : editGender)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        EditableProfileRow(
                            label: "Age",
                            value: editAge == 0 ? "" : "\(editAge)",
                            showContent: showContent,
                            delay: 0.4
                        ) {
                            TextField("Age", value: $editAge, format: .number)
                                .textFieldStyle(ProfileTextFieldStyle())
                        }
                        
                        EditableProfileRow(
                            label: "Weight",
                            value: editWeight == 0 ? "" : "\(String(format: "%.1f", editWeight)) lbs",
                            showContent: showContent,
                            delay: 0.5
                        ) {
                            TextField("Weight", value: $editWeight, format: .number)
                                .textFieldStyle(ProfileTextFieldStyle())
                        }
                        
                        EditableProfileRow(
                            label: "Height",
                            value: editHeight == 0 ? "" : "\(Int(editHeight)) in",
                            showContent: showContent,
                            delay: 0.6
                        ) {
                            TextField("Height", value: $editHeight, format: .number)
                                .textFieldStyle(ProfileTextFieldStyle())
                        }
                        
                        EditableProfileRow(
                            label: "Fitness Level",
                            value: editFitnessLevel,
                            showContent: showContent,
                            delay: 0.7
                        ) {
                            Menu {
                                ForEach(fitnessLevels, id: \.self) { level in
                                    Button(level) {
                                        editFitnessLevel = level
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(editFitnessLevel.isEmpty ? "Select" : editFitnessLevel)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        EditableProfileRow(
                            label: "Training Days/Week",
                            value: editTrainingDays == 0 ? "" : "\(editTrainingDays)",
                            showContent: showContent,
                            delay: 0.8
                        ) {
                            Menu {
                                ForEach(trainingDaysOptions, id: \.self) { days in
                                    Button("\(days)") {
                                        editTrainingDays = days
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(editTrainingDays == 0 ? "Select" : "\(editTrainingDays)")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        EditableProfileRow(
                            label: "Leaderboard Opt-in",
                            value: editLeaderboardOptIn ? "Yes" : "No",
                            showContent: showContent,
                            delay: 0.9
                        ) {
                            Toggle("", isOn: $editLeaderboardOptIn)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.8, blue: 0.0)))
                        }
                        
                        EditableProfileRow(
                            label: "PB (40yd)",
                            value: editPersonalBest == 0 ? "" : "\(String(format: "%.2f", editPersonalBest)) s",
                            showContent: showContent,
                            delay: 1.0
                        ) {
                            TextField("Personal Best", value: $editPersonalBest, format: .number)
                                .textFieldStyle(ProfileTextFieldStyle())
                        }
                    }
                    .padding(.top, 40)
                    
                    // Edit Profile Button
                    Button(action: {
                        HapticManager.shared.medium()
                        saveProfile()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Text("Edit Profile")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
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
                        .cornerRadius(16)
                        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(1.1), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadCurrentValues()
            showContent = true
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
    
    private func loadCurrentValues() {
        editGender = userProfileVM.profile.gender.isEmpty ? "Male" : userProfileVM.profile.gender
        editAge = userProfileVM.profile.age == 0 ? 25 : userProfileVM.profile.age
        editWeight = userProfileVM.profile.weight ?? 170.0
        editHeight = userProfileVM.profile.height == 0 ? 70.0 : userProfileVM.profile.height
        editFitnessLevel = userProfileVM.profile.level.isEmpty ? "Intermediate" : userProfileVM.profile.level
        editTrainingDays = userProfileVM.profile.frequency == 0 ? 3 : userProfileVM.profile.frequency
        editLeaderboardOptIn = userProfileVM.profile.leaderboardOptIn
        editPersonalBest = userProfileVM.profile.baselineTime == 0 ? 5.25 : userProfileVM.profile.baselineTime
    }
    
    private func saveProfile() {
        userProfileVM.profile.gender = editGender
        userProfileVM.profile.age = editAge
        userProfileVM.profile.weight = editWeight
        userProfileVM.profile.height = editHeight
        userProfileVM.profile.level = editFitnessLevel
        userProfileVM.profile.frequency = editTrainingDays
        userProfileVM.profile.leaderboardOptIn = editLeaderboardOptIn
        userProfileVM.profile.baselineTime = editPersonalBest
        userProfileVM.profile.personalBests["40yd"] = editPersonalBest
        
        // Profile will auto-save due to didSet in UserProfileViewModel
    }
}

// MARK: - Editable Profile Row Component

struct EditableProfileRow<Content: View>: View {
    let label: String
    let value: String
    let showContent: Bool
    let delay: Double
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            content
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(delay), value: showContent)
    }
}

// MARK: - Profile Text Field Style

struct ProfileTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Referrals View

struct ReferralsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
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
                
                VStack(spacing: 24) {
                    Text("🎁 Invite Friends")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Share Sprint Coach 40 with friends and earn rewards!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Referrals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

