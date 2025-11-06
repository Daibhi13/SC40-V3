import SwiftUI

struct SyncTestingView: View {
    @StateObject private var syncTester = WorkoutSyncTester.shared
    @StateObject private var syncManager = WatchWorkoutSyncManager.shared
    @StateObject private var liveConnectivity = LiveWatchConnectivityHandler.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection
                    
                    // Connection Status
                    connectionStatusSection
                    
                    // Quick Test Buttons
                    quickTestSection
                    
                    // Test Results Summary
                    testResultsSection
                    
                    // Recent Test Results
                    if !syncTester.testResults.isEmpty {
                        recentResultsSection
                    }
                }
                .padding(16)
            }
            .background(Color.black)
            .navigationTitle("Sync Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") {
                        syncTester.clearTestResults()
                    }
                    .foregroundColor(.red)
                    .disabled(syncTester.testResults.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.blue)
            
            Text("SessionLibrary Sync Test")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Verify workout data sync between Watch and Phone")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Connection Status
    
    private var connectionStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: syncManager.isPhoneConnected ? "iphone.and.arrow.forward" : "iphone.slash")
                    .foregroundColor(syncManager.isPhoneConnected ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phone Connection")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(syncManager.isPhoneConnected ? "Connected" : "Disconnected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(syncManager.isPhoneConnected ? .green : .red)
                }
                
                Spacer()
                
                Circle()
                    .fill(syncManager.isPhoneConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
            
            if let lastSync = syncManager.lastSyncTime {
                Text("Last sync: \(formatTime(lastSync))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Quick Test Section
    
    private var quickTestSection: some View {
        VStack(spacing: 12) {
            Text("Quick Tests")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Live Connectivity Test
                Button(action: {
                    liveConnectivity.sendTestMessageToPhone()
                }) {
                    HStack {
                        Image(systemName: "iphone.and.arrow.forward")
                            .foregroundColor(.blue)
                        
                        Text("Test iPhone Connection")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if liveConnectivity.messagesReceived > 0 {
                            Text("\(liveConnectivity.messagesReceived)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .disabled(!liveConnectivity.isConnected)
                
                // Test Current Session
                Button(action: {
                    syncTester.testCurrentSession()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Test Session Sync")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if syncTester.isTestingActive {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.2))
                            .stroke(Color.green, lineWidth: 1)
                    )
                }
                .disabled(syncTester.isTestingActive)
                
                // Test Speed Session
                Button(action: {
                    testSpeedSession()
                }) {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Test Speed Session")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.2))
                            .stroke(Color.orange, lineWidth: 1)
                    )
                }
                .disabled(syncTester.isTestingActive)
                
                // Test Endurance Session
                Button(action: {
                    testEnduranceSession()
                }) {
                    HStack {
                        Image(systemName: "timer.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("Test Endurance Session")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .disabled(syncTester.isTestingActive)
            }
        }
    }
    
    // MARK: - Test Results Summary
    
    private var testResultsSection: some View {
        VStack(spacing: 8) {
            Text("Test Results")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(syncTester.syncSuccessCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Passed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 4) {
                    Text("\(syncTester.syncFailureCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("Failed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                }
                
                VStack(spacing: 4) {
                    Text("\(syncTester.testResults.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Total")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
    
    // MARK: - Recent Results Section
    
    private var recentResultsSection: some View {
        VStack(spacing: 8) {
            Text("Recent Tests")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 6) {
                ForEach(syncTester.testResults.suffix(3).reversed(), id: \.id) { result in
                    testResultRow(result)
                }
            }
        }
    }
    
    private func testResultRow(_ result: SyncTestResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: result.overallSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.overallSuccess ? .green : .red)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Week \(result.session.week), Day \(result.session.day)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(result.session.type)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(result.endTime))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("\(String(format: "%.1f", result.duration))s")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Test Methods
    
    private func testSpeedSession() {
        let speedSession = TrainingSession(
            week: 2,
            day: 3,
            type: "Speed",
            focus: "Acceleration & Drive Phase",
            sprints: [
                SprintSet(distanceYards: 30, reps: 4, intensity: "max"),
                SprintSet(distanceYards: 40, reps: 3, intensity: "max")
            ],
            accessoryWork: []
        )
        
        syncTester.testSessionLibrarySync(session: speedSession)
    }
    
    private func testEnduranceSession() {
        let enduranceSession = TrainingSession(
            week: 3,
            day: 2,
            type: "Speed Endurance",
            focus: "Lactate Tolerance",
            sprints: [
                SprintSet(distanceYards: 60, reps: 4, intensity: "submax"),
                SprintSet(distanceYards: 80, reps: 2, intensity: "submax")
            ],
            accessoryWork: []
        )
        
        syncTester.testSessionLibrarySync(session: enduranceSession)
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SyncTestingView()
        .preferredColorScheme(.dark)
}
