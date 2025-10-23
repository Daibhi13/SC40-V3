import SwiftUI

struct ContentView: View {
    init() {
        // Set up demo data immediately when ContentView is created
        setupDemoDataForTesting()
    }
    
    var body: some View {
        // DIRECT UI TESTING: Bypass all onboarding/sync/buffering
        NavigationStack {
            DaySessionCardsWatchView()
                .onAppear {
                    // Double-check demo data is available
                    print("🔍 ContentView onAppear - Sessions count: \(WatchSessionManager.shared.trainingSessions.count)")
                    if WatchSessionManager.shared.trainingSessions.isEmpty {
                        print("⚠️ No sessions found, setting up demo data again")
                        setupDemoDataForTesting()
                    }
                }
        }
    }
    
    private func setupDemoDataForTesting() {
        // Safety check: Prevent duplicate session creation
        guard WatchSessionManager.shared.trainingSessions.isEmpty else {
            print("⚠️ Sessions already exist, skipping demo data creation")
            return
        }
        
        print("🔄 Creating demo sessions for ContentView...")
        
        // Create demo sessions for UI testing - ensure they are not completed
        var session1 = TrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Sprint Training",
            focus: "Acceleration",
            sprints: [SprintSet(distanceYards: 20, reps: 6, intensity: "85%")],
            accessoryWork: ["Dynamic warm-up", "Cool-down stretching"]
        )
        session1.isCompleted = false
        
        var session2 = TrainingSession(
            id: UUID(),
            week: 1,
            day: 2,
            type: "Speed Development",
            focus: "Max Velocity",
            sprints: [SprintSet(distanceYards: 40, reps: 4, intensity: "95%")],
            accessoryWork: ["Flying starts", "Speed drills"]
        )
        session2.isCompleted = false
        
        var session3 = TrainingSession(
            id: UUID(),
            week: 1,
            day: 3,
            type: "Time Trial",
            focus: "Benchmark",
            sprints: [SprintSet(distanceYards: 40, reps: 1, intensity: "100%")],
            accessoryWork: ["Thorough warm-up", "Cool-down"]
        )
        session3.isCompleted = false
        
        let demoSessions = [session1, session2, session3]
        
        // Set demo data in session manager
        WatchSessionManager.shared.trainingSessions = demoSessions
        UserDefaults.standard.set("ContentView", forKey: "sessionSource")
        
        print("✅ ContentView demo data loaded: \(demoSessions.count) sessions")
        print("✅ All sessions marked as NOT completed for testing")
    }
}

// MARK: - Canvas Previews

#if DEBUG
#Preview("1. Watch Content View") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("2. SC40 Splash Screen") {
    SC40SplashView(onComplete: {})
        .preferredColorScheme(.dark)
}

#Preview("3. Session Cards") {
    DaySessionCardsWatchView()
        .preferredColorScheme(.dark)
}

#Preview("4. Onboarding Required") {
    OnboardingRequiredView(onComplete: {})
        .preferredColorScheme(.dark)
}

#Preview("5. Starter Pro") {
    StarterProWatchView()
        .preferredColorScheme(.dark)
}

#Preview("6. Full Navigation Flow") {
    NavigationStack {
        EntryViewWatch()
    }
    .preferredColorScheme(.dark)
}

#Preview("7. Watch App States") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Apple Watch App")
            .font(.adaptiveTitle)
            .foregroundColor(.brandPrimary)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("• Entry Flow Management")
                .font(.adaptiveBody)
            Text("• Session Card Display")
                .font(.adaptiveBody)
            Text("• Connectivity Handling")
                .font(.adaptiveBody)
            Text("• Adaptive UI System")
                .font(.adaptiveBody)
        }
        .foregroundColor(.secondary)
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif



