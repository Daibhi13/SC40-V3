import SwiftUI

struct ContentView: View {
    var body: some View {
        EntryViewWatch()
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



