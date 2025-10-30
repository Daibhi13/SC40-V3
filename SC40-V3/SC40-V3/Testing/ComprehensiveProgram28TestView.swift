import SwiftUI

// MARK: - Comprehensive 28 Program Test View

struct ComprehensiveProgram28TestView: View {
    @StateObject private var testRunner = ComprehensiveProgram28Test()
    @State private var showDetails = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Test Controls
                        controlsSection
                        
                        // Progress Section
                        if testRunner.isRunning {
                            progressSection
                        }
                        
                        // Results Overview
                        if !testRunner.testResults.isEmpty {
                            resultsOverviewSection
                        }
                        
                        // Detailed Results Grid
                        if !testRunner.testResults.isEmpty && showDetails {
                            detailedResultsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("28 Program Test")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Comprehensive 28 Program Test")
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Tests all 28 combinations (4 levels × 7 days) to ensure unique 12-week program formats")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await testRunner.runComprehensiveTest()
                    }
                }) {
                    HStack {
                        if testRunner.isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(testRunner.isRunning ? "Running Tests..." : "Run 28 Tests")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: testRunner.isRunning ? [.gray, .gray.opacity(0.8)] : [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(testRunner.isRunning)
                
                if !testRunner.testResults.isEmpty {
                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: showDetails ? "eye.slash" : "eye")
                            Text(showDetails ? "Hide Details" : "Show Details")
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Testing Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Test \(testRunner.currentTest) of \(testRunner.totalTests)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int((Double(testRunner.currentTest) / Double(testRunner.totalTests)) * 100))%")
                        .font(.subheadline.bold())
                        .foregroundColor(.yellow)
                }
                
                ProgressView(value: Double(testRunner.currentTest), total: Double(testRunner.totalTests))
                    .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Results Overview Section
    
    private var resultsOverviewSection: some View {
        VStack(spacing: 16) {
            Text("Test Results Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            let passedCount = testRunner.testResults.filter { $0.status == .passed }.count
            let failedCount = testRunner.testResults.filter { $0.status == .failed }.count
            let uniquePrograms = Set(testRunner.testResults.map { $0.fingerprint.toString() }).count
            let totalSessions = testRunner.testResults.map { $0.sessionCount }.reduce(0, +)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                TestStatCard(
                    title: "Passed Tests",
                    value: "\(passedCount)/28",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                TestStatCard(
                    title: "Failed Tests",
                    value: "\(failedCount)/28",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                
                TestStatCard(
                    title: "Unique Programs",
                    value: "\(uniquePrograms)/28",
                    icon: "star.circle.fill",
                    color: .yellow
                )
                
                TestStatCard(
                    title: "Total Sessions",
                    value: "\(totalSessions)",
                    icon: "list.bullet.circle.fill",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Detailed Results Section
    
    private var detailedResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Test Results")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                // Header row
                Text("Level \\ Days")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
                
                ForEach(1...7, id: \.self) { day in
                    Text("\(day)")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Data rows
                ForEach([TrainingLevel.beginner, .intermediate, .advanced, .pro], id: \.self) { level in
                    Text(level.rawValue.capitalized)
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                    
                    ForEach(1...7, id: \.self) { day in
                        if let result = testRunner.testResults.first(where: { $0.level == level && $0.days == day }) {
                            ResultCell(result: result)
                        } else {
                            Text("-")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Supporting Views

struct TestStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ResultCell: View {
    let result: CombinationTestResult
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: result.status == .passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(result.status == .passed ? .green : .red)
            
            Text("\(result.sessionCount)")
                .font(.caption2.bold())
                .foregroundColor(.white)
            
            if result.isUnique {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(result.status == .passed ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        )
    }
}

// MARK: - Preview

struct ComprehensiveProgram28TestView_Previews: PreviewProvider {
    static var previews: some View {
        ComprehensiveProgram28TestView()
    }
}
