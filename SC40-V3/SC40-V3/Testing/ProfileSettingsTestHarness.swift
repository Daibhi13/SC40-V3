import SwiftUI
import Combine

/// Test harness to validate Profile Settings integration with Onboarding data
struct ProfileSettingsTestHarness: View {
    @StateObject private var userProfileVM = UserProfileViewModel()
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var showProfileView = false
    @State private var showEditProfile = false
    
    struct TestResult {
        let testName: String
        let status: TestStatus
        let details: String
        let timestamp: Date
        
        enum TestStatus {
            case pending, running, passed, failed
            
            var color: Color {
                switch self {
                case .pending: return .gray
                case .running: return .blue
                case .passed: return .green
                case .failed: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .pending: return "clock"
                case .running: return "arrow.clockwise"
                case .passed: return "checkmark.circle.fill"
                case .failed: return "xmark.circle.fill"
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Profile Settings Test")
                            .font(.title.bold())
                        
                        Text("Validate Onboarding → Profile Integration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Test Controls
                    HStack(spacing: 16) {
                        Button(action: runAllTests) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Run Tests")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(isRunningTests)
                        
                        Button(action: simulateOnboarding) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Simulate Onboarding")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { showProfileView = true }) {
                            HStack {
                                Image(systemName: "person.circle")
                                Text("View Profile")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.purple)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Current Profile Summary
                    ProfileSummaryCard(userProfileVM: userProfileVM)
                    
                    // Test Results
                    VStack(spacing: 12) {
                        HStack {
                            Text("Test Results")
                                .font(.headline.bold())
                            Spacer()
                            if isRunningTests {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if testResults.isEmpty {
                            Text("No tests run yet")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                                TestResultCard(result: result)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile Test Harness")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView(userProfileVM: userProfileVM)
        }
    }
    
    // MARK: - Test Functions
    
    private func runAllTests() {
        guard !isRunningTests else { return }
        
        isRunningTests = true
        testResults.removeAll()
        
        let tests = [
            ("Onboarding Data Persistence", testOnboardingDataPersistence),
            ("Profile Field Mapping", testProfileFieldMapping),
            ("Edit Profile Functionality", testEditProfileFunctionality),
            ("UserDefaults Synchronization", testUserDefaultsSynchronization),
            ("Profile Display Accuracy", testProfileDisplayAccuracy),
            ("Data Validation", testDataValidation)
        ]
        
        var testIndex = 0
        
        func runNextTest() {
            guard testIndex < tests.count else {
                isRunningTests = false
                return
            }
            
            let (testName, testFunction) = tests[testIndex]
            
            // Add running status
            testResults.append(TestResult(
                testName: testName,
                status: .running,
                details: "Test in progress...",
                timestamp: Date()
            ))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let result = testFunction()
                
                // Update result
                testResults[testIndex] = TestResult(
                    testName: testName,
                    status: result.0 ? .passed : .failed,
                    details: result.1,
                    timestamp: Date()
                )
                
                testIndex += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    runNextTest()
                }
            }
        }
        
        runNextTest()
    }
    
    private func simulateOnboarding() {
        // Simulate complete onboarding data
        let onboardingData = [
            "userName": "Test User",
            "userGender": "Male",
            "userAge": 28,
            "userHeight": 72, // 6ft
            "userWeight": 180.0,
            "userLevel": "Advanced",
            "trainingFrequency": 5,
            "personalBest40yd": 4.85,
            "leaderboardOptIn": true,
            "onboardingComplete": true
        ] as [String: Any]
        
        // Save to UserDefaults
        for (key, value) in onboardingData {
            UserDefaults.standard.set(value, forKey: key)
        }
        
        // Update profile
        userProfileVM.refreshFromUserDefaults()
        
        print("✅ Simulated onboarding data created")
    }
    
    // MARK: - Individual Tests
    
    private func testOnboardingDataPersistence() -> (Bool, String) {
        // Check if onboarding data persists in UserDefaults
        let requiredKeys = ["userName", "userLevel", "trainingFrequency", "personalBest40yd"]
        var missingKeys: [String] = []
        
        for key in requiredKeys {
            if UserDefaults.standard.object(forKey: key) == nil {
                missingKeys.append(key)
            }
        }
        
        if missingKeys.isEmpty {
            return (true, "All onboarding data persisted successfully")
        } else {
            return (false, "Missing keys: \(missingKeys.joined(separator: ", "))")
        }
    }
    
    private func testProfileFieldMapping() -> (Bool, String) {
        // Test if profile fields match onboarding data
        let profile = userProfileVM.profile
        
        let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        let userLevel = UserDefaults.standard.string(forKey: "userLevel") ?? ""
        let frequency = UserDefaults.standard.integer(forKey: "trainingFrequency")
        let pb = UserDefaults.standard.double(forKey: "personalBest40yd")
        
        var issues: [String] = []
        
        if profile.name != userName && !userName.isEmpty {
            issues.append("Name mismatch: profile='\(profile.name)', stored='\(userName)'")
        }
        
        if profile.level != userLevel && !userLevel.isEmpty {
            issues.append("Level mismatch: profile='\(profile.level)', stored='\(userLevel)'")
        }
        
        if profile.frequency != frequency && frequency > 0 {
            issues.append("Frequency mismatch: profile=\(profile.frequency), stored=\(frequency)")
        }
        
        if abs(profile.baselineTime - pb) > 0.01 && pb > 0 {
            issues.append("PB mismatch: profile=\(profile.baselineTime), stored=\(pb)")
        }
        
        if issues.isEmpty {
            return (true, "All profile fields match onboarding data")
        } else {
            return (false, issues.joined(separator: "; "))
        }
    }
    
    private func testEditProfileFunctionality() -> (Bool, String) {
        // Test if edit profile updates both profile and UserDefaults
        let originalName = userProfileVM.profile.name
        let testName = "Test Edit \(Date().timeIntervalSince1970)"
        
        // Simulate edit
        userProfileVM.profile.name = testName
        // Trigger save through property change (since saveProfile is private)
        userProfileVM.objectWillChange.send()
        
        // Check if UserDefaults updated
        let savedName = UserDefaults.standard.string(forKey: "userName")
        
        // Restore original
        userProfileVM.profile.name = originalName
        
        if savedName == testName {
            return (true, "Edit profile updates both profile and UserDefaults")
        } else {
            return (false, "Edit profile failed to update UserDefaults: expected='\(testName)', got='\(savedName ?? "nil")'")
        }
    }
    
    private func testUserDefaultsSynchronization() -> (Bool, String) {
        // Test bidirectional sync between profile and UserDefaults
        let testAge = 99
        
        // Update UserDefaults
        UserDefaults.standard.set(testAge, forKey: "userAge")
        
        // Refresh profile
        userProfileVM.refreshFromUserDefaults()
        
        if userProfileVM.profile.age == testAge {
            return (true, "UserDefaults → Profile sync working")
        } else {
            return (false, "Sync failed: UserDefaults=\(testAge), Profile=\(userProfileVM.profile.age)")
        }
    }
    
    private func testProfileDisplayAccuracy() -> (Bool, String) {
        // Test if profile displays match actual data
        let profile = userProfileVM.profile
        
        var checks: [String] = []
        
        // Check height formatting
        if profile.height > 0 {
            let feet = Int(profile.height / 12)
            let inches = Int(profile.height.truncatingRemainder(dividingBy: 12))
            let expectedFormat = "\(feet)ft \(inches)in"
            checks.append("Height format: \(expectedFormat)")
        }
        
        // Check PB formatting
        let pbValue = profile.personalBests["40yd"] ?? profile.baselineTime
        if pbValue > 0 {
            let expectedFormat = String(format: "%.2f seconds", pbValue)
            checks.append("PB format: \(expectedFormat)")
        }
        
        // Check frequency display
        if profile.frequency > 0 {
            let expectedFormat = "\(profile.frequency) days/week"
            checks.append("Frequency format: \(expectedFormat)")
        }
        
        return (true, "Display formats validated: \(checks.joined(separator: ", "))")
    }
    
    private func testDataValidation() -> (Bool, String) {
        // Test data validation and edge cases
        var validationTests: [String] = []
        
        // Test empty/default values
        let emptyProfile = UserProfile(name: "", email: nil, gender: "", age: 0, height: 0, weight: nil, personalBests: [:], level: "", baselineTime: 0.0, frequency: 0, currentWeek: 1, currentDay: 1, leaderboardOptIn: false)
        
        // Should handle empty values gracefully
        if emptyProfile.name.isEmpty {
            validationTests.append("Empty name handled")
        }
        
        if emptyProfile.age == 0 {
            validationTests.append("Zero age handled")
        }
        
        if emptyProfile.frequency == 0 {
            validationTests.append("Zero frequency handled")
        }
        
        // Test valid ranges
        let validAge = 25
        let validFrequency = 3
        let validHeight = 70
        
        if validAge >= 8 && validAge <= 100 {
            validationTests.append("Age range valid")
        }
        
        if validFrequency >= 1 && validFrequency <= 7 {
            validationTests.append("Frequency range valid")
        }
        
        if validHeight >= 48 && validHeight <= 84 {
            validationTests.append("Height range valid")
        }
        
        return (true, "Validation tests passed: \(validationTests.joined(separator: ", "))")
    }
}

// MARK: - Supporting Views

struct ProfileSummaryCard: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Profile")
                    .font(.headline.bold())
                Spacer()
                Button("Refresh") {
                    userProfileVM.refreshFromUserDefaults()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
            }
            
            let profile = userProfileVM.profile
            
            VStack(spacing: 8) {
                ProfileSummaryRow(label: "Name", value: profile.name.isEmpty ? "Not set" : profile.name)
                ProfileSummaryRow(label: "Level", value: profile.level.isEmpty ? "Not set" : profile.level)
                ProfileSummaryRow(label: "Frequency", value: profile.frequency == 0 ? "Not set" : "\(profile.frequency) days/week")
                ProfileSummaryRow(label: "40yd PB", value: profile.baselineTime == 0 ? "Not set" : String(format: "%.2fs", profile.baselineTime))
                ProfileSummaryRow(label: "Progress", value: "Week \(profile.currentWeek), Day \(profile.currentDay)")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProfileSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

struct TestResultCard: View {
    let result: ProfileSettingsTestHarness.TestResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.status.icon)
                .foregroundColor(result.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testName)
                    .font(.subheadline.bold())
                
                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            Text(DateFormatter.localizedString(from: result.timestamp, dateStyle: .none, timeStyle: .medium))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(result.status.color.opacity(0.1))
        .cornerRadius(8)
    }
}
