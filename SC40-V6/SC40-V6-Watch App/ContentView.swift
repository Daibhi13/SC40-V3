import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Sprint Coach 40")
                .font(.title)
                .foregroundColor(.yellow)
            Text("Watch App")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Canvas Previews

#if DEBUG
#Preview("1. Watch Content View") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("2. Watch Entry View") {
    EntryViewWatch()
        .preferredColorScheme(.dark)
}

#Preview("3. Watch App States") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Apple Watch App")
            .font(.adaptiveTitle)
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))

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



