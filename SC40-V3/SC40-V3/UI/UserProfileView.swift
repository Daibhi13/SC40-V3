import SwiftUI
import PhotosUI
import HealthKit

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Preview for ProfileView (UserProfileView)
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(userProfileVM: UserProfileViewModel())
            .frame(width: 350, height: 700)
    }
}
// MARK: - Preview showing all views side by side
struct AllViews_Previews: PreviewProvider {
    static var previews: some View {
        let userProfileVM = UserProfileViewModel()
        Group {
            HStack(alignment: .top, spacing: 0) {
                UserProfileView(userProfileVM: userProfileVM)
                    .frame(width: 350, height: 700)
                WelcomeView(onContinue: { _,_ in })
                    .frame(width: 350, height: 700)
            }
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
            HStack(alignment: .top, spacing: 0) {
                UserProfileView(userProfileVM: userProfileVM)
                    .frame(width: 350, height: 700)
                WelcomeView(onContinue: { _,_ in })
                    .frame(width: 350, height: 700)
            }
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        }
    }
}
import SwiftUI
import PhotosUI
import HealthKit

struct UserProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userProfileVM: UserProfileViewModel
    @State private var showImagePicker = false
    #if canImport(UIKit)
    @State private var selectedUIImage: UIImage? = nil
    #endif
    @State private var isEditMode = false
    @State private var editName = ""
    @State private var editGender = ""
    @State private var editAge = 25
    @State private var editWeight: Double = 150.0
    @State private var editHeight: Double = 68.0
    @State private var editLevel = ""
    @State private var editFrequency = 3
    @State private var editLeaderboard = true
    @State private var editPB: Double = 0.0
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                Spacer().frame(height: 56) // Space for where the back button was
                VStack(spacing: 12) {
                    ZStack {
                        #if canImport(UIKit)
                        if let photoData = userProfileVM.profile.photo, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color("Primary"), lineWidth: 3))
                        } else {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 110, height: 110)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color("Primary"))
                                        .font(.system(size: 40))
                                )
                                .overlay(Circle().stroke(Color("Primary"), lineWidth: 3))
                        }
                        #else
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 110, height: 110)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color("Primary"))
                                    .font(.system(size: 40))
                            )
                            .overlay(Circle().stroke(Color("Primary"), lineWidth: 3))
                        #endif
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Circle().fill(Color.clear).frame(width: 110, height: 110)
                        }
                    }
                    // User's name below the camera
                    if isEditMode {
                        TextField("Name", text: $editName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 20)
                    } else {
                        Text(userProfileVM.profile.name)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 8) {
                        Button(action: { /* Edit name */ }) {
                            Image(systemName: "pencil")
                                .foregroundColor(Color("Primary"))
                        }
                    }
                }
                .padding(.bottom, 24)
                VStack(spacing: 0) {
                    profileRow(
                        label: "Import From Apple Health", 
                        value: "\u{2665} IMPORT", 
                        action: {
                            Task {
                                let success = await HealthKitManager.shared.requestAuthorization()
                                if success {
                                    if let profileData = await HealthKitManager.shared.fetchProfileData() {
                                        await MainActor.run {
                                            if let height = profileData.height {
                                                userProfileVM.profile.height = height
                                            }
                                            if let weight = profileData.weight {
                                                userProfileVM.profile.weight = weight
                                            }
                                            if let age = profileData.age {
                                                userProfileVM.profile.age = age
                                            }
                                            if let gender = profileData.gender {
                                                userProfileVM.profile.gender = gender
                                            }
                                            print("✅ Profile updated from HealthKit")
                                        }
                                    }
                                }
                            }
                            //                     userProfileVM.profile.weight = weight
                            //                 }
                            //                 if let age = age {
                            //                     userProfileVM.profile.age = age
                            //                 }
                            //                 if let gender = gender {
                            //                     userProfileVM.profile.gender = gender
                            //                 }
                            //             }
                            //         }
                            //     }
                            // }
                        }, 
                        valueColor: Color("Primary")
                    )
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Gender") {
                            Picker("Gender", selection: $editGender) {
                                ForEach(["Male", "Female", "Other"], id: \.self) { gender in
                                    Text(gender).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    } else {
                        profileRow(label: "Gender", value: userProfileVM.profile.gender, action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Age") {
                            Stepper("Age: \(editAge)", value: $editAge, in: 8...100)
                                .foregroundColor(.white)
                        }
                    } else {
                        profileRow(label: "Age", value: "\(userProfileVM.profile.age)", action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Weight") {
                            Stepper("Weight: \(Int(editWeight)) lbs", value: $editWeight, in: 40...500, step: 1)
                                .foregroundColor(.white)
                        }
                    } else {
                        profileRow(label: "Weight", value: String(format: "%.1f lbs", userProfileVM.profile.weight ?? 0), action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Height") {
                            Stepper("Height: \(Int(editHeight)) in", value: $editHeight, in: 48...84, step: 1)
                                .foregroundColor(.white)
                        }
                    } else {
                        profileRow(label: "Height", value: String(format: "%.0f in", userProfileVM.profile.height), action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Fitness Level") {
                            Picker("Level", selection: $editLevel) {
                                ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                                    Text(level).tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    } else {
                        profileRow(label: "Fitness Level", value: userProfileVM.profile.level, action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Training Days/Week") {
                            Stepper("Days: \(editFrequency)", value: $editFrequency, in: 1...7)
                                .foregroundColor(.white)
                        }
                    } else {
                        profileRow(label: "Training Days/Week", value: "\(userProfileVM.profile.frequency)", action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "Leaderboard Opt-in") {
                            Picker("Leaderboard", selection: $editLeaderboard) {
                                Text("Yes").tag(true)
                                Text("No").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    } else {
                        profileRow(label: "Leaderboard Opt-in", value: userProfileVM.profile.leaderboardOptIn ? "Yes" : "No", action: { })
                    }
                    Divider().background(Color("Accent"))
                    if isEditMode {
                        editableProfileRow(label: "PB (40yd)") {
                            HStack {
                                TextField("PB", value: $editPB, formatter: NumberFormatter())
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 100)
                                Text("seconds")
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        profileRow(label: "PB (40yd)", value: String(format: "%.2f s", userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime), action: { })
                    }
                }
                .background(Color.white.opacity(0.08))
                .cornerRadius(18)
                .padding(.horizontal)
                .padding(.top, 8)
                // Reset Profile Button
                Button(action: {
                    if isEditMode {
                        // Save changes
                        let oldLevel = userProfileVM.profile.level
                        let oldFrequency = userProfileVM.profile.frequency
                        
                        userProfileVM.profile.name = editName
                        userProfileVM.profile.gender = editGender
                        userProfileVM.profile.age = editAge
                        userProfileVM.profile.weight = editWeight
                        userProfileVM.profile.height = editHeight
                        userProfileVM.profile.level = editLevel
                        userProfileVM.profile.frequency = editFrequency
                        userProfileVM.profile.leaderboardOptIn = editLeaderboard
                        userProfileVM.profile.baselineTime = editPB
                        userProfileVM.profile.personalBests["40yd"] = editPB // Keep both values in sync
                        
                        // Regenerate training program if level or frequency changed
                        if oldLevel != editLevel || oldFrequency != editFrequency {
                            userProfileVM.refreshAdaptiveProgram() // Re-enabled - session management fixed
                        }
                        
                        // Exit edit mode
                        isEditMode = false
                    } else {
                        // Initialize edit values with current profile data
                        editName = userProfileVM.profile.name
                        editGender = userProfileVM.profile.gender
                        editAge = userProfileVM.profile.age
                        editWeight = userProfileVM.profile.weight ?? 150.0
                        editHeight = userProfileVM.profile.height
                        editLevel = userProfileVM.profile.level
                        editFrequency = userProfileVM.profile.frequency
                        editLeaderboard = userProfileVM.profile.leaderboardOptIn
                        editPB = userProfileVM.profile.personalBests["40yd"] ?? userProfileVM.profile.baselineTime
                        
                        // Enable edit mode
                        isEditMode = true
                    }
                }) {
                    Text(isEditMode ? "Save Changes" : "Edit Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isEditMode ? Color.green : Color.blue)
                        .cornerRadius(14)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                
                Spacer(minLength: 50) // Add some bottom spacing for scrolling
                
                Text("Accelerate")
                    .font(.headline)
                    .foregroundColor(Color("Primary"))
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    func editableProfileRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
            content()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }
    
    func profileRow(label: String, value: String, action: @escaping () -> Void, valueColor: Color = .white) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
            Spacer()
            Button(action: action) {
                Text(value)
                    .foregroundColor(valueColor)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(valueColor, lineWidth: 1.5)
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .sheet(isPresented: $showImagePicker) {
            #if canImport(UIKit)
            ImagePicker(image: $selectedUIImage)
                .onDisappear {
                    if selectedUIImage != nil {
                        // TODO: Image picker temporarily disabled
                        // userProfileVM.profile.photo = selectedUIImage.jpegData(compressionQuality: 0.8)
                    }
                }
            #else
            Text("Image picker not available on this platform")
            #endif
        }
    }
}

// MARK: - ImagePicker for iOS 15 compatibility
#if canImport(UIKit)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
#endif

// Color extension for palette
// ...existing code...
