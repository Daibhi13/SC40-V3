import SwiftUI

struct EditProfileView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var level: String = ""
    @State private var frequency: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section("Physical Stats") {
                    TextField("Height (inches)", text: $height)
                        .keyboardType(.decimalPad)
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section("Training") {
                    Picker("Level", selection: $level) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                        Text("Elite").tag("Elite")
                    }
                    
                    Picker("Training Frequency", selection: $frequency) {
                        Text("2 days/week").tag("2")
                        Text("3 days/week").tag("3")
                        Text("4 days/week").tag("4")
                        Text("5 days/week").tag("5")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private func loadCurrentProfile() {
        name = userProfileVM.profile.name
        email = userProfileVM.profile.email ?? ""
        age = "\(userProfileVM.profile.age)"
        height = "\(userProfileVM.profile.height)"
        weight = "\(userProfileVM.profile.weight)"
        level = userProfileVM.profile.level
        frequency = "\(userProfileVM.profile.frequency)"
    }
    
    private func saveProfile() {
        userProfileVM.profile.name = name
        userProfileVM.profile.email = email.isEmpty ? nil : email
        userProfileVM.profile.age = Int(age) ?? userProfileVM.profile.age
        userProfileVM.profile.height = Double(height) ?? userProfileVM.profile.height
        userProfileVM.profile.weight = Double(weight) ?? userProfileVM.profile.weight
        userProfileVM.profile.level = level
        userProfileVM.profile.frequency = Int(frequency) ?? userProfileVM.profile.frequency
    }
}

#Preview {
    EditProfileView(
        userProfileVM: UserProfileViewModel(),
        isPresented: .constant(true)
    )
}

