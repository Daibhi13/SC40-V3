import SwiftUI

// Import UserProfileViewModel from Models
struct OnboardingView: View {
    var userName: String
    @ObservedObject var userProfileVM: UserProfileViewModel
    var onComplete: () -> Void
    
    @State private var gender = "Male"
    @State private var age = 25
    @State private var heightFeet = 5
    @State private var heightInches = 10
    @State private var weight = 170
    @State private var fitnessLevel = "Intermediate"
    @State private var daysAvailable = 3
    @State private var pbSeconds: Int = 5
    @State private var pbTenthsHundredths: Int = 25
    @State private var leaderboardOptIn: Bool = true
    @State private var showManualOverride = false
    
    // Computed property to convert wheel selections to Double
    private var pb: Double {
        Double(pbSeconds) + Double(pbTenthsHundredths) / 100.0
    }
    
    let feetRange = Array(4...7)
    let inchRange = Array(0...11)
    let ageRange = Array(8...100)
    let weightRange = Array(40...500)
    
    // Premium gradient background matching the design
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),  // Dark blue top
                Color(red: 0.2, green: 0.1, blue: 0.3),  // Purple middle
                Color(red: 0.1, green: 0.05, blue: 0.2)  // Dark purple bottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with progress matching the design
                        VStack(spacing: 16) {
                            Text("Welcome, \(userName)!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Let's build your personalized training program")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Progress bar matching the design
                            HStack(spacing: 0) {
                                ForEach(0..<5) { index in
                                    Rectangle()
                                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                        .frame(height: 4)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .cornerRadius(2)
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal)
                        
                        pbSection
                        profileSection
                        bodyMetricsSection
                        scheduleSection
                        leaderboardSection
                        
                        Spacer(minLength: 80) // leaves space for sticky finish button
                    }
                    .padding()
                }
                
                // Sticky Finish Button
                VStack {
                    Spacer()
                    finishButton
                        .padding()
                        .glassEffect()
                        .background(
                            Color.black
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
    
    // MARK: - 40 Yard PB Section
    private var pbSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section header with icon and badge
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "stopwatch.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("40 Yard Personal Best")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("1/5")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            
                Text("This is the foundation of your training program. Be honest for best results.")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    // Seconds wheel (3-7 seconds)
                    VStack {
                        Text("Seconds")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .bold()
                        
                        Picker("Seconds", selection: $pbSeconds) {
                            ForEach(3...8, id: \.self) { second in
                                Text("\(second)")
                                    .foregroundColor(.white)
                                    .font(.title2.bold())
                                    .tag(second)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        #else
                        .pickerStyle(MenuPickerStyle())
                        #endif
                        .frame(width: 80, height: 120)
                        .clipped()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                    
                    Text(".")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.top, 20)
                    
                    // Tenths and hundredths wheel (00-99)
                    VStack {
                        Text("Hundredths")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .bold()
                        
                        Picker("Hundredths", selection: $pbTenthsHundredths) {
                            ForEach(0...99, id: \.self) { hundredths in
                                Text(String(format: "%02d", hundredths))
                                    .foregroundColor(.white)
                                    .font(.title2.bold())
                                    .tag(hundredths)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        #else
                        .pickerStyle(MenuPickerStyle())
                        #endif
                        .frame(width: 80, height: 120)
                        .clipped()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                    
                    Text("s")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.top, 20)
                }
                
                // Display the selected time with better styling
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(String(format: "%.2f", pb))s")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                    
                    // Level classification with badge
                    if pb > 0 {
                        let level = classify_40yd_time(time: Float(pb), gender: gender)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Level")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(level)
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(levelColor(level))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    // Helper function for level colors
    private func levelColor(_ level: String) -> Color {
        switch level {
        case "Beginner": return Color.blue
        case "Intermediate": return Color.green
        case "Advanced": return Color.orange
        case "Elite": return Color.purple
        default: return Color.gray
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Profile Information")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("2/5")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            
                Text("Gender")
                    .foregroundColor(.yellow)
                    .bold()
                Picker("Gender", selection: $gender) {
                    ForEach(["Male", "Female", "Other"], id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level")
                        .foregroundColor(.yellow)
                        .bold()
                    
                    if pb > 0 {
                        let autoLevel = classify_40yd_time(time: Float(pb), gender: gender)
                        HStack {
                            Text("Auto-detected: \(autoLevel)")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            Spacer()
                            Button("Override") {
                                showManualOverride.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .onAppear {
                            if !showManualOverride {
                                fitnessLevel = autoLevel
                            }
                        }
                        .onChange(of: pbSeconds) { _, _ in
                            if pb > 0 && !showManualOverride {
                                fitnessLevel = classify_40yd_time(time: Float(pb), gender: gender)
                            }
                        }
                        .onChange(of: pbTenthsHundredths) { _, _ in
                            if pb > 0 && !showManualOverride {
                                fitnessLevel = classify_40yd_time(time: Float(pb), gender: gender)
                            }
                        }
                        .onChange(of: gender) { _, _ in
                            if pb > 0 && !showManualOverride {
                                fitnessLevel = classify_40yd_time(time: Float(pb), gender: gender)
                            }
                        }
                    } else {
                        Text("Select your 40-yard time above for automatic level detection")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Picker("Level", selection: $fitnessLevel) {
                        ForEach(["Beginner", "Intermediate", "Advanced", "Elite"], id: \.self) { lvl in
                            Text(lvl).tag(lvl)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(pb > 0 && !showManualOverride) // Disable manual selection when auto-detected
                }
            }
        }
    }
    
    // MARK: - Body Metrics Section
    private var bodyMetricsSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Body Metrics")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("3/5")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            
                VStack(alignment: .leading, spacing: 12) {
                    Stepper("Age: \(age)", value: $age, in: 8...100)
                        .foregroundColor(.white)
                    
                    HStack {
                        Stepper("Height: \(heightFeet)ft \(heightInches)in", value: $heightFeet, in: 4...7)
                            .foregroundColor(.white)
                        Stepper("", value: $heightInches, in: 0...11)
                    }
                    
                    Stepper("Weight: \(weight) lbs", value: $weight, in: 40...500)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Schedule Section
    private var scheduleSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Training Schedule")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("4/5")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Stepper("Days per week: \(daysAvailable)", value: $daysAvailable, in: 1...7)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Compete & Compare")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("5/5")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Picker("Opt in to Leaderboard", selection: $leaderboardOptIn) {
                    Text("Yes").tag(true)
                    Text("No").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
    
    // MARK: - Finish Button
    private var finishButton: some View {
        VStack(spacing: 12) {
            // Summary card
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to Start")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Your \(String(format: "%.2f", pb))s program is ready")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            Button(action: {
            userProfileVM.profile.name = userName
            userProfileVM.profile.gender = gender
            userProfileVM.profile.age = age
            userProfileVM.profile.height = Double(heightFeet * 12 + heightInches)
            userProfileVM.profile.weight = Double(weight)
            userProfileVM.profile.level = fitnessLevel
            userProfileVM.profile.baselineTime = pb
            userProfileVM.profile.personalBests["40yd"] = pb // Also update the personalBests dictionary
            userProfileVM.profile.frequency = daysAvailable
            userProfileVM.profile.leaderboardOptIn = leaderboardOptIn
            // userProfileVM.profile.sessions = [] // Removed - using UUID-based session management
            
            // Debug: Verify the personal best is set correctly
            print("🏃‍♂️ Onboarding: Setting personal best to \(pb)s")
            print("🏃‍♂️ Onboarding: personalBests['40yd'] = \(userProfileVM.profile.personalBests["40yd"] ?? 0.0)")
            print("🏃‍♂️ Onboarding: baselineTime = \(userProfileVM.profile.baselineTime)")
            
            // Generate the appropriate training program based on user's selections
            userProfileVM.refreshAdaptiveProgram() // Re-enabled - session management fixed
            
                onComplete()
            }) {
                HStack {
                    Text("Generate My Training Program")
                        .font(.headline.bold())
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.black)
                .cornerRadius(16)
                .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 5)
            }
        }
    }
    
    // MARK: - Reusable Section Card
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .glassEffect()
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    
    /// Classifies a 40-yard dash time into training levels based on gender-specific performance standards
    private func classify_40yd_time(time: Float, gender: String) -> String {
        let normalizedGender = gender.lowercased()
        
        switch normalizedGender {
        case "male":
            if time >= 6.0 {
                return "Beginner"
            } else if time >= 5.2 {
                return "Intermediate"
            } else if time >= 4.6 {
                return "Advanced"
            } else {
                return "Elite"
            }
            
        case "female":
            if time >= 6.5 {
                return "Beginner"
            } else if time >= 5.7 {
                return "Intermediate"
            } else if time >= 5.2 {
                return "Advanced"
            } else {
                return "Elite"
            }
            
        default:
            // Default to male standards if gender is not recognized
            if time >= 6.0 {
                return "Beginner"
            } else if time >= 5.2 {
                return "Intermediate"
            } else if time >= 4.6 {
                return "Advanced"
            } else {
                return "Elite"
            }
        }
    }
}

// MARK: - Text Styling Extension
extension Text {
    func sectionHeader() -> some View {
        self
            .font(.headline.bold())
            .foregroundColor(.yellow)
    }
}

#Preview {
    NavigationView {
        OnboardingView(userName: "Test", userProfileVM: UserProfileViewModel(), onComplete: {})
    }
}
