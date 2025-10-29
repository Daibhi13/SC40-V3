import SwiftUI

// Import UserProfileViewModel from Models
struct OnboardingView: View {
    var userName: String
    @ObservedObject var userProfileVM: UserProfileViewModel
    var onComplete: () -> Void
    
    @StateObject private var workflowManager = TrainingPreferencesWorkflow()
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
    @State private var gender = "Male"
    @State private var age = 25
    @State private var heightFeet = 5
    @State private var heightInches = 10
    @State private var weight = 170
    @State private var fitnessLevel = "Intermediate"
    @State private var hasUserManuallySelectedLevel = false
    @State private var daysAvailable = 3
    @State private var pbSeconds: Int = 5
    @State private var pbTenthsHundredths: Int = 25
    @State private var leaderboardOptIn: Bool = true
    
    // Computed property to convert wheel selections to Double
    private var pb: Double {
        Double(pbSeconds) + Double(pbTenthsHundredths) / 100.0
    }
    
    // Computed property to estimate total sessions in 12-week program
    private var estimatedSessions: Int {
        let trainingDaysPerWeek = daysAvailable >= 6 ? daysAvailable - 1 : daysAvailable // Account for recovery days
        let totalTrainingDays = trainingDaysPerWeek * 12
        let timeTrialDays = 4 // Weeks 1, 4, 8, 12
        return totalTrainingDays + timeTrialDays
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
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Header with progress matching the design
                        VStack(spacing: 16) {
                            Text("Welcome, \(userName)!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Let's build your personalized training program")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Enhanced progress bar with animation
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { index in
                                        Rectangle()
                                            .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                            .frame(height: 4)
                                            .frame(maxWidth: .infinity)
                                            .cornerRadius(2)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                Text("5 Questions • 2 minutes")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        
                        // Questions sections with improved spacing
                        Group {
                            pbSection
                            profileSection
                            bodyMetricsSection
                            scheduleSection
                            leaderboardSection
                        }
                        
                        // Extra bottom padding for sticky button - increased to prevent overlap
                        Spacer(minLength: 200)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                // Enhanced Sticky Finish Button
                VStack {
                    Spacer()
                    
                    // Gradient fade overlay for better visual separation
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)
                    
                    finishButton
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            Color.black.opacity(0.8)
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
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
                            Text("Suggested: \(autoLevel)")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            Spacer()
                            Text("(You can override)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .onAppear {
                            // Only auto-set level if user hasn't manually selected one
                            if !hasUserManuallySelectedLevel && fitnessLevel == "Intermediate" {
                                fitnessLevel = autoLevel
                            }
                        }
                    } else {
                        Text("Select your 40-yard time above for automatic level suggestion")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    Picker("Level", selection: $fitnessLevel) {
                        ForEach(["Beginner", "Intermediate", "Advanced", "Elite"], id: \.self) { lvl in
                            Text(lvl).tag(lvl)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: fitnessLevel) { _ in
                        // Mark that user has manually selected a level
                        hasUserManuallySelectedLevel = true
                    }
                    // Always allow manual selection - user choice is paramount
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
            
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .bold()
                        Stepper("Age: \(age)", value: $age, in: 8...100)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .bold()
                        HStack(spacing: 12) {
                            Stepper("Height: \(heightFeet)ft \(heightInches)in", value: $heightFeet, in: 4...7)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(10)
                            Stepper("", value: $heightInches, in: 0...11)
                                .labelsHidden()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .bold()
                        Stepper("Weight: \(weight) lbs", value: $weight, in: 40...500)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                    }
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Frequency")
                        .foregroundColor(.yellow)
                        .font(.caption)
                        .bold()
                    
                    Text("All 1-7 day options are available regardless of your level")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 4)
                    
                    Stepper("Days per week: \(daysAvailable)", value: $daysAvailable, in: 1...7)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                }
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Join the global leaderboard and compete with other athletes?")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Picker("Opt in to Leaderboard", selection: $leaderboardOptIn) {
                        Text("Yes, I'm in!").tag(true)
                        Text("No thanks").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
    
    // MARK: - Enhanced Finish Button
    private var finishButton: some View {
        VStack(spacing: 16) {
            // Enhanced summary card with program details
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Program Ready")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(fitnessLevel) • \(daysAvailable) days/week • \(String(format: "%.2f", pb))s baseline")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // Program features preview
                HStack(spacing: 16) {
                    FeaturePreview(icon: "calendar", text: "12 Weeks", color: .blue)
                    FeaturePreview(icon: "figure.run", text: "\(estimatedSessions) Sessions", color: .green)
                    FeaturePreview(icon: "target", text: "Time Trials", color: .orange)
                    if daysAvailable >= 6 {
                        FeaturePreview(icon: "leaf", text: "Recovery", color: .mint)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            Button(action: {
            // Save all user profile data
            userProfileVM.profile.name = userName
            userProfileVM.profile.gender = gender
            userProfileVM.profile.age = age
            userProfileVM.profile.height = Double(heightFeet * 12 + heightInches)
            userProfileVM.profile.weight = Double(weight)
            userProfileVM.profile.level = fitnessLevel
            userProfileVM.profile.baselineTime = pb
            userProfileVM.profile.personalBests["40yd"] = pb
            userProfileVM.profile.frequency = daysAvailable
            userProfileVM.profile.leaderboardOptIn = leaderboardOptIn
            
            // Consolidated UserDefaults saving with consistent keys
            print("💾 Onboarding: Saving user data to UserDefaults")
            print("   Level: \(fitnessLevel)")
            print("   Frequency: \(daysAvailable) days/week")
            print("   Personal Best: \(pb)s")
            
            // Primary keys used by TrainingView and Watch app
            UserDefaults.standard.set(fitnessLevel, forKey: "userLevel")
            UserDefaults.standard.set(daysAvailable, forKey: "trainingFrequency")
            UserDefaults.standard.set(pb, forKey: "personalBest40yd")
            
            // Additional user profile data
            UserDefaults.standard.set(gender, forKey: "userGender")
            UserDefaults.standard.set(age, forKey: "userAge")
            UserDefaults.standard.set(1, forKey: "currentWeek")
            UserDefaults.standard.set(1, forKey: "currentDay")
            
            // Force UserDefaults synchronization
            UserDefaults.standard.synchronize()
            
            // Verify data was saved correctly
            print("✅ Onboarding: UserDefaults verification:")
            print("   userLevel: \(UserDefaults.standard.string(forKey: "userLevel") ?? "nil")")
            print("   trainingFrequency: \(UserDefaults.standard.integer(forKey: "trainingFrequency"))")
            print("   personalBest40yd: \(UserDefaults.standard.double(forKey: "personalBest40yd"))")
            
            // Trigger workflow and sync
            Task {
                await workflowManager.handleTrainingPreferencesSubmitted(
                    userId: userName,
                    level: fitnessLevel.lowercased(),
                    daysPerWeek: daysAvailable,
                    userProfileVM: userProfileVM
                )
                
                // Refresh profile from UserDefaults to ensure sync
                await MainActor.run {
                    userProfileVM.refreshFromUserDefaults()
                    print("🔄 Profile refreshed from UserDefaults after onboarding")
                    
                    // Force session regeneration with updated profile
                    userProfileVM.refreshAdaptiveProgram()
                    print("🔄 Sessions regenerated with updated profile")
                }
                
                // Sync onboarding data to Watch
                print("🔄 Syncing onboarding data to Apple Watch...")
                await watchConnectivity.syncOnboardingData(userProfile: userProfileVM.profile)
                print("✅ Onboarding data synced to Apple Watch")
                
                // Give a moment for session sync to complete
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                print("✅ Session sync completed")
                
                // Complete onboarding after workflow finishes
                await MainActor.run {
                    onComplete()
                }
            }
            }) {
                HStack {
                    if workflowManager.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(getWorkflowStatusText())
                            .font(.headline.bold())
                    } else {
                        Text("Generate My Training Program")
                            .font(.headline.bold())
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
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
    
    // MARK: - Enhanced Reusable Section Card
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Training Program Generation
    
    /// Generates comprehensive 12-week training program based on user selections
    private func generateTrainingProgram() {
        print("🏃‍♂️ Generating 12-week program: Level=\(fitnessLevel), Frequency=\(daysAvailable)")
        
        // Create user preferences for program generation
        let userPreferences = UserSessionPreferences(
            favoriteTemplateIDs: userProfileVM.profile.favoriteSessionTemplateIDs,
            preferredTemplateIDs: userProfileVM.profile.preferredSessionTemplateIDs,
            dislikedTemplateIDs: userProfileVM.profile.dislikedSessionTemplateIDs,
            allowRepeatingFavorites: userProfileVM.profile.allowRepeatingFavorites,
            manualOverrides: userProfileVM.profile.manualSessionOverrides
        )
        
        // Generate 12-week program with level-specific sessions
        let weeklyPrograms = WeeklyProgramTemplate.generateWithUserPreferences(
            level: fitnessLevel,
            totalDaysPerWeek: daysAvailable,
            userPreferences: userPreferences,
            includeActiveRecovery: daysAvailable >= 6,
            includeRestDay: daysAvailable >= 7
        )
        
        print("📅 Generated \(weeklyPrograms.count) weeks of training")
        
        // Convert to training sessions and store in UserProfileViewModel
        userProfileVM.refreshAdaptiveProgram()
        
        // Log program details for debugging
        for (_, week) in weeklyPrograms.prefix(3).enumerated() {
            print("Week \(week.weekNumber): \(week.sessions.count) sessions")
            for session in week.sessions.prefix(2) {
                if let template = session.sessionTemplate {
                    print("  Day \(session.dayNumber): \(template.name) (\(template.focus))")
                } else {
                    print("  Day \(session.dayNumber): \(session.sessionType.rawValue)")
                }
            }
        }
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
    
    /// Get workflow status text for UI display
    private func getWorkflowStatusText() -> String {
        switch workflowManager.workflowStatus {
        case .idle:
            return "Generate My Training Program"
        case .validating:
            return "Validating Inputs..."
        case .allocatingSchedule:
            return "Creating Schedule..."
        case .fetchingSessions:
            return "Loading Sessions..."
        case .generatingPlan:
            return "Building Your Plan..."
        case .storingPlan:
            return "Saving Plan..."
        case .completed:
            return "Plan Complete!"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    /// Create initial session preferences based on user level and training frequency
    private func createInitialSessionPreferences(level: String, frequency: Int) -> (favoriteTypes: [String], preferredDistances: [Int], intensityPreference: Double) {
        var favoriteTypes: [String] = []
        var preferredDistances: [Int] = []
        var intensityPreference: Double = 0.5
        
        // Set preferences based on fitness level
        switch level {
        case "Beginner":
            favoriteTypes = ["Sprint", "Acceleration"]
            preferredDistances = [10, 20, 30, 40]
            intensityPreference = 0.3 // Lower intensity for beginners
            
        case "Intermediate":
            favoriteTypes = ["Sprint", "Max Velocity", "Acceleration"]
            preferredDistances = [20, 30, 40, 50]
            intensityPreference = 0.5 // Moderate intensity
            
        case "Advanced":
            favoriteTypes = ["Max Velocity", "Speed Endurance", "Sprint"]
            preferredDistances = [30, 40, 50, 60, 70]
            intensityPreference = 0.7 // Higher intensity
            
        case "Elite":
            favoriteTypes = ["Peak Velocity", "Speed Endurance", "Max Velocity"]
            preferredDistances = [40, 50, 60, 70, 80, 90, 100]
            intensityPreference = 0.9 // Maximum intensity
            
        default:
            favoriteTypes = ["Sprint", "Acceleration"]
            preferredDistances = [20, 30, 40]
            intensityPreference = 0.5
        }
        
        // Adjust preferences based on training frequency
        if frequency >= 5 {
            // High frequency - add recovery and variety
            favoriteTypes.append("Active Recovery")
            favoriteTypes.append("Tempo")
        } else if frequency <= 2 {
            // Low frequency - focus on core sessions
            favoriteTypes = favoriteTypes.prefix(2).map { $0 }
            intensityPreference = min(intensityPreference + 0.1, 1.0) // Slightly higher intensity for fewer sessions
        }
        
        return (favoriteTypes, preferredDistances, intensityPreference)
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

// MARK: - Feature Preview Component
struct FeaturePreview: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        OnboardingView(userName: "Test", userProfileVM: UserProfileViewModel(), onComplete: {})
    }
}
