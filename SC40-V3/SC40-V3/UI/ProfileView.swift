import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showContent = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var showEditProfile = false
    
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
                VStack(spacing: 24) {
                    // Header with profile icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: showContent)
                        
                        VStack(spacing: 8) {
                            Text("Profile")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Manage your information")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
                    }
                    .padding(.top, 40)
                    
                    // Profile Picture Section
                    VStack(spacing: 16) {
                        Button(action: {
                            HapticManager.shared.light()
                            showImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                                
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.7), value: showContent)
                        
                        Text(userProfileVM.profile.name.isEmpty ? "Your Name" : userProfileVM.profile.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.9), value: showContent)
                    }
                    
                    // Import from Apple Health Button
                    Button(action: {
                        HapticManager.shared.light()
                        // Import from Apple Health logic
                    }) {
                        Text("Import From Apple Health")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(1.1), value: showContent)
                    
                    // Profile Information
                    VStack(spacing: 16) {
                        ProfileInfoRow(
                            label: "Gender",
                            value: userProfileVM.profile.gender.isEmpty ? "Male" : userProfileVM.profile.gender,
                            showContent: showContent,
                            delay: 1.3
                        )
                        
                        ProfileInfoRow(
                            label: "Age",
                            value: userProfileVM.profile.age == 0 ? "25" : "\(userProfileVM.profile.age)",
                            showContent: showContent,
                            delay: 1.4
                        )
                        
                        ProfileInfoRow(
                            label: "Weight",
                            value: (userProfileVM.profile.weight ?? 0) == 0 ? "170.0 lbs" : "\(String(format: "%.1f", userProfileVM.profile.weight ?? 170.0)) lbs",
                            showContent: showContent,
                            delay: 1.5
                        )
                        
                        ProfileInfoRow(
                            label: "Height",
                            value: userProfileVM.profile.height == 0 ? "70 in" : "\(userProfileVM.profile.height) in",
                            showContent: showContent,
                            delay: 1.6
                        )
                        
                        ProfileInfoRow(
                            label: "Fitness Level",
                            value: userProfileVM.profile.level.isEmpty ? "Intermediate" : userProfileVM.profile.level,
                            showContent: showContent,
                            delay: 1.7
                        )
                        
                        ProfileInfoRow(
                            label: "Training Days/Week",
                            value: userProfileVM.profile.frequency == 0 ? "3" : "\(userProfileVM.profile.frequency)",
                            showContent: showContent,
                            delay: 1.8
                        )
                        
                        ProfileInfoRow(
                            label: "Leaderboard Opt-in",
                            value: userProfileVM.profile.leaderboardOptIn ? "Yes" : "No",
                            showContent: showContent,
                            delay: 1.9
                        )
                        
                        ProfileInfoRow(
                            label: "PB (40yd)",
                            value: userProfileVM.profile.baselineTime == 0 ? "5.25 s" : "\(String(format: "%.2f", userProfileVM.profile.baselineTime)) s",
                            showContent: showContent,
                            delay: 2.0
                        )
                    }
                    
                    // Edit Profile Button
                    Button(action: {
                        HapticManager.shared.medium()
                        showEditProfile = true
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
                    .animation(.easeInOut(duration: 0.8).delay(2.1), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            showContent = true
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            profileImage = uiImage
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(userProfileVM: userProfileVM)
        }
    }
}

// MARK: - Profile Info Row Component

struct ProfileInfoRow: View {
    let label: String
    let value: String
    let showContent: Bool
    let delay: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(delay), value: showContent)
    }
}
