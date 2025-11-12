import SwiftUI
import Combine

// MARK: - Onboarding Error Types

enum OnboardingError: LocalizedError {
    case missingUserName
    case missingFitnessLevel
    case invalidFrequency
    case invalidPersonalBest
    case saveFailed(Error)
    case verificationFailed
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .missingUserName:
            return "Please enter your name"
        case .missingFitnessLevel:
            return "Please select your fitness level"
        case .invalidFrequency:
            return "Please select training frequency"
        case .invalidPersonalBest:
            return "Please enter a valid personal best time"
        case .saveFailed(let error):
            return "Failed to save profile: \(error.localizedDescription)"
        case .verificationFailed:
            return "Profile data verification failed"
        case .timeout:
            return "Operation timed out"
        }
    }
}

// Import UserProfileViewModel from Models
@MainActor
struct OnboardingView: View {
    var userName: String
    @ObservedObject var userProfileVM: UserProfileViewModel
    var onComplete: () -> Void
    
    // CRASH FIX: Don't use @StateObject with .shared singletons - causes immediate crash
    private var watchConnectivity: WatchConnectivityManager { WatchConnectivityManager.shared }
    private var profileManager: UserProfileManager { UserProfileManager.shared }
    
    @State private var gender = "Male"
    @State private var age = 25
    @State private var heightFeet = 5
    @State private var heightInches = 10
    @State private var weight = 170
    @State private var fitnessLevel = "Beginner"
    @State private var hasUserManuallySelectedLevel = false
    @State private var isAutoSettingLevel = false
    @State private var daysAvailable = 7
    @State private var pbSeconds: Int = 5
    @State private var pbTenthsHundredths: Int = 25
    @State private var leaderboardOptIn: Bool = true
    @State private var isCompleting = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // Computed property to convert wheel selections to Double
    private var pb: Double {
        Double(pbSeconds) + Double(pbTenthsHundredths) / 100.0
    }
    
    // Computed property to estimate total sessions in 12-week program
    private var estimatedSessions: Int {
        // For 1-4 day programs: All days are training sessions
        if daysAvailable <= 4 {
            return daysAvailable * 12
        }
        // For 5-6 day programs: Include active recovery sessions (still training)
        else if daysAvailable <= 6 {
            return daysAvailable * 12 // Active recovery sessions are included
        }
        // For 7-day programs: 6 training days + 1 full recovery day
        else {
            return (daysAvailable - 1) * 12 // Subtract 1 full recovery day
        }
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
    
    // MARK: - Adaptive Layout Helpers
    
    /// Adaptive spacing based on screen height
    private func adaptiveSpacing(for height: CGFloat) -> CGFloat {
        switch height {
        case ..<700:  // iPhone SE, iPhone 8
            return 16
        case 700..<800:  // iPhone 12 mini, iPhone 13 mini
            return 18
        case 800..<900:  // iPhone 14, iPhone 15
            return 20
        default:  // iPhone 14 Pro Max, iPhone 15 Pro Max
            return 24
        }
    }
    
    /// Adaptive font size based on screen height
    private func adaptiveFontSize(base: CGFloat, for height: CGFloat) -> CGFloat {
        switch height {
        case ..<700:  // iPhone SE, iPhone 8
            return base * 0.85
        case 700..<800:  // iPhone 12 mini, iPhone 13 mini
            return base * 0.9
        case 800..<900:  // iPhone 14, iPhone 15
            return base * 0.95
        default:  // iPhone 14 Pro Max, iPhone 15 Pro Max
            return base
        }
    }
    
    /// Adaptive top padding based on screen height
    private func adaptiveTopPadding(for height: CGFloat) -> CGFloat {
        switch height {
        case ..<700:  // iPhone SE, iPhone 8
            return 8
        case 700..<800:  // iPhone 12 mini, iPhone 13 mini
            return 12
        case 800..<900:  // iPhone 14, iPhone 15
            return 16
        default:  // iPhone 14 Pro Max, iPhone 15 Pro Max
            return 20
        }
    }
    
    /// Adaptive bottom padding for sticky button
    private func adaptiveBottomPadding(for height: CGFloat) -> CGFloat {
        switch height {
        case ..<700:  // iPhone SE, iPhone 8
            return 170
        case 700..<800:  // iPhone 12 mini, iPhone 13 mini
            return 190
        case 800..<852:  // iPhone 14, iPhone 15
            return 210
        case 852..<900:  // iPhone 14 Pro, iPhone 15 Pro
            return 220
        case 900..<950:  // iPhone 14 Pro Max, iPhone 15 Pro Max
            return 230
        default:  // iPhone 17 Pro and future larger models
            return 240
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                        // Header with progress matching the design
                        VStack(spacing: adaptiveSpacing(for: geometry.size.height) * 0.6) {
                            Text("Welcome, \(userName)!")
                                .font(.system(size: adaptiveFontSize(base: 28, for: geometry.size.height), weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Let's build your personalized training program")
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size.height), weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Enhanced progress bar with animation
                            VStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { index in
                                        Rectangle()
                                            .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                            .frame(height: 3)
                                            .frame(maxWidth: .infinity)
                                            .cornerRadius(2)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                Text("5 Questions • 2 minutes")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.top, adaptiveTopPadding(for: geometry.size.height))
                        .padding(.horizontal)
                    
                    // Questions sections with improved spacing
                    Group {
                        pbSection
                        profileSection
                        bodyMetricsSection
                        scheduleSection
                        leaderboardSection
                    }
                    
                        // Extra bottom padding for sticky button
                        Spacer(minLength: adaptiveBottomPadding(for: geometry.size.height))
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
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .allowsHitTesting(false)
                    
                    finishButton
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                        .background(
                            Color.black.opacity(0.9)
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
            }
        }
        .alert("Setup Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Clear stale state before onboarding starts to prevent old state carryover
            userProfileVM.resetUserState()
            print("🧹 OnboardingView: Cleared stale user state before starting onboarding")
            
            // Initialize level from PB if not already set
            if pb > 0 && fitnessLevel == "Beginner" {
                updateLevelFromPB()
                print("🎯 OnboardingView: Initial level set to '\(fitnessLevel)' based on PB: \(pb)s")
            }
        }
        .onDisappear {
            print("🧹 OnboardingView: OnboardingView disappeared")
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
                        .onChange(of: pbSeconds) { _, _ in
                            updateLevelFromPB()
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
                        .onChange(of: pbTenthsHundredths) { _, _ in
                            updateLevelFromPB()
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
    
    // Auto-update level based on PB time
    private func updateLevelFromPB() {
        let newLevel = classify_40yd_time(time: Float(pb), gender: gender)
        if newLevel != fitnessLevel {
            print("🎯 Auto-updating level from '\(fitnessLevel)' to '\(newLevel)' based on PB: \(pb)s")
            fitnessLevel = newLevel
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
                .onChange(of: gender) { _, _ in
                    updateLevelFromPB()
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
                    
                    Text("Whatever the level, all 1–7 day options are always available")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .bold()
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
    
    // MARK: - Live Program Ready Summary (Updates with all onboarding choices)
    private var finishButton: some View {
        VStack(spacing: 10) {
            // Live summary card - updates as user makes selections
            VStack(spacing: 10) {
                // Header with live level indicator
                HStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.body)
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Program Ready")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        // Live summary - updates with every selection
                        HStack(spacing: 6) {
                            // Level badge - LIVE UPDATES
                            Text(fitnessLevel)
                                .font(.caption2.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(levelColor(fitnessLevel))
                                .cornerRadius(4)
                                .id("level-\(fitnessLevel)") // Force refresh on level change
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            
                            // Frequency - LIVE UPDATES
                            Text("\(daysAvailable) days/wk")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                                .id("freq-\(daysAvailable)") // Force refresh on frequency change
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            
                            // PB Time - LIVE UPDATES
                            Text("\(String(format: "%.2f", pb))s")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .id("pb-\(pb)") // Force refresh on PB change
                        }
                        .id("summary-\(fitnessLevel)-\(daysAvailable)-\(pb)") // Force entire row refresh
                    }
                    
                    Spacer()
                }
                
                // Detailed program breakdown
                VStack(spacing: 6) {
                    // Week 1 start info
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption2)
                            .foregroundColor(.cyan)
                        Text("Starting Week 1")
                            .font(.caption2)
                            .foregroundColor(.white)
                        Spacer()
                        Text("Day 1")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Program features preview - LIVE UPDATES
                    HStack(spacing: 10) {
                        FeaturePreview(icon: "calendar", text: "12 Weeks", color: .blue)
                        FeaturePreview(icon: "figure.run", text: "\(estimatedSessions) Sessions", color: .green)
                            .id("sessions-\(estimatedSessions)") // Force refresh when session count changes
                        FeaturePreview(icon: "target", text: "Time Trials", color: .orange)
                        if daysAvailable >= 6 {
                            FeaturePreview(icon: "leaf", text: "Recovery", color: .mint)
                        }
                    }
                    .id("features-\(daysAvailable)") // Force refresh when frequency changes
                }
                
                // Simple Continue Button
                Button(action: {
                    print("\n" + String(repeating: "=", count: 80))
                    print("🔵 CONTINUE BUTTON TAPPED")
                    print(String(repeating: "=", count: 80))
                    print("📊 CURRENT STATE:")
                    print("   userName: '\(userName)'")
                    print("   fitnessLevel: '\(fitnessLevel)'")
                    print("   daysAvailable: \(daysAvailable)")
                    print("   pb: \(pb)")
                    print("   age: \(age)")
                    print("   height: \(heightFeet)ft \(heightInches)in")
                    print("   weight: \(weight) lbs")
                    print("   isCompleting: \(isCompleting)")
                    print(String(repeating: "=", count: 80) + "\n")
                    
                    // Use async safe completion method
                    Task {
                        print("🔵 ASYNC TASK STARTED")
                        if !isCompleting {
                            print("🔵 NOT COMPLETING - Proceeding with onboarding")
                            isCompleting = true
                            do {
                                print("🔵 CALLING runSafeOnboardingCompletion()...")
                                try await runSafeOnboardingCompletion()
                                print("✅ runSafeOnboardingCompletion() COMPLETED SUCCESSFULLY")
                            } catch {
                                print("\n" + String(repeating: "❌", count: 40))
                                print("❌ ONBOARDING ERROR CAUGHT")
                                print("❌ Error: \(error.localizedDescription)")
                                print("❌ Error type: \(type(of: error))")
                                print(String(repeating: "❌", count: 40) + "\n")
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                                isCompleting = false
                            }
                        } else {
                            print("⚠️ ALREADY COMPLETING - Ignoring duplicate tap")
                        }
                    }
                }) {
                    HStack {
                        if isCompleting {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Setting up...")
                                .font(.subheadline.bold())
                        } else {
                            Text("Continue")
                                .font(.subheadline.bold())
                            Image(systemName: "arrow.right")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isCompleting ? [Color.gray, Color.gray.opacity(0.8)] : [Color.yellow, Color.orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(isCompleting ? .white.opacity(0.6) : .black)
                    .cornerRadius(10)
                    .shadow(color: isCompleting ? Color.clear : Color.yellow.opacity(0.5), radius: 8, x: 0, y: 4)
                    .opacity(isCompleting ? 0.6 : 1.0)
                }
                .disabled(isCompleting)
                .padding(.top, 4)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Save and Navigate Helper
    // REMOVED: Old saveAndNavigate() function - now using runSafeOnboardingCompletion() instead
    
    // MARK: - Enhanced Reusable Section Card
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
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
    
    // MARK: - Thread-Safe Onboarding Completion
    
    // MARK: - 🚨 CRASH-PROOF COMPLETION METHOD
    
    /// Safe onboarding completion with comprehensive error handling
    @MainActor
    private func runSafeOnboardingCompletion() async throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🛡️ SAFE COMPLETION: Starting crash-protected onboarding flow")
        print(String(repeating: "=", count: 80))
        
        // STEP 1: Validate all inputs
        print("\n📊 INPUT VALIDATION:")
        print("   userName: '\(userName)' (isEmpty: \(userName.isEmpty))")
        print("   fitnessLevel: '\(fitnessLevel)' (isEmpty: \(fitnessLevel.isEmpty))")
        print("   daysAvailable: \(daysAvailable)")
        print("   pb: \(pb)")
        
        guard !userName.isEmpty else {
            print("❌ VALIDATION FAILED: userName is empty")
            throw OnboardingError.missingUserName
        }
        guard !fitnessLevel.isEmpty else {
            print("❌ VALIDATION FAILED: fitnessLevel is empty")
            throw OnboardingError.missingFitnessLevel
        }
        guard daysAvailable > 0 else {
            print("❌ VALIDATION FAILED: daysAvailable is 0")
            throw OnboardingError.invalidFrequency
        }
        guard pb > 0 else {
            print("❌ VALIDATION FAILED: pb is 0")
            throw OnboardingError.invalidPersonalBest
        }
        print("✅ All inputs validated successfully")
        
        // STEP 2: Save to UserDefaults with error handling
        print("\n💾 SAVING TO USERDEFAULTS:")
        do {
            UserDefaults.standard.set(userName, forKey: "user_name")
            UserDefaults.standard.set(userName, forKey: "userName")
            print("   ✓ userName saved: '\(userName)'")
            
            UserDefaults.standard.set(gender, forKey: "userGender")
            print("   ✓ gender saved")
            
            UserDefaults.standard.set(age, forKey: "userAge")
            UserDefaults.standard.set(age, forKey: "SC40_UserAge")
            print("   ✓ age saved: \(age)")
            
            let totalHeight = Double(heightFeet * 12 + heightInches)
            UserDefaults.standard.set(totalHeight, forKey: "userHeight")
            UserDefaults.standard.set(Int(totalHeight), forKey: "SC40_UserHeight")
            print("   ✓ height saved: \(totalHeight) inches")
            
            UserDefaults.standard.set(Double(weight), forKey: "userWeight")
            UserDefaults.standard.set(Double(weight), forKey: "SC40_UserWeight")
            print("   ✓ weight saved: \(weight) lbs")
            
            UserDefaults.standard.set(fitnessLevel, forKey: "userLevel")
            UserDefaults.standard.set(fitnessLevel, forKey: "SC40_UserLevel")
            print("   ✓ fitnessLevel saved: '\(fitnessLevel)'")
            
            UserDefaults.standard.set(daysAvailable, forKey: "trainingFrequency")
            UserDefaults.standard.set(daysAvailable, forKey: "SC40_UserFrequency")
            print("   ✓ trainingFrequency saved: \(daysAvailable)")
            
            UserDefaults.standard.set(pb, forKey: "personalBest40yd")
            UserDefaults.standard.set(pb, forKey: "SC40_TargetTime")
            print("   ✓ personalBest40yd saved: \(pb)")
            
            UserDefaults.standard.set(leaderboardOptIn, forKey: "leaderboardOptIn")
            print("   ✓ leaderboardOptIn saved")
            
            UserDefaults.standard.set(true, forKey: "onboardingCompleted")
            UserDefaults.standard.set(true, forKey: "SC40_OnboardingCompleted")
            UserDefaults.standard.set(true, forKey: "SC40_userProfileExists")
            print("   ✓ onboardingCompleted saved: true")
            
            UserDefaults.standard.synchronize()
            print("   ✓ UserDefaults synchronized")
        } catch {
            print("❌ UserDefaults save failed: \(error)")
            throw OnboardingError.saveFailed(error)
        }
        
        // STEP 3: Verify data was saved
        print("\n🔍 VERIFICATION:")
        let verifyLevel = UserDefaults.standard.string(forKey: "userLevel") ?? "NOT FOUND"
        let verifyFreq = UserDefaults.standard.integer(forKey: "trainingFrequency")
        let verifyPB = UserDefaults.standard.double(forKey: "personalBest40yd")
        
        guard verifyLevel == fitnessLevel, verifyFreq == daysAvailable, verifyPB == pb else {
            print("❌ VERIFICATION FAILED - Data mismatch!")
            throw OnboardingError.verificationFailed
        }
        print("✅ VERIFICATION PASSED - Data matches")
        
        // STEP 4: Wait for persistence
        print("\n⏳ WAITING 500ms for persistence...")
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // STEP 5: UPDATE PROFILE DIRECTLY - Don't use refreshFromUserDefaults yet
        print("\n🔄 PROFILE UPDATE: Directly updating profile from saved UserDefaults")
        print("   BEFORE UPDATE:")
        print("     profile.name: '\(userProfileVM.profile.name)'")
        print("     profile.level: '\(userProfileVM.profile.level)'")
        print("     profile.frequency: \(userProfileVM.profile.frequency)")
        print("     profile.baselineTime: \(userProfileVM.profile.baselineTime)")
        
        // Directly update profile properties from the values we just saved to UserDefaults
        userProfileVM.profile.name = userName
        userProfileVM.profile.level = fitnessLevel
        userProfileVM.profile.frequency = daysAvailable
        userProfileVM.profile.baselineTime = pb
        userProfileVM.profile.personalBests["40yd"] = pb
        userProfileVM.profile.currentWeek = 1
        userProfileVM.profile.currentDay = 1
        
        print("   AFTER UPDATE:")
        print("     profile.name: '\(userProfileVM.profile.name)'")
        print("     profile.level: '\(userProfileVM.profile.level)'")
        print("     profile.frequency: \(userProfileVM.profile.frequency)")
        print("     profile.baselineTime: \(userProfileVM.profile.baselineTime)")
        print("✅ PROFILE UPDATED: Direct assignment complete")
        
        // STEP 5b: Save the profile to UserProfileData key
        print("\n💾 SAVING PROFILE TO USERPROFILEDATA:")
        userProfileVM.saveProfile()
        print("✅ Profile saved - TrainingView will load this data")
        
        // STEP 5c: Verify the save worked
        print("\n🔍 VERIFICATION: Reading back saved profile...")
        if let savedData = UserDefaults.standard.data(forKey: "UserProfileData"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
            print("   ✅ Verified saved profile:")
            print("      name: '\(decoded.name)'")
            print("      level: '\(decoded.level)'")
            print("      frequency: \(decoded.frequency)")
            print("      baselineTime: \(decoded.baselineTime)")
        } else {
            print("   ❌ ERROR: Could not read back saved profile!")
        }
        
        // STEP 6: Wait for profile to fully update before navigation
        print("\n⏳ WAITING: Allowing profile to stabilize...")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // STEP 7: Navigate to TrainingView
        print("\n🚀 NAVIGATION: Calling onComplete()")
        print(String(repeating: "=", count: 60))
        
        // CRASH FIX: Add delay before navigation to allow audio system to stabilize
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms delay
        
        await MainActor.run { 
            print("📱 MainActor: Setting onboardingCompleted = true")
            onComplete() 
        }
        
        print("✅ ONBOARDING COMPLETE - Transitioning to TrainingView")
        print(String(repeating: "=", count: 60) + "\n")
        
        isCompleting = false
        
        // STEP 7a: Immediately push full profile snapshot to Watch via application context
        do {
            let profileContext: [String: Any] = [
                "type": "profile",
                "userName": userProfileVM.profile.name,
                "fitnessLevel": userProfileVM.profile.level,
                "daysAvailable": userProfileVM.profile.frequency,
                "pb": userProfileVM.profile.baselineTime,
                "onboardingCompleted": true,
                "userProfileExists": true,
                "age": age,
                "height": heightFeet * 12 + heightInches,
                "weight": Double(weight)
            ]
            print("📤 ONBOARDING: Sending profile context to Watch")
            print("   userName: \(profileContext["userName"] ?? "nil")")
            print("   fitnessLevel: \(profileContext["fitnessLevel"] ?? "nil")")
            print("   daysAvailable: \(profileContext["daysAvailable"] ?? "nil")")
            print("   pb: \(profileContext["pb"] ?? "nil")")
            print("   onboardingCompleted: \(profileContext["onboardingCompleted"] ?? "nil")")
            WatchConnectivityManager.shared.sendApplicationContext(profileContext)
            print("📤 ONBOARDING: sendApplicationContext() called - check WCSession state")
        }
        
        // STEP 7: Sync to Watch in background (non-blocking)
        Task.detached(priority: .background) {
            print("\n📤 BACKGROUND WATCH SYNC: Sending onboarding data to Apple Watch...")
            let debugProfile = await userProfileVM.profile
            print("   • Name: \(debugProfile.name)")
            print("   • Level: \(debugProfile.level)")
            print("   • Frequency: \(debugProfile.frequency)")
            print("   • Baseline: \(debugProfile.baselineTime)")
            await watchConnectivity.syncOnboardingData(userProfile: debugProfile)
            print("✅ BACKGROUND WATCH SYNC: Onboarding data sent to Watch")
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

// MARK: - Feature Preview Component
struct FeaturePreview: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 9))
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
